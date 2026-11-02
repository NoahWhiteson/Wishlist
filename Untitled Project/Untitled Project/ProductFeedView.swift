import SwiftUI

struct ProductFeedView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var products: [Product] = []
    @State private var index = 0
    @State private var loadState: LoadState = .loading
    @State private var isRefreshing = false
    @State private var catalogEpoch = 0
    @State private var refreshError: String?

    private let catalogPollSeconds: UInt64 = 25

    private enum LoadState {
        case loading
        case ready
        case failed(String)
        case needsAPIKey
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                ZStack {
                    WishlistTheme.background.ignoresSafeArea()
                    ProgressView("Loading products…")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
            case .needsAPIKey:
                configHelp(message: "Add your API key in WishlistSecrets.plist (copy from WishlistSecrets.plist.example).")
            case .failed(let message):
                configHelp(message: message)
            case .ready:
                if products.isEmpty {
                    configHelp(message: "No active products in the database.")
                } else {
                    productStack
                }
            }
        }
        .task {
            await hydrateFromCacheIfPossible()
            await load(forceRefresh: false)
        }
        .task {
            await catalogPollLoop()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await load(forceRefresh: true, silent: true) }
            }
        }
    }

    @ViewBuilder
    private var productStack: some View {
        let nextIndex = (index + 1) % products.count

        ZStack {
            WishlistTheme.background.ignoresSafeArea()

            ProductDiscoveryView(product: products[nextIndex], isBackdrop: true)
                .allowsHitTesting(false)

            ProductDiscoveryView(
                product: products[index],
                onSwipeFinished: { advance() },
                onRefresh: {
                    isRefreshing = true
                    Task { await refreshFromGesture() }
                },
                isFeedRefreshing: $isRefreshing
            )
        }
        .id(catalogEpoch)
        .overlay(alignment: .top) {
            if let message = refreshError {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.85), in: Capsule())
                    .padding(.top, 56)
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 2_500_000_000)
                            refreshError = nil
                        }
                    }
            }
        }
    }

    private func configHelp(message: String) -> some View {
        ZStack {
            WishlistTheme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 28)
                Button("Retry") { Task { await load(forceRefresh: true) } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func advance() {
        guard !products.isEmpty else { return }
        index = (index + 1) % products.count
        WishlistAPIClient.shared.prefetchNeighbors(in: products, around: index)
    }

    private func refreshFromGesture() async {
        refreshError = nil
        let ok = await load(forceRefresh: true, silent: true)
        if ok {
            catalogEpoch += 1
        } else if !products.isEmpty {
            refreshError = "Couldn’t refresh catalog"
        }
        isRefreshing = false
    }

    private func catalogPollLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: catalogPollSeconds * 1_000_000_000)
            await load(forceRefresh: true, silent: true)
        }
    }

    private func hydrateFromCacheIfPossible() async {
        if let cached = await WishlistAPIClient.shared.cachedProductsSnapshot(), !cached.isEmpty {
            products = cached
            index = 0
            loadState = .ready
        }
    }

    @discardableResult
    private func load(forceRefresh: Bool = false, silent: Bool = false) async -> Bool {
        if WishlistConfig.apiKey.isEmpty {
            loadState = .needsAPIKey
            return false
        }
        if products.isEmpty, !silent {
            loadState = .loading
        }
        do {
            let fetched = try await WishlistAPIClient.shared.fetchProducts(
                forceRefresh: forceRefresh || products.isEmpty
            )
            applyCatalogUpdate(fetched)
            loadState = .ready
            return true
        } catch WishlistAPIError.missingAPIKey {
            loadState = .needsAPIKey
            return false
        } catch WishlistAPIError.badStatus(let code) {
            loadState = products.isEmpty ? .failed("API returned \(code). Check base URL and API key.") : .ready
            return false
        } catch {
            loadState = products.isEmpty ? .failed(error.localizedDescription) : .ready
            return false
        }
    }

    private func applyCatalogUpdate(_ fetched: [Product]) {
        let currentId = products.indices.contains(index) ? products[index].id : nil
        products = fetched
        if let currentId, let sameIndex = fetched.firstIndex(where: { $0.id == currentId }) {
            index = sameIndex
        } else {
            index = min(index, max(fetched.count - 1, 0))
        }
        if !fetched.isEmpty {
            WishlistAPIClient.shared.prefetchNeighbors(in: fetched, around: index)
        }
    }
}

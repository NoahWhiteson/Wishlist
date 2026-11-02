import SwiftUI

struct ProductFeedView: View {
    @State private var products: [Product] = []
    @State private var index = 0
    @State private var loadState: LoadState = .loading

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
                    ProductDiscoveryView(
                        product: products[index],
                        onSwipeFinished: { advance() }
                    )
                    .id(products[index].id)
                }
            }
        }
        .task { await load() }
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
                Button("Retry") { Task { await load() } }
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    private func advance() {
        guard !products.isEmpty else { return }
        index = (index + 1) % products.count
    }

    private func load() async {
        loadState = .loading
        if WishlistConfig.apiKey.isEmpty {
            loadState = .needsAPIKey
            return
        }
        do {
            let fetched = try await WishlistAPIClient.shared.fetchProducts()
            products = fetched
            index = 0
            loadState = fetched.isEmpty ? .ready : .ready
        } catch WishlistAPIError.missingAPIKey {
            loadState = .needsAPIKey
        } catch WishlistAPIError.badStatus(let code) {
            loadState = .failed("API returned \(code). Check base URL and API key.")
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

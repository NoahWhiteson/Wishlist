import SwiftUI
import UIKit

enum ProductImageSource: Hashable {
    case asset(String)
    case remote(URL)
}

struct ProductImageView: View {
    let source: ProductImageSource
    var highQuality: Bool = false

    var body: some View {
        switch source {
        case .asset(let name):
            styled(Image(name))
        case .remote(let url):
            RemoteProductImage(url: url, highQuality: highQuality)
        }
    }

    @ViewBuilder
    private func styled(_ image: Image) -> some View {
        if highQuality {
            image
                .resizable()
                .interpolation(.high)
                .antialiased(true)
        } else {
            image
                .resizable()
                .interpolation(.medium)
                .antialiased(true)
        }
    }
}

enum ProductImagePrefetcher {
    static func prefetchHeroes(for products: [Product], from start: Int = 0, count: Int = 8) async {
        guard !products.isEmpty else { return }
        let scale = await MainActor.run { UIScreen.main.scale }
        var urls: [URL] = []
        urls.reserveCapacity(count)
        for offset in 0 ..< count {
            let index = (start + offset) % products.count
            if let url = products[index].heroImage.remoteURL {
                urls.append(url)
            }
        }
        await RemoteImageLoader.shared.prefetch(urls: urls, displayScale: scale)
    }
}

// MARK: - Remote loading

actor RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private var storage: [URL: UIImage] = [:]
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 48_000_000, diskCapacity: 200_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    func cached(_ url: URL) -> UIImage? {
        storage[url]
    }

    func image(for url: URL, displayScale: CGFloat) async -> UIImage? {
        if let hit = storage[url] { return hit }
        guard let loaded = await fetchImage(from: url, displayScale: displayScale) else { return nil }
        storage[url] = loaded
        return loaded
    }

    func prefetch(urls: [URL], displayScale: CGFloat) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    _ = await self.image(for: url, displayScale: displayScale)
                }
            }
        }
    }

    private func fetchImage(from url: URL, displayScale: CGFloat) async -> UIImage? {
        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                return nil
            }
            guard let decoded = UIImage(data: data) else { return nil }
            guard let cgImage = decoded.cgImage else { return decoded }
            return UIImage(cgImage: cgImage, scale: displayScale, orientation: decoded.imageOrientation)
        } catch {
            return nil
        }
    }
}

private struct RemoteProductImage: View {
    let url: URL
    var highQuality: Bool

    @Environment(\.displayScale) private var displayScale
    @State private var uiImage: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let uiImage {
                styled(Image(uiImage: uiImage))
            } else if failed {
                placeholder
            } else {
                placeholder
                    .overlay { ProgressView().tint(.white) }
            }
        }
        .task(id: url) {
            await load()
        }
    }

    @ViewBuilder
    private func styled(_ image: Image) -> some View {
        if highQuality {
            image
                .resizable()
                .interpolation(.high)
                .antialiased(true)
        } else {
            image
                .resizable()
                .interpolation(.medium)
                .antialiased(true)
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(white: 0.12))
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.35))
            }
    }

    private func load() async {
        failed = false
        if let cached = await RemoteImageLoader.shared.cached(url) {
            uiImage = cached
            return
        }
        uiImage = nil
        if let loaded = await RemoteImageLoader.shared.image(for: url, displayScale: displayScale) {
            uiImage = loaded
        } else {
            failed = true
        }
    }
}

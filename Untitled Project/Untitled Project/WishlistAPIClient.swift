import Foundation

struct ProductsListResponse: Decodable {
    let data: [ProductDTO]
    let pagination: Pagination

    struct Pagination: Decodable {
        let limit: Int
        let offset: Int
        let count: Int
    }
}

struct ProductDTO: Decodable {
    let id: String
    let title: String
    let brand: String
    let descriptor: String
    let price: String
    let isGiftPick: Bool
    let heroImageUrl: String
    let galleryImageUrls: [String]
    let quickTags: [ProductTagDTO]
    let about: String
    let highlights: [String]
    let detailTags: [ProductTagDTO]
}

struct ProductTagDTO: Decodable {
    let label: String
    let systemImage: String
    let emphasized: Bool?
}

enum WishlistAPIError: Error {
    case missingAPIKey
    case badStatus(Int)
    case decoding(Error)
}

actor WishlistAPIClient {
    static let shared = WishlistAPIClient()

    private var cachedProducts: [Product]?
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 8_000_000, diskCapacity: 32_000_000)
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    func cachedProductsSnapshot() -> [Product]? {
        cachedProducts
    }

    func warmStart() async {
        guard !WishlistConfig.apiKey.isEmpty else { return }
        _ = try? await fetchProducts(forceRefresh: false)
    }

    func fetchProducts(limit: Int = 50, offset: Int = 0, forceRefresh: Bool = true) async throws -> [Product] {
        if offset == 0, !forceRefresh, let cachedProducts, !cachedProducts.isEmpty {
            return cachedProducts
        }

        if forceRefresh, offset == 0 {
            cachedProducts = nil
        }

        let key = WishlistConfig.apiKey
        guard !key.isEmpty else { throw WishlistAPIError.missingAPIKey }

        var components = URLComponents(
            url: WishlistConfig.apiBaseURL.appendingPathComponent("v1/products"),
            resolvingAgainstBaseURL: false
        )!
        var queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]
        if forceRefresh {
            queryItems.append(URLQueryItem(name: "_refresh", value: String(Int(Date().timeIntervalSince1970 * 1000))))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.setValue(key, forHTTPHeaderField: "X-API-Key")
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad
        if forceRefresh {
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WishlistAPIError.badStatus(-1)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw WishlistAPIError.badStatus(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(ProductsListResponse.self, from: data)
            let mapped = decoded.data.map(Product.init(dto:))
            if offset == 0 {
                cachedProducts = mapped
                Task.detached(priority: .userInitiated) {
                    await ProductImagePrefetcher.prefetchHeroes(for: mapped, from: 0, count: min(mapped.count, 12))
                }
            }
            return mapped
        } catch {
            throw WishlistAPIError.decoding(error)
        }
    }

    func prefetchNeighbors(in products: [Product], around index: Int) {
        guard !products.isEmpty else { return }
        Task.detached(priority: .utility) {
            await ProductImagePrefetcher.prefetchHeroes(for: products, from: index, count: min(products.count, 4))
        }
    }
}

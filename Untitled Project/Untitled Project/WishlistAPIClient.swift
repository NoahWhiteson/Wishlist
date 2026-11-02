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

    func fetchProducts(limit: Int = 50, offset: Int = 0) async throws -> [Product] {
        let key = WishlistConfig.apiKey
        guard !key.isEmpty else { throw WishlistAPIError.missingAPIKey }

        var components = URLComponents(
            url: WishlistConfig.apiBaseURL.appendingPathComponent("v1/products"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(key, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw WishlistAPIError.badStatus(-1)
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw WishlistAPIError.badStatus(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(ProductsListResponse.self, from: data)
            return decoded.data.map(Product.init(dto:))
        } catch {
            throw WishlistAPIError.decoding(error)
        }
    }
}

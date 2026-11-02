import Foundation

enum WishlistConfig {
    private static func plistString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    static var apiBaseURL: URL {
        if let raw = plistString("WishlistAPIBaseURL"), let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://wishlist.loomship.xyz")!
    }

    static var apiKey: String {
        if let key = plistString("WishlistAPIKey"), !key.isEmpty, key != "REPLACE_ME" {
            return key
        }
        if let url = Bundle.main.url(forResource: "WishlistSecrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let key = dict["WishlistAPIKey"] as? String, !key.isEmpty {
            return key
        }
        return ""
    }
}

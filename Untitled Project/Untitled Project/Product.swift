import Foundation

struct Product: Identifiable {
    let id: String
    let title: String
    let brand: String
    let descriptor: String
    let price: String
    let isGiftPick: Bool
    let heroImage: ProductImageSource
    let galleryImages: [ProductImageSource]
    let quickTags: [ProductTag]
    let about: String
    let highlights: [String]
    let detailTags: [ProductTag]

    init(
        id: String = UUID().uuidString,
        title: String,
        brand: String,
        descriptor: String,
        price: String,
        isGiftPick: Bool,
        heroImage: ProductImageSource,
        galleryImages: [ProductImageSource],
        quickTags: [ProductTag],
        about: String,
        highlights: [String],
        detailTags: [ProductTag]
    ) {
        self.id = id
        self.title = title
        self.brand = brand
        self.descriptor = descriptor
        self.price = price
        self.isGiftPick = isGiftPick
        self.heroImage = heroImage
        self.galleryImages = galleryImages
        self.quickTags = quickTags
        self.about = about
        self.highlights = highlights
        self.detailTags = detailTags
    }

    init(dto: ProductDTO) {
        id = dto.id
        title = dto.title
        brand = dto.brand
        descriptor = dto.descriptor
        price = dto.price
        isGiftPick = dto.isGiftPick
        heroImage = ProductImageSource.from(urlOrAsset: dto.heroImageUrl)
        galleryImages = dto.galleryImageUrls.map { ProductImageSource.from(urlOrAsset: $0) }
        quickTags = dto.quickTags.map { ProductTag($0) }
        about = dto.about
        highlights = dto.highlights
        detailTags = dto.detailTags.map { ProductTag($0) }
    }
}

struct ProductTag: Identifiable {
    let id = UUID()
    let label: String
    let systemImage: String
    let emphasized: Bool

    init(_ label: String, systemImage: String, emphasized: Bool = false) {
        self.label = label
        self.systemImage = systemImage
        self.emphasized = emphasized
    }

    init(_ dto: ProductTagDTO) {
        label = dto.label
        systemImage = dto.systemImage
        emphasized = dto.emphasized ?? false
    }
}

extension ProductImageSource {
    static func from(urlOrAsset value: String) -> ProductImageSource {
        if value.hasPrefix("http://") || value.hasPrefix("https://"), let url = URL(string: value) {
            return .remote(url)
        }
        return .asset(value)
    }

    var remoteURL: URL? {
        if case .remote(let url) = self { return url }
        return nil
    }
}

extension Product {
    static let airPodsPro = Product(
        title: "AirPods Pro (2nd Generation)",
        brand: "Apple",
        descriptor: "Active noise-cancelling wireless earbuds with MagSafe charging case (USB‑C).",
        price: "$249",
        isGiftPick: true,
        heroImage: .asset("AirPodsHero"),
        galleryImages: [
            .asset("AirPodsGalleryCase"),
            .asset("AirPodsGalleryFlatlay"),
            .asset("AirPodsGalleryLifestyle"),
        ],
        quickTags: [
            ProductTag("Wireless", systemImage: "antenna.radiowaves.left.and.right", emphasized: true),
            ProductTag("$200 – $300", systemImage: "tag"),
            ProductTag("Noise Cancelling", systemImage: "waveform"),
        ],
        about: "AirPods Pro feature the Apple H2 chip for up to 2× better Active Noise Cancellation than the previous generation. Adaptive Transparency lets outside sound in while reducing loud noise around you. Personalized Spatial Audio with dynamic head tracking places sound all around you.",
        highlights: [
            "Up to 2× more Active Noise Cancellation with Adaptive Transparency",
            "Spatial Audio with dynamic head tracking for immersive listening",
            "Up to 6 hours listening time per charge; 30 hours with the case",
            "IP54 dust, sweat, and water resistant (earbuds and case)",
        ],
        detailTags: [
            ProductTag("Tech", systemImage: "cpu"),
            ProductTag("Bluetooth", systemImage: "dot.radiowaves.left.and.right"),
            ProductTag("Travel", systemImage: "airplane"),
            ProductTag("Giftable", systemImage: "gift", emphasized: true),
            ProductTag("Popular", systemImage: "flame", emphasized: true),
            ProductTag("USB‑C", systemImage: "cable.connector"),
            ProductTag("MagSafe", systemImage: "bolt.circle.fill"),
        ]
    )
}

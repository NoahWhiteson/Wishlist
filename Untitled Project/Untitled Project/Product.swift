import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let title: String
    let brand: String
    let descriptor: String
    let price: String
    let isGiftPick: Bool
    let heroImageName: String
    let galleryImageNames: [String]
    let quickTags: [ProductTag]
    let about: String
    let highlights: [String]
    let detailTags: [ProductTag]
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
}

extension Product {
    static let airPodsPro = Product(
        title: "AirPods Pro (2nd Generation)",
        brand: "Apple",
        descriptor: "Active noise-cancelling wireless earbuds with MagSafe charging case (USB‑C).",
        price: "$249",
        isGiftPick: true,
        heroImageName: "AirPodsHero",
        galleryImageNames: [
            "AirPodsGalleryCase",
            "AirPodsGalleryFlatlay",
            "AirPodsGalleryLifestyle"
        ],
        quickTags: [
            ProductTag("Wireless", systemImage: "antenna.radiowaves.left.and.right", emphasized: true),
            ProductTag("$200 – $300", systemImage: "tag"),
            ProductTag("Noise Cancelling", systemImage: "waveform")
        ],
        about: "AirPods Pro feature the Apple H2 chip for up to 2× better Active Noise Cancellation than the previous generation. Adaptive Transparency lets outside sound in while reducing loud noise around you. Personalized Spatial Audio with dynamic head tracking places sound all around you.",
        highlights: [
            "Up to 2× more Active Noise Cancellation with Adaptive Transparency",
            "Spatial Audio with dynamic head tracking for immersive listening",
            "Up to 6 hours listening time per charge; 30 hours with the case",
            "IP54 dust, sweat, and water resistant (earbuds and case)"
        ],
        detailTags: [
            ProductTag("Tech", systemImage: "cpu"),
            ProductTag("Bluetooth", systemImage: "dot.radiowaves.left.and.right"),
            ProductTag("Travel", systemImage: "airplane"),
            ProductTag("Giftable", systemImage: "gift", emphasized: true),
            ProductTag("Popular", systemImage: "flame", emphasized: true),
            ProductTag("USB‑C", systemImage: "cable.connector"),
            ProductTag("MagSafe", systemImage: "bolt.circle.fill")
        ]
    )
}

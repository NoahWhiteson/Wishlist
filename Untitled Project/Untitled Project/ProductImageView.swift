import SwiftUI

enum ProductImageSource: Hashable {
    case asset(String)
    case remote(URL)
}

struct ProductImageView: View {
    let source: ProductImageSource

    var body: some View {
        switch source {
        case .asset(let name):
            Image(name)
                .resizable()
        case .remote(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                case .failure:
                    placeholder
                case .empty:
                    placeholder.overlay { ProgressView().tint(.white) }
                @unknown default:
                    placeholder
                }
            }
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
}

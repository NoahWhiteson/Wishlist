import SwiftUI

enum WishlistTheme {
    static let background = Color.black
    static let surface = Color(white: 0.12)
    static let muted = Color(white: 0.55)
    static let giftGold = Color(red: 0.95, green: 0.78, blue: 0.35)
    static let accent = Color(red: 1.0, green: 0.18, blue: 0.55)
    static let accentSoft = Color(red: 1.0, green: 0.35, blue: 0.65)

    static let accentGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.22, blue: 0.58), Color(red: 0.98, green: 0.12, blue: 0.45)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

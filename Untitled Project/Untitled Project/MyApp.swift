import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await WishlistAPIClient.shared.warmStart()
                }
        }
    }
}

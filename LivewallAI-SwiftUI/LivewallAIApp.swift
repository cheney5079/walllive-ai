import SwiftUI

@main
struct LivewallAIApp: App {
    @StateObject private var store = WallpaperStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

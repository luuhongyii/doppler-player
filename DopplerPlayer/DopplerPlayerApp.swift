import SwiftUI

@main
struct DopplerPlayerApp: App {
    @State private var library = LibraryManager()
    @State private var playlists = PlaylistStore()
    @State private var player = AudioPlayerManager()
    @State private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(library)
                .environment(playlists)
                .environment(player)
                .environment(theme)
                .preferredColorScheme(theme.preferredColorScheme)
        }
    }
}

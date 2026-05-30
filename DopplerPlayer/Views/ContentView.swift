import SwiftUI

struct ContentView: View {
    @Environment(AudioPlayerManager.self) private var player
    @State private var selectedTab = 0

    var body: some View {
        @Bindable var player = player

        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem { Label("歌曲", systemImage: "music.note.list") }
                .tag(0)

            PlaylistsView()
                .tabItem { Label("播放列表", systemImage: "list.star") }
                .tag(1)

            AlbumsGridView()
                .tabItem { Label("专辑", systemImage: "square.stack") }
                .tag(2)

            ArtistsListView()
                .tabItem { Label("艺术家", systemImage: "person.2") }
                .tag(3)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(4)
        }
        .tint(AppTheme.accent)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentTrack != nil {
                MiniPlayerView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: player.currentTrack?.id)
        .background(AppTheme.background)
        .fullScreenCover(isPresented: $player.showNowPlaying) {
            NowPlayingView()
        }
    }
}

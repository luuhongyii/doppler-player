import SwiftUI

struct TrackActionModifier: ViewModifier {
    let track: Track

    @Environment(PlaylistStore.self) private var playlists
    @State private var showAddToPlaylist = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    Haptics.tap()
                    _ = playlists.toggleFavorite(track)
                } label: {
                    Label(
                        playlists.isFavorite(track) ? "取消收藏" : "收藏",
                        systemImage: playlists.isFavorite(track) ? "heart.slash" : "heart"
                    )
                }
                Button { showAddToPlaylist = true } label: {
                    Label("添加到播放列表", systemImage: "text.badge.plus")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    Haptics.tap()
                    _ = playlists.toggleFavorite(track)
                } label: {
                    Label("收藏", systemImage: playlists.isFavorite(track) ? "heart.slash" : "heart.fill")
                }
                .tint(AppTheme.accent)

                Button { showAddToPlaylist = true } label: {
                    Label("列表", systemImage: "plus")
                }
                .tint(AppTheme.surfaceElevated)
            }
            .sheet(isPresented: $showAddToPlaylist) {
                AddToPlaylistSheet(track: track)
            }
    }
}

extension View {
    func trackActions(for track: Track) -> some View {
        modifier(TrackActionModifier(track: track))
    }
}

struct FavoriteButton: View {
    let track: Track
    var size: CGFloat = 22

    @Environment(PlaylistStore.self) private var playlists

    var body: some View {
        Button {
            Haptics.tap()
            _ = playlists.toggleFavorite(track)
        } label: {
            Image(systemName: playlists.isFavorite(track) ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(playlists.isFavorite(track) ? AppTheme.accent : AppTheme.textTertiary)
                .symbolEffect(.bounce, value: playlists.isFavorite(track))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playlists.isFavorite(track) ? "取消收藏" : "收藏")
    }
}

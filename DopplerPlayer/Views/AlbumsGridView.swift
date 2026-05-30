import SwiftUI

struct AlbumsGridView: View {
    @Environment(LibraryManager.self) private var library

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if library.albums.isEmpty {
                    ContentUnavailableView(
                        "暂无专辑",
                        systemImage: "square.stack",
                        description: Text("导入音乐后将按专辑分组显示")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(library.albums) { album in
                                NavigationLink(value: album) {
                                    AlbumGridCell(album: album)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("专辑")
            .navigationDestination(for: AlbumGroup.self) { album in
                AlbumDetailView(album: album)
            }
        }
    }
}

struct AlbumGridCell: View {
    let album: AlbumGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ArtworkThumbnail(image: album.artworkImage, size: nil)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.artworkCorner, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(2)
                Text(album.artist)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
        }
    }
}

struct AlbumDetailView: View {
    let album: AlbumGroup
    @Environment(AudioPlayerManager.self) private var player

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    ArtworkThumbnail(image: album.artworkImage, size: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.45), radius: 24, y: 12)

                    VStack(spacing: 6) {
                        Text(album.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)
                        Text(album.artist)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(album.tracks.count) 首 · \(formatDuration(album.totalDuration))")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textTertiary)
                    }

                    Button("播放全部") {
                        player.playAlbum(album)
                    }
                    .buttonStyle(AccentButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(AppTheme.background)
                .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 8, trailing: 20))
            }

            Section {
                ForEach(album.tracks) { track in
                    TrackRow(track: track, showFavorite: true)
                        .trackActions(for: track)
                        .listRowBackground(AppTheme.background)
                        .contentShape(Rectangle())
                        .onTapGesture { player.playAlbum(album, from: track) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

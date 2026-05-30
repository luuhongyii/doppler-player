import SwiftUI

struct ArtistsListView: View {
    @Environment(LibraryManager.self) private var library

    var body: some View {
        NavigationStack {
            Group {
                if library.artists.isEmpty {
                    ContentUnavailableView(
                        "暂无艺术家",
                        systemImage: "person.2",
                        description: Text("导入音乐后将按艺术家分组")
                    )
                } else {
                    List(library.artists) { artist in
                        NavigationLink(value: artist) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.surfaceElevated)
                                    Text(String(artist.name.prefix(1)).uppercased())
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                .frame(width: 48, height: 48)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(artist.name)
                                        .font(.body.weight(.medium))
                                    Text("\(artist.albums.count) 张专辑 · \(artist.trackCount) 首")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(AppTheme.background)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("艺术家")
            .navigationDestination(for: ArtistGroup.self) { artist in
                ArtistDetailView(artist: artist)
            }
        }
    }
}

struct ArtistDetailView: View {
    let artist: ArtistGroup

    var body: some View {
        List(artist.albums) { album in
            NavigationLink(value: album) {
                HStack(spacing: 14) {
                    ArtworkThumbnail(image: album.artworkImage, size: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(album.title)
                            .font(.body.weight(.medium))
                        Text("\(album.tracks.count) 首")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .listRowBackground(AppTheme.background)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .navigationTitle(artist.name)
        .navigationDestination(for: AlbumGroup.self) { album in
            AlbumDetailView(album: album)
        }
    }
}

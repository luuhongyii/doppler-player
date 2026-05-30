import SwiftUI

struct PlaylistsView: View {
    @Environment(LibraryManager.self) private var library
    @Environment(PlaylistStore.self) private var playlists

    @State private var showCreateAlert = false
    @State private var showRenameAlert = false
    @State private var newPlaylistName = ""
    @State private var playlistToRename: Playlist?

    var body: some View {
        NavigationStack {
            Group {
                if library.tracks.isEmpty {
                    ContentUnavailableView(
                        "暂无音乐",
                        systemImage: "music.note.list",
                        description: Text("导入歌曲后可创建播放列表与收藏")
                    )
                } else {
                    playlistList
                }
            }
            .background(AppTheme.background)
            .navigationTitle("播放列表")
            .toolbar { toolbarContent }
            .navigationDestination(for: PlaylistDestination.self) { destination in
                PlaylistDetailView(destination: destination)
            }
            .alert("新建播放列表", isPresented: $showCreateAlert) {
                TextField("名称", text: $newPlaylistName)
                Button("取消", role: .cancel) { newPlaylistName = "" }
                Button("创建") {
                    if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = playlists.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                        Haptics.tap()
                    }
                }
            } message: {
                Text("为播放列表取个名字")
            }
            .alert("重命名播放列表", isPresented: $showRenameAlert) {
                TextField("名称", text: $newPlaylistName)
                Button("取消", role: .cancel) {
                    playlistToRename = nil
                    newPlaylistName = ""
                }
                Button("保存") {
                    if let playlistToRename, !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        playlists.renamePlaylist(playlistToRename, name: newPlaylistName)
                        Haptics.tap()
                    }
                    playlistToRename = nil
                    newPlaylistName = ""
                }
            }
        }
        .onAppear {
            playlists.pruneInvalidTracks(validIDs: Set(library.tracks.map(\.id)))
        }
    }

    private var playlistList: some View {
        List {
            Section {
                NavigationLink(value: PlaylistDestination.favorites) {
                    PlaylistRow(
                        title: "我的收藏",
                        subtitle: "\(playlists.favoritesCount) 首",
                        icon: "heart.fill",
                        iconColor: AppTheme.accent,
                        artwork: playlists.favoriteTracks(from: library.tracks).first?.artworkImage
                    )
                }
                .listRowBackground(AppTheme.background)
            }

            Section {
                if playlists.playlists.isEmpty {
                    Text("点右上角 + 创建播放列表")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .listRowBackground(AppTheme.background)
                } else {
                    ForEach(playlists.playlists) { playlist in
                        NavigationLink(value: PlaylistDestination.playlist(playlist.id)) {
                            let resolved = playlists.tracks(for: playlist, from: library.tracks)
                            PlaylistRow(
                                title: playlist.name,
                                subtitle: "\(resolved.count) 首",
                                icon: "music.note.list",
                                iconColor: AppTheme.textSecondary,
                                artwork: resolved.first?.artworkImage
                            )
                        }
                        .listRowBackground(AppTheme.background)
                        .contextMenu {
                            Button {
                                playlistToRename = playlist
                                newPlaylistName = playlist.name
                                showRenameAlert = true
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                playlists.deletePlaylist(playlist)
                                Haptics.tap()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            playlists.deletePlaylist(playlists.playlists[index])
                        }
                    }
                }
            } header: {
                Text("我的播放列表")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                newPlaylistName = ""
                showCreateAlert = true
            } label: {
                Image(systemName: "plus")
            }
            .disabled(library.tracks.isEmpty)
        }
    }

}

struct PlaylistRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let artwork: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            if let artwork {
                ArtworkThumbnail(image: artwork, size: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(iconColor)
                }
                .frame(width: 52, height: 52)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
}

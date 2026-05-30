import SwiftUI

struct PlaylistDetailView: View {
    let destination: PlaylistDestination

    @Environment(LibraryManager.self) private var library
    @Environment(PlaylistStore.self) private var playlists
    @Environment(AudioPlayerManager.self) private var player

    @State private var showRenameAlert = false
    @State private var renameText = ""

    private var isFavorites: Bool {
        if case .favorites = destination { return true }
        return false
    }

    private var playlist: Playlist? {
        guard case .playlist(let id) = destination else { return nil }
        return playlists.playlist(id: id)
    }

    private var title: String {
        isFavorites ? "我的收藏" : (playlist?.name ?? "播放列表")
    }

    private var resolvedTracks: [Track] {
        if isFavorites {
            return playlists.favoriteTracks(from: library.tracks)
        }
        guard let playlist else { return [] }
        return playlists.tracks(for: playlist, from: library.tracks)
    }

    var body: some View {
        Group {
            if resolvedTracks.isEmpty {
                ContentUnavailableView(
                    isFavorites ? "还没有收藏" : "播放列表为空",
                    systemImage: isFavorites ? "heart" : "music.note.list",
                    description: Text(isFavorites ? "在歌曲旁点 ♥ 即可收藏" : "从资料库将歌曲添加到此列表")
                )
            } else {
                trackList
            }
        }
        .background(AppTheme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("重命名播放列表", isPresented: $showRenameAlert) {
            TextField("名称", text: $renameText)
            Button("取消", role: .cancel) {}
            Button("保存") {
                if let playlist, !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    playlists.renamePlaylist(playlist, name: renameText)
                    Haptics.tap()
                }
            }
        }
    }

    private var trackList: some View {
        List {
            Section {
                Button("播放全部") {
                    player.play(tracks: resolvedTracks, startingAt: 0)
                }
                .buttonStyle(AccentButtonStyle())
                .frame(maxWidth: .infinity)
                .listRowBackground(AppTheme.background)
                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 8, trailing: 20))
            }

            Section {
                ForEach(resolvedTracks) { track in
                    TrackRow(track: track, showFavorite: true)
                        .trackActions(for: track)
                        .listRowBackground(AppTheme.background)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            player.play(
                                tracks: resolvedTracks,
                                startingAt: resolvedTracks.firstIndex(where: { $0.id == track.id }) ?? 0
                            )
                        }
                }
                .onDelete(perform: deleteTracks)
                .onMove(perform: moveTracks)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !isFavorites, playlist != nil {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        renameText = playlist?.name ?? ""
                        showRenameAlert = true
                    } label: {
                        Label("重命名", systemImage: "pencil")
                    }
                    if let playlist {
                        Button(role: .destructive) {
                            playlists.deletePlaylist(playlist)
                            Haptics.tap()
                        } label: {
                            Label("删除播放列表", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        } else if isFavorites {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
    }

    private func deleteTracks(at offsets: IndexSet) {
        if isFavorites {
            for index in offsets {
                let track = resolvedTracks[index]
                if playlists.isFavorite(track) {
                    _ = playlists.toggleFavorite(track)
                }
            }
        } else if let playlist {
            playlists.removeTracks(at: offsets, from: playlist)
        }
    }

    private func moveTracks(from source: IndexSet, to destination: Int) {
        if isFavorites {
            var ids = playlists.favoriteTrackIDs
            ids.move(fromOffsets: source, toOffset: destination)
            // 需通过 store 暴露 reorderFavorites — 添加方法
            playlists.reorderFavorites(ids)
        } else if let playlist {
            playlists.moveTracks(from: source, to: destination, in: playlist)
        }
    }
}

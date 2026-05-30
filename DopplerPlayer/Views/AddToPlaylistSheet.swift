import SwiftUI

struct AddToPlaylistSheet: View {
    let track: Track

    @Environment(PlaylistStore.self) private var playlists
    @Environment(\.dismiss) private var dismiss

    @State private var newPlaylistName = ""
    @State private var showCreateField = false

    var body: some View {
        NavigationStack {
            List {
                if showCreateField {
                    Section {
                        HStack {
                            TextField("播放列表名称", text: $newPlaylistName)
                            Button("创建") { createAndAdd() }
                                .disabled(newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }

                Section {
                    if playlists.playlists.isEmpty && !showCreateField {
                        Text("还没有播放列表")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    ForEach(playlists.playlists) { playlist in
                        let contained = playlists.contains(track, in: playlist)
                        Button {
                            toggle(playlist: playlist, contained: contained)
                        } label: {
                            HStack {
                                Image(systemName: contained ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(contained ? AppTheme.accent : AppTheme.textTertiary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .foregroundStyle(AppTheme.textPrimary)
                                    Text("\(playlist.trackIDs.count) 首")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("添加到播放列表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("新建") {
                        withAnimation { showCreateField.toggle() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func toggle(playlist: Playlist, contained: Bool) {
        Haptics.select()
        if contained {
            playlists.removeTrack(track, from: playlist)
        } else {
            playlists.addTrack(track, to: playlist)
        }
    }

    private func createAndAdd() {
        let playlist = playlists.createPlaylist(name: newPlaylistName)
        playlists.addTrack(track, to: playlist)
        newPlaylistName = ""
        showCreateField = false
        Haptics.tap()
    }
}

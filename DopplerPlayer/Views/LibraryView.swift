import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(LibraryManager.self) private var library
    @Environment(PlaylistStore.self) private var playlists
    @Environment(AudioPlayerManager.self) private var player
    @State private var showImporter = false
    @State private var searchText = ""

    private var filtered: [Track] {
        guard !searchText.isEmpty else { return library.tracks }
        return library.tracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if library.tracks.isEmpty {
                    emptyState
                } else {
                    trackList
                }
            }
            .background(AppTheme.background)
            .navigationTitle("资料库")
            .searchable(text: $searchText, prompt: "搜索歌曲、专辑、艺术家")
            .toolbar { toolbarContent }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: UTType.audioImport,
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    Task { await library.importFiles(from: urls) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(AppTheme.textTertiary)
            Text("导入本地音乐")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Text("从「文件」选择 MP3、FLAC、M4A、LRC 等\n同名 .lrc 会自动匹配为歌词")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.textSecondary)
            Button("导入音乐") { showImporter = true }
                .buttonStyle(AccentButtonStyle())
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var trackList: some View {
        List {
            ForEach(filtered) { track in
                TrackRow(track: track, showFavorite: true)
                    .trackActions(for: track)
                    .listRowBackground(AppTheme.background)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        player.play(tracks: filtered, startingAt: filtered.firstIndex(where: { $0.id == track.id }) ?? 0)
                    }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let track = filtered[index]
                    playlists.removeTrackFromAll(track.id)
                    library.removeTrack(track)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showImporter = true } label: {
                Image(systemName: "plus")
            }
            .disabled(library.isScanning)
        }
        if library.isScanning {
            ToolbarItem(placement: .topBarLeading) {
                ProgressView()
            }
        }
    }
}

struct TrackRow: View {
    let track: Track
    var showFavorite: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ArtworkThumbnail(image: track.artworkImage, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(track.displayArtist) · \(track.displayAlbum)")
                    if track.hasLyrics {
                        Image(systemName: "text.quote")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            if showFavorite {
                FavoriteButton(track: track, size: 18)
            }
            Text(formatDuration(track.duration))
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

func formatDuration(_ seconds: TimeInterval) -> String {
    guard seconds.isFinite, seconds > 0 else { return "--:--" }
    let m = Int(seconds) / 60
    let s = Int(seconds) % 60
    return String(format: "%d:%02d", m, s)
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(uiColor: .black))
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(AppTheme.accent)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

import SwiftUI

private enum NowPlayingDisplayMode: String, CaseIterable {
    case artwork = "封面"
    case lyrics = "歌词"
}

struct NowPlayingView: View {
    @Environment(AudioPlayerManager.self) private var player
    @Environment(LibraryManager.self) private var library
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showQueue = false
    @State private var showAddToPlaylist = false
    @State private var isDraggingSlider = false
    @State private var dragValue: Double = 0
    @State private var dismissDragOffset: CGFloat = 0
    @State private var displayMode: NowPlayingDisplayMode = .artwork
    @State private var parsedLyrics: ParsedLyrics?

    private var track: Track? { player.currentTrack }

    private var glowColor: Color {
        track?.artworkImage?.dominantColor() ?? AppTheme.accent
    }

    var body: some View {
        @Bindable var player = player

        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                dragHandle
                header
                if track?.hasLyrics == true {
                    modePicker
                }
                Spacer(minLength: 8)
                centerContent
                Spacer(minLength: 12)
                trackInfo
                progressSection
                controlsSection
                bottomActions
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .offset(y: dismissDragOffset)
        .opacity(1 - min(dismissDragOffset / 400, 0.35))
        .dragToDismiss(dragOffset: $dismissDragOffset) {
            player.showNowPlaying = false
        }
        .sheet(isPresented: $showQueue) {
            QueueSheet()
        }
        .sheet(isPresented: $showAddToPlaylist) {
            if let track {
                AddToPlaylistSheet(track: track)
            }
        }
        .onChange(of: track?.id) { _, _ in
            loadLyrics()
            displayMode = track?.hasLyrics == true ? displayMode : .artwork
        }
        .onAppear { loadLyrics() }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(AppTheme.textTertiary.opacity(0.5))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 4)
    }

    private var backgroundLayer: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            if let image = track?.artworkImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 80)
                    .scaleEffect(1.2)
                    .opacity(0.45)
                    .ignoresSafeArea()
            }
            glowColor.opacity(colorScheme == .dark ? 0.18 : 0.12).ignoresSafeArea()
            LinearGradient(
                colors: [
                    .clear,
                    AppTheme.background.opacity(colorScheme == .dark ? 0.92 : 0.88),
                    AppTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.tap()
                player.showNowPlaying = false
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            if let track {
                FavoriteButton(track: track, size: 20)
                    .frame(width: 44, height: 44)
                Button { showAddToPlaylist = true } label: {
                    Image(systemName: "text.badge.plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
            Button { showQueue = true } label: {
                Image(systemName: "list.bullet")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var modePicker: some View {
        Picker("显示", selection: $displayMode) {
            ForEach(NowPlayingDisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
        .onChange(of: displayMode) { _, _ in Haptics.select() }
    }

    @ViewBuilder
    private var centerContent: some View {
        Group {
        switch displayMode {
        case .artwork:
            artworkSection
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
        case .lyrics:
            if let parsedLyrics {
                LyricsScrollView(
                    lyrics: parsedLyrics,
                    currentTime: player.currentTime,
                    accent: glowColor
                )
                .frame(maxHeight: 340)
                .transition(.opacity)
            } else {
                lyricsPlaceholder
            }
        }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: displayMode)
    }

    private var artworkSection: some View {
        ArtworkThumbnail(image: track?.artworkImage, size: nil)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: glowColor.opacity(0.35), radius: 40, y: 20)
            .padding(.horizontal, 8)
            .onTapGesture(count: 2) {
                if track?.hasLyrics == true {
                    withAnimation(.spring(response: 0.35)) {
                        displayMode = .lyrics
                    }
                }
            }
    }

    private var lyricsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.textTertiary)
            Text("未找到歌词")
                .foregroundStyle(AppTheme.textSecondary)
            Text("将同名 .lrc 文件与歌曲一起导入")
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: 280)
    }

    private var trackInfo: some View {
        VStack(spacing: 8) {
            Text(track?.title ?? "")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            HStack(spacing: 6) {
                Text(track?.displayArtist ?? "")
                if track?.hasLyrics == true {
                    Image(systemName: "text.quote")
                        .font(.caption2)
                        .foregroundStyle(glowColor)
                }
            }
            .font(.body)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.bottom, 16)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isDraggingSlider ? dragValue : player.currentTime },
                    set: { newValue in
                        dragValue = newValue
                        if !isDraggingSlider { player.seek(to: newValue) }
                    }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    isDraggingSlider = editing
                    if editing { Haptics.select() }
                    if !editing { player.seek(to: dragValue) }
                }
            )
            .tint(glowColor)

            HStack {
                Text(formatDuration(isDraggingSlider ? dragValue : player.currentTime))
                Spacer()
                if player.playbackRate != 1 {
                    Text(String(format: "%.2g×", player.playbackRate))
                        .foregroundStyle(glowColor)
                }
                Text(formatDuration(player.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 36) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundStyle(player.isShuffled ? glowColor : AppTheme.textTertiary)
            }

            Button { player.skipBackward() } label: {
                Image(systemName: "backward.fill")
                    .font(.title)
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        AppTheme.textPrimary,
                        glowColor.opacity(colorScheme == .dark ? 0.5 : 0.35)
                    )
            }

            Button { player.skipForward() } label: {
                Image(systemName: "forward.fill")
                    .font(.title)
            }

            Button { player.cycleRepeatMode() } label: {
                Image(systemName: player.repeatMode.icon)
                    .font(.title3)
                    .foregroundStyle(player.repeatMode != .off ? glowColor : AppTheme.textTertiary)
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.vertical, 24)
    }

    private var bottomActions: some View {
        HStack {
            if let remaining = player.sleepTimerRemaining {
                Label(formatDuration(remaining), systemImage: "moon.zzz.fill")
                    .font(.caption)
                    .foregroundStyle(glowColor)
            } else {
                Image(systemName: "hifispeaker")
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
            Text(player.repeatMode.label)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private func loadLyrics() {
        guard let track else {
            parsedLyrics = nil
            return
        }
        parsedLyrics = library.loadLyrics(for: track)
    }
}

struct QueueSheet: View {
    @Environment(AudioPlayerManager.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(player.queue.enumerated()), id: \.element.id) { index, track in
                    HStack(spacing: 12) {
                        if index == player.queueIndex {
                            Image(systemName: "waveform")
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 20)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(AppTheme.textTertiary)
                                .frame(width: 20)
                        }
                        TrackRow(track: track)
                    }
                    .listRowBackground(
                        index == player.queueIndex ? AppTheme.accentMuted.opacity(0.15) : AppTheme.background
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.tap()
                        player.play(tracks: player.queue, startingAt: index)
                    }
                }
                .onMove(perform: player.moveQueue)
                .onDelete(perform: player.removeFromQueue)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("播放队列")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

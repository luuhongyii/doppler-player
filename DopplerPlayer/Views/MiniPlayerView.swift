import SwiftUI

struct MiniPlayerView: View {
    @Environment(AudioPlayerManager.self) private var player

    private var accentFromArt: Color {
        player.currentTrack?.artworkImage?.dominantColor() ?? AppTheme.accent
    }

    var body: some View {
        if let track = player.currentTrack {
            VStack(spacing: 0) {
                ProgressView(value: progress)
                    .tint(accentFromArt)
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)

                HStack(spacing: 12) {
                    ArtworkThumbnail(image: track.artworkImage, size: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(track.displayArtist)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Button { player.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.body)
                    }
                    .foregroundStyle(AppTheme.textPrimary)

                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                    }
                    .foregroundStyle(AppTheme.textPrimary)

                    Button { player.skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.body)
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background {
                BlurBackdrop(color: AppTheme.surface)
            }
            .contentShape(Rectangle())
            .onTapGesture { player.showNowPlaying = true }
        }
    }

    private var progress: Double {
        guard player.duration > 0 else { return 0 }
        return min(1, max(0, player.currentTime / player.duration))
    }
}

import SwiftUI

struct SettingsView: View {
    @Environment(LibraryManager.self) private var library
    @Environment(PlaylistStore.self) private var playlists
    @Environment(AudioPlayerManager.self) private var player
    @Environment(ThemeManager.self) private var theme

    private let speedOptions: [(label: String, rate: Float)] = [
        ("0.75×", 0.75), ("1×", 1), ("1.25×", 1.25), ("1.5×", 1.5), ("2×", 2)
    ]

    private let sleepOptions: [(label: String, minutes: Int?)] = [
        ("关闭", nil), ("15 分钟", 15), ("30 分钟", 30), ("45 分钟", 45), ("60 分钟", 60)
    ]

    var body: some View {
        @Bindable var player = player
        @Bindable var theme = theme

        NavigationStack {
            List {
                Section("外观") {
                    Picker("主题", selection: $theme.appearance) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("播放") {
                    Picker("播放速度", selection: $player.playbackRate) {
                        ForEach(speedOptions, id: \.rate) { option in
                            Text(option.label).tag(option.rate)
                        }
                    }

                    Picker("睡眠定时", selection: Binding(
                        get: { player.sleepTimerMinutes },
                        set: { player.setSleepTimer(minutes: $0) }
                    )) {
                        ForEach(sleepOptions, id: \.label) { option in
                            Text(option.label).tag(option.minutes)
                        }
                    }

                    if let remaining = player.sleepTimerRemaining {
                        HStack {
                            Text("剩余时间")
                            Spacer()
                            Text(formatDuration(remaining))
                                .monospacedDigit()
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }

                Section("体验") {
                    Toggle("触觉反馈", isOn: Binding(
                        get: { Haptics.enabled },
                        set: { Haptics.enabled = $0 }
                    ))
                }

                Section("资料库") {
                    LabeledContent("歌曲", value: "\(library.tracks.count)")
                    LabeledContent("专辑", value: "\(library.albums.count)")
                    LabeledContent("收藏", value: "\(playlists.favoritesCount)")
                    LabeledContent("播放列表", value: "\(playlists.playlists.count)")
                    LabeledContent("含歌词", value: "\(library.tracksWithLyricsCount)")

                    Button("重新匹配歌词文件") {
                        library.rescanLyricsAssociations()
                    }

                    Button("重新扫描资料库", role: .destructive) {
                        Task { await library.rescanMusicFolder() }
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.3")
                    Text("Doppler Player 为本地音乐播放器学习项目，与官方 Doppler 无关联。")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("设置")
        }
    }
}

import SwiftUI

struct LyricsScrollView: View {
    let lyrics: ParsedLyrics
    let currentTime: TimeInterval
    var accent: Color = AppTheme.accent

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if lyrics.lines.isEmpty {
                        Text("暂无歌词")
                            .foregroundStyle(AppTheme.textTertiary)
                            .padding(.top, 40)
                    } else {
                        ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                            Text(line.text)
                                .font(index == activeIndex ? .title3.weight(.bold) : .body)
                                .foregroundStyle(
                                    index == activeIndex ? AppTheme.textPrimary : AppTheme.textTertiary
                                )
                                .multilineTextAlignment(.center)
                                .scaleEffect(index == activeIndex ? 1.02 : 1)
                                .animation(.easeOut(duration: 0.2), value: activeIndex)
                                .id(index)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 24)
            }
            .onChange(of: currentTime) { _, _ in
                guard lyrics.isSynced, let index = activeIndex else { return }
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(index, anchor: .center)
                }
            }
            .onAppear {
                if let activeIndex {
                    proxy.scrollTo(activeIndex, anchor: .center)
                }
            }
        }
    }

    private var activeIndex: Int? {
        lyrics.line(at: currentTime)
    }
}

import SwiftUI
import UIKit

struct ArtworkThumbnail: View {
    let image: UIImage?
    var size: CGFloat? = 56

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            AppTheme.surfaceElevated,
                            AppTheme.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: (size ?? 56) * 0.32, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }
}

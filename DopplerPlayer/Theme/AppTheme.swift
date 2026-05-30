import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.29)

    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
            : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
    })

    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1)
    })

    static let surfaceElevated = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1)
            : UIColor(red: 0.88, green: 0.88, blue: 0.90, alpha: 1)
    })

    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : UIColor(white: 0.08, alpha: 1)
    })

    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.55)
            : UIColor.black.withAlphaComponent(0.52)
    })

    static let textTertiary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.32)
            : UIColor.black.withAlphaComponent(0.35)
    })

    static let divider = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })

    static let accentMuted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.42, blue: 0.29, alpha: 0.35)
            : UIColor(red: 1.0, green: 0.42, blue: 0.29, alpha: 0.22)
    })

    static let cornerRadius: CGFloat = 14
    static let artworkCorner: CGFloat = 12
    static let miniPlayerHeight: CGFloat = 64
}

struct BlurBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    var color: Color = AppTheme.background

    var body: some View {
        Rectangle()
            .fill(color.opacity(colorScheme == .dark ? 0.85 : 0.92))
            .background(.ultraThinMaterial)
            .ignoresSafeArea()
    }
}

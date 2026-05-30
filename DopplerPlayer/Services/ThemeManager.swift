import Observation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@Observable
final class ThemeManager {
    var appearance: AppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "appearanceMode"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let mode = AppearanceMode(rawValue: raw) {
            appearance = mode
        } else {
            appearance = .system
        }
    }

    var preferredColorScheme: ColorScheme? {
        appearance.colorScheme
    }
}

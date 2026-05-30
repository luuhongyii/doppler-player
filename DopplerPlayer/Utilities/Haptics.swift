import UIKit

enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let selection = UISelectionFeedbackGenerator()

    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    static func tap() {
        guard enabled else { return }
        light.prepare()
        light.impactOccurred()
    }

    static func impact() {
        guard enabled else { return }
        medium.prepare()
        medium.impactOccurred()
    }

    static func select() {
        guard enabled else { return }
        selection.prepare()
        selection.selectionChanged()
    }
}

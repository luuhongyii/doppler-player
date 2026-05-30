import SwiftUI
import UIKit

extension UIImage {
    func dominantColor() -> Color {
        guard let cgImage = cgImage else { return AppTheme.accent }
        let size = CGSize(width: 40, height: 40)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let scaled = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = scaled.cgImage?.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else {
            return AppTheme.accent
        }
        let length = CFDataGetLength(data)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        var count: CGFloat = 0
        for i in stride(from: 0, to: length, by: 4) {
            let alpha = ptr[i + 3]
            if alpha < 128 { continue }
            r += CGFloat(ptr[i])
            g += CGFloat(ptr[i + 1])
            b += CGFloat(ptr[i + 2])
            count += 1
        }
        guard count > 0 else { return AppTheme.accent }
        return Color(
            red: Double(r / count / 255),
            green: Double(g / count / 255),
            blue: Double(b / count / 255)
        )
    }
}

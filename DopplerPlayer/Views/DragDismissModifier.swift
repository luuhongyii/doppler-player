import SwiftUI

struct DragToDismissModifier: ViewModifier {
    @Binding var dragOffset: CGFloat
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .offset(y: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .local)
                    .onChanged { value in
                        let dy = value.translation.height
                        if dy > 0 || dragOffset > 0 {
                            dragOffset = max(0, dy)
                        }
                    }
                    .onEnded { value in
                        let shouldDismiss = dragOffset > 120 || value.predictedEndTranslation.height > 200
                        if shouldDismiss {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                dragOffset = 600
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onDismiss()
                                dragOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
    }
}

extension View {
    func dragToDismiss(dragOffset: Binding<CGFloat>, onDismiss: @escaping () -> Void) -> some View {
        modifier(DragToDismissModifier(dragOffset: dragOffset, onDismiss: onDismiss))
    }
}

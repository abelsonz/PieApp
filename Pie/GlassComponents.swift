import SwiftUI

struct LiquidGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial) // The blur effect [cite: 20]
            .background(Color.white.opacity(0.4)) // Extra tint for warmth
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5) // Soft diffuse shadow [cite: 22]
    }
}

extension View {
    func liquidGlass() -> some View {
        self.modifier(LiquidGlass())
    }
}

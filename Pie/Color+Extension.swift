import SwiftUI

// MARK: - Brand Colors
extension Color {
    // Primary (The Crust): Warm Golden Orange
    static let pieCrust = Color(hex: "f59e0b") // [cite: 10]
    
    // Background (The Cream): Warm Off-White/Vanilla
    static let pieCream = Color(hex: "fffbf0") // [cite: 11]
    
    // Text (The Coffee): Deep Warm Brown
    static let pieCoffee = Color(hex: "451a03") // [cite: 12]
    
    // Secondary/Glass: Translucent White
    static let pieGlass = Color.white.opacity(0.6) // [cite: 13]
    
    // Avatars (The Fruit) [cite: 14, 15]
    struct Fruit {
        static let cherry = Color(hex: "ef4444")
        static let blueberry = Color(hex: "3b82f6")
        static let keyLime = Color(hex: "84cc16")
        static let plum = Color(hex: "a855f7")
    }
}

// MARK: - Hex Helper
// This allows you to use hex codes directly in SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography Modifier
// Applies the "Rounded" design to match the Pie circle theme
struct PieFont: ViewModifier {
    var style: Font.TextStyle
    var weight: Font.Weight = .regular

    func body(content: Content) -> some View {
        content
            .font(.system(style, design: .rounded)) // Uses Apple's SF Rounded
            .foregroundColor(.pieCoffee) // Default text color [cite: 12]
    }
}

extension View {
    func pieFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        self.modifier(PieFont(style: style, weight: weight))
    }
}

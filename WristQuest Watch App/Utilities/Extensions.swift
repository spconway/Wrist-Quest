import Foundation
import SwiftUI

extension Color {
    // These colors are now defined in WQDesignSystem, removing duplicates
    
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

extension View {
    func heroClassGradient(for heroClass: HeroClass) -> some View {
        self.background(
            LinearGradient(
                colors: heroClass.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    func questProgressStyle() -> some View {
        self
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    func pixelBorder(width: CGFloat = 2) -> some View {
        self.overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: width)
                .mask(
                    Rectangle()
                        .cornerRadius(0)
                )
        )
    }
}

extension HeroClass {
    var gradientColors: [Color] {
        switch self {
        case .warrior:
            return [.questRed, .orange]
        case .mage:
            return [.questBlue, .questPurple]
        case .rogue:
            return [.gray, .black]
        case .ranger:
            return [.questGreen, .yellow]
        case .cleric:
            return [.white, .questBlue]
        }
    }
}

extension Rarity {
    var color: Color {
        Color(hex: colorHex)
    }
}

extension Double {
    func formatted(decimalPlaces: Int = 1) -> String {
        return String(format: "%.\(decimalPlaces)f", self)
    }
}

extension Int {
    func abbreviated() -> String {
        let number = Double(self)
        switch number {
        case 1_000_000...:
            return "\((number / 1_000_000).formatted(decimalPlaces: 1))M"
        case 1_000...:
            return "\((number / 1_000).formatted(decimalPlaces: 1))K"
        default:
            return "\(self)"
        }
    }
}

extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
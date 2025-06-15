import SwiftUI

// MARK: - Design System
struct WQDesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primaryBackground = Color.black
        static let secondaryBackground = Color(white: 0.1)
        static let tertiaryBackground = Color(white: 0.2)
        
        // Text colors  
        static let primaryText = Color.white
        static let secondaryText = Color(white: 0.7)
        static let tertiaryText = Color(white: 0.5)
        
        // Accent colors
        static let accent = Color.blue
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let border = Color(white: 0.3)
        
        // Additional colors for complications
        static let backgroundSecondary = secondaryBackground
        static let questGold = Color.yellow
        static let primary = accent
        
        // Quest colors
        static let questGreen = Color(red: 0.2, green: 0.7, blue: 0.2)
        static let questBlue = Color(red: 0.2, green: 0.5, blue: 0.8)
        static let questPurple = Color(red: 0.6, green: 0.2, blue: 0.8)
        static let questOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
        static let questRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let footnote = Font.footnote
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
    }
    
    // MARK: - Animations
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Common UI Components

struct WQCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(WQDesignSystem.Spacing.md)
            .background(WQDesignSystem.Colors.secondaryBackground)
            .cornerRadius(WQDesignSystem.CornerRadius.lg)
    }
}

struct WQButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, tertiary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return WQDesignSystem.Colors.accent
            case .secondary: return WQDesignSystem.Colors.secondaryBackground
            case .tertiary: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return WQDesignSystem.Colors.primaryText
            case .tertiary: return WQDesignSystem.Colors.accent
            }
        }
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            print("🎮 WQButton: Button '\(title)' tapped")
            action()
        }) {
            HStack(spacing: WQDesignSystem.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(WQDesignSystem.Typography.body)
            }
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, WQDesignSystem.Spacing.md)
            .padding(.vertical, WQDesignSystem.Spacing.sm)
            .background(style.backgroundColor)
            .cornerRadius(WQDesignSystem.CornerRadius.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(WQDesignSystem.Animation.fast, value: configuration.isPressed)
    }
}

struct WQProgressBar: View {
    let progress: Double
    let color: Color
    let height: CGFloat
    
    init(progress: Double, color: Color = WQDesignSystem.Colors.accent, height: CGFloat = 8) {
        self.progress = max(0, min(1, progress))
        self.color = color
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(WQDesignSystem.Colors.tertiaryBackground)
                    .frame(height: height)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: height)
                    .animation(WQDesignSystem.Animation.medium, value: progress)
            }
        }
        .frame(height: height)
        .cornerRadius(height / 2)
    }
}

struct WQLoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: WQDesignSystem.Colors.accent))
                .scaleEffect(1.2)
            
            Text(message)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WQDesignSystem.Colors.primaryBackground)
    }
}

struct WQErrorView: View {
    let message: String
    let action: (() -> Void)?
    
    init(message: String, action: (() -> Void)? = nil) {
        self.message = message
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(WQDesignSystem.Colors.error)
            
            Text("Error")
                .font(WQDesignSystem.Typography.headline)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text(message)
                .font(WQDesignSystem.Typography.body)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let action = action {
                WQButton("OK", action: action)
            }
        }
        .padding(WQDesignSystem.Spacing.lg)
        .background(WQDesignSystem.Colors.primaryBackground)
    }
}

struct WQStatDisplay: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: WQDesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(WQDesignSystem.Colors.accent)
            
            Text(value)
                .font(WQDesignSystem.Typography.caption)
                .foregroundColor(WQDesignSystem.Colors.primaryText)
            
            Text(title)
                .font(WQDesignSystem.Typography.footnote)
                .foregroundColor(WQDesignSystem.Colors.secondaryText)
        }
    }
}

struct WQHeroClassCard: View {
    let heroClass: HeroClass
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: WQDesignSystem.Spacing.sm) {
                Image(systemName: heroClass.iconName)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: heroClass.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(WQDesignSystem.CornerRadius.md)
                
                Text(heroClass.displayName)
                    .font(WQDesignSystem.Typography.caption)
                    .foregroundColor(WQDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(WQDesignSystem.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? 
                WQDesignSystem.Colors.accent.opacity(0.2) : 
                WQDesignSystem.Colors.secondaryBackground
            )
            .cornerRadius(WQDesignSystem.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: WQDesignSystem.CornerRadius.lg)
                    .stroke(
                        isSelected ? WQDesignSystem.Colors.accent : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
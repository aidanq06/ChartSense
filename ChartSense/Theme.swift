//
//  Theme.swift
//  ChartSense
//
//  Created by Aidan Quach on 7/22/25.
//

import SwiftUI
import UIKit

// MARK: - Color Extensions
extension Color {
    static var bullish: Color {
        ThemeManager.shared.isDarkMode ? AppTheme.dark.colors.bullish : AppTheme.light.colors.bullish
    }
    
    static var bearish: Color {
        ThemeManager.shared.isDarkMode ? AppTheme.dark.colors.bearish : AppTheme.light.colors.bearish
    }
    
    // Support for string-based color names used in sentiment analysis
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "green":
            self = Color.bullish
        case "red":
            self = Color.bearish
        case "lightgreen":
            self = Color.bullish.opacity(0.7)
        case "orange":
            self = Color.orange
        case "blue":
            self = Color.blue
        case "purple":
            self = Color.purple
        case "indigo":
            self = Color.indigo
        case "cyan":
            self = Color.cyan
        case "brown":
            self = Color.brown
        case "gray":
            self = Color.gray
        default:
            self = Color.gray
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    static let shared = ThemeManager()
    
    private init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
}

// MARK: - App Theme
struct AppTheme {
    let colors: ColorScheme
    let typography: Typography
    let spacing: Spacing
    let cornerRadius: CornerRadius
    let shadows: Shadows
    
    static let light = AppTheme(
        colors: .light,
        typography: Typography(),
        spacing: Spacing(),
        cornerRadius: CornerRadius(),
        shadows: .light
    )
    
    static let dark = AppTheme(
        colors: .dark,
        typography: Typography(),
        spacing: Spacing(),
        cornerRadius: CornerRadius(),
        shadows: .dark
    )
}

// MARK: - Color Scheme
struct ColorScheme {
    // Background Colors
    let background: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let cardBackground: Color
    let modalBackground: Color
    
    // Text Colors
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let placeholderText: Color
    
    // Accent Colors
    let primary: Color
    let secondary: Color
    let accent: Color
    
    // Semantic Colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // Interactive Colors
    let buttonPrimary: Color
    let buttonSecondary: Color
    let buttonDisabled: Color
    
    // Border Colors
    let border: Color
    let divider: Color
    
    // Chart Colors
    let bullish: Color
    let bearish: Color
    let neutral: Color
    
    static let light = ColorScheme(
        background: Color(hex: "FFFFFF"),
        secondaryBackground: Color(hex: "F8F9FA"),
        tertiaryBackground: Color(hex: "F1F3F4"),
        cardBackground: Color(hex: "FFFFFF"),
        modalBackground: Color(hex: "FFFFFF"),
        primaryText: Color(hex: "1F2937"),
        secondaryText: Color(hex: "6B7280"),
        tertiaryText: Color(hex: "9CA3AF"),
        placeholderText: Color(hex: "D1D5DB"),
        primary: Color(hex: "3B82F6"),
        secondary: Color(hex: "6366F1"),
        accent: Color(hex: "10B981"),
        success: Color(hex: "10B981"),
        warning: Color(hex: "F59E0B"),
        error: Color(hex: "EF4444"),
        info: Color(hex: "3B82F6"),
        buttonPrimary: Color(hex: "3B82F6"),
        buttonSecondary: Color(hex: "F3F4F6"),
        buttonDisabled: Color(hex: "E5E7EB"),
        border: Color(hex: "E5E7EB"),
        divider: Color(hex: "F3F4F6"),
        bullish: Color(hex: "10B981"),
        bearish: Color(hex: "EF4444"),
        neutral: Color(hex: "6B7280")
    )
    
    static let dark = ColorScheme(
        background: Color(hex: "1A1A1A"),
        secondaryBackground: Color(hex: "262626"),
        tertiaryBackground: Color(hex: "404040"),
        cardBackground: Color(hex: "262626"),
        modalBackground: Color(hex: "1A1A1A"),
        primaryText: Color(hex: "FFFFFF"),
        secondaryText: Color(hex: "D4D4D8"),
        tertiaryText: Color(hex: "A1A1AA"),
        placeholderText: Color(hex: "71717A"),
        primary: Color(hex: "60A5FA"),
        secondary: Color(hex: "818CF8"),
        accent: Color(hex: "34D399"),
        success: Color(hex: "34D399"),
        warning: Color(hex: "FBBF24"),
        error: Color(hex: "F87171"),
        info: Color(hex: "60A5FA"),
        buttonPrimary: Color(hex: "60A5FA"),
        buttonSecondary: Color(hex: "404040"),
        buttonDisabled: Color(hex: "525252"),
        border: Color(hex: "525252"),
        divider: Color(hex: "404040"),
        bullish: Color(hex: "34D399"),
        bearish: Color(hex: "F87171"),
        neutral: Color(hex: "A1A1AA")
    )
}

// MARK: - Typography
struct Typography {
    // Title Styles
    let largeTitle: Font = .system(size: 34, weight: .bold, design: .default)
    let title1: Font = .system(size: 28, weight: .bold, design: .default)
    let title2: Font = .system(size: 22, weight: .bold, design: .default)
    let title3: Font = .system(size: 20, weight: .semibold, design: .default)
    
    // Body Styles
    let body: Font = .system(size: 17, weight: .regular, design: .default)
    let bodyMedium: Font = .system(size: 17, weight: .medium, design: .default)
    let bodySemibold: Font = .system(size: 17, weight: .semibold, design: .default)
    
    // Detail Styles
    let callout: Font = .system(size: 16, weight: .regular, design: .default)
    let subheadline: Font = .system(size: 15, weight: .medium, design: .default)
    let footnote: Font = .system(size: 13, weight: .regular, design: .default)
    let caption: Font = .system(size: 12, weight: .regular, design: .default)
    let caption2: Font = .system(size: 11, weight: .regular, design: .default)
    
    // Monospace for numbers
    let numberLarge: Font = .system(size: 24, weight: .bold, design: .monospaced)
    let numberMedium: Font = .system(size: 17, weight: .semibold, design: .monospaced)
    let numberSmall: Font = .system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Spacing
struct Spacing {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
    let xl: CGFloat = 32
    let xxl: CGFloat = 48
}

// MARK: - Corner Radius
struct CornerRadius {
    let small: CGFloat = 6
    let medium: CGFloat = 12
    let large: CGFloat = 16
    let xlarge: CGFloat = 24
    let card: CGFloat = 12
    let button: CGFloat = 8
}

// MARK: - Shadows
struct Shadows {
    let card: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    let button: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    let modal: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    
    static let light = Shadows(
        card: (Color.black.opacity(0.04), 8, 0, 2),
        button: (Color.black.opacity(0.08), 4, 0, 1),
        modal: (Color.black.opacity(0.15), 20, 0, 8)
    )
    
    static let dark = Shadows(
        card: (Color.black.opacity(0.2), 8, 0, 2),
        button: (Color.black.opacity(0.3), 4, 0, 1),
        modal: (Color.black.opacity(0.4), 20, 0, 8)
    )
}

// MARK: - Color Extension
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

// MARK: - Environment Extension
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.light
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension for Theme
extension View {
    func themedCard(theme: AppTheme) -> some View {
        self
            .background(theme.colors.cardBackground)
            .cornerRadius(theme.cornerRadius.card)
            .shadow(
                color: theme.shadows.card.color,
                radius: theme.shadows.card.radius,
                x: theme.shadows.card.x,
                y: theme.shadows.card.y
            )
    }
    
    func themedButton(
        style: ButtonStyle = .primary,
        theme: AppTheme,
        disabled: Bool = false
    ) -> some View {
        self
            .foregroundColor(disabled ? theme.colors.tertiaryText : (style == .primary ? .white : theme.colors.primaryText))
            .background(
                disabled ? theme.colors.buttonDisabled :
                (style == .primary ? theme.colors.buttonPrimary : theme.colors.buttonSecondary)
            )
            .cornerRadius(theme.cornerRadius.button)
            .shadow(
                color: disabled ? .clear : theme.shadows.button.color,
                radius: theme.shadows.button.radius,
                x: theme.shadows.button.x,
                y: theme.shadows.button.y
            )
    }
    
    func themedBackground(theme: AppTheme) -> some View {
        self
            .background(theme.colors.background)
    }
    
    func primaryText(theme: AppTheme) -> some View {
        self.foregroundColor(theme.colors.primaryText)
    }
    
    func secondaryText(theme: AppTheme) -> some View {
        self.foregroundColor(theme.colors.secondaryText)
    }
    
    func tertiaryText(theme: AppTheme) -> some View {
        self.foregroundColor(theme.colors.tertiaryText)
    }
}

// MARK: - Button Style Enum
enum ButtonStyle {
    case primary
    case secondary
} 
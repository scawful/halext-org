//
//  Theme.swift
//  Cafe
//
//  Theme definitions and color schemes
//

import SwiftUI

// MARK: - Theme Model

struct Theme: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let accentColor: CodableColor
    let backgroundColor: CodableColor
    let secondaryBackgroundColor: CodableColor
    let textColor: CodableColor
    let secondaryTextColor: CodableColor
    let isDark: Bool

    // Derived colors
    var cardBackgroundColor: Color {
        Color(secondaryBackgroundColor)
    }

    var successColor: Color {
        isDark ? Color.green.opacity(0.8) : Color.green
    }

    var warningColor: Color {
        isDark ? Color.orange.opacity(0.8) : Color.orange
    }

    var errorColor: Color {
        isDark ? Color.red.opacity(0.8) : Color.red
    }
}

// MARK: - Predefined Themes

extension Theme {
    // Light Themes
    static let light = Theme(
        id: "light",
        name: "Light",
        accentColor: CodableColor(Color.blue),
        backgroundColor: CodableColor(Color(.systemBackground)),
        secondaryBackgroundColor: CodableColor(Color(.secondarySystemBackground)),
        textColor: CodableColor(Color.primary),
        secondaryTextColor: CodableColor(Color.secondary),
        isDark: false
    )

    static let ocean = Theme(
        id: "ocean",
        name: "Ocean",
        accentColor: CodableColor(Color(red: 0.0, green: 0.48, blue: 0.8)),
        backgroundColor: CodableColor(Color(red: 0.95, green: 0.97, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.9, green: 0.94, blue: 0.98)),
        textColor: CodableColor(Color(red: 0.1, green: 0.2, blue: 0.3)),
        secondaryTextColor: CodableColor(Color(red: 0.4, green: 0.5, blue: 0.6)),
        isDark: false
    )

    static let forest = Theme(
        id: "forest",
        name: "Forest",
        accentColor: CodableColor(Color(red: 0.2, green: 0.6, blue: 0.3)),
        backgroundColor: CodableColor(Color(red: 0.97, green: 0.98, blue: 0.96)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.93, green: 0.96, blue: 0.92)),
        textColor: CodableColor(Color(red: 0.15, green: 0.25, blue: 0.15)),
        secondaryTextColor: CodableColor(Color(red: 0.4, green: 0.5, blue: 0.4)),
        isDark: false
    )

    static let sunset = Theme(
        id: "sunset",
        name: "Sunset",
        accentColor: CodableColor(Color(red: 1.0, green: 0.4, blue: 0.2)),
        backgroundColor: CodableColor(Color(red: 1.0, green: 0.97, blue: 0.95)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.98, green: 0.93, blue: 0.9)),
        textColor: CodableColor(Color(red: 0.3, green: 0.15, blue: 0.1)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.4, blue: 0.3)),
        isDark: false
    )

    static let pastel = Theme(
        id: "pastel",
        name: "Pastel",
        accentColor: CodableColor(Color(red: 0.8, green: 0.6, blue: 0.9)),
        backgroundColor: CodableColor(Color(red: 0.98, green: 0.96, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.95, green: 0.92, blue: 0.98)),
        textColor: CodableColor(Color(red: 0.2, green: 0.15, blue: 0.25)),
        secondaryTextColor: CodableColor(Color(red: 0.5, green: 0.4, blue: 0.6)),
        isDark: false
    )

    static let cherryBlossom = Theme(
        id: "cherryBlossom",
        name: "Cherry Blossom",
        accentColor: CodableColor(Color(red: 1.0, green: 0.4, blue: 0.6)),
        backgroundColor: CodableColor(Color(red: 1.0, green: 0.95, blue: 0.97)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.98, green: 0.9, blue: 0.94)),
        textColor: CodableColor(Color(red: 0.3, green: 0.1, blue: 0.2)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.3, blue: 0.4)),
        isDark: false
    )

    static let lavender = Theme(
        id: "lavender",
        name: "Lavender",
        accentColor: CodableColor(Color(red: 0.6, green: 0.4, blue: 0.9)),
        backgroundColor: CodableColor(Color(red: 0.97, green: 0.95, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.93, green: 0.9, blue: 0.98)),
        textColor: CodableColor(Color(red: 0.2, green: 0.15, blue: 0.3)),
        secondaryTextColor: CodableColor(Color(red: 0.5, green: 0.4, blue: 0.65)),
        isDark: false
    )

    static let sakura = Theme(
        id: "sakura",
        name: "Sakura",
        accentColor: CodableColor(Color(hex: "#FF69B4")),        // Hot Pink
        backgroundColor: CodableColor(Color(hex: "#FFF0F5")),     // Lavender Blush
        secondaryBackgroundColor: CodableColor(Color(hex: "#FFE4E9")), // Light Pink
        textColor: CodableColor(Color(hex: "#2D1B2E")),           // Dark Purple-Brown
        secondaryTextColor: CodableColor(Color(hex: "#4A2E4D")), // Medium Purple
        isDark: false
    )

    static let mint = Theme(
        id: "mint",
        name: "Mint",
        accentColor: CodableColor(Color(red: 0.2, green: 0.9, blue: 0.7)),
        backgroundColor: CodableColor(Color(red: 0.95, green: 1.0, blue: 0.98)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.9, green: 0.98, blue: 0.95)),
        textColor: CodableColor(Color(red: 0.1, green: 0.3, blue: 0.25)),
        secondaryTextColor: CodableColor(Color(red: 0.3, green: 0.6, blue: 0.5)),
        isDark: false
    )

    static let coral = Theme(
        id: "coral",
        name: "Coral",
        accentColor: CodableColor(Color(red: 1.0, green: 0.5, blue: 0.4)),
        backgroundColor: CodableColor(Color(red: 1.0, green: 0.97, blue: 0.95)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.98, green: 0.93, blue: 0.9)),
        textColor: CodableColor(Color(red: 0.3, green: 0.15, blue: 0.1)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.4, blue: 0.3)),
        isDark: false
    )

    static let autumn = Theme(
        id: "autumn",
        name: "Autumn",
        accentColor: CodableColor(Color(red: 0.9, green: 0.5, blue: 0.2)),
        backgroundColor: CodableColor(Color(red: 0.98, green: 0.95, blue: 0.9)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.95, green: 0.9, blue: 0.85)),
        textColor: CodableColor(Color(red: 0.3, green: 0.2, blue: 0.1)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.45, blue: 0.3)),
        isDark: false
    )

    static let monochromeLight = Theme(
        id: "monochromeLight",
        name: "Monochrome Light",
        accentColor: CodableColor(Color(red: 0.2, green: 0.2, blue: 0.2)),
        backgroundColor: CodableColor(Color(red: 1.0, green: 1.0, blue: 1.0)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.95, green: 0.95, blue: 0.95)),
        textColor: CodableColor(Color(red: 0.1, green: 0.1, blue: 0.1)),
        secondaryTextColor: CodableColor(Color(red: 0.5, green: 0.5, blue: 0.5)),
        isDark: false
    )

    // Dark Themes
    static let dark = Theme(
        id: "dark",
        name: "Dark",
        accentColor: CodableColor(Color.blue),
        backgroundColor: CodableColor(Color(.systemBackground)),
        secondaryBackgroundColor: CodableColor(Color(.secondarySystemBackground)),
        textColor: CodableColor(Color.primary),
        secondaryTextColor: CodableColor(Color.secondary),
        isDark: true
    )

    static let midnight = Theme(
        id: "midnight",
        name: "Midnight",
        accentColor: CodableColor(Color(red: 0.4, green: 0.7, blue: 1.0)),
        backgroundColor: CodableColor(Color(red: 0.05, green: 0.08, blue: 0.12)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.1, green: 0.13, blue: 0.18)),
        textColor: CodableColor(Color(red: 0.9, green: 0.92, blue: 0.95)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.65, blue: 0.7)),
        isDark: true
    )

    static let amoled = Theme(
        id: "amoled",
        name: "AMOLED",
        accentColor: CodableColor(Color(red: 0.0, green: 0.8, blue: 0.4)),
        backgroundColor: CodableColor(Color.black),
        secondaryBackgroundColor: CodableColor(Color(red: 0.05, green: 0.05, blue: 0.05)),
        textColor: CodableColor(Color.white),
        secondaryTextColor: CodableColor(Color(red: 0.7, green: 0.7, blue: 0.7)),
        isDark: true
    )

    static let neon = Theme(
        id: "neon",
        name: "Neon",
        accentColor: CodableColor(Color(red: 0.0, green: 1.0, blue: 0.8)),
        backgroundColor: CodableColor(Color(red: 0.08, green: 0.05, blue: 0.15)),
        secondaryBackgroundColor: CodableColor(Color(red: 0.12, green: 0.08, blue: 0.2)),
        textColor: CodableColor(Color(red: 0.9, green: 0.95, blue: 1.0)),
        secondaryTextColor: CodableColor(Color(red: 0.6, green: 0.7, blue: 0.8)),
        isDark: true
    )

    // All available themes
    static let allThemes: [Theme] = [
        .light, .ocean, .forest, .sunset, .pastel,
        .cherryBlossom, .sakura, .lavender, .mint, .coral, .autumn, .monochromeLight,
        .dark, .midnight, .amoled, .neon
    ]

    static let lightThemes: [Theme] = [
        .light, .ocean, .forest, .sunset, .pastel,
        .cherryBlossom, .sakura, .lavender, .mint, .coral, .autumn, .monochromeLight
    ]

    static let darkThemes: [Theme] = [
        .dark, .midnight, .amoled, .neon
    ]
}

// MARK: - Codable Color

struct CodableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(_ color: Color) {
        // Extract RGB components from Color
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
        #else
        self.red = 0
        self.green = 0
        self.blue = 0
        self.opacity = 1
        #endif
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension Color {
    init(_ codableColor: CodableColor) {
        self.init(red: codableColor.red, green: codableColor.green, blue: codableColor.blue, opacity: codableColor.opacity)
    }
}

// MARK: - Font Size Preference

enum FontSizePreference: String, Codable, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
}

// MARK: - App Icon

enum AppIcon: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case purple = "Purple"
    case red = "Red"
    case minimal = "Minimal"
    case dark = "Dark"

    var id: String { rawValue }

    var iconName: String? {
        self == .default ? nil : "AppIcon-\(rawValue)"
    }

    var displayName: String {
        rawValue
    }
}

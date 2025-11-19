//
//  ThemeCustomization.swift
//  Cafe
//
//  Advanced theme customization options
//

import SwiftUI

// MARK: - Theme Customization

struct ThemeCustomization: Codable, Equatable {
    // Typography
    var fontFamily: FontFamily
    var baseFontSize: CGFloat
    var fontWeight: FontWeight
    var lineSpacing: CGFloat

    // Spacing
    var compactSpacing: Bool
    var cardPadding: CGFloat
    var sectionSpacing: CGFloat

    // Visual Style
    var cornerRadius: CornerRadiusStyle
    var shadowIntensity: ShadowIntensity
    var blurEffects: Bool

    // Animations
    var animationSpeed: AnimationSpeed
    var reducedMotion: Bool

    // Icons
    var iconStyle: IconStyle
    var iconSize: IconSize

    init(
        fontFamily: FontFamily = .system,
        baseFontSize: CGFloat = 16,
        fontWeight: FontWeight = .regular,
        lineSpacing: CGFloat = 4,
        compactSpacing: Bool = false,
        cardPadding: CGFloat = 16,
        sectionSpacing: CGFloat = 20,
        cornerRadius: CornerRadiusStyle = .medium,
        shadowIntensity: ShadowIntensity = .medium,
        blurEffects: Bool = true,
        animationSpeed: AnimationSpeed = .normal,
        reducedMotion: Bool = false,
        iconStyle: IconStyle = .filled,
        iconSize: IconSize = .medium
    ) {
        self.fontFamily = fontFamily
        self.baseFontSize = baseFontSize
        self.fontWeight = fontWeight
        self.lineSpacing = lineSpacing
        self.compactSpacing = compactSpacing
        self.cardPadding = cardPadding
        self.sectionSpacing = sectionSpacing
        self.cornerRadius = cornerRadius
        self.shadowIntensity = shadowIntensity
        self.blurEffects = blurEffects
        self.animationSpeed = animationSpeed
        self.reducedMotion = reducedMotion
        self.iconStyle = iconStyle
        self.iconSize = iconSize
    }
}

// MARK: - Font Family

enum FontFamily: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case rounded = "Rounded"
    case serif = "Serif"
    case monospaced = "Monospaced"

    var id: String { rawValue }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: weight)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .monospaced:
            return .system(size: size, weight: weight, design: .monospaced)
        }
    }
}

// MARK: - Font Weight

enum FontWeight: String, Codable, CaseIterable, Identifiable {
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"

    var id: String { rawValue }

    var swiftUIWeight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - Corner Radius Style

enum CornerRadiusStyle: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"

    var id: String { rawValue }

    var value: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 4
        case .medium: return 8
        case .large: return 12
        case .extraLarge: return 16
        }
    }

    var buttonRadius: CGFloat {
        switch self {
        case .none: return 0
        case .small: return 6
        case .medium: return 10
        case .large: return 14
        case .extraLarge: return 20
        }
    }
}

// MARK: - Shadow Intensity

enum ShadowIntensity: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case subtle = "Subtle"
    case medium = "Medium"
    case strong = "Strong"

    var id: String { rawValue }

    var radius: CGFloat {
        switch self {
        case .none: return 0
        case .subtle: return 2
        case .medium: return 4
        case .strong: return 8
        }
    }

    var opacity: Double {
        switch self {
        case .none: return 0
        case .subtle: return 0.1
        case .medium: return 0.2
        case .strong: return 0.3
        }
    }
}

// MARK: - Animation Speed

enum AnimationSpeed: String, Codable, CaseIterable, Identifiable {
    case slow = "Slow"
    case normal = "Normal"
    case fast = "Fast"
    case instant = "Instant"

    var id: String { rawValue }

    var duration: Double {
        switch self {
        case .slow: return 0.5
        case .normal: return 0.3
        case .fast: return 0.15
        case .instant: return 0
        }
    }

    var animation: Animation {
        switch self {
        case .slow: return .easeInOut(duration: 0.5)
        case .normal: return .easeInOut(duration: 0.3)
        case .fast: return .easeInOut(duration: 0.15)
        case .instant: return .linear(duration: 0)
        }
    }
}

// MARK: - Icon Style

enum IconStyle: String, Codable, CaseIterable, Identifiable {
    case outlined = "Outlined"
    case filled = "Filled"

    var id: String { rawValue }

    func systemName(for baseName: String) -> String {
        switch self {
        case .outlined:
            return baseName
        case .filled:
            return baseName.contains(".fill") ? baseName : "\(baseName).fill"
        }
    }
}

// MARK: - Icon Size

enum IconSize: String, Codable, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var size: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    var font: Font {
        switch self {
        case .small: return .system(size: 16)
        case .medium: return .system(size: 20)
        case .large: return .system(size: 24)
        }
    }
}

// MARK: - View Modifiers

extension View {
    func themedCard(customization: ThemeCustomization, theme: Theme) -> some View {
        self
            .padding(customization.cardPadding)
            .background(theme.cardBackgroundColor)
            .cornerRadius(customization.cornerRadius.value)
            .shadow(
                radius: customization.shadowIntensity.radius,
                y: customization.shadowIntensity.radius / 2
            )
    }

    func themedButton(customization: ThemeCustomization) -> some View {
        self
            .padding(.horizontal, customization.compactSpacing ? 12 : 16)
            .padding(.vertical, customization.compactSpacing ? 8 : 12)
            .cornerRadius(customization.cornerRadius.buttonRadius)
    }

    func themedAnimation(_ trigger: some Equatable, customization: ThemeCustomization) -> some View {
        self.animation(
            customization.reducedMotion ? nil : customization.animationSpeed.animation,
            value: trigger
        )
    }
}

// MARK: - Default Customization

extension ThemeCustomization {
    static let `default` = ThemeCustomization()

    static let compact = ThemeCustomization(
        compactSpacing: true,
        cardPadding: 12,
        sectionSpacing: 16
    )

    static let spacious = ThemeCustomization(
        cardPadding: 20,
        sectionSpacing: 28,
        cornerRadius: .large
    )

    static let minimal = ThemeCustomization(
        cornerRadius: .none,
        shadowIntensity: .none,
        blurEffects: false,
        iconStyle: .outlined
    )

    static let bold = ThemeCustomization(
        fontWeight: .bold,
        cornerRadius: .extraLarge,
        shadowIntensity: .strong,
        iconStyle: .filled
    )
}

//
//  ThemeManager.swift
//  Cafe
//
//  Manages app theme and appearance settings
//

import SwiftUI
import Combine

@MainActor
@Observable
class ThemeManager {
    static let shared = ThemeManager()

    // MARK: - Properties

    var currentTheme: Theme {
        didSet {
            saveTheme()
            applyTheme()
        }
    }

    var appearanceMode: AppearanceMode {
        didSet {
            saveAppearanceMode()
            updateThemeForAppearance()
        }
    }

    var fontSizePreference: FontSizePreference {
        didSet {
            saveFontSize()
        }
    }

    var selectedAppIcon: AppIcon {
        didSet {
            saveAppIcon()
            applyAppIcon()
        }
    }

    var customization: ThemeCustomization {
        didSet {
            saveCustomization()
        }
    }
    
    var customBackground: CustomBackground {
        didSet {
            saveCustomBackground()
        }
    }
    
    var perViewBackgrounds: [String: CustomBackground] = [:] {
        didSet {
            savePerViewBackgrounds()
        }
    }

    // Private storage
    private let defaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    private let appearanceModeKey = "appearanceMode"
    private let fontSizeKey = "fontSizePreference"
    private let appIconKey = "selectedAppIcon"
    private let customizationKey = "themeCustomization"
    private let customBackgroundKey = "customBackground"
    private let perViewBackgroundsKey = "perViewBackgrounds"

    // MARK: - Initialization

    private init() {
        // Load saved theme
        if let savedThemeId = defaults.string(forKey: themeKey),
           let theme = Theme.allThemes.first(where: { $0.id == savedThemeId }) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .light
        }

        // Load appearance mode
        if let savedMode = defaults.string(forKey: appearanceModeKey),
           let mode = AppearanceMode(rawValue: savedMode) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .auto
        }

        // Load font size
        if let savedSize = defaults.string(forKey: fontSizeKey),
           let size = FontSizePreference(rawValue: savedSize) {
            self.fontSizePreference = size
        } else {
            self.fontSizePreference = .medium
        }

        // Load app icon
        if let savedIcon = defaults.string(forKey: appIconKey),
           let icon = AppIcon(rawValue: savedIcon) {
            self.selectedAppIcon = icon
        } else {
            self.selectedAppIcon = .default
        }

        // Load customization
        if let savedData = defaults.data(forKey: customizationKey),
           let customization = try? JSONDecoder().decode(ThemeCustomization.self, from: savedData) {
            self.customization = customization
        } else {
            self.customization = .default
        }
        
        // Load custom background
        if let savedData = defaults.data(forKey: customBackgroundKey),
           let background = try? JSONDecoder().decode(CustomBackground.self, from: savedData) {
            self.customBackground = background
        } else {
            self.customBackground = .default
        }
        
        // Load per-view backgrounds
        if let savedData = defaults.data(forKey: perViewBackgroundsKey),
           let backgrounds = try? JSONDecoder().decode([String: CustomBackground].self, from: savedData) {
            self.perViewBackgrounds = backgrounds
        } else {
            self.perViewBackgrounds = [:]
        }

        applyTheme()
    }

    // MARK: - Theme Management

    func setTheme(_ theme: Theme) {
        currentTheme = theme
    }

    func setCustomAccentColor(_ color: Color) {
        var customTheme = currentTheme
        customTheme = Theme(
            id: "custom-\(UUID().uuidString)",
            name: "Custom",
            accentColor: CodableColor(color),
            backgroundColor: currentTheme.backgroundColor,
            secondaryBackgroundColor: currentTheme.secondaryBackgroundColor,
            textColor: currentTheme.textColor,
            secondaryTextColor: currentTheme.secondaryTextColor,
            isDark: currentTheme.isDark
        )
        currentTheme = customTheme
    }

    private func updateThemeForAppearance() {
        switch appearanceMode {
        case .light:
            if currentTheme.isDark {
                currentTheme = .light
            }
        case .dark:
            if !currentTheme.isDark {
                currentTheme = .dark
            }
        case .auto:
            // Will be handled by system
            break
        }
    }

    // MARK: - Persistence

    private func saveTheme() {
        defaults.set(currentTheme.id, forKey: themeKey)
    }

    private func saveAppearanceMode() {
        defaults.set(appearanceMode.rawValue, forKey: appearanceModeKey)
    }

    private func saveFontSize() {
        defaults.set(fontSizePreference.rawValue, forKey: fontSizeKey)
    }

    private func saveAppIcon() {
        defaults.set(selectedAppIcon.rawValue, forKey: appIconKey)
    }

    private func saveCustomization() {
        if let data = try? JSONEncoder().encode(customization) {
            defaults.set(data, forKey: customizationKey)
        }
    }
    
    private func saveCustomBackground() {
        if let data = try? JSONEncoder().encode(customBackground) {
            defaults.set(data, forKey: customBackgroundKey)
        }
    }
    
    private func savePerViewBackgrounds() {
        if let data = try? JSONEncoder().encode(perViewBackgrounds) {
            defaults.set(data, forKey: perViewBackgroundsKey)
        }
    }
    
    // MARK: - Background Management
    
    func setBackgroundForView(viewId: String, background: CustomBackground) {
        perViewBackgrounds[viewId] = background
    }
    
    func getBackgroundForView(viewId: String) -> CustomBackground? {
        return perViewBackgrounds[viewId]
    }
    
    func clearBackgroundForView(viewId: String) {
        perViewBackgrounds.removeValue(forKey: viewId)
    }

    // MARK: - Apply Changes

    private func applyTheme() {
        // Update color scheme if needed
        NotificationCenter.default.post(name: .themeChanged, object: nil)
    }

    private func applyAppIcon() {
        #if !targetEnvironment(simulator)
        UIApplication.shared.setAlternateIconName(selectedAppIcon.iconName) { error in
            if let error = error {
                print("❌ Failed to change app icon: \(error.localizedDescription)")
            } else {
                print("✅ App icon changed to: \(self.selectedAppIcon.displayName)")
            }
        }
        #else
        print("⚠️ App icon changes not supported in Simulator")
        #endif
    }

    // MARK: - Computed Properties

    var accentColor: Color {
        Color(currentTheme.accentColor)
    }

    var backgroundColor: Color {
        Color(currentTheme.backgroundColor)
    }

    var backgroundStyle: AnyShapeStyle {
        // Use custom background if set, otherwise use theme gradient or solid color
        switch customBackground.style {
        case .gradient:
            if let gradient = customBackground.gradient {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color(gradient.startColor),
                            Color(gradient.endColor)
                        ],
                        startPoint: gradient.startPoint.unitPoint,
                        endPoint: gradient.endPoint.unitPoint
                    )
                )
            }
        case .solid:
            if let color = customBackground.solidColor {
                return AnyShapeStyle(Color(color))
            }
        default:
            break
        }
        
        // Fall back to theme background
        if let gradient = currentTheme.backgroundGradient {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(gradient.startColor),
                        Color(gradient.endColor)
                    ],
                    startPoint: gradient.startPoint.unitPoint,
                    endPoint: gradient.endPoint.unitPoint
                )
            )
        }
        return AnyShapeStyle(Color(currentTheme.backgroundColor))
    }
    
    func backgroundStyleForView(viewId: String) -> CustomBackground {
        if let viewBackground = getBackgroundForView(viewId: viewId) {
            return viewBackground
        }
        return customBackground
    }

    var secondaryBackgroundColor: Color {
        Color(currentTheme.secondaryBackgroundColor)
    }

    var textColor: Color {
        Color(currentTheme.textColor)
    }

    var secondaryTextColor: Color {
        Color(currentTheme.secondaryTextColor)
    }

    var cardBackgroundColor: Color {
        currentTheme.cardBackgroundColor
    }

    var successColor: Color {
        currentTheme.successColor
    }

    var warningColor: Color {
        currentTheme.warningColor
    }

    var errorColor: Color {
        currentTheme.errorColor
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
}

// MARK: - View Extension for Theme

extension View {
    func themedBackground() -> some View {
        self.background(ThemeManager.shared.backgroundStyle)
    }
    
    func themedBackground(viewId: String) -> some View {
        let background = ThemeManager.shared.backgroundStyleForView(viewId: viewId)
        return self.customBackground(background)
    }

    func themedCard() -> some View {
        self
            .background(ThemeManager.shared.cardBackgroundColor)
            .cornerRadius(12)
    }

    func themedCardBackground(cornerRadius: CGFloat = 16, shadow: Bool = true, useGradient: Bool = false) -> some View {
        self.background(
            Group {
                if useGradient {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ThemeManager.shared.cardBackgroundColor,
                                    ThemeManager.shared.cardBackgroundColor.opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: shadow ? .black.opacity(0.08) : .clear, radius: shadow ? 12 : 0, y: shadow ? 4 : 0)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(ThemeManager.shared.cardBackgroundColor)
                        .shadow(color: shadow ? .black.opacity(0.05) : .clear, radius: 8, y: 2)
                }
            }
        )
    }

    func themedText() -> some View {
        self.foregroundColor(ThemeManager.shared.textColor)
    }

    func themedSecondaryText() -> some View {
        self.foregroundColor(ThemeManager.shared.secondaryTextColor)
    }

    func scaledFont(_ baseSize: CGFloat, weight: Font.Weight = .regular) -> some View {
        let scale = ThemeManager.shared.fontSizePreference.scale
        return self.font(.system(size: baseSize * scale, weight: weight))
    }
    
    /// Applies a themed button style with gradient support
    func themedButton(style: ThemedButtonStyle = .primary, cornerRadius: CGFloat = 12, useGradient: Bool = false) -> some View {
        self.modifier(ThemedButtonModifier(style: style, cornerRadius: cornerRadius, useGradient: useGradient))
    }
    
    /// Applies a themed card style with consistent styling
    func themedCardStyle(cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .themedCardBackground(cornerRadius: cornerRadius, shadow: true)
    }
    
    /// Applies a themed section header style
    func themedSectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(ThemeManager.shared.textColor)
            .padding(.horizontal, 4)
    }
    
    /// Applies a themed list row style
    func themedListRow() -> some View {
        self
            .listRowBackground(ThemeManager.shared.cardBackgroundColor)
    }
    
    /// Applies a themed icon style with consistent sizing
    func themedIcon(size: CGFloat = 20, color: Color? = nil) -> some View {
        self
            .font(.system(size: size))
            .foregroundColor(color ?? ThemeManager.shared.accentColor)
    }
}

// MARK: - Themed Button Style

enum ThemedButtonStyle {
    case primary
    case secondary
    case outline
    case gradient
}

// MARK: - Themed Button Modifier

struct ThemedButtonModifier: ViewModifier {
    let style: ThemedButtonStyle
    let cornerRadius: CGFloat
    let useGradient: Bool
    @Environment(ThemeManager.self) var themeManager
    
    init(style: ThemedButtonStyle = .primary, cornerRadius: CGFloat = 12, useGradient: Bool = false) {
        self.style = style
        self.cornerRadius = cornerRadius
        self.useGradient = useGradient
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            if useGradient {
                LinearGradient(
                    colors: [
                        themeManager.accentColor,
                        themeManager.accentColor.opacity(0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                themeManager.accentColor
            }
        case .secondary:
            themeManager.cardBackgroundColor
        case .outline:
            Color.clear
        case .gradient:
            LinearGradient(
                colors: [
                    themeManager.accentColor,
                    themeManager.accentColor.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .gradient:
            return .white
        case .secondary, .outline:
            return themeManager.textColor
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary, .gradient:
            return themeManager.accentColor.opacity(0.3)
        default:
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .gradient:
            return 8
        default:
            return 0
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .primary, .gradient:
            return 4
        default:
            return 0
        }
    }
}

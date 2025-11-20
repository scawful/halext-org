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

    // Private storage
    private let defaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    private let appearanceModeKey = "appearanceMode"
    private let fontSizeKey = "fontSizePreference"
    private let appIconKey = "selectedAppIcon"
    private let customizationKey = "themeCustomization"

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
        self.background(ThemeManager.shared.backgroundColor)
    }

    func themedCard() -> some View {
        self
            .background(ThemeManager.shared.cardBackgroundColor)
            .cornerRadius(12)
    }

    func themedCardBackground(cornerRadius: CGFloat = 16, shadow: Bool = true) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(ThemeManager.shared.cardBackgroundColor)
                .shadow(color: shadow ? .black.opacity(0.05) : .clear, radius: 8, y: 2)
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
}

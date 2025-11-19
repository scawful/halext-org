//
//  ThemeSettingsView.swift
//  Cafe
//
//  Theme and appearance customization UI
//

import SwiftUI

struct ThemeSettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var showColorPicker = false
    @State private var customAccentColor: Color = .blue

    var body: some View {
        List {
            // Appearance Mode
            Section {
                Picker("Appearance", selection: $themeManager.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance Mode")
            } footer: {
                Text("Choose how the app adapts to light and dark mode")
            }

            // Light Themes
            if themeManager.appearanceMode != .dark {
                Section {
                    ForEach(Theme.lightThemes) { theme in
                        ThemeRow(theme: theme, isSelected: themeManager.currentTheme.id == theme.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    themeManager.setTheme(theme)
                                }
                            }
                    }
                } header: {
                    Text("Light Themes")
                }
            }

            // Dark Themes
            if themeManager.appearanceMode != .light {
                Section {
                    ForEach(Theme.darkThemes) { theme in
                        ThemeRow(theme: theme, isSelected: themeManager.currentTheme.id == theme.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    themeManager.setTheme(theme)
                                }
                            }
                    }
                } header: {
                    Text("Dark Themes")
                }
            }

            // Custom Accent Color
            Section {
                HStack {
                    Text("Custom Accent Color")
                    Spacer()
                    ColorPicker("", selection: $customAccentColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: customAccentColor) { _, newColor in
                            themeManager.setCustomAccentColor(newColor)
                        }
                }
            } header: {
                Text("Customization")
            } footer: {
                Text("Choose a custom accent color for the selected theme")
            }

            // Font Size
            Section {
                Picker("Font Size", selection: $themeManager.fontSizePreference) {
                    ForEach(FontSizePreference.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.segmented)

                // Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview Text")
                        .scaledFont(16, weight: .semibold)

                    Text("This is how your text will appear throughout the app.")
                        .scaledFont(14)
                        .themedSecondaryText()
                }
                .padding(.vertical, 8)
            } header: {
                Text("Font Size")
            }

            // App Icon
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AppIcon.allCases) { icon in
                            AppIconButton(icon: icon, isSelected: themeManager.selectedAppIcon == icon)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        themeManager.selectedAppIcon = icon
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("App Icon")
            } footer: {
                Text("App icon changes may take a moment to apply")
            }

            // Color Preview
            Section {
                VStack(spacing: 16) {
                    ColorPreviewRow(title: "Accent", color: themeManager.accentColor)
                    ColorPreviewRow(title: "Background", color: themeManager.backgroundColor)
                    ColorPreviewRow(title: "Card", color: themeManager.cardBackgroundColor)
                    ColorPreviewRow(title: "Text", color: themeManager.textColor)
                    ColorPreviewRow(title: "Success", color: themeManager.successColor)
                    ColorPreviewRow(title: "Warning", color: themeManager.warningColor)
                    ColorPreviewRow(title: "Error", color: themeManager.errorColor)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Color Preview")
            }
        }
        .navigationTitle("Theme & Appearance")
        .onAppear {
            customAccentColor = themeManager.accentColor
        }
    }
}

// MARK: - Theme Row

struct ThemeRow: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Color preview circles
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(theme.accentColor))
                    .frame(width: 24, height: 24)

                Circle()
                    .fill(Color(theme.backgroundColor))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Circle()
                    .fill(Color(theme.secondaryBackgroundColor))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }

            // Theme name
            Text(theme.name)
                .font(.body)

            Spacer()

            // Checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(theme.accentColor))
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Color Preview Row

struct ColorPreviewRow: View {
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - App Icon Button

struct AppIconButton: View {
    let icon: AppIcon
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Icon preview (would show actual icon image in real app)
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor(for: icon))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.title)
                        .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

            Text(icon.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .secondary)
        }
    }

    private func iconColor(for icon: AppIcon) -> Color {
        switch icon {
        case .default: return .blue
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .minimal: return .gray
        case .dark: return .black
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ThemeSettingsView()
    }
}

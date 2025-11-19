//
//  AdvancedThemeSettingsView.swift
//  Cafe
//
//  Advanced theme customization options
//

import SwiftUI

struct AdvancedThemeSettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var customization: ThemeCustomization

    init() {
        _customization = State(initialValue: ThemeManager.shared.customization)
    }

    var body: some View {
        List {
            // Typography
            Section {
                Picker("Font Family", selection: $customization.fontFamily) {
                    ForEach(FontFamily.allCases) { family in
                        Text(family.rawValue).tag(family)
                    }
                }

                Picker("Font Weight", selection: $customization.fontWeight) {
                    ForEach(FontWeight.allCases) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }

                HStack {
                    Text("Base Font Size")
                    Spacer()
                    Text("\(Int(customization.baseFontSize))pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $customization.baseFontSize, in: 12...20, step: 1)

                HStack {
                    Text("Line Spacing")
                    Spacer()
                    Text("\(Int(customization.lineSpacing))pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $customization.lineSpacing, in: 0...8, step: 1)
            } header: {
                Text("Typography")
            } footer: {
                Text("Customize font appearance throughout the app")
            }

            // Spacing
            Section {
                Toggle("Compact Spacing", isOn: $customization.compactSpacing)

                HStack {
                    Text("Card Padding")
                    Spacer()
                    Text("\(Int(customization.cardPadding))pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $customization.cardPadding, in: 8...24, step: 2)

                HStack {
                    Text("Section Spacing")
                    Spacer()
                    Text("\(Int(customization.sectionSpacing))pt")
                        .foregroundColor(.secondary)
                }
                Slider(value: $customization.sectionSpacing, in: 12...32, step: 4)
            } header: {
                Text("Spacing")
            } footer: {
                Text("Control whitespace and padding")
            }

            // Visual Style
            Section {
                Picker("Corner Radius", selection: $customization.cornerRadius) {
                    ForEach(CornerRadiusStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Picker("Shadow Intensity", selection: $customization.shadowIntensity) {
                    ForEach(ShadowIntensity.allCases) { intensity in
                        Text(intensity.rawValue).tag(intensity)
                    }
                }

                Toggle("Blur Effects", isOn: $customization.blurEffects)
            } header: {
                Text("Visual Style")
            } footer: {
                Text("Adjust visual depth and effects")
            }

            // Icons
            Section {
                Picker("Icon Style", selection: $customization.iconStyle) {
                    ForEach(IconStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }

                Picker("Icon Size", selection: $customization.iconSize) {
                    ForEach(IconSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
            } header: {
                Text("Icons")
            } footer: {
                Text("Customize icon appearance")
            }

            // Animations
            Section {
                Picker("Animation Speed", selection: $customization.animationSpeed) {
                    ForEach(AnimationSpeed.allCases) { speed in
                        Text(speed.rawValue).tag(speed)
                    }
                }

                Toggle("Reduced Motion", isOn: $customization.reducedMotion)
            } header: {
                Text("Animations")
            } footer: {
                Text("Control animation behavior")
            }

            // Presets
            Section {
                Button("Default") {
                    customization = .default
                }

                Button("Compact") {
                    customization = .compact
                }

                Button("Spacious") {
                    customization = .spacious
                }

                Button("Minimal") {
                    customization = .minimal
                }

                Button("Bold") {
                    customization = .bold
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Quick customization presets")
            }

            // Preview
            Section {
                PreviewCard(customization: customization, theme: themeManager.currentTheme)
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Advanced Theming")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: customization) { _, newValue in
            themeManager.customization = newValue
        }
    }
}

// MARK: - Preview Card

struct PreviewCard: View {
    let customization: ThemeCustomization
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: customization.lineSpacing) {
            HStack {
                Image(systemName: customization.iconStyle.systemName(for: "checkmark.circle"))
                    .font(customization.iconSize.font)
                    .foregroundColor(Color(theme.accentColor))

                Text("Sample Task")
                    .font(customization.fontFamily.font(
                        size: customization.baseFontSize,
                        weight: customization.fontWeight.swiftUIWeight
                    ))

                Spacer()

                Text("Due Today")
                    .font(customization.fontFamily.font(size: customization.baseFontSize - 2))
                    .foregroundColor(.secondary)
            }

            Text("This is a preview of how your content will look with the current customization settings.")
                .font(customization.fontFamily.font(size: customization.baseFontSize - 2))
                .foregroundColor(.secondary)
                .lineSpacing(customization.lineSpacing)

            HStack(spacing: 8) {
                ForEach(["work", "important"], id: \.self) { label in
                    Text(label)
                        .font(customization.fontFamily.font(size: customization.baseFontSize - 4))
                        .padding(.horizontal, customization.compactSpacing ? 6 : 8)
                        .padding(.vertical, customization.compactSpacing ? 2 : 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(customization.cornerRadius.value)
                }
            }
        }
        .themedCard(customization: customization, theme: theme)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedThemeSettingsView()
    }
}

//
//  ThemeSwitcherView.swift
//  Cafe
//
//  Theme selection interface
//

import SwiftUI

struct ThemeSwitcherView: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Appearance Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Picker("Appearance", selection: Binding(
                    get: { themeManager.appearanceMode },
                    set: { themeManager.appearanceMode = $0 }
                )) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Divider()

            // Theme Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                // Light Themes
                if !Theme.lightThemes.isEmpty {
                    Text("Light Themes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Theme.lightThemes) { theme in
                            ThemePreviewButton(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id
                            ) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                }

                // Dark Themes
                if !Theme.darkThemes.isEmpty {
                    Text("Dark Themes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Theme.darkThemes) { theme in
                            ThemePreviewButton(
                                theme: theme,
                                isSelected: themeManager.currentTheme.id == theme.id
                            ) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Theme Preview Button

struct ThemePreviewButton: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Color preview circles
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(theme.accentColor))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(Color(theme.backgroundColor))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    Circle()
                        .fill(Color(theme.secondaryBackgroundColor))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }

                Text(theme.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color(theme.accentColor) : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(theme.accentColor).opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(theme.accentColor) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        Form {
            Section {
                ThemeSwitcherView()
            }
        }
        .environment(ThemeManager.shared)
    }
}

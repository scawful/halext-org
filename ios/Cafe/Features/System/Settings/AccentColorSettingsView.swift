//
//  AccentColorSettingsView.swift
//  Cafe
//
//  Accent color customization
//

import SwiftUI

struct AccentColorSettingsView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var selectedColor: Color = .blue

    private let presetColors: [(String, Color)] = [
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Mint", .mint),
        ("Brown", .brown)
    ]

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(presetColors, id: \.0) { preset in
                        ColorCircleButton(
                            name: preset.0,
                            color: preset.1,
                            isSelected: selectedColor == preset.1
                        ) {
                            selectedColor = preset.1
                            themeManager.setCustomAccentColor(preset.1)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Preset Colors")
            }

            Section {
                HStack {
                    Text("Custom Color")

                    Spacer()

                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                        .labelsHidden()
                        .onChange(of: selectedColor) { _, newColor in
                            themeManager.setCustomAccentColor(newColor)
                        }
                }
            } header: {
                Text("Custom")
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    AccentPreviewRow(
                        icon: "star.fill",
                        text: "Starred Item"
                    )

                    AccentPreviewRow(
                        icon: "checkmark.circle.fill",
                        text: "Selected Item"
                    )

                    AccentPreviewRow(
                        icon: "heart.fill",
                        text: "Favorite Item"
                    )

                    Button("Primary Button") {
                        // Preview
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.accentColor)
                }
                .padding(.vertical, 8)
            } header: {
                Text("Preview")
            }
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedColor = themeManager.accentColor
        }
    }
}

struct ColorCircleButton: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)

                    if isSelected {
                        Circle()
                            .stroke(color, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                Text(name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AccentPreviewRow: View {
    let icon: String
    let text: String

    @State private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.accentColor)
                .font(.title3)

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        AccentColorSettingsView()
    }
}

//
//  FontSizeSettingsView.swift
//  Cafe
//
//  Font size adjustment settings
//

import SwiftUI

struct FontSizeSettingsView: View {
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        List {
            Section {
                Picker("Font Size", selection: $themeManager.fontSizePreference) {
                    ForEach(FontSizePreference.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Font Size")
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    PreviewTextBlock(
                        title: "Title",
                        fontSize: 24,
                        weight: .bold
                    )

                    PreviewTextBlock(
                        title: "Headline",
                        fontSize: 20,
                        weight: .semibold
                    )

                    PreviewTextBlock(
                        title: "Body Text",
                        fontSize: 16,
                        weight: .regular
                    )

                    PreviewTextBlock(
                        title: "Caption",
                        fontSize: 12,
                        weight: .regular
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("Preview")
            } footer: {
                Text("This is how text will appear throughout the app with your selected font size.")
            }
        }
        .navigationTitle("Font Size")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PreviewTextBlock: View {
    let title: String
    let fontSize: CGFloat
    let weight: Font.Weight

    @State private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("The quick brown fox jumps over the lazy dog")
                .scaledFont(fontSize, weight: weight)
        }
    }
}

#Preview {
    NavigationStack {
        FontSizeSettingsView()
    }
}

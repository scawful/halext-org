//
//  ClipboardSuggestionBanner.swift
//  Cafe
//
//  UI for displaying clipboard suggestions
//

import SwiftUI

struct ClipboardSuggestionBanner: View {
    @ObservedObject var clipboardMonitor = ClipboardMonitor.shared
    @State private var offset: CGFloat = -100

    var body: some View {
        VStack {
            if clipboardMonitor.hasClipboardSuggestion, let suggestion = clipboardMonitor.currentSuggestion {
                suggestionCard(for: suggestion)
                    .offset(y: offset)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: offset)
                    .onAppear {
                        offset = 0
                    }
                    .onDisappear {
                        offset = -100
                    }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func suggestionCard(for suggestion: ClipboardSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                iconForType(suggestion.type)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create task from clipboard?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(suggestion.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    if let description = suggestion.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding()

            // Actions
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation {
                        clipboardMonitor.dismissSuggestion()
                    }
                }) {
                    Text("Dismiss")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }

                Divider()
                    .frame(height: 20)

                Button(action: {
                    _Concurrency.Task {
                        await clipboardMonitor.acceptSuggestion()
                    }
                }) {
                    Text("Create Task")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .background(Color(.systemGray6))
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func iconForType(_ type: ClipboardSuggestion.SuggestionType) -> some View {
        switch type {
        case .url:
            Image(systemName: "link")
        case .text:
            Image(systemName: "doc.text")
        case .image:
            Image(systemName: "photo")
        }
    }
}

// MARK: - Clipboard Settings View

struct ClipboardSettingsView: View {
    @ObservedObject var clipboardMonitor = ClipboardMonitor.shared

    var body: some View {
        List {
            Section {
                Toggle("Monitor Clipboard", isOn: Binding(
                    get: { clipboardMonitor.isMonitoringEnabled },
                    set: { clipboardMonitor.isMonitoringEnabled = $0 }
                ))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Smart Suggestions")
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text("Cafe can suggest creating tasks when you copy URLs, text, or images that look like tasks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

            } header: {
                Text("Clipboard Monitoring")
            } footer: {
                Text("Cafe checks your clipboard every 2 seconds when enabled. Your clipboard data never leaves your device.")
            }

            if clipboardMonitor.isMonitoringEnabled {
                Section {
                    Button(action: {
                        clipboardMonitor.checkClipboardNow()
                    }) {
                        Label("Check Clipboard Now", systemImage: "clipboard")
                    }
                } header: {
                    Text("Testing")
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    exampleRow(
                        icon: "link",
                        title: "URLs",
                        description: "Copied links become tasks with the URL in description"
                    )

                    Divider()

                    exampleRow(
                        icon: "doc.text",
                        title: "Task-like Text",
                        description: "Text containing task keywords like \"todo\" or \"remember\""
                    )

                    Divider()

                    exampleRow(
                        icon: "list.bullet",
                        title: "Lists",
                        description: "Multiple lines with bullets or numbers"
                    )

                    Divider()

                    exampleRow(
                        icon: "photo",
                        title: "Images",
                        description: "Screenshots and photos from your clipboard"
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("What Gets Detected")
            }
        }
        .navigationTitle("Clipboard")
    }

    @ViewBuilder
    private func exampleRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClipboardSettingsView()
    }
}

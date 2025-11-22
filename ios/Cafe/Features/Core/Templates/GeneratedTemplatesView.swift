//
//  GeneratedTemplatesView.swift
//  Cafe
//
//  View for reviewing and saving AI-generated templates
//

import SwiftUI

struct GeneratedTemplatesView: View {
    let templates: [TaskTemplate]
    let onSave: (TaskTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager
    @State private var savedTemplates: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates Found", systemImage: "doc.text")
                    } description: {
                        Text("Complete more tasks to generate templates from your patterns")
                    }
                } else {
                    Section {
                        ForEach(templates) { template in
                            TemplatePreviewRow(
                                template: template,
                                isSaved: savedTemplates.contains(template.id),
                                onSave: {
                                    onSave(template)
                                    savedTemplates.insert(template.id)
                                    HapticManager.success()
                                }
                            )
                        }
                    } header: {
                        Text("Generated Templates")
                    } footer: {
                        Text("These templates were generated from your completed tasks. Review and save the ones you want to reuse.")
                    }
                }
            }
            .navigationTitle("Generated Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TemplatePreviewRow: View {
    let template: TaskTemplate
    let isSaved: Bool
    let onSave: () -> Void
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack {
            Image(systemName: template.icon)
                .foregroundColor(colorFromString(template.color))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                if !template.defaultLabels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(template.defaultLabels.prefix(3), id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(themeManager.accentColor.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }

                if let dueDays = template.defaultDueDays {
                    Text("Typically due in \(dueDays) day\(dueDays == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }

            Spacer()

            if isSaved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onSave) {
                    Text("Save")
                        .font(.caption)
                }
                .themedButton(style: .filled, cornerRadius: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorFromString(_ colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .blue
        }
    }
}


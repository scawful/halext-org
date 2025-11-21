//
//  TaskTemplatesView.swift
//  Cafe
//
//  UI for managing task templates
//

import SwiftUI

struct TaskTemplatesView: View {
    @State private var templateManager = TaskTemplateManager.shared
    @State private var searchText = ""
    @State private var showingNewTemplate = false
    @State private var selectedTemplate: TaskTemplate?
    @State private var isGeneratingTemplates = false
    @State private var generatedTemplates: [TaskTemplate] = []
    @State private var showingGeneratedTemplates = false

    var filteredTemplates: [TaskTemplate] {
        templateManager.searchTemplates(query: searchText)
    }

    var body: some View {
        NavigationStack {
            List {
                // Built-in Templates
                Section {
                    ForEach(TaskTemplate.builtInTemplates) { template in
                        TemplateRow(template: template)
                            .onTapGesture {
                                selectedTemplate = template
                            }
                    }
                } header: {
                    Text("Built-in Templates")
                } footer: {
                    Text("Pre-made templates for common tasks")
                }

                // Custom Templates
                if !templateManager.customTemplates.isEmpty {
                    Section {
                        ForEach(templateManager.customTemplates) { template in
                            TemplateRow(template: template)
                                .onTapGesture {
                                    selectedTemplate = template
                                }
                        }
                        .onDelete { offsets in
                            templateManager.deleteTemplates(at: Array(offsets))
                        }
                    } header: {
                        Text("Custom Templates")
                    } footer: {
                        Text("Your personalized templates")
                    }
                }

                // Statistics
                Section {
                    LabeledContent("Total Templates", value: "\(templateManager.templateCount)")
                    LabeledContent("Custom Templates", value: "\(templateManager.customTemplateCount)")
                } header: {
                    Text("Statistics")
                }
            }
            .navigationTitle("Templates")
            .searchable(text: $searchText, prompt: "Search templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingNewTemplate = true }) {
                            Label("New Template", systemImage: "plus")
                        }
                        
                        Divider()
                        
                        Button(action: generateTemplatesFromHistory) {
                            Label("Generate from History", systemImage: "sparkles")
                        }
                        .disabled(isGeneratingTemplates)
                    } label: {
                        if isGeneratingTemplates {
                            ProgressView()
                        } else {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                TemplateEditorView(template: nil)
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }
            .sheet(isPresented: $showingGeneratedTemplates) {
                GeneratedTemplatesView(
                    templates: generatedTemplates,
                    onSave: { template in
                        templateManager.addTemplate(template)
                    }
                )
            }
        }
    }
    
    private func generateTemplatesFromHistory() {
        isGeneratingTemplates = true
        
        _Concurrency.Task {
            do {
                let templates = try await SmartTemplateGenerator.shared.generateTemplatesFromHistory()
                await MainActor.run {
                    generatedTemplates = templates
                    isGeneratingTemplates = false
                    showingGeneratedTemplates = !templates.isEmpty
                }
            } catch {
                print("Failed to generate templates: \(error)")
                await MainActor.run {
                    isGeneratingTemplates = false
                }
            }
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: TaskTemplate

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(colorFromString(template.color).opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: template.icon)
                    .foregroundColor(colorFromString(template.color))
                    .font(.title3)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                Text(template.titleTemplate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !template.defaultLabels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(template.defaultLabels.prefix(3), id: \.self) { label in
                            Text(label)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: TaskTemplate
    @Environment(\.dismiss) var dismiss
    @State private var showingEditor = false
    @State private var showingCreateTask = false

    var body: some View {
        NavigationStack {
            List {
                // Preview
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: template.icon)
                                .font(.largeTitle)
                                .foregroundColor(colorFromString(template.color))

                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                if let priority = template.defaultPriority {
                                    Label(priority.rawValue, systemImage: priority.icon)
                                        .font(.caption)
                                        .foregroundColor(colorFromString(priority.color))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preview")
                }

                // Details
                Section {
                    LabeledContent("Title Template", value: template.titleTemplate)

                    if let description = template.descriptionTemplate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description Template")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(description)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }

                    if let dueDays = template.defaultDueDays {
                        LabeledContent("Due In", value: "\(dueDays) days")
                    }

                    if !template.defaultLabels.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Labels")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                ForEach(template.defaultLabels, id: \.self) { label in
                                    Text(label)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Details")
                }

                // Checklist
                if !template.checklist.isEmpty {
                    Section {
                        ForEach(template.checklist) { item in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                Text(item.title)
                            }
                        }
                    } header: {
                        Text("Checklist Items")
                    }
                }

                // Actions
                Section {
                    Button(action: {
                        showingCreateTask = true
                        dismiss()
                    }) {
                        Label("Create Task from Template", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }

                    // Only show edit for custom templates
                    if !TaskTemplate.builtInTemplates.contains(where: { $0.id == template.id }) {
                        Button(action: { showingEditor = true }) {
                            Label("Edit Template", systemImage: "pencil")
                        }
                    }
                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingEditor) {
                TemplateEditorView(template: template)
            }
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    TaskTemplatesView()
}

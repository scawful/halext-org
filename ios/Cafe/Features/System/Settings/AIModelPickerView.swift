//
//  AIModelPickerView.swift
//  Cafe
//
//  AI model selection view with provider grouping
//

import SwiftUI

struct AIModelPickerView: View {
    @Environment(AppState.self) var appState
    @Binding var selectedModelId: String?
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoadingModels {
                    ProgressView("Loading models...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let modelsResponse = appState.aiModels {
                    modelsList(modelsResponse: modelsResponse)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Select AI Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        _Concurrency.Task {
                            await appState.refreshAIModels()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search models")
            .task {
                await ensureModelsLoaded()
            }
        }
    }

    private func modelsList(modelsResponse: AIModelsResponse) -> some View {
        List {
            // Default model section
            if let defaultModelId = modelsResponse.defaultModelId {
                Section {
                    Button(action: {
                        selectedModelId = nil
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Default Model")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(defaultModelId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedModelId == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                } header: {
                    Text("Recommended")
                }
            }

            // Group models by provider/source
            ForEach(groupedModels(modelsResponse.models), id: \.key) { group in
                Section {
                    ForEach(group.value) { model in
                        modelRow(model: model)
                    }
                } header: {
                    HStack {
                        Text(group.key)
                        if let firstModel = group.value.first, let latency = firstModel.latencyMs {
                            Text("\(latency)ms")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func ensureModelsLoaded() async {
        guard !appState.isLoadingModels else { return }

        if appState.aiModels == nil {
            #if DEBUG
            print("🔍 AIModelPickerView appeared, loading models...")
            #endif
            await appState.refreshAIModels()
            #if DEBUG
            let count = appState.aiModels?.models.count ?? 0
            if count == 0 {
                print("❌ AIModelPickerView did not receive any models after refresh")
            } else {
                print("🔍 Loaded \(count) models in AIModelPickerView")
            }
            #endif
        }
    }

    private func modelRow(model: AIModel) -> some View {
        Button(action: {
            selectedModelId = model.id
            dismiss()
        }) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Model name and tier badge
                    HStack(spacing: 8) {
                        Text(model.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if !model.tierLabel.isEmpty {
                            Text(model.tierLabel)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(tierColor(for: model.tierLabel))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }

                    // Description
                    if let description = model.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    // Capabilities and metadata
                    VStack(alignment: .leading, spacing: 4) {
                        // Context window
                        if let contextWindow = model.contextWindowFormatted {
                            Label(contextWindow, systemImage: "doc.text")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Cost
                        if let cost = model.costDescription {
                            Label(cost, systemImage: "dollarsign.circle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        // Capabilities
                        HStack(spacing: 8) {
                            if model.supportsVision == true {
                                Label("Vision", systemImage: "eye.fill")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }

                            if model.supportsFunctionCalling == true {
                                Label("Functions", systemImage: "function")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }

                        // Node/latency info for distributed models
                        HStack(spacing: 8) {
                            if let nodeName = model.nodeName {
                                Label(nodeName, systemImage: "server.rack")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            if let latency = model.latencyMs {
                                Label("\(latency)ms", systemImage: "speedometer")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            if let size = model.size {
                                Label(size, systemImage: "externaldrive")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                if selectedModelId == model.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func tierColor(for tier: String) -> Color {
        switch tier {
        case "Lightweight":
            return .green
        case "Standard":
            return .blue
        case "Premium":
            return .purple
        default:
            return .gray
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Models Available")
                .font(.headline)

            Text("AI models could not be loaded. Please check your connection and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                _Concurrency.Task {
                    await appState.refreshAIModels()
                }
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func groupedModels(_ models: [AIModel]) -> [(key: String, value: [AIModel])] {
        let filtered = filteredModels(models)
        let grouped = Dictionary(grouping: filtered) { model -> String in
            if let nodeName = model.nodeName {
                return nodeName
            } else if let source = model.source {
                return source.capitalized
            } else {
                return model.provider.capitalized
            }
        }

        // Sort by group name
        return grouped.sorted { $0.key < $1.key }
    }

    private func filteredModels(_ models: [AIModel]) -> [AIModel] {
        if searchText.isEmpty {
            return models
        }

        return models.filter { model in
            model.name.localizedCaseInsensitiveContains(searchText) ||
            model.provider.localizedCaseInsensitiveContains(searchText) ||
            (model.nodeName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}

// MARK: - Compact Picker for Inline Use

struct AIModelCompactPicker: View {
    @Environment(AppState.self) var appState
    @Binding var selectedModelId: String?
    @State private var showingPicker = false

    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .font(.caption)

                Text(displayName)
                    .font(.caption)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .foregroundColor(.primary)
        }
        .sheet(isPresented: $showingPicker) {
            AIModelPickerView(selectedModelId: $selectedModelId)
        }
    }

    private var displayName: String {
        if let selectedId = selectedModelId,
           let model = appState.aiModels?.models.first(where: { $0.id == selectedId }) {
            return model.displayName
        } else if let defaultId = appState.aiModels?.defaultModelId {
            return "Default (\(defaultId))"
        } else {
            return "Select Model"
        }
    }
}

// MARK: - Preview

#Preview {
    AIModelPickerView(selectedModelId: .constant(nil))
        .environment(AppState())
}

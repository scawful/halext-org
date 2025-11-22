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
    @State private var selectedProvider: String? = nil
    @State private var collapsedSections: Set<String> = []
    @State private var showCompactView = true

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
        let grouped = groupedModels(modelsResponse.models)
        let providers = Set(grouped.map { $0.key }).sorted()
        
        return List {
            // Quick filter chips
            if !searchText.isEmpty || selectedProvider == nil {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ModelFilterChip(
                                title: "All",
                                isSelected: selectedProvider == nil,
                                count: modelsResponse.models.count
                            ) {
                                selectedProvider = nil
                            }
                            
                            ForEach(providers.prefix(8), id: \.self) { provider in
                                ModelFilterChip(
                                    title: provider,
                                    isSelected: selectedProvider == provider,
                                    count: grouped.first(where: { $0.key == provider })?.value.count ?? 0
                                ) {
                                    selectedProvider = selectedProvider == provider ? nil : provider
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } header: {
                    Text("Quick Filters")
                }
            }
            
            // Default model section
            if let defaultModelId = modelsResponse.defaultModelId,
               (selectedProvider == nil || defaultModelId.contains(selectedProvider ?? "")) {
                Section {
                    Button(action: {
                        selectedModelId = nil
                        dismiss()
                    }) {
                        CompactModelRow(
                            modelName: "Default Model",
                            provider: defaultModelId,
                            isSelected: selectedModelId == nil,
                            showDetails: false
                        )
                    }
                } header: {
                    Text("Recommended")
                }
            }

            // Group models by provider/source with collapsible sections
            ForEach(grouped, id: \.key) { group in
                if selectedProvider == nil || group.key == selectedProvider {
                    let isCollapsed = collapsedSections.contains(group.key)
                    
                    Section {
                        if !isCollapsed {
                            ForEach(group.value) { model in
                                modelRow(model: model, compact: showCompactView)
                            }
                        } else {
                            Button(action: {
                                collapsedSections.remove(group.key)
                            }) {
                                HStack {
                                    Text("\(group.value.count) models")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Button(action: {
                                if isCollapsed {
                                    collapsedSections.remove(group.key)
                                } else {
                                    collapsedSections.insert(group.key)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(group.key)
                                    Text("(\(group.value.count))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
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
        .listStyle(.insetGrouped)
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

    private func modelRow(model: AIModel, compact: Bool) -> some View {
        Button(action: {
            selectedModelId = model.id
            dismiss()
        }) {
            if compact {
                CompactModelRow(
                    modelName: model.name,
                    provider: model.provider,
                    isSelected: selectedModelId == model.id,
                    showDetails: false,
                    tierLabel: model.tierLabel.isEmpty ? nil : model.tierLabel,
                    supportsVision: model.supportsVision == true,
                    supportsFunctions: model.supportsFunctionCalling == true,
                    latency: model.latencyMs
                )
            } else {
                DetailedModelRow(model: model, isSelected: selectedModelId == model.id)
            }
        }
        .buttonStyle(.plain)
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

        // Sort by group name, but prioritize common providers
        let priorityProviders = ["Openai", "Gemini", "Ollama", "Openwebui"]
        return grouped.sorted { lhs, rhs in
            let lhsPriority = priorityProviders.firstIndex(of: lhs.key) ?? Int.max
            let rhsPriority = priorityProviders.firstIndex(of: rhs.key) ?? Int.max
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.key < rhs.key
        }
    }

    private func filteredModels(_ models: [AIModel]) -> [AIModel] {
        var filtered = models
        
        // Apply provider filter
        if let provider = selectedProvider {
            filtered = filtered.filter { model in
                model.provider.capitalized == provider ||
                model.source?.capitalized == provider ||
                model.nodeName == provider
            }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { model in
                model.name.localizedCaseInsensitiveContains(searchText) ||
                model.provider.localizedCaseInsensitiveContains(searchText) ||
                (model.nodeName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (model.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
}

// MARK: - Compact Model Row

struct CompactModelRow: View {
    let modelName: String
    let provider: String
    let isSelected: Bool
    let showDetails: Bool
    var tierLabel: String? = nil
    var supportsVision: Bool = false
    var supportsFunctions: Bool = false
    var latency: Int? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Model info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(modelName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let tier = tierLabel {
                        Text(tier)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(tierColor(for: tier))
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(provider.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if supportsVision {
                        Image(systemName: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                    
                    if supportsFunctions {
                        Image(systemName: "function")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    if let latency = latency {
                        Text("\(latency)ms")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
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
}

// MARK: - Detailed Model Row (for future use)

struct DetailedModelRow: View {
    let model: AIModel
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
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

                if let description = model.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

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
                    
                    if let latency = model.latencyMs {
                        Label("\(latency)ms", systemImage: "speedometer")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
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
}

// MARK: - Filter Chip

private struct ModelFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("(\(count))")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
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

//
//  AISettingsView.swift
//  Cafe
//
//  AI model and provider settings
//

import SwiftUI

struct AISettingsView: View {
    @Environment(AppState.self) var appState
    @State private var settingsManager = SettingsManager.shared
    @State private var showingModelPicker = false

    var body: some View {
        List {
            // Model Selection Section
            modelSelectionSection

            // Provider Controls Section
            providerControlsSection

            // Model Info Section
            if let modelsResponse = appState.aiModels {
                modelInfoSection(modelsResponse: modelsResponse)
            }
        }
        .navigationTitle("AI Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingModelPicker) {
            AIModelPickerView(selectedModelId: $settingsManager.selectedAiModelId)
        }
        .task {
            if appState.aiModels == nil {
                await appState.loadAIModels()
            }
        }
    }

    // MARK: - Model Selection Section

    private var modelSelectionSection: some View {
        Section {
            Button(action: {
                showingModelPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Model")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(currentModelDisplay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if settingsManager.selectedAiModelId != nil {
                Button(action: {
                    settingsManager.selectedAiModelId = nil
                }) {
                    HStack {
                        Text("Reset to Default")
                            .foregroundColor(.blue)

                        Spacer()

                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
        } header: {
            Label("Model Selection", systemImage: "cpu")
        } footer: {
            Text("Choose which AI model to use for chat, suggestions, and other AI features. The default model is automatically selected based on availability and performance.")
        }
    }

    // MARK: - Provider Controls Section

    private var providerControlsSection: some View {
        Section {
            Toggle(isOn: $settingsManager.cloudProvidersDisabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disable Cloud Providers")
                        .font(.headline)

                    Text("Only use local or self-hosted models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: {
                _Concurrency.Task {
                    await appState.refreshAIModels()
                }
            }) {
                HStack {
                    Label("Refresh Models", systemImage: "arrow.clockwise")
                        .foregroundColor(.primary)

                    Spacer()

                    if appState.isLoadingModels {
                        ProgressView()
                    }
                }
            }
            .disabled(appState.isLoadingModels)
        } header: {
            Label("Provider Controls", systemImage: "slider.horizontal.3")
        } footer: {
            Text("Control which AI providers are available. Disabling cloud providers will limit models to local or self-hosted options only.")
        }
    }

    // MARK: - Model Info Section

    private func modelInfoSection(modelsResponse: AIModelsResponse) -> some View {
        Section {
            LabeledContent("Available Models", value: "\(modelsResponse.models.count)")

            LabeledContent("Current Provider", value: modelsResponse.provider.capitalized)

            if let defaultModelId = modelsResponse.defaultModelId {
                LabeledContent {
                    Text(defaultModelId)
                        .font(.caption)
                } label: {
                    Text("Default Model ID")
                }
            }

            // Group counts
            let grouped = Dictionary(grouping: modelsResponse.models) { model -> String in
                model.source ?? model.provider
            }

            ForEach(grouped.sorted(by: { $0.key < $1.key }), id: \.key) { provider, models in
                LabeledContent {
                    Text("\(models.count)")
                } label: {
                    Text(provider.capitalized)
                }
            }
        } header: {
            Label("Model Information", systemImage: "info.circle")
        }
    }

    // MARK: - Helpers

    private var currentModelDisplay: String {
        if let selectedId = settingsManager.selectedAiModelId,
           let model = appState.aiModels?.models.first(where: { $0.id == selectedId }) {
            return model.displayName
        } else if let defaultId = appState.aiModels?.defaultModelId {
            return "Default (\(defaultId))"
        } else if appState.isLoadingModels {
            return "Loading..."
        } else {
            return "Not configured"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AISettingsView()
            .environment(AppState())
    }
}

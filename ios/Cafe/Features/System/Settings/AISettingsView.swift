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
    @State private var themeManager = ThemeManager.shared
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

            providerStatusSection
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
            if appState.aiProviderInfo == nil {
                await appState.loadAIProviderInfo()
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
                            .foregroundColor(themeManager.textColor)

                        Text(currentModelDisplay)
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }

            if settingsManager.selectedAiModelId != nil {
                Button(action: {
                    settingsManager.selectedAiModelId = nil
                }) {
                    HStack {
                        Text("Reset to Default")
                            .foregroundColor(themeManager.accentColor)

                        Spacer()

                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
        } header: {
            Label("Model Selection", systemImage: "cpu")
        } footer: {
            Text("Choose which AI model to use for chat, suggestions, and other AI features. The default model is automatically selected based on availability and performance.")
        }
    }

    private var providerStatusSection: some View {
        Section {
            if appState.isLoadingProviderInfo {
                ProgressView("Loading provider info...")
            } else if let info = appState.aiProviderInfo {
                LabeledContent("Current Provider", value: info.provider.capitalized)
                LabeledContent("Active Model", value: info.model)

                if let defaultId = info.defaultModelId {
                    LabeledContent("Default Model ID") {
                        Text(defaultId)
                            .font(.caption)
                    }
                }

                if !info.availableProviders.isEmpty {
                    LabeledContent("Available Providers") {
                        Text(info.availableProviders.joined(separator: ", "))
                            .font(.caption)
                    }
                }

                if let openwebui = info.openwebuiPublicUrl ?? info.openwebuiUrl {
                    LabeledContent("OpenWebUI") {
                        Text(openwebui)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }

                if let ollama = info.ollamaUrl {
                    LabeledContent("Ollama Endpoint") {
                        Text(ollama)
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }

                if let creds = info.credentials, !creds.isEmpty {
                    Section {
                        ForEach(creds, id: \.provider) { credential in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(credential.provider.capitalized)
                                        .font(.headline)
                                    if credential.hasKey {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundColor(themeManager.successColor)
                                    } else {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(themeManager.warningColor)
                                    }
                                    Spacer()
                                }

                                if let masked = credential.maskedKey, credential.hasKey {
                                    Text(masked)
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                } else if !credential.hasKey {
                                    Text("No API key stored")
                                        .font(.caption)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }

                                if let model = credential.model {
                                    Text("Preferred model: \(model)")
                                        .font(.caption2)
                                        .foregroundColor(themeManager.secondaryTextColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Provider Credentials")
                    }
                }
            } else {
                Button("Reload Provider Info") {
                    _Concurrency.Task {
                        await appState.loadAIProviderInfo()
                    }
                }
            }
        } header: {
            Label("Provider Status", systemImage: "shield.checkered")
        } footer: {
            Text("Provider details reflect how the backend is routing AI traffic and whether optional services (OpenWebUI, Ollama) are reachable.")
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
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }

            Button(action: {
                _Concurrency.Task {
                    await appState.refreshAIModels()
                }
            }) {
                HStack {
                    Label("Refresh Models", systemImage: "arrow.clockwise")
                        .foregroundColor(themeManager.textColor)

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

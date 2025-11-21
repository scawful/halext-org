//
//  AgentHubView.swift
//  Cafe
//
//  Manage LLM models and launch AI agent threads.
//

import SwiftUI

struct AgentHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) var themeManager
    @State private var modelsResponse: AIModelsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedModelId: String?

    var onStartChat: ((String?) -> Void)?

    var body: some View {
        List {
            modelsListSection
            providerSection
            controlsSection
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .navigationTitle("Agents & LLMs")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    _Concurrency.Task { await loadModels() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        })
        .overlay {
            if isLoading {
                ProgressView("Loading models…")
            }
        }
        .task {
            await loadModels()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var modelsListSection: some View {
        Section("Models") {
            if let models = modelsResponse?.models, !models.isEmpty {
                ForEach(models, id: \.id) { model in
                    modelRow(model: model)
                }
            } else if isLoading {
                ProgressView()
            } else {
                Text("No models available. Add provider credentials or start the backend.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var providerSection: some View {
        Section("Backend Status") {
            if let response = modelsResponse {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Provider: \(response.provider)", systemImage: "antenna.radiowaves.left.and.right")
                    Label("Current model: \(response.currentModel)", systemImage: "cpu")
                    if let defaultId = response.defaultModelId {
                        Label("Default: \(defaultId)", systemImage: "star.fill")
                    }
                }
                .font(.subheadline)

                if let creds = response.credentials, !creds.isEmpty {
                    ForEach(creds, id: \.self) { cred in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cred.provider.capitalized)
                                    .font(.subheadline)
                                if let model = cred.model {
                                    Text("Model: \(model)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let name = cred.keyName {
                                    Text("Key: \(name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: cred.hasKey ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(cred.hasKey ? .green : .orange)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Text("No provider credentials detected for this user.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } else if isLoading {
                ProgressView()
            } else {
                Text("Load models to see backend status.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func modelRow(model: AIModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                Text(model.provider.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let endpoint = model.endpoint {
                    Text(endpoint)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if selectedModelId == model.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedModelId = model.id
        }
    }

    private var controlsSection: some View {
        Section {
            Button {
                onStartChat?(selectedModelId)
            } label: {
                Label("Start AI Thread", systemImage: "sparkles")
            }
            .disabled(onStartChat == nil)

            if let modelId = selectedModelId, !modelId.isEmpty {
                Text("Selected: \(modelId)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func loadModels() async {
        isLoading = true
        defer { isLoading = false }
        do {
            modelsResponse = try await APIClient.shared.fetchAiModels()
            if selectedModelId == nil {
                selectedModelId = modelsResponse?.defaultModelId ?? modelsResponse?.models.first?.id
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AgentHubView()
    }
}

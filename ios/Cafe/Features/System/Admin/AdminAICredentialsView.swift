//
//  AdminAICredentialsView.swift
//  Cafe
//
//  Admin panel for managing cloud AI provider credentials (OpenAI, Gemini)
//

import SwiftUI

struct AdminAICredentialsView: View {
    @Environment(AppState.self) var appState
    @State private var credentials: [ProviderCredentialStatus] = []
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showSuccessAlert = false

    // OpenAI form state
    @State private var openaiApiKey = ""
    @State private var openaiModel = "gpt-4o-mini"
    @State private var showOpenAIKey = false

    // Gemini form state
    @State private var geminiApiKey = ""
    @State private var geminiModel = "gemini-1.5-flash"
    @State private var showGeminiKey = false

    private let openAIModels = [
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]

    private let geminiModels = [
        "gemini-3.0-preview",
        "gemini-2.5-pro",
        "gemini-2.5-flash"
    ]

    var body: some View {
        List {
            headerSection

            if isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("Loading credentials...")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                openAISection
                geminiSection
                currentConfigSection
            }

            if let errorMessage = errorMessage {
                Section {
                    Label {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("AI Credentials")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCredentials()
        }
        .refreshable {
            await loadCredentials()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let successMessage = successMessage {
                Text(successMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cloud AI Providers")
                            .font(.headline)

                        Text("Manage OpenAI and Gemini API credentials")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - OpenAI Section

    private var openAISection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Status indicator
                if let openaiCred = credentials.first(where: { $0.provider == "openai" }) {
                    HStack {
                        Image(systemName: openaiCred.hasKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(openaiCred.hasKey ? .green : .gray)

                        Text(openaiCred.hasKey ? "Configured" : "Not configured")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let maskedKey = openaiCred.maskedKey {
                            Text("(\(maskedKey))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // API Key field
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Group {
                            if showOpenAIKey {
                                TextField("sk-proj-...", text: $openaiApiKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("sk-proj-...", text: $openaiApiKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button(action: { showOpenAIKey.toggle() }) {
                            Image(systemName: showOpenAIKey ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Model picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Model")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Model", selection: $openaiModel) {
                        ForEach(openAIModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Save button
                Button(action: {
                    _Concurrency.Task {
                        await saveOpenAICredentials()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save OpenAI Credentials")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(openaiApiKey.isEmpty || isSaving)
            }
            .padding(.vertical, 4)
        } header: {
            Label("OpenAI", systemImage: "brain")
        } footer: {
            Text("Enter your OpenAI API key to enable GPT models. Keys are encrypted and stored securely on the server.")
        }
    }

    // MARK: - Gemini Section

    private var geminiSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Status indicator
                if let geminiCred = credentials.first(where: { $0.provider == "gemini" }) {
                    HStack {
                        Image(systemName: geminiCred.hasKey ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(geminiCred.hasKey ? .green : .gray)

                        Text(geminiCred.hasKey ? "Configured" : "Not configured")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let maskedKey = geminiCred.maskedKey {
                            Text("(\(maskedKey))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // API Key field
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Group {
                            if showGeminiKey {
                                TextField("AIza...", text: $geminiApiKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("AIza...", text: $geminiApiKey)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button(action: { showGeminiKey.toggle() }) {
                            Image(systemName: showGeminiKey ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Model picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Model")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("Model", selection: $geminiModel) {
                        ForEach(geminiModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Save button
                Button(action: {
                    _Concurrency.Task {
                        await saveGeminiCredentials()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Gemini Credentials")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(geminiApiKey.isEmpty || isSaving)
            }
            .padding(.vertical, 4)
        } header: {
            Label("Google Gemini", systemImage: "sparkles")
        } footer: {
            Text("Enter your Google AI API key to enable Gemini models. Keys are encrypted and stored securely on the server.")
        }
    }

    // MARK: - Current Configuration Section

    private var currentConfigSection: some View {
        Section {
            if let providerInfo = appState.aiProviderInfo {
                LabeledContent("Active Provider", value: providerInfo.provider.capitalized)
                LabeledContent("Active Model", value: providerInfo.model)

                if let defaultId = providerInfo.defaultModelId {
                    LabeledContent("Default Model ID") {
                        Text(defaultId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Button("Load Current Configuration") {
                    _Concurrency.Task {
                        await appState.loadAIProviderInfo()
                    }
                }
            }
        } header: {
            Label("Current Configuration", systemImage: "info.circle")
        } footer: {
            Text("This shows the currently active AI provider and model being used by the backend.")
        }
    }

    // MARK: - Actions

    @MainActor
    private func loadCredentials() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedCreds = try await APIClient.shared.getAIProviderCredentials()
            credentials = loadedCreds

            // Pre-populate model fields with existing configuration
            if let openaiCred = loadedCreds.first(where: { $0.provider == "openai" }),
               let model = openaiCred.model {
                openaiModel = model
            }

            if let geminiCred = loadedCreds.first(where: { $0.provider == "gemini" }),
               let model = geminiCred.model {
                geminiModel = model
            }
        } catch {
            errorMessage = "Failed to load credentials: \(error.localizedDescription)"
            print("Error loading credentials: \(error)")
        }

        isLoading = false
    }

    @MainActor
    private func saveOpenAICredentials() async {
        guard !openaiApiKey.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        do {
            let result = try await APIClient.shared.saveAIProviderCredential(
                provider: "openai",
                apiKey: openaiApiKey,
                model: openaiModel
            )

            // Update credentials list
            if let index = credentials.firstIndex(where: { $0.provider == "openai" }) {
                credentials[index] = result
            } else {
                credentials.append(result)
            }

            // Clear the API key field
            openaiApiKey = ""
            showOpenAIKey = false

            successMessage = "OpenAI credentials saved successfully"
            showSuccessAlert = true

            // Refresh AI provider info
            await appState.loadAIProviderInfo()
        } catch {
            errorMessage = "Failed to save OpenAI credentials: \(error.localizedDescription)"
            print("Error saving OpenAI credentials: \(error)")
        }

        isSaving = false
    }

    @MainActor
    private func saveGeminiCredentials() async {
        guard !geminiApiKey.isEmpty else { return }

        isSaving = true
        errorMessage = nil

        do {
            let result = try await APIClient.shared.saveAIProviderCredential(
                provider: "gemini",
                apiKey: geminiApiKey,
                model: geminiModel
            )

            // Update credentials list
            if let index = credentials.firstIndex(where: { $0.provider == "gemini" }) {
                credentials[index] = result
            } else {
                credentials.append(result)
            }

            // Clear the API key field
            geminiApiKey = ""
            showGeminiKey = false

            successMessage = "Gemini credentials saved successfully"
            showSuccessAlert = true

            // Refresh AI provider info
            await appState.loadAIProviderInfo()
        } catch {
            errorMessage = "Failed to save Gemini credentials: \(error.localizedDescription)"
            print("Error saving Gemini credentials: \(error)")
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdminAICredentialsView()
            .environment(AppState())
    }
}

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
    @Environment(AppState.self) var appState
    @State private var modelsResponse: AIModelsResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showRetry = false
    @State private var selectedModelId: String?
    @State private var settingsManager = SettingsManager.shared
    @State private var chatSettings = ChatSettingsManager.shared
    @State private var showingModelPicker = false
    @State private var pressedModelId: String?
    @State private var isStartButtonPressed = false
    @State private var animatedModelIds: Set<String> = []

    var onStartChat: ((String?) -> Void)?

    var body: some View {
        List {
            modelsListSection
            providerSection
            aiSettingsSection
            chatSettingsSection
            controlsSection
        }
        .listStyle(.insetGrouped)
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
            if appState.aiModels == nil {
                await appState.loadAIModels()
            }
            if appState.aiProviderInfo == nil {
                await appState.loadAIProviderInfo()
            }
        }
        .sheet(isPresented: $showingModelPicker) {
            AIModelPickerView(selectedModelId: $settingsManager.selectedAiModelId)
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in 
            errorMessage = nil
            showRetry = false
        })) {
            Button("OK", role: .cancel) {
                errorMessage = nil
                showRetry = false
            }
            if showRetry {
                Button("Retry") {
                    errorMessage = nil
                    showRetry = false
                    _Concurrency.Task {
                        await loadModels()
                    }
                }
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var modelsListSection: some View {
        Section("Models") {
            if let models = modelsResponse?.models, !models.isEmpty {
                ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                    modelRow(model: model)
                        .opacity(animatedModelIds.contains(model.id) ? 1 : 0)
                        .offset(y: animatedModelIds.contains(model.id) ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                            value: animatedModelIds.contains(model.id)
                        )
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                                withAnimation {
                                    animatedModelIds.insert(model.id)
                                }
                            }
                        }
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
        HStack(spacing: 12) {
            // Model icon with selection animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                (selectedModelId == model.id ? themeManager.accentColor : themeManager.accentColor.opacity(0.2)),
                                (selectedModelId == model.id ? themeManager.accentColor.opacity(0.8) : themeManager.accentColor.opacity(0.1))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .scaleEffect(pressedModelId == model.id ? 0.9 : 1.0)

                Image(systemName: "cpu.fill")
                    .font(.subheadline)
                    .foregroundColor(selectedModelId == model.id ? .white : themeManager.accentColor)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedModelId)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressedModelId)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Text(model.provider.uppercased())
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                if let endpoint = model.endpoint {
                    Text(endpoint)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                }
            }

            Spacer()

            if selectedModelId == model.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.accentColor)
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(pressedModelId == model.id ? themeManager.accentColor.opacity(0.1) : Color.clear)
        )
        .scaleEffect(pressedModelId == model.id ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressedModelId)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if pressedModelId != model.id {
                        pressedModelId = model.id
                    }
                }
                .onEnded { _ in
                    pressedModelId = nil
                }
        )
        .onTapGesture {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedModelId = model.id
            }
        }
    }

    // MARK: - AI Settings Section
    
    private var aiSettingsSection: some View {
        Section {
            // Model Selection
            Button(action: {
                showingModelPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default AI Model")
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
            
            // Provider Controls
            Toggle(isOn: $settingsManager.cloudProvidersDisabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disable Cloud Providers")
                        .font(.headline)

                    Text("Only use local or self-hosted models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Label("AI Settings", systemImage: "slider.horizontal.3")
        } footer: {
            Text("Configure default AI model and provider preferences")
        }
    }
    
    // MARK: - Chat Settings Section
    
    private var chatSettingsSection: some View {
        Group {
            // Quick Presets
            Section {
                ForEach(ChatPreset.allCases, id: \.self) { preset in
                    Button(action: { chatSettings.loadPreset(preset) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.rawValue)
                                .font(.body)
                                .foregroundColor(.primary)

                            Text(preset.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Quick Presets")
            } footer: {
                Text("Apply preconfigured chat behavior presets")
            }
            
            Section {
                Toggle("Enable AI Responses", isOn: $chatSettings.enableAIResponses)

                if chatSettings.enableAIResponses {
                    Picker("Response Style", selection: $chatSettings.aiResponseStyle) {
                        ForEach(AIResponseStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading) {
                                Text(style.rawValue)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(style)
                        }
                    }

                    Picker("Default Personality", selection: $chatSettings.defaultAgentPersonality) {
                        ForEach(AgentPersonality.allCases, id: \.self) { personality in
                            Text(personality.rawValue).tag(personality)
                        }
                    }
                    
                    // Auto-respond Delay
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Auto-respond Delay")
                            Spacer()
                            Text("\(chatSettings.autoRespondDelay, specifier: "%.1f")s")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $chatSettings.autoRespondDelay, in: 0...5, step: 0.5)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Context Window")
                            Spacer()
                            Text("\(chatSettings.contextWindowSize) messages")
                                .foregroundColor(.secondary)
                        }

                        Stepper("", value: $chatSettings.contextWindowSize, in: 10...200, step: 10)
                    }

                    Toggle("Remember History", isOn: $chatSettings.rememberConversationHistory)

                    Toggle("Cross-conversation Context", isOn: $chatSettings.enableCrossConversationContext)
                }
            } header: {
                Label("Chat Settings", systemImage: "message")
            } footer: {
                Text("Control how AI agents respond in conversations")
            }
            
            // Active AI Agents
            if chatSettings.enableAIResponses {
                Section {
                    ForEach(AIAgent.allAgents) { agent in
                        HStack {
                            Image(systemName: agent.avatar)
                                .font(.title3)
                                .foregroundColor(colorFromString(agent.color))
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(agent.name)
                                    .font(.body)

                                Text(agent.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 4) {
                                    ForEach(agent.capabilities.prefix(3), id: \.self) { capability in
                                        Text(capability.rawValue)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { chatSettings.isAgentActive(agent.id) },
                                set: { _ in chatSettings.toggleAgent(agent.id) }
                            ))
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Available AI Agents")
                } footer: {
                    Text("Select which AI agents can participate in conversations")
                }
            }
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "purple": return .purple
        case "blue": return .blue
        case "green": return .green
        case "pink": return .pink
        case "orange": return .orange
        case "red": return .red
        case "cyan": return .cyan
        case "mint": return .mint
        default: return .blue
        }
    }

    private var controlsSection: some View {
        Section {
            Button {
                HapticManager.success()
                onStartChat?(selectedModelId)
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .symbolEffect(.bounce, value: selectedModelId)
                    Text("Start AI Thread")
                        .fontWeight(.semibold)
                    Spacer()
                    if selectedModelId != nil {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .foregroundColor(themeManager.textColor)
                .padding(.vertical, 8)
            }
            .disabled(onStartChat == nil)
            .scaleEffect(isStartButtonPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isStartButtonPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isStartButtonPressed = true }
                    .onEnded { _ in isStartButtonPressed = false }
            )
            .themedButton(style: .gradient, cornerRadius: 12)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if let modelId = selectedModelId, !modelId.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.accentColor)
                        .symbolEffect(.pulse.wholeSymbol, options: .repeat(1))
                    Text("Selected: \(modelId)")
                        .font(.footnote)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.vertical, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Text("Actions")
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedModelId)
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

    private func loadModels() async {
        isLoading = true
        defer { isLoading = false }
        do {
            modelsResponse = try await APIClient.shared.fetchAiModels()
            if selectedModelId == nil {
                selectedModelId = modelsResponse?.defaultModelId ?? modelsResponse?.models.first?.id
            }
            await MainActor.run {
                errorMessage = nil
                showRetry = false
            }
        } catch {
            await MainActor.run {
                // Provide user-friendly error messages and determine if retry should be shown
                let friendlyMessage: String
                var shouldShowRetry = false
                
                if let apiError = error as? APIError {
                    friendlyMessage = apiError.errorDescription ?? "Failed to load AI models. Please try again."
                    // Show retry for transient errors (decoding errors might be server-side issues)
                    shouldShowRetry = apiError != .unauthorized && apiError != .notAuthenticated
                } else if let urlError = error as? URLError {
                    friendlyMessage = "Network error: \(urlError.localizedDescription). Please check your connection and try again."
                    shouldShowRetry = true
                } else if let decodingError = error as? DecodingError {
                    // Decoding errors might indicate server-side format changes - allow retry
                    friendlyMessage = "The data couldn't be read because it is missing."
                    shouldShowRetry = true
                } else {
                    friendlyMessage = "Failed to load AI models: \(error.localizedDescription)"
                    shouldShowRetry = true
                }
                
                errorMessage = friendlyMessage
                showRetry = shouldShowRetry
            }
        }
    }
}

#Preview {
    NavigationStack {
        AgentHubView()
    }
}

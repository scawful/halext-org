//
//  ChatSettingsManager.swift
//  Cafe
//
//  Manages chat behavior and AI agent settings
//

import Foundation

@MainActor
@Observable
class ChatSettingsManager {
    static let shared = ChatSettingsManager()

    // AI Behavior
    var enableAIResponses: Bool {
        didSet { saveSettings() }
    }

    var autoRespondDelay: Double { // seconds
        didSet { saveSettings() }
    }

    var aiResponseStyle: AIResponseStyle {
        didSet { saveSettings() }
    }

    var defaultAgentPersonality: AgentPersonality {
        didSet { saveSettings() }
    }

    // Message Features
    var enableTypingIndicators: Bool {
        didSet { saveSettings() }
    }

    var enableReadReceipts: Bool {
        didSet { saveSettings() }
    }

    var enableNotifications: Bool {
        didSet { saveSettings() }
    }

    var enableSoundEffects: Bool {
        didSet { saveSettings() }
    }

    // Group Chat
    var maxGroupSize: Int {
        didSet { saveSettings() }
    }

    var allowGroupAIAgents: Bool {
        didSet { saveSettings() }
    }

    var maxAIAgentsPerGroup: Int {
        didSet { saveSettings() }
    }

    // Context & Memory
    var contextWindowSize: Int { // Number of messages
        didSet { saveSettings() }
    }

    var rememberConversationHistory: Bool {
        didSet { saveSettings() }
    }

    var enableCrossConversationContext: Bool {
        didSet { saveSettings() }
    }

    // Active AI Agents
    var activeAgents: Set<String> {
        didSet { saveSettings() }
    }

    private let defaults = UserDefaults.standard
    private let settingsKey = "chatSettings"

    private init() {
        // Load saved settings or use defaults
        if let savedData = defaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(ChatSettings.self, from: savedData) {
            self.enableAIResponses = settings.enableAIResponses
            self.autoRespondDelay = settings.autoRespondDelay
            self.aiResponseStyle = settings.aiResponseStyle
            self.defaultAgentPersonality = settings.defaultAgentPersonality
            self.enableTypingIndicators = settings.enableTypingIndicators
            self.enableReadReceipts = settings.enableReadReceipts
            self.enableNotifications = settings.enableNotifications
            self.enableSoundEffects = settings.enableSoundEffects
            self.maxGroupSize = settings.maxGroupSize
            self.allowGroupAIAgents = settings.allowGroupAIAgents
            self.maxAIAgentsPerGroup = settings.maxAIAgentsPerGroup
            self.contextWindowSize = settings.contextWindowSize
            self.rememberConversationHistory = settings.rememberConversationHistory
            self.enableCrossConversationContext = settings.enableCrossConversationContext
            self.activeAgents = settings.activeAgents
        } else {
            // Default values
            self.enableAIResponses = true
            self.autoRespondDelay = 1.0
            self.aiResponseStyle = .balanced
            self.defaultAgentPersonality = .helpful
            self.enableTypingIndicators = true
            self.enableReadReceipts = true
            self.enableNotifications = true
            self.enableSoundEffects = true
            self.maxGroupSize = 10
            self.allowGroupAIAgents = true
            self.maxAIAgentsPerGroup = 3
            self.contextWindowSize = 50
            self.rememberConversationHistory = true
            self.enableCrossConversationContext = false
            self.activeAgents = Set(AIAgent.allAgents.map { $0.id })
        }
    }

    private func saveSettings() {
        let settings = ChatSettings(
            enableAIResponses: enableAIResponses,
            autoRespondDelay: autoRespondDelay,
            aiResponseStyle: aiResponseStyle,
            defaultAgentPersonality: defaultAgentPersonality,
            enableTypingIndicators: enableTypingIndicators,
            enableReadReceipts: enableReadReceipts,
            enableNotifications: enableNotifications,
            enableSoundEffects: enableSoundEffects,
            maxGroupSize: maxGroupSize,
            allowGroupAIAgents: allowGroupAIAgents,
            maxAIAgentsPerGroup: maxAIAgentsPerGroup,
            contextWindowSize: contextWindowSize,
            rememberConversationHistory: rememberConversationHistory,
            enableCrossConversationContext: enableCrossConversationContext,
            activeAgents: activeAgents
        )

        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Agent Management

    func isAgentActive(_ agentId: String) -> Bool {
        activeAgents.contains(agentId)
    }

    func toggleAgent(_ agentId: String) {
        if activeAgents.contains(agentId) {
            activeAgents.remove(agentId)
        } else {
            activeAgents.insert(agentId)
        }
    }

    func getActiveAgents() -> [AIAgent] {
        AIAgent.allAgents.filter { activeAgents.contains($0.id) }
    }

    // MARK: - Presets

    func loadPreset(_ preset: ChatPreset) {
        switch preset {
        case .minimal:
            enableAIResponses = false
            enableTypingIndicators = false
            enableReadReceipts = false
            enableSoundEffects = false
            autoRespondDelay = 0

        case .standard:
            enableAIResponses = true
            enableTypingIndicators = true
            enableReadReceipts = true
            enableSoundEffects = true
            autoRespondDelay = 1.0
            aiResponseStyle = .balanced

        case .enhanced:
            enableAIResponses = true
            enableTypingIndicators = true
            enableReadReceipts = true
            enableSoundEffects = true
            autoRespondDelay = 0.5
            aiResponseStyle = .creative
            rememberConversationHistory = true
            enableCrossConversationContext = true

        case .professional:
            enableAIResponses = true
            enableTypingIndicators = false
            enableReadReceipts = true
            enableSoundEffects = false
            autoRespondDelay = 2.0
            aiResponseStyle = .concise
            defaultAgentPersonality = .professional
        }
    }
}

// MARK: - Chat Settings Model

struct ChatSettings: Codable {
    let enableAIResponses: Bool
    let autoRespondDelay: Double
    let aiResponseStyle: AIResponseStyle
    let defaultAgentPersonality: AgentPersonality
    let enableTypingIndicators: Bool
    let enableReadReceipts: Bool
    let enableNotifications: Bool
    let enableSoundEffects: Bool
    let maxGroupSize: Int
    let allowGroupAIAgents: Bool
    let maxAIAgentsPerGroup: Int
    let contextWindowSize: Int
    let rememberConversationHistory: Bool
    let enableCrossConversationContext: Bool
    let activeAgents: Set<String>
}

// MARK: - AI Response Style

enum AIResponseStyle: String, Codable, CaseIterable {
    case concise = "Concise"
    case balanced = "Balanced"
    case detailed = "Detailed"
    case creative = "Creative"

    var description: String {
        switch self {
        case .concise:
            return "Short, to-the-point responses"
        case .balanced:
            return "Well-rounded responses with context"
        case .detailed:
            return "Comprehensive, in-depth responses"
        case .creative:
            return "Imaginative and engaging responses"
        }
    }

    var maxTokens: Int {
        switch self {
        case .concise: return 150
        case .balanced: return 300
        case .detailed: return 500
        case .creative: return 400
        }
    }
}

// MARK: - Chat Preset

enum ChatPreset: String, CaseIterable {
    case minimal = "Minimal"
    case standard = "Standard"
    case enhanced = "Enhanced"
    case professional = "Professional"

    var description: String {
        switch self {
        case .minimal:
            return "No AI, basic features only"
        case .standard:
            return "Balanced AI assistance"
        case .enhanced:
            return "Full AI features with context"
        case .professional:
            return "Formal, business-focused"
        }
    }
}

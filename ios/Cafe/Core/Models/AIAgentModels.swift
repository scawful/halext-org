//
//  AIAgentModels.swift
//  Cafe
//
//  AI agent models for chat conversations
//

import Foundation

// MARK: - AI Agent

struct AIAgent: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let personality: AgentPersonality
    let capabilities: [AgentCapability]
    let avatar: String // SF Symbol name
    let color: String
    let isActive: Bool

    var displayName: String {
        name
    }

    // Predefined agents
    static let assistant = AIAgent(
        id: "assistant",
        name: "AI Assistant",
        description: "General-purpose helpful assistant",
        personality: .helpful,
        capabilities: [.general, .tasks, .scheduling],
        avatar: "sparkles",
        color: "purple",
        isActive: true
    )

    static let productivity = AIAgent(
        id: "productivity",
        name: "Productivity Coach",
        description: "Helps you stay focused and productive",
        personality: .motivating,
        capabilities: [.tasks, .scheduling, .productivity],
        avatar: "chart.line.uptrend.xyaxis",
        color: "blue",
        isActive: true
    )

    static let finance = AIAgent(
        id: "finance",
        name: "Finance Advisor",
        description: "Helps with budgeting and financial planning",
        personality: .professional,
        capabilities: [.finance, .analytics],
        avatar: "dollarsign.circle",
        color: "green",
        isActive: true
    )

    static let creative = AIAgent(
        id: "creative",
        name: "Creative Muse",
        description: "Helps with brainstorming and creative tasks",
        personality: .creative,
        capabilities: [.general, .creative],
        avatar: "paintbrush",
        color: "pink",
        isActive: true
    )

    static let technical = AIAgent(
        id: "technical",
        name: "Tech Expert",
        description: "Technical advice and coding help",
        personality: .technical,
        capabilities: [.general, .technical],
        avatar: "chevron.left.forwardslash.chevron.right",
        color: "orange",
        isActive: true
    )

    static let allAgents: [AIAgent] = [
        .assistant,
        .productivity,
        .finance,
        .creative,
        .technical
    ]
}

// MARK: - Agent Personality

enum AgentPersonality: String, Codable, CaseIterable {
    case helpful = "Helpful"
    case motivating = "Motivating"
    case professional = "Professional"
    case creative = "Creative"
    case technical = "Technical"
    case friendly = "Friendly"
    case formal = "Formal"

    var systemPrompt: String {
        switch self {
        case .helpful:
            return "You are a helpful and friendly AI assistant. You provide clear, concise answers and always try to be supportive."
        case .motivating:
            return "You are an energetic and motivating coach. You encourage users to achieve their goals and stay productive."
        case .professional:
            return "You are a professional advisor. You provide expert advice in a formal, business-appropriate manner."
        case .creative:
            return "You are a creative and imaginative assistant. You help users brainstorm ideas and think outside the box."
        case .technical:
            return "You are a technical expert. You provide detailed technical explanations and coding assistance."
        case .friendly:
            return "You are a warm and friendly companion. You engage in casual conversation and provide support."
        case .formal:
            return "You are a formal and professional assistant. You maintain proper etiquette and provide structured responses."
        }
    }
}

// MARK: - Agent Capability

enum AgentCapability: String, Codable, CaseIterable {
    case general = "General Knowledge"
    case tasks = "Task Management"
    case scheduling = "Calendar & Scheduling"
    case finance = "Financial Advice"
    case productivity = "Productivity Tips"
    case analytics = "Data Analysis"
    case creative = "Creative Writing"
    case technical = "Technical Support"

    var icon: String {
        switch self {
        case .general: return "brain"
        case .tasks: return "checkmark.circle"
        case .scheduling: return "calendar"
        case .finance: return "dollarsign.circle"
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .analytics: return "chart.bar"
        case .creative: return "paintbrush"
        case .technical: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Conversation Participant

enum ConversationParticipant: Codable, Identifiable {
    case user(User)
    case agent(AIAgent)

    var id: String {
        switch self {
        case .user(let user):
            return "user-\(user.id)"
        case .agent(let agent):
            return "agent-\(agent.id)"
        }
    }

    var displayName: String {
        switch self {
        case .user(let user):
            return user.fullName ?? user.username
        case .agent(let agent):
            return agent.name
        }
    }

    var isAI: Bool {
        if case .agent = self {
            return true
        }
        return false
    }

    enum CodingKeys: String, CodingKey {
        case type, user, agent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "user":
            let user = try container.decode(User.self, forKey: .user)
            self = .user(user)
        case "agent":
            let agent = try container.decode(AIAgent.self, forKey: .agent)
            self = .agent(agent)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Unknown participant type: \(type)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .user(let user):
            try container.encode("user", forKey: .type)
            try container.encode(user, forKey: .user)
        case .agent(let agent):
            try container.encode("agent", forKey: .type)
            try container.encode(agent, forKey: .agent)
        }
    }
}

// MARK: - Enhanced Message

struct EnhancedMessage: Codable, Identifiable {
    let id: Int
    let conversationId: Int
    let sender: ConversationParticipant
    let content: String
    let messageType: MessageType
    let isRead: Bool
    let createdAt: Date
    let metadata: MessageMetadata?

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case sender, content
        case messageType = "message_type"
        case isRead = "is_read"
        case createdAt = "created_at"
        case metadata
    }

    var isFromCurrentUser: Bool {
        if case .user(let user) = sender {
            return user.id == KeychainManager.shared.getUserId()
        }
        return false
    }

    var isFromAI: Bool {
        sender.isAI
    }
}

// MARK: - Message Metadata

struct MessageMetadata: Codable {
    var aiModel: String?
    var responseTime: Double?
    var tokensUsed: Int?
    var context: [String: String]?
}

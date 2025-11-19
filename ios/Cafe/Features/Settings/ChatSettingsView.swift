//
//  ChatSettingsView.swift
//  Cafe
//
//  UI for chat behavior and AI agent settings
//

import SwiftUI

struct ChatSettingsView: View {
    @State private var chatSettings = ChatSettingsManager.shared

    var body: some View {
        List {
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

            // AI Behavior
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

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Auto-respond Delay")
                            Spacer()
                            Text("\(chatSettings.autoRespondDelay, specifier: "%.1f")s")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $chatSettings.autoRespondDelay, in: 0...5, step: 0.5)
                    }
                }
            } header: {
                Text("AI Behavior")
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

            // Message Features
            Section {
                Toggle("Typing Indicators", isOn: $chatSettings.enableTypingIndicators)
                Toggle("Read Receipts", isOn: $chatSettings.enableReadReceipts)
                Toggle("Notifications", isOn: $chatSettings.enableNotifications)
                Toggle("Sound Effects", isOn: $chatSettings.enableSoundEffects)
            } header: {
                Text("Message Features")
            } footer: {
                Text("Control message delivery and notification features")
            }

            // Group Chat
            Section {
                Stepper("Max Group Size: \(chatSettings.maxGroupSize)", value: $chatSettings.maxGroupSize, in: 2...50)

                if chatSettings.enableAIResponses {
                    Toggle("Allow AI in Groups", isOn: $chatSettings.allowGroupAIAgents)

                    if chatSettings.allowGroupAIAgents {
                        Stepper("Max AI per Group: \(chatSettings.maxAIAgentsPerGroup)", value: $chatSettings.maxAIAgentsPerGroup, in: 1...5)
                    }
                }
            } header: {
                Text("Group Chat")
            } footer: {
                Text("Configure group conversation limits")
            }

            // Context & Memory
            if chatSettings.enableAIResponses {
                Section {
                    Stepper("Context Window: \(chatSettings.contextWindowSize) messages", value: $chatSettings.contextWindowSize, in: 10...200, step: 10)

                    Toggle("Remember History", isOn: $chatSettings.rememberConversationHistory)

                    Toggle("Cross-conversation Context", isOn: $chatSettings.enableCrossConversationContext)
                } header: {
                    Text("Context & Memory")
                } footer: {
                    Text("Control how much conversation history AI agents remember")
                }
            }

            // Agent Capabilities Info
            Section {
                ForEach(AgentCapability.allCases, id: \.self) { capability in
                    HStack {
                        Image(systemName: capability.icon)
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        Text(capability.rawValue)
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("Agent Capabilities")
            } footer: {
                Text("What AI agents can help with")
            }
        }
        .navigationTitle("Chat Settings")
        .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatSettingsView()
    }
}

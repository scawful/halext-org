//
//  MoreView.swift
//  Cafe
//
//  “More” hub with overflow navigation
//

import SwiftUI

enum FeatureDestination: Hashable {
    case tasks
    case templates
    case smartLists
    case messages
    case finance
    case calendar
    case pages
    case admin
    case agentHub
    case recipes
    case goals
    case memories
    case sharedFiles
    case themes
    case advancedFeatures
    case help
    case chat // Legacy - redirects to messages
    case settings
    case social // Deprecated
}

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var showIOSFeatures = false
    @State private var showSettings = false

    private let aiAndComms: [MoreLink] = [
        MoreLink(title: "Messages", subtitle: "Chat with AI and contacts", icon: "message.fill", color: .purple, destination: .messages),
        MoreLink(title: "Agent Hub", subtitle: "Browse and configure AI models", icon: "cpu.fill", color: .blue, destination: .agentHub),
        MoreLink(title: "Pages", subtitle: "Notes and AI context", icon: "doc.on.doc.fill", color: .pink, destination: .pages)
    ]

    private let productivity: [MoreLink] = [
        MoreLink(title: "Tasks", subtitle: "Manage your to-dos", icon: "checkmark.circle", color: .green, destination: .tasks),
        MoreLink(title: "Calendar", subtitle: "Plan events and deadlines", icon: "calendar", color: .red, destination: .calendar),
        MoreLink(title: "Smart Lists", subtitle: "Custom filtered views", icon: "list.bullet.rectangle", color: .orange, destination: .smartLists),
        MoreLink(title: "Templates", subtitle: "Reusable task templates", icon: "doc.text", color: .purple, destination: .templates),
        MoreLink(title: "Recipes", subtitle: "Generate recipes from ingredients", icon: "fork.knife", color: .brown, destination: .recipes)
    ]
    
    private let toolsAndApps: [MoreLink] = [
        MoreLink(title: "Finance", subtitle: "Budgets and spending", icon: "dollarsign.circle", color: .mint, destination: .finance),
        MoreLink(title: "Goals", subtitle: "Track long-term objectives", icon: "flag.fill", color: .yellow, destination: .goals),
        MoreLink(title: "Memories", subtitle: "Journal and photos", icon: "photo.on.rectangle", color: .pink, destination: .memories),
        MoreLink(title: "Shared Files", subtitle: "Collaborative documents", icon: "folder.fill", color: .blue, destination: .sharedFiles)
    ]

    private let customization: [MoreLink] = [
        MoreLink(title: "Themes", subtitle: "Customize colors and styles", icon: "paintpalette.fill", color: .purple, destination: .themes),
        MoreLink(title: "Advanced Features", subtitle: "Power user settings", icon: "slider.horizontal.3", color: .orange, destination: .advancedFeatures)
    ]
    
    private let systemLinks: [MoreLink] = [
        MoreLink(title: "Admin Panel", subtitle: "Server and user management", icon: "shield.fill", color: .red, destination: .admin),
        MoreLink(title: "Settings", subtitle: "App preferences", icon: "gearshape.fill", color: .gray, destination: .settings),
        MoreLink(title: "Help & Support", subtitle: "Get assistance", icon: "questionmark.circle.fill", color: .blue, destination: .help)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: { showIOSFeatures = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discover iOS Features")
                                    .font(.headline)
                                Text("Widgets, Siri, Live Activities & more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                            .foregroundColor(themeManager.textColor)
                    }
                } header: {
                    Text("Quick Actions")
                }

                Section("AI & Communication") {
                    ForEach(aiAndComms) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            MoreRow(item: item)
                        }
                    }
                }

                Section("Productivity") {
                    ForEach(productivity) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            MoreRow(item: item)
                        }
                    }
                }
                
                Section("Apps & Tools") {
                    ForEach(toolsAndApps) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            MoreRow(item: item)
                        }
                    }
                }
                
                Section("Customization") {
                    ForEach(customization) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            MoreRow(item: item)
                        }
                    }
                }

                Section("System") {
                    ForEach(systemLinks) { item in
                        NavigationLink {
                            destinationView(for: item.destination)
                        } label: {
                            MoreRow(item: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                Rectangle()
                    .fill(themeManager.backgroundStyle)
                    .ignoresSafeArea()
            )
            .sheet(isPresented: $showIOSFeatures) {
                IOSFeaturesDetailView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    @ViewBuilder
    private func destinationView(for destination: FeatureDestination) -> some View {
        switch destination {
        case .tasks:
            TaskListView()
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .messages:
            MessagesView()
        case .finance:
            FinanceView()
        case .calendar:
            CalendarView()
        case .pages:
            PagesView()
        case .admin:
            AdminView()
        case .agentHub:
            AgentHubView(onStartChat: { _ in })
        case .recipes:
            RecipeGeneratorView()
        case .goals:
            GoalsView()
        case .memories:
            MemoriesView()
        case .sharedFiles:
            SharedFilesView()
        case .themes:
            ThemeSettingsView()
        case .advancedFeatures:
            AdvancedFeaturesView()
        case .help:
            HelpView()
        case .chat:
            MessagesView() // Legacy redirect
        case .settings:
            SettingsView()
        case .social:
            Text("Social Circles feature coming soon")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Models + Rows

private struct MoreLink: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: FeatureDestination
}

private struct MoreRow: View {
    let item: MoreLink

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: item.icon)
                        .font(.headline)
                        .foregroundColor(item.color)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - iOS Features Detail View (Shared Component)

// This view is shared with the Dashboard's IOSFeaturesWidget
// Defined here to avoid code duplication
struct IOSFeaturesDetailView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("iOS Features")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Enhance your productivity with these powerful iOS integrations")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    // Feature Sections
                    IOSFeatureSection(
                        title: "Home Screen",
                        features: [
                            IOSFeatureDetail(
                                icon: "square.grid.3x3.fill",
                                title: "Widgets",
                                description: "Add Today's Tasks, Calendar, or Quick Add widgets to your home screen. Long-press the home screen, tap +, and search for Cafe.",
                                color: .blue
                            ),
                            IOSFeatureDetail(
                                icon: "hand.point.up.left.fill",
                                title: "Quick Actions",
                                description: "3D Touch or long-press the app icon for quick shortcuts to add tasks, view today's agenda, or start AI chat.",
                                color: .pink
                            )
                        ]
                    )

                    IOSFeatureSection(
                        title: "Real-time Updates",
                        features: [
                            IOSFeatureDetail(
                                icon: "bell.badge.fill",
                                title: "Live Activities",
                                description: "Track active tasks in real-time on your lock screen and Dynamic Island. Start a timer or focus session to see it in action.",
                                color: .purple
                            )
                        ]
                    )

                    IOSFeatureSection(
                        title: "Voice & Search",
                        features: [
                            IOSFeatureDetail(
                                icon: "mic.fill",
                                title: "Siri Shortcuts",
                                description: "Create tasks with your voice. Say 'Hey Siri, add a task' or create custom shortcuts in the Shortcuts app.",
                                color: .orange
                            ),
                            IOSFeatureDetail(
                                icon: "magnifyingglass",
                                title: "Spotlight Search",
                                description: "Search for tasks and events directly from Spotlight. Swipe down on home screen and start typing.",
                                color: .green
                            ),
                            IOSFeatureDetail(
                                icon: "waveform",
                                title: "Speech Recognition",
                                description: "Dictate task titles and descriptions with voice input. Tap the microphone icon in any text field.",
                                color: .indigo
                            )
                        ]
                    )

                    IOSFeatureSection(
                        title: "Continuity",
                        features: [
                            IOSFeatureDetail(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Handoff",
                                description: "Start a task on iPhone and continue on iPad or Mac. Look for the Cafe icon in your dock.",
                                color: .cyan
                            ),
                            IOSFeatureDetail(
                                icon: "moon.fill",
                                title: "Focus Filters",
                                description: "Customize task views for different Focus modes. Set up work vs personal task filters in Settings.",
                                color: .purple
                            )
                        ]
                    )

                    IOSFeatureSection(
                        title: "Advanced",
                        features: [
                            IOSFeatureDetail(
                                icon: "doc.viewfinder",
                                title: "Document Scanning",
                                description: "Scan receipts, documents, or notes to attach to tasks. Use the camera icon when adding attachments.",
                                color: .teal
                            )
                        ]
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct IOSFeatureSection: View {
    let title: String
    let features: [IOSFeatureDetail]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(features) { feature in
                    IOSFeatureDetailRow(feature: feature)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct IOSFeatureDetail: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct IOSFeatureDetailRow: View {
    let feature: IOSFeatureDetail

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(feature.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MoreView()
        .environment(ThemeManager.shared)
}

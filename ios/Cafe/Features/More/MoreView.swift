//
//  MoreView.swift
//  Cafe
//
//  Grid view of all app features
//

import SwiftUI

struct MoreView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var showIOSFeatures = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Header with iOS Features callout
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Explore More")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.textColor)

                                Text("Discover all features and integrations")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            Spacer()

                            // Quick Settings Access
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)

                        // iOS Features Banner
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

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Discover iOS Features")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Widgets, Siri, Live Activities & more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.1),
                                                Color.purple.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    // Productivity Apps
                    FeatureCategorySection(
                        title: "Productivity",
                        icon: "checkmark.circle.fill",
                        color: .green,
                        features: FeatureCard.productivityFeatures
                    )

                    // Communication Apps
                    FeatureCategorySection(
                        title: "Communication",
                        icon: "bubble.left.and.bubble.right.fill",
                        color: .blue,
                        features: FeatureCard.communicationFeatures
                    )

                    // Tools & Utilities
                    FeatureCategorySection(
                        title: "Tools & Utilities",
                        icon: "wrench.and.screwdriver.fill",
                        color: .orange,
                        features: FeatureCard.toolsFeatures
                    )

                    // System & Settings
                    FeatureCategorySection(
                        title: "System",
                        icon: "gearshape.fill",
                        color: .gray,
                        features: FeatureCard.systemFeatures
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationDestination(for: FeatureDestination.self) { destination in
                destinationView(for: destination)
            }
            .sheet(isPresented: $showIOSFeatures) {
                IOSFeaturesDetailView()
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                }
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
        case .chat:
            ChatView()
        case .settings:
            SettingsView()
        case .social:
            SocialCirclesView()
        }
    }
}

// MARK: - Feature Category Section

struct FeatureCategorySection: View {
    let title: String
    let icon: String
    let color: Color
    let features: [FeatureCard]
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(features) { feature in
                    FeatureCardView(feature: feature)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Feature Card Model

struct FeatureCard: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let destination: FeatureDestination
    let description: String

    static let allFeatures: [FeatureCard] = productivityFeatures + communicationFeatures + toolsFeatures + systemFeatures

    static let productivityFeatures: [FeatureCard] = [
        FeatureCard(
            title: "Tasks",
            icon: "checkmark.circle",
            color: .green,
            destination: .tasks,
            description: "Manage your tasks"
        ),
        FeatureCard(
            title: "Calendar",
            icon: "calendar",
            color: .red,
            destination: .calendar,
            description: "Schedule events"
        ),
        FeatureCard(
            title: "Templates",
            icon: "doc.text",
            color: .purple,
            destination: .templates,
            description: "Reusable task templates"
        ),
        FeatureCard(
            title: "Smart Lists",
            icon: "list.bullet.rectangle",
            color: .orange,
            destination: .smartLists,
            description: "Custom filtered views"
        )
    ]

    static let communicationFeatures: [FeatureCard] = [
        FeatureCard(
            title: "AI Chat",
            icon: "sparkles",
            color: .pink,
            destination: .chat,
            description: "AI assistant"
        ),
        FeatureCard(
            title: "Messages",
            icon: "message",
            color: .cyan,
            destination: .messages,
            description: "Team collaboration"
        ),
        FeatureCard(
            title: "Social Circles",
            icon: "person.3.sequence.fill",
            color: .orange,
            destination: .social,
            description: "Group pulse board"
        )
    ]

    static let toolsFeatures: [FeatureCard] = [
        FeatureCard(
            title: "Finance",
            icon: "dollarsign.circle",
            color: .teal,
            destination: .finance,
            description: "Budget tracking"
        )
    ]

    static let systemFeatures: [FeatureCard] = [
        FeatureCard(
            title: "Settings",
            icon: "gearshape",
            color: .gray,
            destination: .settings,
            description: "App preferences"
        )
    ]
}

enum FeatureDestination {
    case tasks
    case templates
    case smartLists
    case messages
    case finance
    case calendar
    case chat
    case settings
    case social
}

// MARK: - Feature Card View

struct FeatureCardView: View {
    let feature: FeatureCard
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        NavigationLink(value: feature.destination) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(feature.color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: feature.icon)
                        .font(.system(size: 28))
                        .foregroundColor(feature.color)
                }

                // Title
                Text(feature.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)

                // Description
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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

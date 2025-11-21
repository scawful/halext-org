//
//  HelpView.swift
//  Cafe
//
//  Comprehensive help and documentation for all app features
//

import SwiftUI

struct HelpView: View {
    @Environment(ThemeManager.self) var themeManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil
    @State private var expandedSections: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    helpHeader

                    // Quick Links
                    quickLinksSection

                    // Feature Status
                    if searchText.isEmpty || "features status".contains(searchText.lowercased()) {
                        featureStatusSection
                    }

                    // Getting Started
                    if searchText.isEmpty || "getting started guide tutorial".contains(searchText.lowercased()) {
                        gettingStartedSection
                    }

                    // FAQ
                    if searchText.isEmpty || "faq questions answers".contains(searchText.lowercased()) {
                        faqSection
                    }

                    // Troubleshooting
                    if searchText.isEmpty || "troubleshooting problems issues fix".contains(searchText.lowercased()) {
                        troubleshootingSection
                    }

                    // About
                    if searchText.isEmpty || "about version credits".contains(searchText.lowercased()) {
                        aboutSection
                    }
                }
                .padding()
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search help topics...")
        }
    }

    // MARK: - Header

    private var helpHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("How can we help you?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)

            Text("Find answers, learn features, and get support")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Quick Links

    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Links")
                .font(.headline)
                .foregroundColor(themeManager.textColor)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickLinkCard(
                    title: "iOS Features",
                    icon: "sparkles",
                    color: .blue,
                    destination: .iosFeatures
                )

                QuickLinkCard(
                    title: "Advanced",
                    icon: "wand.and.stars",
                    color: .purple,
                    destination: .advanced
                )

                QuickLinkCard(
                    title: "Settings",
                    icon: "gearshape",
                    color: .gray,
                    destination: .settings
                )

                QuickLinkCard(
                    title: "Contact",
                    icon: "envelope",
                    color: .green,
                    destination: .contact
                )
            }
        }
    }

    // MARK: - Feature Status Section

    private var featureStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.blue)
                Text("Feature Status")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }

            VStack(spacing: 12) {
                // Core Features
                FeatureStatusCategory(title: "Core Features") {
                    FeatureStatusRow(
                        name: "Tasks & Lists",
                        description: "Create, manage, and organize tasks",
                        status: .ready,
                        icon: "checkmark.circle"
                    )

                    FeatureStatusRow(
                        name: "Calendar & Events",
                        description: "Schedule and manage events",
                        status: .ready,
                        icon: "calendar"
                    )

                    FeatureStatusRow(
                        name: "AI Chat Assistant",
                        description: "Get help from AI-powered assistant",
                        status: .ready,
                        icon: "sparkles"
                    )

                    FeatureStatusRow(
                        name: "Smart Task Generator",
                        description: "Generate tasks from natural language",
                        status: .ready,
                        icon: "wand.and.stars"
                    )
                }

                // Productivity Features
                FeatureStatusCategory(title: "Productivity") {
                    FeatureStatusRow(
                        name: "Task Templates",
                        description: "Reusable task templates",
                        status: .ready,
                        icon: "doc.text"
                    )

                    FeatureStatusRow(
                        name: "Smart Lists",
                        description: "Dynamic filtered task views",
                        status: .ready,
                        icon: "list.bullet.rectangle"
                    )

                    FeatureStatusRow(
                        name: "Pages & Notes",
                        description: "Rich text documents",
                        status: .planned,
                        icon: "doc.richtext"
                    )

                    FeatureStatusRow(
                        name: "Recipe Generator",
                        description: "AI-powered meal planning",
                        status: .ready,
                        icon: "fork.knife"
                    )
                }

                // iOS Integration
                FeatureStatusCategory(title: "iOS Integration") {
                    FeatureStatusRow(
                        name: "Widgets",
                        description: "Home & Lock Screen widgets",
                        status: .ready,
                        icon: "square.stack.3d.up"
                    )

                    FeatureStatusRow(
                        name: "Siri Shortcuts",
                        description: "Voice commands and automation",
                        status: .ready,
                        icon: "mic"
                    )

                    FeatureStatusRow(
                        name: "Live Activities",
                        description: "Dynamic Island task tracking",
                        status: .ready,
                        icon: "apps.iphone"
                    )

                    FeatureStatusRow(
                        name: "Spotlight Search",
                        description: "System-wide task search",
                        status: .ready,
                        icon: "magnifyingglass"
                    )

                    FeatureStatusRow(
                        name: "Voice Input",
                        description: "Speech-to-text for tasks",
                        status: .ready,
                        icon: "waveform"
                    )

                    FeatureStatusRow(
                        name: "Document Scanner",
                        description: "Scan documents with OCR",
                        status: .ready,
                        icon: "doc.viewfinder"
                    )

                    FeatureStatusRow(
                        name: "Focus Filters",
                        description: "Filter tasks by Focus mode",
                        status: .ready,
                        icon: "moon.circle"
                    )

                    FeatureStatusRow(
                        name: "Handoff",
                        description: "Continue on other devices",
                        status: .ready,
                        icon: "arrow.triangle.2.circlepath"
                    )
                }

                // Communication
                FeatureStatusCategory(title: "Communication") {
                    FeatureStatusRow(
                        name: "Messages",
                        description: "Personal messaging and AI conversations",
                        status: .inProgress,
                        icon: "message"
                    )

                    FeatureStatusRow(
                        name: "Conversations",
                        description: "Chat with AI assistants and contacts",
                        status: .inProgress,
                        icon: "person.3"
                    )
                }

                // Customization
                FeatureStatusCategory(title: "Customization") {
                    FeatureStatusRow(
                        name: "Themes",
                        description: "Light, dark, and custom themes",
                        status: .ready,
                        icon: "paintbrush"
                    )

                    FeatureStatusRow(
                        name: "Custom Gestures",
                        description: "Swipe actions and shortcuts",
                        status: .ready,
                        icon: "hand.point.up.left"
                    )

                    FeatureStatusRow(
                        name: "Biometric Lock",
                        description: "Face ID / Touch ID security",
                        status: .ready,
                        icon: "faceid"
                    )
                }

                // Finance & Tracking
                FeatureStatusCategory(title: "Finance") {
                    FeatureStatusRow(
                        name: "Budget Tracking",
                        description: "Track expenses and budgets",
                        status: .inProgress,
                        icon: "dollarsign.circle"
                    )
                }

                // Admin Features
                FeatureStatusCategory(title: "Admin (Beta)") {
                    FeatureStatusRow(
                        name: "User Management",
                        description: "Manage users and permissions",
                        status: .ready,
                        icon: "person.2"
                    )

                    FeatureStatusRow(
                        name: "AI Client Management",
                        description: "Configure AI providers",
                        status: .ready,
                        icon: "cpu"
                    )

                    FeatureStatusRow(
                        name: "Content Management",
                        description: "Manage app content",
                        status: .ready,
                        icon: "folder"
                    )
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - Getting Started Section

    private var gettingStartedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.circle")
                    .foregroundColor(.green)
                Text("Getting Started")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }

            VStack(spacing: 16) {
                // Creating Tasks
                GettingStartedCard(
                    title: "Creating Your First Task",
                    icon: "plus.circle",
                    color: .blue,
                    isExpanded: expandedSections.contains("create-task")
                ) {
                    toggleSection("create-task")
                } content: {
                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Tap the Tasks tab in the navigation bar")
                        StepRow(number: 2, text: "Tap the + button in the top right")
                        StepRow(number: 3, text: "Enter a task title and optional description")
                        StepRow(number: 4, text: "Set a due date by tapping the calendar icon")
                        StepRow(number: 5, text: "Add labels to organize your task")
                        StepRow(number: 6, text: "Tap Save to create the task")

                        TipBox(text: "Swipe left on any task to quickly mark it as complete or delete it")
                    }
                }

                // Voice Input
                GettingStartedCard(
                    title: "Using Voice Input",
                    icon: "mic.fill",
                    color: .orange,
                    isExpanded: expandedSections.contains("voice-input")
                ) {
                    toggleSection("voice-input")
                } content: {
                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Go to Settings > Power User > Advanced Features")
                        StepRow(number: 2, text: "Enable Speech Recognition permissions")
                        StepRow(number: 3, text: "When creating a task, tap the microphone icon")
                        StepRow(number: 4, text: "Speak your task title or description")
                        StepRow(number: 5, text: "Tap done when finished")

                        TipBox(text: "Voice input works offline after initial setup and supports multiple languages")
                    }
                }

                // Calendar Events
                GettingStartedCard(
                    title: "Setting Up Calendar Events",
                    icon: "calendar.badge.plus",
                    color: .red,
                    isExpanded: expandedSections.contains("calendar")
                ) {
                    toggleSection("calendar")
                } content: {
                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Navigate to the Calendar tab")
                        StepRow(number: 2, text: "Tap the + button to create an event")
                        StepRow(number: 3, text: "Enter event title, time, and location")
                        StepRow(number: 4, text: "Set recurring events if needed")
                        StepRow(number: 5, text: "Add optional notes and save")

                        TipBox(text: "Events automatically sync with your device calendar and can be searched via Spotlight")
                    }
                }

                // AI Features
                GettingStartedCard(
                    title: "Using AI Features",
                    icon: "sparkles",
                    color: .purple,
                    isExpanded: expandedSections.contains("ai-features")
                ) {
                    toggleSection("ai-features")
                } content: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Chat Assistant")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        StepRow(number: 1, text: "Tap the Chat tab to open AI assistant")
                        StepRow(number: 2, text: "Type or speak your question or request")
                        StepRow(number: 3, text: "The AI will respond with helpful information")

                        Divider()
                            .padding(.vertical, 4)

                        Text("Smart Task Generator")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        StepRow(number: 1, text: "From Dashboard, tap 'AI Task Generator'")
                        StepRow(number: 2, text: "Describe what you want to accomplish in plain English")
                        StepRow(number: 3, text: "Review the AI-generated tasks and subtasks")
                        StepRow(number: 4, text: "Edit if needed, then create tasks")

                        TipBox(text: "The AI can break down complex projects, suggest time estimates, and recommend priorities")
                    }
                }

                // Document Scanning
                GettingStartedCard(
                    title: "Document Scanning",
                    icon: "doc.viewfinder",
                    color: .teal,
                    isExpanded: expandedSections.contains("scanner")
                ) {
                    toggleSection("scanner")
                } content: {
                    VStack(alignment: .leading, spacing: 12) {
                        StepRow(number: 1, text: "Ensure camera permissions are enabled")
                        StepRow(number: 2, text: "Go to Settings > Advanced Features > Document Scanner")
                        StepRow(number: 3, text: "Tap 'Test Scanner' to try it out")
                        StepRow(number: 4, text: "Point camera at document and tap capture")
                        StepRow(number: 5, text: "AI will extract text using OCR")

                        TipBox(text: "Perfect for capturing receipts, notes, or business cards. Scanned text can be used to create tasks automatically")
                    }
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - FAQ Section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.bubble")
                    .foregroundColor(.purple)
                Text("Frequently Asked Questions")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }

            VStack(spacing: 12) {
                FAQItem(
                    question: "How do I sync my data across devices?",
                    answer: "Your data is automatically synced to the cloud when you're signed in. Use Handoff to continue working on other Apple devices. Make sure you're signed in with the same account on all devices.",
                    isExpanded: expandedSections.contains("faq-sync")
                ) {
                    toggleSection("faq-sync")
                }

                FAQItem(
                    question: "Can I use the app offline?",
                    answer: "Yes! Most features work offline. Your tasks, events, and notes are stored locally. Changes will sync automatically when you're back online. Voice input also works offline after initial setup.",
                    isExpanded: expandedSections.contains("faq-offline")
                ) {
                    toggleSection("faq-offline")
                }

                FAQItem(
                    question: "How do I add widgets to my home screen?",
                    answer: "Long-press on your home screen, tap the + button in the top left, search for 'Cafe', and select the widget size you want. You can customize widget content in Settings > Widgets.",
                    isExpanded: expandedSections.contains("faq-widgets")
                ) {
                    toggleSection("faq-widgets")
                }

                FAQItem(
                    question: "How do I set up Siri shortcuts?",
                    answer: "Open the Shortcuts app, tap +, search for 'Cafe' in the app list, and select the action you want. Give it a name, then say 'Hey Siri' followed by that name. See Settings > Advanced Features for available shortcuts.",
                    isExpanded: expandedSections.contains("faq-siri")
                ) {
                    toggleSection("faq-siri")
                }

                FAQItem(
                    question: "What is a Live Activity?",
                    answer: "Live Activities show your active tasks in the Dynamic Island and Lock Screen on iPhone 14 Pro and newer. Start a task timer to see it appear. Available on iOS 16.1 and later.",
                    isExpanded: expandedSections.contains("faq-live")
                ) {
                    toggleSection("faq-live")
                }

                FAQItem(
                    question: "How do I change the app theme?",
                    answer: "Go to Settings > Appearance > Theme Switcher. Choose from light, dark, or several preset themes. You can also create custom themes with your own colors in Advanced Theming.",
                    isExpanded: expandedSections.contains("faq-theme")
                ) {
                    toggleSection("faq-theme")
                }

                FAQItem(
                    question: "Can I share tasks with others?",
                    answer: "Messaging features allow you to communicate with contacts. Sharing and collaboration features are experimental and can be accessed through Messages.",
                    isExpanded: expandedSections.contains("faq-share")
                ) {
                    toggleSection("faq-share")
                }

                FAQItem(
                    question: "How do Focus Filters work?",
                    answer: "When you activate a Focus mode on your device, Cafe can automatically filter tasks to show only relevant items. Configure which labels appear in each Focus mode in Settings > Advanced Features > Focus Filters.",
                    isExpanded: expandedSections.contains("faq-focus")
                ) {
                    toggleSection("faq-focus")
                }

                FAQItem(
                    question: "Is my data private and secure?",
                    answer: "Yes! Your data is encrypted in transit and at rest. Enable Face ID/Touch ID app lock in Settings for extra security. We never share your data with third parties. Admin users have additional security controls.",
                    isExpanded: expandedSections.contains("faq-privacy")
                ) {
                    toggleSection("faq-privacy")
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - Troubleshooting Section

    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.orange)
                Text("Troubleshooting")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }

            VStack(spacing: 12) {
                TroubleshootingItem(
                    problem: "Widgets not updating",
                    solution: "Make sure Background App Refresh is enabled for Cafe in Settings. Go to iOS Settings > General > Background App Refresh and enable it for Cafe. Also check Settings > Widgets in the app.",
                    isExpanded: expandedSections.contains("trouble-widgets")
                ) {
                    toggleSection("trouble-widgets")
                }

                TroubleshootingItem(
                    problem: "Voice input not working",
                    solution: "Check that microphone permissions are enabled in iOS Settings > Cafe > Microphone. Also enable Speech Recognition in Settings > Privacy & Security > Speech Recognition and select Cafe.",
                    isExpanded: expandedSections.contains("trouble-voice")
                ) {
                    toggleSection("trouble-voice")
                }

                TroubleshootingItem(
                    problem: "Notifications not appearing",
                    solution: "Enable notifications in iOS Settings > Cafe > Notifications. Make sure 'Allow Notifications' is on and your preferred alert style is selected. Check that Do Not Disturb or Focus mode isn't blocking them.",
                    isExpanded: expandedSections.contains("trouble-notif")
                ) {
                    toggleSection("trouble-notif")
                }

                TroubleshootingItem(
                    problem: "Siri shortcuts not responding",
                    solution: "Open the Shortcuts app and check that your Cafe shortcuts are properly configured. Try deleting and recreating the shortcut. Make sure Siri is enabled in iOS Settings > Siri & Search.",
                    isExpanded: expandedSections.contains("trouble-siri")
                ) {
                    toggleSection("trouble-siri")
                }

                TroubleshootingItem(
                    problem: "Tasks not syncing",
                    solution: "Check your internet connection. Sign out and sign back in from Settings. If the problem persists, try force-quitting the app and reopening it. Your local data is always safe.",
                    isExpanded: expandedSections.contains("trouble-sync")
                ) {
                    toggleSection("trouble-sync")
                }

                TroubleshootingItem(
                    problem: "Face ID / Touch ID not working",
                    solution: "Ensure biometric authentication is set up in iOS Settings. Go to Cafe Settings > Security and toggle the biometric lock option off and on again. Make sure you're using the latest iOS version.",
                    isExpanded: expandedSections.contains("trouble-biometric")
                ) {
                    toggleSection("trouble-biometric")
                }

                TroubleshootingItem(
                    problem: "Handoff not working",
                    solution: "Make sure Handoff is enabled on all devices in Settings > General > AirPlay & Handoff. Ensure all devices are signed in to the same iCloud account and have Bluetooth and WiFi enabled.",
                    isExpanded: expandedSections.contains("trouble-handoff")
                ) {
                    toggleSection("trouble-handoff")
                }

                TroubleshootingItem(
                    problem: "App running slowly",
                    solution: "Try force-quitting and restarting the app. Clear old cached data in Settings > Advanced. Make sure you have the latest version of the app. If problems persist, try reinstalling the app.",
                    isExpanded: expandedSections.contains("trouble-slow")
                ) {
                    toggleSection("trouble-slow")
                }
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("About Cafe")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textColor)
            }

            VStack(spacing: 16) {
                // App Info
                VStack(spacing: 12) {
                    HStack {
                        Text("Version")
                            .foregroundColor(themeManager.secondaryTextColor)
                        Spacer()
                        Text(appVersion)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                    }

                    Divider()

                    HStack {
                        Text("Build")
                            .foregroundColor(themeManager.secondaryTextColor)
                        Spacer()
                        Text(buildNumber)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textColor)
                    }
                }

                Divider()

                // Credits
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credits")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)

                    Text("Developed with passion to help you stay productive and organized.")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }

                Divider()

                // Links
                VStack(spacing: 12) {
                    AboutLinkButton(
                        icon: "hand.raised",
                        title: "Privacy Policy",
                        url: "https://halext.org/privacy"
                    )

                    AboutLinkButton(
                        icon: "doc.text",
                        title: "Terms of Service",
                        url: "https://halext.org/terms"
                    )

                    AboutLinkButton(
                        icon: "globe",
                        title: "Website",
                        url: "https://halext.org"
                    )
                }

                Divider()

                // Technologies
                VStack(alignment: .leading, spacing: 8) {
                    Text("Powered By")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)

                    FlowLayout(spacing: 8) {
                        TechnologyBadge(name: "SwiftUI")
                        TechnologyBadge(name: "Vision")
                        TechnologyBadge(name: "Speech")
                        TechnologyBadge(name: "WidgetKit")
                        TechnologyBadge(name: "ActivityKit")
                        TechnologyBadge(name: "CloudKit")
                        TechnologyBadge(name: "Core ML")
                    }
                }

                // Copyright
                Text("© 2024 Halext - Experimental project")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    // MARK: - Helper Methods

    private func toggleSection(_ id: String) {
        withAnimation {
            if expandedSections.contains(id) {
                expandedSections.remove(id)
            } else {
                expandedSections.insert(id)
            }
        }
    }

    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

// MARK: - Supporting Views

struct QuickLinkCard: View {
    let title: String
    let icon: String
    let color: Color
    let destination: HelpDestination

    var body: some View {
        NavigationLink(value: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(height: 30)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .navigationDestination(for: HelpDestination.self) { dest in
            destinationView(for: dest)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: HelpDestination) -> some View {
        switch destination {
        case .iosFeatures:
            IOSFeaturesDetailView()
        case .advanced:
            AdvancedFeaturesView()
        case .settings:
            SettingsView()
        case .contact:
            VStack(spacing: 16) {
                Text("For questions or feedback, visit halext.org")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Contact")
        }
    }
}

struct FeatureStatusCategory<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    content
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeatureStatusRow: View {
    let name: String
    let description: String
    let status: FeatureReadyStatus
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text(status.emoji)
                    .font(.caption)
                Text(status.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .foregroundColor(status.color)
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

struct GettingStartedCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let isExpanded: Bool
    let onTap: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TipBox: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TroubleshootingItem: View {
    let problem: String
    let solution: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(problem)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.green)

                    Text(solution)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TechnologyBadge: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum HelpCategory: String, CaseIterable, Identifiable {
    case features = "Features"
    case gettingStarted = "Getting Started"
    case faq = "FAQ"
    case troubleshooting = "Troubleshooting"
    case about = "About"

    var id: String { rawValue }
}

enum HelpDestination: Hashable {
    case iosFeatures
    case advanced
    case settings
    case contact
}

enum FeatureReadyStatus {
    case ready
    case inProgress
    case planned

    var displayName: String {
        switch self {
        case .ready: return "Ready"
        case .inProgress: return "In Progress"
        case .planned: return "Planned"
        }
    }

    var emoji: String {
        switch self {
        case .ready: return "✅"
        case .inProgress: return "🚧"
        case .planned: return "📋"
        }
    }

    var color: Color {
        switch self {
        case .ready: return .green
        case .inProgress: return .orange
        case .planned: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    HelpView()
        .environment(ThemeManager.shared)
}

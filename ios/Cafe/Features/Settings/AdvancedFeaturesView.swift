//
//  AdvancedFeaturesView.swift
//  Cafe
//
//  Advanced iOS features settings and controls
//  Exposes all the hidden power user features like Shortcuts, Live Activities, etc.
//

import SwiftUI
import Speech
import VisionKit
import ActivityKit

struct AdvancedFeaturesView: View {
    @State private var speechManager = SpeechRecognitionManager.shared
    @State private var scannerManager = DocumentScannerManager.shared
    @State private var focusManager = FocusFilterManager.shared
    @State private var liveActivityManager = TaskLiveActivityManager.shared

    @State private var showingShortcutsInfo = false
    @State private var showingFocusConfig = false
    @State private var showingVoiceTest = false
    @State private var showingScannerTest = false

    var body: some View {
        List {
            // Pro Tips Section
            proTipsSection

            // Siri & Shortcuts
            shortcutsSection

            // Focus Filters
            focusFiltersSection

            // Document Scanning
            documentScanningSection

            // Speech Recognition
            speechRecognitionSection

            // Live Activities
            liveActivitiesSection

            // Handoff & Continuity
            handoffSection

            // Quick Actions
            quickActionsSection

            // Spotlight Search
            spotlightSection

            // Other Advanced Features
            otherFeaturesSection
        }
        .navigationTitle("Advanced Features")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingShortcutsInfo) {
            ShortcutsInfoView()
        }
        .sheet(isPresented: $showingFocusConfig) {
            FocusConfigView()
        }
        .sheet(isPresented: $showingVoiceTest) {
            VoiceInputView(isPresented: $showingVoiceTest) { text in
                print("Voice input: \(text)")
            }
        }
    }

    // MARK: - Pro Tips Section

    private var proTipsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("Power User Features")
                        .font(.headline)
                }

                Text("Unlock the full potential of Cafe with these advanced iOS integrations. These features work seamlessly with your device to boost productivity.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "apple.shortcuts",
                    iconColor: .orange,
                    title: "Siri Shortcuts",
                    description: "Control tasks with voice commands",
                    status: .available
                )

                Button(action: { showingShortcutsInfo = true }) {
                    HStack {
                        Text("View Available Shortcuts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: openShortcutsApp) {
                    HStack {
                        Text("Open Shortcuts App")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .font(.caption)
                    }
                }
            }
        } header: {
            Text("Siri & Shortcuts")
        } footer: {
            Text("Add Cafe shortcuts to Siri for quick voice access. Available shortcuts: Create Task, Complete Task, Search Tasks, Get Tasks Count, and more.")
        }
    }

    // MARK: - Focus Filters Section

    private var focusFiltersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "moon.circle.fill",
                    iconColor: .purple,
                    title: "Focus Filters",
                    description: "Filter tasks based on Focus mode",
                    status: .available
                )

                if let currentMode = focusManager.currentFocusMode {
                    HStack {
                        Text("Current Focus")
                        Spacer()
                        Text(currentMode.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }

                Toggle("Priority Tasks Only", isOn: $focusManager.showOnlyPriority)
                    .disabled(focusManager.currentFocusMode == nil)

                Button(action: { showingFocusConfig = true }) {
                    HStack {
                        Text("Configure Focus Filters")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Focus Filters")
        } footer: {
            Text("When a Focus mode is active, Cafe can filter your tasks and events to show only relevant items. Configure which labels appear in each Focus mode.")
        }
    }

    // MARK: - Document Scanning Section

    private var documentScanningSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "doc.text.viewfinder",
                    iconColor: .blue,
                    title: "Document Scanner",
                    description: "Scan documents with OCR",
                    status: scannerManager.isDocumentScannerAvailable ? .available : .unavailable
                )

                if scannerManager.isDocumentScannerAvailable {
                    Button(action: { showingScannerTest = true }) {
                        HStack {
                            Text("Test Scanner")
                            Spacer()
                            Image(systemName: "camera.viewfinder")
                                .font(.caption)
                        }
                    }
                    .disabled(!scannerManager.isDocumentScannerAvailable)

                    Text("Scan receipts, notes, or any document and extract text instantly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                } else {
                    Text("Document scanner not available on this device")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        } header: {
            Text("Document Scanning")
        } footer: {
            Text("Use the device camera to scan documents and extract text using OCR. Perfect for quickly capturing meeting notes or receipts.")
        }
        .sheet(isPresented: $showingScannerTest) {
            DocumentScannerTestView(isPresented: $showingScannerTest)
        }
    }

    // MARK: - Speech Recognition Section

    private var speechRecognitionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "mic.fill",
                    iconColor: .red,
                    title: "Voice Input",
                    description: "Create tasks with your voice",
                    status: speechManager.isAuthorized ? .enabled : .requiresPermission
                )

                if !speechManager.isAuthorized {
                    Button("Enable Speech Recognition") {
                        _Concurrency.Task {
                            let authorized = await speechManager.requestAuthorization()
                            if !authorized {
                                // Show alert to go to settings
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    await UIApplication.shared.open(url)
                                }
                            }
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Button(action: { showingVoiceTest = true }) {
                        HStack {
                            Text("Test Voice Input")
                            Spacer()
                            Image(systemName: "waveform")
                                .font(.caption)
                        }
                    }

                    Text("Speak naturally to create tasks hands-free")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        } header: {
            Text("Speech Recognition")
        } footer: {
            Text("Use voice input to quickly create tasks or notes without typing. Works even when offline after initial setup.")
        }
    }

    // MARK: - Live Activities Section

    private var liveActivitiesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "apps.iphone",
                    iconColor: .indigo,
                    title: "Live Activities",
                    description: "Track tasks in Dynamic Island",
                    status: liveActivityManager.isLiveActivitySupported ? .available : .unavailable
                )

                if liveActivityManager.isLiveActivitySupported {
                    Text("Start a task timer to see it in the Dynamic Island and on your Lock Screen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text("Long press a task to start tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Live Activities require iOS 16.1+ and iPhone 14 Pro or newer")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        } header: {
            Text("Live Activities")
        } footer: {
            Text("Track your active tasks in real-time with Live Activities in the Dynamic Island, Lock Screen, and StandBy mode.")
        }
    }

    // MARK: - Handoff Section

    private var handoffSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "arrow.triangle.2.circlepath",
                    iconColor: .green,
                    title: "Handoff",
                    description: "Continue on other devices",
                    status: .available
                )

                Text("Start viewing a task on iPhone and continue on your Mac, iPad, or web browser")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Button("Configure in System Settings") {
                    if let url = URL(string: "App-prefs:") {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.subheadline)
            }
        } header: {
            Text("Handoff & Continuity")
        } footer: {
            Text("Seamlessly switch between your Apple devices. Make sure Handoff is enabled in System Settings > General > AirPlay & Handoff.")
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "hand.tap.fill",
                    iconColor: .pink,
                    title: "Quick Actions",
                    description: "3D Touch home screen shortcuts",
                    status: .available
                )

                VStack(alignment: .leading, spacing: 4) {
                    QuickActionItem(title: "New Task", icon: "plus.circle")
                    QuickActionItem(title: "New Event", icon: "calendar.badge.plus")
                    QuickActionItem(title: "Today's Tasks", icon: "checkmark.circle")
                    QuickActionItem(title: "AI Assistant", icon: "sparkles")
                }
                .padding(.vertical, 4)

                Text("Long press the Cafe app icon to access these shortcuts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Quick Actions")
        } footer: {
            Text("Press and hold the Cafe app icon on your home screen to reveal quick action shortcuts.")
        }
    }

    // MARK: - Spotlight Section

    private var spotlightSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(
                    icon: "magnifyingglass",
                    iconColor: .gray,
                    title: "Spotlight Search",
                    description: "Find tasks from system search",
                    status: .available
                )

                Button("Reindex Content") {
                    _Concurrency.Task {
                        // Trigger reindex
                        let tasks = try? await APIClient.shared.getTasks()
                        if let tasks = tasks {
                            await SpotlightManager.shared.indexTasks(tasks)
                        }

                        let events = try? await APIClient.shared.getEvents()
                        if let events = events {
                            await SpotlightManager.shared.indexEvents(events)
                        }
                    }
                }

                Text("Search for your tasks and events from the iPhone search screen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        } header: {
            Text("Spotlight Search")
        } footer: {
            Text("Your tasks and events are automatically indexed for system-wide search. Swipe down on the home screen and search for any task or event.")
        }
    }

    // MARK: - Other Features Section

    private var otherFeaturesSection: some View {
        Section {
            FeatureRow(
                icon: "hand.point.up.left.fill",
                iconColor: .orange,
                title: "Custom Gestures",
                description: "Swipe gestures for quick actions",
                status: .available
            )

            FeatureRow(
                icon: "widget.small.fill",
                iconColor: .blue,
                title: "Home Screen Widgets",
                description: "Add widgets to your home screen",
                status: .available
            )

            FeatureRow(
                icon: "bell.badge.fill",
                iconColor: .red,
                title: "Smart Notifications",
                description: "Intelligent task reminders",
                status: .available
            )

            FeatureRow(
                icon: "shield.lefthalf.filled",
                iconColor: .blue,
                title: "Biometric Lock",
                description: "Face ID / Touch ID app lock",
                status: .available
            )
        } header: {
            Text("Other Features")
        } footer: {
            Text("Additional power user features are available throughout the app. Explore settings to customize your experience.")
        }
    }

    // MARK: - Helper Methods

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let status: FeatureStatus

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()

                    StatusBadge(status: status)
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: FeatureStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)

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
}

enum FeatureStatus {
    case available
    case enabled
    case disabled
    case requiresPermission
    case unavailable

    var displayName: String {
        switch self {
        case .available: return "Available"
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .requiresPermission: return "Needs Permission"
        case .unavailable: return "Unavailable"
        }
    }

    var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .enabled: return "checkmark.circle.fill"
        case .disabled: return "xmark.circle.fill"
        case .requiresPermission: return "exclamationmark.triangle.fill"
        case .unavailable: return "slash.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .available: return .green
        case .enabled: return .green
        case .disabled: return .gray
        case .requiresPermission: return .orange
        case .unavailable: return .red
        }
    }
}

// MARK: - Quick Action Item

struct QuickActionItem: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(title)
                .font(.caption)
        }
    }
}

// MARK: - Shortcuts Info View

struct ShortcutsInfoView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Cafe provides powerful Siri Shortcuts that let you control your tasks with voice commands or automation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("Available Shortcuts") {
                    ShortcutInfoItem(
                        name: "Create Task",
                        description: "Quickly create a new task by speaking its title",
                        example: "Hey Siri, create a task in Cafe"
                    )

                    ShortcutInfoItem(
                        name: "Complete Task",
                        description: "Mark a task as complete by name",
                        example: "Hey Siri, complete task Buy groceries"
                    )

                    ShortcutInfoItem(
                        name: "Search Tasks",
                        description: "Find tasks matching a keyword",
                        example: "Hey Siri, search for meeting tasks"
                    )

                    ShortcutInfoItem(
                        name: "Get Tasks Count",
                        description: "Get count of tasks by status",
                        example: "Hey Siri, how many tasks are overdue?"
                    )

                    ShortcutInfoItem(
                        name: "Create Multiple Tasks",
                        description: "Create several tasks from a list",
                        example: "Create tasks from list in Cafe"
                    )

                    ShortcutInfoItem(
                        name: "Get Next Event",
                        description: "Find your next upcoming event",
                        example: "Hey Siri, what's my next event?"
                    )
                }

                Section("How to Add to Siri") {
                    VStack(alignment: .leading, spacing: 12) {
                        ShortcutInstructionStep(number: 1, text: "Open the Shortcuts app")
                        ShortcutInstructionStep(number: 2, text: "Tap the + button to create a new shortcut")
                        ShortcutInstructionStep(number: 3, text: "Search for 'Cafe' in the app list")
                        ShortcutInstructionStep(number: 4, text: "Select the action you want to add")
                        ShortcutInstructionStep(number: 5, text: "Configure the shortcut and give it a name")
                        ShortcutInstructionStep(number: 6, text: "Say 'Hey Siri' followed by your shortcut name")
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Siri Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShortcutInfoItem: View {
    let name: String
    let description: String
    let example: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "quote.bubble")
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(example)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .italic()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

struct ShortcutInstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Focus Config View

struct FocusConfigView: View {
    @Environment(\.dismiss) var dismiss
    @State private var focusManager = FocusFilterManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Configure which tasks appear when different Focus modes are active. Cafe filters tasks based on their labels and keywords.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ForEach([FocusMode.work, .personal, .fitness, .reading, .gaming, .sleep, .driving], id: \.self) { mode in
                    Section(mode.rawValue.capitalized) {
                        Text("Suggested labels:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        FlowLayout(spacing: 8) {
                            ForEach(focusManager.suggestedLabels(for: mode), id: \.self) { label in
                                Text(label)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Focus Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Document Scanner Test View

struct DocumentScannerTestView: View {
    @Binding var isPresented: Bool
    @State private var scannedImages: [UIImage] = []
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            VStack {
                if scannedImages.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Scan a Document")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Use your camera to scan documents and extract text")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: { showScanner = true }) {
                            Label("Start Scanning", systemImage: "camera.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scanned Images")
                                .font(.headline)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(scannedImages.indices, id: \.self) { index in
                                        Image(uiImage: scannedImages[index])
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 150)
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            Divider()
                                .padding(.horizontal)

                            Text("Recognized Text")
                                .font(.headline)
                                .padding(.horizontal)

                            if isProcessing {
                                ProgressView("Processing...")
                                    .padding()
                            } else if !recognizedText.isEmpty {
                                Text(recognizedText)
                                    .font(.body)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                            } else {
                                Text("No text recognized")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Document Scanner Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentScannerView(isPresented: $showScanner) { images in
                    scannedImages = images
                    processScannedImages(images)
                }
            }
        }
    }

    private func processScannedImages(_ images: [UIImage]) {
        isProcessing = true

        _Concurrency.Task {
            do {
                let text = try await DocumentScannerManager.shared.recognizeTextFromMultipleImages(images)
                recognizedText = text
            } catch {
                recognizedText = "Error: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }
}

// MARK: - Flow Layout (for label chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AdvancedFeaturesView()
    }
}

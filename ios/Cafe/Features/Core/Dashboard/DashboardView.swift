//
//  DashboardView.swift
//  Cafe
//
//  Main dashboard with productivity widgets
//

import SwiftUI

struct DashboardView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var viewModel = DashboardViewModel()
    @State private var showAIGenerator = false
    @State private var showingLayoutEditor = false
    @State private var showingAgentHub = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    // Welcome header
                    WelcomeHeader()
                        .padding(.horizontal)

                    // Partner Status Card (Chris)
                    PartnerStatusCard()
                        .padding(.horizontal)

                    // AI Features Section
                    AIFeaturesSection(
                        showAIGenerator: $showAIGenerator,
                        showingAgentHub: $showingAgentHub
                    )
                    .padding(.horizontal)

                    // Stats cards
                    StatsCardsView(viewModel: viewModel)
                        .padding(.horizontal)

                    // Today's tasks widget
                    if !viewModel.todaysTasks.isEmpty {
                        TodaysTasksWidget(tasks: viewModel.todaysTasks)
                            .padding(.horizontal)
                    }

                    // Overdue tasks (if any)
                    if !viewModel.overdueTasks.isEmpty {
                        OverdueTasksWidget(tasks: viewModel.overdueTasks)
                            .padding(.horizontal)
                    }

                    // Upcoming events widget
                    if !viewModel.upcomingEvents.isEmpty {
                        UpcomingEventsWidget(events: viewModel.upcomingEvents)
                            .padding(.horizontal)
                    }
                    
                    // Upcoming Together Card (Shared Events)
                    UpcomingTogetherCard()
                        .padding(.horizontal)
                    
                    // Shared Tasks Card
                    SharedTasksCard()
                        .padding(.horizontal)

                    // Meal Planning Widget
                    MealPlanningWidget()
                        .padding(.horizontal)

                    // iOS Features Discovery
                    IOSFeaturesWidget()
                        .padding(.horizontal)

                    // Quick actions
                    QuickActionsWidget()
                        .padding(.horizontal)

                    // All Apps Grid
                    AllAppsWidget()
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .padding(.bottom, 100) // Extra padding to prevent getting stuck at bottom
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAIGenerator = true
                        } label: {
                            Label("AI Generator", systemImage: "sparkles")
                        }

                        Button {
                            showingAgentHub = true
                        } label: {
                            Label("Agent Hub", systemImage: "atom")
                        }

                        Divider()

                        Button {
                            showingLayoutEditor = true
                        } label: {
                            Label("Customize Dashboard", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Dashboard options")
                    .accessibilityHint("Opens menu with AI generator, Agent Hub, and dashboard customization options")
                }
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.tasks.isEmpty {
                    ProgressView()
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                SmartGeneratorView()
            }
            .sheet(isPresented: $showingAgentHub) {
                NavigationStack {
                    AgentHubView(onStartChat: { _ in })
                        .navigationTitle("Agent Hub")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    showingAgentHub = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingLayoutEditor) {
                NavigationStack {
                    ConfigurableDashboardView()
                        .navigationTitle("Customize Dashboard")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showingLayoutEditor = false }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - AI Features Section

struct AIFeaturesSection: View {
    @Binding var showAIGenerator: Bool
    @Binding var showingAgentHub: Bool
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(spacing: 12) {
            // Main AI Generator Card
            Button {
                showAIGenerator = true
            } label: {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("AI Task Generator")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                        }

                        Text("Describe what you need in plain English and let AI create tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
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
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            }
            .accessibilityLabel("AI Task Generator")
            .accessibilityHint("Opens AI generator to create tasks from plain English descriptions")
            .accessibilityAddTraits(.isButton)

            // AI Quick Actions Row
            HStack(spacing: 12) {
                Button {
                    showingAgentHub = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "atom")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Text("Agent Hub")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .accessibilityLabel("Agent Hub")
                .accessibilityHint("Opens the AI Agent Hub to access specialized AI assistants")
                .accessibilityAddTraits(.isButton)

                Button {
                    showAIGenerator = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "brain")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                        Text("Quick Generate")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .accessibilityLabel("Quick Generate")
                .accessibilityHint("Opens the AI generator for quickly creating tasks")
                .accessibilityAddTraits(.isButton)
            }
        }
    }
}

// MARK: - Welcome Header

struct WelcomeHeader: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)

                Text(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }

            Spacer()

            // Decorative icon
            Image(systemName: "sun.max.fill")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        default:
            return "Good Evening"
        }
    }
}

// MARK: - Stats Cards

struct StatsCardsView: View {
    let viewModel: DashboardViewModel
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatCard(
                value: "\(viewModel.completedToday)",
                label: "Completed Today",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                value: "\(viewModel.tasksThisWeek)",
                label: "This Week",
                icon: "calendar",
                color: .blue
            )

            StatCard(
                value: "\(viewModel.upcomingEventsCount)",
                label: "Upcoming",
                icon: "star.fill",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)

            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeManager.cardBackgroundColor) // Using background directly as StatCard is inside a grid which might not want rounded corners individually or different radius
        .cornerRadius(12)
    }
}

// MARK: - Today's Tasks Widget

struct TodaysTasksWidget: View {
    let tasks: [Task]
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }

            VStack(spacing: 8) {
                ForEach(tasks.prefix(5)) { task in
                    CompactTaskRow(task: task)
                }
            }
        }
        .padding()
        .themedCardBackground()
    }
}

struct CompactTaskRow: View {
    let task: Task
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundColor(themeManager.textColor)

                if !task.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(task.labels.prefix(2)) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: label.color ?? "#6B7280").opacity(0.2))
                                )
                                .foregroundColor(themeManager.textColor)
                        }
                    }
                }
            }

            Spacer()

            if let dueDate = task.dueDate {
                Text(dueDate, style: .time)
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Overdue Tasks Widget

struct OverdueTasksWidget: View {
    let tasks: [Task]
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Overdue")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                ForEach(tasks.prefix(3)) { task in
                    CompactTaskRow(task: task)
                }
            }
        }
        .padding()
        .themedCardBackground()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Upcoming Events Widget

struct UpcomingEventsWidget: View {
    let events: [Event]
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Upcoming Events")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding()
        .themedCardBackground()
    }
}

struct EventRow: View {
    let event: Event
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack(spacing: 12) {
            // Date badge
            VStack(spacing: 2) {
                Text(event.startTime, format: .dateTime.month(.abbreviated))
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                Text(event.startTime, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
            }
            .frame(width: 50)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(event.startTime, style: .time)
                        .font(.caption)
                }
                .foregroundColor(themeManager.secondaryTextColor)

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(themeManager.secondaryTextColor)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Quick Actions

struct QuickActionsWidget: View {
    @State private var showAIGenerator = false
    @State private var showNewTask = false
    @State private var showNewEvent = false
    @State private var showViewAll = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(themeManager.textColor)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                Button {
                    showNewTask = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text("New Task")
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.backgroundColor)
                    )
                }

                Button {
                    showNewEvent = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(.purple)

                        Text("New Event")
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.backgroundColor)
                    )
                }

                Button {
                    showAIGenerator = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("AI Generator")
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.backgroundColor)
                    )
                }

                NavigationLink(destination: TaskListView()) {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.green)

                        Text("View All")
                            .font(.caption)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.backgroundColor)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .themedCardBackground()
        .sheet(isPresented: $showAIGenerator) {
            SmartGeneratorView()
        }
        .sheet(isPresented: $showNewTask) {
            NewTaskView { newTask in
                await createTask(newTask)
            }
        }
        .sheet(isPresented: $showNewEvent) {
            NewEventView(viewModel: CalendarViewModel())
        }
    }

    private func createTask(_ taskCreate: TaskCreate) async {
        do {
            _ = try await APIClient.shared.createTask(taskCreate)
            // Task created successfully - could refresh dashboard if needed
            showNewTask = false
            HapticManager.success()
        } catch {
            print("Failed to create task:", error)
            HapticManager.error()
        }
    }
}

// MARK: - iOS Features Widget

struct IOSFeaturesWidget: View {
    @State private var showAllFeatures = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Discover iOS Features")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Button(action: { showAllFeatures = true }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    NavigationLink(destination: WidgetSettingsView()) {
                        IOSFeatureCardContent(
                            title: "Widgets",
                            icon: "square.grid.3x3.fill",
                            color: .blue,
                            badge: "NEW",
                            description: "Add tasks to home screen"
                        )
                    }
                    .buttonStyle(.plain)

                    IOSFeatureCard(
                        title: "Live Activities",
                        icon: "bell.badge.fill",
                        color: .purple,
                        badge: "iOS 16+",
                        description: "Track tasks in real-time"
                    )

                    IOSFeatureCard(
                        title: "Siri Shortcuts",
                        icon: "mic.fill",
                        color: .orange,
                        badge: nil,
                        description: "Voice task creation"
                    )

                    IOSFeatureCard(
                        title: "Spotlight",
                        icon: "magnifyingglass",
                        color: .green,
                        badge: nil,
                        description: "Quick task search"
                    )

                    IOSFeatureCard(
                        title: "Quick Actions",
                        icon: "hand.point.up.left.fill",
                        color: .pink,
                        badge: "3D Touch",
                        description: "App icon shortcuts"
                    )

                    IOSFeatureCard(
                        title: "Handoff",
                        icon: "arrow.triangle.2.circlepath",
                        color: .cyan,
                        badge: nil,
                        description: "Continue on other devices"
                    )
                }
                .padding(.horizontal, 4)
            }

            Text("Tap to learn how to enable these features")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding()
        .themedCardBackground()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .sheet(isPresented: $showAllFeatures) {
            IOSFeaturesDetailView()
        }
    }
}

struct IOSFeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let badge: String?
    let description: String
    @State private var isPressed = false

    var body: some View {
        Button {
            // Navigate to feature details
        } label: {
            IOSFeatureCardContent(
                title: title,
                icon: icon,
                color: color,
                badge: badge,
                description: description,
                isPressed: isPressed
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct IOSFeatureCardContent: View {
    let title: String
    let icon: String
    let color: Color
    let badge: String?
    let description: String
    var isPressed: Bool = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(color)
                        )
                }
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)

            Text(description)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 160)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.backgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

// Note: IOSFeaturesDetailView and related components are defined in MoreView.swift
// to avoid code duplication between Dashboard and More tabs

// MARK: - Meal Planning Widget

struct MealPlanningWidget: View {
    @State private var showingRecipeGenerator = false
    @State private var showingMealPlan = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.orange)
                Text("What's for Dinner?")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }

            VStack(spacing: 12) {
                // Recipe Ideas Button
                Button(action: { showingRecipeGenerator = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recipe Ideas")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.textColor)

                            Text("Get AI-powered recipe suggestions")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }

                        Spacer()

                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                // Meal Plan Button
                Button(action: { showingMealPlan = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Meal Plan")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.textColor)

                            Text("Plan your meals for the week")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }

                        Spacer()

                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            // Quick Tips
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)

                Text("Tip: Add shopping lists to your tasks to get instant recipe suggestions")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .padding(.top, 4)
        }
        .padding()
        .themedCardBackground()
        .sheet(isPresented: $showingRecipeGenerator) {
            RecipeGeneratorView()
        }
        .sheet(isPresented: $showingMealPlan) {
            MealPlanGeneratorView()
        }
    }
}

// MARK: - All Apps Widget

struct AllAppsWidget: View {
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.blue)
                Text("All Apps")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(NavigationTab.allCases.filter { $0 != .dashboard && $0 != .more && $0 != .settings }.count)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DashboardAppButton(tab: .tasks)
                DashboardAppButton(tab: .calendar)
                DashboardAppButton(tab: .messages) // Unified: AI + Human
                DashboardAppButton(tab: .finance)
                DashboardAppButton(tab: .pages)
                DashboardAppButton(tab: .templates)
                DashboardAppButton(tab: .smartLists)
                DashboardAppButton(tab: .admin)
            }

            // Helper text
            Text("Tap any app to explore its features")
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding()
        .themedCardBackground()
    }
}

struct DashboardAppButton: View {
    let tab: NavigationTab
    @State private var isPressed = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        NavigationLink(destination: destinationView) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [tab.color, tab.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: tab.color.opacity(0.3), radius: isPressed ? 2 : 4, y: isPressed ? 1 : 2)

                    Image(systemName: tab.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)

                Text(tab.rawValue)
                    .font(.caption2)
                    .foregroundColor(themeManager.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var destinationView: some View {
        switch tab {
        case .tasks:
            TaskListView()
        case .calendar:
            CalendarView()
        case .messages:
            MessagesView() // Unified: AI + Human
        case .finance:
            FinanceView()
        case .templates:
            TaskTemplatesView()
        case .smartLists:
            SmartListsView()
        case .pages:
            PagesView() // Now implemented for AI context
        case .admin:
            AdminView()
        case .dashboard, .settings, .more:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
}

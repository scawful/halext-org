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
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                if viewModel.isLoading && viewModel.tasks.isEmpty && !hasAppeared {
                    // Skeleton loading state
                    DashboardSkeletonView()
                        .padding(.vertical)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 20) {
                        // Welcome header
                        WelcomeHeader()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 0)

                        // Partner Status Card (Chris)
                        PartnerStatusCard()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 1)

                        // AI Features Section
                        AIFeaturesSection(
                            showAIGenerator: $showAIGenerator,
                            showingAgentHub: $showingAgentHub
                        )
                        .padding(.horizontal)
                        .staggeredEntrance(index: 2)

                        // Stats cards
                        StatsCardsView(viewModel: viewModel)
                            .padding(.horizontal)
                            .staggeredEntrance(index: 3)

                        // Today's tasks widget
                        if !viewModel.todaysTasks.isEmpty {
                            TodaysTasksWidget(tasks: viewModel.todaysTasks)
                                .padding(.horizontal)
                                .staggeredEntrance(index: 4)
                                .transition(.scaleAndFade)
                        } else if hasAppeared {
                            // Show empty state when no tasks
                            DashboardEmptyTasksCard()
                                .padding(.horizontal)
                                .staggeredEntrance(index: 4)
                                .transition(.scaleAndFade)
                        }

                        // Overdue tasks (if any)
                        if !viewModel.overdueTasks.isEmpty {
                            OverdueTasksWidget(tasks: viewModel.overdueTasks)
                                .padding(.horizontal)
                                .staggeredEntrance(index: 5)
                                .transition(.scaleAndFade)
                        }

                        // Upcoming events widget
                        if !viewModel.upcomingEvents.isEmpty {
                            UpcomingEventsWidget(events: viewModel.upcomingEvents)
                                .padding(.horizontal)
                                .staggeredEntrance(index: 6)
                                .transition(.scaleAndFade)
                        }

                        // Upcoming Together Card (Shared Events)
                        UpcomingTogetherCard()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 7)

                        // Shared Tasks Card
                        SharedTasksCard()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 8)

                        // Meal Planning Widget
                        MealPlanningWidget()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 9)

                        // iOS Features Discovery
                        IOSFeaturesWidget()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 10)

                        // Quick actions
                        QuickActionsWidget()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 11)

                        // All Apps Grid
                        AllAppsWidget()
                            .padding(.horizontal)
                            .staggeredEntrance(index: 12)
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100) // Extra padding to prevent getting stuck at bottom
                }
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            HapticManager.selection()
                            showAIGenerator = true
                        } label: {
                            Label("AI Generator", systemImage: "sparkles")
                        }

                        Button {
                            HapticManager.selection()
                            showingAgentHub = true
                        } label: {
                            Label("Agent Hub", systemImage: "atom")
                        }

                        Divider()

                        Button {
                            HapticManager.selection()
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
                HapticManager.lightImpact()
                await viewModel.loadDashboardData()
                HapticManager.success()
            }
            .task {
                await viewModel.loadDashboardData()
                withAnimation(.easeOut(duration: 0.3)) {
                    hasAppeared = true
                }
            }
            .sheet(isPresented: $showAIGenerator) {
                SmartGeneratorView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - AI Features Section

struct AIFeaturesSection: View {
    @Binding var showAIGenerator: Bool
    @Binding var showingAgentHub: Bool
    @Environment(ThemeManager.self) var themeManager
    @State private var isMainCardPressed = false
    @State private var isAgentHubPressed = false
    @State private var isQuickGenPressed = false
    @State private var sparkleAnimation = false

    var body: some View {
        VStack(spacing: 12) {
            // Main AI Generator Card
            Button {
                HapticManager.mediumImpact()
                showAIGenerator = true
            } label: {
                HStack(spacing: 16) {
                    // Animated Icon
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
                            .shadow(color: .purple.opacity(0.4), radius: isMainCardPressed ? 2 : 8, y: isMainCardPressed ? 1 : 4)

                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(sparkleAnimation ? 10 : -10))
                            .scaleEffect(sparkleAnimation ? 1.1 : 1.0)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("AI Task Generator")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)

                            Spacer()

                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                                .offset(x: isMainCardPressed ? 4 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMainCardPressed)
                        }

                        Text("Describe what you need in plain English and let AI create tasks")
                            .font(.subheadline)
                            .foregroundColor(themeManager.secondaryTextColor)
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
                                    Color.blue.opacity(isMainCardPressed ? 0.15 : 0.1),
                                    Color.purple.opacity(isMainCardPressed ? 0.15 : 0.1)
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
                .scaleEffect(isMainCardPressed ? 0.98 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isMainCardPressed)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isMainCardPressed {
                            isMainCardPressed = true
                            HapticManager.lightImpact()
                        }
                    }
                    .onEnded { _ in isMainCardPressed = false }
            )
            .accessibilityLabel("AI Task Generator")
            .accessibilityHint("Opens AI generator to create tasks from plain English descriptions")
            .accessibilityAddTraits(.isButton)

            // AI Quick Actions Row
            HStack(spacing: 12) {
                Button {
                    HapticManager.selection()
                    showingAgentHub = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "atom")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isAgentHubPressed ? 180 : 0))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAgentHubPressed)
                        Text("Agent Hub")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .scaleEffect(isAgentHubPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isAgentHubPressed)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isAgentHubPressed = true }
                        .onEnded { _ in isAgentHubPressed = false }
                )
                .accessibilityLabel("Agent Hub")
                .accessibilityHint("Opens the AI Agent Hub to access specialized AI assistants")
                .accessibilityAddTraits(.isButton)

                Button {
                    HapticManager.selection()
                    showAIGenerator = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "brain")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .scaleEffect(isQuickGenPressed ? 1.2 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isQuickGenPressed)
                        Text("Quick Generate")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .scaleEffect(isQuickGenPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isQuickGenPressed)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isQuickGenPressed = true }
                        .onEnded { _ in isQuickGenPressed = false }
                )
                .accessibilityLabel("Quick Generate")
                .accessibilityHint("Opens the AI generator for quickly creating tasks")
                .accessibilityAddTraits(.isButton)
            }
        }
        .onAppear {
            // Start sparkle animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                sparkleAnimation = true
            }
        }
    }
}

// MARK: - Welcome Header

struct WelcomeHeader: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var iconRotation = 0.0
    @State private var iconScale = 1.0
    @State private var showContent = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)

                Text(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)
            }

            Spacer()

            // Animated decorative icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(iconGlowColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 10)
                    .scaleEffect(iconScale)

                Image(systemName: timeIcon)
                    .font(.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(iconRotation))
                    .scaleEffect(iconScale)
            }
            .opacity(showContent ? 1 : 0)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greetingText). Today is \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))")
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }

            // Subtle continuous animation for the icon
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                iconRotation = 5
                iconScale = 1.05
            }
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

    private var timeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6:
            return "moon.stars.fill"
        case 6..<12:
            return "sun.max.fill"
        case 12..<17:
            return "sun.min.fill"
        case 17..<20:
            return "sunset.fill"
        default:
            return "moon.fill"
        }
    }

    private var iconColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6:
            return [.indigo, .purple]
        case 6..<12:
            return [.orange, .yellow]
        case 12..<17:
            return [.orange, .red]
        case 17..<20:
            return [.orange, .pink]
        default:
            return [.indigo, .blue]
        }
    }

    private var iconGlowColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6:
            return .purple
        case 6..<12:
            return .orange
        case 12..<17:
            return .orange
        case 17..<20:
            return .pink
        default:
            return .indigo
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
    @State private var isPressed = false
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            .opacity(hasAppeared ? 1 : 0)
            .accessibilityHidden(true)

            AnimatedNumber(Int(value) ?? 0, font: .title2, color: themeManager.textColor)

            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: isPressed ? color.opacity(0.2) : .clear, radius: 4, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                hasAppeared = true
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticManager.lightImpact()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Dashboard Empty Tasks Card

struct DashboardEmptyTasksCard: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var showNewTask = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }

            DashboardEmptyState(
                icon: "sun.max.fill",
                title: "No tasks for today",
                message: "Your day is clear! Add a task to stay productive.",
                suggestion: "Plan tomorrow's tasks now",
                actionTitle: "Add Task",
                action: { showNewTask = true },
                accentColor: .blue
            )
        }
        .padding()
        .themedCardBackground()
        .sheet(isPresented: $showNewTask) {
            NewTaskView { newTask in
                await createTask(newTask)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func createTask(_ taskCreate: TaskCreate) async {
        do {
            _ = try await APIClient.shared.createTask(taskCreate)
            showNewTask = false
            HapticManager.success()
        } catch {
            print("Failed to create task:", error)
            HapticManager.error()
        }
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
                    .accessibilityHidden(true)
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's Tasks: \(tasks.count) task\(tasks.count == 1 ? "" : "s")")

            VStack(spacing: 8) {
                ForEach(tasks.prefix(5)) { task in
                    CompactTaskRow(task: task)
                }
            }
        }
        .padding()
        .themedCardBackground()
        .accessibilityElement(children: .contain)
    }
}

struct CompactTaskRow: View {
    let task: Task
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : .secondary)
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(taskAccessibilityLabel)
    }

    private var taskAccessibilityLabel: String {
        var label = task.completed ? "Completed: " : "Pending: "
        label += task.title
        if let dueDate = task.dueDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            label += ", due at \(formatter.string(from: dueDate))"
        }
        if !task.labels.isEmpty {
            let labelNames = task.labels.prefix(2).map { $0.name }.joined(separator: ", ")
            label += ", labels: \(labelNames)"
        }
        return label
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
                    .accessibilityHidden(true)
                Text("Overdue")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Overdue Tasks: \(tasks.count) task\(tasks.count == 1 ? "" : "s") need attention")
            .accessibilityAddTraits(.isHeader)

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
        .accessibilityElement(children: .contain)
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
                    .accessibilityHidden(true)
                Text("Upcoming Events")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Upcoming Events: \(events.count) event\(events.count == 1 ? "" : "s")")
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding()
        .themedCardBackground()
        .accessibilityElement(children: .contain)
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
            .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(eventAccessibilityLabel)
    }

    private var eventAccessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        var label = "\(event.title) on \(dateFormatter.string(from: event.startTime))"
        if let location = event.location {
            label += ", at \(location)"
        }
        return label
    }
}

// MARK: - Quick Actions

struct QuickActionsWidget: View {
    @State private var showAIGenerator = false
    @State private var showNewTask = false
    @State private var showNewEvent = false
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
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "New Task",
                    color: .blue,
                    action: {
                        HapticManager.selection()
                        showNewTask = true
                    }
                )
                .accessibilityLabel("New Task")
                .accessibilityHint("Opens form to create a new task")

                QuickActionButton(
                    icon: "calendar.badge.plus",
                    title: "New Event",
                    color: .purple,
                    action: {
                        HapticManager.selection()
                        showNewEvent = true
                    }
                )
                .accessibilityLabel("New Event")
                .accessibilityHint("Opens form to create a new calendar event")

                QuickActionButton(
                    icon: "sparkles",
                    title: "AI Generator",
                    color: .orange,
                    action: {
                        HapticManager.selection()
                        showAIGenerator = true
                    }
                )
                .accessibilityLabel("AI Generator")
                .accessibilityHint("Opens AI assistant to generate tasks automatically")

                NavigationLink(destination: TaskListView()) {
                    QuickActionButtonContent(
                        icon: "list.bullet",
                        title: "View All",
                        color: .green,
                        isPressed: false
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View All Tasks")
                .accessibilityHint("Opens the full task list")
            }
        }
        .padding()
        .themedCardBackground()
        .sheet(isPresented: $showAIGenerator) {
            SmartGeneratorView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNewTask) {
            NewTaskView { newTask in
                await createTask(newTask)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNewEvent) {
            NewEventView(viewModel: CalendarViewModel())
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        Button(action: action) {
            QuickActionButtonContent(
                icon: icon,
                title: title,
                color: color,
                isPressed: isPressed
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticManager.lightImpact()
                    }
                }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct QuickActionButtonContent: View {
    let icon: String
    let title: String
    let color: Color
    let isPressed: Bool

    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isPressed ? 0.9 : 1.0)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .scaleEffect(isPressed ? 1.1 : 1.0)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .shadow(
                    color: isPressed ? color.opacity(0.2) : .black.opacity(0.03),
                    radius: isPressed ? 2 : 4,
                    y: isPressed ? 1 : 2
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
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
                    .accessibilityHidden(true)

                Text("Discover iOS Features")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Button(action: { showAllFeatures = true }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("See all iOS features")
                .accessibilityHint("Opens a list of all available iOS features")
            }
            .accessibilityElement(children: .contain)

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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) feature\(badge != nil ? ", \(badge!)" : "")")
        .accessibilityHint(description)
        .accessibilityAddTraits(.isButton)
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
                    .accessibilityHidden(true)
                Text("What's for Dinner?")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Meal Planning: What's for Dinner?")
            .accessibilityAddTraits(.isHeader)

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
                .accessibilityLabel("Recipe Ideas")
                .accessibilityHint("Opens AI-powered recipe suggestions based on your preferences")

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
                .accessibilityLabel("Weekly Meal Plan")
                .accessibilityHint("Opens meal planning view to organize your weekly meals")
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingMealPlan) {
            MealPlanGeneratorView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - All Apps Widget

struct AllAppsWidget: View {
    @Environment(ThemeManager.self) var themeManager

    private var appCount: Int {
        NavigationTab.allCases.filter { $0 != .dashboard && $0 != .more && $0 != .settings }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                Text("All Apps")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)
                Spacer()
                Text("\(appCount)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("All Apps: \(appCount) app\(appCount == 1 ? "" : "s") available")
            .accessibilityAddTraits(.isHeader)

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
        .accessibilityLabel("Open \(tab.rawValue)")
        .accessibilityHint("Navigate to the \(tab.rawValue) section of the app")
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

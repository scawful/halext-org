//
//  CardContentView.swift
//  Cafe
//
//  Main content renderer for different card types
//

import SwiftUI

struct CardContentView: View {
    let card: DashboardCard
    let viewModel: DashboardViewModel
    @Binding var showAIGenerator: Bool

    @ViewBuilder
    var body: some View {
        switch card.type {
            case .welcome:
                WelcomeCardContent()

            case .aiGenerator:
                AIGeneratorCardContent(showAIGenerator: $showAIGenerator)

            case .todayTasks:
                TodayTasksCardContent(
                    tasks: viewModel.todaysTasks,
                    config: card.configuration
                )

            case .upcomingTasks:
                UpcomingTasksCardContent(
                    tasks: viewModel.upcomingTasksForWeek,
                    config: card.configuration
                )

            case .overdueTasks:
                OverdueTasksCardContent(
                    tasks: viewModel.overdueTasks,
                    config: card.configuration
                )

            case .tasksStats:
                TasksStatsCardContent(viewModel: viewModel)

            case .calendar:
                CalendarCardContent(
                    events: viewModel.upcomingEvents,
                    config: card.configuration
                )

            case .upcomingEvents:
                UpcomingEventsCardContent(
                    events: viewModel.upcomingEvents,
                    config: card.configuration
                )

            case .quickActions:
                QuickActionsCardContent(showAIGenerator: $showAIGenerator)

            case .weather:
                WeatherCardContent()

            case .recentActivity:
                RecentActivityCardContent()

            case .notes:
                NotesCardContent()

            case .aiSuggestions:
                AISuggestionsCardContent(viewModel: viewModel)

            case .socialActivity:
                SocialActivityCardContent()

            case .mealPlanning:
                MealPlanningCardContent()

            case .iosFeatures:
                IOSFeaturesCardContent()

            case .allApps:
                AllAppsCardContent()

            case .customList:
                CustomListCardContent(config: card.configuration)
        }
    }
}

// MARK: - Welcome Card

struct WelcomeCardContent: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: timeIcon)
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(
                        colors: iconColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    private var timeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "sun.max.fill"
        case 12..<17: return "sun.min.fill"
        default: return "moon.stars.fill"
        }
    }

    private var iconColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return [.orange, .yellow]
        case 12..<17: return [.orange, .red]
        default: return [.indigo, .purple]
        }
    }
}

// MARK: - AI Generator Card

struct AIGeneratorCardContent: View {
    @Binding var showAIGenerator: Bool

    var body: some View {
        Button {
            showAIGenerator = true
        } label: {
            HStack(spacing: 16) {
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

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("AI Task Generator")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }

                    Text("Describe what you need in plain English")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Tasks Card

struct TodayTasksCardContent: View {
    let tasks: [Task]
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if config.showHeader {
                CardHeader(
                    icon: "checkmark.circle.fill",
                    title: "Today's Tasks",
                    color: .blue,
                    badge: "\(filteredTasks.count)"
                )
            }

            if filteredTasks.isEmpty && !config.autoHideWhenEmpty {
                EmptyCardState(
                    icon: "checkmark.circle",
                    message: "No tasks for today"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredTasks.prefix(config.maxTasksToShow)) { task in
                        CompactTaskRow(task: task)
                    }
                }
            }
        }
    }

    private var filteredTasks: [Task] {
        tasks.filter { task in
            if !config.showCompletedTasks && task.completed {
                return false
            }
            return true
        }
    }
}

// MARK: - Upcoming Tasks Card

struct UpcomingTasksCardContent: View {
    let tasks: [Task]
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if config.showHeader {
                CardHeader(
                    icon: "calendar.badge.clock",
                    title: "Upcoming Tasks",
                    color: .cyan,
                    badge: "\(tasks.count)"
                )
            }

            if tasks.isEmpty && !config.autoHideWhenEmpty {
                EmptyCardState(
                    icon: "calendar",
                    message: "No upcoming tasks"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(config.maxTasksToShow)) { task in
                        CompactTaskRow(task: task)
                    }
                }
            }
        }
    }
}

// MARK: - Overdue Tasks Card

struct OverdueTasksCardContent: View {
    let tasks: [Task]
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if config.showHeader {
                CardHeader(
                    icon: "exclamationmark.triangle.fill",
                    title: "Overdue",
                    color: .red,
                    badge: "\(tasks.count)"
                )
            }

            if tasks.isEmpty && !config.autoHideWhenEmpty {
                EmptyCardState(
                    icon: "checkmark.circle",
                    message: "All caught up!"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(config.maxTasksToShow)) { task in
                        CompactTaskRow(task: task)
                    }
                }
            }
        }
    }
}

// MARK: - Tasks Stats Card

struct TasksStatsCardContent: View {
    let viewModel: DashboardViewModel

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MiniStatCard(
                value: "\(viewModel.completedToday)",
                label: "Completed Today",
                icon: "checkmark.circle.fill",
                color: .green
            )

            MiniStatCard(
                value: "\(viewModel.tasksThisWeek)",
                label: "This Week",
                icon: "calendar",
                color: .blue
            )

            MiniStatCard(
                value: "\(viewModel.upcomingEventsCount)",
                label: "Upcoming",
                icon: "star.fill",
                color: .purple
            )
        }
    }
}

struct MiniStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Calendar Card

struct CalendarCardContent: View {
    let events: [Event]
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "calendar",
                title: "Calendar",
                color: .purple
            )

            // Mini calendar view or week view
            Text("Calendar view coming soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
        }
    }
}

// MARK: - Upcoming Events Card

struct UpcomingEventsCardContent: View {
    let events: [Event]
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if config.showHeader {
                CardHeader(
                    icon: "calendar",
                    title: "Upcoming Events",
                    color: .purple
                )
            }

            if events.isEmpty && !config.autoHideWhenEmpty {
                EmptyCardState(
                    icon: "calendar.badge.plus",
                    message: "No upcoming events"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(events.prefix(config.maxEventsToShow)) { event in
                        EventRow(event: event)
                    }
                }
            }
        }
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCardContent: View {
    @Binding var showAIGenerator: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DashboardQuickActionButton(
                    title: "New Task",
                    icon: "plus.circle.fill",
                    color: .blue
                )

                DashboardQuickActionButton(
                    title: "New Event",
                    icon: "calendar.badge.plus",
                    color: .purple
                )

                Button {
                    showAIGenerator = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(.orange)

                        Text("AI Generator")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                DashboardQuickActionButton(
                    title: "View All",
                    icon: "list.bullet",
                    color: .green
                )
            }
        }
    }
}

// MARK: - Weather Card

struct WeatherCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "cloud.sun.fill",
                title: "Weather",
                color: .cyan
            )

            HStack(spacing: 16) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("72°F")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Partly Cloudy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("San Francisco, CA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "clock.arrow.circlepath",
                title: "Recent Activity",
                color: .gray
            )

            VStack(alignment: .leading, spacing: 12) {
                DashboardActivityItemView(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Completed 'Design Review'",
                    time: "5 minutes ago"
                )

                DashboardActivityItemView(
                    icon: "plus.circle.fill",
                    color: .blue,
                    title: "Created 'Meeting'",
                    time: "1 hour ago"
                )

                DashboardActivityItemView(
                    icon: "calendar.badge.plus",
                    color: .purple,
                    title: "Added event to calendar",
                    time: "2 hours ago"
                )
            }
        }
    }
}

struct DashboardActivityItemView: View {
    let icon: String
    let color: Color
    let title: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)

                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Notes Card

struct NotesCardContent: View {
    @State private var noteText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "note.text",
                title: "Quick Notes",
                color: .yellow
            )

            TextEditor(text: $noteText)
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

// MARK: - AI Suggestions Card

struct AISuggestionsCardContent: View {
    let viewModel: DashboardViewModel
    @State private var insights: [DashboardInsight] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "brain.head.profile",
                title: "AI Insights",
                color: .pink
            )

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if insights.isEmpty {
                Text("No insights available yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(insights.prefix(3)) { insight in
                        SuggestionRow(
                            icon: insight.icon,
                            text: insight.message,
                            color: insight.color
                        )
                    }
                }
            }
        }
        .task {
            await generateInsights()
        }
    }
    
    private func generateInsights() async {
        isLoading = true
        
        var generatedInsights: [DashboardInsight] = []
        
        // Generate insights based on user data
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        
        // Overdue tasks insight
        if !viewModel.overdueTasks.isEmpty {
            generatedInsights.append(DashboardInsight(
                icon: "exclamationmark.triangle.fill",
                message: "You have \(viewModel.overdueTasks.count) overdue task\(viewModel.overdueTasks.count > 1 ? "s" : ""). Consider rescheduling or breaking them down.",
                color: .red,
                priority: .high
            ))
        }
        
        // Productivity pattern insight
        if viewModel.completedToday > 0 {
            let completionRate = Double(viewModel.completedToday) / Double(max(viewModel.todaysTasks.count + viewModel.completedToday, 1))
            if completionRate > 0.7 {
                generatedInsights.append(DashboardInsight(
                    icon: "star.fill",
                    message: "Great progress today! You've completed \(Int(completionRate * 100))% of today's tasks.",
                    color: .green,
                    priority: .medium
                ))
            }
        }
        
        // Task distribution insight
        if viewModel.tasksThisWeek > 10 {
            generatedInsights.append(DashboardInsight(
                icon: "chart.bar.fill",
                message: "You have \(viewModel.tasksThisWeek) tasks this week. Consider prioritizing or delegating some.",
                color: .orange,
                priority: .medium
            ))
        }
        
        // Day of week insights
        if weekday == 2 { // Monday
            generatedInsights.append(DashboardInsight(
                icon: "calendar",
                message: "Start of the week! Good time to review and plan your priorities.",
                color: .blue,
                priority: .low
            ))
        } else if weekday == 6 { // Friday
            generatedInsights.append(DashboardInsight(
                icon: "calendar",
                message: "End of the week! Consider wrapping up loose ends.",
                color: .blue,
                priority: .low
            ))
        }
        
        // Event preparation insight
        if !viewModel.upcomingEvents.isEmpty {
            let nextEvent = viewModel.upcomingEvents.first!
            let daysUntil = calendar.dateComponents([.day], from: now, to: nextEvent.startTime).day ?? 0
            if daysUntil <= 2 && daysUntil > 0 {
                generatedInsights.append(DashboardInsight(
                    icon: "calendar.badge.clock",
                    message: "\"\(nextEvent.title)\" is in \(daysUntil) day\(daysUntil > 1 ? "s" : ""). Time to prepare!",
                    color: .purple,
                    priority: .high
                ))
            }
        }
        
        // Task completion pattern
        let tasksWithLabels = viewModel.tasks.filter { !$0.labels.isEmpty }
        if tasksWithLabels.count > 5 {
            generatedInsights.append(DashboardInsight(
                icon: "tag.fill",
                message: "Tasks with labels tend to get completed faster. Consider adding labels to important tasks.",
                color: .teal,
                priority: .low
            ))
        }
        
        await MainActor.run {
            // Sort by priority
            insights = generatedInsights.sorted { $0.priority.rawValue > $1.priority.rawValue }
            isLoading = false
        }
    }
}

struct DashboardInsight: Identifiable {
    let id = UUID()
    let icon: String
    let message: String
    let color: Color
    let priority: InsightPriority
    
    enum InsightPriority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}

struct SuggestionRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Social Activity Card

struct SocialActivityCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "person.2.fill",
                title: "Activity",
                color: .teal
            )

            VStack(alignment: .leading, spacing: 12) {
                TeamActivityItem(
                    name: "Sarah",
                    action: "completed 5 tasks",
                    time: "10 minutes ago"
                )

                TeamActivityItem(
                    name: "Mike",
                    action: "created new project",
                    time: "1 hour ago"
                )

                TeamActivityItem(
                    name: "Emma",
                    action: "shared a document",
                    time: "2 hours ago"
                )
            }
        }
    }
}

struct TeamActivityItem: View {
    let name: String
    let action: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.teal.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(name.prefix(1))
                        .font(.headline)
                        .foregroundColor(.teal)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(action)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Meal Planning Card

struct MealPlanningCardContent: View {
    @State private var showingRecipeGenerator = false
    @State private var showingMealPlan = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(
                icon: "fork.knife",
                title: "What's for Dinner?",
                color: .orange
            )

            VStack(spacing: 12) {
                Button(action: { showingRecipeGenerator = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recipe Ideas")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Get AI-powered recipe suggestions")
                                .font(.caption)
                                .foregroundColor(.secondary)
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

                Button(action: { showingMealPlan = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Meal Plan")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Plan your meals for the week")
                                .font(.caption)
                                .foregroundColor(.secondary)
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
        }
        .sheet(isPresented: $showingRecipeGenerator) {
            RecipeGeneratorView()
        }
        .sheet(isPresented: $showingMealPlan) {
            MealPlanGeneratorView()
        }
    }
}

// MARK: - iOS Features Card

struct IOSFeaturesCardContent: View {
    @State private var showAllFeatures = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CardHeader(
                icon: "sparkles",
                title: "Discover iOS Features",
                color: .blue,
                action: { showAllFeatures = true }
            )

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
                }
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showAllFeatures) {
            IOSFeaturesDetailView()
        }
    }
}

// MARK: - All Apps Card

struct AllAppsCardContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "square.grid.2x2",
                title: "All Apps",
                color: .blue,
                badge: "\(appTabs.count)"
            )

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(appTabs, id: \.self) { tab in
                    DashboardAppButton(tab: tab)
                }
            }

            Text("Tap any app to explore its features")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var appTabs: [NavigationTab] {
        NavigationTab.allCases.filter {
            $0 != .dashboard && $0 != .more && $0 != .settings
        }
    }
}

// MARK: - Custom List Card

struct CustomListCardContent: View {
    let config: CardConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(
                icon: "list.bullet",
                title: config.customListTitle ?? "Custom List",
                color: .green
            )

            EmptyCardState(
                icon: "list.bullet",
                message: "Configure this list in settings"
            )
        }
    }
}

// MARK: - Dashboard Quick Action Button

struct DashboardQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

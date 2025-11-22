//
//  WidgetSettingsView.swift
//  Cafe
//
//  Widget configuration and showcase UI
//

import SwiftUI
import WidgetKit

struct WidgetSettingsView: View {
    @State private var selectedWidget: WidgetType = .todaysTasks
    @State private var selectedSize: WidgetSize = .medium
    @State private var showInstructions = false

    var body: some View {
        List {
            // Widget Gallery Section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(WidgetType.allCases) { widget in
                            WidgetTypeCard(
                                widget: widget,
                                isSelected: selectedWidget == widget
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedWidget = widget
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            } header: {
                Text("Available Widgets")
            } footer: {
                Text("Tap a widget to view details and available sizes")
            }

            // Selected Widget Details
            Section {
                WidgetDetailView(widget: selectedWidget, selectedSize: $selectedSize)
            } header: {
                Text(selectedWidget.displayName)
            }

            // Size Options
            Section {
                ForEach(selectedWidget.supportedSizes) { size in
                    WidgetSizeRow(
                        size: size,
                        isSelected: selectedSize == size,
                        onSelect: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSize = size
                            }
                        }
                    )
                }
            } header: {
                Text("Available Sizes")
            } footer: {
                Text("Select a size to preview")
            }

            // Preview
            Section {
                WidgetPreviewView(widget: selectedWidget, size: selectedSize)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } header: {
                Text("Preview")
            }

            // How to Add Instructions
            Section {
                Button(action: { showInstructions = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.blue)
                        Text("How to Add Widgets")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Instructions")
            }

            // Widget Refresh
            Section {
                Button(action: {
                    refreshAllWidgets()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                        Text("Refresh All Widgets")
                            .foregroundColor(.primary)
                    }
                }
            } header: {
                Text("Management")
            } footer: {
                Text("Force refresh all widgets with latest data from the app")
            }
        }
        .navigationTitle("Widgets")
        .sheet(isPresented: $showInstructions) {
            WidgetInstructionsView()
        }
    }

    private func refreshAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Widget Type

enum WidgetType: String, CaseIterable, Identifiable {
    case todaysTasks = "TodaysTasksWidget"
    case calendar = "CalendarWidget"
    case quickAdd = "QuickAddWidget"
    case lockScreenCircular = "TaskCountWidget"
    case lockScreenRectangular = "NextEventWidget"
    case lockScreenInline = "CompletedTodayWidget"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .todaysTasks: return "Today's Tasks"
        case .calendar: return "Calendar"
        case .quickAdd: return "Quick Add"
        case .lockScreenCircular: return "Task Count"
        case .lockScreenRectangular: return "Next Event"
        case .lockScreenInline: return "Completed Today"
        }
    }

    var description: String {
        switch self {
        case .todaysTasks:
            return "See your tasks for today at a glance. Shows task count, titles, and due times."
        case .calendar:
            return "View your upcoming events with times and locations."
        case .quickAdd:
            return "Quickly create tasks and events with interactive buttons (iOS 17+)."
        case .lockScreenCircular:
            return "Shows the number of tasks due today on your lock screen."
        case .lockScreenRectangular:
            return "Displays your next upcoming event on the lock screen."
        case .lockScreenInline:
            return "Shows how many tasks you've completed today."
        }
    }

    var icon: String {
        switch self {
        case .todaysTasks: return "checkmark.circle.fill"
        case .calendar: return "calendar"
        case .quickAdd: return "plus.circle.fill"
        case .lockScreenCircular: return "circle.circle"
        case .lockScreenRectangular: return "rectangle"
        case .lockScreenInline: return "minus"
        }
    }

    var iconColor: Color {
        switch self {
        case .todaysTasks: return .blue
        case .calendar: return .purple
        case .quickAdd: return .orange
        case .lockScreenCircular: return .green
        case .lockScreenRectangular: return .purple
        case .lockScreenInline: return .blue
        }
    }

    var supportedSizes: [WidgetSize] {
        switch self {
        case .todaysTasks:
            return [.small, .medium, .large]
        case .calendar:
            return [.small, .medium]
        case .quickAdd:
            return [.small, .medium]
        case .lockScreenCircular:
            return [.lockScreenCircular]
        case .lockScreenRectangular:
            return [.lockScreenRectangular]
        case .lockScreenInline:
            return [.lockScreenInline]
        }
    }

    var isLockScreenWidget: Bool {
        switch self {
        case .lockScreenCircular, .lockScreenRectangular, .lockScreenInline:
            return true
        default:
            return false
        }
    }
}

// MARK: - Widget Size

enum WidgetSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case lockScreenCircular = "Lock Screen Circular"
    case lockScreenRectangular = "Lock Screen Rectangular"
    case lockScreenInline = "Lock Screen Inline"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var dimensions: String {
        switch self {
        case .small: return "2x2 grid spaces"
        case .medium: return "4x2 grid spaces"
        case .large: return "4x4 grid spaces"
        case .lockScreenCircular: return "Circular widget"
        case .lockScreenRectangular: return "Rectangular widget"
        case .lockScreenInline: return "Inline text widget"
        }
    }

    var icon: String {
        switch self {
        case .small: return "square"
        case .medium: return "rectangle"
        case .large: return "square.grid.2x2"
        case .lockScreenCircular: return "circle"
        case .lockScreenRectangular: return "rectangle.portrait"
        case .lockScreenInline: return "minus"
        }
    }
}

// MARK: - Widget Type Card

struct WidgetTypeCard: View {
    let widget: WidgetType
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Image(systemName: widget.icon)
                .font(.title)
                .foregroundColor(widget.iconColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(widget.iconColor.opacity(0.15))
                )

            // Name
            Text(widget.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Badge
            if widget.isLockScreenWidget {
                Text("Lock Screen")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                    )
                    .foregroundColor(.green)
            }
        }
        .frame(width: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? widget.iconColor : Color.clear, lineWidth: 2)
                )
        )
    }
}

// MARK: - Widget Detail View

struct WidgetDetailView: View {
    let widget: WidgetType
    @Binding var selectedSize: WidgetSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Name
            HStack(spacing: 12) {
                Image(systemName: widget.icon)
                    .font(.title2)
                    .foregroundColor(widget.iconColor)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(widget.iconColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(widget.displayName)
                        .font(.headline)

                    if widget.isLockScreenWidget {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text("Lock Screen Widget")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }

            // Description
            Text(widget.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Features
            if !widget.isLockScreenWidget {
                VStack(alignment: .leading, spacing: 8) {
                    FeatureBullet(icon: "arrow.clockwise", text: "Updates every \(updateInterval(for: widget))")
                    FeatureBullet(icon: "hand.tap", text: "Tap to open app")
                    if widget == .quickAdd {
                        FeatureBullet(icon: "star.fill", text: "Interactive buttons (iOS 17+)")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private func updateInterval(for widget: WidgetType) -> String {
        switch widget {
        case .todaysTasks, .lockScreenCircular, .lockScreenInline:
            return "15 minutes"
        case .calendar, .lockScreenRectangular:
            return "30 minutes"
        case .quickAdd:
            return "daily"
        }
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Widget Size Row

struct WidgetSizeRow: View {
    let size: WidgetSize
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: size.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(size.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(size.dimensions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget Preview View

struct WidgetPreviewView: View {
    let widget: WidgetType
    let size: WidgetSize

    var body: some View {
        VStack(spacing: 16) {
            // Preview mockup
            widgetMockup
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            // Preview note
            Text("This is a preview of how the widget will appear")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    @ViewBuilder
    private var widgetMockup: some View {
        switch (widget, size) {
        case (.todaysTasks, .small):
            SmallTasksPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.todaysTasks, .medium):
            MediumTasksPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.todaysTasks, .large):
            LargeTasksPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.calendar, .small):
            SmallCalendarPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.calendar, .medium):
            MediumCalendarPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.quickAdd, .small):
            SmallQuickAddPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.quickAdd, .medium):
            MediumQuickAddPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.lockScreenCircular, .lockScreenCircular):
            CircularLockScreenPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.lockScreenRectangular, .lockScreenRectangular):
            RectangularLockScreenPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        case (.lockScreenInline, .lockScreenInline):
            InlineLockScreenPreview()
                .frame(width: previewSize.width, height: previewSize.height)
        default:
            EmptyView()
        }
    }

    private var previewSize: CGSize {
        switch size {
        case .small:
            return CGSize(width: 155, height: 155)
        case .medium:
            return CGSize(width: 320, height: 155)
        case .large:
            return CGSize(width: 320, height: 320)
        case .lockScreenCircular:
            return CGSize(width: 100, height: 100)
        case .lockScreenRectangular:
            return CGSize(width: 280, height: 90)
        case .lockScreenInline:
            return CGSize(width: 280, height: 30)
        }
    }

    private var cornerRadius: CGFloat {
        size == .lockScreenCircular ? 50 : 16
    }
}

// MARK: - Preview Components

struct SmallTasksPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                Text("Today")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("3")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                Text("tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MediumTasksPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("3")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                TaskPreviewRow(title: "Morning workout", time: "9:00 AM")
                TaskPreviewRow(title: "Team meeting", time: "10:30 AM")
                TaskPreviewRow(title: "Code review", time: "2:00 PM")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct LargeTasksPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Updated 5m ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("5")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                TaskPreviewRow(title: "Morning workout", time: "9:00 AM")
                TaskPreviewRow(title: "Team meeting", time: "10:30 AM")
                TaskPreviewRow(title: "Code review", time: "2:00 PM")
                TaskPreviewRow(title: "Write documentation", time: "3:30 PM")
                TaskPreviewRow(title: "Deploy updates", time: "5:00 PM")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct TaskPreviewRow: View {
    let title: String
    let time: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundColor(.blue)
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
            Spacer()
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SmallCalendarPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Calendar")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Team Standup")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("10:00 AM")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct MediumCalendarPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text("Upcoming Events")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("2")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                EventPreviewRow(title: "Team Standup", time: "10:00 AM")
                EventPreviewRow(title: "Lunch Meeting", time: "12:30 PM")
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct EventPreviewRow: View {
    let title: String
    let time: String

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Nov")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("19")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 40)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.purple.opacity(0.1))
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(time)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
}

struct SmallQuickAddPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Quick Add")
                .font(.headline)
                .fontWeight(.bold)

            Text("Tap to create")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct MediumQuickAddPreview: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                Text("Quick Add")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            HStack(spacing: 12) {
                QuickAddButton(icon: "checkmark.circle.fill", label: "Task", color: .blue)
                QuickAddButton(icon: "calendar.badge.plus", label: "Event", color: .purple)
                QuickAddButton(icon: "sparkles", label: "AI Chat", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct QuickAddButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct CircularLockScreenPreview: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemBackground))

            VStack(spacing: 2) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                Text("3")
                    .font(.system(size: 24, weight: .bold))
                Text("TASKS")
                    .font(.system(size: 10))
                    .textCase(.uppercase)
            }
        }
    }
}

struct RectangularLockScreenPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("NEXT EVENT")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
            }
            .foregroundColor(.secondary)

            Text("Team Standup")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("10:00 AM")
                        .font(.caption)
                }
                HStack(spacing: 2) {
                    Image(systemName: "location")
                        .font(.caption2)
                    Text("Conference Room")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
    }
}

struct InlineLockScreenPreview: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
            Text("5 completed today")
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// MARK: - Widget Instructions View

struct WidgetInstructionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    InstructionStep(
                        number: 1,
                        title: "Long press on your home screen",
                        description: "Press and hold on an empty area of your home screen until the apps start jiggling"
                    )

                    InstructionStep(
                        number: 2,
                        title: "Tap the '+' button",
                        description: "Look for the plus icon in the top-left corner of your screen"
                    )

                    InstructionStep(
                        number: 3,
                        title: "Search for 'Cafe'",
                        description: "Use the search bar or scroll through the widget gallery to find Cafe widgets"
                    )

                    InstructionStep(
                        number: 4,
                        title: "Select a widget",
                        description: "Choose from Today's Tasks, Calendar, or Quick Add widgets"
                    )

                    InstructionStep(
                        number: 5,
                        title: "Choose a size",
                        description: "Swipe left or right to select Small, Medium, or Large size"
                    )

                    InstructionStep(
                        number: 6,
                        title: "Add widget",
                        description: "Tap 'Add Widget' and then 'Done' in the top-right corner"
                    )
                } header: {
                    Text("Adding Home Screen Widgets")
                }

                Section {
                    InstructionStep(
                        number: 1,
                        title: "Long press on the lock screen",
                        description: "Press and hold on your lock screen (not on the time)"
                    )

                    InstructionStep(
                        number: 2,
                        title: "Tap 'Customize'",
                        description: "Select 'Customize' from the menu that appears"
                    )

                    InstructionStep(
                        number: 3,
                        title: "Choose 'Lock Screen'",
                        description: "Select the lock screen you want to customize"
                    )

                    InstructionStep(
                        number: 4,
                        title: "Tap a widget area",
                        description: "Tap on the area above or below the time to add widgets"
                    )

                    InstructionStep(
                        number: 5,
                        title: "Select Cafe widgets",
                        description: "Choose from Task Count (circular), Next Event (rectangular), or Completed Today (inline)"
                    )

                    InstructionStep(
                        number: 6,
                        title: "Tap 'Done'",
                        description: "Confirm your changes and your lock screen widgets are ready"
                    )
                } header: {
                    Text("Adding Lock Screen Widgets (iOS 16+)")
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        WidgetInfoRow(icon: "arrow.clockwise", text: "Widgets update automatically")
                        WidgetInfoRow(icon: "hand.tap", text: "Tap any widget to open the app")
                        WidgetInfoRow(icon: "gear", text: "Widget data syncs with the app")
                        WidgetInfoRow(icon: "bolt.fill", text: "Interactive buttons work on iOS 17+")
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Tips")
                }
            }
            .navigationTitle("How to Add Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }
}

struct WidgetInfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WidgetSettingsView()
    }
}

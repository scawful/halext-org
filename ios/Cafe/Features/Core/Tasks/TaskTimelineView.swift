//
//  TaskTimelineView.swift
//  Cafe
//
//  Timeline/calendar view for tasks
//

import SwiftUI

struct TaskTimelineView: View {
    let tasks: [Task]
    @State private var selectedDate: Date = Date()
    @Environment(ThemeManager.self) private var themeManager
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dateRange: [Date] {
        let startDate = calendar.date(byAdding: .day, value: -7, to: selectedDate) ?? selectedDate
        let endDate = calendar.date(byAdding: .day, value: 14, to: selectedDate) ?? selectedDate
        return generateDates(from: startDate, to: endDate)
    }
    
    private func generateDates(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = start
        while currentDate <= end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        return dates
    }
    
    private func tasksForDate(_ date: Date) -> [Task] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Date selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(dateRange, id: \.self) { date in
                            DateButton(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                taskCount: tasksForDate(date).count,
                                hasOverdue: tasksForDate(date).contains { !$0.completed && ($0.dueDate ?? Date()) < Date() }
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = date
                                }
                                HapticManager.selection()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(themeManager.cardBackgroundColor)
                
                // Tasks for selected date
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedDate, style: .date)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(dayOfWeek(for: selectedDate))
                                .font(.subheadline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Text("\(tasksForDate(selectedDate).count) tasks")
                            .font(.headline)
                            .foregroundColor(themeManager.accentColor)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Task list
                    if tasksForDate(selectedDate).isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(themeManager.secondaryTextColor.opacity(0.5))
                            
                            Text("No tasks for this date")
                                .font(.headline)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(tasksForDate(selectedDate)) { task in
                            TaskTimelineRow(task: task)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Date Button

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let taskCount: Int
    let hasOverdue: Bool
    let action: () -> Void
    
    @Environment(ThemeManager.self) private var themeManager
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : themeManager.secondaryTextColor)
                
                Text(dayNumber)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : themeManager.textColor)
                
                if taskCount > 0 {
                    Circle()
                        .fill(
                            hasOverdue
                                ? Color.red
                                : (isSelected ? Color.white.opacity(0.3) : themeManager.accentColor)
                        )
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 50, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [themeManager.accentColor, themeManager.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [themeManager.cardBackgroundColor, themeManager.cardBackgroundColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : themeManager.accentColor.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? themeManager.accentColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Timeline Row

struct TaskTimelineRow: View {
    let task: Task
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator (if task has time)
            if let dueDate = task.dueDate {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(dueDate, style: .time)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.accentColor)
                }
                .frame(width: 60)
            }
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? themeManager.secondaryTextColor : themeManager.textColor)
                
                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(2)
                }
                
                // Labels
                if !task.labels.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(task.labels.prefix(3)) { label in
                            LabelBadge(label: label)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.completed ? .green : themeManager.secondaryTextColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    TaskTimelineView(tasks: [])
        .environment(ThemeManager.shared)
}


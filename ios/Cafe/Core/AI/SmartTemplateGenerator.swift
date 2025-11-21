//
//  SmartTemplateGenerator.swift
//  Cafe
//
//  AI-powered template generation from task history
//

import Foundation

@MainActor
@Observable
class SmartTemplateGenerator {
    static let shared = SmartTemplateGenerator()
    
    private let apiClient = APIClient.shared
    private let templateManager = TaskTemplateManager.shared
    
    private init() {}
    
    // MARK: - Generate Templates from History
    
    /// Analyze completed tasks and generate reusable templates
    func generateTemplatesFromHistory(limit: Int = 50) async throws -> [TaskTemplate] {
        // Fetch completed tasks
        let allTasks = try await apiClient.getTasks()
        let completedTasks = allTasks
            .filter { $0.completed }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
        
        guard !completedTasks.isEmpty else {
            return []
        }
        
        // Group tasks by patterns
        let patterns = identifyTaskPatterns(Array(completedTasks))
        
        // Generate templates from patterns
        var templates: [TaskTemplate] = []
        
        for pattern in patterns {
            if let template = createTemplate(from: pattern) {
                templates.append(template)
            }
        }
        
        return templates
    }
    
    // MARK: - Pattern Identification
    
    private func identifyTaskPatterns(_ tasks: [Task]) -> [TaskPattern] {
        var patterns: [String: TaskPattern] = [:]
        
        for task in tasks {
            // Extract base pattern from title (remove dates, numbers, etc.)
            let baseTitle = normalizeTitle(task.title)
            
            if patterns[baseTitle] == nil {
                patterns[baseTitle] = TaskPattern(
                    baseTitle: baseTitle,
                    tasks: [],
                    commonLabels: [],
                    averageDueDays: nil
                )
            }
            
            patterns[baseTitle]?.tasks.append(task)
        }
        
        // Filter patterns that appear at least 2 times
        let frequentPatterns = patterns.values.filter { $0.tasks.count >= 2 }
        
        // Analyze each pattern
        return frequentPatterns.map { pattern in
            var updatedPattern = pattern
            
            // Extract common labels
            let allLabels = pattern.tasks.flatMap { $0.labels.map { $0.name } }
            let labelCounts = Dictionary(grouping: allLabels, by: { $0 })
                .mapValues { $0.count }
            updatedPattern.commonLabels = Array(labelCounts.keys.filter { labelCounts[$0] ?? 0 >= 2 })
            
            // Calculate average due days
            let dueDates = pattern.tasks.compactMap { task -> Int? in
                guard let dueDate = task.dueDate else { return nil }
                let days = Calendar.current.dateComponents([.day], from: task.createdAt, to: dueDate).day
                return days
            }
            
            if !dueDates.isEmpty {
                let average = dueDates.reduce(0, +) / dueDates.count
                updatedPattern.averageDueDays = average
            }
            
            return updatedPattern
        }
    }
    
    private func normalizeTitle(_ title: String) -> String {
        // Remove common date patterns, numbers, etc.
        var normalized = title
        
        // Remove dates (e.g., "2024", "Jan 15", etc.)
        normalized = normalized.replacingOccurrences(of: #"\d{4}"#, with: "", options: .regularExpression)
        normalized = normalized.replacingOccurrences(of: #"\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2}"#, with: "", options: .regularExpression)
        
        // Remove standalone numbers
        normalized = normalized.replacingOccurrences(of: #"\b\d+\b"#, with: "", options: .regularExpression)
        
        // Trim and normalize whitespace
        normalized = normalized.trimmingCharacters(in: .whitespaces)
        normalized = normalized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return normalized.isEmpty ? title : normalized
    }
    
    // MARK: - Template Creation
    
    private func createTemplate(from pattern: TaskPattern) -> TaskTemplate? {
        guard pattern.tasks.count >= 2 else { return nil }
        
        // Use the most recent task as the base
        guard let baseTask = pattern.tasks.first else { return nil }
        
        // Create template name from base title
        let templateName = pattern.baseTitle
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Extract common description pattern
        let descriptions = pattern.tasks.compactMap { $0.description }
        let descriptionTemplate = descriptions.first
        
        // Determine icon and color based on labels
        let (icon, color) = determineIconAndColor(from: pattern.commonLabels)
        
        return TaskTemplate(
            name: templateName,
            icon: icon,
            color: color,
            titleTemplate: templateName,
            descriptionTemplate: descriptionTemplate,
            defaultLabels: pattern.commonLabels,
            defaultDueDays: pattern.averageDueDays,
            defaultPriority: nil,
            checklist: []
        )
    }
    
    private func determineIconAndColor(from labels: [String]) -> (String, String) {
        let labelString = labels.joined(separator: " ").lowercased()
        
        // Determine icon based on labels
        let icon: String
        if labelString.contains("meeting") || labelString.contains("call") {
            icon = "person.3"
        } else if labelString.contains("work") || labelString.contains("project") {
            icon = "briefcase"
        } else if labelString.contains("shopping") || labelString.contains("grocery") {
            icon = "cart"
        } else if labelString.contains("fitness") || labelString.contains("workout") {
            icon = "figure.run"
        } else if labelString.contains("recipe") || labelString.contains("cooking") {
            icon = "fork.knife"
        } else if labelString.contains("home") || labelString.contains("house") {
            icon = "house"
        } else {
            icon = "checkmark.circle"
        }
        
        // Determine color
        let color: String
        if labelString.contains("urgent") || labelString.contains("important") {
            color = "red"
        } else if labelString.contains("work") {
            color = "blue"
        } else if labelString.contains("personal") {
            color = "green"
        } else {
            color = "blue"
        }
        
        return (icon, color)
    }
}

// MARK: - Task Pattern Model

private struct TaskPattern {
    var baseTitle: String
    var tasks: [Task]
    var commonLabels: [String]
    var averageDueDays: Int?
}


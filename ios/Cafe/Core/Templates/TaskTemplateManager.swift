//
//  TaskTemplateManager.swift
//  Cafe
//
//  Manages task templates
//

import Foundation

@MainActor
@Observable
class TaskTemplateManager {
    static let shared = TaskTemplateManager()

    private(set) var customTemplates: [TaskTemplate] = []
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "customTaskTemplates"

    var allTemplates: [TaskTemplate] {
        TaskTemplate.builtInTemplates + customTemplates
    }

    private init() {
        loadTemplates()
    }

    // MARK: - CRUD Operations

    func addTemplate(_ template: TaskTemplate) {
        customTemplates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: TaskTemplate) {
        if let index = customTemplates.firstIndex(where: { $0.id == template.id }) {
            customTemplates[index] = template
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: TaskTemplate) {
        customTemplates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func deleteTemplates(at indices: [Int]) {
        for index in indices.sorted(by: >) {
            customTemplates.remove(at: index)
        }
        saveTemplates()
    }

    func getTemplate(id: UUID) -> TaskTemplate? {
        allTemplates.first { $0.id == id }
    }

    // MARK: - Persistence

    private func saveTemplates() {
        do {
            let data = try JSONEncoder().encode(customTemplates)
            userDefaults.set(data, forKey: templatesKey)
            print("✅ Saved \(customTemplates.count) custom templates")
        } catch {
            print("❌ Failed to save templates: \(error)")
        }
    }

    private func loadTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey) else {
            print("ℹ️ No custom templates found")
            return
        }

        do {
            customTemplates = try JSONDecoder().decode([TaskTemplate].self, from: data)
            print("✅ Loaded \(customTemplates.count) custom templates")
        } catch {
            print("❌ Failed to load templates: \(error)")
            customTemplates = []
        }
    }

    // MARK: - Template Usage

    func createTask(from template: TaskTemplate) -> TaskCreate {
        template.createTask()
    }

    // MARK: - Search & Filter

    func searchTemplates(query: String) -> [TaskTemplate] {
        guard !query.isEmpty else { return allTemplates }

        let lowercasedQuery = query.lowercased()
        return allTemplates.filter { template in
            template.name.lowercased().contains(lowercasedQuery) ||
            template.titleTemplate.lowercased().contains(lowercasedQuery) ||
            (template.descriptionTemplate?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    func filterByLabel(_ label: String) -> [TaskTemplate] {
        allTemplates.filter { $0.defaultLabels.contains(label) }
    }

    // MARK: - Statistics

    var templateCount: Int {
        allTemplates.count
    }

    var customTemplateCount: Int {
        customTemplates.count
    }

    var builtInTemplateCount: Int {
        TaskTemplate.builtInTemplates.count
    }
}

//
//  SmartListManager.swift
//  Cafe
//
//  Manages smart lists
//

import Foundation

@MainActor
@Observable
class SmartListManager {
    static let shared = SmartListManager()

    private(set) var customLists: [SmartList] = []
    private let userDefaults = UserDefaults.standard
    private let listsKey = "customSmartLists"

    var allLists: [SmartList] {
        SmartList.builtInLists + customLists
    }

    private init() {
        loadLists()
    }

    // MARK: - CRUD Operations

    func addList(_ list: SmartList) {
        customLists.append(list)
        saveLists()
    }

    func updateList(_ list: SmartList) {
        if let index = customLists.firstIndex(where: { $0.id == list.id }) {
            customLists[index] = list
            saveLists()
        }
    }

    func deleteList(_ list: SmartList) {
        customLists.removeAll { $0.id == list.id }
        saveLists()
    }

    func deleteLists(at indices: [Int]) {
        for index in indices.sorted(by: >) {
            customLists.remove(at: index)
        }
        saveLists()
    }

    func getList(id: UUID) -> SmartList? {
        allLists.first { $0.id == id }
    }

    // MARK: - Persistence

    private func saveLists() {
        do {
            let data = try JSONEncoder().encode(customLists)
            userDefaults.set(data, forKey: listsKey)
            print("✅ Saved \(customLists.count) custom smart lists")
        } catch {
            print("❌ Failed to save smart lists: \(error)")
        }
    }

    private func loadLists() {
        guard let data = userDefaults.data(forKey: listsKey) else {
            print("ℹ️ No custom smart lists found")
            return
        }

        do {
            customLists = try JSONDecoder().decode([SmartList].self, from: data)
            print("✅ Loaded \(customLists.count) custom smart lists")
        } catch {
            print("❌ Failed to load smart lists: \(error)")
            customLists = []
        }
    }

    // MARK: - Task Filtering

    func filterTasks(_ tasks: [Task], using list: SmartList) -> [Task] {
        list.filter(tasks: tasks)
    }

    func groupTasks(_ tasks: [Task], using list: SmartList) -> [(String, [Task])] {
        let filtered = filterTasks(tasks, using: list)
        return list.group(tasks: filtered)
    }

    // MARK: - Search

    func searchLists(query: String) -> [SmartList] {
        guard !query.isEmpty else { return allLists }

        let lowercasedQuery = query.lowercased()
        return allLists.filter { list in
            list.name.lowercased().contains(lowercasedQuery)
        }
    }

    // MARK: - Statistics

    var listCount: Int {
        allLists.count
    }

    var customListCount: Int {
        customLists.count
    }

    var builtInListCount: Int {
        SmartList.builtInLists.count
    }
}

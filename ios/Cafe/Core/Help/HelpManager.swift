//
//  HelpManager.swift
//  Cafe
//
//  Help content manager and search
//

import Foundation

struct HelpArticle: Identifiable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let content: String
    let tags: [String]
    let category: String
    
    init(id: UUID = UUID(), title: String, summary: String, content: String, tags: [String] = [], category: String = "General") {
        self.id = id
        self.title = title
        self.summary = summary
        self.content = content
        self.tags = tags
        self.category = category
    }
}

@MainActor
class HelpManager {
    static let shared = HelpManager()
    
    private var articles: [HelpArticle] = []
    private var recentSearchesList: [String] = []
    
    private let recentSearchesKey = "helpRecentSearches"
    
    init() {
        loadArticles()
        loadRecentSearches()
    }
    
    var recentSearches: [String] {
        recentSearchesList
    }
    
    var popularSearches: [String] {
        [
            "How to create tasks",
            "Dashboard customization",
            "AI chat features",
            "Sync across devices",
            "Widget setup",
            "Theme customization"
        ]
    }
    
    func search(query: String) -> [HelpArticle] {
        let lowercasedQuery = query.lowercased()
        return articles.filter { article in
            article.title.lowercased().contains(lowercasedQuery) ||
            article.summary.lowercased().contains(lowercasedQuery) ||
            article.content.lowercased().contains(lowercasedQuery) ||
            article.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func addRecentSearch(_ search: String) {
        recentSearchesList.removeAll { $0 == search }
        recentSearchesList.insert(search, at: 0)
        if recentSearchesList.count > 10 {
            recentSearchesList = Array(recentSearchesList.prefix(10))
        }
        saveRecentSearches()
    }
    
    private func loadArticles() {
        // Load help articles - in production, this could load from a file or API
        articles = [
            HelpArticle(
                title: "Getting Started with Tasks",
                summary: "Learn how to create, manage, and organize your tasks",
                content: """
                # Getting Started with Tasks
                
                Tasks are the core of productivity in Cafe. Here's how to use them:
                
                ## Creating Tasks
                - Tap the + button in the Tasks view
                - Enter a title and optional description
                - Set a due date if needed
                - Add labels for organization
                
                ## Managing Tasks
                - Swipe left to complete or delete
                - Swipe right for quick actions
                - Tap to view details
                - Use grouping to organize by date, label, or status
                
                ## Timeline View
                - Switch to timeline view to see tasks by date
                - Navigate through dates with the date picker
                - See all tasks for a specific day
                """,
                tags: ["tasks", "getting started", "basics"],
                category: "Tasks"
            ),
            HelpArticle(
                title: "Dashboard Customization",
                summary: "Customize your dashboard layout and cards",
                content: """
                # Dashboard Customization
                
                Make your dashboard work for you with full customization options.
                
                ## Card Management
                - Enter edit mode to drag and reorder cards
                - Tap the gear icon to configure individual cards
                - Use size presets (small, medium, large) for optimal layout
                - Auto-hide cards when they're empty
                
                ## Layout Presets
                - Choose from built-in presets (Default, Focus, Overview)
                - Save your own custom layouts
                - Switch between layouts anytime
                """,
                tags: ["dashboard", "customization", "layout"],
                category: "Dashboard"
            ),
            HelpArticle(
                title: "AI Chat Features",
                summary: "Get help from AI assistants in conversations",
                content: """
                # AI Chat Features
                
                Cafe includes powerful AI assistants to help you be more productive.
                
                ## Starting a Conversation
                - Go to Messages tab
                - Tap "AI Chat" to start
                - Choose your preferred AI model from Agent Hub
                
                ## Features
                - Streaming responses for real-time answers
                - Code syntax highlighting
                - Rich markdown rendering
                - Copy and regenerate message actions
                """,
                tags: ["ai", "chat", "assistant"],
                category: "AI"
            ),
            HelpArticle(
                title: "Theme Customization",
                summary: "Personalize the app's appearance",
                content: """
                # Theme Customization
                
                Make Cafe look exactly how you want.
                
                ## Color Themes
                - Choose from multiple vibrant themes
                - Light and dark mode support
                - Custom accent colors
                - Gradient backgrounds
                
                ## Accessibility
                - Improved contrast ratios
                - Dynamic Type support
                - Reduced motion options
                """,
                tags: ["theme", "customization", "appearance"],
                category: "Settings"
            )
        ]
    }
    
    private func loadRecentSearches() {
        if let data = UserDefaults.standard.data(forKey: recentSearchesKey),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearchesList = searches
        }
    }
    
    private func saveRecentSearches() {
        if let data = try? JSONEncoder().encode(recentSearchesList) {
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        }
    }
}


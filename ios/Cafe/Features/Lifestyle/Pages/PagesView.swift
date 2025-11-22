//
//  PagesView.swift
//  Cafe
//
//  Pages for notes, documents, and AI context
//

import SwiftUI

struct PagesView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var pages: [Page] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingNewPage = false
    @State private var selectedPage: Page?
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && pages.isEmpty {
                    ThemedLoadingStateView(message: "Loading pages...")
                } else if pages.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(pages) { page in
                            NavigationLink(destination: PageDetailView(page: page, onUpdate: { updated in
                                if let index = pages.firstIndex(where: { $0.id == updated.id }) {
                                    pages[index] = updated
                                }
                            })) {
                                PageRowView(page: page)
                            }
                        }
                        .onDelete(perform: deletePages)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(themeManager.backgroundColor)
                    .refreshable {
                        await loadPages()
                    }
                }
            }
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .navigationTitle("Pages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewPage = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPage) {
                NewPageView(onPageCreated: { newPage in
                    pages.insert(newPage, at: 0)
                })
            }
            .task {
                await loadPages()
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var emptyState: some View {
        ThemedEmptyStateView(
            icon: "doc.on.doc",
            title: "No Pages Yet",
            message: "Create pages for notes, documents, and AI context",
            actionTitle: "Create Page",
            action: { showingNewPage = true }
        )
    }
    
    private func loadPages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            pages = try await APIClient.shared.getPages()
        } catch {
            errorMessage = "Failed to load pages: \(error.localizedDescription)"
        }
    }
    
    private func deletePages(at offsets: IndexSet) {
        for index in offsets {
            let page = pages[index]
            _Concurrency.Task {
                do {
                    try await APIClient.shared.deletePage(id: page.id)
                    await loadPages()
                } catch {
                    errorMessage = "Failed to delete page: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Page Row

struct PageRowView: View {
    @Environment(ThemeManager.self) private var themeManager
    let page: Page

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(page.displayTitle)
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)

                Spacer()

                if page.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }

            if let content = page.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
            }

            HStack {
                Text("Updated \(page.updatedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)

                Spacer()

                Text("\(page.layout.widgets.count) widgets")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Page Detail View

struct PageDetailView: View {
    let page: Page
    let onUpdate: (Page) -> Void
    
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @State private var title: String
    @State private var content: String
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showingAIAssist = false
    
    init(page: Page, onUpdate: @escaping (Page) -> Void) {
        self.page = page
        self.onUpdate = onUpdate
        _title = State(initialValue: page.title)
        _content = State(initialValue: page.content ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    TextField("Page Title", text: $title)
                        .font(.title)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                        .foregroundColor(themeManager.textColor)

                    TextEditor(text: $content)
                        .frame(minHeight: 300)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(themeManager.cardBackgroundColor)
                        .cornerRadius(8)
                } else {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textColor)

                    if !content.isEmpty {
                        Text(content)
                            .font(.body)
                            .foregroundColor(themeManager.textColor)
                    } else {
                        Text("No content")
                            .foregroundColor(themeManager.secondaryTextColor)
                            .italic()
                    }
                }
                
                // AI Context Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Writing Assistant", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(themeManager.textColor)

                            Spacer()

                            Button(action: { showingAIAssist = true }) {
                                Image(systemName: "wand.and.stars")
                                    .font(.title3)
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }

                        Text("Use AI to summarize, enhance, expand, or ask questions about this page")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)

                        HStack(spacing: 12) {
                            Button(action: { showingAIAssist = true }) {
                                Label("Open AI Assistant", systemImage: "brain")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(content.isEmpty)
                        }

                        if content.isEmpty {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("Add content to enable AI features")
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        }
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created \(page.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)

                    Text("Last updated \(page.updatedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top)
            }
            .padding()
        }
        .background(themeManager.backgroundColor)
        .navigationTitle(page.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: toggleEdit) {
                    if isEditing {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Done")
                        }
                    } else {
                        Text("Edit")
                    }
                }
                .disabled(isSaving)
            }
        }
        .sheet(isPresented: $showingAIAssist) {
            AIContextSheet(pageContent: content, pageTitle: title) { newContent in
                // Apply AI-generated content to the page
                content = newContent
                isEditing = true // Enable editing mode to show changes
            }
        }
    }
    
    private func toggleEdit() {
        if isEditing {
            saveChanges()
        } else {
            isEditing = true
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        _Concurrency.Task {
            do {
                let update = PageUpdate(title: title, content: content, layout: nil)
                let updatedPage = try await APIClient.shared.updatePage(id: page.id, update)
                onUpdate(updatedPage)
                isEditing = false
            } catch {
                print("Failed to save page: \(error)")
            }
            
            isSaving = false
        }
    }
}

// MARK: - New Page View

struct NewPageView: View {
    @Environment(\.dismiss) var dismiss
    let onPageCreated: (Page) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Page Details") {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Button(action: createPage) {
                        if isCreating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Page")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isCreating || title.isEmpty)
                }
            }
            .navigationTitle("New Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createPage() {
        isCreating = true
        
        _Concurrency.Task {
            do {
                let pageCreate = PageCreate(title: title, content: content, layout: nil)
                let newPage = try await APIClient.shared.createPage(pageCreate)
                onPageCreated(newPage)
                dismiss()
            } catch {
                print("Failed to create page: \(error)")
            }
            
            isCreating = false
        }
    }
}

// MARK: - AI Context Sheet

struct AIContextSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ThemeManager.self) private var themeManager
    let pageContent: String
    let pageTitle: String
    let onApplyContent: ((String) -> Void)?

    @StateObject private var aiAssistant = AIPageAssistant.shared
    @State private var prompt = ""
    @State private var aiResponse = ""
    @State private var isGenerating = false
    @State private var selectedAction: AIPageAction?
    @State private var showingActionPicker = false
    @State private var resultCanReplace = false

    init(pageContent: String, pageTitle: String, onApplyContent: ((String) -> Void)? = nil) {
        self.pageContent = pageContent
        self.pageTitle = pageTitle
        self.onApplyContent = onApplyContent
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Context Preview
                    contextPreviewSection

                    // Quick Actions Grid
                    quickActionsSection

                    // Custom Question Section
                    customQuestionSection

                    // Response Section
                    if !aiResponse.isEmpty {
                        responseSection
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Context Preview Section

    private var contextPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Using as Context", systemImage: "doc.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Text("\(pageContent.count) characters")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
            }

            if !pageContent.isEmpty {
                Text(pageContent.prefix(200) + (pageContent.count > 200 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("No content to analyze. Add some text to your page first.")
                }
                .font(.caption)
                .foregroundColor(.orange)
                .padding()
                .frame(maxWidth: .infinity)
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Actions", systemImage: "bolt.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.textColor)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AIPageAction.allCases.filter { $0 != .askQuestion }) { action in
                    PageQuickActionButton(
                        action: action,
                        isLoading: isGenerating && selectedAction == action,
                        isDisabled: isGenerating || pageContent.isEmpty
                    ) {
                        executeQuickAction(action)
                    }
                }
            }
        }
    }

    // MARK: - Custom Question Section

    private var customQuestionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ask a Question", systemImage: "questionmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(themeManager.textColor)

            TextField("What would you like to know about this content?", text: $prompt, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(8)
                .lineLimit(2...4)

            Button(action: { askQuestion() }) {
                HStack {
                    if isGenerating && selectedAction == .askQuestion {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Thinking...")
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Ask AI")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || prompt.isEmpty || pageContent.isEmpty)
        }
    }

    // MARK: - Response Section

    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let action = selectedAction {
                    Label(action.displayName + " Result", systemImage: action.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.textColor)
                } else {
                    Label("Response", systemImage: "text.bubble")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.textColor)
                }

                Spacer()

                Button(action: copyResponse) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                if resultCanReplace && onApplyContent != nil {
                    Button(action: applyToPage) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Apply")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            ScrollView {
                Text(aiResponse)
                    .font(.body)
                    .foregroundColor(themeManager.textColor)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(8)
            .frame(maxHeight: 300)

            if let model = aiAssistant.lastResult?.model {
                Text("Generated by \(model)")
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
        }
    }

    // MARK: - Actions

    private func executeQuickAction(_ action: AIPageAction) {
        guard !pageContent.isEmpty else { return }

        selectedAction = action
        isGenerating = true
        aiResponse = ""

        _Concurrency.Task {
            do {
                let result = try await aiAssistant.executeAction(
                    action,
                    content: pageContent,
                    pageTitle: pageTitle
                )
                aiResponse = result.generatedContent
                resultCanReplace = result.canReplaceContent
            } catch {
                aiResponse = "Error: \(error.localizedDescription)"
                resultCanReplace = false
            }
            isGenerating = false
        }
    }

    private func askQuestion() {
        guard !prompt.isEmpty, !pageContent.isEmpty else { return }

        selectedAction = .askQuestion
        isGenerating = true
        aiResponse = ""

        _Concurrency.Task {
            do {
                let response = try await aiAssistant.askQuestion(
                    prompt,
                    content: pageContent,
                    pageTitle: pageTitle
                )
                aiResponse = response
                resultCanReplace = false
            } catch {
                aiResponse = "Error: \(error.localizedDescription)"
            }
            isGenerating = false
            prompt = ""
        }
    }

    private func copyResponse() {
        UIPasteboard.general.string = aiResponse
    }

    private func applyToPage() {
        onApplyContent?(aiResponse)
        dismiss()
    }
}

// MARK: - Page Quick Action Button

struct PageQuickActionButton: View {
    @Environment(ThemeManager.self) private var themeManager
    let action: AIPageAction
    let isLoading: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: action.icon)
                        .font(.title3)
                        .foregroundColor(themeManager.accentColor)
                }

                Text(action.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundColor(themeManager.textColor)

                Text(action.description)
                    .font(.caption2)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
    }
}

#Preview {
    PagesView()
        .environment(ThemeManager.shared)
}


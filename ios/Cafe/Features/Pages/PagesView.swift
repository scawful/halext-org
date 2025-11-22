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
                    ProgressView()
                        .frame(maxHeight: .infinity)
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
        VStack(spacing: 24) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Pages Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create pages for notes, documents, and AI context")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingNewPage = true }) {
                Label("Create Page", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxHeight: .infinity)
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
    let page: Page
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(page.displayTitle)
                    .font(.headline)
                
                Spacer()
                
                if page.isShared {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let content = page.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Text("Updated \(page.updatedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(page.layout.widgets.count) widgets")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 300)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if !content.isEmpty {
                        Text(content)
                            .font(.body)
                    } else {
                        Text("No content")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                
                // AI Context Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("AI Context", systemImage: "sparkles")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingAIAssist = true }) {
                                Image(systemName: "wand.and.stars")
                                    .font(.title3)
                            }
                        }
                        
                        Text("This page can be used as context for AI conversations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !content.isEmpty {
                            Button("Use as AI Context") {
                                // TODO: Implement AI context usage
                                showingAIAssist = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    Text("Created \(page.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Last updated \(page.updatedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            AIContextSheet(pageContent: content, pageTitle: title)
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
    let pageContent: String
    let pageTitle: String
    
    @State private var prompt = ""
    @State private var aiResponse = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Context Preview
                VStack(alignment: .leading, spacing: 8) {
                    Label("Using as Context", systemImage: "doc.text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(pageContent.prefix(200) + "...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Prompt Input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Ask About This Content", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("What would you like to know?", text: $prompt, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .lineLimit(3...5)
                }
                
                Button(action: generateResponse) {
                    if isGenerating {
                        HStack {
                            ProgressView()
                            Text("Generating...")
                        }
                    } else {
                        Label("Ask AI", systemImage: "sparkles")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || prompt.isEmpty)
                
                // Response
                if !aiResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Response", systemImage: "text.bubble")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            Text(aiResponse)
                                .font(.body)
                                .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(maxHeight: 300)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
    
    private func generateResponse() {
        isGenerating = true
        aiResponse = ""
        
        _Concurrency.Task {
            do {
                // Build context-aware prompt
                let contextPrompt = """
                Based on the following content from "\(pageTitle)":
                
                \(pageContent)
                
                Question: \(prompt)
                """
                
                let chatResponse = try await APIClient.shared.sendChatMessage(
                    prompt: contextPrompt,
                    history: []
                )
                
                aiResponse = chatResponse.response
            } catch {
                aiResponse = "Error: \(error.localizedDescription)"
            }
            
            isGenerating = false
        }
    }
}

#Preview {
    PagesView()
        .environment(ThemeManager.shared)
}


//
//  MemoriesView.swift
//  Cafe
//
//  Timeline view of shared memories with Chris
//

import SwiftUI

struct MemoriesView: View {
    @Environment(ThemeManager.self) var themeManager
    @State private var viewModel = MemoriesViewModel()
    @State private var showingNewMemory = false
    @State private var searchText = ""

    var filteredMemories: [Memory] {
        if searchText.isEmpty {
            return viewModel.memories
        }
        return viewModel.memories.filter { memory in
            memory.title.localizedCaseInsensitiveContains(searchText) ||
            (memory.content?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (memory.location?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredMemories.isEmpty && searchText.isEmpty {
                    EmptyMemoriesView(onCreateMemory: { showingNewMemory = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredMemories) { memory in
                                NavigationLink {
                                    MemoryDetailView(memory: memory)
                                } label: {
                                    MemoryCard(memory: memory)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Memories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewMemory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMemory) {
                NewMemoryView(viewModel: viewModel)
            }
            .searchable(text: $searchText, prompt: "Search memories")
            .task {
                await viewModel.loadMemories()
            }
            .refreshable {
                await viewModel.loadMemories()
            }
        }
    }
}

// MARK: - Memory Card

struct MemoryCard: View {
    @Environment(ThemeManager.self) var themeManager
    let memory: Memory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(memory.title)
                        .font(.headline)
                    
                    Text(memory.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(themeManager.accentColor)
            }
            
            // Content
            if let content = memory.content {
                Text(content)
                    .font(.subheadline)
                    .lineLimit(3)
                    .foregroundColor(themeManager.textColor)
            }
            
            // Photos preview
            if let photos = memory.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos.prefix(3), id: \.self) { photoURL in
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                        }
                        
                        if photos.count > 3 {
                            Text("+\(photos.count - 3)")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                                .frame(width: 80, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeManager.cardBackgroundColor)
                                )
                        }
                    }
                }
            }
            
            // Location
            if let location = memory.location {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(location)
                        .font(.caption)
                }
                .foregroundColor(themeManager.secondaryTextColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyMemoriesView: View {
    @Environment(ThemeManager.self) var themeManager
    let onCreateMemory: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(themeManager.secondaryTextColor)

            Text("No Memories Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textColor)

            Text("Create your first shared memory together")
                .font(.subheadline)
                .foregroundColor(themeManager.secondaryTextColor)
                .multilineTextAlignment(.center)

            Button(action: onCreateMemory) {
                Label("Create Memory", systemImage: "plus.circle.fill")
                    .padding()
                    .background(themeManager.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

#Preview {
    MemoriesView()
}


//
//  MemoriesView.swift
//  Cafe
//
//  Timeline view of shared memories with Chris
//

import SwiftUI

struct MemoriesView: View {
    @State private var viewModel = MemoriesViewModel()
    @State private var showingNewMemory = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.memories.isEmpty {
                    EmptyMemoriesView(onCreateMemory: { showingNewMemory = true })
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.memories) { memory in
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
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.pink)
            }
            
            // Content
            if let content = memory.content {
                Text(content)
                    .font(.subheadline)
                    .lineLimit(3)
                    .foregroundColor(.primary)
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
                                .foregroundColor(.secondary)
                                .frame(width: 80, height: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
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
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ThemeManager.shared.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyMemoriesView: View {
    let onCreateMemory: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Memories Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first shared memory together")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateMemory) {
                Label("Create Memory", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
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


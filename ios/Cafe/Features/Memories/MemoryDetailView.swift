//
//  MemoryDetailView.swift
//  Cafe
//
//  Detailed view of a shared memory
//

import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(memory.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(memory.createdAt, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                    }
                }
                .padding()
                
                // Content
                if let content = memory.content {
                    Text(content)
                        .font(.body)
                        .padding(.horizontal)
                }
                
                // Photos
                if let photos = memory.photos, !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos, id: \.self) { photoURL in
                                AsyncImage(url: URL(string: photoURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                }
                                .frame(width: 300, height: 300)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Location
                if let location = memory.location {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MemoryDetailView(memory: Memory(
            id: 1,
            title: "Sample Memory",
            content: "This is a sample memory",
            photos: nil,
            location: "San Francisco",
            sharedWith: ["magicalgirl"],
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: 1
        ))
    }
}


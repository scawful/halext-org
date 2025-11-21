//
//  NewMemoryView.swift
//  Cafe
//
//  Create a new shared memory
//

import SwiftUI
import PhotosUI

struct NewMemoryView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: MemoriesViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var location = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoData: [Data] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var preferredContactUsername: String = "magicalgirl"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Memory Details") {
                    TextField("Title", text: $title)
                    
                    TextField("What happened?", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                    
                    TextField("Location (optional)", text: $location)
                }
                
                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label("Add Photos", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: selectedPhotos) { _, newItems in
                        loadPhotos(from: newItems)
                    }
                    
                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .overlay(
                                                Button {
                                                    photoData.remove(at: index)
                                                    selectedPhotos.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.5))
                                                        .clipShape(Circle())
                                                }
                                                .padding(4),
                                                alignment: .topTrailing
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Sharing") {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.pink)
                        Text("Will be shared with \(preferredContactUsername.capitalized)")
                            .font(.subheadline)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        _Concurrency.Task {
                            await createMemory()
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        _Concurrency.Task {
            var loadedData: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    loadedData.append(data)
                }
            }
            await MainActor.run {
                photoData = loadedData
            }
        }
    }
    
    private func createMemory() async {
        isSubmitting = true
        errorMessage = nil
        
        // For now, we'll store photo URLs as placeholders
        // In production, you'd upload photos to a storage service first
        let photoURLs = photoData.enumerated().map { index, _ in
            "photo_\(UUID().uuidString)_\(index).jpg"
        }
        
        let memory = MemoryCreate(
            title: title,
            content: content.isEmpty ? nil : content,
            photos: photoURLs.isEmpty ? nil : photoURLs,
            location: location.isEmpty ? nil : location,
            sharedWith: [preferredContactUsername]
        )
        
        do {
            _ = try await viewModel.createMemory(memory)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

#Preview {
    NewMemoryView(viewModel: MemoriesViewModel())
}


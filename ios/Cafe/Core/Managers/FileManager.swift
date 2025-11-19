//
//  FileManager.swift
//  Cafe
//
//  File and photo picker management
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - File Picker Manager

@MainActor
@Observable
class FilePickerManager {
    static let shared = FilePickerManager()

    var isShowingDocumentPicker = false
    var isShowingPhotoPicker = false
    var selectedImages: [UIImage] = []
    var selectedFiles: [PickedFile] = []

    private init() {}

    // MARK: - Photo Picker

    func selectPhotos(maxSelection: Int = 10, completion: @escaping ([UIImage]) -> Void) {
        selectedImages = []
        isShowingPhotoPicker = true
        // Completion handled in PhotoPickerView
    }

    func processPhotoSelection(_ items: [PhotosPickerItem]) async {
        selectedImages = []

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    // MARK: - Document Picker

    func selectDocuments(types: [UTType] = [.pdf, .text, .plainText, .image],
                        allowsMultiple: Bool = true,
                        completion: @escaping ([PickedFile]) -> Void) {
        selectedFiles = []
        isShowingDocumentPicker = true
        // Completion handled in DocumentPickerView
    }

    func processDocumentSelection(_ urls: [URL]) async throws {
        selectedFiles = []

        for url in urls {
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let data = try? Data(contentsOf: url) else { continue }

            let file = PickedFile(
                id: UUID(),
                name: url.lastPathComponent,
                type: url.pathExtension,
                size: data.count,
                data: data,
                url: url
            )

            selectedFiles.append(file)
        }
    }

    // MARK: - File Operations

    func saveToDocuments(_ data: Data, filename: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    func deleteFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    func getFileSize(at url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}

// MARK: - Picked File Model

struct PickedFile: Identifiable {
    let id: UUID
    let name: String
    let type: String
    let size: Int
    let data: Data
    let url: URL

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var icon: String {
        switch type.lowercased() {
        case "pdf":
            return "doc.fill"
        case "txt", "text":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "heic":
            return "photo.fill"
        case "doc", "docx":
            return "doc.richtext.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "zip", "rar":
            return "doc.zipper"
        default:
            return "doc.fill"
        }
    }
}

// MARK: - Photo Picker View

struct PhotoPickerView: View {
    @Binding var isPresented: Bool
    let maxSelection: Int
    let onComplete: ([UIImage]) -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack {
                if isProcessing {
                    ProgressView("Processing images...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxSelection,
                        matching: .images
                    ) {
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Select Photos")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Choose up to \(maxSelection) photos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .onChange(of: selectedItems) { _, newItems in
                        if !newItems.isEmpty {
                            processSelection(newItems)
                        }
                    }
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func processSelection(_ items: [PhotosPickerItem]) {
        isProcessing = true

        _Concurrency.Task {
            await FilePickerManager.shared.processPhotoSelection(items)

            await MainActor.run {
                onComplete(FilePickerManager.shared.selectedImages)
                isProcessing = false
                isPresented = false
            }
        }
    }
}

// MARK: - Document Picker Wrapper

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let types: [UTType]
    let allowsMultiple: Bool
    let onComplete: ([PickedFile]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = allowsMultiple
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            _Concurrency.Task {
                try? await FilePickerManager.shared.processDocumentSelection(urls)

                await MainActor.run {
                    parent.onComplete(FilePickerManager.shared.selectedFiles)
                    parent.isPresented = false
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

// MARK: - File Attachment View

struct FileAttachmentView: View {
    let file: PickedFile
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: file.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Image Attachment View

struct ImageAttachmentView: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.red))
            }
            .offset(x: 8, y: -8)
        }
    }
}

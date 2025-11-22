//
//  SharedFilesViewModel.swift
//  Cafe
//
//  Business logic for shared files management
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
class SharedFilesViewModel {
    var files: [SharedFile] = []
    var filteredFiles: [SharedFile] = []
    var searchText = ""
    var selectedCategory: FileCategory?
    var sortOption: FileSortOption = .dateNewest
    var viewMode: FileViewMode = .grid

    var isLoading = false
    var errorMessage: String?
    var selectedFile: SharedFile?

    private let cloudKitManager = CloudKitManager.shared
    private let filePickerManager = FilePickerManager.shared
    private let localStorageManager = LocalFileStorageManager.shared

    init() {
        _Concurrency.Task {
            await loadFiles()
        }
    }

    // MARK: - File Loading

    func loadFiles() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load from local storage first
            let localFiles = localStorageManager.loadFiles()
            files = localFiles

            // Apply filters
            applyFilters()

            // Then sync with CloudKit if available
            if cloudKitManager.isAvailable {
                let cloudFiles = try await cloudKitManager.fetchAllFiles()

                // Merge cloud files with local files
                mergeCloudFiles(cloudFiles)
            } else {
                // Update sync status for all files
                for index in files.indices {
                    files[index].syncStatus = .notAvailable
                }
            }

        } catch {
            errorMessage = "Failed to load files: \(error.localizedDescription)"
            print("Error loading files: \(error)")
        }

        isLoading = false
    }

    private func mergeCloudFiles(_ cloudFiles: [SharedFile]) {
        var mergedFiles = files

        for cloudFile in cloudFiles {
            if let index = mergedFiles.firstIndex(where: { $0.id == cloudFile.id }) {
                // Update existing file
                mergedFiles[index] = cloudFile
            } else {
                // Add new file from cloud
                mergedFiles.append(cloudFile)
            }
        }

        files = mergedFiles
        localStorageManager.saveFiles(files)
        applyFilters()
    }

    // MARK: - File Upload

    func uploadFile(from pickedFile: PickedFile, uploadedBy: String, userId: Int?) async {
        isLoading = true
        errorMessage = nil

        do {
            // Create SharedFile object
            let sharedFile = SharedFile(
                name: pickedFile.name.components(separatedBy: ".").dropLast().joined(separator: "."),
                fileExtension: pickedFile.type,
                size: Int64(pickedFile.size),
                mimeType: getMimeType(for: pickedFile.type),
                uploadedBy: uploadedBy,
                uploadedByUserId: userId,
                localURL: try localStorageManager.saveFile(pickedFile.data, filename: pickedFile.name),
                thumbnailData: generateThumbnail(from: pickedFile)
            )

            // Save to local storage
            files.append(sharedFile)
            localStorageManager.saveFiles(files)

            // Upload to CloudKit if available
            if cloudKitManager.isAvailable {
                let uploadedFile = try await cloudKitManager.uploadFile(sharedFile, data: pickedFile.data)

                // Update the file in our list
                if let index = files.firstIndex(where: { $0.id == sharedFile.id }) {
                    files[index] = uploadedFile
                    localStorageManager.saveFiles(files)
                }
            } else {
                // Mark as not synced if CloudKit not available
                if let index = files.firstIndex(where: { $0.id == sharedFile.id }) {
                    files[index].syncStatus = .notAvailable
                }
            }

            applyFilters()

        } catch {
            errorMessage = "Failed to upload file: \(error.localizedDescription)"
            print("Error uploading file: \(error)")
        }

        isLoading = false
    }

    // MARK: - File Download

    func downloadFile(_ file: SharedFile) async -> Data? {
        isLoading = true
        errorMessage = nil

        do {
            // Try local storage first
            if let localURL = file.localURL,
               let data = try? Data(contentsOf: localURL) {
                isLoading = false
                return data
            }

            // Fall back to CloudKit
            if cloudKitManager.isAvailable {
                let data = try await cloudKitManager.downloadFile(file)

                // Save to local storage
                let savedURL = try localStorageManager.saveFile(data, filename: file.fileName)
                if let index = files.firstIndex(where: { $0.id == file.id }) {
                    files[index].localURL = savedURL
                    localStorageManager.saveFiles(files)
                }

                isLoading = false
                return data
            }

            throw CloudKitError.downloadFailed

        } catch {
            errorMessage = "Failed to download file: \(error.localizedDescription)"
            print("Error downloading file: \(error)")
            isLoading = false
            return nil
        }
    }

    // MARK: - File Deletion

    func deleteFile(_ file: SharedFile) async {
        isLoading = true
        errorMessage = nil

        do {
            // Delete from CloudKit if synced
            if file.isSynced && cloudKitManager.isAvailable {
                try await cloudKitManager.deleteFile(file)
            }

            // Delete local file
            if let localURL = file.localURL {
                try? FileManager.default.removeItem(at: localURL)
            }

            // Remove from list
            files.removeAll { $0.id == file.id }
            localStorageManager.saveFiles(files)
            applyFilters()

        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
            print("Error deleting file: \(error)")
        }

        isLoading = false
    }

    // MARK: - File Sharing

    func shareFile(_ file: SharedFile, with users: [String]) async {
        isLoading = true
        errorMessage = nil

        do {
            if cloudKitManager.isAvailable {
                let updatedFile = try await cloudKitManager.shareFile(file, with: users)

                // Update in our list
                if let index = files.firstIndex(where: { $0.id == file.id }) {
                    files[index] = updatedFile
                    localStorageManager.saveFiles(files)
                    applyFilters()
                }
            } else {
                throw CloudKitError.accountNotAvailable
            }

        } catch {
            errorMessage = "Failed to share file: \(error.localizedDescription)"
            print("Error sharing file: \(error)")
        }

        isLoading = false
    }

    // MARK: - Filtering and Sorting

    func applyFilters() {
        var results = files

        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { file in
                file.name.localizedCaseInsensitiveContains(searchText) ||
                file.fileName.localizedCaseInsensitiveContains(searchText) ||
                file.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Sort
        results = sortFiles(results, by: sortOption)

        filteredFiles = results
    }

    private func sortFiles(_ files: [SharedFile], by option: FileSortOption) -> [SharedFile] {
        switch option {
        case .nameAscending:
            return files.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDescending:
            return files.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }
        case .dateNewest:
            return files.sorted { $0.uploadedAt > $1.uploadedAt }
        case .dateOldest:
            return files.sorted { $0.uploadedAt < $1.uploadedAt }
        case .sizeSmallest:
            return files.sorted { $0.size < $1.size }
        case .sizeLargest:
            return files.sorted { $0.size > $1.size }
        case .category:
            return files.sorted { $0.category.rawValue < $1.category.rawValue }
        }
    }

    // MARK: - Helper Methods

    private func getMimeType(for fileExtension: String) -> String {
        if let utType = UTType(filenameExtension: fileExtension) {
            return utType.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }

    private func generateThumbnail(from pickedFile: PickedFile) -> Data? {
        // Only generate thumbnails for images
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "gif", "webp"]
        guard imageExtensions.contains(pickedFile.type.lowercased()) else {
            return nil
        }

        guard let image = UIImage(data: pickedFile.data) else {
            return nil
        }

        // Resize to thumbnail size
        let targetSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: targetSize)

        let thumbnail = renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return thumbnail.jpegData(compressionQuality: 0.7)
    }

    // MARK: - Sync

    func syncAllFiles() async {
        guard cloudKitManager.isAvailable else {
            errorMessage = "iCloud is not available"
            return
        }

        isLoading = true
        errorMessage = nil

        for file in files where !file.isSynced {
            if let localURL = file.localURL,
               let data = try? Data(contentsOf: localURL) {
                do {
                    let syncedFile = try await cloudKitManager.syncFile(file, data: data)
                    if let index = files.firstIndex(where: { $0.id == file.id }) {
                        files[index] = syncedFile
                    }
                } catch {
                    print("Error syncing file \(file.name): \(error)")
                }
            }
        }

        localStorageManager.saveFiles(files)
        applyFilters()
        isLoading = false
    }
}

// MARK: - Local File Storage Manager

@MainActor
class LocalFileStorageManager {
    static let shared = LocalFileStorageManager()

    private let filesDirectory: URL
    private let metadataURL: URL

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        filesDirectory = documentsPath.appendingPathComponent("SharedFiles", isDirectory: true)
        metadataURL = documentsPath.appendingPathComponent("shared_files_metadata.json")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)
    }

    func saveFile(_ data: Data, filename: String) throws -> URL {
        let fileURL = filesDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    func loadFiles() -> [SharedFile] {
        guard let data = try? Data(contentsOf: metadataURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([SharedFile].self, from: data)
        } catch {
            print("Error decoding files metadata: \(error)")
            return []
        }
    }

    func saveFiles(_ files: [SharedFile]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(files)
            try data.write(to: metadataURL)
        } catch {
            print("Error saving files metadata: \(error)")
        }
    }
}

//
//  CloudKitManager.swift
//  Cafe
//
//  CloudKit integration for syncing files and data
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
@Observable
class CloudKitManager {
    static let shared = CloudKitManager()

    var isAvailable = false
    var accountStatus: CKAccountStatus = .couldNotDetermine
    var lastError: Error?
    var isSyncing = false

    private let container: CKContainer! = nil
    private let publicDatabase: CKDatabase! = nil
    private let privateDatabase: CKDatabase! = nil

    private init() {
        // CloudKit disabled - will use backend API for file sharing in the future
        // Containers are set to nil in property declarations
        isAvailable = false

        // Task {
        //     await checkAccountStatus()
        // }
    }

    // MARK: - Account Status

    func checkAccountStatus() async {
        do {
            accountStatus = try await container.accountStatus()
            isAvailable = accountStatus == .available

            if !isAvailable {
                print("iCloud not available: \(accountStatus)")
            }
        } catch {
            print("Error checking iCloud status: \(error)")
            lastError = error
            isAvailable = false
        }
    }

    func requestPermission() async -> Bool {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            isAvailable = status == .available
            return isAvailable
        } catch {
            print("Error requesting iCloud permission: \(error)")
            lastError = error
            return false
        }
    }

    // MARK: - File Upload

    func uploadFile(_ file: SharedFile, data: Data) async throws -> SharedFile {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        isSyncing = true
        defer { isSyncing = false }

        // Save file data to temporary location
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.id.uuidString)
            .appendingPathExtension(file.fileExtension)

        try data.write(to: tempURL)

        // Create CloudKit asset
        let asset = CKAsset(fileURL: tempURL)

        // Create record
        var updatedFile = file
        updatedFile.syncStatus = .syncing

        let record = updatedFile.toCloudKitRecord()
        record["fileData"] = asset

        do {
            let savedRecord = try await privateDatabase.save(record)

            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)

            // Update file with CloudKit info
            updatedFile.cloudRecordID = savedRecord.recordID.recordName
            updatedFile.isSynced = true
            updatedFile.syncStatus = .synced

            return updatedFile
        } catch {
            // Clean up temp file on error
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }

    // MARK: - File Download

    func downloadFile(_ file: SharedFile) async throws -> Data {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        guard let recordID = file.cloudRecordID else {
            throw CloudKitError.recordNotFound
        }

        let ckRecordID = CKRecord.ID(recordName: recordID)

        do {
            let record = try await privateDatabase.record(for: ckRecordID)

            guard let asset = record["fileData"] as? CKAsset,
                  let fileURL = asset.fileURL else {
                throw CloudKitError.assetNotFound
            }

            return try Data(contentsOf: fileURL)
        } catch {
            throw error
        }
    }

    // MARK: - Fetch Files

    func fetchAllFiles() async throws -> [SharedFile] {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        isSyncing = true
        defer { isSyncing = false }

        let query = CKQuery(recordType: "SharedFile", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

        do {
            let (matchResults, _) = try await privateDatabase.records(matching: query)

            var files: [SharedFile] = []

            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    if let file = SharedFile.fromCloudKitRecord(record) {
                        files.append(file)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }

            return files
        } catch {
            throw error
        }
    }

    // MARK: - Delete File

    func deleteFile(_ file: SharedFile) async throws {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        guard let recordID = file.cloudRecordID else {
            throw CloudKitError.recordNotFound
        }

        let ckRecordID = CKRecord.ID(recordName: recordID)

        do {
            _ = try await privateDatabase.deleteRecord(withID: ckRecordID)
        } catch {
            throw error
        }
    }

    // MARK: - Update File

    func updateFile(_ file: SharedFile) async throws -> SharedFile {
        guard isAvailable else {
            throw CloudKitError.accountNotAvailable
        }

        guard let recordID = file.cloudRecordID else {
            throw CloudKitError.recordNotFound
        }

        isSyncing = true
        defer { isSyncing = false }

        let ckRecordID = CKRecord.ID(recordName: recordID)

        do {
            // Fetch existing record
            let record = try await privateDatabase.record(for: ckRecordID)

            // Update fields
            record["name"] = file.name as CKRecordValue
            record["tags"] = file.tags as CKRecordValue
            record["sharedWith"] = file.sharedWith as CKRecordValue
            record["isPublic"] = (file.isPublic ? 1 : 0) as CKRecordValue
            record["modifiedAt"] = Date() as CKRecordValue

            // Save
            let savedRecord = try await privateDatabase.save(record)

            var updatedFile = file
            updatedFile.cloudRecordID = savedRecord.recordID.recordName
            updatedFile.isSynced = true
            updatedFile.syncStatus = .synced
            updatedFile.modifiedAt = Date()

            return updatedFile
        } catch {
            throw error
        }
    }

    // MARK: - Share File

    func shareFile(_ file: SharedFile, with users: [String]) async throws -> SharedFile {
        var updatedFile = file
        updatedFile.sharedWith = users
        return try await updateFile(updatedFile)
    }

    // MARK: - Sync Status

    func syncFile(_ file: SharedFile, data: Data) async throws -> SharedFile {
        if file.cloudRecordID != nil {
            return try await updateFile(file)
        } else {
            return try await uploadFile(file, data: data)
        }
    }
}

// MARK: - CloudKit Errors

enum CloudKitError: LocalizedError {
    case accountNotAvailable
    case recordNotFound
    case assetNotFound
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .recordNotFound:
            return "File record not found in iCloud."
        case .assetNotFound:
            return "File data not found in iCloud."
        case .uploadFailed:
            return "Failed to upload file to iCloud."
        case .downloadFailed:
            return "Failed to download file from iCloud."
        }
    }
}

// MARK: - Account Status Display

extension CKAccountStatus {
    var displayName: String {
        switch self {
        case .available:
            return "Available"
        case .noAccount:
            return "No iCloud Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .available:
            return "checkmark.icloud.fill"
        case .noAccount:
            return "xmark.icloud.fill"
        case .restricted:
            return "exclamationmark.icloud.fill"
        case .couldNotDetermine:
            return "questionmark.circle.fill"
        case .temporarilyUnavailable:
            return "exclamationmark.icloud.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .available:
            return .green
        case .noAccount:
            return .red
        case .restricted:
            return .orange
        case .couldNotDetermine:
            return .gray
        case .temporarilyUnavailable:
            return .yellow
        @unknown default:
            return .gray
        }
    }
}

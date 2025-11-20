//
//  SharedFileModels.swift
//  Cafe
//
//  Models for shared file management with CloudKit support
//

import Foundation
import SwiftUI
import CloudKit

// MARK: - Shared File Model

struct SharedFile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var fileExtension: String
    var size: Int64
    var mimeType: String
    var category: FileCategory
    var tags: [String]
    var uploadedBy: String
    var uploadedByUserId: Int?
    var uploadedAt: Date
    var modifiedAt: Date
    var sharedWith: [String]  // Usernames of people with access
    var isPublic: Bool
    var localURL: URL?
    var cloudRecordID: String?  // CloudKit record ID
    var thumbnailData: Data?
    var isSynced: Bool
    var syncStatus: SyncStatus

    var fileName: String {
        "\(name).\(fileExtension)"
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var icon: String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "doc.fill"
        case "txt", "text", "md", "markdown":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "heic", "gif", "webp":
            return "photo.fill"
        case "doc", "docx", "rtf":
            return "doc.richtext.fill"
        case "xls", "xlsx", "csv":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "rectangle.on.rectangle.angled"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "mp4", "mov", "avi", "mkv":
            return "video.fill"
        case "mp3", "wav", "m4a", "flac":
            return "music.note"
        case "json", "xml", "html", "css", "js", "swift", "py", "java":
            return "chevron.left.forwardslash.chevron.right"
        default:
            return "doc.fill"
        }
    }

    var color: Color {
        switch category {
        case .document:
            return .blue
        case .image:
            return .purple
        case .video:
            return .red
        case .audio:
            return .orange
        case .archive:
            return .gray
        case .code:
            return .green
        case .other:
            return .secondary
        }
    }

    var canPreview: Bool {
        let previewableExtensions = ["pdf", "txt", "jpg", "jpeg", "png", "heic", "gif", "md", "json", "html", "css", "js", "swift"]
        return previewableExtensions.contains(fileExtension.lowercased())
    }

    init(
        id: UUID = UUID(),
        name: String,
        fileExtension: String,
        size: Int64,
        mimeType: String,
        category: FileCategory? = nil,
        tags: [String] = [],
        uploadedBy: String,
        uploadedByUserId: Int? = nil,
        uploadedAt: Date = Date(),
        modifiedAt: Date = Date(),
        sharedWith: [String] = [],
        isPublic: Bool = false,
        localURL: URL? = nil,
        cloudRecordID: String? = nil,
        thumbnailData: Data? = nil,
        isSynced: Bool = false,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.name = name
        self.fileExtension = fileExtension
        self.size = size
        self.mimeType = mimeType
        self.category = category ?? FileCategory.fromExtension(fileExtension)
        self.tags = tags
        self.uploadedBy = uploadedBy
        self.uploadedByUserId = uploadedByUserId
        self.uploadedAt = uploadedAt
        self.modifiedAt = modifiedAt
        self.sharedWith = sharedWith
        self.isPublic = isPublic
        self.localURL = localURL
        self.cloudRecordID = cloudRecordID
        self.thumbnailData = thumbnailData
        self.isSynced = isSynced
        self.syncStatus = syncStatus
    }
}

// MARK: - File Category

enum FileCategory: String, Codable, CaseIterable, Identifiable {
    case document = "Document"
    case image = "Image"
    case video = "Video"
    case audio = "Audio"
    case archive = "Archive"
    case code = "Code"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .document:
            return "doc.text.fill"
        case .image:
            return "photo.fill"
        case .video:
            return "video.fill"
        case .audio:
            return "music.note"
        case .archive:
            return "doc.zipper"
        case .code:
            return "chevron.left.forwardslash.chevron.right"
        case .other:
            return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .document:
            return .blue
        case .image:
            return .purple
        case .video:
            return .red
        case .audio:
            return .orange
        case .archive:
            return .gray
        case .code:
            return .green
        case .other:
            return .secondary
        }
    }

    static func fromExtension(_ ext: String) -> FileCategory {
        let lowercased = ext.lowercased()

        let documentExtensions = ["pdf", "doc", "docx", "txt", "rtf", "md", "pages"]
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "gif", "webp", "svg", "bmp"]
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv"]
        let audioExtensions = ["mp3", "wav", "m4a", "flac", "aac", "ogg"]
        let archiveExtensions = ["zip", "rar", "7z", "tar", "gz"]
        let codeExtensions = ["swift", "py", "java", "js", "html", "css", "json", "xml", "c", "cpp", "h", "m"]

        if documentExtensions.contains(lowercased) {
            return .document
        } else if imageExtensions.contains(lowercased) {
            return .image
        } else if videoExtensions.contains(lowercased) {
            return .video
        } else if audioExtensions.contains(lowercased) {
            return .audio
        } else if archiveExtensions.contains(lowercased) {
            return .archive
        } else if codeExtensions.contains(lowercased) {
            return .code
        } else {
            return .other
        }
    }
}

// MARK: - Sync Status

enum SyncStatus: String, Codable {
    case pending = "Pending"
    case syncing = "Syncing"
    case synced = "Synced"
    case failed = "Failed"
    case notAvailable = "Not Available"

    var icon: String {
        switch self {
        case .pending:
            return "clock.fill"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.icloud.fill"
        case .failed:
            return "exclamationmark.icloud.fill"
        case .notAvailable:
            return "xmark.icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .failed:
            return .red
        case .notAvailable:
            return .gray
        }
    }
}

// MARK: - Sort Option

enum FileSortOption: String, CaseIterable, Identifiable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case dateNewest = "Date (Newest)"
    case dateOldest = "Date (Oldest)"
    case sizeSmallest = "Size (Smallest)"
    case sizeLargest = "Size (Largest)"
    case category = "Category"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nameAscending, .nameDescending:
            return "textformat.abc"
        case .dateNewest, .dateOldest:
            return "calendar"
        case .sizeSmallest, .sizeLargest:
            return "chart.bar"
        case .category:
            return "folder"
        }
    }
}

// MARK: - View Mode

enum FileViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"

    var icon: String {
        switch self {
        case .grid:
            return "square.grid.2x2"
        case .list:
            return "list.bullet"
        }
    }
}

// MARK: - CloudKit Extensions

extension SharedFile {
    // Convert to CloudKit record
    func toCloudKitRecord() -> CKRecord {
        let recordID: CKRecord.ID
        if let existingID = cloudRecordID {
            recordID = CKRecord.ID(recordName: existingID)
        } else {
            recordID = CKRecord.ID(recordName: id.uuidString)
        }

        let record = CKRecord(recordType: "SharedFile", recordID: recordID)
        record["name"] = name as CKRecordValue
        record["fileExtension"] = fileExtension as CKRecordValue
        record["size"] = size as CKRecordValue
        record["mimeType"] = mimeType as CKRecordValue
        record["category"] = category.rawValue as CKRecordValue
        record["tags"] = tags as CKRecordValue
        record["uploadedBy"] = uploadedBy as CKRecordValue
        record["uploadedAt"] = uploadedAt as CKRecordValue
        record["modifiedAt"] = modifiedAt as CKRecordValue
        record["sharedWith"] = sharedWith as CKRecordValue
        record["isPublic"] = (isPublic ? 1 : 0) as CKRecordValue

        if let uploadedByUserId = uploadedByUserId {
            record["uploadedByUserId"] = uploadedByUserId as CKRecordValue
        }

        if let thumbnailData = thumbnailData {
            record["thumbnailData"] = thumbnailData as CKRecordValue
        }

        return record
    }

    // Create from CloudKit record
    static func fromCloudKitRecord(_ record: CKRecord) -> SharedFile? {
        guard
            let name = record["name"] as? String,
            let fileExtension = record["fileExtension"] as? String,
            let size = record["size"] as? Int64,
            let mimeType = record["mimeType"] as? String,
            let categoryString = record["category"] as? String,
            let category = FileCategory(rawValue: categoryString),
            let uploadedBy = record["uploadedBy"] as? String,
            let uploadedAt = record["uploadedAt"] as? Date,
            let modifiedAt = record["modifiedAt"] as? Date
        else {
            return nil
        }

        let tags = record["tags"] as? [String] ?? []
        let sharedWith = record["sharedWith"] as? [String] ?? []
        let isPublic = (record["isPublic"] as? Int ?? 0) == 1
        let uploadedByUserId = record["uploadedByUserId"] as? Int
        let thumbnailData = record["thumbnailData"] as? Data

        return SharedFile(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            name: name,
            fileExtension: fileExtension,
            size: size,
            mimeType: mimeType,
            category: category,
            tags: tags,
            uploadedBy: uploadedBy,
            uploadedByUserId: uploadedByUserId,
            uploadedAt: uploadedAt,
            modifiedAt: modifiedAt,
            sharedWith: sharedWith,
            isPublic: isPublic,
            cloudRecordID: record.recordID.recordName,
            thumbnailData: thumbnailData,
            isSynced: true,
            syncStatus: .synced
        )
    }
}

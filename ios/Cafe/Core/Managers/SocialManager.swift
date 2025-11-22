//
//  SocialManager.swift
//  Cafe
//
//  Manages social features, connections, and CloudKit sync
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
@Observable
class SocialManager {
    static let shared = SocialManager()

    // MARK: - Properties

    var currentProfile: SocialProfile?
    var connections: [Connection] = []
    var partnerProfiles: [String: SocialProfile] = [:] // profileId -> profile
    var sharedTasks: [SharedTask] = []
    var activities: [ActivityItem] = []
    var presenceStatuses: [String: SocialPresenceStatus] = [:] // profileId -> status

    var isCloudKitAvailable: Bool = false
    var isSyncing: Bool = false
    var syncError: String?

    private var isInitialized: Bool = false

    // CloudKit container (disabled - will use backend API)
    // Note: These are force-unwrapped but should never be accessed since isCloudKitAvailable = false
    private let container: CKContainer! = nil
    private let publicDatabase: CKDatabase! = nil
    private let privateDatabase: CKDatabase! = nil

    // Subscriptions for real-time updates
    private var subscriptionIDs: Set<String> = []

    // MARK: - Record Types

    private enum RecordType {
        static let profile = "SocialProfile"
        static let connection = "Connection"
        static let sharedTask = "SharedTask"
        static let activity = "ActivityItem"
        static let comment = "TaskComment"
        static let presence = "PresenceStatus"
        static let inviteCode = "InviteCode"
    }

    // MARK: - Initialization

    private init() {
        // CloudKit disabled - will use backend API for social features in the future
        // Containers are set to nil in property declarations
        self.isCloudKitAvailable = false
    }

    // Call this when you first use social features
    func initialize() async {
        guard !isInitialized else { return }
        isInitialized = true

        // CloudKit disabled - social features will use backend API instead
        print("ℹ️ Social features disabled - CloudKit not configured")
        // await checkCloudKitAvailability()
        // await setupSubscriptions()
    }

    // MARK: - CloudKit Availability

    func checkCloudKitAvailability() async {
        do {
            let status = try await container.accountStatus()
            isCloudKitAvailable = status == .available

            if !isCloudKitAvailable {
                syncError = "iCloud account not available"
                print("❌ iCloud not available: \(status)")
            } else {
                print("✅ iCloud is available")
            }
        } catch {
            isCloudKitAvailable = false
            syncError = "Failed to check iCloud status: \(error.localizedDescription)"
            print("❌ CloudKit error: \(error)")
        }
    }

    // MARK: - Profile Management

    func createProfile(username: String, displayName: String?, userId: Int) async throws -> SocialProfile {
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let profile = SocialProfile(
            userId: userId,
            username: username,
            displayName: displayName,
            isOnline: true
        )

        let record = CKRecord(recordType: RecordType.profile)
        record["userId"] = userId as CKRecordValue
        record["username"] = username as CKRecordValue
        if let displayName = displayName {
            record["displayName"] = displayName as CKRecordValue
        }
        record["isOnline"] = 1 as CKRecordValue
        record["createdAt"] = profile.createdAt as CKRecordValue
        record["updatedAt"] = profile.updatedAt as CKRecordValue

        let savedRecord = try await privateDatabase.save(record)

        var savedProfile = profile
        savedProfile = SocialProfile(
            id: savedRecord.recordID.recordName,
            userId: userId,
            username: username,
            displayName: displayName,
            isOnline: true
        )

        self.currentProfile = savedProfile
        print("✅ Created social profile: \(username)")

        return savedProfile
    }

    func updateProfile(_ profile: SocialProfile) async throws {
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let recordID = CKRecord.ID(recordName: profile.id)
        let record = try await privateDatabase.record(for: recordID)

        record["displayName"] = profile.displayName as CKRecordValue?
        record["statusMessage"] = profile.statusMessage as CKRecordValue?
        record["currentActivity"] = profile.currentActivity as CKRecordValue?
        record["isOnline"] = (profile.isOnline ? 1 : 0) as CKRecordValue
        record["updatedAt"] = Date() as CKRecordValue

        _ = try await privateDatabase.save(record)
        self.currentProfile = profile

        print("✅ Updated profile: \(profile.username)")
    }

    func fetchProfile(byUserId userId: Int) async throws -> SocialProfile? {
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let predicate = NSPredicate(format: "userId == %d", userId)
        let query = CKQuery(recordType: RecordType.profile, predicate: predicate)

        let results = try await privateDatabase.records(matching: query)
        guard let (_, result) = results.matchResults.first,
              let record = try? result.get() else {
            return nil
        }

        return profileFromRecord(record)
    }

    // MARK: - Connection Management

    func generateInviteCode() async throws -> InviteCode {
        guard let profile = currentProfile else {
            throw SocialError.noProfile
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let code = String(format: "%06d", Int.random(in: 100000...999999))
        let expiresAt = Date().addingTimeInterval(3600) // 1 hour

        let inviteCode = InviteCode(
            code: code,
            profileId: profile.id,
            expiresAt: expiresAt
        )

        let record = CKRecord(recordType: RecordType.inviteCode)
        record["code"] = code as CKRecordValue
        record["profileId"] = profile.id as CKRecordValue
        record["expiresAt"] = expiresAt as CKRecordValue
        record["createdAt"] = inviteCode.createdAt as CKRecordValue
        record["maxUses"] = inviteCode.maxUses as CKRecordValue
        record["currentUses"] = inviteCode.currentUses as CKRecordValue

        _ = try await publicDatabase.save(record)

        print("✅ Generated invite code: \(code)")
        return inviteCode
    }

    func connectWithInviteCode(_ code: String) async throws -> Connection {
        guard let profile = currentProfile else {
            throw SocialError.noProfile
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        // Find invite code
        let predicate = NSPredicate(format: "code == %@", code)
        let query = CKQuery(recordType: RecordType.inviteCode, predicate: predicate)

        let results = try await publicDatabase.records(matching: query)
        guard let (recordID, result) = results.matchResults.first,
              let inviteRecord = try? result.get(),
              let partnerProfileId = inviteRecord["profileId"] as? String,
              let expiresAt = inviteRecord["expiresAt"] as? Date,
              let currentUses = inviteRecord["currentUses"] as? Int,
              let maxUses = inviteRecord["maxUses"] as? Int else {
            throw SocialError.invalidInviteCode
        }

        // Validate invite code
        guard currentUses < maxUses && expiresAt > Date() else {
            throw SocialError.inviteCodeExpired
        }

        // Create connection
        let connection = Connection(
            profileId: profile.id,
            partnerProfileId: partnerProfileId,
            status: .accepted,
            inviteCode: code,
            acceptedAt: Date()
        )

        let connectionRecord = CKRecord(recordType: RecordType.connection)
        connectionRecord["profileId"] = profile.id as CKRecordValue
        connectionRecord["partnerProfileId"] = partnerProfileId as CKRecordValue
        connectionRecord["status"] = connection.status.rawValue as CKRecordValue
        connectionRecord["inviteCode"] = code as CKRecordValue
        connectionRecord["createdAt"] = connection.createdAt as CKRecordValue
        if let acceptedAt = connection.acceptedAt {
            connectionRecord["acceptedAt"] = acceptedAt as CKRecordValue
        }

        _ = try await publicDatabase.save(connectionRecord)

        // Update invite code usage
        inviteRecord["currentUses"] = (currentUses + 1) as CKRecordValue
        try await publicDatabase.save(inviteRecord)

        // Add to local connections
        connections.append(connection)

        // Fetch partner profile
        if let partnerProfile = try await fetchProfileById(partnerProfileId) {
            partnerProfiles[partnerProfileId] = partnerProfile
        }

        // Create activity
        let activity = ActivityItem(
            connectionId: connection.id,
            profileId: profile.id,
            activityType: .connectionAccepted,
            title: "Connected with \(partnerProfileId)"
        )
        try await createActivity(activity)

        print("✅ Connected with partner: \(partnerProfileId)")
        return connection
    }

    func fetchConnections() async throws {
        guard let profile = currentProfile, isCloudKitAvailable else {
            return
        }

        let predicate = NSPredicate(
            format: "profileId == %@ OR partnerProfileId == %@",
            profile.id, profile.id
        )
        let query = CKQuery(recordType: RecordType.connection, predicate: predicate)

        let results = try await publicDatabase.records(matching: query)

        var fetchedConnections: [Connection] = []
        for (_, result) in results.matchResults {
            if let record = try? result.get(),
               let connection = connectionFromRecord(record) {
                fetchedConnections.append(connection)

                // Fetch partner profile
                let partnerProfileId = connection.profileId == profile.id ?
                    connection.partnerProfileId : connection.profileId

                if let partnerProfile = try? await fetchProfileById(partnerProfileId) {
                    partnerProfiles[partnerProfileId] = partnerProfile
                }
            }
        }

        connections = fetchedConnections
        print("✅ Fetched \(connections.count) connections")
    }

    // MARK: - Shared Tasks

    func createSharedTask(_ task: Task, assignedTo: String? = nil) async throws -> SharedTask {
        guard let profile = currentProfile,
              let connection = connections.first else {
            throw SocialError.noConnection
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let sharedTask = SharedTask(
            taskId: task.id,
            title: task.title,
            description: task.description,
            completed: task.completed,
            dueDate: task.dueDate,
            assignedToProfileId: assignedTo,
            createdByProfileId: profile.id,
            connectionId: connection.id
        )

        let record = CKRecord(recordType: RecordType.sharedTask)
        record["taskId"] = task.id as CKRecordValue
        record["title"] = task.title as CKRecordValue
        record["description"] = task.description as CKRecordValue?
        record["completed"] = (task.completed ? 1 : 0) as CKRecordValue
        record["dueDate"] = task.dueDate as CKRecordValue?
        record["assignedToProfileId"] = assignedTo as CKRecordValue?
        record["createdByProfileId"] = profile.id as CKRecordValue
        record["connectionId"] = connection.id as CKRecordValue
        record["createdAt"] = sharedTask.createdAt as CKRecordValue
        record["updatedAt"] = sharedTask.updatedAt as CKRecordValue

        let savedRecord = try await publicDatabase.save(record)

        var savedTask = sharedTask
        savedTask = SharedTask(
            id: savedRecord.recordID.recordName,
            taskId: task.id,
            title: task.title,
            description: task.description,
            completed: task.completed,
            dueDate: task.dueDate,
            assignedToProfileId: assignedTo,
            createdByProfileId: profile.id,
            connectionId: connection.id
        )

        sharedTasks.append(savedTask)

        // Create activity
        let activity = ActivityItem(
            connectionId: connection.id,
            profileId: profile.id,
            activityType: .taskCreated,
            title: "Created task: \(task.title)",
            relatedTaskId: savedTask.id
        )
        try await createActivity(activity)

        print("✅ Created shared task: \(task.title)")
        return savedTask
    }

    func updateSharedTask(_ sharedTask: SharedTask) async throws {
        guard let profile = currentProfile else {
            throw SocialError.noProfile
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let recordID = CKRecord.ID(recordName: sharedTask.id)
        let record = try await publicDatabase.record(for: recordID)

        record["title"] = sharedTask.title as CKRecordValue
        record["description"] = sharedTask.description as CKRecordValue?
        record["completed"] = (sharedTask.completed ? 1 : 0) as CKRecordValue
        record["dueDate"] = sharedTask.dueDate as CKRecordValue?
        record["assignedToProfileId"] = sharedTask.assignedToProfileId as CKRecordValue?
        record["updatedAt"] = Date() as CKRecordValue

        if sharedTask.completed && sharedTask.completedAt == nil {
            record["completedAt"] = Date() as CKRecordValue
            record["completedByProfileId"] = profile.id as CKRecordValue
        }

        _ = try await publicDatabase.save(record)

        // Update local cache
        if let index = sharedTasks.firstIndex(where: { $0.id == sharedTask.id }) {
            sharedTasks[index] = sharedTask
        }

        // Create activity
        if sharedTask.completed {
            let activity = ActivityItem(
                connectionId: sharedTask.connectionId,
                profileId: profile.id,
                activityType: .taskCompleted,
                title: "Completed task: \(sharedTask.title)",
                relatedTaskId: sharedTask.id
            )
            try await createActivity(activity)
        }

        print("✅ Updated shared task: \(sharedTask.title)")
    }

    func fetchSharedTasks() async throws {
        guard let profile = currentProfile, isCloudKitAvailable else {
            return
        }

        // Fetch tasks for all connections
        var allTasks: [SharedTask] = []

        for connection in connections {
            let predicate = NSPredicate(format: "connectionId == %@", connection.id)
            let query = CKQuery(recordType: RecordType.sharedTask, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let results = try await publicDatabase.records(matching: query)

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let task = sharedTaskFromRecord(record) {
                    allTasks.append(task)
                }
            }
        }

        sharedTasks = allTasks
        print("✅ Fetched \(sharedTasks.count) shared tasks")
    }

    func deleteSharedTask(_ sharedTask: SharedTask) async throws {
        guard let profile = currentProfile else {
            throw SocialError.noProfile
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let recordID = CKRecord.ID(recordName: sharedTask.id)

        do {
            _ = try await publicDatabase.deleteRecord(withID: recordID)

            // Remove from local cache
            sharedTasks.removeAll { $0.id == sharedTask.id }

            // Create activity for deletion
            let activity = ActivityItem(
                connectionId: sharedTask.connectionId,
                profileId: profile.id,
                activityType: .taskCreated, // Using taskCreated as proxy; ideally add .taskDeleted
                title: "Deleted task: \(sharedTask.title)",
                relatedTaskId: sharedTask.id
            )
            try? await createActivity(activity)

            print("✅ Deleted shared task: \(sharedTask.title)")
        } catch let error as CKError {
            // Handle specific CloudKit errors
            switch error.code {
            case .unknownItem:
                // Record already deleted, remove from local cache
                sharedTasks.removeAll { $0.id == sharedTask.id }
                print("⚠️ Task already deleted from CloudKit")
            case .networkUnavailable, .networkFailure:
                throw SocialError.cloudKitUnavailable
            default:
                throw error
            }
        }
    }

    // MARK: - Activity Feed

    func createActivity(_ activity: ActivityItem) async throws {
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let record = CKRecord(recordType: RecordType.activity)
        record["connectionId"] = activity.connectionId as CKRecordValue
        record["profileId"] = activity.profileId as CKRecordValue
        record["activityType"] = activity.activityType.rawValue as CKRecordValue
        record["title"] = activity.title as CKRecordValue
        record["description"] = activity.description as CKRecordValue?
        record["relatedTaskId"] = activity.relatedTaskId as CKRecordValue?
        record["relatedEventId"] = activity.relatedEventId as CKRecordValue?
        record["timestamp"] = activity.timestamp as CKRecordValue

        _ = try await publicDatabase.save(record)
        activities.insert(activity, at: 0)

        print("✅ Created activity: \(activity.title)")
    }

    func fetchActivities(limit: Int = 50) async throws {
        guard let profile = currentProfile, isCloudKitAvailable else {
            return
        }

        var allActivities: [ActivityItem] = []

        for connection in connections {
            let predicate = NSPredicate(format: "connectionId == %@", connection.id)
            let query = CKQuery(recordType: RecordType.activity, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

            let results = try await publicDatabase.records(matching: query, desiredKeys: nil, resultsLimit: limit)

            for (_, result) in results.matchResults {
                if let record = try? result.get(),
                   let activity = activityFromRecord(record) {
                    allActivities.append(activity)
                }
            }
        }

        // Sort all activities by timestamp
        activities = allActivities.sorted { $0.timestamp > $1.timestamp }
        print("✅ Fetched \(activities.count) activities")
    }

    // MARK: - Presence & Status

    func updatePresence(isOnline: Bool, currentActivity: String? = nil, statusMessage: String? = nil) async throws {
        guard let profile = currentProfile else {
            throw SocialError.noProfile
        }
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let presence = SocialPresenceStatus(
            profileId: profile.id,
            isOnline: isOnline,
            currentActivity: currentActivity,
            statusMessage: statusMessage
        )

        // Update profile
        var updatedProfile = profile
        updatedProfile = SocialProfile(
            id: profile.id,
            userId: profile.userId,
            username: profile.username,
            displayName: profile.displayName,
            avatarURL: profile.avatarURL,
            statusMessage: statusMessage,
            currentActivity: currentActivity,
            isOnline: isOnline,
            lastSeen: Date(),
            createdAt: profile.createdAt,
            updatedAt: Date()
        )

        try await updateProfile(updatedProfile)
        presenceStatuses[profile.id] = presence

        print("✅ Updated presence: online=\(isOnline)")
    }

    func fetchPartnerPresence() async throws {
        guard isCloudKitAvailable else {
            return
        }

        for (partnerId, _) in partnerProfiles {
            if let partnerProfile = try? await fetchProfileById(partnerId) {
                partnerProfiles[partnerId] = partnerProfile
                let presence = SocialPresenceStatus(
                    profileId: partnerId,
                    isOnline: partnerProfile.isOnline,
                    currentActivity: partnerProfile.currentActivity,
                    statusMessage: partnerProfile.statusMessage
                )
                presenceStatuses[partnerId] = presence
            }
        }

        print("✅ Fetched presence for \(partnerProfiles.count) partners")
    }

    // MARK: - Subscriptions

    private func setupSubscriptions() async {
        guard isCloudKitAvailable else {
            return
        }

        do {
            // Subscribe to shared tasks
            let taskSubscription = CKQuerySubscription(
                recordType: RecordType.sharedTask,
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )

            let taskNotification = CKSubscription.NotificationInfo()
            taskNotification.shouldSendContentAvailable = true
            taskSubscription.notificationInfo = taskNotification

            _ = try await publicDatabase.save(taskSubscription)
            subscriptionIDs.insert(taskSubscription.subscriptionID)

            // Subscribe to activities
            let activitySubscription = CKQuerySubscription(
                recordType: RecordType.activity,
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation]
            )

            let activityNotification = CKSubscription.NotificationInfo()
            activityNotification.shouldSendContentAvailable = true
            activitySubscription.notificationInfo = activityNotification

            _ = try await publicDatabase.save(activitySubscription)
            subscriptionIDs.insert(activitySubscription.subscriptionID)

            print("✅ Setup CloudKit subscriptions")
        } catch {
            print("❌ Failed to setup subscriptions: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func fetchProfileById(_ profileId: String) async throws -> SocialProfile? {
        guard isCloudKitAvailable else {
            throw SocialError.cloudKitUnavailable
        }

        let recordID = CKRecord.ID(recordName: profileId)
        let record = try await privateDatabase.record(for: recordID)
        return profileFromRecord(record)
    }

    private func profileFromRecord(_ record: CKRecord) -> SocialProfile? {
        guard let userId = record["userId"] as? Int,
              let username = record["username"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let isOnline = (record["isOnline"] as? Int) == 1
        let updatedAt = record["updatedAt"] as? Date ?? Date()

        return SocialProfile(
            id: record.recordID.recordName,
            userId: userId,
            username: username,
            displayName: record["displayName"] as? String,
            avatarURL: record["avatarURL"] as? String,
            statusMessage: record["statusMessage"] as? String,
            currentActivity: record["currentActivity"] as? String,
            isOnline: isOnline,
            lastSeen: record["lastSeen"] as? Date,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func connectionFromRecord(_ record: CKRecord) -> Connection? {
        guard let profileId = record["profileId"] as? String,
              let partnerProfileId = record["partnerProfileId"] as? String,
              let statusString = record["status"] as? String,
              let status = Connection.ConnectionStatus(rawValue: statusString),
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        return Connection(
            id: record.recordID.recordName,
            profileId: profileId,
            partnerProfileId: partnerProfileId,
            status: status,
            inviteCode: record["inviteCode"] as? String,
            createdAt: createdAt,
            acceptedAt: record["acceptedAt"] as? Date
        )
    }

    private func sharedTaskFromRecord(_ record: CKRecord) -> SharedTask? {
        guard let taskId = record["taskId"] as? Int,
              let title = record["title"] as? String,
              let createdByProfileId = record["createdByProfileId"] as? String,
              let connectionId = record["connectionId"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }

        let completed = (record["completed"] as? Int) == 1
        let updatedAt = record["updatedAt"] as? Date ?? Date()

        return SharedTask(
            id: record.recordID.recordName,
            taskId: taskId,
            title: title,
            description: record["description"] as? String,
            completed: completed,
            dueDate: record["dueDate"] as? Date,
            assignedToProfileId: record["assignedToProfileId"] as? String,
            createdByProfileId: createdByProfileId,
            connectionId: connectionId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: record["completedAt"] as? Date,
            completedByProfileId: record["completedByProfileId"] as? String
        )
    }

    private func activityFromRecord(_ record: CKRecord) -> ActivityItem? {
        guard let connectionId = record["connectionId"] as? String,
              let profileId = record["profileId"] as? String,
              let activityTypeString = record["activityType"] as? String,
              let activityType = ActivityItem.ActivityType(rawValue: activityTypeString),
              let title = record["title"] as? String,
              let timestamp = record["timestamp"] as? Date else {
            return nil
        }

        return ActivityItem(
            id: record.recordID.recordName,
            connectionId: connectionId,
            profileId: profileId,
            activityType: activityType,
            title: title,
            description: record["description"] as? String,
            relatedTaskId: record["relatedTaskId"] as? String,
            relatedEventId: record["relatedEventId"] as? Int,
            timestamp: timestamp
        )
    }
}

// MARK: - Social Errors

enum SocialError: LocalizedError {
    case cloudKitUnavailable
    case noProfile
    case noConnection
    case invalidInviteCode
    case inviteCodeExpired

    var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .noProfile:
            return "No social profile found. Please create a profile first."
        case .noConnection:
            return "No connection found. Please connect with a partner first."
        case .invalidInviteCode:
            return "Invalid invite code. Please check and try again."
        case .inviteCodeExpired:
            return "This invite code has expired or reached its usage limit."
        }
    }
}

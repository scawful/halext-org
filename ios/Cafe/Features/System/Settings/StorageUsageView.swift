//
//  StorageUsageView.swift
//  Cafe
//
//  View storage usage breakdown
//

import SwiftUI

struct StorageUsageView: View {
    @State private var settingsManager = SettingsManager.shared
    @State private var storageCategories: [StorageCategory] = []

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Total storage usage
                    VStack(spacing: 8) {
                        Text("Total Storage")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(settingsManager.storageUsageString)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.blue)
                    }

                    // Storage bar
                    StorageBar(categories: storageCategories)
                }
                .padding(.vertical, 12)
            }

            Section {
                ForEach(storageCategories) { category in
                    StorageCategoryRow(category: category)
                }
            } header: {
                Text("Storage Breakdown")
            }

            Section {
                Button(action: clearCache) {
                    HStack {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                        Text("Clear Cache")
                        Spacer()
                        Text(settingsManager.cacheSize)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: clearTempFiles) {
                    HStack {
                        Image(systemName: "doc.fill.badge.minus")
                            .foregroundColor(.orange)
                        Text("Clear Temporary Files")
                    }
                }

                Button(action: optimizeStorage) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.purple)
                        Text("Optimize Storage")
                    }
                }
            } header: {
                Text("Storage Management")
            }
        }
        .navigationTitle("Storage Usage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadStorageData()
        }
    }

    private func loadStorageData() {
        storageCategories = [
            StorageCategory(
                id: "tasks",
                name: "Tasks & Events",
                icon: "checkmark.circle.fill",
                color: .blue,
                size: 15_000_000,
                percentage: 40
            ),
            StorageCategory(
                id: "messages",
                name: "Messages",
                icon: "message.fill",
                color: .green,
                size: 8_000_000,
                percentage: 25
            ),
            StorageCategory(
                id: "files",
                name: "Files & Attachments",
                icon: "doc.fill",
                color: .orange,
                size: 6_000_000,
                percentage: 20
            ),
            StorageCategory(
                id: "cache",
                name: "Cache",
                icon: "folder.fill",
                color: .gray,
                size: 3_500_000,
                percentage: 10
            ),
            StorageCategory(
                id: "other",
                name: "Other",
                icon: "ellipsis.circle.fill",
                color: .purple,
                size: 2_000_000,
                percentage: 5
            )
        ]
    }

    private func clearCache() {
        _Concurrency.Task {
            await settingsManager.clearCache()
        }
    }

    private func clearTempFiles() {
        // Clear temporary files
    }

    private func optimizeStorage() {
        // Optimize storage
    }
}

struct StorageBar: View {
    let categories: [StorageCategory]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(categories) { category in
                    Rectangle()
                        .fill(category.color)
                        .frame(width: geometry.size.width * CGFloat(category.percentage) / 100)
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }
}

struct StorageCategoryRow: View {
    let category: StorageCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.title3)
                .foregroundColor(category.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.body)

                Text("\(category.percentage)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: Int64(category.size), countStyle: .file))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StorageCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let size: Int
    let percentage: Double
}

#Preview {
    NavigationStack {
        StorageUsageView()
    }
}

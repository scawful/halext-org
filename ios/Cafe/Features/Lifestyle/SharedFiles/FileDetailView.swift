//
//  FileDetailView.swift
//  Cafe
//
//  Detailed view for file preview and management
//

import SwiftUI
import QuickLook
import UniformTypeIdentifiers

struct FileDetailView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) var appState
    @Environment(ThemeManager.self) var themeManager

    let file: SharedFile
    let viewModel: SharedFilesViewModel

    @State private var fileData: Data?
    @State private var isLoadingData = false
    @State private var showingShareSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingQuickLook = false
    @State private var showingShareUsers = false
    @State private var shareUsers: [String] = []
    @State private var tempFileURL: URL?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview section
                    filePreviewSection

                    // Info section
                    fileInfoSection

                    // Actions section
                    actionsSection

                    // Sharing section
                    sharingSection

                    // Metadata section
                    metadataSection
                }
                .padding()
            }
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.backgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { downloadAndShare() }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        if file.canPreview {
                            Button(action: { showPreview() }) {
                                Label("Quick Look", systemImage: "eye")
                            }
                        }

                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadFileData()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = tempFileURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingQuickLook) {
                if let url = tempFileURL {
                    QuickLookView(url: url)
                }
            }
            .sheet(isPresented: $showingShareUsers) {
                ShareUsersView(
                    currentUsers: file.sharedWith,
                    onShare: { users in
                        _Concurrency.Task {
                            await viewModel.shareFile(file, with: users)
                        }
                    }
                )
            }
            .confirmationDialog("Delete File", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    _Concurrency.Task {
                        await viewModel.deleteFile(file)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(file.fileName)'? This action cannot be undone.")
            }
        }
    }

    // MARK: - Preview Section

    private var filePreviewSection: some View {
        VStack(spacing: 16) {
            if let thumbnailData = file.thumbnailData,
               let image = UIImage(data: thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(file.color.opacity(0.15))
                        .frame(height: 200)

                    Image(systemName: file.icon)
                        .font(.system(size: 64))
                        .foregroundColor(file.color)
                }
            }

            if file.canPreview && fileData != nil {
                Button(action: { showPreview() }) {
                    Label("Quick Look", systemImage: "eye.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Info Section

    private var fileInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)
                .foregroundColor(themeManager.textColor)

            VStack(spacing: 0) {
                InfoRow(label: "Name", value: file.fileName)
                Divider()
                InfoRow(label: "Type", value: file.category.rawValue)
                Divider()
                InfoRow(label: "Size", value: file.formattedSize)
                Divider()
                InfoRow(label: "Uploaded", value: file.uploadedAt.formatted(date: .long, time: .shortened))
                Divider()
                InfoRow(label: "Uploaded By", value: file.uploadedBy)

                if file.modifiedAt != file.uploadedAt {
                    Divider()
                    InfoRow(label: "Modified", value: file.modifiedAt.formatted(date: .long, time: .shortened))
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundColor(themeManager.textColor)

            VStack(spacing: 12) {
                ActionButton(
                    icon: "square.and.arrow.down",
                    title: "Download",
                    subtitle: "Save to device",
                    color: .blue
                ) {
                    downloadAndShare()
                }

                ActionButton(
                    icon: "square.and.arrow.up",
                    title: "Export to Files",
                    subtitle: "Save to Files app",
                    color: .green
                ) {
                    exportToFiles()
                }

                if isLoadingData {
                    HStack {
                        ProgressView()
                            .padding(.leading)
                        Text("Loading file...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(themeManager.cardBackgroundColor)
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Sharing Section

    private var sharingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sharing")
                    .font(.headline)
                    .foregroundColor(themeManager.textColor)

                Spacer()

                Button(action: { showingShareUsers = true }) {
                    Label("Manage", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(file.isPublic ? .green : .gray)
                    Text("Public Access")
                        .foregroundColor(themeManager.textColor)
                    Spacer()
                    Text(file.isPublic ? "Enabled" : "Disabled")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .padding()

                if !file.sharedWith.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shared with \(file.sharedWith.count) \(file.sharedWith.count == 1 ? "person" : "people")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ForEach(file.sharedWith, id: \.self) { username in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(username)
                                    .foregroundColor(themeManager.textColor)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(themeManager.textColor)

            VStack(spacing: 0) {
                HStack {
                    Label("Sync Status", systemImage: file.syncStatus.icon)
                        .foregroundColor(themeManager.textColor)
                    Spacer()
                    Text(file.syncStatus.rawValue)
                        .foregroundColor(file.syncStatus.color)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding()

                if !file.tags.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        FlowLayout(spacing: 8) {
                            ForEach(file.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Methods

    private func loadFileData() async {
        isLoadingData = true
        fileData = await viewModel.downloadFile(file)
        isLoadingData = false
    }

    private func downloadAndShare() {
        guard let data = fileData else {
            _Concurrency.Task {
                await loadFileData()
                if fileData != nil {
                    downloadAndShare()
                }
            }
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.fileName)

        do {
            try data.write(to: tempURL)
            tempFileURL = tempURL
            showingShareSheet = true
        } catch {
            print("Error saving temp file: \(error)")
        }
    }

    private func showPreview() {
        guard let data = fileData else {
            _Concurrency.Task {
                await loadFileData()
                if fileData != nil {
                    showPreview()
                }
            }
            return
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.fileName)

        do {
            try data.write(to: tempURL)
            tempFileURL = tempURL
            showingQuickLook = true
        } catch {
            print("Error saving temp file for preview: \(error)")
        }
    }

    private func exportToFiles() {
        downloadAndShare()
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @Environment(ThemeManager.self) var themeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textColor)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(themeManager.cardBackgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Users View

struct ShareUsersView: View {
    @Environment(\.dismiss) var dismiss
    @State var currentUsers: [String]
    let onShare: ([String]) -> Void

    @State private var newUsername = ""
    @State private var users: [String]

    init(currentUsers: [String], onShare: @escaping ([String]) -> Void) {
        self.currentUsers = currentUsers
        self.onShare = onShare
        _users = State(initialValue: currentUsers)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Add User") {
                    HStack {
                        TextField("Username", text: $newUsername)
                            .autocapitalization(.none)
                        Button("Add") {
                            if !newUsername.isEmpty && !users.contains(newUsername) {
                                users.append(newUsername)
                                newUsername = ""
                            }
                        }
                        .disabled(newUsername.isEmpty)
                    }
                }

                if !users.isEmpty {
                    Section("Shared With") {
                        ForEach(users, id: \.self) { username in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(username)
                                Spacer()
                                Button(action: {
                                    users.removeAll { $0 == username }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share File")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onShare(users)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quick Look View

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return url as QLPreviewItem
        }
    }
}

#Preview {
    FileDetailView(
        file: SharedFile(
            name: "Sample Document",
            fileExtension: "pdf",
            size: 1024000,
            mimeType: "application/pdf",
            uploadedBy: "John Doe"
        ),
        viewModel: SharedFilesViewModel()
    )
    .environment(AppState())
    .environment(ThemeManager.shared)
}

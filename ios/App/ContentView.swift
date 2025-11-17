import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            if let token = appState.token, !token.isEmpty {
                WorkspaceView()
            } else {
                VStack(spacing: 16) {
                    Text("Halext Org")
                        .font(.largeTitle).bold()
                    TextField("Access Code", text: $appState.accessCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                    Button(action: {
                        Task {
                            await appState.login(username: username, password: password)
                        }
                    }) {
                        if appState.isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    if let error = appState.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
    }
}

struct WorkspaceView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            Section("Tasks") {
                ForEach(appState.tasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title).font(.headline)
                        if let description = task.description, !description.isEmpty {
                            Text(description).font(.subheadline)
                        }
                        if !task.labels.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(task.labels) { label in
                                        Text(label.name)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Section("Events") {
                ForEach(appState.events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title).font(.headline)
                        Text("Starts \(event.start_time.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
                        if let location = event.location {
                            Text(location).font(.footnote)
                        }
                    }
                }
            }

            Section("Layout Presets") {
                if appState.layoutPresets.isEmpty {
                    Text("No presets available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appState.layoutPresets) { preset in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(preset.name).font(.headline)
                                if preset.is_system {
                                    Text("System")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(Capsule())
                                } else {
                                    Text("Custom")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            if let description = preset.description, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(preset.layout.count) column\(preset.layout.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Workspace")
        .toolbar {
            Button("Refresh") {
                Task { await appState.refreshWorkspace() }
            }
        }
    }
}

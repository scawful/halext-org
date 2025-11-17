import SwiftUI

@main
struct HalextApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

final class AppState: ObservableObject {
    @Published var accessCode: String = ""
    @Published var token: String?
    @Published var tasks: [TaskSummary] = []
    @Published var events: [EventSummary] = []
    @Published var layoutPresets: [LayoutPreset] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let api = HalextAPI()

    func login(username: String, password: String) async {
        guard !accessCode.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "Access code required." }
            return
        }
        isLoading = true
        do {
            let token = try await api.login(username: username, password: password, accessCode: accessCode)
            DispatchQueue.main.async {
                self.token = token
                self.errorMessage = nil
            }
            await refreshWorkspace()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    func refreshWorkspace() async {
        guard let token else { return }
        do {
            async let tasksResponse = api.fetchTasks(token: token, accessCode: accessCode)
            async let eventsResponse = api.fetchEvents(token: token, accessCode: accessCode)
            async let presetsResponse = api.fetchLayoutPresets(token: token, accessCode: accessCode)
            let (tasks, events, presets) = try await (tasksResponse, eventsResponse, presetsResponse)
            DispatchQueue.main.async {
                self.tasks = tasks
                self.events = events
                self.layoutPresets = presets
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

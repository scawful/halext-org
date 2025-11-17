## Halext iOS Plan

This folder is a starting point for the native client. The goal is to share as much logic as possible (models/API client) while building SwiftUI screens for:

1. **Auth** – capture access code + username/password, request `/token`, persist bearer token in the keychain.
2. **Dashboard** – list tasks/events similar to the web layout presets.
3. **Chats** – list/group conversations, send messages to `/conversations/{id}/messages`.

### Project Structure

```
ios/
  App/
    HalextApp.swift        # AppState + entry point
    ContentView.swift      # Temporary placeholder UI
  Models/
    Task.swift
    Event.swift
    Page.swift
  Networking/
    HalextAPI.swift        # Async client wrapping the FastAPI endpoints
```

Open Xcode, create a new SwiftUI iOS App target called “Halext”, and drop these files into it (or run `xcodebuild -create-xcframework` once a Package manifest is added).

### API Client Expectations

- `ACCESS_CODE` must be stored securely (e.g., in the Keychain or Settings bundle) and sent as `X-Halext-Code` header for `/token` and `/users/`.
- After login, the bearer token is saved (Keychain or `AppStorage`) and attached to every request.
- `HalextAPI` in `Networking/` already exposes `login`, `fetchTasks`, and `fetchLayoutPresets` examples—extend it as needed.

### Next Steps

1. Wire `ContentView` to call `HalextAPI.login` and show basic task/event lists using `TaskListView`/`EventListView`.
2. Add a `LayoutPresetView` that mirrors the Apple widget-like presets from the web.
3. Create modules for Conversations and AI chat once the basics are in place.

Feel free to restructure into multiple Swift packages (Core, Features, etc.) once the foundation is stable.

# Quick Debug Checklist for More Page & AI Models

## Before You Start Coding

### 1. Test on Actual Device
- [ ] Install IPA via SideStore (no AltServer needed once configured)
- [ ] Open app, go to More tab
- [ ] Tap each feature card, document what happens:
  - Do buttons respond to touch? (flash/highlight?)
  - Do they navigate anywhere?
  - Any error messages in UI?
- [ ] Go to Settings → AI Settings → AI Model
- [ ] Document what happens:
  - Does picker appear?
  - Any loading indicator?
  - Any models shown?
  - Any errors displayed?

### 2. Check Xcode Console
- [ ] Connect device via USB
- [ ] Open Xcode → Window → Devices and Simulators
- [ ] Select device → Open Console
- [ ] Run app, trigger the broken features
- [ ] Look for errors/warnings

### 3. Test in Simulator
- [ ] Open Xcode, select iOS Simulator
- [ ] Run the app (⌘R)
- [ ] Test More page navigation
- [ ] Test AI model selector
- [ ] Does it work in simulator? If yes → device-specific issue

## More Page Quick Fixes to Try

### Fix 1: Check NavigationStack in RootView
```bash
grep -A 5 "case .more:" ios/Cafe/App/RootView.swift
```

Look for:
```swift
case .more:
    MoreView()  // ← Should this be wrapped in NavigationStack?
```

If not wrapped, try:
```swift
case .more:
    NavigationStack {
        MoreView()
    }
```

But check if MoreView already has NavigationStack (it does) - might need to remove one.

### Fix 2: Use Simple NavigationLink Pattern
In `ios/Cafe/Features/More/MoreView.swift`, replace value-based navigation:

```swift
// FROM (around line 320):
NavigationLink(value: feature.destination) {
    // card content
}

// TO:
NavigationLink(destination: destinationView(for: feature.destination)) {
    // card content
}
.buttonStyle(.plain)
```

And remove the `.navigationDestination()` modifier since we're using direct navigation.

### Fix 3: Add Debug Prints
```swift
NavigationLink(value: feature.destination) {
    // content
}
.simultaneousGesture(TapGesture().onEnded {
    print("🔍 TAPPED: \(feature.destination)")
})

// And in navigationDestination:
.navigationDestination(for: FeatureDestination.self) { destination in
    print("🔍 NAVIGATING TO: \(destination)")
    return destinationView(for: destination)
}
```

Rebuild, run, tap, check console.

## AI Model Selector Quick Fixes to Try

### Fix 1: Check if Models Endpoint Works
```bash
ssh halext-server
curl -H "Authorization: Bearer $(cat /tmp/test-token.txt)" http://localhost:8000/ai/models
```

Should return JSON with models. If empty or error → backend issue.

### Fix 2: Add Debug Logging
In `ios/Cafe/Features/Settings/AIModelPickerView.swift`:

```swift
.task {
    print("🔍 AIModelPickerView appeared, loading models...")
    do {
        let models = try await loadModels()
        print("🔍 Loaded \(models.count) models")
    } catch {
        print("❌ Error loading models: \(error)")
    }
}
```

### Fix 3: Check API Keys Are Set
```bash
ssh halext-server
cd /srv/halext.org/halext-org/backend
cat .env | grep -E "(OPENAI|GEMINI)_API_KEY"
```

Should show:
```
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

If not set, backend can't fetch models from providers.

### Fix 4: Test with Hardcoded Models
Temporarily hardcode models to verify UI works:

```swift
@State private var models: [AIModel] = [
    AIModel(id: "test-1", name: "Test Model", description: "Hardcoded test", 
            contextWindow: 128000, costPerMillion: 0.15, tier: "lightweight"),
    AIModel(id: "test-2", name: "Another Model", description: "Second test",
            contextWindow: 1000000, costPerMillion: 1.25, tier: "premium")
]
```

If hardcoded models display → API/loading issue
If hardcoded models DON'T display → UI issue

## Emergency Fallback

If nothing works after trying above:

### For More Page:
Create a simple, working navigation pattern:
```swift
List {
    NavigationLink("Tasks", destination: TaskListView())
    NavigationLink("Calendar", destination: CalendarView())
    NavigationLink("AI Chat", destination: ChatView())
    // ... etc
}
```

Test if THIS works. If yes → fancy FeatureCard pattern is the problem.

### For AI Models:
Simplify the picker to just show available models without fancy UI:
```swift
List {
    ForEach(["gpt-4o-mini", "gemini-1.5-flash"], id: \.self) { model in
        Button(model) {
            selectedModel = model
        }
    }
}
```

Test if THIS works. If yes → complex loading/display logic is the problem.

## Stop and Report If:

- [ ] Features work in Simulator but not on Device
- [ ] Console shows auth errors
- [ ] Backend endpoints return errors
- [ ] No amount of debugging shows WHERE the code is failing

In these cases, deeper investigation needed.

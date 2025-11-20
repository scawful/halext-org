# Critical Fix Plan: More Page Navigation & AI Model Selector

## Status: STILL BROKEN (as of Nov 20, 2025)

Despite multiple fix attempts, these features remain non-functional on device:
1. ✅ Dashboard quick actions - NOW WORKING
2. ❌ More page navigation - STILL BROKEN
3. ❌ AI model selector - STILL BROKEN

---

## Problem 1: More Page Navigation Still Doesn't Work

### User Report
"The more page is still useless. It doesnt work."

### What We've Tried
1. Added `Hashable` conformance to `FeatureDestination` enum
2. Fixed `navigationDestination` placement in NavigationStack
3. Moved Settings to quick access gear icon
4. Verified all destination views exist

### Why It Might Still Be Broken

#### Theory 1: NavigationStack Context Issue
The More tab might not have a NavigationStack wrapping it in RootView. Check:
```swift
// File: ios/Cafe/App/RootView.swift
// Around line 70 in tabContent(for:)

case .more:
    MoreView()  // ← Does this need to be wrapped in NavigationStack?
```

**Test:** Wrap MoreView in NavigationStack at the RootView level:
```swift
case .more:
    NavigationStack {
        MoreView()
    }
```

But check if MoreView already has NavigationStack internally (it does at line 16) - this could cause double-wrapping.

#### Theory 2: TabView Interference
SwiftUI TabView might be interfering with NavigationStack. Each tab needs its own navigation hierarchy.

**Test:** Check if other tabs (Tasks, Calendar) have NavigationStack and how they're structured in RootView.

#### Theory 3: Build vs Runtime Issue
The fix was applied but the IPA might not have the latest code compiled in correctly.

**Test:**
1. Clean build folder: `rm -rf ios/build/DerivedData`
2. Rebuild from scratch
3. Verify MoreView.swift line 303 shows `enum FeatureDestination: Hashable` in the compiled app

#### Theory 4: Simulator vs Device Behavior
Navigation might work in simulator but fail on device due to iOS version differences.

**Test:** Build and run in Xcode Simulator, tap More page cards, verify they navigate.

#### Theory 5: The Fix Is Wrong
The `navigationDestination(for: FeatureDestination.self)` handler might be:
- In the wrong place in the view hierarchy
- Not attached to the correct NavigationStack
- Being overridden by another handler

**Test:** Move `.navigationDestination()` from inside ScrollView to directly on NavigationStack:
```swift
NavigationStack {
    ScrollView {
        // content
    }
    .navigationTitle("More")
}
.navigationDestination(for: FeatureDestination.self) { destination in
    destinationView(for: destination)
}
```

### Investigation Steps for Future Agent

1. **Read Current Implementation:**
   ```
   ios/Cafe/App/RootView.swift - Check how More tab is set up
   ios/Cafe/Features/More/MoreView.swift - Check NavigationStack structure
   ```

2. **Compare with Working Navigation:**
   ```
   ios/Cafe/Features/Dashboard/DashboardView.swift - Uses NavigationLink(destination:)
   ios/Cafe/Features/Tasks/TaskListView.swift - Check their navigation
   ```

3. **Try Alternative Pattern:**
   Replace value-based NavigationLink with destination-based:
   ```swift
   // Instead of:
   NavigationLink(value: feature.destination) { }

   // Use:
   NavigationLink(destination: destinationView(for: feature.destination)) { }
   ```

4. **Add Debug Logging:**
   ```swift
   NavigationLink(value: feature.destination) {
       // content
   }
   .onTapGesture {
       print("🔍 Tapped feature: \(feature.destination)")
   }

   .navigationDestination(for: FeatureDestination.self) { destination in
       print("🔍 Navigating to: \(destination)")
       return destinationView(for: destination)
   }
   ```

5. **Check Console Output:**
   Connect device, run app, tap More page cards, check Xcode console for:
   - Any navigation errors
   - Whether tap gestures are registering
   - Whether navigationDestination is being called

---

## Problem 2: AI Model Selector Doesn't Work

### User Report
"Loading models doesnt work yet either. Select model and load available models does nothing."

### What We've Implemented
1. Backend endpoints: `GET /admin/ai/models/openai` and `/admin/ai/models/gemini`
2. Model metadata system with costs, context windows
3. Enhanced iOS AIModelPickerView with rich display
4. Backend deployed and running

### Why It Might Not Be Working

#### Theory 1: API Not Being Called
The iOS app might not be making the API request when the picker appears.

**Check in:** `ios/Cafe/Features/Settings/AIModelPickerView.swift`
```swift
.task {
    await loadModels()
}
```

Does `loadModels()` exist? Is it being called?

#### Theory 2: Authentication Issue
The models endpoint requires authentication. The app might not be sending:
- JWT token in Authorization header
- Valid session token

**Test:** Check APIClient to verify it adds auth headers:
```swift
// ios/Cafe/Core/API/APIClient.swift
func request<T: Decodable>(endpoint: String, method: String) async throws -> T {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    // ...
}
```

#### Theory 3: Endpoint Path Wrong
The iOS app might be calling the wrong endpoint.

**Check:**
- iOS code: What endpoint is it calling? `/ai/models`? `/admin/ai/models/openai`?
- Backend: What endpoints actually exist and work?

**Test with curl:**
```bash
# From server:
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/ai/models
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8000/admin/ai/models/openai
```

#### Theory 4: No API Keys Configured
The backend might return empty results if no OpenAI/Gemini keys are set.

**Check backend .env:**
```bash
ssh halext-server
cat /srv/halext.org/halext-org/backend/.env | grep -E "(OPENAI|GEMINI)"
```

Should see:
```
AI_PROVIDER=openai  # or gemini
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

#### Theory 5: UI Not Refreshing
The API call might succeed but the UI doesn't update with results.

**Check:** AIModelPickerView should use `@State` or `@Published` to trigger UI updates:
```swift
@State private var models: [AIModel] = []

func loadModels() async {
    do {
        let fetchedModels = try await APIClient.shared.getModels()
        await MainActor.run {
            self.models = fetchedModels  // ← Must update on MainActor
        }
    } catch {
        print("Error loading models: \(error)")
    }
}
```

#### Theory 6: Wrong View Being Used
There might be multiple model picker views, and we're using the wrong one.

**Search for:**
```bash
find ios/Cafe -name "*ModelPicker*" -o -name "*Model*View.swift"
```

Check if there's:
- AIModelPickerView
- AIModelSelector
- ModelSelectionView
- etc.

Make sure we're editing and using the RIGHT one.

### Investigation Steps for Future Agent

1. **Trace the User Flow:**
   ```
   Settings → AI Settings → Tap "AI Model" → AIModelPickerView appears
   ```
   Find exactly which view is shown and which code runs.

2. **Check API Call:**
   Add logging to APIClient:
   ```swift
   func getModels() async throws -> [AIModel] {
       print("🔍 Fetching models from: \(endpoint)")
       let result = try await request(...)
       print("🔍 Received \(result.count) models")
       return result
   }
   ```

3. **Test Backend Directly:**
   ```bash
   ssh halext-server
   curl -X GET http://localhost:8000/ai/models | jq
   ```
   Verify it returns models.

4. **Check for Errors:**
   Wrap everything in proper error handling:
   ```swift
   .task {
       do {
           await loadModels()
       } catch {
           print("❌ Failed to load models: \(error)")
           self.errorMessage = error.localizedDescription
       }
   }
   ```

5. **Simplify and Test:**
   Create a minimal test view that JUST calls the API:
   ```swift
   struct TestModelsView: View {
       @State private var models: [AIModel] = []

       var body: some View {
           List(models, id: \.id) { model in
               Text(model.name)
           }
           .task {
               do {
                   models = try await APIClient.shared.getModels()
                   print("✅ Loaded \(models.count) models")
               } catch {
                   print("❌ Error: \(error)")
               }
           }
       }
   }
   ```
   If this works, the problem is in AIModelPickerView UI logic.

---

## Recommended Approach for Future Agent

### Phase 1: Investigation (Don't Code Yet)

1. **Test on Device:**
   - Install current IPA on physical device
   - Test More page - document exact behavior (buttons visible? clickable? any animation?)
   - Test AI model selector - document exact behavior (view appears? loading indicator? errors?)
   - Check Xcode console for any error messages

2. **Test in Simulator:**
   - Open Xcode, run app in Simulator
   - Same tests as above
   - Compare behavior: Does it work in simulator but not device?

3. **Read All Related Code:**
   ```
   More Page:
   - ios/Cafe/App/RootView.swift
   - ios/Cafe/Features/More/MoreView.swift
   - ios/Cafe/Features/Tasks/TaskListView.swift (for comparison)

   AI Models:
   - ios/Cafe/Features/Settings/AISettingsView.swift
   - ios/Cafe/Features/Settings/AIModelPickerView.swift
   - ios/Cafe/Core/API/APIClient+AI.swift
   - backend/app/admin_routes.py (model endpoints)
   ```

4. **Create Hypotheses:**
   - List 3-5 specific theories for WHY each feature doesn't work
   - Each theory should be testable

### Phase 2: Targeted Fixes

1. **More Page:**
   - If navigation pattern is wrong → Switch to destination-based NavigationLink
   - If NavigationStack is missing → Add it in RootView
   - If double-wrapped → Remove one NavigationStack
   - Test after EACH change

2. **AI Model Selector:**
   - If API not called → Add .task { await loadModels() }
   - If auth missing → Fix APIClient headers
   - If endpoint wrong → Update to correct endpoint
   - If keys missing → Document how to set them
   - Test after EACH change

### Phase 3: Verification

1. **Build and Test:**
   ```bash
   cd ios
   ./build-for-altstore.sh
   ```

2. **Install on Device:**
   - Use AirDrop to send IPA
   - Install via AltStore
   - Test both features

3. **Document Results:**
   - What was broken
   - What the fix was
   - How to verify it works
   - Screenshots if helpful

---

## Files to Focus On

### More Page Navigation:
1. `ios/Cafe/App/RootView.swift` - Tab setup
2. `ios/Cafe/Features/More/MoreView.swift` - Navigation implementation
3. `ios/Cafe/Features/Dashboard/DashboardView.swift` - Working navigation reference

### AI Model Selector:
1. `ios/Cafe/Features/Settings/AISettingsView.swift` - Entry point
2. `ios/Cafe/Features/Settings/AIModelPickerView.swift` - The picker UI
3. `ios/Cafe/Core/API/APIClient+AI.swift` - API calls
4. `backend/app/admin_routes.py` - Backend endpoints
5. `backend/.env` - API key configuration

---

## Success Criteria

### More Page:
- [ ] Tap any card in More page
- [ ] App navigates to the destination view with slide animation
- [ ] Back button appears in top-left
- [ ] Tapping back returns to More page
- [ ] All 9 destinations work (Tasks, Calendar, Chat, Messages, Finance, Templates, Smart Lists, Settings, Social)

### AI Model Selector:
- [ ] Navigate to Settings → AI Settings → AI Model
- [ ] Picker appears with loading indicator
- [ ] List of models loads (OpenAI and/or Gemini)
- [ ] Each model shows name, description, tier badge, cost, context window
- [ ] Can select a model
- [ ] Selected model is saved
- [ ] Model is used for subsequent AI requests

---

## Priority

**HIGH PRIORITY - BLOCKING CHRIS FROM USING THE APP**

Both features are core to the user experience:
- More page is the main navigation hub for discovering features
- AI model selector is needed to use AI features (recipes, tasks, chat)

Without these working, the app is significantly degraded.

---

## Next Steps

When you're ready to fix these:

1. Spawn an iOS investigation agent with this plan
2. Have them test on device first, document exact behavior
3. Create targeted fixes based on findings
4. Rebuild and test again
5. Repeat until both features work

Don't try to fix without understanding WHY they're broken first.

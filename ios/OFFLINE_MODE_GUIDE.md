# Offline Mode Guide

Complete guide to testing and using offline functionality in the Cafe iOS app.

---

## ⚠️ First: Add Files to Xcode Project

**The offline support files are created but NOT yet in the Xcode project.**

### Files to Add:

1. **Core/Storage/** (create group folder)
   - `SwiftDataModels.swift`
   - `StorageManager.swift`

2. **Core/Network/** (create group folder)
   - `NetworkMonitor.swift`

3. **Core/Sync/** (create group folder)
   - `SyncManager.swift`

### How to Add:

1. Open Xcode: `open Cafe.xcodeproj`
2. Right-click `Core` folder → "New Group" → name it "Storage"
3. Right-click "Storage" → "Add Files to Cafe..."
4. Navigate to `Cafe/Core/Storage/`
5. Select both `.swift` files
6. ✅ Uncheck "Copy items if needed"
7. ✅ Check "Add to targets: Cafe"
8. Click "Add"
9. Repeat for Network and Sync folders

---

## 🧪 How to Test Offline Mode

### Method 1: Simulator Network Condition (Recommended)

**During Development:**

1. **Build and Run** (Cmd+R)
2. **Enable Airplane Mode** in iOS Simulator:
   ```
   Settings App → Airplane Mode → ON
   ```
   Or use: `Features → Toggle Airplane Mode` in simulator menu

3. **Test offline functionality:**
   - Create tasks → they save locally
   - Toggle task completion → works offline
   - Delete tasks → queued for sync
   - See "Offline" indicator in navigation bar

4. **Restore Connection:**
   - Turn Airplane Mode OFF
   - Watch automatic sync happen
   - See "Syncing..." indicator
   - Data syncs to server

### Method 2: Mac Network Conditioner (Advanced)

**For more realistic testing:**

1. Install Network Link Conditioner:
   - Xcode → Settings → Downloads → Components
   - Install "Additional Tools"
   - Open `Hardware/Network Link Conditioner.prefPane`

2. Add to System Settings:
   - Open the `.prefPane` file
   - Drag to System Settings

3. Use profiles:
   - **100% Loss** = Complete offline
   - **Very Bad Network** = Flaky connection
   - **Edge** = Slow connection

### Method 3: Disconnect Backend Server

**Test with no API available:**

1. Stop your backend server
2. App continues working with cached data
3. All changes queue for sync
4. Start server again to see auto-sync

---

## 📱 How to Use Offline Mode (User Perspective)

### Normal Usage

**Just use the app normally!** Offline mode is automatic:

1. **When Online:**
   - Everything syncs immediately
   - Changes save to server
   - You see "Synced X ago" in navigation

2. **When Offline:**
   - You see "Offline" indicator
   - Tasks/events still work normally
   - Changes save locally
   - Queued for later sync

3. **When Connection Restored:**
   - You see "Syncing..." indicator
   - Automatic sync happens
   - All queued changes upload
   - Fresh data downloads

### Visual Indicators

**In Navigation Bar (Tasks view):**

- 📶 **Connected + Synced**: Shows "Synced 2m ago"
- 🔄 **Syncing**: Shows progress spinner + "Syncing..."
- 📴 **Offline**: Shows "📡 Offline" with orange icon

### What Works Offline?

✅ **Fully Supported:**
- ✅ View all tasks (from cache)
- ✅ Create new tasks
- ✅ Toggle task completion
- ✅ Delete tasks
- ✅ View events (from cache)
- ✅ Create new events
- ✅ View dashboard stats
- ✅ Browse calendar

❌ **Requires Connection:**
- ❌ AI Chat (needs live API)
- ❌ Initial login/register
- ❌ User profile updates

---

## 🔍 Testing Checklist

### Basic Offline Flow

- [ ] Login while online
- [ ] Go to Tasks
- [ ] Enable Airplane Mode
- [ ] See "Offline" indicator appear
- [ ] Create a new task
- [ ] Task appears in list immediately
- [ ] Toggle task completion
- [ ] Delete a task
- [ ] Disable Airplane Mode
- [ ] See "Syncing..." indicator
- [ ] Verify changes synced to server

### Edge Cases

- [ ] **Force quit app while offline**
  - Changes persist after restart
  - Auto-sync when app reopens online

- [ ] **Create 10 tasks offline**
  - All queue properly
  - All sync when online

- [ ] **Toggle same task multiple times offline**
  - Final state syncs correctly

- [ ] **Delete task created offline**
  - Both actions queue
  - Handled correctly on sync

### Dashboard & Calendar

- [ ] **View dashboard offline**
  - Stats show from cache
  - Widgets display correctly

- [ ] **View calendar offline**
  - Events appear from cache
  - Can create new events

- [ ] **Sync updates dashboard**
  - Fresh data appears after sync

---

## 🛠️ Developer Testing

### Check Sync Queue

Look for console logs:

```
✅ Synced 15 tasks
📋 Saved pending action: createTask
⚙️ Processing action: createTask
✅ Completed action: createTask
```

### Verify Local Storage

Check SwiftData persistence:

1. Create tasks offline
2. Force quit app
3. Relaunch app (still offline)
4. Tasks should still be there

### Test Retry Logic

1. Create task while offline
2. Keep offline and restart app 3 times
3. Action retries but doesn't duplicate
4. Go online → syncs once

### Monitor Network State

Watch for:

```
🌍 Network connected: wifi
📴 Network disconnected
🔄 Starting full sync...
✅ Full sync completed
```

---

## 🐛 Troubleshooting

### "Tasks don't appear after going offline"

**Cause**: No initial sync happened
**Fix**: Go online first, wait for sync, then go offline

### "Changes don't sync when back online"

**Check**:
1. Look for sync errors in console
2. Verify backend is running
3. Check auth token is valid

### "Duplicate tasks after sync"

**Cause**: Temporary IDs not replaced
**Fix**: Should not happen - report as bug

### "App crashes on offline action"

**Check**:
1. SwiftData container initialized?
2. Files added to Xcode project?
3. Console error messages?

---

## 📊 How It Works (Technical)

### Architecture

```
┌─────────────────────────────────────┐
│           User Action               │
└──────────────┬──────────────────────┘
               │
               ▼
        ┌─────────────┐
        │ Online?     │
        └──────┬──────┘
               │
       ┌───────┴────────┐
       │                │
    ✅ Yes           ❌ No
       │                │
       ▼                ▼
   ┌───────┐      ┌──────────────┐
   │  API  │      │ Local Cache  │
   └───┬───┘      └──────┬───────┘
       │                 │
       ▼                 ▼
   ┌────────┐      ┌──────────────┐
   │ Cache  │      │ Pending Queue│
   └────────┘      └──────────────┘
       │                 │
       └────────┬────────┘
                ▼
           ┌─────────┐
           │   UI    │
           └─────────┘
```

### Data Flow

1. **App Launch:**
   - Load from SwiftData cache (instant)
   - If online → sync in background
   - UI updates with fresh data

2. **User Creates Task (Offline):**
   - Save to SwiftData with temp ID
   - Add to pending actions queue
   - Update UI immediately

3. **Connection Restored:**
   - NetworkMonitor posts notification
   - SyncManager processes pending queue
   - Each action retries up to 3 times
   - Download fresh data from server
   - Update local cache
   - Update Spotlight index

### Pending Action Structure

```swift
{
  "id": "uuid",
  "actionType": "createTask",
  "entityType": "task",
  "entityId": -1731234567, // temp ID
  "payload": {encodedJSON},
  "retryCount": 0
}
```

---

## ✅ Success Criteria

After adding files and building, you should see:

1. ✅ App launches instantly (loads from cache)
2. ✅ "Offline" indicator when disconnected
3. ✅ Can create/edit/delete tasks offline
4. ✅ Changes persist through app restart
5. ✅ Auto-sync when connection restored
6. ✅ No data loss or duplicates

---

## 🚀 Quick Start Commands

```bash
# Open Xcode
open /Users/scawful/Code/halext-org/ios/Cafe.xcodeproj

# After adding files, build
# Cmd+B in Xcode

# Run on simulator
# Cmd+R in Xcode

# Test offline mode:
# - Run app
# - Settings → Airplane Mode → ON
# - Create tasks
# - Airplane Mode → OFF
# - Watch sync happen
```

---

## 📝 Example Test Session

```
1. Launch app while online
   ✅ Data loads from cache (fast)
   ✅ Background sync starts
   ✅ "Synced 2s ago" appears

2. Enable Airplane Mode
   ✅ "Offline" indicator appears
   ✅ Tasks still visible

3. Create "Buy groceries" task
   ✅ Appears in list immediately
   ✅ Saved to local storage
   ✅ Queued for sync

4. Toggle task as complete
   ✅ Updates immediately
   ✅ Action queued

5. Disable Airplane Mode
   ✅ "Syncing..." appears
   ✅ Pending actions process
   ✅ Fresh data downloads
   ✅ "Synced just now" appears

6. Check backend
   ✅ Task exists on server
   ✅ Completion status matches
```

---

**Ready to test offline mode!** 🎉

Just add the files to Xcode, build, and start testing with Airplane Mode.

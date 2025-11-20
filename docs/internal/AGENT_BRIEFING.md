# Agent Briefing: Critical iOS Issues

## Current Status (Nov 20, 2025 - 3:00 PM)

### ✅ What's Working
- Backend deployed at https://org.halext.org/ with AI model endpoints
- Dashboard quick actions (New Task, New Event, View All) - **FIXED**
- Settings quick access via gear icon
- Sakura pink theme
- Admin AI credentials management UI
- App builds successfully, IPA available

### ❌ What's STILL Broken
1. **More Page Navigation** - None of the feature cards work when tapped
2. **AI Model Selector** - "Select model" and "load available models" do nothing

---

## For the Next Agent

### READ THESE FIRST:
1. `/Users/scawful/Code/halext-org/docs/internal/FIX_PLAN_MORE_PAGE_AND_AI.md`
   - Comprehensive investigation plan
   - Theories about what's wrong
   - Step-by-step debugging approach

2. `/Users/scawful/Code/halext-org/docs/internal/QUICK_DEBUG_CHECKLIST.md`
   - Quick fixes to try first
   - Debug logging patterns
   - Emergency fallback approaches

### Your Mission:
**DO NOT just apply random fixes. Follow this process:**

1. **Investigate First** (30 minutes)
   - Read the code files listed in the plans
   - Test in Xcode Simulator if possible
   - Document exact behavior of broken features
   - Form specific hypotheses

2. **Test Hypotheses** (30 minutes)
   - Try the quick fixes from checklist
   - Add debug logging
   - Test after each change
   - Document what works/doesn't

3. **Apply Targeted Fixes** (30 minutes)
   - Based on findings, implement the RIGHT fix
   - Don't cargo-cult code from examples
   - Test thoroughly

4. **Verify** (15 minutes)
   - Rebuild IPA
   - Test both features work
   - Document the solution

---

## Context You Need to Know

### More Page Issue History:
- **Attempt 1:** Added `Hashable` to `FeatureDestination` enum
  - **Result:** Build succeeded, still doesn't work on device
  - **Theory:** Might be NavigationStack placement issue

- **Previous Working Patterns:**
  - Dashboard uses `NavigationLink(destination: View())`
  - This works reliably

- **Current Pattern:**
  - More page uses `NavigationLink(value: enum)`
  - With `.navigationDestination(for: enum.self)`
  - Theory is sound, but not working in practice

### AI Model Selector Issue History:
- **Backend:** Fully implemented and deployed
  - `GET /admin/ai/models/openai` - Works on server
  - `GET /admin/ai/models/gemini` - Works on server
  - Model metadata system complete

- **iOS:** Enhanced UI created
  - Shows tiers, costs, context windows
  - BUT: Not loading any data

- **Possible Issues:**
  - API not being called
  - Auth headers missing
  - No API keys configured on server
  - UI not updating when data arrives

---

## Key Files to Focus On

### More Page:
```
ios/Cafe/App/RootView.swift          - How More tab is set up
ios/Cafe/Features/More/MoreView.swift - Navigation implementation
```

### AI Models:
```
ios/Cafe/Features/Settings/AISettingsView.swift     - Entry point
ios/Cafe/Features/Settings/AIModelPickerView.swift  - The picker
ios/Cafe/Core/API/APIClient+AI.swift                - API calls
```

---

## Success Criteria

### More Page Fixed When:
- Tap "Tasks" card → Navigates to TaskListView
- Tap "Calendar" card → Navigates to CalendarView
- All 9 feature cards work
- Back button returns to More page

### AI Model Selector Fixed When:
- Open Settings → AI Settings → AI Model
- Picker loads and shows models
- Models have names, descriptions, tiers, costs
- Can select a model
- Selection is saved and used

---

## Important Notes

1. **User is frustrated** - Multiple fix attempts haven't worked
2. **Quick actions DO work now** - So we know how to fix things when done right
3. **Focus on investigation** - Don't guess, understand the problem first
4. **Test incrementally** - Small changes, test after each
5. **Document findings** - So next agent doesn't repeat same mistakes

---

## Command to Start Fresh Investigation

```bash
# Open these files side-by-side:
code ios/Cafe/App/RootView.swift \
     ios/Cafe/Features/More/MoreView.swift \
     ios/Cafe/Features/Dashboard/DashboardView.swift

# Search for working navigation patterns:
grep -r "NavigationLink" ios/Cafe/Features/Dashboard/

# Check current More page navigation:
grep -A 10 "navigationDestination" ios/Cafe/Features/More/MoreView.swift
```

---

## When to Give Up and Escalate

If after 2 hours of focused debugging you haven't:
- Figured out WHY it's broken
- Made measurable progress
- Found a working pattern to copy

Then STOP and report:
- What you tried
- What you learned
- What you're stuck on
- Specific questions for the user

Don't spin your wheels. Better to ask for help than waste time.

---

## Final Reminder

**The user said: "The more page is still useless. It doesnt work."**

This is the PRIMARY issue to solve. Everything else is secondary.
Get the More page working first, then tackle AI models.

Good luck! 🚀

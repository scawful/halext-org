# AI Model Selection & Social Features UX/UI Improvements

## Context

We've recently improved the AI model picker (`AIModelPickerView`) to handle 116+ models with:
- Compact, scrollable rows
- Collapsible sections
- Quick filter chips
- Enhanced search

However, there are many more UX/UI improvements we could make across the entire AI experience AND we have critical social features that need fixing. **Before creating a plan, you MUST ask comprehensive follow-up questions** to understand user needs, priorities, and design preferences.

## Areas to Explore

### 1. AgentHubView & Model Display
- Current state: Shows models in a list with animations
- Potential improvements: Better visual hierarchy, model comparison, favorites, recent models
- Questions needed: How do users typically select models? Do they compare models? Do they have favorites?

### 2. Settings Integration
- Current state: Multiple settings views (AISettingsView, ChatSettingsView, AgentHubView)
- Potential improvements: Unified settings experience, better organization, contextual help
- Questions needed: Are users confused by multiple settings locations? What's the primary use case?

### 3. Model Information Display
- Current state: Shows name, provider, capabilities, latency
- Potential improvements: Cost estimates, performance metrics, usage history, recommendations
- Questions needed: What information do users need to make decisions? When do they need detailed vs. summary info?

### 4. Selection & Feedback
- Current state: Checkmark indicators, basic animations
- Potential improvements: Visual feedback, confirmation dialogs, undo, preview/test models
- Questions needed: Do users need to test models before committing? Should selection be reversible?

### 5. Error States & Loading
- Current state: Basic progress views and error alerts
- Potential improvements: Skeleton loading, better error messages, retry strategies, offline handling
- Questions needed: What errors do users encounter? How should we handle slow networks?

### 6. Accessibility & Internationalization
- Current state: Basic accessibility labels
- Potential improvements: VoiceOver improvements, dynamic type, localization
- Questions needed: Are there accessibility pain points? What languages are needed?

### 7. Performance & Optimization
- Current state: Loads all 116 models at once
- Potential improvements: Pagination, lazy loading, caching, prefetching
- Questions needed: Is performance acceptable? Are there specific pain points?

### 8. Onboarding & Help
- Current state: No onboarding or help text
- Potential improvements: Tooltips, guided tours, contextual help, model recommendations
- Questions needed: Are new users confused? What do they need to learn first?

### 9. Visual Design & Branding
- Current state: Standard iOS list styling
- Potential improvements: Custom cards, better icons, color coding, animations
- Questions needed: Should we match existing app design? Any brand guidelines?

### 10. Advanced Features
- Potential additions: Model comparison view, usage analytics, cost tracking, model testing playground
- Questions needed: What advanced features would be most valuable? What's the priority?

## Social Features - CRITICAL FIXES NEEDED

### Current Issues (from logs and codebase analysis)

1. **Presence API Errors**
   - 500 errors from `/api/users/{username}/presence` endpoint
   - Repeated retry attempts failing
   - Error: "Internal Server Error" with invalid JSON response
   - Location: `APIClient+Presence.swift`, `PresenceManager.swift`

2. **CloudKit Unavailable**
   - Warnings: "Presence tracking not started: CloudKit unavailable or no profile"
   - Social features depend on CloudKit but it's not available
   - Location: `SocialPresenceManager.swift`, `SocialManager.swift`

3. **Multiple Presence Systems**
   - Two presence managers: `PresenceManager` (backend API) and `SocialPresenceManager` (CloudKit)
   - Potential conflicts or confusion about which to use
   - Need to understand the intended architecture

4. **Social Features Architecture**
   - Social features documented but may not be fully functional
   - CloudKit-based but CloudKit appears disabled
   - Backend API presence endpoints exist but returning errors
   - Location: `SOCIAL_FEATURES_DOCS.md`, various social view files

### Areas Requiring Investigation & Fixes

#### 11. Presence System Architecture
- **Current state**: Two presence systems (CloudKit + Backend API), 500 errors, CloudKit unavailable
- **Questions needed**: 
  - Should we use CloudKit or backend API for presence?
  - Why is CloudKit unavailable? Is it intentional or a bug?
  - Are both systems needed, or should we consolidate?
  - What's the intended architecture?
  - Is the backend presence endpoint implemented correctly?

#### 12. Presence API Error Handling
- **Current state**: 500 errors not handled gracefully, retries failing
- **Questions needed**:
  - Is the backend endpoint `/api/users/{username}/presence` implemented?
  - What should happen when presence fails?
  - Should we show errors to users or fail silently?
  - How should we handle offline scenarios?

#### 13. Social Features Integration
- **Current state**: Social features exist but may not work due to CloudKit dependency
- **Questions needed**:
  - Should social features work without CloudKit?
  - Can we migrate to backend API instead?
  - What social features are actually being used?
  - Are shared tasks, activity feeds, etc. working?

#### 14. Partner Status & Presence Display
- **Current state**: Partner status cards may not show correct data
- **Questions needed**:
  - How should partner presence be displayed?
  - What information is most important?
  - Should we show real-time updates or cached data?
  - How do we handle when partner is offline?

#### 15. Error Recovery & User Experience
- **Current state**: Errors may be silent or confusing
- **Questions needed**:
  - How should we communicate presence errors to users?
  - Should social features degrade gracefully?
  - What's the fallback when presence fails?
  - Should we show connection status indicators?

## Required Process

**CRITICAL: Before creating any plan, you MUST:**

1. **Ask at least 10-15 follow-up questions** covering:
   - User needs and pain points
   - Priority and scope preferences
   - Design preferences and constraints
   - Technical constraints
   - User flows and workflows
   - Success metrics

2. **Explore the codebase** to understand:
   - Current implementation details
   - Related views and components
   - Existing design patterns
   - State management approach
   - Theme system usage
   - **Social features architecture** (CloudKit vs Backend API)
   - **Presence system implementation** (both PresenceManager and SocialPresenceManager)
   - **Backend API endpoints** for presence and social features

3. **Identify specific problems** by:
   - Reading user feedback (if available)
   - Analyzing current UX flows
   - Finding friction points
   - Identifying missing features

4. **Only then create a plan** that:
   - Addresses specific, validated problems
   - Prioritizes based on user needs
   - Follows existing design patterns
   - Is scoped appropriately

## Example Questions to Ask

### User Needs & Pain Points
- "What specific problems are users experiencing with the current AI model selection?"
- "Do users frequently switch between models, or do they set it once and forget it?"
- "Are there models that users never select? Why?"
- "What information do users need to make model selection decisions?"
- "Do users understand the difference between providers (OpenAI, Gemini, etc.)?"

### Priority & Scope
- "Which improvements would have the biggest impact on user satisfaction?"
- "Should we focus on the model picker, or the broader AI settings experience?"
- "Are there quick wins we should prioritize over larger redesigns?"
- "What's the timeline and scope we're working with?"

### Design Preferences
- "Should we maintain the current iOS-native look, or create a more custom design?"
- "Do we have design system guidelines to follow?"
- "Are there specific accessibility requirements?"
- "What's the target device (iPhone only, or iPad too)?"

### Technical Constraints
- "Are there performance requirements we need to meet?"
- "Do we need to maintain backward compatibility?"
- "Are there API limitations we should be aware of?"
- "What iOS version are we targeting?"

### User Flows
- "How do users typically discover and access AI model settings?"
- "Do users need to compare models side-by-side?"
- "Should model selection be contextual (different models for different features)?"
- "Do users need to test models before committing?"

### Social Features & Presence
- "Is the backend presence endpoint `/api/users/{username}/presence` implemented and working?"
- "Should we use CloudKit or backend API for social features? Or both?"
- "Why is CloudKit showing as unavailable? Is this intentional?"
- "Are users actually using social features (shared tasks, presence, etc.)?"
- "What's the priority: fixing presence errors or improving social UX?"
- "How should we handle presence failures gracefully?"
- "Do we need both PresenceManager and SocialPresenceManager?"
- "What social features are most important to users?"
- "Should social features work offline or require network?"
- "How do users discover and use social features?"

## Success Criteria

### AI Features
- Make model selection faster and easier
- Reduce cognitive load when choosing from 116+ models
- Improve discoverability of model features
- Enhance overall user satisfaction with AI features
- Maintain or improve performance

### Social Features (CRITICAL)
- Fix presence API 500 errors
- Resolve CloudKit availability issues OR migrate to backend API
- Ensure partner presence displays correctly
- Handle errors gracefully without breaking user experience
- Make social features functional and reliable
- Clarify architecture (CloudKit vs Backend API)

## Next Steps

1. Read this prompt carefully
2. Explore the codebase:
   - **AI Features**: `AIModelPickerView.swift`, `AgentHubView.swift`, `AISettingsView.swift`
   - **Social Features**: `SocialManager.swift`, `SocialPresenceManager.swift`, `PresenceManager.swift`
   - **API Clients**: `APIClient+Presence.swift`, `APIClient+Social.swift`
   - **Views**: `SocialDashboardView.swift`, `PartnerStatusCard.swift`, `SharedTasksView.swift`
   - **Backend**: Check if presence endpoints are implemented (`/api/users/{username}/presence`)
3. **ASK LOTS OF QUESTIONS** before planning (especially about social features architecture)
4. Create a detailed plan that addresses BOTH AI UX improvements AND social features fixes
5. Get approval before implementing

Remember: **Better to ask too many questions than to build the wrong thing!**


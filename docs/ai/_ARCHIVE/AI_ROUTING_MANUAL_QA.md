# AI Routing Manual QA Checklist

This document provides comprehensive manual testing scenarios for the AI routing implementation. Use this checklist to verify that all AI routing features work correctly across different platforms and configurations.

## Prerequisites

Before starting manual testing, ensure:
- [ ] Backend server is running and accessible
- [ ] At least one AI client node (Mac/Windows) is configured and online
- [ ] You have both admin and regular user accounts
- [ ] Frontend web application is built and accessible
- [ ] iOS app is built and running (if testing mobile)

## Test Environment Setup

### Setting Up Test Nodes

1. **Mac/Windows AI Node Configuration**
   - [ ] SSH into halext-server or access admin panel
   - [ ] Navigate to Admin → AI Clients
   - [ ] Add MacBook Pro node:
     - Name: "MacBook Pro M1"
     - Type: ollama
     - Hostname: [Mac IP/hostname]
     - Port: 11434
     - Is Public: ✓
   - [ ] Add Windows GPU node:
     - Name: "Windows GPU RTX 4090"
     - Type: ollama
     - Hostname: [Windows IP/hostname]
     - Port: 11434
     - Is Public: ✓
   - [ ] Test connection for both nodes
   - [ ] Verify models are discovered

2. **Verify Node Status**
   - [ ] Check that both nodes show "online" status
   - [ ] Verify model count is > 0 for each node
   - [ ] Note response time (latency) for each node

---

## Section 1: Model Discovery & Listing

### Test Case 1.1: View Available Models (Web)

**Objective:** Verify that all configured models appear in the UI

**Steps:**
1. [ ] Log in to web application
2. [ ] Navigate to AI Chat section
3. [ ] Click on model selector/dropdown
4. [ ] Observe the list of available models

**Expected Results:**
- [ ] MacBook Pro models appear with node name
- [ ] Windows GPU models appear with node name
- [ ] Cloud provider models appear (OpenAI, Gemini if configured)
- [ ] Models are grouped by provider/source
- [ ] Latency information is displayed for client nodes
- [ ] Mock models appear if no providers configured

**Acceptance Criteria:**
- All online nodes' models are visible
- Node names are clearly labeled
- No duplicate entries
- UI is responsive and loads within 2 seconds

---

### Test Case 1.2: Filter Own vs Public Nodes

**Objective:** Verify filtering logic for private vs public nodes

**Steps:**
1. [ ] As admin user, create a private AI node (is_public = false)
2. [ ] Log in as admin, navigate to model selector
3. [ ] Verify private node appears
4. [ ] Log out, log in as regular user
5. [ ] Navigate to model selector

**Expected Results:**
- [ ] Admin sees both public and own private nodes
- [ ] Regular user sees only public nodes
- [ ] Regular user does NOT see admin's private node
- [ ] User can see their own private nodes if they create any

---

### Test Case 1.3: API Endpoint - List Models

**Objective:** Test `/ai/models` API endpoint directly

**Steps:**
1. [ ] Obtain authentication token
2. [ ] Make GET request to `/ai/models`
3. [ ] Inspect response JSON

**Expected Response Structure:**
```json
{
  "models": [
    {
      "id": "client:1:llama3.1",
      "name": "llama3.1",
      "provider": "ollama",
      "node_id": 1,
      "node_name": "MacBook Pro M1",
      "latency_ms": 120,
      ...
    }
  ],
  "provider": "mock",
  "current_model": "llama3.1",
  "default_model_id": "client:1:llama3.1"
}
```

**Acceptance Criteria:**
- [ ] Response status is 200
- [ ] All models include required fields (id, name, provider)
- [ ] Client models include node_id and node_name
- [ ] default_model_id is set correctly

---

## Section 2: Model Selection & Routing

### Test Case 2.1: Select OpenAI Model (Web)

**Objective:** Test selecting and using OpenAI cloud model

**Steps:**
1. [ ] Navigate to AI Chat
2. [ ] Open model selector
3. [ ] Select "OpenAI: gpt-4o-mini"
4. [ ] Type message: "What is 2+2?"
5. [ ] Send message
6. [ ] Observe response header/metadata

**Expected Results:**
- [ ] Model selector shows "OpenAI: gpt-4o-mini" as selected
- [ ] Response is generated successfully
- [ ] SSE header or response metadata shows `model: openai:gpt-4o-mini`
- [ ] Provider badge shows "OpenAI"

---

### Test Case 2.2: Select Remote Node Model (Web)

**Objective:** Test selecting and using a remote client node

**Steps:**
1. [ ] Navigate to AI Chat
2. [ ] Open model selector
3. [ ] Select "MacBook Pro M1: llama3.1"
4. [ ] Type message: "Tell me a joke"
5. [ ] Send message
6. [ ] Check response metadata

**Expected Results:**
- [ ] Selected model shows as "client:1:llama3.1" (or similar)
- [ ] Response is generated from MacBook node
- [ ] SSE/response header confirms model: `client:1:llama3.1`
- [ ] Node name "MacBook Pro M1" is displayed
- [ ] Latency/performance is reasonable

---

### Test Case 2.3: Switch Between Models

**Objective:** Verify switching between different models mid-conversation

**Steps:**
1. [ ] Start chat with "OpenAI: gpt-4o-mini"
2. [ ] Send message: "Hello"
3. [ ] Receive response
4. [ ] Switch model to "MacBook Pro: llama3.1"
5. [ ] Send message: "How are you?"
6. [ ] Receive response

**Expected Results:**
- [ ] First response uses OpenAI
- [ ] Second response uses MacBook node
- [ ] Conversation history is maintained
- [ ] No errors or warnings
- [ ] UI clearly shows which model was used for each message

---

### Test Case 2.4: Test Streaming Response

**Objective:** Verify streaming works with different models

**Steps:**
1. [ ] Select a client node model
2. [ ] Send a message that generates a long response
3. [ ] Observe streaming behavior

**Expected Results:**
- [ ] Response streams in real-time (word by word)
- [ ] No buffering delay
- [ ] Stream completes successfully
- [ ] Model identifier is included in SSE headers

---

## Section 3: Settings & Preferences

### Test Case 3.1: Toggle "Cloud Only" Setting

**Objective:** Test filtering models by source preference

**Steps:**
1. [ ] Navigate to Settings → AI
2. [ ] Enable "Cloud providers only" toggle
3. [ ] Return to AI Chat
4. [ ] Open model selector

**Expected Results:**
- [ ] Only cloud providers (OpenAI, Gemini) appear
- [ ] Remote nodes (client:*) are hidden
- [ ] Toggle state persists across page reloads

---

### Test Case 3.2: Toggle "Remote Only" Setting

**Objective:** Test excluding cloud providers

**Steps:**
1. [ ] Navigate to Settings → AI
2. [ ] Enable "Remote/local only" toggle
3. [ ] Return to AI Chat
4. [ ] Open model selector

**Expected Results:**
- [ ] Only remote nodes and local Ollama appear
- [ ] Cloud providers (OpenAI, Gemini) are hidden
- [ ] Setting persists

---

### Test Case 3.3: Picker Updates Immediately

**Objective:** Verify real-time updates when settings change

**Steps:**
1. [ ] Open AI Chat with model selector visible
2. [ ] In another tab, change AI settings
3. [ ] Return to AI Chat tab

**Expected Results:**
- [ ] Model list updates without refresh
- [ ] Previously selected model is cleared if now filtered
- [ ] No errors in console

---

## Section 4: Admin Panel Features

### Test Case 4.1: Add New AI Client Node

**Objective:** Test adding a new remote node via admin panel

**Steps:**
1. [ ] Log in as admin
2. [ ] Navigate to Admin → AI Clients
3. [ ] Click "Add Client"
4. [ ] Fill in details:
   - Name: "Test Node"
   - Type: ollama
   - Hostname: localhost
   - Port: 11434
   - Is Public: ✓
5. [ ] Click "Test Connection"
6. [ ] Click "Save"

**Expected Results:**
- [ ] Connection test shows "online" with model count
- [ ] Node appears in list with green status
- [ ] Node's models immediately appear in `/ai/models` endpoint
- [ ] Frontend model picker updates (may require refresh)

---

### Test Case 4.2: View Client Models

**Objective:** View models available on a specific node

**Steps:**
1. [ ] Navigate to Admin → AI Clients
2. [ ] Click on a node (e.g., "MacBook Pro")
3. [ ] Click "View Models" or similar action

**Expected Results:**
- [ ] List of models on that node is displayed
- [ ] Model names, sizes, and metadata are shown
- [ ] "Copy Identifier" button works (e.g., copies `client:1:llama3.1`)

---

### Test Case 4.3: Health Check All Nodes

**Objective:** Test bulk health check functionality

**Steps:**
1. [ ] Navigate to Admin → AI Clients
2. [ ] Click "Health Check All" button
3. [ ] Observe results

**Expected Results:**
- [ ] Each node shows updated status (online/offline)
- [ ] Response times are updated
- [ ] Offline nodes show error messages
- [ ] Model counts are refreshed

---

### Test Case 4.4: Pull Model on Node

**Objective:** Test pulling a new model onto a remote node

**Steps:**
1. [ ] Navigate to Admin → AI Clients
2. [ ] Select an Ollama node
3. [ ] Click "Pull Model"
4. [ ] Enter model name: "mistral"
5. [ ] Submit

**Expected Results:**
- [ ] Pull operation starts
- [ ] Progress or confirmation message appears
- [ ] New model appears in node's model list after pull completes
- [ ] Model becomes available in frontend picker

---

## Section 5: Conversation & Messaging

### Test Case 5.1: Group Chat with AI

**Objective:** Test AI in group conversation

**Steps:**
1. [ ] Create a group conversation with AI enabled
2. [ ] Select a specific model (e.g., "MacBook Pro: llama3.1")
3. [ ] Send a message
4. [ ] Observe AI response

**Expected Results:**
- [ ] AI responds in the group chat
- [ ] Message metadata shows `model_used: "client:1:llama3.1"`
- [ ] UI displays model badge (e.g., "AI • MacBook Pro (llama3.1)")
- [ ] Other participants can see the model info

---

### Test Case 5.2: Per-Message Model Override

**Objective:** Test changing model for a single message (advanced)

**Steps:**
1. [ ] In a conversation, click "Route" button (if implemented)
2. [ ] Select different model for this message only
3. [ ] Send message

**Expected Results:**
- [ ] Message uses the overridden model
- [ ] Subsequent messages revert to default conversation model
- [ ] Model used is clearly indicated in UI

---

## Section 6: iOS App Testing

### Test Case 6.1: List Models on iOS

**Objective:** Verify model listing works on iOS

**Steps:**
1. [ ] Open Cafe iOS app
2. [ ] Navigate to AI Chat or Settings → AI
3. [ ] View available models

**Expected Results:**
- [ ] All configured models appear
- [ ] Node names are visible
- [ ] Cloud and remote models are distinguishable
- [ ] UI is responsive and formatted correctly

---

### Test Case 6.2: Select and Use Model (iOS)

**Objective:** Test model selection in iOS app

**Steps:**
1. [ ] Open AI Chat
2. [ ] Tap model selector
3. [ ] Select "Windows GPU: llama3.1"
4. [ ] Send a message

**Expected Results:**
- [ ] Model selection persists
- [ ] Response comes from selected model
- [ ] Model info is displayed in chat UI
- [ ] No crashes or errors

---

### Test Case 6.3: Sync Settings Between Web and iOS

**Objective:** Test preference synchronization

**Steps:**
1. [ ] On web, select "OpenAI: gpt-4o-mini" as default
2. [ ] Open iOS app
3. [ ] Check if same model is selected

**Expected Results:**
- [ ] If preferences are synced via backend, iOS shows same selection
- [ ] Otherwise, iOS has independent preference (expected behavior)

---

## Section 7: Regression & Edge Cases

### Test Case 7.1: No Providers Available

**Objective:** Test UI when no AI providers are configured

**Steps:**
1. [ ] Disable all cloud providers (remove API keys)
2. [ ] Set all client nodes to inactive
3. [ ] Navigate to AI Chat
4. [ ] Open model selector

**Expected Results:**
- [ ] Mock models are displayed (llama3.1, mistral)
- [ ] Call-to-action message appears: "Configure AI providers in settings"
- [ ] UI does not crash
- [ ] User can still attempt to chat (receives mock responses)

---

### Test Case 7.2: Node Goes Offline During Chat

**Objective:** Test handling when node becomes unavailable

**Steps:**
1. [ ] Select a client node model
2. [ ] Start a conversation
3. [ ] Stop the Ollama service on that node
4. [ ] Send another message

**Expected Results:**
- [ ] Request fails gracefully
- [ ] Error message shown: "Node unavailable, falling back to default"
- [ ] System automatically falls back to mock or default model
- [ ] User can continue conversation with different model

---

### Test Case 7.3: Invalid Model Identifier

**Objective:** Test handling of malformed identifiers

**Steps:**
1. [ ] Manually make API request with invalid model ID:
   ```
   POST /ai/chat
   { "prompt": "test", "model": "invalid:bad:id" }
   ```

**Expected Results:**
- [ ] Request does not crash server
- [ ] Falls back to default model
- [ ] Returns 200 with response from fallback model

---

### Test Case 7.4: Concurrent Requests

**Objective:** Test multiple simultaneous requests

**Steps:**
1. [ ] Open 3 browser tabs
2. [ ] In each tab, send different messages to different models simultaneously

**Expected Results:**
- [ ] All requests complete successfully
- [ ] No race conditions or errors
- [ ] Each response matches its requested model

---

## Section 8: Performance & Reliability

### Test Case 8.1: Latency Display Accuracy

**Objective:** Verify latency measurements are accurate

**Steps:**
1. [ ] View model list with latency info
2. [ ] Note latency for each node
3. [ ] Send messages to different nodes
4. [ ] Observe actual response times

**Expected Results:**
- [ ] Displayed latency roughly matches actual response time
- [ ] Fast nodes show lower latency
- [ ] Slow/distant nodes show higher latency

---

### Test Case 8.2: Model Selection Persistence

**Objective:** Verify selection persists across sessions

**Steps:**
1. [ ] Select a specific model
2. [ ] Send a message
3. [ ] Close browser
4. [ ] Reopen and log in
5. [ ] Navigate to AI Chat

**Expected Results:**
- [ ] Previously selected model is still active
- [ ] Or, defaults to system default (depending on implementation)

---

## Section 9: API Integration Tests

### Test Case 9.1: Task Suggestions with Model Selection

**Objective:** Test AI task features with custom model

**Steps:**
1. [ ] Make POST request to `/ai/tasks/suggest`
   ```json
   {
     "title": "Build a website",
     "description": "E-commerce site",
     "model": "client:1:llama3.1"
   }
   ```

**Expected Results:**
- [ ] Response includes task suggestions
- [ ] Specified model was used
- [ ] Response metadata confirms model identifier

---

### Test Case 9.2: Event Analysis with Model

**Objective:** Test event AI features

**Steps:**
1. [ ] POST to `/ai/events/analyze` with model parameter

**Expected Results:**
- [ ] Analysis is returned
- [ ] Custom model is used if specified

---

### Test Case 9.3: Recipe Generation with Model

**Objective:** Test recipe AI endpoints

**Steps:**
1. [ ] POST to `/ai/recipes/generate` with model parameter

**Expected Results:**
- [ ] Recipes are generated
- [ ] Model selection is respected

---

## Test Completion Checklist

### Critical Tests (Must Pass)
- [ ] Test Case 1.1: View Available Models
- [ ] Test Case 2.1: Select OpenAI Model
- [ ] Test Case 2.2: Select Remote Node Model
- [ ] Test Case 2.3: Switch Between Models
- [ ] Test Case 7.1: No Providers Available

### Important Tests (Should Pass)
- [ ] All Section 1 tests (Model Discovery)
- [ ] All Section 2 tests (Model Selection)
- [ ] Test Case 3.1-3.2: Settings Toggles
- [ ] Test Case 7.2: Node Goes Offline

### Optional Tests (Nice to Have)
- [ ] iOS app tests (Section 6)
- [ ] Advanced admin features (Section 4)
- [ ] Performance tests (Section 8)

---

## Bug Reporting Template

When you find issues during testing, use this template:

```
**Test Case:** [e.g., 2.2 - Select Remote Node Model]
**Environment:** [Web/iOS, Browser version, OS]
**Steps to Reproduce:**
1.
2.
3.

**Expected Result:**

**Actual Result:**

**Screenshots/Logs:**

**Severity:** [Critical/High/Medium/Low]
```

---

## Notes

- Test in both development and production environments
- Test with different network conditions (fast/slow)
- Test with different user roles (admin, regular user)
- Clear browser cache between tests if issues arise
- Check browser console for errors
- Monitor backend logs during testing

---

**Last Updated:** 2025-11-19
**Version:** 1.0
**Maintainer:** AI Routing Implementation Team

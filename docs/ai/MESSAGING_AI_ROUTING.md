# Messaging & Group Chat AI Integration

This document describes the AI model routing integration for the messaging and group chat system.

## Overview

The messaging system now supports:
1. AI model selection at the conversation level (default model for all messages)
2. Per-message model overrides (use different model for specific prompts)
3. Display of which model generated each AI response
4. Consistent UI across web and mobile platforms

## Database Schema Changes

### Conversation Model

Added new field to the `conversations` table:

```sql
ALTER TABLE conversations ADD COLUMN default_model_id VARCHAR NULL;
```

**Field Details:**
- `default_model_id` (String, nullable): The AI model identifier to use for this conversation
- If null, uses the system default model
- Format: Same as other model identifiers (e.g., "openai:gpt-4", "client:1:llama3.1")

### Migration

Run the migration script:

```bash
cd backend
python -m migrations.add_conversation_default_model
```

Or manually apply the SQL above to your database.

## Backend Implementation

### API Endpoints

#### 1. Update Conversation Settings

**Endpoint:** `PUT /conversations/{conversation_id}`

**Request Body:**
```json
{
  "title": "My Conversation",
  "mode": "group",
  "with_ai": true,
  "default_model_id": "client:1:llama3.1"
}
```

**Response:** Updated conversation summary including `default_model_id`

**Authorization:** Only conversation owner can modify settings

#### 2. Send Message with Model Override

**Endpoint:** `POST /conversations/{conversation_id}/messages`

**Request Body:**
```json
{
  "content": "Hello, how are you?",
  "model": "openai:gpt-4o-mini"
}
```

**Notes:**
- `model` field is optional
- If provided, overrides conversation's default model for this message only
- If omitted, uses conversation's `default_model_id`
- If conversation's `default_model_id` is null, uses system default

#### 3. Get Conversation Messages

**Endpoint:** `GET /conversations/{conversation_id}/messages`

**Response:**
```json
[
  {
    "id": 1,
    "conversation_id": 1,
    "author_id": 123,
    "author_type": "user",
    "content": "Hello",
    "created_at": "2025-01-01T12:00:00Z"
  },
  {
    "id": 2,
    "conversation_id": 1,
    "author_id": null,
    "author_type": "ai",
    "content": "Hi! How can I help?",
    "model_used": "client:1:llama3.1",
    "created_at": "2025-01-01T12:00:01Z"
  }
]
```

**Notes:**
- AI messages include `model_used` field showing which model generated the response
- User messages do not have `model_used` field

### Model Selection Logic

The backend follows this priority order for selecting which model to use:

1. **Per-message override** (`message.model` in POST request)
2. **Conversation default** (`conversation.default_model_id`)
3. **System default** (from environment or AI gateway configuration)

```python
# From backend/main.py
model_to_use = message.model or conversation.default_model_id
ai_reply, route = await ai_gateway.generate_reply(
    message.content,
    history_payload,
    model_identifier=model_to_use,
    user_id=current_user.id,
    db=db,
    include_context=True,
)
```

## Frontend Implementation

### Components

#### AiModelSelector

Reusable dropdown component for selecting AI models.

**Location:** `/frontend/src/components/ai/AiModelSelector.tsx`

**Usage:**
```tsx
import { AiModelSelector } from '../ai/AiModelSelector'

<AiModelSelector
  token={token}
  compact={false}  // Optional: compact mode for smaller spaces
/>
```

**Features:**
- Automatically loads available models from `/ai/models` endpoint
- Groups models by source/provider
- Shows node name and latency if available
- Integrates with `AiProviderContext` for global model selection
- Persists selection in localStorage

#### AI Chat Section

The main AI chat section now includes model selector in the header.

**Location:** `/frontend/src/components/sections/ChatSection.tsx`

**Features:**
- Model selector in header (top right)
- Shows selected model for all new messages
- Displays model used for each AI response
- Persistent selection across sessions

### Type Updates

Updated TypeScript types to include new fields:

**`/frontend/src/types/models.ts`:**
```typescript
export type ConversationSummary = {
  // ... existing fields
  default_model_id?: string | null
}

export type ChatMessage = {
  // ... existing fields
  model_used?: string | null
}
```

### AI Provider Context

The global AI provider context manages model selection state:

**Location:** `/frontend/src/contexts/AiProviderContext.tsx`

**Usage:**
```tsx
import { useAiProvider } from '../../contexts/AiProviderContext'

const { selectedModelId, setSelectedModelId } = useAiProvider()
```

**State:**
- `selectedModelId`: Currently selected model ID (or undefined for system default)
- `setSelectedModelId`: Function to update the selection
- `disableCloudProviders`: Toggle for privacy-conscious users
- `preferredSources`: Array of preferred model sources
- `resetToDefault`: Clear selection and return to system default

## User Experience Flow

### Setting Conversation Default Model

1. Navigate to conversation settings (owner only)
2. Select "AI Model" from dropdown
3. Choose desired model (or "System Default")
4. Save settings
5. All future AI responses in this conversation use the selected model

### Per-Message Model Override

1. Compose message in conversation
2. Click "Route" button (small icon next to send button)
3. Select model for this specific message
4. Send message
5. AI responds using the selected model
6. Next messages revert to conversation default

### Viewing Model Information

- **In message list:** AI messages show a small chip like "AI • Mac Studio (llama3.1)"
- **In AI chat:** Each assistant message displays the model used
- **In header:** Current/default model shown in selector

## Admin Features

### Conversation Settings UI

Conversation owners can:
- Set default AI model for the conversation
- Toggle AI participation (`with_ai`)
- Change conversation mode (solo/partner/group)
- View which model was used for each AI response

**Implementation Notes:**
- Only conversation owner has edit access
- Regular participants see the settings but cannot modify
- Changes take effect immediately for new messages
- Existing messages retain their original `model_used` value

## iOS Implementation

### Model Structures

Update iOS models to include new fields:

**Location:** `/ios/Cafe/Core/Models/MessageModels.swift`

```swift
struct Conversation: Codable, Identifiable {
    // ... existing fields
    let defaultModelId: String?
    
    enum CodingKeys: String, CodingKey {
        // ... existing cases
        case defaultModelId = "default_model_id"
    }
}
```

### API Client Updates

Add support for updating conversation settings:

**Location:** `/ios/Cafe/Core/API/APIClient+Messages.swift`

```swift
func updateConversation(
    id: Int,
    title: String,
    mode: String,
    withAi: Bool,
    defaultModelId: String?
) async throws -> Conversation {
    var request = try authorizedRequest(
        path: "/conversations/\(id)",
        method: "PUT"
    )
    let body = ConversationUpdate(
        title: title,
        mode: mode,
        withAi: withAi,
        defaultModelId: defaultModelId
    )
    request.httpBody = try JSONEncoder().encode(body)
    return try await performRequest(request)
}
```

### UI Components

Create model selector in conversation settings:

```swift
// In ConversationSettingsView
Picker("AI Model", selection: $selectedModel) {
    Text("System Default").tag(nil as String?)
    ForEach(availableModels) { model in
        Text(model.displayName).tag(model.id as String?)
    }
}
```

Display model used in message bubbles:

```swift
// In MessageBubbleView
if message.authorType == "ai", let model = message.modelUsed {
    HStack(spacing: 4) {
        Circle()
            .fill(Color.purple)
            .frame(width: 6, height: 6)
        Text("AI")
        Text("•")
        Text(model)
            .foregroundColor(.secondary)
    }
    .font(.caption2)
}
```

## Testing

### Manual Testing Checklist

Backend:
- [ ] Create conversation with `default_model_id` set
- [ ] Send message without model override (uses default)
- [ ] Send message with model override (uses specified model)
- [ ] Verify `model_used` appears in GET /messages response
- [ ] Update conversation settings (owner only)
- [ ] Attempt update as non-owner (should fail with 403)

Frontend:
- [ ] Model selector loads and displays available models
- [ ] Selecting model persists in localStorage
- [ ] AI Chat shows selected model in header
- [ ] AI responses display model used
- [ ] Model selection works across page refreshes

iOS:
- [ ] Conversation settings show model selector
- [ ] Updating default model persists on backend
- [ ] Message bubbles show model used for AI responses

### Integration Testing

```python
# Test conversation model selection
def test_conversation_default_model():
    # Create conversation with default model
    conversation = create_conversation(
        title="Test",
        with_ai=True,
        default_model_id="client:1:llama3.1"
    )
    
    # Send message
    messages = send_message(
        conversation.id,
        content="Hello"
    )
    
    # Verify AI response used default model
    ai_message = messages[1]
    assert ai_message.model_used == "client:1:llama3.1"

def test_per_message_override():
    # Create conversation with default
    conversation = create_conversation(
        default_model_id="openai:gpt-4"
    )
    
    # Send with override
    messages = send_message(
        conversation.id,
        content="Hello",
        model="openai:gpt-4o-mini"
    )
    
    # Verify override was used
    ai_message = messages[1]
    assert ai_message.model_used == "openai:gpt-4o-mini"
```

## Security Considerations

1. **Authorization:** Only conversation owners can modify `default_model_id`
2. **Model Validation:** Backend validates model IDs against available models
3. **Cost Control:** Per-message overrides allow users to select cheaper models for simple queries
4. **Privacy:** Users can set conversation defaults to local/self-hosted models

## Future Enhancements

1. **Model Suggestions:** Suggest optimal model based on conversation context
2. **Usage Analytics:** Track which models are used most frequently
3. **Cost Tracking:** Show estimated cost per conversation
4. **Smart Routing:** Automatically route simple queries to faster/cheaper models
5. **Conversation Templates:** Pre-configure model settings for different conversation types

## Troubleshooting

### Model not appearing in selector

1. Verify model is registered in `/admin/ai-clients`
2. Check model is marked as `is_active=true`
3. Ensure node is online and reachable
4. Review `/ai/models` endpoint response

### AI responses not using selected model

1. Check conversation `default_model_id` in database
2. Verify model ID format matches backend expectations
3. Review backend logs for routing decisions
4. Confirm `model_used` field in database matches expectations

### Permission denied updating conversation

1. Verify user is conversation owner
2. Check `conversation.owner_id` matches `current_user.id`
3. Review backend authorization logs

## Related Documentation

- [AI Architecture](./AI_ARCHITECTURE.md) - Overall AI system architecture
- [Ollama Setup Guide](./OLLAMA_SETUP.md) - Ollama server setup guide
- [Distributed Model Router](./DISTRIBUTED_MODEL_ROUTER_PLAN.md)

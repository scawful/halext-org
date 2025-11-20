# AI Model Selector Fix - Complete Documentation

## Problem Summary

The AI model selector in the iOS app was not loading even though users had configured OpenAI and Gemini API keys in the web interface. This was a blocking issue preventing users from selecting AI models.

## Root Cause Analysis

### What Was Broken

1. **Backend was not polling actual models from cloud providers**
   - The `/ai/models` endpoint existed and was being called correctly by iOS
   - However, it only returned models from local Ollama/OpenWebUI instances
   - OpenAI and Gemini providers had `list_models()` methods but they weren't being called with stored credentials

2. **Missing metadata enrichment**
   - Models lacked important information like:
     - Context window sizes
     - Token costs
     - Capabilities (vision support, function calling)
     - Descriptions to help users choose

3. **No admin endpoints for testing**
   - Admins couldn't test if their API keys were valid
   - No way to see available models before users tried to access them

## Solution Implementation

### 1. Backend Changes

#### A. Created Admin-Only Model Discovery Endpoints

**File: `/Users/scawful/Code/halext-org/backend/app/admin_routes.py`**

Added two new endpoints for admins to poll cloud provider APIs:

```python
GET /admin/ai/models/openai
GET /admin/ai/models/gemini
```

These endpoints:
- Require admin authentication
- Fetch models directly from OpenAI/Gemini APIs using stored credentials
- Return enriched model metadata including:
  - Model ID and name
  - Description
  - Context window (tokens)
  - Max output tokens
  - Cost per 1M tokens (input/output)
  - Vision support
  - Function calling support
  - Provider ownership info

#### B. Created Model Metadata Module

**File: `/Users/scawful/Code/halext-org/backend/app/model_metadata.py`**

Centralized metadata for all cloud models including:

**OpenAI Models:**
- `gpt-4o`: 128K context, $5/$15 per 1M tokens, vision support
- `gpt-4o-mini`: 128K context, $0.15/$0.60 per 1M tokens, vision support
- `gpt-4-turbo`: 128K context, $10/$30 per 1M tokens, vision support
- `gpt-4`: 8K context, $30/$60 per 1M tokens
- `gpt-3.5-turbo`: 16K context, $0.50/$1.50 per 1M tokens

**Gemini Models:**
- `gemini-1.5-pro`: 2M context, $1.25/$5.00 per 1M tokens, vision support
- `gemini-1.5-flash`: 1M context, $0.075/$0.30 per 1M tokens, vision support
- `gemini-1.0-pro`: 32K context, $0.50/$1.50 per 1M tokens
- `gemini-2.0-flash-exp`: 1M context, FREE (experimental), vision support

#### C. Enhanced Existing `/ai/models` Endpoint

**File: `/Users/scawful/Code/halext-org/backend/app/ai.py`**

Updated `_list_provider_models()` to:
1. Call provider's `list_models()` method
2. Enrich each model with metadata using the new helpers
3. Return complete model information to all users (not just admins)

#### D. Updated Response Schema

**File: `/Users/scawful/Code/halext-org/backend/app/schemas.py`**

Extended `AiModelInfo` with:
```python
description: Optional[str]
context_window: Optional[int]
max_output_tokens: Optional[int]
input_cost_per_1m: Optional[float]
output_cost_per_1m: Optional[float]
supports_vision: Optional[bool]
supports_function_calling: Optional[bool]
```

### 2. iOS Changes

#### A. Updated AIModel Struct

**File: `/Users/scawful/Code/halext-org/ios/Cafe/Core/API/APIClient+AI.swift`**

Added properties and computed helpers:
- All new metadata fields
- `tierLabel`: Categorizes models as Lightweight/Standard/Premium
- `costDescription`: Formats pricing for display
- `contextWindowFormatted`: Formats token counts (e.g., "128K tokens", "2M tokens")

#### B. Enhanced Model Picker UI

**File: `/Users/scawful/Code/halext-org/ios/Cafe/Features/Settings/AIModelPickerView.swift`**

Now displays:
1. **Tier badge** (color-coded: Green=Lightweight, Blue=Standard, Purple=Premium)
2. **Model description** (helps users understand use cases)
3. **Context window** (shows token capacity)
4. **Pricing** (input/output costs or "Free during preview")
5. **Capabilities** (vision and function calling icons)
6. **Node info** (for distributed Ollama models)

## Model Recommendations

### For Testing / Development (Low Cost)
- **OpenAI**: `gpt-3.5-turbo` - Fast, cheap, good for prototyping
- **Gemini**: `gemini-1.5-flash` - Very fast, ultra-low cost

### For Production (Balanced)
- **OpenAI**: `gpt-4o-mini` - Best price/performance, vision support
- **Gemini**: `gemini-1.5-pro` - Huge context window (2M tokens), strong reasoning

### For Premium Tasks (High Quality)
- **OpenAI**: `gpt-4o` - Most advanced, multimodal
- **Gemini**: `gemini-exp-1206` - Experimental, cutting-edge (free during preview)

## Testing the Fix

### Backend Testing

1. **Test OpenAI endpoint**:
```bash
# As admin user with token
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
     http://localhost:8000/admin/ai/models/openai
```

Expected response:
```json
{
  "provider": "openai",
  "models": [
    {
      "id": "gpt-4o-mini",
      "name": "gpt-4o-mini",
      "description": "Affordable and intelligent small model for fast, lightweight tasks",
      "context_window": 128000,
      "max_output_tokens": 16384,
      "input_cost_per_1m": 0.15,
      "output_cost_per_1m": 0.60,
      "supports_vision": true,
      "supports_function_calling": true
    }
  ],
  "total_count": 8,
  "credentials_configured": true
}
```

2. **Test Gemini endpoint**:
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
     http://localhost:8000/admin/ai/models/gemini
```

3. **Test regular user endpoint**:
```bash
curl -H "Authorization: Bearer YOUR_USER_TOKEN" \
     http://localhost:8000/ai/models
```

This should now include OpenAI and Gemini models with full metadata.

### iOS Testing

1. **Launch the app** and navigate to Settings > AI Settings
2. **Tap "AI Model"** - The model picker should load
3. **Verify models appear** - You should see:
   - OpenAI models (if key configured)
   - Gemini models (if key configured)
   - Local Ollama models (if available)
4. **Check metadata display**:
   - Each model shows a tier badge
   - Descriptions are visible
   - Context windows shown (e.g., "128K tokens")
   - Costs displayed (e.g., "$0.15/$0.60 per 1M tokens")
   - Capability icons (vision, functions) appear
5. **Select a model** - Should save and display in settings

### Error Scenarios

#### No API Keys Configured
- Backend returns empty model list with `credentials_configured: false`
- iOS shows "No Models Available" with retry button

#### Invalid API Key
- Backend returns error: `"error": "Incorrect API key provided"`
- iOS shows error state with retry option

#### Network Error
- Backend times out or fails
- iOS shows offline state, keeps cached models

## API Reference

### Admin Endpoints

#### GET /admin/ai/models/openai
Fetch available OpenAI models

**Auth**: Admin required

**Response**:
```typescript
{
  provider: "openai",
  models: CloudModelInfo[],
  total_count: number,
  credentials_configured: boolean,
  error?: string
}
```

#### GET /admin/ai/models/gemini
Fetch available Gemini models

**Auth**: Admin required

**Response**: Same as OpenAI endpoint

### User Endpoints

#### GET /ai/models
List all available AI models (includes enriched cloud models)

**Auth**: User required

**Response**:
```typescript
{
  models: AiModelInfo[],
  provider: string,
  current_model: string,
  default_model_id?: string
}
```

## Cost Comparison (as of 2025)

| Model | Input ($/1M tokens) | Output ($/1M tokens) | Context Window | Best For |
|-------|-------------------|---------------------|---------------|----------|
| gpt-3.5-turbo | $0.50 | $1.50 | 16K | Quick tasks, testing |
| gpt-4o-mini | $0.15 | $0.60 | 128K | Production, balanced |
| gpt-4o | $5.00 | $15.00 | 128K | Complex reasoning |
| gemini-1.5-flash | $0.075 | $0.30 | 1M | Fast, cheap, huge context |
| gemini-1.5-pro | $1.25 | $5.00 | 2M | Premium, massive context |
| gemini-2.0-flash | FREE | FREE | 1M | Experimental features |

## Known Limitations

1. **Model list caching**: The iOS app caches the model list. To refresh, users must:
   - Pull to refresh in the model picker
   - Or restart the app

2. **Admin-only polling**: Only admins can use `/admin/ai/models/*` endpoints
   - Regular users see models via `/ai/models` which is populated by backend

3. **Cost data maintenance**: Pricing info is hardcoded and must be updated when providers change prices

4. **Rate limits**: Polling OpenAI/Gemini APIs too frequently may hit rate limits
   - Implement caching or rate limiting if needed

## Future Enhancements

1. **Model benchmarks**: Add performance metrics (speed, quality scores)
2. **Usage tracking**: Show which models users are actually using
3. **Cost calculator**: Estimate costs based on expected usage
4. **Smart recommendations**: Suggest models based on task type
5. **Model health monitoring**: Track which models are responding well
6. **Auto-refresh**: Periodically refresh model list in background

## Troubleshooting

### Models still not showing
1. Check admin panel: Are API keys saved correctly?
2. Check backend logs: Any errors calling OpenAI/Gemini APIs?
3. Test endpoints manually with curl
4. Verify database has provider credentials
5. Check iOS logs for API errors

### Wrong models appearing
1. Verify provider credentials are for correct account
2. Check if you have access to specific models (some are beta-only)
3. Clear app data and re-authenticate

### Pricing/metadata incorrect
1. Update `/Users/scawful/Code/halext-org/backend/app/model_metadata.py`
2. Verify against official provider pricing pages:
   - OpenAI: https://openai.com/pricing
   - Gemini: https://ai.google.dev/pricing

## Files Changed

### Backend
- `/backend/app/admin_routes.py` - Added model polling endpoints
- `/backend/app/model_metadata.py` - Created metadata helpers (NEW FILE)
- `/backend/app/ai.py` - Enhanced model enrichment
- `/backend/app/schemas.py` - Extended AiModelInfo schema
- `/backend/app/ai_providers.py` - Already had list_models() methods (NO CHANGE)

### iOS
- `/ios/Cafe/Core/API/APIClient+AI.swift` - Enhanced AIModel struct
- `/ios/Cafe/Features/Settings/AIModelPickerView.swift` - Improved UI with metadata
- `/ios/Cafe/App/AppState.swift` - Already had model loading (NO CHANGE)

### Documentation
- `/docs/AI_MODEL_SELECTOR_FIX.md` - This file (NEW)

## Summary

The fix successfully:
1. ✅ Enables model polling from OpenAI and Gemini APIs
2. ✅ Enriches models with context windows, costs, and capabilities
3. ✅ Provides admin endpoints for testing API key validity
4. ✅ Updates iOS UI to display comprehensive model information
5. ✅ Helps users make informed model choices with tier badges and descriptions
6. ✅ Maintains backward compatibility with Ollama/OpenWebUI models

Users can now see and select cloud AI models after configuring API keys in the admin panel.

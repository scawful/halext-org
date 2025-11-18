# Cafe AI Architecture

## Overview

Cafe uses a **distributed AI system** where multiple machines can serve AI models to the central server. This architecture is designed to:

1. **Minimize server load**: The lightweight VM (2 vCPU, 2GB RAM) delegates AI inference to more powerful clients
2. **Support multiple providers**: OpenAI, Google Gemini, local Ollama instances, and Open WebUI
3. **User-level API keys**: Each user can configure their own API keys for cloud providers
4. **Hybrid model serving**: Use cloud models when available, fall back to local models

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Cafe Backend (VM)                       │
│                  2 vCPU, 2GB RAM, Ubuntu                    │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐ │
│  │           Enhanced AI Gateway                         │ │
│  │  - Routes requests to appropriate provider            │ │
│  │  - Manages user API keys (encrypted)                  │ │
│  │  - Handles streaming and embeddings                   │ │
│  └───────────────────────────────────────────────────────┘ │
│                          ↓                                  │
│     ┌──────────┬─────────────┬──────────┬─────────────┐   │
│     ↓          ↓             ↓          ↓             ↓   │
└─────────────────────────────────────────────────────────────┘
      │          │             │          │             │
      │          │             │          │             │
┌─────┴──┐  ┌────┴─────┐  ┌───┴────┐  ┌──┴──────┐  ┌──┴────────┐
│ OpenAI │  │  Gemini  │  │ Ollama │  │OpenWebUI│  │   Mock    │
│  API   │  │   API    │  │ (local)│  │ (local) │  │ (fallback)│
└────────┘  └──────────┘  └────────┘  └─────────┘  └───────────┘
   Cloud        Cloud       Client      Client       Development
```

## Client Nodes

### macOS Client (Your Mac M1)
- **Role**: Primary local LLM server when Mac is running
- **Models**: Larger models (70B, etc.) via Ollama or llama.cpp
- **Connection**: HTTP to VM's backend
- **Auto-start**: Launch agent runs when Mac boots

### Windows Client (RTX 5060 Ti 16GB)
- **Role**: GPU-accelerated inference node
- **Models**: CUDA-optimized models via Ollama
- **Connection**: HTTP to VM's backend
- **Setup**: Windows service or startup script

### Open WebUI Instance
- **Role**: Central model router with UI
- **Features**: Model management, chat history, SSO with Cafe
- **Connection**: Shared between all clients

## Provider Types

### 1. Cloud Providers (API Key Required)

#### OpenAI / ChatGPT
```python
# Environment (server-level fallback)
AI_PROVIDER=openai
AI_MODEL=gpt-4o-mini
OPENAI_API_KEY=sk-...

# User-level configuration (preferred)
# Users add their own API keys via Cafe settings
```

**Models**: GPT-4o, GPT-4o-mini, GPT-3.5-turbo

**Cost**: Pay-per-token
- GPT-4o-mini: ~$0.15/1M input tokens, ~$0.60/1M output tokens
- GPT-4o: ~$2.50/1M input tokens, ~$10/1M output tokens

**Best for**: General-purpose chat, complex reasoning, function calling

#### Google Gemini
```python
# Environment
AI_PROVIDER=gemini
AI_MODEL=gemini-1.5-flash
GEMINI_API_KEY=...

# User-level via API key management
```

**Models**: Gemini 1.5 Flash, Gemini 1.5 Pro

**Cost**: Free tier available, then pay-per-token
- Flash: ~$0.075/1M input tokens, ~$0.30/1M output tokens
- Pro: ~$1.25/1M input tokens, ~$5/1M output tokens

**Best for**: Long context tasks, multimodal (can handle images)

### 2. Local/Self-Hosted Providers (Free)

#### Ollama (Recommended for Clients)
```python
# Environment
AI_PROVIDER=ollama
OLLAMA_URL=http://your-mac.local:11434
AI_MODEL=llama3.1

# Or user-level provider config
```

**Models**: Llama 3.1, Mistral, Qwen, Gemma, etc.

**Requirements**:
- macOS: 8GB RAM minimum (16GB recommended for 70B models)
- Windows: NVIDIA GPU with CUDA support

**Setup**: See [macOS Agent Setup](#macos-agent-setup)

#### Open WebUI
```python
AI_PROVIDER=openwebui
OPENWEBUI_URL=http://your-server:3000
AI_MODEL=llama3.1
```

**Features**:
- Web UI for model management
- Conversation history
- User authentication
- SSO with Cafe (via OpenWebUISync)

## API Key Management

### User Flow

1. **User logs into Cafe**
2. **Navigate to Settings → AI Providers**
3. **Add API Key**:
   - Select provider (OpenAI, Gemini)
   - Enter friendly name ("My OpenAI Key")
   - Paste API key
   - Key is encrypted and stored
4. **Configure Provider**:
   - Select provider type
   - Choose API key (if cloud)
   - Select default model
   - Mark as default (optional)
5. **Use AI Features**:
   - Chat uses user's configured provider
   - Task suggestions use user's configured provider
   - Falls back to server default if no user config

### Security

- **Encryption at Rest**: API keys encrypted using Fernet (AES-128)
- **Encryption Key**: Derived from `API_KEY_ENCRYPTION_KEY` env var
- **Access Control**: Users can only access their own API keys
- **Masked Display**: Keys shown as `sk-...xyz123` in UI
- **Audit Trail**: `last_used_at` timestamp tracked

### API Endpoints

```python
# Add API key
POST /api/ai/api-keys
{
  "provider": "openai",
  "key_name": "My OpenAI Key",
  "api_key": "sk-..."
}

# List user's API keys
GET /api/ai/api-keys
# Returns masked keys: sk-****xyz123

# Delete API key
DELETE /api/ai/api-keys/{key_id}

# Configure AI provider
POST /api/ai/provider-config
{
  "provider_type": "openai",
  "api_key_id": 123,
  "config": {
    "model": "gpt-4o-mini",
    "temperature": 0.7,
    "max_tokens": 2000
  },
  "is_default": true
}

# Get user's provider configs
GET /api/ai/provider-configs
```

## macOS Agent Setup

### Install Ollama

```bash
# Install via Homebrew
brew install ollama

# Or download from https://ollama.ai

# Pull models
ollama pull llama3.1
ollama pull mistral
```

### Create Launch Agent

Create `~/Library/LaunchAgents/org.halext.ollama.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.halext.ollama</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/Library/Logs/ollama.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/Library/Logs/ollama.error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
        <key>OLLAMA_ORIGINS</key>
        <string>*</string>
    </dict>
</dict>
</plist>
```

### Load and Start

```bash
# Load the agent
launchctl load ~/Library/LaunchAgents/org.halext.ollama.plist

# Start now
launchctl start org.halext.ollama

# Check status
launchctl list | grep ollama

# View logs
tail -f ~/Library/Logs/ollama.log
```

### Configure Firewall

```bash
# Allow Ollama through macOS firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/local/bin/ollama
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/local/bin/ollama
```

### Point Cafe Backend to Mac

On your Ubuntu server:

```bash
# Add to .env or environment
export OLLAMA_URL=http://your-mac.local:11434
export AI_PROVIDER=ollama
export AI_MODEL=llama3.1
```

## Windows Agent Setup

### Install Ollama

1. Download from https://ollama.ai/download/windows
2. Install and run
3. Open PowerShell as Administrator:

```powershell
# Pull models
ollama pull llama3.1
ollama pull mistral

# Configure to listen on all interfaces
$env:OLLAMA_HOST = "0.0.0.0:11434"
$env:OLLAMA_ORIGINS = "*"

# Create Windows service
sc.exe create OllamaService binPath= "C:\Program Files\Ollama\ollama.exe serve" start= auto
sc.exe start OllamaService
```

### Configure Windows Firewall

```powershell
# Allow Ollama through Windows Firewall
New-NetFirewallRule -DisplayName "Ollama" -Direction Inbound -Protocol TCP -LocalPort 11434 -Action Allow
```

## iOS App Integration

The iOS app uses the same API endpoints as the web interface. Key patterns:

### 1. API Key Management (iOS)

```swift
// In APIClient.swift
func addAPIKey(provider: String, keyName: String, apiKey: String) async throws {
    let payload = [
        "provider": provider,
        "key_name": keyName,
        "api_key": apiKey
    ]

    let request = try authorizedRequest(path: "/api/ai/api-keys", method: "POST")
    request.httpBody = try JSONEncoder().encode(payload)

    return try await performRequest(request)
}

func getAPIKeys() async throws -> [APIKeyInfo] {
    let request = try authorizedRequest(path: "/api/ai/api-keys", method: "GET")
    return try await performRequest(request)
}
```

### 2. Provider Configuration (iOS)

```swift
func configureAIProvider(
    providerType: String,
    apiKeyId: Int?,
    config: [String: Any],
    isDefault: Bool
) async throws {
    let payload: [String: Any] = [
        "provider_type": providerType,
        "api_key_id": apiKeyId as Any,
        "config": config,
        "is_default": isDefault
    ]

    var request = try authorizedRequest(path: "/api/ai/provider-configs", method: "POST")
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)

    return try await performRequest(request)
}
```

### 3. Using AI Features (iOS)

The existing AI endpoints remain the same - the backend automatically uses the user's configured provider:

```swift
// Task suggestions - uses user's configured provider
func getTaskSuggestions(title: String, description: String?) async throws -> AITaskSuggestions {
    // No changes needed - backend handles provider selection
    let suggestionRequest = AITaskSuggestionsRequest(title: title, description: description)
    var request = try authorizedRequest(path: "/ai/tasks/suggest", method: "POST")
    request.httpBody = try JSONEncoder().encode(suggestionRequest)
    return try await performRequest(request)
}

// AI Chat - uses user's configured provider
func sendChatMessage(prompt: String, history: [ChatMessage] = []) async throws -> AIChatResponse {
    let chatRequest = AIChatRequest(prompt: prompt, history: history)
    var request = try authorizedRequest(path: "/ai/chat", method: "POST")
    request.httpBody = try JSONEncoder().encode(chatRequest)
    return try await performRequest(request)
}
```

## Provider Selection Logic

```python
def get_user_ai_provider(user_id: int, db: Session) -> AIProvider:
    """
    Get the appropriate AI provider for a user
    Priority:
    1. User's default configured provider
    2. User's first active provider
    3. Server default (environment variables)
    4. Mock provider (development)
    """

    # Check for user's configured provider
    config = db.query(AIProviderConfig).filter(
        AIProviderConfig.owner_id == user_id,
        AIProviderConfig.is_default == True
    ).first()

    if config:
        return create_provider_from_config(config, db)

    # Fall back to server default
    provider_type = os.getenv("AI_PROVIDER", "mock")
    if provider_type == "openai":
        api_key = os.getenv("OPENAI_API_KEY")
        return OpenAIProvider(api_key, os.getenv("AI_MODEL", "gpt-4o-mini"))
    # ... etc
```

## Cost Optimization

### Recommended Strategy

1. **Free Tier First**: Use Gemini's free tier for casual users
2. **Local for Power Users**: Encourage technical users to run Ollama
3. **Paid for Premium**: Offer GPT-4o as premium feature
4. **Server Fallback**: Keep a small OpenAI credit for system features

### Usage Limits

```python
# Implement per-user rate limits
class UserAIQuota(Base):
    __tablename__ = "user_ai_quota"

    user_id = Column(Integer, ForeignKey("users.id"))
    provider = Column(String)
    requests_today = Column(Integer, default=0)
    last_reset = Column(DateTime)
    monthly_limit = Column(Integer, default=1000)  # requests
```

## Monitoring

Track AI usage:

```python
# Log each AI request
class AIUsageLog(Base):
    __tablename__ = "ai_usage_logs"

    user_id = Column(Integer, ForeignKey("users.id"))
    provider = Column(String)
    model = Column(String)
    prompt_tokens = Column(Integer)
    completion_tokens = Column(Integer)
    cost_estimate = Column(Float)
    created_at = Column(DateTime)
```

## Future Enhancements

1. **Load Balancing**: Distribute requests across multiple Ollama instances
2. **Model Router**: Automatically select cheapest/fastest model for task
3. **Caching**: Cache common responses to reduce API calls
4. **Fine-tuning**: Train custom models on user data (privacy-preserving)
5. **Multi-modal**: Add support for image generation (DALL-E, Stable Diffusion)

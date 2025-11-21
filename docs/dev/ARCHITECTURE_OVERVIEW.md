# Halext.org Architecture Overview

**Personal AI Infrastructure with Distributed Computing**

## Executive Summary

Halext.org is a personal AI assistant platform that uses **distributed computing** to delegate resource-intensive AI workloads from a lightweight cloud server to powerful home machines. This architecture allows you to run large language models on your own hardware while maintaining a public web interface.

```
┌─────────────────────────────────────────────────────────┐
│                    Internet Users                       │
│              (https://org.halext.org)                   │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ HTTPS
                         │
┌────────────────────────▼────────────────────────────────┐
│              Ubuntu Cloud Server (2GB RAM)              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Nginx Reverse Proxy + SSL/TLS                   │  │
│  └─────────────┬────────────────┬────────────────────┘  │
│                │                │                        │
│    ┌───────────▼──────┐   ┌────▼─────────────┐         │
│    │ FastAPI Backend  │   │  React Frontend  │         │
│    │   (Python)       │   │   (TypeScript)   │         │
│    │                  │   │                  │         │
│    │ • Auth & Users   │   │ • Admin Panel    │         │
│    │ • AI Routing     │   │ • Task Manager   │         │
│    │ • Admin API      │   │ • Chat UI        │         │
│    └───────────┬──────┘   └──────────────────┘         │
│                │                                         │
│    ┌───────────▼──────┐                                 │
│    │  PostgreSQL DB   │                                 │
│    │ • Users & Auth   │                                 │
│    │ • AI Nodes       │                                 │
│    │ • Tasks & Data   │                                 │
│    └──────────────────┘                                 │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ HTTP/API Calls
                         │ (via port forwarding)
                         │
          ┌──────────────┴───────────────┐
          │                              │
┌─────────▼──────────┐       ┌──────────▼─────────┐
│   Home Network     │       │   Home Network     │
│  (Mac M1 Studio)   │       │  (Windows Gaming)  │
│                    │       │                    │
│  Ollama Server     │       │  Ollama Server     │
│  Port: 11434       │       │  Port: 11434       │
│                    │       │                    │
│  Models:           │       │  Models:           │
│  • qwen2.5-coder   │       │  • CUDA-optimized  │
│  • llama3          │       │  • Stable Diffusion│
│  • mistral         │       │  • (Coming soon)   │
│  • deepseek-r1     │       │                    │
│  32GB RAM          │       │  RTX 5060 Ti 16GB  │
└────────────────────┘       └────────────────────┘
```

---

## Core Components

### 1. Cloud Server (Ubuntu VPS)
**Role:** Public-facing coordinator & web interface

**Specifications:**
- 2 vCPU, 2GB RAM, 64GB SSD
- **Does NOT run AI models** (not enough resources)
- Acts as reverse proxy and request router

**Services:**
- **Nginx** - Reverse proxy, SSL termination
- **FastAPI Backend** - API server, authentication, AI routing
- **PostgreSQL** - User data, AI node registry, task management
- **React Frontend** - Admin panel, task manager, chat interface

**Why this works:**
- Lightweight coordination doesn't need much RAM
- Delegates heavy AI workload to home machines
- Always online, public IP, managed hosting

---

### 2. Home AI Nodes (Mac, Windows PC)

**Role:** Heavy-lifting AI compute engines

**Mac M1 Studio:**
- 32GB unified memory
- Neural Engine for AI acceleration
- Runs Ollama with 9+ models
- Exposed via port forwarding (port 11434)

**Windows Gaming PC (Future):**
- RTX 5060 Ti 16GB VRAM
- CUDA acceleration
- Image generation (Stable Diffusion)
- Exposed via port forwarding (port 11435)

**Why this approach:**
- Leverage existing powerful hardware
- No cloud GPU costs ($$$)
- Privacy - models run on your hardware
- Expandable - add more nodes as needed

---

### 3. Admin Panel (New!)

**Location:** https://org.halext.org/admin

**Features:**
- **Node Management** - Add/remove AI client nodes
- **Health Monitoring** - Real-time status of each node
- **Model Discovery** - See which models are loaded where
- **Connection Testing** - Verify network connectivity
- **Remote Deployment** - Rebuild frontend from admin panel

**Access Control:**
- Admin-only endpoint (user ID 1 or username "scawful")
- JWT token authentication
- Can be extended to role-based access

---

## Data Flow

### Example: User Sends Chat Message

```
1. User → https://org.halext.org/chat
   │
2. React Frontend → POST /api/chat
   │
3. FastAPI Backend:
   │ - Validates JWT token
   │ - Queries available AI nodes
   │ - Selects best node (lowest latency, has required model)
   │
4. Backend → http://YOUR_PUBLIC_IP:11434/api/generate
   │ (Mac Ollama via port forwarding)
   │
5. Mac Ollama:
   │ - Loads qwen2.5-coder:14b
   │ - Generates response
   │ - Returns JSON
   │
6. Backend → Streams response to frontend
   │
7. User sees AI response in real-time
```

---

## Network Architecture

### Current Setup: Port Forwarding

```
Internet
   │
   │ HTTPS (443)
   ▼
Ubuntu Cloud Server (144.202.52.126)
   │
   │ HTTP (via public IP + port)
   │ YOUR_PUBLIC_IP:11434
   ▼
Verizon 5G Router
   │ Port Forward: 11434 → 192.168.1.204:11434
   ▼
Mac M1 Studio (192.168.1.204)
   │
   └─ Ollama listening on 0.0.0.0:11434
```

**Pros:**
- Simple setup
- Direct connection (low latency)
- No additional services

**Cons:**
- Exposes Ollama to internet (security risk)
- Requires router configuration
- Public IP may change (need DDNS)

### Recommended: Cloudflare Tunnel (Future)

```
Internet
   │
   ▼
Cloudflare Network
   │ Encrypted Tunnel
   ▼
Mac M1 Studio (cloudflared daemon)
   │
   └─ Ollama on localhost:11434
```

**Pros:**
- No port forwarding needed
- Encrypted by default
- DDoS protection
- Free SSL certificate
- Access control built-in

**Cons:**
- Additional service to run
- Slight latency increase

---

## Database Schema

### Key Tables

**users**
- Authentication and user profiles
- JWT token management

**ai_client_nodes**
- Registry of available AI nodes
- Health status tracking
- Capabilities (models, GPU, memory)
- Connection details (hostname, port)

**api_keys** (Encrypted)
- Encrypted API keys for external services
- User-specific configurations

**tasks**
- Task management
- AI-assisted task suggestions
- Priority and status tracking

---

## Security Model

### 1. Authentication Layer
```python
User Login → JWT Token → Bearer Token in Headers
```

### 2. Admin Access Control
```python
@router.get("/admin/...")
def admin_endpoint(
    current_user = Depends(get_current_admin_user)
):
    # Only admin users can access
```

### 3. API Key Encryption
```python
from cryptography.fernet import Fernet

# Keys encrypted at rest with Fernet
encrypted_key = fernet.encrypt(api_key.encode())
```

### 4. Network Security

**Current:**
- Ollama exposed on public IP (⚠️ security risk)
- Should add IP allowlisting
- Consider VPN or Cloudflare Tunnel

**Best Practice:**
```python
# In ai_client_manager.py
ALLOWED_IPS = ["144.202.52.126"]  # Ubuntu server only

if request.client.host not in ALLOWED_IPS:
    raise HTTPException(403, "Forbidden")
```

---

## Scaling Strategy

### Current Limits
- **Ubuntu Server:** 2GB RAM (maxed out)
- **Mac:** 9 models loaded, can handle ~5 concurrent requests
- **Windows:** Not yet configured

### Future Scaling Options

**Horizontal Scaling (Add More Nodes):**
```
Cloud Server
   ├─ Mac M1 Studio
   ├─ Windows Gaming PC
   ├─ Mac Mini (M4)
   └─ Cloud GPU Instance (when needed)
```

**Load Balancing:**
```python
async def select_best_node(
    model_name: str,
    nodes: List[AIClientNode]
) -> AIClientNode:
    # Filter nodes that have the model
    capable_nodes = [n for n in nodes if model_name in n.capabilities["models"]]

    # Sort by response time
    return sorted(capable_nodes, key=lambda n: n.capabilities["last_response_time_ms"])[0]
```

**Caching Layer:**
```
Redis Cache
   ├─ Common prompts (TTL: 1 hour)
   ├─ Model metadata (TTL: 5 minutes)
   └─ Response deduplication
```

---

## Cost Analysis

### Current Setup (Monthly)

| Component | Provider | Cost |
|-----------|----------|------|
| Ubuntu VPS (2GB) | Vultr/DigitalOcean | $12 |
| Domain (halext.org) | Namecheap | $1 |
| SSL Certificate | Let's Encrypt | Free |
| Mac M1 Studio | Home (electricity) | ~$5 |
| **Total** | | **~$18/mo** |

### vs Cloud GPU Alternative

| Component | Provider | Cost |
|-----------|----------|------|
| Server + A100 GPU | Runpod/Lambda | $600+ |
| Storage | | $50 |
| Data Transfer | | $20 |
| **Total** | | **$670+/mo** |

**Savings: $652/month** or **$7,824/year** by using home hardware!

---

## Performance Metrics

### Mac M1 Studio (qwen2.5-coder:14b)
- **Cold Start:** ~3 seconds (model loading)
- **Warm Response:** 15-30 tokens/sec
- **Memory Usage:** ~12GB per active model
- **Concurrent Requests:** 3-5 before slowdown

### Ubuntu Server
- **API Response Time:** <50ms (without AI)
- **Database Queries:** <10ms
- **Static Assets:** <100ms (via CDN recommended)

---

## Monitoring & Observability

### Current State
- Basic health checks in admin panel
- Last seen timestamps
- Response time tracking

### Recommended Additions

**1. Prometheus + Grafana**
```yaml
metrics:
  - request_count
  - response_time_p95
  - active_connections
  - model_usage_by_type
  - node_availability
```

**2. Alerting**
```python
# Webhook to Slack/Discord when:
- Node offline > 5 minutes
- Error rate > 10%
- Response time > 10 seconds
- Disk usage > 90%
```

**3. Logging**
```python
import structlog

logger = structlog.get_logger()
logger.info(
    "ai_request",
    user_id=user.id,
    model="qwen2.5-coder",
    node_id=node.id,
    latency_ms=response_time
)
```

---

## Development Workflow

### Local Development
```bash
# Backend
cd backend
python -m venv env
source env/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload

# Frontend
cd frontend
npm install
npm run dev
```

### Deployment to Ubuntu
```bash
# Automated deployment script
./scripts/deploy-to-ubuntu.sh

# Manual steps:
ssh halext@YOUR_SERVER
cd /srv/halext.org/halext-org
git pull origin main
cd backend && source env/bin/activate && pip install -r requirements.txt
cd ../frontend && npm run build
sudo systemctl restart halext-backend nginx
```

---

## Technology Stack

### Backend
- **Python 3.8+**
- **FastAPI** - Modern async web framework
- **SQLAlchemy** - ORM for PostgreSQL
- **Pydantic** - Data validation
- **python-jose** - JWT tokens
- **httpx** - Async HTTP client for AI node communication
- **passlib** - Password hashing

### Frontend
- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Fast build tool
- **React Icons** - Icon library
- **CSS Modules** - Component styling

### Infrastructure
- **Nginx** - Reverse proxy & SSL
- **PostgreSQL** - Primary database
- **Ollama** - LLM runtime on nodes
- **systemd** - Service management

---

## Future Enhancements

### Short Term (1-2 months)
1. **Cloudflare Tunnel** - Replace port forwarding
2. **Redis Caching** - Speed up repeated queries
3. **Windows Node** - Add GPU image generation
4. **Monitoring Dashboard** - Real-time metrics

### Medium Term (3-6 months)
5. **Queue System** - Celery for background jobs
6. **Model Fine-Tuning** - Custom model training
7. **API Gateway** - OpenAI-compatible endpoint
8. **Multi-User Support** - User workspaces & quotas

### Long Term (6-12 months)
9. **Mobile App** - React Native
10. **Auto-Scaling** - Add/remove nodes based on load
11. **Marketplace** - Share compute with others (Airbnb for GPU)
12. **Edge Deployment** - Run models on iOS devices

---

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

## Related Documentation

- [Quickstart Guide](QUICKSTART.md) - Get running in 15 minutes
- [Ollama Setup Guide](../ai/OLLAMA_SETUP.md) - Detailed node setup (local network + remote/exposed)
- [Port Forwarding Guide](../PORT_FORWARDING_GUIDE.md) - Router configuration
- [Emergency Recovery](EMERGENCY_SERVER_RECOVERY.md) - When things go wrong
- [API Reference](API_REFERENCE.md) - Backend API documentation (TODO)

---

**Last Updated:** 2025-11-18
**Version:** 1.0.0
**Maintainer:** scawful

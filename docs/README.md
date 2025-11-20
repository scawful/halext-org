# Documentation Index

The documentation set is grouped so you can jump directly to the area you need:

## Development Guides (`docs/dev/`)
- [LOCAL_DEVELOPMENT.md](dev/LOCAL_DEVELOPMENT.md) – macOS dev workflow, launchd helpers, troubleshooting tips.
- [SETUP_OVERVIEW.md](dev/SETUP_OVERVIEW.md) – initial environment prep and dependencies.
- [QUICKSTART.md](dev/QUICKSTART.md) – five-minute path to running the stack locally.
- [ARCHITECTURE_OVERVIEW.md](dev/ARCHITECTURE_OVERVIEW.md) – high-level system design.
- [PLANNING.md](dev/PLANNING.md) & [USER_GUIDE.md](dev/USER_GUIDE.md) – roadmap notes plus UX walkthroughs.
- [GEMINI.md](dev/GEMINI.md) – coding standards distilled from Gemini sessions.

## Operations & Infrastructure (`docs/ops/`)
- [AGENTS.md](ops/AGENTS.md) – production runbook and SSH/Nginx references.
- [DEPLOYMENT.md](ops/DEPLOYMENT.md) + [DEPLOYMENT_CHECKLIST.md](ops/DEPLOYMENT_CHECKLIST.md) – bootstrap + recurring deploy flow.
- [PORT_FORWARDING_GUIDE.md](ops/PORT_FORWARDING_GUIDE.md) – exposing remote Ollama boxes.
- [SERVER_FIELD_GUIDE.md](ops/SERVER_FIELD_GUIDE.md), [SERVER_MONITORING.md](ops/SERVER_MONITORING.md), [SERVER_ALIGNMENT_PLAN.md](ops/SERVER_ALIGNMENT_PLAN.md) – day-to-day administration.
- [EMERGENCY_SERVER_RECOVERY.md](ops/EMERGENCY_SERVER_RECOVERY.md), [TROUBLESHOOTING.md](ops/TROUBLESHOOTING.md) – incident playbooks.
- [MIGRATION_PRESETS.md](ops/MIGRATION_PRESETS.md), [CDN_FAILOVER_PLAN.md](ops/CDN_FAILOVER_PLAN.md), [`nginx-config-example.conf`](ops/nginx-config-example.conf) – reference snippets.

## AI Infrastructure (`docs/ai/`)
- [AI_ARCHITECTURE.md](ai/AI_ARCHITECTURE.md) – distributed model hub design.
- [AI_ROUTING_IMPLEMENTATION_PLAN.md](ai/AI_ROUTING_IMPLEMENTATION_PLAN.md) & [AI_ROUTING_ROADMAP.md](ai/AI_ROUTING_ROADMAP.md) – current rollout tasks.
- [DISTRIBUTED_OLLAMA_SETUP.md](ai/DISTRIBUTED_OLLAMA_SETUP.md), [REMOTE_OLLAMA_SETUP.md](ai/REMOTE_OLLAMA_SETUP.md) – client compute onboarding.
- [CONNECTING_MAC_TO_UBUNTU.md](ai/CONNECTING_MAC_TO_UBUNTU.md), [OPENWEBUI_SETUP.md](ai/OPENWEBUI_SETUP.md) – tunnels, OpenWebUI automation, best practices.

## iOS & Product Integrations (`docs/ios/`)
- [IOS_DEVELOPMENT_PLAN.md](ios/IOS_DEVELOPMENT_PLAN.md) – native roadmap.
- [ZENIEA_ZEN3MP_INTEGRATION.md](ios/ZENIEA_ZEN3MP_INTEGRATION.md) – cross-product notes.

Each file keeps its original title/content; only the paths changed so the repo root stays tidy. Update this index whenever you add a new long-form guide.

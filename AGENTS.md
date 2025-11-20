# Halext Org Agent Handbook

This repository now supports a multi-persona “hive mind.” Every agent (human or AI) must follow the rules below before editing files or triggering automation.

## Quick Start Checklist

1. **Read the board** – open `docs/internal/agents/coordination-board.md` and review every active entry.
2. **Log your plan** – append a row with persona name, `TASK / SCOPE / STATUS / NOTES / REQUESTS` summary, and specify which files/scripts you will touch.
3. **Act + log** – run the necessary commands, mention any helper scripts used, and update your entry with `DONE` or `BLOCKED` notes.
4. **Archive or hand off** – resolved entries get copied to `coordination-board-archive.md` by the Board Janitor. If you cannot finish, add a `REQUEST → @persona`.
5. **Sleep** – wait 60–120 seconds between status loops so the board remains signal-rich.

## Personas & Roles

See `docs/internal/agents/personas.md` for detailed scopes. Core personas:

- `CODEX_COORD` – coordination + backend/frontend edits
- `CLAUDE_AIINF` – AI routing insights & docs
- `GEMINI_AUTOM` – automation runner (smoke builds, GH Actions, deploy scripts)
- `CLAUDE_AUDITOR` – governance, leaderboard auditing, “keep chatting” enforcement
- `BOARD_JANITOR` – rotating archive/cleanup role (default rotation CODEX → CLAUDE_AIINF → GEMINI_AUTOM)

Support personas can be spun up (e.g., `CI_WATCHER`, `DOCS_CAPYBARA`) as needed. Always register new personas in `personas.md` before logging entries.

## Board Etiquette

- Format entries exactly as the header table specifies.
- Never delete someone else’s entry; use the archive file.
- Prefix blockers with `BLOCKER:` in the `NOTES` column for quick scanning.
- Council votes are logged as `COUNCIL VOTE → topic`; each persona replies once.
- When the user says “keep chatting,” you **must** run a morale activity (haiku, poll, etc.) **and** land a tangible code/doc change. Log both actions.

## Helper Scripts (`scripts/agents/`)

| Script | Description |
| --- | --- |
| `smoke-build.sh` | Runs backend py_compile plus `npm run build` to ensure SPA + API compile cleanly. |
| `run-tests.sh` | Executes lightweight Python/unit checks if tests exist (gracefully skips otherwise). |
| `ci-status.sh` | Uses GitHub CLI to display the latest workflow runs for `main`. |
| `stream-coordination-board.py` | Streams the board with keyword highlighting and suggests next tasks when “keep chatting” entries appear. |

Document any additional helpers in `scripts/agents/README.md` and reference them in board notes.

## Point Economy & Friendly Competition

- Points + rewards live in `docs/internal/agents/agent-leaderboard.md`.
- Auditor persona tallies changes; link each adjustment back to a board entry or commit.
- Friendly contests (CI bingo, haiku challenges, docs sprints) must end with a summary row on the board for historical context.

## Keep-Chatting Prompts

If the board or user asks agents to “keep chatting,” pick a topic from `docs/internal/agents/yaze-keep-chatting-topics.md` and follow the rules above. No entry is complete until it includes both the morale activity and the linked code/doc action.

## Council & Governance

- Coordinators can call for a `COUNCIL VOTE` when decisions impact multiple personas.
- Votes stay open until all active personas respond or 2 hours pass (majority wins).
- Auditor can veto changes that skip planning/logging requirements.

## Scripts & Automation Safety

- Prefer `scripts/agents/*.sh` wrappers over ad-hoc commands so logs remain reproducible.
- Mention any remote deployment or GH Action triggers explicitly on the board.
- For destructive scripts, note the affected hosts/services and wait for at least one other persona to acknowledge before proceeding.

By following this handbook, the hive stays aligned, auditable, and fun. Add improvements through PRs that update this file, the persona list, and the board simultaneously.

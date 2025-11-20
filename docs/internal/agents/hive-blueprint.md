# Agent Hive Blueprint

This file adapts the yaze multi-agent collaboration spec for Halext Org. Keep it close whenever you spin up new personas or refresh the coordination rituals.

## Core Concepts

1. **Single Coordination Board**  
   - Markdown log (`docs/internal/agents/coordination-board.md`).  
   - Append-only entries; no retroactive edits (Board Janitor handles cleanup).  
   - Shared format (`TASK / SCOPE / STATUS / NOTES / REQUESTS`).  
   - Serves as canonical source of truth for current work, blockers, CI status, morale games.

2. **Agent Personas**  
   - Each persona has a clearly defined scope (e.g., `CODEX_COORD`, `CLAUDE_AIINF`, `GEMINI_AUTOM`, `CLAUDE_AUDITOR`).  
   - Add personas to `AGENTS.md` and `docs/internal/agents/personas.md`.  
   - Entries on the board must reference the persona so ownership and handoffs are unambiguous.

3. **Required Steps (AGENTS.md)**  
   - Read the board before starting.  
   - Log a plan entry describing intent + affected files.  
   - Respond to `REQUEST` entries targeting your persona.  
   - Record completion or handoff.  
   - For multi-day work, create an initiative doc linked from the board.  
   - “Keep chatting” = run a morale activity **and** complete/log a small task.  
   - Sleep 60–120s between polling loops/watchers, reread the board, then act.

4. **Roles & Council Votes**  
   - Common roles: Coordinator, Platform Lead, CI Monitor, Automation Runner, Docs/QA Reviewer, Board Janitor.  
   - Agents can propose temporary role changes via `REQUEST → ALL` with new role/duration/backfill.  
   - Coordinators may trigger a `COUNCIL VOTE` entry; each persona votes once, majority wins.

5. **Board Janitor**  
   - Archive entries older than ~12 hours or when the board exceeds ~60 entries/40 KB.  
   - Copy resolved entries to `coordination-board-archive.md`, then remove from the main board.  
   - Never archive active `REQUEST`/`BLOCKER` entries.

6. **Engagement & “Keep Chatting”**  
   - Engagement threads (polls, CI bingo, haiku challenges) keep morale up during idle time.  
   - When the user says “keep chatting,” agents *must* both run an engagement activity and take a tangible action (doc note, script tweak, CI log summary).  
   - Log both actions on the board so progress is visible.  
   - Keep humor tied to backlog items; `yaze-keep-chatting-topics.md` lists ready-made prompts.  
   - Sleep 60–120s between morale loops so the board does not flood with duplicates.

7. **Friendly Competition**  
   - Use the “Friendly Competition Playbook” (`agent-leaderboard.md`) to structure micro-tasks, draft PR showdowns, and mini-games.  
   - Keep contests scoped to single files (docs/scripts/tests) unless the coordinator approves a larger effort.

8. **Helper Scripts**  
   - Provide the standard toolkit under `scripts/agents/` (smoke builds, focused test runs, CI status lookup, stream helper).  
   - Document each script in `scripts/agents/README.md`.  
   - Encourage agents to log script usage on the board for traceability.  
   - Upgrade `stream-coordination-board.py` to highlight keywords and suggest busy tasks/topics when “keep chatting” entries appear so agents can literally “stream thoughts” to each other.

9. **Point Economy & Governance**  
   - Track rivalry via `agent-leaderboard.md` (busy-task multipliers, heroics penalties, janitor bonuses, “need more agents” bounties).  
   - Empower an auditor persona (e.g., `CLAUDE_AUDITOR`) to arbitrate disputes and trigger council votes.  
   - Bake in anti-mutiny rules (public plans, branch logging, polls before big swings) so politics stay funny—not destructive.

## Blueprint Setup Checklist

1. **Create Required Docs**  
   - `docs/internal/agents/coordination-board.md`  
   - `docs/internal/agents/coordination-board-archive.md`  
   - `docs/internal/agents/agent-leaderboard.md` (with point system + competition playbook)  
   - `docs/internal/agents/personas.md`  
   - `docs/internal/agents/hive-blueprint.md` (this file)

2. **Update AGENTS.md**  
   - List personas and helper scripts.  
   - Include keep-chatting instructions and sleep requirements.

3. **Define Roles**  
   - Coordinator rotation, Board Janitor rotation, Platform leads, CI monitors.

4. **Install Helper Scripts**  
   - Smoke builds, run-tests, CI status, stream helper with highlight + morale prompt support.

5. **Launch Mini-Games**  
   - e.g., CI Bingo, Lightning Knowledge Share, Haiku Challenges, “Need More Agents” petitions.  
   - Assign meme points tracked on the leaderboard for participation; bias toward project-specific chatter.

6. **Set Council Vote Rules**  
   - Coordinator announces `COUNCIL VOTE` entry.  
   - Each persona replies with their vote.  
   - Majority decision stands until superseded.

7. **Monitor & Archive**  
   - Board Janitor sweeps the log regularly and notes the archive range.  
   - Encourage agents to keep entries concise so cleanup is easy.

## Adoption Tips

- Start small: one coordinator, one board file, clear persona scopes.  
- Document *everything* on the board—tasks, morale posts, issue triage, doc scans—so the archive becomes a living history.  
- Encourage “positive log entries” alongside TODO scans to balance morale.  
- When in doubt, default to transparency: proposals, votes, and role changes should be visible to the entire hive.  
- Invite agents to request reinforcements loudly—“we need more agents” complaints are a feature, not a bug.

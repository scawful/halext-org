# Agent Helper Scripts

Use these wrappers whenever you need to run smoke builds, quick tests, or check CI status. Logging a board entry? Mention which script you used so other personas can replay the steps.

| Script | Description |
| --- | --- |
| `ai-health.sh` | Probes `/ai/provider-info` and `/ai/models` with optional `X-Halext-Code` (`HAL_AI_CODE`) and `Authorization: Bearer …` (`HAL_AI_BEARER` or `HAL_AI_BEARER_FILE`) headers for quick auth-required checks. |
| `smoke-build.sh` | Compiles backend Python files and runs `npm run build` for the SPA. Fails fast if either step breaks. |
| `run-tests.sh` | Runs lightweight backend checks (`pytest` if tests exist, pycompile fallback otherwise). Safe to run repeatedly. |
| `ci-status.sh` | Uses `gh run list` to print the latest GitHub Actions results; helps keep CI bingo honest. |
| `stream-coordination-board.py` | Streams `coordination-board.md`, highlights TODO/BLOCKER keywords, and suggests morale prompts when “keep chatting” appears. |

## Usage

```bash
chmod +x scripts/agents/*.sh
scripts/agents/smoke-build.sh
scripts/agents/run-tests.sh
scripts/agents/ci-status.sh
python scripts/agents/stream-coordination-board.py
```

Each script is self-documenting—run with `-h` or read the source. Extend the toolkit as new workflows emerge, but keep commands idempotent and chatty so the board stays informative.

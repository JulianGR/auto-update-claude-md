---
name: auto-update-claude
description: Manage the auto-update-claude memory cadence system. Use when the user wants to see the current counter, change how often memory is updated (the N value), force a memory flush now, reset the counter, or disable/enable the cadence. Keywords - "memory cadence", "auto update claude", "how many messages until update", "force memory update".
---

# auto-update-claude — management

This skill administers the memory cadence system installed by the
`auto-update-claude` plugin. The system uses two hooks (`SessionStart` and
`UserPromptSubmit`) that, every N messages, ask Claude to flush what it has
learned to the project's `memory/` folder and, when appropriate, to `CLAUDE.md`.

## Locations

- **Hook script**: `${CLAUDE_PLUGIN_ROOT}/hooks/auto-update-claude.sh` (plugin
  install) or `~/.claude/hooks/auto-update-claude.sh` (manual install).
- **Per-project counter**: `~/.claude/state/auto-update-claude/<project-key>.count`,
  where `<project-key>` is the project path with `/ \ :` replaced by `_`.
- **Frequency (N)**: env var `AUTO_UPDATE_CLAUDE_N` (default 5).

## Tasks you can handle

### Show the current counter
1. Compute the key: take `$CLAUDE_PROJECT_DIR` (or the cwd) and replace `/`, `\`, `:` with `_`.
2. Read `~/.claude/state/auto-update-claude/<key>.count`.
3. Report the current count and how many messages remain until the next flush
   (`N - (count % N)`).

### Change the frequency (N)
Prefer NOT editing the script. Set the env var in the user's settings
(`~/.claude/settings.json`):
```json
{ "env": { "AUTO_UPDATE_CLAUDE_N": "8" } }
```
Suggest restarting the session. Guide values: 3 aggressive, 5 recommended, 8-10 relaxed.

### Force a memory flush NOW
Review the recent conversation and, if there is anything durable (decisions,
conventions, key paths/commands, bug fixes), write it as files in the project's
`memory/` folder and refresh `MEMORY.md`. If it is a stable convention, also
reflect it in `CLAUDE.md`.

### Reset the counter
Delete `~/.claude/state/auto-update-claude/<key>.count` (it restarts at 0).

### Disable / re-enable
- **Plugin**: use the Claude Code plugin panel to disable `auto-update-claude`.
- **Manual**: remove the `SessionStart` / `UserPromptSubmit` entries (the ones
  referencing `auto-update-claude.sh`) from `~/.claude/settings.json`.

## Note

This system does NOT replace Claude Code's native Auto Memory or Auto Dream; it
complements them by forcing a review on a fixed cadence. Periodic cleanup is
still handled by Auto Dream (every 24h) and the `consolidate-memory` skill.

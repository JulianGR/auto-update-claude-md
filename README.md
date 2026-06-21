# auto-update-claude

Hooks for **Claude Code** that keep each project's memory fresh on a **fixed
cadence**, built on top of the native _Auto Memory_.

It does two things:

1. **On session start**, if the project has **no `CLAUDE.md`**, it asks Claude to
   create a concise one.
2. **Every N messages** (5 by default), it makes Claude flush what it has learned
   into its `memory/` folder + `MEMORY.md` (and into `CLAUDE.md` for stable
   conventions) — **only if there is something durable** worth remembering.

> **Why a hook and not just a skill?** A skill is _on-demand_: Claude does not
> count messages or self-trigger deterministically. Automatic cadence is only
> possible with **hooks**, whose `stdout` (for `SessionStart` and
> `UserPromptSubmit`) is injected as context and can instruct Claude.

---

## How it works

| Hook | Fires | What it does |
|------|-------|--------------|
| `SessionStart` | When a session opens/resumes | If `CLAUDE.md` is missing, suggests creating it |
| `UserPromptSubmit` | On every user message | Counts; every N, injects the "update memory" instruction |

- The **counter** lives in `~/.claude/state/auto-update-claude/<project>.count`
  (outside your repos — it never pollutes git).
- The **frequency** is controlled by `AUTO_UPDATE_CLAUDE_N` (default `5`).

This **does not replace** Auto Memory (which writes opportunistically) or Auto
Dream (which consolidates every 24h): it **complements** them by forcing a review
on a fixed rhythm.

---

## Install A — as a plugin (recommended, fully additive)

Plugin hooks are **merged** with your existing configuration by Claude Code — they
do **not** modify or replace your `settings.json`.

In a `claude` terminal:

```text
/plugin marketplace add JulianGR/auto-update-claude
/plugin install auto-update-claude@auto-update-claude
```

Restart the session. Done — it applies to all your projects.

## Install B — manual (additive script)

The included `install.sh` only **adds** its hooks to your `~/.claude/settings.json`
and preserves everything else. It is **idempotent** (safe to re-run).

```bash
git clone https://github.com/JulianGR/auto-update-claude.git
cd auto-update-claude
bash install.sh
```

> Requires `bash`. On Windows, run it from Git Bash (the one bundled with Claude
> Code works). If `jq` is installed, the merge is automatic; otherwise the script
> prints the exact `hooks` block for you to merge by hand (never replace the file).

---

## Configuration

Change the cadence **without editing the script** by setting the env var in
`settings.json`:

```json
{ "env": { "AUTO_UPDATE_CLAUDE_N": "8" } }
```

Guide: `3` aggressive · `5` recommended · `8-10` relaxed.

---

## Management skill

The plugin ships an `auto-update-claude` skill so you can ask Claude things like:

- "what's the memory counter at?"
- "change the cadence to 8"
- "force a memory flush now"
- "reset the counter" / "disable the cadence"

---

## Requirements & notes

- **`bash`** must be available for the hooks. On Windows it works with the Git Bash
  that ships with Claude Code (tested on the desktop app, Windows 11).
- Built for Claude Code **v2.1.59+** (native Auto Memory) and later.
- Conservative by design: if there is nothing new, it **writes nothing**.

---

## License

MIT — see [LICENSE](LICENSE).

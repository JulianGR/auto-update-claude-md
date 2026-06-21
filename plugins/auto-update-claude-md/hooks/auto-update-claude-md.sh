#!/usr/bin/env bash
# auto-update-claude-md.sh
# Cadence hook for Claude Code: keeps each project's memory fresh.
#
# Modes (first argument):
#   sessionstart  -> if the project has no CLAUDE.md, ask Claude to create one.
#   cadence       -> per-project message counter; every N messages, ask Claude
#                    to flush durable learnings to memory/ (and CLAUDE.md).
#
# stdout of SessionStart and UserPromptSubmit hooks is injected as CONTEXT for
# Claude (documented behavior), so we just print the instruction and exit 0.
#
# Frequency: env var AUTO_UPDATE_CLAUDE_N (default 5).
#   3 = aggressive   5 = recommended   8-10 = relaxed

set -uo pipefail

N="${AUTO_UPDATE_CLAUDE_N:-5}"
case "$N" in (*[!0-9]*|'') N=5 ;; esac

mode="${1:-cadence}"
proj="${CLAUDE_PROJECT_DIR:-$PWD}"

# Per-project counter under ~/.claude (never touches your repos).
state_dir="$HOME/.claude/state/auto-update-claude-md"
mkdir -p "$state_dir" 2>/dev/null || true
key="$(printf '%s' "$proj" | tr '/\\:' '___')"
count_file="$state_dir/$key.count"

has_claudemd() {
  [ -f "$proj/CLAUDE.md" ] || [ -f "$proj/.claude/CLAUDE.md" ]
}

case "$mode" in
  sessionstart)
    if ! has_claudemd; then
      printf '%s\n' "[auto-update-claude-md] This project has no CLAUDE.md. If you already understand its purpose and structure (build/test commands, conventions, architecture, key paths), create a CONCISE CLAUDE.md at the project root. If you don't have enough context yet, ignore this for now."
    fi
    ;;

  cadence)
    count=0
    if [ -f "$count_file" ]; then
      count="$(cat "$count_file" 2>/dev/null || echo 0)"
    fi
    case "$count" in (*[!0-9]*|'') count=0 ;; esac
    count=$((count + 1))
    printf '%s' "$count" > "$count_file" 2>/dev/null || true

    if [ $((count % N)) -eq 0 ]; then
      printf '%s\n' "[auto-update-claude-md] ${N} messages have passed (total: ${count} in this project). BEFORE answering, update your memory ONLY if you have learned something durable (design decisions, conventions, key paths/commands, bug fixes): write the new facts as files in your memory/ folder and refresh the MEMORY.md index; if you discovered a STABLE project convention, also add it to CLAUDE.md. If there is nothing new worth remembering, do NOT write anything and answer normally."
    fi
    ;;

  *)
    : # unknown mode: do nothing
    ;;
esac

exit 0

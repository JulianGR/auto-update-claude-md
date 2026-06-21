#!/usr/bin/env bash
# Additive manual installer for auto-update-claude.
#
# This script ONLY ADDS its two hooks to ~/.claude/settings.json. It never
# replaces or removes your existing settings. It is idempotent: re-running it
# will not create duplicate hook entries.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SRC="$REPO_DIR/plugins/auto-update-claude/hooks/auto-update-claude.sh"
HOOK_DEST_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"

# 1) Install the hook script
mkdir -p "$HOOK_DEST_DIR"
cp "$HOOK_SRC" "$HOOK_DEST_DIR/auto-update-claude.sh"
chmod +x "$HOOK_DEST_DIR/auto-update-claude.sh" 2>/dev/null || true
echo "Installed hook -> $HOOK_DEST_DIR/auto-update-claude.sh"

# 2) The hooks fragment we add (and only this)
FRAGMENT='{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash \"$HOME/.claude/hooks/auto-update-claude.sh\" sessionstart"}]}],"UserPromptSubmit":[{"hooks":[{"type":"command","command":"bash \"$HOME/.claude/hooks/auto-update-claude.sh\" cadence"}]}]}}'

if command -v jq >/dev/null 2>&1; then
  mkdir -p "$(dirname "$SETTINGS")"
  [ -f "$SETTINGS" ] || printf '%s' '{}' > "$SETTINGS"
  tmp="$(mktemp)"
  # Preserve every other key. For SessionStart/UserPromptSubmit, drop any prior
  # auto-update-claude entries (idempotency) and append ours. Other events and
  # all other settings keys are left untouched.
  jq --argjson add "$FRAGMENT" '
    def strip($a): [ ($a // [])[] | select((([.hooks[]?.command] | join(" ")) | test("auto-update-claude")) | not) ];
    .hooks = (.hooks // {})
    | .hooks.SessionStart     = (strip(.hooks.SessionStart)     + $add.hooks.SessionStart)
    | .hooks.UserPromptSubmit = (strip(.hooks.UserPromptSubmit) + $add.hooks.UserPromptSubmit)
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "Merged hooks into $SETTINGS (existing settings preserved)."
else
  echo ""
  echo "jq not found. Add the following 'hooks' block to:"
  echo "  $SETTINGS"
  echo "IMPORTANT: MERGE it into your existing JSON — do NOT replace the file."
  echo ""
  echo "$FRAGMENT"
fi

echo ""
echo "Done. Restart your Claude Code session to load the hooks."

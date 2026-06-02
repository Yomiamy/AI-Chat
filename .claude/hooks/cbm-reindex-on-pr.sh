#!/bin/bash
# PostToolUse(Bash) hook: re-index the codebase whenever a PR is created.
# Fires after every Bash call; only acts when the command ran `gh pr create`.
# Indexing runs in the background (fast mode) so it never blocks the agent.

input=$(cat)

# Extract the command string from the tool input JSON.
command=$(printf '%s' "$input" | python3 -c \
  'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' \
  2>/dev/null)

# Only trigger on `gh pr create` (tolerate extra flags / whitespace).
if ! printf '%s' "$command" | grep -qE 'gh[[:space:]]+pr[[:space:]]+create'; then
  exit 0
fi

repo="${CLAUDE_PROJECT_DIR:-$PWD}"
cli="$HOME/.local/bin/codebase-memory-mcp"
[ -x "$cli" ] || exit 0

# Background re-index; detached so the hook returns immediately.
nohup "$cli" cli index_repository "{\"repo_path\":\"$repo\",\"mode\":\"fast\"}" \
  >/dev/null 2>&1 &

echo "[cbm] PR detected → re-indexing $repo in background (fast mode)."
exit 0

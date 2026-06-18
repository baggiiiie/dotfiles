#!/bin/bash
# herdr sessionizer — mirrors others/tmux-sessionizer.sh
#
# Usage:
#   herdr-sessionizer.sh                # fuzzy-pick a project (needs an interactive pane)
#   herdr-sessionizer.sh <project-key>  # jump directly, e.g. "personal/jjui" or "home"
#
# Focuses an existing workspace (matched by label) or creates one at the
# project cwd. `herdr workspace create` always creates a new workspace (not
# idempotent), so we look up an existing one by label first.
#
# Bound from ~/.config/herdr/config.toml via [[keys.command]]:
#   prefix+f          -> this script (fuzzy, type=pane)
#   prefix+<Shift+X>  -> this script <key>  (direct, type=shell)
# mirroring the prefix+J / prefix+D / ... bindings in ~/.tmux.conf.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAST_WORKSPACE_HELPER="$SCRIPT_DIR/herdr-toggle-last-workspace.sh"

REPO_DIR=("$HOME/repos/work/" "$HOME/repos/personal/" "$HOME/repos/personal/tries/")

# Resolve a project key (e.g. "personal/jjui", "work/eosctl", "home") to a cwd.
resolve_cwd() {
  local key="$1"
  if [[ "$key" == "home" ]]; then
    echo "$HOME"
    return
  fi
  fd . "${REPO_DIR[@]}" -d 1 -t d 2>/dev/null | grep -E "/${key}/?\$" | sed 's:/$::' | head -1
}

# Focus an existing workspace with this label, or create one at cwd.
focus_or_create() {
  local key="$1" cwd="$2"
  if [[ -z "$cwd" ]]; then
    echo "herdr-sessionizer: could not resolve cwd for '$key'" >&2
    exit 1
  fi

  local id
  id=$(herdr workspace list 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    key = sys.argv[1]
    # Match the full key (e.g. "personal/jjui") first, then fall back to the
    # basename (e.g. "dotfiles") so a workspace herdr auto-labeled by basename
    # is reused instead of duplicated.
    candidates = [key] + ([key.rsplit("/", 1)[-1]] if "/" in key else [])
    for w in d.get("result", {}).get("workspaces", []):
        if w.get("label") in candidates:
            print(w["workspace_id"])
            break
except Exception:
    pass
' "$key" 2>/dev/null || true)

  if [[ -n "$id" ]]; then
    [[ -x "$LAST_WORKSPACE_HELPER" ]] && "$LAST_WORKSPACE_HELPER" --record "$id" || true
    herdr workspace focus "$id" >/dev/null 2>&1 || true
  else
    [[ -x "$LAST_WORKSPACE_HELPER" ]] && "$LAST_WORKSPACE_HELPER" --snapshot-current || true
    herdr workspace create --cwd "$cwd" --label "$key" --focus >/dev/null 2>&1 || true
    [[ -x "$LAST_WORKSPACE_HELPER" ]] && "$LAST_WORKSPACE_HELPER" --record-current || true
  fi
}

if [[ $# -ge 1 ]]; then
  # Direct jump: prefix+<Shift+X> -> herdr-sessionizer.sh <key>
  key="$1"
  cwd="$(resolve_cwd "$key")"
  focus_or_create "$key" "$cwd"
else
  # Fuzzy mode: prefix+f -> interactive picker (requires a pane).
  name=$(fd . "${REPO_DIR[@]}" -d 1 -t d --print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null | sort -rn \
    | awk '{sub(/^[0-9]+ /,""); sub(/\/$/,""); n=split($0,a,"/"); print a[n-1]"/"a[n]}' \
    | sk --layout=reverse) || true
  [[ -z "${name:-}" ]] && exit 0
  cwd="$(fd . "${REPO_DIR[@]}" -d 1 -t d 2>/dev/null | grep -E "/${name}/?\$" | sed 's:/$::' | head -1)"
  focus_or_create "$name" "$cwd"
fi

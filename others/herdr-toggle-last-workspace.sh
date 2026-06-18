#!/usr/bin/env bash
# Toggle between the current Herdr workspace and the last visited workspace.
#
# Herdr's built-in previous_workspace cycles through workspace order. This keeps
# a tiny MRU state file so repeated invocations bounce current <-> last.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/herdr"
STATE_FILE="$STATE_DIR/last-workspace.json"

workspace_list() {
  herdr workspace list 2>/dev/null
}

write_state() {
  local current="$1" last="${2:-}"
  mkdir -p "$STATE_DIR"
  local tmp
  tmp="$(mktemp "$STATE_DIR/last-workspace.XXXXXX")"
  python3 - "$current" "$last" >"$tmp" <<'PY'
import json, sys
print(json.dumps({"current": sys.argv[1], "last": sys.argv[2]}))
PY
  mv "$tmp" "$STATE_FILE"
}

current_workspace_id() {
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    for w in d.get("result", {}).get("workspaces", []):
        if w.get("focused"):
            print(w.get("workspace_id", ""))
            break
except Exception:
    pass
'
}

# Record that Herdr is about to focus the given workspace id.
record_target() {
  local target="$1" list current
  list="$(workspace_list)" || exit 0
  current="$(printf '%s' "$list" | current_workspace_id)"
  [[ -n "$current" && "$target" != "$current" ]] || exit 0
  write_state "$target" "$current"
}

# Snapshot whatever is focused now. Useful before creating a new focused workspace.
snapshot_current() {
  local list current last
  list="$(workspace_list)" || exit 0
  current="$(printf '%s' "$list" | current_workspace_id)"
  [[ -n "$current" ]] || exit 0
  last="$(python3 - "$STATE_FILE" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(json.load(f).get("last", ""))
except Exception:
    pass
PY
)"
  write_state "$current" "$last"
}

# Record the current workspace after some external focus change happened.
record_current() {
  local list current previous_current
  list="$(workspace_list)" || exit 0
  current="$(printf '%s' "$list" | current_workspace_id)"
  [[ -n "$current" ]] || exit 0
  previous_current="$(python3 - "$STATE_FILE" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(json.load(f).get("current", ""))
except Exception:
    pass
PY
)"
  if [[ -n "$previous_current" && "$previous_current" != "$current" ]]; then
    write_state "$current" "$previous_current"
  fi
}

toggle_last_workspace() {
  local list choice target current
  list="$(workspace_list)" || exit 0

  choice="$(python3 -c '
import json, sys
state_file = sys.argv[1]
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(2)
workspaces = d.get("result", {}).get("workspaces", [])
ids = {w.get("workspace_id") for w in workspaces}
current = next((w.get("workspace_id") for w in workspaces if w.get("focused")), "")
try:
    with open(state_file) as f:
        state = json.load(f)
except Exception:
    state = {}
stored_current = state.get("current", "")
stored_last = state.get("last", "")

# Normal case: state says the focused workspace is current, so go to last.
# If the user changed workspaces outside this script, treat the previously
# recorded current workspace as the last visited one.
target = stored_last if stored_current == current else stored_current

if not current or not target or target == current or target not in ids:
    sys.exit(2)
print(target + "\t" + current)
' "$STATE_FILE" <<<"$list")" || exit 0

  IFS=$'\t' read -r target current <<<"$choice"
  [[ -n "$target" && -n "$current" ]] || exit 0

  if herdr workspace focus "$target" >/dev/null 2>&1; then
    write_state "$target" "$current"
  fi
}

case "${1:-}" in
  --record)
    [[ $# -eq 2 ]] || exit 2
    record_target "$2"
    ;;
  --snapshot-current)
    snapshot_current
    ;;
  --record-current)
    record_current
    ;;
  "")
    toggle_last_workspace
    ;;
  *)
    echo "usage: $(basename "$0") [--record WORKSPACE_ID|--snapshot-current|--record-current]" >&2
    exit 2
    ;;
esac

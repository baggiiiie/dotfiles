#!/usr/bin/env bash
# Toggle between the current Herdr tab and the last focused tab in the current workspace.
#
# Herdr does not currently expose a native "last focused tab" binding. This
# keeps a small MRU state file per workspace. The helper can also wrap tab
# navigation bindings so the MRU state stays up to date.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/herdr"
# TSV is intentionally used here instead of JSON to keep the hot path light:
#   workspace_id<TAB>current_tab_id<TAB>last_tab_id
STATE_FILE="$STATE_DIR/last-tab.tsv"

choose_target() {
  local mode="$1" arg="${2:-}" tabs
  tabs="$(herdr tab list 2>/dev/null)" || exit 0

  python3 -c '
import json, os, sys
mode, arg, state_file = sys.argv[1:4]
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(2)

tabs = d.get("result", {}).get("tabs", [])
current_tab = next((t for t in tabs if t.get("focused")), None)
if not current_tab:
    sys.exit(2)
workspace_id = current_tab.get("workspace_id", "")
current = current_tab.get("tab_id", "")
if not workspace_id or not current:
    sys.exit(2)

workspace_tabs = [t for t in tabs if t.get("workspace_id") == workspace_id and t.get("tab_id")]
workspace_tabs.sort(key=lambda t: t.get("number", 0))
ids = [t["tab_id"] for t in workspace_tabs]
ids_set = set(ids)

stored_current = stored_last = ""
try:
    with open(state_file) as f:
        for line in f:
            parts = line.rstrip("\n").split("\t")
            if len(parts) >= 3 and parts[0] == workspace_id:
                stored_current, stored_last = parts[1], parts[2]
                break
except Exception:
    pass

target = ""
if mode == "toggle":
    # Normal case: state says the focused tab is current, so go to last. If the
    # user changed tabs outside this helper, treat the previously recorded
    # current tab as the last visited one.
    target = stored_last if stored_current == current else stored_current

    # On a fresh state file, a two-tab workspace can still safely toggle to the
    # only other tab. With 3+ tabs, there is no reliable history yet.
    if (not target or target == current or target not in ids_set) and len(ids) == 2:
        target = next((tid for tid in ids if tid != current), "")
elif mode == "number":
    # Herdr tab numbers are stable creation numbers, so they can have gaps after
    # tabs are closed. Treat prefix+N as the Nth visible tab instead.
    index = int(arg) - 1
    if 0 <= index < len(workspace_tabs):
        target = workspace_tabs[index]["tab_id"]
elif mode == "relative":
    delta = int(arg)
    if len(ids) >= 2 and current in ids_set:
        target = ids[(ids.index(current) + delta) % len(ids)]
elif mode == "record":
    if stored_current and stored_current != current:
        target = current
        print(workspace_id + "\t" + current + "\t" + stored_current + "\trecord")
        sys.exit(0)
    elif not stored_current:
        print(workspace_id + "\t" + current + "\t-\trecord")
        sys.exit(0)
    sys.exit(2)
else:
    sys.exit(2)

if not target or target == current or target not in ids_set:
    sys.exit(2)
print(workspace_id + "\t" + current + "\t" + target + "\tfocus")
' "$mode" "$arg" "$STATE_FILE" <<<"$tabs"
}

write_state() {
  local workspace_id="$1" current="$2" last="${3:-}"
  mkdir -p "$STATE_DIR"
  local tmp
  tmp="$(mktemp "$STATE_DIR/last-tab.XXXXXX")"
  if [[ -f "$STATE_FILE" ]]; then
    awk -v ws="$workspace_id" -v cur="$current" -v last="$last" '
      BEGIN { FS = OFS = "\t" }
      $1 == ws { print ws, cur, last; found = 1; next }
      { print }
      END { if (!found) print ws, cur, last }
    ' "$STATE_FILE" >"$tmp"
  else
    printf '%s\t%s\t%s\n' "$workspace_id" "$current" "$last" >"$tmp"
  fi
  mv "$tmp" "$STATE_FILE"
}

run_focus() {
  local mode="$1" arg="${2:-}" choice workspace_id current target action
  choice="$(choose_target "$mode" "$arg")" || exit 0
  IFS=$'\t' read -r workspace_id current target action <<<"$choice"
  [[ -n "$workspace_id" && -n "$current" && -n "$target" ]] || exit 0

  if [[ "$action" == "record" ]]; then
    [[ "$target" == "-" ]] && target=""
    write_state "$workspace_id" "$current" "$target"
  elif herdr tab focus "$target" >/dev/null 2>&1; then
    write_state "$workspace_id" "$target" "$current"
  fi
}

case "${1:-}" in
  --focus-number)
    [[ $# -eq 2 && "$2" =~ ^[0-9]+$ ]] || exit 2
    run_focus number "$2"
    ;;
  --focus-relative)
    [[ $# -eq 2 && "$2" =~ ^-?[0-9]+$ ]] || exit 2
    run_focus relative "$2"
    ;;
  --record-current)
    run_focus record
    ;;
  "")
    run_focus toggle
    ;;
  *)
    echo "usage: $(basename "$0") [--focus-number N|--focus-relative +/-N|--record-current]" >&2
    exit 2
    ;;
esac

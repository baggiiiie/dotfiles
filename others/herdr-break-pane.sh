#!/bin/bash
# herdr break-pane — tmux prefix+! equivalent.
#
# Breaks the current pane out into a new tab/window.
#
# Extracted from an inline [[keys.command]] because herdr runs keybind commands
# through the login shell (Nushell here), which can't parse POSIX syntax like
# `$(...)`, `pane_id=...`, or nested `python3 -c '...'`. Keeping the logic in a
# script invoked as `bash ~/.../herdr-break-pane.sh` sidesteps that entirely.
#
# Bound from ~/.config/herdr/config.toml via [[keys.command]] key = "prefix+!".

set -euo pipefail

# herdr launches keybind commands with a minimal PATH that omits the Homebrew
# and zerobrew bin dirs, so herdr/python3 are not found by bare name.
export PATH="/opt/homebrew/bin:/opt/zerobrew/prefix/bin:$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"

pane_id=$(herdr pane current 2>/dev/null \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("result",{}).get("pane",{}).get("pane_id",""))' \
  2>/dev/null || true)
pane_id=${pane_id:-${HERDR_PANE_ID:-}}

[[ -n "$pane_id" ]] && herdr pane move "$pane_id" --new-tab --focus >/dev/null 2>&1 || true

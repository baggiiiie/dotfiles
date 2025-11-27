#!/bin/bash

REPO_DIR="$HOME/Desktop/repos"
sesh_to_init=("eosctl" "coffeeee" "jjui")

if [[ $# -eq 1 ]]; then
    session_name=$1
else
    session_name=$(fd . "$REPO_DIR" -d 2 -t d -x sh -c 'echo "$(basename $(dirname {}))/$(basename {})"' | sk --layout=reverse)
fi

if [[ -z $session_name ]]; then
    exit 0
fi

session_path="$REPO_DIR/$session_name"
if ! pgrep tmux >/dev/null; then
    echo "no tmux running"
    exit 1
fi

if ! tmux has-session -t="$session_name" 2>/dev/null; then
    tmux new-session -ds "$session_name" -c "$session_path"
    # Run init script if session_name is in sesh_to_init array
    for sesh in "${sesh_to_init[@]}"; do
        if [[ "$session_name" == *"$sesh"* ]]; then
            bash "$(dirname "$0")/tmux-init-sesh.sh" "$session_name" "$session_path"
            break
        fi
    done
fi

tmux switch-client -t "$session_name"

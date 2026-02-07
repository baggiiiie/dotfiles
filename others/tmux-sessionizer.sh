#!/bin/bash

REPO_DIR=("$HOME/Desktop/repos/work/" "$HOME/Desktop/repos/personal/" "$HOME/Desktop/repos/personal/tries/")
sesh_to_init=("eosctl" "coffeeee" "jjui")

if [[ $# -eq 1 ]]; then
    session_name=$1
else
    session_name=$(fd . "${REPO_DIR[@]}" -d 1 -t d --print0 \
        | xargs -0 stat -f '%a %N' \
        | sort -rn \
        | cut -d' ' -f2- \
        | while read -r p; do echo "$(basename "$(dirname "$p")")/$(basename "$p")"; done \
        | sk --layout=reverse)
fi

if [[ -z $session_name ]]; then
    exit 0
fi

session_path=$(fd . "${REPO_DIR[@]}" -d 1 -t d -x sh -c 'echo "$(dirname {})/$(basename {})"' | grep "/$session_name$")
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

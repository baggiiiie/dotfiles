#!/bin/bash

# tmux_sesh=$(tmux ls | awk -F ":" '{print $1}')
# dir+=$'\n'"$tmux_sesh"

REPO_DIR="$HOME/Desktop/repos"

function find_dir() {
    fd . "$REPO_DIR" -d 2 -t d -x basename {} | sk --layout=reverse
}

if [[ $# -eq 1 ]]; then
    session_name=$1
else
    session_name=$(fd . "$REPO_DIR" -d 2 -t d -x sh -c 'echo "$(basename $(dirname {}))/$(basename {})"' | sk --layout=reverse)
fi

if [[ -z $session_name ]]; then
    exit 0
fi

session_path="$REPO_DIR/$session_name"
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s "$session_name" -c "$session_path"
    exit 0
fi

if ! tmux has-session -t="$session_name" 2>/dev/null; then
    tmux new-session -ds "$session_name" -c "$session_path"
fi

tmux switch-client -t "$session_name"

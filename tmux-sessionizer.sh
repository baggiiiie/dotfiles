#!/bin/bash

# tmux_sesh=$(tmux ls | awk -F ":" '{print $1}')
# dir+=$'\n'"$tmux_sesh"

if [[ $# -eq 1 ]]; then
  if [[ $1 == "open" ]]; then
    selected=$(tmux ls | awk -F ":" '{print $1}' | sk --layout=reverse)
  else
    selected=$1
  fi
else
  selected=$(fd . "$HOME/Desktop/repos" -d 1 -t d -x basename {} \; | sk --layout=reverse | xargs printf "$HOME/Desktop/repos/%s")
fi

if [[ -z $selected ]]; then
  exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
  tmux new-session -s "$selected_name" -c "$selected"
  exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
  tmux new-session -ds "$selected_name" -c "$selected"
fi

tmux switch-client -t "$selected_name"

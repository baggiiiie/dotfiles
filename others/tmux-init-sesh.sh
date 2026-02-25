#!/bin/bash

session_name="${1:-$(tmux display-message -p '#S' 2>/dev/null)}"
session_path="${2:-$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)}"

if [[ -z "$session_name" || -z "$session_path" ]]; then
  echo "Error: Not in a tmux session and no arguments provided."
  echo "Usage: $0 [session_name] [session_path]"
  exit 1
fi

# Create second window named "agents"
tmux new-window -t "$session_name" -n agent -c "$session_path"

# Create third window named "term"
tmux new-window -t "$session_name" -n terminal -c "$session_path"

# Create fourth window named "jjui"
tmux new-window -t "$session_name" -n jjui -c "$session_path"

# Create fifth window named "server"
# tmux new-window -t "$session_name" -n server -c "$session_path"

# Rename the first window to "editor"
tmux rename-window -t "$session_name:1" editor

# Switch back to the first window (editor)
tmux select-window -t "$session_name:1"

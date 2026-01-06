#!/bin/bash

session_name="$1"
session_path="$2"

# Create second window named "agents"
tmux new-window -t "$session_name" -n agent -c "$session_path"

# Create third window named "term"
tmux new-window -t "$session_name" -n terminal -c "$session_path"

# Create fourth window named "jjui"
tmux new-window -t "$session_name" -n jjui -c "$session_path"

# Create fifth window named "server"
tmux new-window -t "$session_name" -n server -c "$session_path"

# Rename the first window to "editor"
tmux rename-window -t "$session_name:1" editor

# Switch back to the first window (editor)
tmux select-window -t "$session_name:1"

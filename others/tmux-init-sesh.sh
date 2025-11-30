#!/bin/bash

# Rename the first window to "editor"
tmux rename-window -t 1 editor

# Create second window named "agents"
tmux new-window -n agent

# Create third window named "term"
tmux new-window -n terminal

# Create fourth window named "jjui"
tmux new-window -n jjui

# Create fifth window named "server"
tmux new-window -n server

# Switch back to the first window (editor)
tmux select-window -t 1

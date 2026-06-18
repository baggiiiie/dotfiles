#!/bin/bash

# exp - Experiment launcher
# Usage: exp <github-url|name>
# Creates a session/workspace in /tmp for quick experiments.
# Detects the current terminal multiplexer (tmux or herdr); defaults to herdr.

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: exp <github-url|name>"
    exit 1
fi

input="$1"

# Determine if input is a GitHub URL
if [[ "$input" =~ ^https?://github\.com/ ]] || [[ "$input" =~ ^git@github\.com: ]]; then
    # Extract repo name from URL (strip .git suffix if present)
    repo_name=$(basename "$input" .git)
    target_dir="/tmp/$repo_name"

    if [[ -d "$target_dir" ]]; then
        echo "Directory $target_dir already exists, reusing it."
    else
        echo "Shallow cloning into $target_dir..."
        git clone --depth 1 "$input" "$target_dir"
    fi
else
    # It's just a string, create a directory
    target_dir="/tmp/$input"
    mkdir -p "$target_dir"
fi

# Sanitize session name (multiplexers don't like dots/colons)
session_name=$(basename "$target_dir" | tr '.:' '--')

# Detect the current terminal multiplexer (tmux or herdr), default herdr.
if [[ -n "$TMUX" ]]; then
    mux="tmux"
elif [[ -n "$HERDR_ENV" || -n "$HERDR_SOCKET_PATH" ]]; then
    mux="herdr"
else
    mux="herdr"
fi

case "$mux" in
    tmux)
        # Create tmux session if it doesn't exist
        if ! tmux has-session -t="$session_name" 2>/dev/null; then
            tmux new-session -ds "$session_name" -c "$target_dir"
        fi

        # Attach or switch
        if [[ -z "$TMUX" ]]; then
            tmux attach-session -t "$session_name"
        else
            tmux switch-client -t "$session_name"
        fi
        ;;
    herdr)
        # Create a focused herdr workspace rooted at the target directory
        herdr workspace create --cwd "$target_dir" --label "$session_name" --focus
        ;;
esac

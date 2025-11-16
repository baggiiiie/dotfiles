#!/bin/bash

branch=$(git branch --column=never --no-color | fzf | xargs)
remotes=$(git remote | xargs echo)

# Select remote if multiple exist
remote_count=$(echo "$remotes" | wc -w | xargs)
if [[ $remote_count -gt 1 ]]; then
    selected_remote=$(echo "$remotes" | tr ' ' '\n' | fzf --prompt="Select remote: ")
else
    selected_remote=$(echo "$remotes" | awk '{print $1}')
fi

# Extract user and repo from remote URL
remote_url=$(git remote get-url "$selected_remote")
if [[ $remote_url =~ git(.*).com[:/]([^/]+)/([^/.]+) ]]; then
    user="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
else
    echo "Error: Could not parse GitHub user/repo from remote URL: $remote_url"
    exit 1
fi

if gh pr view "$branch" -w -R "$user/$repo"; then
    return
fi
if [[ $2 != "" ]]; then
    gh pr create -b main -H "$branch" -w -F "$2" -R "$user/$repo"
else
    gh pr create -b main -H "$branch" -w -R "$user/$repo"
fi

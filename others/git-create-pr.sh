#!/bin/bash

branch="$1"
if [[ -z $branch ]]; then
    branch=$(git branch --column=never --no-color | fzf | xargs)
fi

# Read remotes into array (faster than multiple pipes)
mapfile -t remotes_array < <(git remote)

# Select remote if multiple exist
if [[ ${#remotes_array[@]} -gt 1 ]]; then
    selected_remote=$(printf '%s\n' "${remotes_array[@]}" | fzf --prompt="Select remote: ")
else
    selected_remote="${remotes_array[0]}"
fi

# Extract user and repo from remote URL
remote_url=$(git remote get-url "$selected_remote")
if [[ $remote_url =~ git.*.com[:/]([^/]+)/([^/.]+) ]]; then
    user="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
    dash_r_option=(-R "$user/$repo")
else
    echo "Error: Could not parse GitHub user/repo from remote URL: $remote_url"
    exit 1
fi

# Try to view existing PR first (faster than ls-remote)
if gh pr view "$branch" -w "${dash_r_option[@]}" 2>/dev/null; then
    exit 0
fi

# Push branch if needed
if [[ -d .jj ]]; then
    jj git push -b "$branch" 2>/dev/null || true
else
    git push -u "$selected_remote" "$branch" 2>/dev/null || true
fi

# Create PR
if [[ $2 != "" ]]; then
    gh pr create -B main -H "$branch" -w -F "$2" "${dash_r_option[@]}"
else
    gh pr create -B main -H "$branch" -w "${dash_r_option[@]}"
fi

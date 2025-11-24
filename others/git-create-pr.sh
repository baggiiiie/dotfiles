#!/bin/bash

# Parse command line arguments
branch=""
pr_body=""
me="baggiiiie"

while [[ $# -gt 0 ]]; do
    case $1 in
    --branch)
        branch="$2"
        shift 2
        ;;
    --pr-body)
        pr_body="$2"
        shift 2
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--branch BRANCH] [--pr-body FILE]"
        exit 1
        ;;
    esac
done

# If branch not provided, use fzf to select
if [[ -z $branch ]]; then
    branch=$(git branch --column=never --no-color | fzf --prompt="Select branch to open PR with: " | xargs)
fi

if [[ "$branch" =~ "no branch" ]]; then
    branch=$(jj git push -c @ -N 2>&1 | grep -oE 'yc/test-\w' | head -n 1)
    echo "pushed bookmark is: $branch"
fi

# Read remotes into array (faster than multiple pipes)
mapfile -t remotes_array < <(git remote)

# Select remote if multiple exist
if [[ ${#remotes_array[@]} -gt 1 ]]; then
    selected_remote=$(printf '%s\n' "${remotes_array[@]}" | fzf --prompt="Select remote to open PR in: ")
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

if [[ $(pwd) =~ "jjui" ]] && [[ "$user" != "$me" ]]; then
    branch="$me:$branch"
fi

# Try to view existing PR first (faster than ls-remote)
if gh pr view "$branch" -w "${dash_r_option[@]}" 2>/dev/null; then
    exit 0
fi

# Push branch if needed
if [[ -d .jj ]]; then
    if ! jj git push -b "${branch#"$me":}"; then
        echo "probably a private commit, push failed"
        exit 1
    fi
else
    git push -u "$selected_remote" "$branch" 2>/dev/null || true
fi

# Create PR
if [[ -n $pr_body ]]; then
    gh pr create -B main -H "$branch" -w -F "$pr_body" "${dash_r_option[@]}"
else
    gh pr create -B main -H "$branch" -w "${dash_r_option[@]}"
fi

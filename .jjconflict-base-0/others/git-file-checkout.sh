commit=$1
git diff release-edgeos-1.9 "$commit" --name-only | fzf --ansi --preview "git diff --color=always release-edgeos-1.9 $commit -- {}" --preview-window=right:70% -m | xargs git checkout "$commit" --

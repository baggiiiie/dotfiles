#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OLD_PATH_SEGMENT="repos/personal/dotfiles"
REPO_PATH_SEGMENT="repos/personal/dotfiles"

# Repair stale symlinks created before moving dotfiles from ~/repos to ~/repos.
repair_links() {
  local search_root="$1"
  local max_depth="$2"
  find "$search_root" -maxdepth "$max_depth" -type l -print0 2>/dev/null |
    while IFS= read -r -d '' link; do
      target="$(readlink "$link" || true)"
      case "$target" in
        *"$OLD_PATH_SEGMENT"*)
          fixed_target="${target/Desktop\/repos\/personal\/dotfiles/repos\/personal\/dotfiles}"
          if [[ "$fixed_target" != "$target" ]]; then
            ln -snf "$fixed_target" "$link"
          fi
          ;;
      esac
    done
}

repair_links "$HOME" 1
repair_links "$HOME/.config" 3

# Remove links that are managed by this dotfiles repo so we can recreate them cleanly.
remove_managed_links() {
  find "$HOME" \
    \( -path "$HOME/Library" -o -path "$HOME/.Trash" -o -path "$HOME/repos" \) -prune -o \
    -type l -print0 2>/dev/null |
    while IFS= read -r -d '' link; do
      target="$(readlink "$link" || true)"
      case "$target" in
        *"$OLD_PATH_SEGMENT"*|*"$REPO_PATH_SEGMENT"*|"$DOTFILES_DIR"*)
          rm -f "$link"
          ;;
      esac
    done
}

is_simulation=false
for arg in "$@"; do
  case "$arg" in
    -n|--no|--simulate)
      is_simulation=true
      ;;
  esac
done

if [[ "$is_simulation" == false ]]; then
  remove_managed_links
fi

stow -t "$HOME" -d "$DOTFILES_DIR" --restow . "$@"

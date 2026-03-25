#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Check if a symlink target looks like it belongs to this dotfiles repo.
points_to_dotfiles() {
  local target="$1"
  [[ "$target" == "$DOTFILES_DIR"* || "$target" == *"/dotfiles/"* ]]
}

# ---------------------------------------------------------------------------
# Clean up existing symlinks before restow
# ---------------------------------------------------------------------------

cleanup_links() {
  local search_dirs=("$HOME" "$HOME/.config" "$HOME/.ssh")
  local depths=(1 3 1)
  local stale=()

  for i in "${!search_dirs[@]}"; do
    local dir="${search_dirs[$i]}"
    local depth="${depths[$i]}"
    [[ -d "$dir" ]] || continue

    find "$dir" -maxdepth "$depth" -type l -print0 2>/dev/null |
      while IFS= read -r -d '' link; do
        local target
        target="$(readlink "$link" 2>/dev/null || true)"

        if ! points_to_dotfiles "$target"; then
          continue  # not ours — leave it alone
        fi

        if [[ -e "$link" ]]; then
          # Active managed link — remove so stow can recreate it.
          rm -f "$link"
          echo "removed: $link"
        else
          # Broken link that used to point to our dotfiles.
          rm -f "$link"
          echo "removed (stale): $link -> $target"
        fi
      done
  done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

dry_run=false
for arg in "$@"; do
  case "$arg" in
    -n|--no|--simulate) dry_run=true ;;
  esac
done

if [[ "$dry_run" == false ]]; then
  cleanup_links
fi

stow -t "$HOME" -d "$DOTFILES_DIR" --restow . "$@"

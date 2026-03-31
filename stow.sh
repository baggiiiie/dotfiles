#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STOW_BIN="$(command -v stow 2>/dev/null || true)"
if [[ -z "$STOW_BIN" && -x "/opt/homebrew/bin/stow" ]]; then
  STOW_BIN="/opt/homebrew/bin/stow"
fi

if [[ -z "$STOW_BIN" ]]; then
  echo "error: stow is required but was not found on PATH or at /opt/homebrew/bin/stow" >&2
  exit 1
fi

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

link_macos_nushell_config() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  local xdg_dir="$HOME/.config/nushell"
  local app_support_dir="$HOME/Library/Application Support"
  local app_support_nu="$app_support_dir/nushell"

  [[ -d "$xdg_dir" ]] || return 0

  mkdir -p "$app_support_dir"

  if [[ -L "$app_support_nu" ]]; then
    local target
    target="$(readlink "$app_support_nu" 2>/dev/null || true)"
    [[ "$target" == "$xdg_dir" ]] && return 0

    echo "warning: leaving existing nushell symlink unchanged: $app_support_nu -> $target"
    return 0
  fi

  if [[ -d "$app_support_nu" ]]; then
    local entry
    for entry in "$app_support_nu"/* "$app_support_nu"/.[!.]* "$app_support_nu"/..?*; do
      [[ -e "$entry" ]] || continue

      local name
      name="${entry##*/}"

      case "$name" in
        config.nu|env.nu|completions)
          rm -rf "$entry"
          ;;
        *)
          if [[ ! -e "$xdg_dir/$name" ]]; then
            mv "$entry" "$xdg_dir/$name"
          else
            echo "warning: keeping existing $xdg_dir/$name; leaving $entry in place"
          fi
          ;;
      esac
    done

    if ! rmdir "$app_support_nu" 2>/dev/null; then
      echo "warning: unable to replace $app_support_nu; remove remaining files manually"
      return 0
    fi
  elif [[ -e "$app_support_nu" ]]; then
    echo "warning: leaving existing non-directory path unchanged: $app_support_nu"
    return 0
  fi

  ln -s "$xdg_dir" "$app_support_nu"
  echo "linked: $app_support_nu -> $xdg_dir"
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

"$STOW_BIN" -t "$HOME" -d "$DOTFILES_DIR" --restow . "$@"

if [[ "$dry_run" == false ]]; then
  link_macos_nushell_config
fi

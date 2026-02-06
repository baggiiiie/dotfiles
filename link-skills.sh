#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)/.config/agents/skills"

targets=(
  "$HOME/.config/amp/skills"
  "$HOME/.claude/skills"
)

for target in "${targets[@]}"; do
  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    echo "removing existing symlink: $target"
    rm "$target"
  elif [ -d "$target" ]; then
    echo "error: $target is a real directory, move its contents first"
    exit 1
  fi

  ln -s "$SKILLS_DIR" "$target"
  echo "linked: $target -> $SKILLS_DIR"
done

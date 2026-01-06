#!/bin/bash

# Get platform type
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS-specific configurations
  export PLATFORM="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux-specific configurations
  export PLATFORM="Linux"
else
  # Fallback for other systems
  export PLATFORM="Unknown"
fi

CURRENT_DIR=$(pwd)

# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle --file="$CURRENT_DIR/Brewfile"

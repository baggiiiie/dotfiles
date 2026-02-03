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

# NOTE: some configs are from: https://github.com/josean-dev/dev-environment-files/blob/main/.zshrc
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# vscode stuff
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

export EDITOR=nvim
export VISUAL=nvim

export MANPAGER='nvim +Man!'

# ---- PATH & ENVIRONMENT CONFIGURATION ----
# Use Zsh's 'path' array tied to $PATH. 'typeset -U' keeps entries unique.
typeset -U path PATH

# 1. Platform Specifics
if [[ "$PLATFORM" == "macOS" ]]; then
  path=("/Users/ydai/.rd/bin" $path)
  export GOPATH="$HOME/go"
  path=($path "/usr/local/go/bin" "$GOPATH/bin" "/opt/homebrew/opt/sqlite/bin")
  path=("/opt/homebrew/opt/postgresql@15/bin" $path)

  # Java version management
  # export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
  # export JAVA_23_HOME=$(/usr/libexec/java_home -v23)
  # alias java17='export JAVA_HOME=$JAVA_17_HOME'
  # alias java23='export JAVA_HOME=$JAVA_23_HOME'
  # export JAVA_HOME=$JAVA_17_HOME

  # SSH configuration
  # eval "$(ssh-agent -s)" > /dev/null 2>&1
  # ssh-add ~/.ssh/ydai_ssh
  # ssh-add ~/.ssh/edgeos_dragen_root.id_rsa

elif [[ "$PLATFORM" == "Linux" ]]; then
  [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  path=($path "/opt/nvim-linux-x86_64/bin")
fi

# 2. Languages & Tools
# NVM (Lazy-load compatible PATH setup)
export NVM_DIR="$HOME/.nvm"
_NODE_BIN="$NVM_DIR/versions/node/$(cat $NVM_DIR/alias/default 2>/dev/null || echo 'v18.0.0')/bin"
path=($_NODE_BIN $path)

# Cargo / Rust
path=($path "$HOME/.cargo/bin")

# Bun
export BUN_INSTALL="$HOME/.bun"
path=("$BUN_INSTALL/bin" $path)

# 3. User & App Binaries (Prepended for priority)
path=(
  "$HOME/bin"
  "/Applications/gg.app/Contents/MacOS"
  $path
)

export PATH
# ------------------------------------------

# Cache brew prefix for performance (saves multiple subprocess calls)
BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"

# Theme configuration
# source $BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# History configuration
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# FZF configuration (must come before vi-mode)
# ZVM_INIT_MODE is needed so ^R works for vi-mode insert mode
ZVM_INIT_MODE=sourcing
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE

# Key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
# Below lines are needed for vi insert mode to call fzf
bindkey -M emacs '^R' fzf-history-widget
bindkey -M vicmd '^R' fzf-history-widget
bindkey -M viins '^R' fzf-history-widget


# ---- FZF -----
# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"
# -- Use fd instead of fzf --
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# source ~/fzf-git.sh/fzf-git.sh

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd|z)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza --tree --level=1 --color=always $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=1 --color=always $realpath'

# Optimize compinit with cache (only check once per day)
autoload -Uz compinit
# Use HOME instead of ZDOTDIR if ZDOTDIR is not set
local zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
# Plugins (load after vi-mode and key bindings)
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# Load syntax highlighting last for better performance
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tool initializations
# eval "$(zoxide init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Aliases
alias ls="eza --icons=always"
alias la="ls -alhO -s name"
alias tree="eza --tree --icons=always"
alias c="xargs echo -n | pbcopy"
alias lg="lazygit"
alias zshrc="nvim ~/.zshrc"
alias tl="tldr"
# alias diff="delta"
alias nv="nvim"
alias cat="bat"
alias venv="source .venv/bin/activate"
alias devsync="bash $HOME/Desktop/repos/work/devsync/dev-sync.sh"
alias ts="tailscale"
alias ta="tmux a"
alias j="jj"
alias jjui="/Users/ydai/Desktop/repos/personal/jjui/jjui/jjui-good"
alias eos="sh /Users/ydai/Desktop/repos/work/scripts/get_servers_info/get_eos_version.sh"
alias hi="terminal-notifier -message '$(basename $(pwd))' -title 'im done' -sound ping"
alias ghist="bash /Users/ydai/Desktop/repos/personal/tries/2025-12-12-jj-git-integration/git-file-history.sh"
alias curl="curlie"
alias dig="doggo"
alias cc="claude --dangerously-skip-permissions"

ZSHRC_DIR="${${(%):-%x}:A:h}"

# Lazy load nvm on first use
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

node() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npx "$@"
}


function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


. "$HOME/.local/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"


# Lazy load jira_me to avoid API call on every shell startup
function jira() {
  # Only fetch jira_me if not already set
  if [[ -z "$jira_me" ]]; then
    jira_me=$(command jira me)
  fi

  if [[ $# -eq 0 ]]; then
    command jira issue list -q "(assignee = $jira_me OR reporter = $jira_me) AND status not in ('Done', 'FIXED')" --order-by priority --updated -30d
  elif [[ $1 == "all" ]]; then
    command jira issue list -q "(assignee = $jira_me OR reporter = $jira_me)" --order-by priority --updated -30d
  else
    command jira "$@"
  fi
}

# echo $ZSHRC_DIR
function chpwd() {
  export $(grep -v '^#' "$ZSHRC_DIR/.env" | xargs)
  if [[ -f "$(pwd)/.env" ]]; then
      source "$(pwd)/.env"
  fi
  case $(pwd) in
    */work*)
        export GH_HOST=git.illumina.com
        export $(grep -v '^#' "$ZSHRC_DIR/.env-work" | xargs)
      ;;
    */personal*)
        export GH_HOST=github.com
      ;;
  esac
}

chpwd

source "$ZSHRC_DIR/.jj-completion.sh"

# bun completions
[ -s "/Users/ydai/.bun/_bun" ] && source "/Users/ydai/.bun/_bun"

# for remote tmux during ssh with ghostty
export TERM=xterm-256color

export TRY_PATH="$HOME/Desktop/repos/personal/tries"
# Lazy load try - only initialize when 'try' command is used
try() {
  unset -f try
  eval "$(ruby ~/.local/try.rb init $TRY_PATH)"
  try "$@"
}

export LESS='-RX'
export LESSCHARSET=utf-8

eval "$(starship init zsh)"

esc() {
  printf '%s\n' "$1" | sed 's/[.[\*^$()+?{|}\/\\]/\\&/g'
}


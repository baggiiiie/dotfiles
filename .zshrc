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
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# vscode stuff
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

export EDITOR=nvim
export VISUAL=nvim

export MANPAGER='nvim +Man!'


# Conditional PATH modifications
if [[ "$PLATFORM" == "macOS" ]]; then
  PATH="/opt/homebrew/bin:$PATH"
  PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
  PATH="/Users/ydai/.rd/bin:$PATH"
  GOPATH=$HOME/go
  PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
  export PATH

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
  # export ARTIFACTORY_APIKEY=cmVmdGtuOjAxOjE3NzI3ODY4NTc6cGd5TURMQWdPaVNQV2RjVERXQkN4MUFpU3VG


elif [[ "$PLATFORM" == "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi


# Cache brew prefix for performance (saves multiple subprocess calls)
BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"

# Theme configuration
source $BREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
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
eval "$(zoxide init zsh)"
# eval "$(zoxide init --cmd cd zsh)"

# Aliases
alias ls="eza --icons=always"
alias la="ls -alh -s name"
alias tree="eza --tree --icons=always"
alias c="xargs echo -n | pbcopy"
alias lg="lazygit"
alias zshrc="nvim ~/.zshrc"
alias sshrc="nvim ~/.ssh/config"
alias vimrc="nvim ~/.vimrc"
alias wezrc="nvim ~/.wezterm.lua"
alias tl="tldr"
# alias diff="delta"
alias nv="nvim"
alias cat="bat"
alias venv="source .venv/bin/activate"
alias k="kubectl"
alias e="eosctl"
alias tx="tmux"
alias devsync="bash $HOME/Desktop/repos/work/devsync/dev-sync.sh"
alias ts="tailscale"
alias ta="tmux a"
alias ll="lazysql"
alias j="jj"
alias jjui="/Users/ydai/Desktop/repos/personal/jjui/jjui/jjui-good"
alias eos="sh /Users/ydai/Desktop/repos/work/scripts/get_servers_info/get_eos_version.sh"
alias hi="terminal-notifier -message '$(basename $(pwd))' -title 'im done' -sound ping"
alias ghist="bash /Users/ydai/Desktop/repos/personal/dotfiles/others/git-file-history.sh"
alias curl="curlie"
alias dig="doggo"
alias claude="claude --dangerously-skip-permissions"

ZSHRC_DIR="${${(%):-%x}:A:h}"

# Lazy load NVM - only load when needed (saves ~800ms startup time)
export NVM_DIR="$HOME/.nvm"
# Add node to PATH without loading full nvm
export PATH="$NVM_DIR/versions/node/$(cat $NVM_DIR/alias/default 2>/dev/null || echo 'v18.0.0')/bin:$PATH"

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


export PATH="/opt/homebrew/opt/sqlite/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"


function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


PATH="$PATH:$HOME/.cargo/bin"

. "$HOME/.local/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"
export PATH="$HOME/bin:/Applications/gg.app/Contents/MacOS:$PATH"

export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export JIRA_AUTH_TYPE=bearer
# JIRA_API_TOKEN in .env-jira
set -a
source $ZSHRC_DIR/.env-jira
set +a

jira_me=$(jira me)
function jira() {
  if [[ $# -eq 0 ]]; then
    command jira issue list -q "(assignee = $jira_me OR reporter = $jira_me) AND status not in ('Done', 'FIXED')" --order-by priority --updated -30d
  else
    command jira "$@"
  fi
}

function gh() {
  if [[ $# -eq 0 ]]; then
    echo "gh: create pr?"
    echo "usage: gh prr [pr-file]"
  elif [[ $1 == "prr" ]]; then
      shift
      bash ~/Desktop/repos/personal/dotfiles/others/git-create-pr.sh "$@"
  else
    command gh "$@"
  fi
}

# echo $ZSHRC_DIR
function chpwd() {
  export $(grep -v '^#' "$ZSHRC_DIR/.env" | xargs)
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
eval "$(ruby ~/.local/try.rb init $TRY_PATH)"

# to allow scripts in ~/bin to be found
export PATH="$HOME/bin:$PATH"

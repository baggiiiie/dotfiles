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

  # alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

elif [[ "$PLATFORM" == "Linux" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi


# Theme configuration
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
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

source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
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
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
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
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --tree --level=1 --color=always $realpath'

autoload -U compinit; compinit
# Plugins (load after vi-mode and key bindings)
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tool initializations
# eval "$(zoxide init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Aliases
alias ls="eza --icons=always"
alias la="ls -alh"
alias tree="eza --tree --icons=always"
alias c="clear"
alias lg="lazygit"
alias zshrc="nvim ~/.zshrc"
alias sshrc="nvim ~/.ssh/config"
alias vimrc="nvim ~/.vimrc"
alias wezrc="nvim ~/.wezterm.lua"
alias tl="tldr"
alias diff="delta"
alias nv="nvim"
alias cat="bat"
alias venv="source .venv/bin/activate"
alias k="kubectl"
alias e="eosctl"
alias tx="tmux"
alias devsync="bash $HOME/Desktop/repos/devsync/dev-sync.sh"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


export EDITOR=nvim
export VISUAL=nvim

export MANPAGER='nvim +Man!'

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

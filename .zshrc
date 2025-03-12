if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# vscode stuff
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# Path configurations
export PATH=/opt/homebrew/bin:$PATH
PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
PATH="/Users/ydai/.rd/bin:$PATH"
export PATH

# History configuration
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify


# FZF configuration (must come before vi-mode)
# ZVM_INIT_MODE is needed so ^R works for vi-mode insert mode
ZVM_INIT_MODE=sourcing
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# SSH configuration
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/ydai_ssh
ssh-add ~/.ssh/edgeos_dragen_root.id_rsa
export ARTIFACTORY_APIKEY=cmVmdGtuOjAxOjE3NzI3ODY4NTc6cGd5TURMQWdPaVNQV2RjVERXQkN4MUFpU3VG

# Tool initializations
eval "$(zoxide init zsh)"

# Theme configuration
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
# Below lines are needed for vi insert mode to call fzf
bindkey -M emacs '^R' fzf-history-widget
bindkey -M vicmd '^R' fzf-history-widget
bindkey -M viins '^R' fzf-history-widget

ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE

# Plugins (load after vi-mode and key bindings)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Java version management
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_23_HOME=$(/usr/libexec/java_home -v23)
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java23='export JAVA_HOME=$JAVA_23_HOME'
export JAVA_HOME=$JAVA_17_HOME

# Aliases
alias ls="eza --icons=always"
alias la="ls -alh"
alias cd="z"
alias lg="lazygit"
alias zshrc="nvim ~/.zshrc"
alias vimrc="nvim ~/.vimrc"
alias wezrc="nvim ~/.wezterm.lua"
alias tl="tldr"
alias diff="diff -y --color=always"
alias nv="nvim"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

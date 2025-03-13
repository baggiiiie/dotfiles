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

# SSH configuration
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/ydai_ssh
ssh-add ~/.ssh/edgeos_dragen_root.id_rsa
export ARTIFACTORY_APIKEY=cmVmdGtuOjAxOjE3NzI3ODY4NTc6cGd5TURMQWdPaVNQV2RjVERXQkN4MUFpU3VG

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

# Completion styling
# make auto-complete case-insensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
# zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'

# Plugins (load after vi-mode and key bindings)
source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab/fzf-tab.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tool initializations
# eval "$(zoxide init zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Java version management
export JAVA_17_HOME=$(/usr/libexec/java_home -v17)
export JAVA_23_HOME=$(/usr/libexec/java_home -v23)
alias java17='export JAVA_HOME=$JAVA_17_HOME'
alias java23='export JAVA_HOME=$JAVA_23_HOME'
export JAVA_HOME=$JAVA_17_HOME

# Aliases
alias ls="eza --icons=always"
alias la="ls -alh"
# alias cd="z"
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

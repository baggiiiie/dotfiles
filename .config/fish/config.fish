# ---- PLATFORM DETECTION ----
switch (uname)
    case Darwin
        set -gx PLATFORM macOS
    case Linux
        set -gx PLATFORM Linux
    case '*'
        set -gx PLATFORM Unknown
end

# ---- EDITOR ----
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx MANPAGER 'nvim +Man!'

# ---- PATH & ENVIRONMENT ----
if test "$PLATFORM" = macOS
    fish_add_path --prepend /Users/ydai/.rd/bin
    set -gx GOPATH "$HOME/go"
    fish_add_path /usr/local/go/bin $GOPATH/bin /opt/homebrew/opt/sqlite/bin
    fish_add_path --prepend /opt/homebrew/opt/postgresql@15/bin
else if test "$PLATFORM" = Linux
    if test -f /home/linuxbrew/.linuxbrew/bin/brew
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    end
    fish_add_path /opt/nvim-linux-x86_64/bin
end

# NVM
set -gx NVM_DIR "$HOME/.nvm"
set -l _default_node (cat $NVM_DIR/alias/default 2>/dev/null; or echo 'v18.0.0')
fish_add_path --prepend "$NVM_DIR/versions/node/$_default_node/bin"

# Cargo / Rust
fish_add_path "$HOME/.cargo/bin"

# Bun
set -gx BUN_INSTALL "$HOME/.bun"
fish_add_path --prepend "$BUN_INSTALL/bin"

# User & App Binaries
fish_add_path --prepend "$HOME/bin" /Applications/gg.app/Contents/MacOS

# Ensure Homebrew is in PATH before using it
if test "$PLATFORM" = macOS; and test -x /opt/homebrew/bin/brew
    fish_add_path --prepend /opt/homebrew/bin /opt/homebrew/sbin
end

# Brew prefix (cached)
if not set -q BREW_PREFIX
    set -gx BREW_PREFIX (brew --prefix)
end

# ---- HISTORY ----
# Fish handles history natively; these are rough equivalents
set -g fish_history default

# ---- FZF ----
set -gx FZF_DEFAULT_COMMAND "fd --hidden --strip-cwd-prefix --exclude .git"
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND "fd --type=d --hidden --strip-cwd-prefix --exclude .git"

set -l show_file_or_dir_preview "if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
set -gx FZF_CTRL_T_OPTS "--preview '$show_file_or_dir_preview'"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --color=always {} | head -200'"

# ---- ALIASES ----
alias ls "eza --icons=always"
alias la "ls -alhO -s name"
alias tree "eza --tree --icons=always"
alias c "xargs echo -n | pbcopy"
alias lg lazygit
alias zshrc "nvim ~/.zshrc"
alias fishrc "nvim ~/.config/fish/config.fish"
alias tl tldr
alias nv nvim
alias cat bat
alias venv "source .venv/bin/activate.fish"
alias devsync "bash $HOME/Desktop/repos/work/devsync/dev-sync.sh"
alias ts tailscale
alias ta "tmux a"
alias j jj
alias jjui /Users/ydai/Desktop/repos/personal/jjui/jjui/jjui-good
alias eos "sh /Users/ydai/Desktop/repos/work/scripts/get_servers_info/get_eos_version.sh"
alias hi "terminal-notifier -message (basename (pwd)) -title 'im done' -sound ping"
alias ghist "bash /Users/ydai/Desktop/repos/personal/tries/2025-12-12-jj-git-integration/git-file-history.sh"
alias curl curlie
alias dig doggo
alias cc "claude --dangerously-skip-permissions"

# ---- FUNCTIONS ----

# jjdiff - Open a file with jj revision diffs in nvim splits
# Usage: jjdiff <file> <rev1> [rev2 ...]
function jjdiff --description "Open a file with jj revision diffs in nvim splits"
    set -l file $argv[1]
    set -e argv[1]
    if test -z "$file" -o (count $argv) -eq 0
        echo "Usage: jjdiff <file> <rev1> [rev2 ...]"
        return 1
    end
    set -l revs $argv
    set -l lua_cmd "local revs = {"
    for r in $revs
        set lua_cmd "$lua_cmd'$r',"
    end
    set lua_cmd "$lua_cmd} "
    set lua_cmd "$lua_cmd local ft = vim.bo.filetype "
    set lua_cmd "$lua_cmd local rel = vim.fn.fnamemodify(vim.fn.expand('%'), ':~:.') "
    set lua_cmd "$lua_cmd for _, rev in ipairs(revs) do "
    set lua_cmd "$lua_cmd   local out = vim.fn.systemlist({'jj','file','show','-r',rev,rel}) "
    set lua_cmd "$lua_cmd   if vim.v.shell_error == 0 then "
    set lua_cmd "$lua_cmd     vim.cmd('vsplit') "
    set lua_cmd "$lua_cmd     local buf = vim.api.nvim_create_buf(false, true) "
    set lua_cmd "$lua_cmd     vim.api.nvim_win_set_buf(0, buf) "
    set lua_cmd "$lua_cmd     vim.api.nvim_buf_set_lines(buf, 0, -1, false, out) "
    set lua_cmd "$lua_cmd     vim.bo[buf].buftype = 'nofile' "
    set lua_cmd "$lua_cmd     vim.bo[buf].modifiable = false "
    set lua_cmd "$lua_cmd     vim.bo[buf].filetype = ft "
    set lua_cmd "$lua_cmd     vim.api.nvim_buf_set_name(buf, rel..' @ '..rev) "
    set lua_cmd "$lua_cmd     vim.cmd('diffthis') "
    set lua_cmd "$lua_cmd   end "
    set lua_cmd "$lua_cmd end "
    set lua_cmd "$lua_cmd vim.cmd('wincmd t') vim.cmd('diffthis')"
    nvim "$file" -c "lua $lua_cmd"
end

# yazi wrapper - cd to last directory on exit
function y --description "Yazi file manager with cwd tracking"
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    set -l cwd (cat "$tmp" 2>/dev/null)
    if test -n "$cwd" -a "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# Lazy-load nvm
function nvm --description "Lazy-load nvm"
    functions --erase nvm node npm npx
    bass source "$NVM_DIR/nvm.sh"
    if test -f "$NVM_DIR/bash_completion"
        bass source "$NVM_DIR/bash_completion"
    end
    nvm $argv
end

function node --description "Lazy-load node via nvm"
    functions --erase nvm node npm npx
    bass source "$NVM_DIR/nvm.sh"
    node $argv
end

function npm --description "Lazy-load npm via nvm"
    functions --erase nvm node npm npx
    bass source "$NVM_DIR/nvm.sh"
    npm $argv
end

function npx --description "Lazy-load npx via nvm"
    functions --erase nvm node npm npx
    bass source "$NVM_DIR/nvm.sh"
    npx $argv
end

# Jira wrapper with lazy-loaded identity
function jira --description "Jira CLI wrapper with smart defaults"
    if not set -q jira_me
        set -g jira_me (command jira me)
    end

    if test (count $argv) -eq 0
        command jira issue list -q "(assignee = $jira_me OR reporter = $jira_me) AND status not in ('Done', 'FIXED')" --order-by priority --updated -30d
    else if test "$argv[1]" = all
        command jira issue list -q "(assignee = $jira_me OR reporter = $jira_me)" --order-by priority --updated -30d
    else
        command jira $argv
    end
end

# chpwd equivalent - auto-run on directory change
function __fish_chpwd --on-variable PWD --description "Auto-load env on directory change"
    set -l zshrc_dir (status dirname 2>/dev/null; or echo "$HOME")
    set -l dotfiles_dir "$HOME/Desktop/repos/personal/dotfiles"

    # Source global .env
    if test -f "$dotfiles_dir/.env"
        for line in (grep -v '^#' "$dotfiles_dir/.env" | grep -v '^\s*$')
            set -l key (string split -m 1 '=' -- $line)[1]
            set -l val (string split -m 1 '=' -- $line)[2]
            if test -n "$key"
                set -gx $key $val
            end
        end
    end

    # Source local .env if present
    if test -f (pwd)/.env
        for line in (grep -v '^#' (pwd)/.env | grep -v '^\s*$')
            set -l key (string split -m 1 '=' -- $line)[1]
            set -l val (string split -m 1 '=' -- $line)[2]
            if test -n "$key"
                set -gx $key $val
            end
        end
    end

    # Context-specific settings
    switch (pwd)
        case '*work*'
            set -gx GH_HOST git.illumina.com
            if test -f "$dotfiles_dir/.env-work"
                for line in (grep -v '^#' "$dotfiles_dir/.env-work" | grep -v '^\s*$')
                    set -l key (string split -m 1 '=' -- $line)[1]
                    set -l val (string split -m 1 '=' -- $line)[2]
                    if test -n "$key"
                        set -gx $key $val
                    end
                end
            end
        case '*personal*'
            set -gx GH_HOST github.com
    end
end

# try - lazy loaded
set -gx TRY_PATH "$HOME/Desktop/repos/personal/tries"
eval (~/.local/try.rb init | string collect)

# esc - escape regex special chars
function esc --description "Escape regex special characters"
    printf '%s\n' "$argv[1]" | sed 's/[.[\*^$()+?{|}\/\\]/\\&/g'
end

# ---- TOOL INITIALIZATIONS ----
set -gx RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"
set -gx LESS -RX
set -gx LESSCHARSET utf-8
set -gx TERM xterm-256color

# Zoxide (replaces cd)
if type -q zoxide
    zoxide init --cmd cd fish | source
end

# Atuin
if type -q atuin
    atuin init fish --disable-up-arrow | source
end

# Starship prompt
# if type -q starship
#     starship init fish | source
# end

# Run chpwd on startup
__fish_chpwd

# Bun completions
if test -f "$HOME/.bun/_bun.fish"
    source "$HOME/.bun/_bun.fish"
end

# ---- ZEROBREW ----
set -gx ZEROBREW_DIR /Users/ydai/.zerobrew
set -gx ZEROBREW_BIN /Users/ydai/.zerobrew/bin
set -gx ZEROBREW_ROOT /opt/zerobrew
set -gx ZEROBREW_PREFIX /opt/zerobrew/prefix
set -gx PKG_CONFIG_PATH "$ZEROBREW_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"

# SSL/TLS certificates
if test -f "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
    set -gx CURL_CA_BUNDLE "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
    set -gx SSL_CERT_FILE "$ZEROBREW_PREFIX/opt/ca-certificates/share/ca-certificates/cacert.pem"
else if test -f "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
    set -gx CURL_CA_BUNDLE "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
    set -gx SSL_CERT_FILE "$ZEROBREW_PREFIX/etc/ca-certificates/cacert.pem"
else if test -f "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
    set -gx CURL_CA_BUNDLE "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
    set -gx SSL_CERT_FILE "$ZEROBREW_PREFIX/share/ca-certificates/cacert.pem"
end

if test -d "$ZEROBREW_PREFIX/etc/ca-certificates"
    set -gx SSL_CERT_DIR "$ZEROBREW_PREFIX/etc/ca-certificates"
else if test -d "$ZEROBREW_PREFIX/share/ca-certificates"
    set -gx SSL_CERT_DIR "$ZEROBREW_PREFIX/share/ca-certificates"
end

fish_add_path --prepend "$ZEROBREW_BIN" "$ZEROBREW_PREFIX/bin"

# VSCode shell integration
if test "$TERM_PROGRAM" = vscode
    if type -q code
        source (code --locate-shell-integration-path fish)
    end
end

# Source local env file
if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end

fish_vi_key_bindings
bind vv edit_command_buffer
bind \t fzf-tab-widget
bind -M insert \t fzf-tab-widget

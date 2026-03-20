# config.nu - Nushell configuration, aliases, and tool initializations

$env.config.completions.algorithm = "fuzzy"

$env.config.history.file_format = "Sqlite"

# ---- Cargo env ----
# Inline instead of sourcing ~/.cargo/env.nu (which uses deprecated home-path)
use std/util "path add"
path add $"($nu.home-dir)/.cargo/bin"

# ---- Vi mode ----
$env.config.edit_mode = "vi"
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"

# ---- Aliases ----
alias lg = lazygit
alias tl = tldr
alias nv = nvim
alias cat = bat
alias venv = bash -c "source .venv/bin/activate && exec $SHELL"
alias devsync = bash $"($nu.home-dir)/repos/work/devsync/dev-sync.sh"
alias ts = tailscale
alias ta = tmux a
def j [...args: string] {
    if ($args | is-empty) {
        ^/Users/ydai/repos/personal/jjui/jjui/jjui-good
    } else {
        ^jj ...$args
    }
}
alias eos = sh /Users/ydai/repos/work/scripts/get_servers_info/get_eos_version.sh
alias ghist = bash /Users/ydai/repos/personal/tries/2025-12-12-jj-git-integration/git-file-history.sh
alias curl = curlie
alias dig = doggo
alias cc = claude --dangerously-skip-permissions

# c - copy stdin to clipboard
def c [] { str trim | pbcopy }

# hi - notification when done
def hi [] {
    let dir = ($env.PWD | path basename)
    terminal-notifier -message $dir -title "im done" -sound ping
}

# y - yazi with directory change
def --env y [...args: string] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp | str trim)
    if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
    }
    rm -f $tmp
}

# jira - lazy-loaded jira shortcut
def jira [...args: string] {
    let jira_me = (^jira me | str trim)
    if ($args | is-empty) {
        let query = $"\(assignee = '($jira_me)' OR reporter = '($jira_me)'\) AND status not in \('Done', 'FIXED'\)"
        ^jira issue list -q $query --order-by priority --updated -30d
    } else if ($args.0 == "all") {
        let query = $"\(assignee = '($jira_me)' OR reporter = '($jira_me)'\)"
        ^jira issue list -q $query --order-by priority --updated -30d
    } else {
        ^jira ...$args
    }
}

# ---- Auto-load .env files on directory change (mirrors zsh chpwd) ----
const ZSHRC_DIR = "/Users/ydai/repos/personal/dotfiles"

def --env load-dotenv [path: string] {
    if ($path | path exists) {
        let entries = (open $path
            | lines
            | where { |line| ($line | str trim) != "" and not ($line | str starts-with "#") })
        for line in $entries {
            let idx = ($line | str index-of "=")
            if $idx >= 0 {
                let key = ($line | str substring 0..<($idx) | str trim)
                let value = ($line | str substring ($idx + 1).. | str trim)
                load-env { ($key): $value }
            }
        }
    }
}

def --env apply-env-for-pwd [] {
    load-dotenv $"($ZSHRC_DIR)/.env"

    if ($"($env.PWD)/.env" | path exists) {
        load-dotenv $"($env.PWD)/.env"
    }

    if ($env.PWD | str contains "/work") {
        $env.GH_HOST = "git.illumina.com"
        load-dotenv $"($ZSHRC_DIR)/.env-work"
    } else if ($env.PWD | str contains "/personal") {
        $env.GH_HOST = "github.com"
    }
}

# Run once at startup
apply-env-for-pwd

# Hook to run on every directory change
$env.config.hooks.env_change = {
    PWD: [{ |before, after| apply-env-for-pwd }]
}

# ---- Tool initializations ----
# Zoxide (z/zi commands, keeps built-in cd intact)
source ($nu.default-config-dir | path join "vendor/autoload/zoxide.nu")
alias z = __zoxide_z
alias zi = __zoxide_zi

# https://www.nushell.sh/book/line_editor.html#keybindings
$env.config.keybindings ++= [{
    name: change_dir_with_fzf
    modifier: CONTROL
    keycode: Char_y
    mode: emacs
    event: {
        send: executehostcommand,
        cmd: "cd (ls | where type == dir | each { |row| $row.name} | str join (char nl) | fzf | decode utf-8 | str trim)"
    }
}]

$env.config.keybindings ++= [
    {
        name: fzf_files
        modifier: control
        keycode: char_t
        mode: [emacs, vi_normal, vi_insert]
        event: [
          {
            send: executehostcommand
            cmd: "
              let fzf_ctrl_t_command = \"rg --files | fzf --preview 'bat --color=always --style=full --line-range=:500 {}'\";
              let result = nu -c $fzf_ctrl_t_command;
              commandline edit --append $result;
              commandline set-cursor --end
            "
          }
        ]
    }
]

$env.config.keybindings ++= [
    {
        name: edit_buffer_in_nvim
        modifier: control
        keycode: char_g
        mode: [emacs, vi_normal, vi_insert]
        event: {
            send: openeditor
        }
    }
]

$env.config.buffer_editor = "nvim"

$env.config.table.mode = 'rounded'

# ---- PROMPT ----
# Put the input on a new line below the prompt info
let orig_prompt = $env.PROMPT_COMMAND
$env.PROMPT_COMMAND = {|| $"(do $orig_prompt)\n" }
$env.PROMPT_INDICATOR = "➜ "
$env.PROMPT_INDICATOR_VI_INSERT = "➜ "
$env.PROMPT_INDICATOR_VI_NORMAL = "➜ "

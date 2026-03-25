# env.nu - Environment variables and PATH configuration for Nushell

# ---- EDITOR ----
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.MANPAGER = "nvim +Man!"

# ---- PLATFORM DETECTION ----
let platform = if (sys host | get name) == "Darwin" { "macOS" } else if (sys host | get name) == "Linux" { "Linux" } else { "Unknown" }

# ---- XDG BASE DIRS ----
# Many cross-platform CLIs (including lazygit) use these instead of macOS
# ~/Library/Application Support paths when they are set.
$env.XDG_CONFIG_HOME = $"($nu.home-dir)/.config"
$env.XDG_CACHE_HOME = $"($nu.home-dir)/.cache"
$env.XDG_DATA_HOME = $"($nu.home-dir)/.local/share"
$env.XDG_STATE_HOME = $"($nu.home-dir)/.local/state"

# ---- PATH CONFIGURATION ----
# Start with the inherited PATH
$env.PATH = ($env.PATH | split row (char esep))

# User & App binaries (highest priority)
$env.PATH = ($env.PATH | prepend [
    $"($nu.home-dir)/bin"
    $"($nu.home-dir)/.npm-global/bin"
    "/Applications/gg.app/Contents/MacOS"
])

# Bun
$env.BUN_INSTALL = $"($nu.home-dir)/.bun"
$env.PATH = ($env.PATH | prepend $"($env.BUN_INSTALL)/bin")

# Cargo / Rust
$env.PATH = ($env.PATH | append $"($nu.home-dir)/.cargo/bin")

# Platform-specific paths
if $platform == "macOS" {
    $env.GOPATH = $"($nu.home-dir)/go"
    $env.PATH = ($env.PATH
        | prepend $"($nu.home-dir)/.rd/bin"
        | prepend "/opt/homebrew/opt/postgresql@15/bin"
        | append "/usr/local/go/bin"
        | append $"($nu.home-dir)/go/bin"
        | append "/opt/homebrew/opt/sqlite/bin"
        | append "/usr/local/bin"
    )
}

# Homebrew
if ("/opt/homebrew/bin/brew" | path exists) {
    $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin" | prepend "/opt/homebrew/sbin")
}

# ~/.local/bin
$env.PATH = ($env.PATH | prepend $"($nu.home-dir)/.local/bin")

# ---- FZF ----
$env.FZF_DEFAULT_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
$env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
$env.FZF_ALT_C_COMMAND = "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
$env.FZF_CTRL_T_OPTS = "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
$env.FZF_ALT_C_OPTS = "--preview 'eza --tree --color=always {} | head -200'"

# ---- RIPGREP ----
$env.RIPGREP_CONFIG_PATH = $"($nu.home-dir)/.ripgreprc"

# ---- TERMINAL ----
$env.TERM = "xterm-256color"
$env.LESS = "-RX"
$env.LESSCHARSET = "utf-8"

# ---- ZEROBREW ----
$env.ZEROBREW_DIR = $"($nu.home-dir)/.zerobrew"
$env.ZEROBREW_BIN = $"($nu.home-dir)/.zerobrew/bin"
$env.ZEROBREW_ROOT = "/opt/zerobrew"
$env.ZEROBREW_PREFIX = "/opt/zerobrew/prefix"
$env.PKG_CONFIG_PATH = $"($env.ZEROBREW_PREFIX)/lib/pkgconfig:(($env | get -o PKG_CONFIG_PATH) | default '')"

# Zerobrew SSL/TLS certificates
let cacert_paths = [
    $"($env.ZEROBREW_PREFIX)/opt/ca-certificates/share/ca-certificates/cacert.pem"
    $"($env.ZEROBREW_PREFIX)/etc/ca-certificates/cacert.pem"
    $"($env.ZEROBREW_PREFIX)/share/ca-certificates/cacert.pem"
]
for p in $cacert_paths {
    if ($p | path exists) {
        $env.CURL_CA_BUNDLE = $p
        $env.SSL_CERT_FILE = $p
        break
    }
}

let certdir_paths = [
    $"($env.ZEROBREW_PREFIX)/etc/ca-certificates"
    $"($env.ZEROBREW_PREFIX)/share/ca-certificates"
]
for p in $certdir_paths {
    if ($p | path exists) {
        $env.SSL_CERT_DIR = $p
        break
    }
}

# Zerobrew PATH
$env.PATH = ($env.PATH | prepend $env.ZEROBREW_BIN | prepend $"($env.ZEROBREW_PREFIX)/bin")

# ---- TRY ----
$env.TRY_PATH = $"($nu.home-dir)/repos/personal/tries"

# ---- Deduplicate PATH ----
$env.PATH = ($env.PATH | uniq)



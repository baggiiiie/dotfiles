### fzf key-bindings for fish 4+ ###

function fzf_key_bindings
    if not type -q fzf
        echo "fzf was not found in path." >&2
        return 1
    end

    function __fzf_defaults
        test -n "$FZF_TMUX_HEIGHT"; or set -l FZF_TMUX_HEIGHT 40%
        string join ' ' -- \
            "--height $FZF_TMUX_HEIGHT --min-height=20+ --ignore-case --bind=ctrl-z:ignore" $argv[1] \
            (test -r "$FZF_DEFAULT_OPTS_FILE"; and string join -- ' ' <$FZF_DEFAULT_OPTS_FILE) \
            $FZF_DEFAULT_OPTS $argv[2..-1]
    end

    function __fzfcmd
        test -n "$FZF_TMUX_HEIGHT"; or set -l FZF_TMUX_HEIGHT 40%
        if test -n "$FZF_TMUX_OPTS"
            echo "fzf-tmux $FZF_TMUX_OPTS -- "
        else if test "$FZF_TMUX" = 1
            echo "fzf-tmux -d$FZF_TMUX_HEIGHT -- "
        else
            echo fzf
        end
    end

    function __fzf_parse_commandline -d 'Parse the current command line token and return split of existing filepath, fzf query, and optional -option= prefix'
        set -l fzf_query ''
        set -l prefix ''
        set -l dir '.'

        set -l -- match_regex '(?<fzf_query>[\s\S]*?(?=\n?$)$)'
        set -l -- prefix_regex '^-[^\s=]+=|^-(?!-)\S'
        if string match -q -v -- '* -- *' (string sub -l (commandline -Cp) -- (commandline -p))
            set -- match_regex "(?<prefix>$prefix_regex)?$match_regex"
        end

        string match -q -r -- $match_regex (commandline --current-token --tokens-expanded | string collect -N)

        if test -n "$fzf_query"
            set -- fzf_query (path normalize -- $fzf_query)
            set -- dir $fzf_query
            while not path is -d $dir
                set -- dir (path dirname $dir)
            end

            if not string match -q -- '.' $dir; or string match -q -r -- '^\./|^\.$' $fzf_query
                string match -q -r -- '^'(string escape --style=regex -- $dir)'/?(?<fzf_query>[\s\S]*)' $fzf_query
            end
        end

        string escape -n -- "$dir" "$fzf_query" "$prefix"
    end

    # Ctrl+T: search all files/dirs recursively, excluding .jj and .git
    function fzf-file-widget -d "List files and folders"
        set -l commandline (__fzf_parse_commandline)
        set -lx dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]

        set -l show_file_or_dir_preview "bash -c 'if [ -d {} ]; then eza --tree -L 2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"

        set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
          "--reverse --scheme=path" \
          "--multi --print0 --preview \"$show_file_or_dir_preview\"")
        set -lx FZF_DEFAULT_COMMAND "fd --hidden --exclude .git --exclude .jj . '$dir' | sed 's|^\./||'"
        set -lx FZF_DEFAULT_OPTS_FILE

        set -l result
        set result (eval (__fzfcmd) --query=$fzf_query | string split0)
        and commandline -rt -- (string join -- ' ' $prefix(string escape -- $result))' '

        commandline -f repaint
    end

    # Tab: context-aware fzf completion
    function fzf-tab-widget -d "Context-aware fzf tab completion"
        set -l commandline (__fzf_parse_commandline)
        set -lx dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]

        set -l current_cmd (commandline -po)[1] 2>/dev/null

        set -l base_opts "--reverse --no-multi --print0 --select-1"
        set -lx FZF_DEFAULT_OPTS_FILE

        set -l result
        switch "$current_cmd"
            case ssh scp
                set -lx FZF_DEFAULT_OPTS (__fzf_defaults "$base_opts --scheme=default" "--preview 'doggo {}'")
                set -l hosts_cmd "{ grep -oE '^[^ ,]+' ~/.ssh/known_hosts 2>/dev/null | sort -u; awk '/^Host / && !/\\*/ {print \$2}' ~/.ssh/config 2>/dev/null; } | sort -u"
                set result (eval $hosts_cmd | eval (__fzfcmd) --query=$fzf_query | string split0)

            case kill
                set -lx FZF_DEFAULT_OPTS (__fzf_defaults "$base_opts" "--preview 'echo {}' --header 'Select process to kill'")
                set result (ps -eo pid,user,%cpu,%mem,command | tail -n +2 | eval (__fzfcmd) --query=$fzf_query | string split0)
                if test -n "$result"
                    set result (string trim -- $result | string split ' ')[1]
                end

            case export unset echo set
                set -lx FZF_DEFAULT_OPTS (__fzf_defaults "$base_opts" "--preview 'echo \${}'")
                set result (env | string split0 | string replace -r '=.*' '' | sort -u | eval (__fzfcmd) --query=$fzf_query | string split0)

            case cd z
                set -lx FZF_DEFAULT_OPTS (__fzf_defaults "$base_opts --scheme=path" "--preview 'eza --tree -L 2 --color=always {} | head -200'")
                set result (fd --type=d --hidden --no-ignore --max-depth 1 --exclude .git --exclude .jj . "$dir" | string replace -r '^\\./' '' | eval (__fzfcmd) --query=$fzf_query | string split0)

            case '*'
                set -lx FZF_DEFAULT_OPTS (__fzf_defaults "$base_opts --scheme=path" "--preview 'bash -c \"if [ -d {} ]; then eza --tree -L 2 --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi\"'")
                set result (fd --hidden --no-ignore --max-depth 1 --exclude .git --exclude .jj . "$dir" | string replace -r '^\\./' '' | eval (__fzfcmd) --query=$fzf_query | string split0)
        end
        and commandline -rt -- $result

        commandline -f repaint
    end

    function fzf-cd-widget -d "Change directory"
        set -l commandline (__fzf_parse_commandline)
        set -lx dir $commandline[1]
        set -l fzf_query $commandline[2]
        set -l prefix $commandline[3]

        set -lx FZF_DEFAULT_OPTS (__fzf_defaults \
      "--reverse --walker=dir,follow,hidden --scheme=path" \
      "$FZF_ALT_C_OPTS --no-multi --print0")

        set -lx FZF_DEFAULT_OPTS_FILE
        set -lx FZF_DEFAULT_COMMAND "$FZF_ALT_C_COMMAND"

        if set -l result (eval (__fzfcmd) --query=$fzf_query --walker-root=$dir | string split0)
            cd -- $result
            commandline -rt -- $prefix
        end

        commandline -f repaint
    end

    # Ctrl+T: recursive file search
    bind \ct fzf-file-widget
    bind -M insert \ct fzf-file-widget
    # Alt+C: cd widget
    bind \ec fzf-cd-widget
    bind -M insert \ec fzf-cd-widget
    # Tab: context-aware completion
    bind \t fzf-tab-widget
    bind -M insert \t fzf-tab-widget

end
### end: key-bindings.fish ###
fzf_key_bindings

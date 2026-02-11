function fish_prompt
    set -l last_status $status
    set -l stat
    if test $last_status -ne 0
        set stat (set_color brred)"[$last_status]"(set_color normal)
        printf '%s ' $stat
    else
    end

    set_color brcyan
    printf '%s ' (gdate +"%T")
    set_color brblue
    printf '%s' (prompt_pwd --full-length-dirs 4)

    # VCS info: jj if available, otherwise git
    if jj root --quiet >/dev/null 2>&1
        set -l jj_info (jj log -r @ -n 1 --no-graph --color always --ignore-working-copy -T 'surround("(", ")", separate(" ", change_id.shortest(), description.first_line(), bookmarks.join(" "), if(empty, "(empty)")))' 2>/dev/null)
        if test -n "$jj_info"
            set_color normal
            printf ' %s' "$jj_info"
        end
    else
        set_color normal
        printf ' %s' (fish_vcs_prompt)
    end

    set_color normal

    echo

    printf '↪ '
    set_color normal
end

#!/bin/bash
# Save as ~/bin/yank or similar
osc52() {
    buf=$(cat)
    len=$(echo -n "$buf" | wc -c)
    max=74994

    if [ $len -gt $max ]; then
        echo "Input is too large for OSC 52" >&2
        return 1
    fi

    esc="\033]52;c;$(echo -n "$buf" | base64)\a"
    printf "$esc"
}

is_ssh() {
    [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ] && return 0 || return 1
}

if is_ssh; then
    echo "copy over ssh"
    osc52
else
    /usr/bin/pbcopy
fi

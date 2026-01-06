#!/bin/bash
# Save as ~/bin/yank or similar
# Usage: command | yank.sh

# Read from stdin
buf=$(cat)

# Write to pbcopy
echo -n "$buf" | /usr/bin/pbcopy

# Write to OSC52
len=$(echo -n "$buf" | wc -c)
max=74994

if [ $len -gt $max ]; then
    echo "Input is too large for OSC 52" >&2
else
    esc="\033]52;c;$(echo -n "$buf" | base64)\a"
    printf "$esc"
fi

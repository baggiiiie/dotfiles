#!/bin/bash
# Save as ~/bin/yank or similar
# Usage: command | yank.sh

# Read from stdin
buf=$(cat)

# Write to pbcopy
echo -n "$buf" | /usr/bin/pbcopy
echo "$buf" >>/tmp/pbcopy.log

# Write to OSC52
len=$(echo -n "$buf" | wc -c)
max=74994

if [ "$len" -gt "$max" ]; then
    echo "Input is too large for OSC 52" >&2
else
    # Write OSC52 escape to /dev/tty so it reaches the terminal even when stdout is a pipe (e.g. when invoked by a library)
    printf '\033]52;c;%s\a' "$(echo -n "$buf" | base64)" >/dev/tty
fi

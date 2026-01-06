#!/bin/bash
while [[ $# -gt 0 ]]; do
    case $1 in
    -r)
        revision_r="$2"
        shift 2
        ;;
    -t)
        revision_t="$2"
        shift 2
        ;;
    -f)
        revision_f="$2"
        shift 2
        ;;
    *)
        file="$1"
        shift
        ;;
    esac
done

if [[ -n $revision_r ]]; then
    r_option=(-r "$revision_r")
fi
if [[ -n $revision_t ]]; then
    t_option=(--to "$revision_t")
fi
if [[ -n $revision_f ]]; then
    f_option=(--from "$revision_f")
fi

if [[ -n $file ]]; then
    jj diff "${r_option[@]}" "${f_option[@]}" "${t_option[@]}" --color=always "$file"
else
    jj diff "${r_option[@]}" "${f_option[@]}" "${t_option[@]}" --color=always --summary --git | /Users/ydai/Desktop/repos/work/diffnav/diffnav
fi

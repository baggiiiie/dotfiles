function jjdiff --description "Open a file with jj revision diffs in nvim splits"
    set -l file $argv[1]
    set -e argv[1]
    if test -z "$file" -o (count $argv) -eq 0
        echo "Usage: jjdiff <file> <rev1> [rev2 ...]"
        return 1
    end
    set -l rev_list (string join '","' -- $argv)
    nvim "$file" --cmd "let g:jjdiff_revs = [\"$rev_list\"]" -c "lua require('jjdiff')"
end

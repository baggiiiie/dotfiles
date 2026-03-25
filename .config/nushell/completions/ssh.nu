# SSH host completion

def ssh-host-candidates [] {
    let ssh_dir = ($nu.home-dir | path join ".ssh")
    let config_path = ($ssh_dir | path join "config")
    let known_hosts_path = ($ssh_dir | path join "known_hosts")

    let config_hosts = if ($config_path | path exists) {
        (
            open $config_path
            | lines
            | each { |line|
                let normalized = ($line | str trim | str replace -r '\\s+' ' ')
                if (($normalized | str downcase) | str starts-with "host ") {
                    (
                        $normalized
                        | split row ' '
                        | skip 1
                        | where { |host|
                            $host != "" and not ($host | str contains "*") and not ($host | str starts-with "!")
                        }
                    )
                } else {
                    []
                }
            }
            | flatten
        )
    } else {
        []
    }

    let known_hosts = if ($known_hosts_path | path exists) {
        (
            open $known_hosts_path
            | lines
            | each { |line|
                let first_field = ($line | split row ' ' | first | default "")
                (
                    $first_field
                    | split row ','
                    | each { |host|
                        let normalized = ($host | str trim | str replace -r '^\\[(.+)\\]:\\d+$' '$1')
                        if $normalized == "" or ($normalized | str starts-with "|") {
                            null
                        } else {
                            $normalized
                        }
                    }
                )
            }
            | flatten
            | compact
        )
    } else {
        []
    }

    $config_hosts
    | append $known_hosts
    | flatten
    | uniq
    | sort
}

def ssh-target-position [spans: list<string>] {
    let options_with_values = ["-B" "-b" "-c" "-D" "-E" "-e" "-F" "-I" "-i" "-J" "-L" "-l" "-m" "-O" "-o" "-p" "-Q" "-R" "-S" "-W" "-w"]
    let prior = if ($spans | length) > 2 {
        $spans | skip 1 | reverse | skip 1 | reverse
    } else {
        []
    }

    mut expect_value = false
    mut saw_target = false

    for span in $prior {
        if $expect_value {
            $expect_value = false
        } else if ($options_with_values | any { |opt| $opt == $span }) {
            $expect_value = true
        } else if ($span | str starts-with "-") {
            continue
        } else {
            $saw_target = true
        }
    }

    (not $expect_value) and (not $saw_target)
}

def ssh-host-matches [host: string, query: string] {
    let host_lc = ($host | str downcase)
    let query_lc = ($query | str downcase)

    if $query_lc == "" {
        true
    } else if ($host_lc | str starts-with $query_lc) or ($host_lc | str contains $query_lc) {
        true
    } else {
        let chars = ($query_lc | split chars)
        mut rest = $host_lc
        mut matched = true

        for ch in $chars {
            let idx = ($rest | str index-of $ch)
            if $idx == -1 {
                $matched = false
                break
            }
            $rest = ($rest | str substring ($idx + 1)..)
        }

        $matched
    }
}

def complete-ssh-hosts [spans: list<string>] {
    let current = ($spans | last | default "")
    if (not (ssh-target-position $spans)) or ($current | str starts-with "-") {
        []
    } else {
        let parts = if ($current | str contains "@") {
            $current | split row '@'
        } else {
            []
        }

        let user_prefix = if ($parts | is-empty) {
            ""
        } else {
            $"(($parts | first))@"
        }

        let host_query = if ($parts | is-empty) {
            $current
        } else {
            ($parts | last)
        }

        ssh-host-candidates
        | where { |host| ssh-host-matches $host $host_query }
        | each { |host| $"($user_prefix)($host)" }
    }
}

@complete 'complete-ssh-hosts'
def --wrapped ssh [...args] {
    ^ssh ...$args
}

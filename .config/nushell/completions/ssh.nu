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
                if ($normalized | str starts-with --ignore-case "host ") {
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
    if $query == "" {
        true
    } else if ($host | str starts-with --ignore-case $query) or ($host | str contains --ignore-case $query) {
        true
    } else {
        let host_chars = ($host | split chars)
        let query_chars = ($query | split chars)
        mut host_idx = 0
        mut matched = true

        for query_char in $query_chars {
            mut found = false
            while $host_idx < ($host_chars | length) {
                let host_char = ($host_chars | get $host_idx)
                $host_idx += 1
                if ($host_char | str starts-with --ignore-case $query_char) {
                    $found = true
                    break
                }
            }

            if not $found {
                $matched = false
                break
            }
        }

        $matched
    }
}

def complete-ssh-hosts [place: record] {
    let spans = $place.command
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

# Jira CLI Reference

Tool: [jira-cli](https://github.com/ankitpokhrel/jira-cli) v1.7.0 (ankitpokhrel/jira-cli)
Config: `~/.config/.jira/.config.yml`

## Important: Shell Wrapper

The user has a shell function `jira` that wraps `command jira`. Always use `command jira` to call the binary directly, or rely on the shell function behavior:
- `jira` (no args) → lists issues assigned to/reported by current user, not Done, updated in last 30d
- `jira all` → same but includes Done
- `jira <anything else>` → passes through to `command jira`

## Common Commands

### View an issue
```bash
command jira issue view ISSUE-KEY
command jira issue view ISSUE-KEY --comments 5    # show 5 comments
command jira issue view ISSUE-KEY --raw           # raw JSON
command jira issue view ISSUE-KEY --plain         # plain text
```

### List/search issues
```bash
command jira issue list                               # interactive list
command jira issue list --plain                        # plain table
command jira issue list -q "JQL query"                # raw JQL
command jira issue list -tEpic -sDone                 # by type+status
command jira issue list -s~Open -ax                   # NOT open, unassigned
command jira issue list --paginate 10:50              # pagination (from:limit)
command jira issue list --columns key,assignee,status --plain
command jira issue list -a "user@email" -s "In Progress"
```

### Transition/move an issue
```bash
command jira issue move ISSUE-KEY "In Progress"
command jira issue move ISSUE-KEY Done
command jira issue move ISSUE-KEY "In Progress" --comment "Starting work"
```

### Assign
```bash
command jira issue assign ISSUE-KEY "user@email"
command jira issue assign ISSUE-KEY $(command jira me)   # assign to self
command jira issue assign ISSUE-KEY x                    # unassign
```

### Comment
```bash
command jira issue comment add ISSUE-KEY
```

### Open in browser
```bash
command jira open ISSUE-KEY
```

### Sprints
```bash
command jira sprint list         # top 50 sprints
command jira sprint add          # add issues to sprint
```

### Other
```bash
command jira me                  # show current user
command jira serverinfo          # Jira server info
command jira board list          # list boards
command jira project list        # list projects
```

## Useful Flags (global)
- `-p PROJECT` — override project
- `--debug` — verbose output
- `-c CONFIG` — override config file

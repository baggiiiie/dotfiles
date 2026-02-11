---
name: commit
description: "Use when asked to commit, describe, or finalize changes. Triggers on any commit-related request. Detects whether the repo uses jj before proceeding."
---

# Committing A Change

Manages the commit workflow for repositories using the Jujutsu version control system.

## Pre-check: Detect VCS

Before doing anything, check if the repo uses jj by running `jj root` in the workspace root.

- If it succeeds, proceed with this skill.
- If it fails (not a jj repo), fall back to regular git commands instead and do NOT follow the rest of this skill.

## Key Concepts

- In jj, the working copy is always part of a **change** (no staging area).
- Changes are mutable until they become immutable (e.g., merged to main).
- `jj commit` = `jj describe` + `jj new` (describe the current change and start a new one).
- `jj describe` updates the description without creating a new change.
- Bookmarks are jj's equivalent of Git branches.

## Workflow

1. **Check the repository state.** Run `jj status` to see what files are modified and the current change.

2. **Show the current log.** Run `jj log --limit 10` to understand where the working copy (`@`) is in the change graph.

3. **Review the diff.** Run `jj diff` to see what changes are in the current working copy change.

4. **Determine the commit action** based on the user's request:

   | User wants to...                                           | Command                                        |
   | ---------------------------------------------------------- | ---------------------------------------------- |
   | Finalize current change with a message and start a new one | `jj commit -m "message"`                       |
   | Set/update description without starting a new change       | `jj describe -m "message"`                     |
   | Describe a specific revision                               | `jj describe -r <rev> -m "message"`            |
   | Split current change into multiple changes                 | `jj split <files> -m "message"` |
   | Create a new empty change on top of current                | `jj new`                                       |
   | Create a new change with a message                         | `jj new -m "message"`                          |
   | Create a new change inserted after a specific revision     | `jj new -A <rev>`                              |
   | Create a new change inserted before a specific revision    | `jj new -B <rev>`                              |

5. **Do not push any changes to remote**

6. **Verify the result.** Run `jj log --limit 5` to confirm the commit graph looks correct.

## Commit Message Guidelines

When generating commit messages:

- Use conventional commit format if the project uses it (check existing log with `jj log --limit 20`).
- First line: imperative mood, max 72 characters.
- If the diff is large, include a blank line then a body explaining the "why".
- If it's a bug fix, include the root causes, and the fix.
- Do NOT include jj change IDs or revision IDs in the message.

## Common Patterns

### Amend a previous change

```
jj describe -r <rev> -m "updated message"
```

## Rules

- Always run `jj status` first to understand the current state.
- Never force-push or delete remote bookmarks unless explicitly asked.
- If the working copy is empty (no diff), inform the user — do not create empty commits unless asked.
- Prefer `jj describe` over `jj commit` when the user just wants to set a message on the current change.
- When the user says "commit", use `jj commit -m "..."` (which finalizes and starts a new change).
- When the user says "describe", use `jj describe -m "..."` (which only sets the message).
- Always show the result with `jj log` after committing.

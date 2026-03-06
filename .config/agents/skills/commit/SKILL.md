---
name: commit
description: "Use when asked to commit, describe, or finalize changes. Triggers on any commit-related request. Detects whether the repo uses jj before proceeding."
---

# Committing A Change

Manages the commit workflow for repositories using the Jujutsu version control system.

## Key Concepts

- In jj, the working copy is always part of a **change** (no staging area).
- Changes are mutable until they become immutable (e.g., merged to main).
- `jj commit` = `jj describe` + `jj new` (describe the current change and start a new one).
- `jj describe` updates the description without creating a new change.
- Bookmarks are jj's equivalent of Git branches.

## Workflow

1. **Get ChangeID.** If user didn't provide a ChangeID, assume working copy (`@`).

2. **Review the diff.** Run `jj diff -r $ChangeID -s` to see what changes are in the current working copy change.

3. **Determine the commit action**:

   | Situation                                                | Command                                       |
   | ---------------------------------------------------------- | ---------------------------------------------- |
   | Commit the current change                                  | `jj commit -m "message"`                       |
   | Update the current change's message                        | `jj describe -r $ChangeID -m "message"`                     |
   | Current ChangeID contains file changes that are not modified by you | `jj split -m "message" $files`, where `$files` are the files you've changed                       |

4. **Do not push any changes to remote**

## Commit Message Guidelines

When generating commit messages:

- If the diff is large, include a section explaining the "why" we need the change.
- If it's a bug fix, include the root causes, and the fix. If there's reproduction info, include it.
- If there's trade-offs being discussed, include them.
- If further improvements are possible, include them.

## Rules

- if `jj` command suggest this is not a `jj` repo, exit and inform user.
- Never push anything to remote.
- If the working copy is empty (no diff), inform the user — do not create empty commits unless asked.
- If you see anything unexpected, inform the user before doing anything else.

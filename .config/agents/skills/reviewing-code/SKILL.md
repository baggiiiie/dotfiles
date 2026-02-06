---
name: reviewing-code
description: "Reviews code changes for bugs, security issues, performance problems, and style. Use when asked to review code, check a diff, analyze uncommitted work, or review changes since diverging from a branch."
---

# Code Review Skill

Performs comprehensive code reviews on diffs, uncommitted changes, or modified files.

## Workflow

1. **Determine the diff to review.** Based on the user's request, run the appropriate git command:
   - Uncommitted changes: `git diff` and `git diff --cached`
   - Changes vs a branch: `git diff <branch>...HEAD`
   - Specific commit: `git show <commit>`
   - Specific files: add `-- <paths>` to any of the above
   - If the user doesn't specify, default to uncommitted changes (`git diff HEAD`)

2. **If the diff is empty**, tell the user there are no changes to review and stop.

3. **Read surrounding context.** For each changed file, read the full file (or relevant sections) to understand the broader context beyond the diff hunks.

4. **Run checks across these categories:**

   | Check | What to look for |
   |-------|-----------------|
   | **Bugs** | Logic errors, off-by-one, null/undefined access, race conditions, missing error handling, incorrect return values |
   | **Security** | Injection (SQL, XSS, command), hardcoded secrets/credentials, insecure crypto, path traversal, SSRF, missing auth checks |
   | **Performance** | O(n²) or worse in hot paths, unnecessary allocations, missing indexes, N+1 queries, unbounded growth |
   | **Big-O** | Algorithm complexity issues; suggest better data structures or algorithms |
   | **Error handling** | Swallowed exceptions, missing try/catch, unclear error messages, missing cleanup/finally |
   | **Concurrency** | Data races, deadlocks, missing locks, unsafe shared state |
   | **API design** | Breaking changes, inconsistent naming, missing validation, poor REST conventions |
   | **Types** | Missing or overly broad types (`any`), incorrect generics, type safety gaps |
   | **Tests** | Missing test coverage for new code paths, brittle assertions, test logic bugs |
   | **Style** | Violations of project conventions (check AGENTS.md / existing code for conventions) |

5. **Classify each issue by severity:**
   - **CRITICAL** — Will cause data loss, security breach, or crash in production
   - **HIGH** — Likely bug or significant problem that should be fixed before merge
   - **MEDIUM** — Code smell, maintainability concern, or potential future bug
   - **LOW** — Nitpick, style suggestion, or minor improvement

6. **Present results in this exact format:**

### Code Review Results

**X issues found across Y checks**

| # | Severity | Check | Location | Problem | Why | Fix |
|---|----------|-------|----------|---------|-----|-----|
| 1 | CRITICAL | security | file.py:42 | Unsanitized user input in SQL query | SQL injection allows attackers to read/modify database | Use parameterized queries |
| 2 | HIGH | bugs | api.ts:128 | Null check missing before `.length` | TypeError if response is null | Add optional chaining `?.length` |

**Checks performed:** bugs, security, performance, big-o, error-handling, concurrency, api-design, types, tests, style

Then ask: "Would you like me to fix any of these issues? (e.g., 'fix issue #1' or 'fix issues #2 and #3')"

## Rules

- Number issues sequentially starting from 1.
- Only report real issues — do not pad the list with non-issues.
- If no issues are found, say so clearly: "No issues found across Y checks."
- Link file locations using `file://` URLs for easy navigation.
- When checking style, infer conventions from the project (AGENTS.md, existing code, linter configs) rather than imposing external standards.
- Focus on the *changed* lines, but use surrounding context to understand correctness.

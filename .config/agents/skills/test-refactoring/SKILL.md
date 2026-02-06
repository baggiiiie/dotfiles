---
name: test-refactoring-workflow
description: Systematic workflow for refactoring tests to use shared helpers and reduce duplication
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: refactoring
---

## What I Do

Guide systematic refactoring of test files to reduce duplication by:
- Identifying common patterns across test files
- Extracting shared logic into reusable helpers
- Creating templated configurations with token replacement
- Cleaning up obsolete code after migration

## When to Use Me

Use this skill when:
- Multiple test files have similar boilerplate code
- Test configuration is verbose and repetitive
- There's an existing shared helper that tests aren't fully utilizing
- You want to simplify test maintenance

## Workflow Overview

```
1. Analyze Current State
   ↓
2. Identify Shared Helper Capabilities
   ↓
3. Create/Update Templates
   ↓
4. Refactor Tests (one at a time)
   ↓
5. Update Cleanup Hooks
   ↓
6. Remove Obsolete Code
   ↓
7. Document Learnings
```

## Phase 1: Analyze Current State

### Find Duplicate Patterns
```bash
# Find files with similar patterns
grep -r "pattern_to_find" --include="*.feature" test/

# Count occurrences to prioritize
grep -r "verbose_pattern" --include="*.feature" | wc -l
```

### Map Dependencies
- Which config files do tests read from?
- What helper functions are available but underutilized?
- What parameters are repeated across tests?

### Identify Candidates
Look for tests that:
- Read explicit config when helpers can generate it
- Pass many parameters that have sensible defaults
- Duplicate setup/cleanup logic

## Phase 2: Understand Shared Helpers

### Examine Helper Capabilities
Read the shared helper thoroughly to understand:
- What parameters it accepts
- What defaults it provides
- What it can auto-derive vs what must be explicit

### Identify Default Behaviors
```javascript
// Example: Helper checks for param, uses default if missing
* def value = karate.get('__arg.runParams.someParam', defaultValue)
```

Parameters with defaults can often be omitted from test configs.

### Check for Bugs/Limitations
While reading helpers, note any:
- Hardcoded values that should be configurable
- Missing parameter passthrough
- Inconsistent default handling

Fix these before refactoring tests.

## Phase 3: Create Templated Configurations

### Design Token System
Replace hardcoded values with tokens:
```
Before: "SoftwareVersion,4.4.9"
After:  "SoftwareVersion,<dragenVersion>"
```

### Common Token Patterns
- `<version>` - Software/app versions
- `<name>` - Generated names (runs, projects)
- `<platform>` - Environment-specific values
- `<timestamp>` - Time-based values

### Template Organization
```json
{
    "template_name": "content with <tokens>",
    "variant_name": "different content with <tokens>"
}
```

Key by logical name, not by data folder or other implementation details.

## Phase 4: Refactor Tests

### One Test at a Time
Refactor incrementally:
1. Pick one test file
2. Simplify its configuration
3. Verify it still works conceptually
4. Move to next test

### Simplification Checklist
Remove parameters that:
- [ ] Have sensible defaults in helper
- [ ] Can be derived from other parameters
- [ ] Are implementation details, not test requirements

Add parameters that:
- [ ] Enable better test behavior (waitUntilX, verify flags)
- [ ] Were missing but are now available

### Use Explicit Keys When Needed
When template name differs from default lookup:
```javascript
{
    "app": "appname",
    "templateKey": "specific_template",  // Override default lookup
}
```

## Phase 5: Standardize Cleanup Hooks

### Consistent Pattern
```javascript
* configure afterScenario = function() {
    if(karate.get("testContext")) 
        karate.call('shared/cleanup.feature@cleanup', {context: testContext});
}
```

### Why Conditional Cleanup
- Cleanup only runs if test created resources
- Prevents errors when setup failed early
- Uses standardized helper instead of inline logic

## Phase 6: Remove Obsolete Code

### Find Unused Entries
```bash
# Search for direct references
grep -r "entry_name" --include="*.feature"

# Check indirect references (e.g., via config lookup)
grep -r "configKey" --include="*.json" config/
```

### Safe Removal Process
1. Verify no references exist
2. Remove the entry
3. Validate file format (JSON, YAML, etc.)
4. Commit with clear message

### What NOT to Remove
Keep entries that are:
- Referenced indirectly via config mappings
- Used by tests you haven't refactored yet
- Part of external integrations

## Phase 7: Document Learnings

### Update AGENTS.md
Document framework patterns for future reference:
- Project structure
- Configuration file purposes
- Common patterns and anti-patterns

### Create/Update Skills
Capture reusable knowledge:
- Domain-specific refactoring steps
- Token definitions and usage
- File reference tables

## Anti-Patterns to Avoid

### Don't Refactor Everything at Once
- Change one test, verify, commit
- Easier to debug issues
- Clearer git history

### Don't Remove Before Verifying
- Search thoroughly before deleting
- Some references are indirect
- Config files may map to entries

### Don't Over-Simplify
- Some verbosity is intentional (special cases)
- Keep explicit what needs to be explicit
- Document why certain tests differ

## Success Indicators

Refactoring is successful when:
- Test files are shorter and clearer
- Configuration is in one place (templates)
- Helpers handle common logic
- New tests are easy to write using patterns
- Old cruft is cleaned up

## Commit Strategy

### Logical Commits
1. Fix helper bugs first (separate commit)
2. Add templates (separate commit)
3. Refactor tests (can batch related tests)
4. Update cleanup hooks (with test changes)
5. Remove obsolete code (separate commit)
6. Add documentation (separate commit)

### Clear Messages
```
fix: correct parameter passthrough in e2e_helper
feat: add tokenized templates for app configs
refactor: simplify methylation and somatic test runParams
chore: remove unused legacy config entries
docs: add test framework patterns to AGENTS.md
```

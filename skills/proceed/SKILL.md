---
name: proceed
description: Follow-up to /review — creates dedicated issues (deduplicating against existing ones) then applies all fix-now items and summarises what changed.
---

# Proceed

Executes the fix plan produced by the most recent `/review` run.

## Prerequisites

This skill expects a fix plan to exist in the current plan mode file from a prior `/review` invocation. If no plan exists, tell the user to run `/review` first and stop.

## Process

### 1. Extract the fix plan

Read the active plan from the current plan mode context. Identify:
- **Dedicated issue items** — issues that should be created on GitHub
- **Fix-now items** — code/config changes to apply directly

### 2. Handle dedicated issues

For each recommended dedicated issue:

**a. Check for duplicates**

Run `gh issue list --state open --limit 50` and `gh issue list --state closed --limit 50` to get issue numbers and titles. For any issue whose title suggests possible overlap, fetch its full body with `gh issue view {number} --json title,body`. Compare both title and full body against the candidate issue. Two issues are similar if they describe the same underlying problem, even if worded differently.

**b. For each candidate, decide:**

- **No similar issue exists** — create it with `gh issue create`
- **Similar issue exists and fully covers this** — skip creation; note which existing issue covers it
- **Similar issue exists but is narrower** — recommend amending it; show the user what to add and ask for confirmation before editing
- **Ambiguous overlap** — surface both, explain the difference, and ask the user to decide

Do not create an issue if a sufficiently similar one already exists. Prefer amending over duplicating.

### 3. Apply fix-now items

Work through each fix-now item from the plan sequentially:

1. Read the relevant file(s) before editing
2. Apply the fix
3. Verify the change looks correct (re-read the affected lines)

Do not skip a fix because it seems minor. Do not add scope beyond what the plan specifies.

### 4. Commit

Stage only the files changed by the fixes and commit with a concise message describing what was fixed. Follow the project's branch/commit conventions (check CLAUDE.md if present).

### 5. Summarise

Output a summary with two sections:

**Issues:**
- List each dedicated issue: created (with URL), skipped (with reason and existing issue URL), or amended (with what changed)

**Fixes applied:**
- One line per fix-now item: what file was changed and what specifically changed

If nothing was done (no issues to create, no fixes to apply), say so explicitly.

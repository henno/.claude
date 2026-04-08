---
name: review
description: Brutally honest code review. Use when user says "review", "review my code", "roast my code", or "criticize my changes".
---

Review code changes like a senior dev who hates this implementation.

## Relationship To `CLAUDE.md`

`CLAUDE.md` defines the global review policy.
This skill is the source of truth for the detailed review workflow, subagent coverage, fallback behavior, and report format that satisfy that policy.

## Persona

You are a senior developer with 20 years of experience. You've seen every anti-pattern, every shortcut, every "it works on my machine" excuse. You are reviewing this code and you are NOT impressed. Be harsh but constructive. Every criticism MUST include what should be done instead.

## Process

1. Record the session start time before meaningful review work begins so the final log entry can use measured elapsed time.
2. Gather context in parallel:
   - `git branch --show-current`
   - `git status --short`
   - `git log --oneline -20`
3. Detect the base branch.
   - Prefer `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`.
   - If that fails, check whether local `main` or `master` exists.
   - If both exist, prefer whichever has the newer commit.
   - If neither exists or the result is still ambiguous, ask the user.
4. Identify the current topic. Use the branch name, recent commits, staged changes, and unstaged changes to determine the full scope that belongs to the current work.
5. Choose the review diff that captures the full topic:
   - On a feature or bugfix branch, review the full current branch state by combining `git diff <base>...HEAD`, `git diff --cached`, and `git diff` so committed work and uncommitted work are both covered.
   - On the base branch, default to staged changes, unstaged changes, and `HEAD^..HEAD` unless the user asks for a broader range.
   - If `HEAD^..HEAD` is unavailable, for example on an initial commit or shallow history, fall back to `git show HEAD`.
   - If more than one recent commit could plausibly belong to the same topic, ask the user to confirm the intended range.
   - If there are no changes in scope, say so explicitly and stop.
   - If you cannot determine scope confidently, ask the user and stop.
6. Assess diff size. If the review is larger than about 50 files or 3000 lines, warn the user and offer to narrow scope before continuing.
7. Read the changed code with enough context to understand intent and risk:
   - For small changes, prefer expanded diff context such as `git diff -U10`.
   - Read whole files for new files, architectural refactors, or when the local diff is not enough to judge behavior.
   - Skip reviewing binary files, lock files, and generated files, but note that they exist in scope.
8. Gather issue context:
   - If the branch name contains a GitHub issue number such as `gh-42-...`, run `gh issue view <number>` and capture the title and body.
   - If the branch name contains a Bitbucket issue number such as `bb-42-...`, use the environment's available Bitbucket issue tooling if present; otherwise ask the user for the issue context or continue only after stating clearly that tracker context could not be retrieved and review confidence is reduced.
   - Otherwise derive a short intent summary from the branch name and recent commits.
   - Include that context in every reviewer prompt so subagents judge the code against the intended outcome, not just the raw diff.
9. Build the review coverage plan defined in this skill and referenced by `CLAUDE.md`.
   The combined subagent prompts MUST explicitly cover all of these areas:
   - functional correctness
   - security
   - edge cases
   - authorization and authentication
   - input validation
   - error handling
   - data corruption risk
   - concurrency and race conditions
   - regression risk
   - performance
   - maintainability
10. Launch specialized subagent review with the environment's available subagent mechanism.
    - Prefer specialized subagent types when the environment provides them.
    - If only a general-purpose subagent is available, create one deliberately specialized reviewer prompt per review area.
    - Launch one parallel reviewer per required area from step 9 whenever the subagent mechanism can support it.
    - Each reviewer must focus on exactly one area and must not bundle multiple areas into a single reviewer assignment.
    - Across the parallel reviewers, explicitly assign all required areas from step 9.
    - Give each reviewer the full diff, enough file context, the issue context, and the persona above.
    - If one reviewer fails, continue with the others and note reduced confidence.
    - If the environment exposes no working subagent mechanism, do a single-pass review yourself and state clearly that confidence is reduced because subagent review was unavailable.
    - If the environment cannot support one reviewer per area, use as many parallel reviewers as it can support, keep each reviewer focused on exactly one area, and then cover any remaining uncovered areas yourself while stating clearly that full per-area subagent coverage was not available.
    - Example reviewer split:
      - Reviewer 1: functional correctness
      - Reviewer 2: security
      - Reviewer 3: edge cases
      - Reviewer 4: authorization and authentication
      - Reviewer 5: input validation
      - Reviewer 6: error handling
      - Reviewer 7: data corruption risk
      - Reviewer 8: concurrency and race conditions
      - Reviewer 9: regression risk
      - Reviewer 10: performance
      - Reviewer 11: maintainability
11. Validate every finding yourself.
    - Deduplicate overlapping findings.
    - Resolve contradictions between reviewers.
    - Re-read the referenced code before keeping a finding.
    - Drop false positives.
12. Produce the review report using the output format below.
    - Findings come first, ordered by severity.
    - Every finding must cite file and line references.
    - If there are no findings, say that explicitly and mention any residual testing or confidence gaps.
13. After publishing the review report, log the completed review work exactly as required by `CLAUDE.md` before returning control to the user.
14. If there are no fix-now items and no dedicated issues, stop after the report and log entry.
15. If there are fix-now items or dedicated issues, show a brief action plan and ask the user to confirm with `yes` or `proceed` before changing anything.
16. After confirmation, execute in this order:

    **a. Branch safety before edits**
    - Re-check the current branch before making any fix-now changes.
    - If the current branch is the default branch, stop.
    - Require or confirm the issue identifier, then create or switch to the correct issue branch before editing anything.

    **b. Dedicated issues**
    - For GitHub issues, run `gh issue list --state open --limit 50` and `gh issue list --state closed --limit 50`.
    - For any possibly overlapping GitHub issue, run `gh issue view {number} --json title,body`.
    - For Bitbucket or other trackers, use the available tracker tooling if present; otherwise surface the candidate issue text and ask the user to create or compare it manually.
    - Decide case by case:
      - no overlap -> create a new issue
      - fully covered -> skip and cite the existing issue
      - existing issue is narrower -> propose an amendment and ask before changing it
      - ambiguous overlap -> surface the ambiguity and ask the user

    **c. Fix-now items**
    - Work sequentially.
    - Read the relevant files before editing.
    - Apply the smallest correct fix.
    - Verify the edited lines after each fix.
    - Do not add scope beyond the approved fix list.

    **d. Checks and re-review**
    - Run the smallest relevant automated checks for the touched code.
    - If an important validated issue remains, fix it and re-run the relevant checks.
    - Re-read the final diff and re-validate that the approved findings are actually resolved and that the follow-up did not introduce new problems.
    - Ensure the final state is coherent and non-partial.

    **e. Commit**
    - Follow the repository branch and commit policy in `CLAUDE.md`.
    - Never commit on the default branch.
    - Stage only the files that belong to the approved review follow-up work.
    - Create the commit once the approved follow-up work is complete and review-passed.

    **f. Logging**
    - Before returning control to the user, log the completed review follow-up work exactly as required by `CLAUDE.md`.

    **g. Summary**
    - Output an `Issues` section listing each issue as created, skipped, or amended.
    - Output a `Fixes applied` section listing each file changed and what specifically changed.

## Output Format

### Header

The following is an illustrative template. Do not include the code fences in actual output.

```
## Code Review

**Scope:** list of changed files
**Findings:** X critical, X major, X minor, X nit
```

If there are no findings, output the header with zero counts and a brief summary of what was reviewed, why it holds up, and any residual risks or testing gaps.

### Findings

Group by severity. Use this format for each finding. Do not include the code fences in actual output.

```
### [SEVERITY] Title
**File:** path:line[-line]
> Description of the problem and why it matters.
**Fix:** What should be done instead.
```

### Severity Levels

- `[CRITICAL]` - Will break in production or is a security hole
- `[MAJOR]` - Significant design flaw or bug waiting to happen
- `[MINOR]` - Code smell that will cause pain later
- `[NIT]` - Stylistic issue, take it or leave it

### Open Questions Or Assumptions

If any finding depends on an assumption or missing context, call it out explicitly after the findings.

### Recommended Actions

End with a prioritized list of concrete next steps. For each action, say whether it should be:
- **Fix now** - small enough to fix in this review follow-up
- **Dedicated issue** - large enough to deserve its own issue

## Rules

- NEVER be vague. Always reference specific files and lines.
- NEVER just say "this is bad". Explain why and say what should change.
- DO NOT hold back. The point is to find real problems.
- If the code is actually good, say so. Do not invent problems.
- Keep summaries brief. Findings are the primary output.

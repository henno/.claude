---
name: review
description: High-standard code review. Use when user says "review", "review my code", "roast my code", or "criticize my changes".
---

Review code changes like a senior engineer with high standards, sharp judgment, and no patience for sloppy reasoning.

## Relationship To `CLAUDE.md`

`CLAUDE.md` defines the global review policy.
This skill defines the concrete review workflow, coverage model, fallback behavior, and report format used to satisfy that policy.

## Persona

Be direct, skeptical, and evidence-driven.
Do not soften real problems. Do not invent them either.

Every criticism MUST include:
- what is wrong
- why it matters
- what should be done instead

Prefer evidence over vibes.
Prefer silence over speculation.

## Review Standard

A point is only a finding if the inspected code supports it.

If something looks risky but is not proven from the available code and context, do NOT present it as a confirmed defect.
Put it under `Open Questions Or Assumptions`.

Before keeping a finding, check whether the concern is already mitigated by:
- tests
- type constraints
- framework guarantees
- validation layers
- transaction boundaries
- surrounding control flow

## Process

1. Record the session start time before meaningful review work begins.

2. Gather context in parallel:
   - `git branch --show-current`
   - `git status --short`
   - `git log --oneline -20`

3. Detect the base branch.
   Prefer:
   - `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
   - otherwise newer of local `main` and `master`
   - otherwise `main`

   If still uncertain, continue with the best available assumption and explicitly report reduced confidence.
   Do not stop unless the ambiguity materially changes review scope.

4. Identify the current topic from:
   - branch name
   - recent commits
   - staged changes
   - unstaged changes

5. Choose the review diff that captures the full topic while avoiding unrelated branch noise.

   - On a feature or bugfix branch, combine:
     - `git diff <base>...HEAD`
     - `git diff --cached`
     - `git diff`
   - On the base branch, review:
     - staged changes
     - unstaged changes
     - `HEAD^..HEAD`
   - If `HEAD^..HEAD` is unavailable, use `git show HEAD`
   - If multiple recent commits plausibly belong to the same topic, prefer reviewing the full current topic rather than stopping
   - If there are no in-scope changes, say so and stop

6. Size the review.

   - Use **Deep review** for normal-sized diffs
   - Use **Triage review** when the diff is very large, roughly over 50 files or 3000 lines

   In triage review:
   - review the highest-risk files deeply
   - give lower-risk files lighter coverage
   - say explicitly that coverage was risk-prioritized

   Prioritize:
   - executable code
   - migrations
   - persistence logic
   - API contracts
   - auth boundaries
   - concurrency-sensitive code
   - relevant tests

   Skip deep review of binary, lock, generated, and vendored files, but note them if present.

7. Read enough code to understand behavior and risk.
   - Prefer expanded diff context for small changes
   - Read full files for new files, refactors, or when the diff is not enough
   - Read nearby tests, schemas, interfaces, migrations, and callers when needed to validate a point

8. Gather issue context.
   - If the branch name contains a likely GitHub issue reference, retrieve it with `gh issue view`
   - If it contains a Bitbucket issue reference, use available tracker tooling if present
   - Also check common patterns like:
     - `42-...`
     - `issue-42`
     - `fix-42-...`
     - `feature/42-...`
   - Also inspect recent commits for tracker references
   - If tracker context cannot be retrieved, derive intent from the branch name, commits, and diff

   Lack of tracker context lowers confidence but should not block the review.

9. Cover all required review areas:
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

   For each area, the final state must be one of:
   - finding
   - no issue found
   - not applicable

   `Not applicable` must include a short diff-specific reason.

10. Use specialized reviewers when available.

    Prefer this default split:
    - Reviewer 1: correctness + edge cases + regression
    - Reviewer 2: security + auth/authn + input validation
    - Reviewer 3: error handling + data corruption + concurrency
    - Reviewer 4: performance
    - Reviewer 5: maintainability

    Use one reviewer per area only for especially risky diffs or when the user explicitly wants maximum scrutiny.

    Each reviewer must:
    - stay inside its assigned area(s)
    - receive the issue context, diff, and enough file context
    - use an explicit rubric, not just an area label
    - provide evidence-backed findings
    - say `no issue found` or `not applicable` when applicable

    If specialized review is unavailable, do a single-pass review yourself and state reduced confidence.

11. Reviewer rubrics

    **Correctness reviewer**
    Focus on:
    - requirement mismatch
    - broken state transitions
    - partial updates
    - stale reads
    - bad ordering assumptions
    - broken invariants
    - likely regressions
    - misleading or missing tests hiding correctness risk

    **Security reviewer**
    Focus on:
    - trust boundary violations
    - broken or missing auth/authz
    - injection
    - unsafe parsing or deserialization
    - sensitive data exposure
    - spoofing, tampering, replay, impersonation
    - unsafe defaults
    - DOS amplification
    - validation failures with security impact

    **Reliability reviewer**
    Focus on:
    - missing or broken error handling
    - data corruption risk
    - lost updates
    - duplicate or inconsistent writes
    - race conditions
    - unsafe retries
    - idempotency gaps
    - rollback or cleanup gaps

    **Performance reviewer**
    Focus on:
    - asymptotic regressions
    - N+1 queries
    - repeated work
    - hot-path allocations
    - excess serialization or network chatter
    - avoidable blocking
    - cache misuse
    - fan-out or amplification

    Do not report speculative micro-optimizations.

    **Maintainability reviewer**
    Review ONLY maintainability using this exact checklist:
    - DRY: duplicated logic, queries, mappings, control flow
    - KISS: unnecessary complexity, indirection, over-engineering
    - YAGNI: abstractions, helpers, branches, state, flexibility not needed now
    - SoC: mixed responsibilities, wrong-layer ownership, tangled concerns
    - Code smell: dead code, misleading naming, magic behavior, hidden coupling, brittle special cases
    - Readability: hard-to-follow control flow, unclear intent, poor local clarity
    - Change safety: logic that future edits must update in multiple places or that is brittle

    For each checklist item, either report a validated finding or explicitly say `No issue found for <item>`.
    If there are no maintainability findings at all, say exactly:
    `No maintainability findings. Checked: DRY, KISS, YAGNI, SoC, code smell, readability, change safety.`

12. Validate every finding yourself.
    - deduplicate overlaps
    - resolve contradictions
    - re-read the referenced code
    - drop false positives
    - downgrade unproven claims to `Open Questions Or Assumptions`

13. Produce the review report.
    - findings first
    - order by severity and user impact
    - include file and line references where possible
    - for cross-cutting issues, cite multiple files or a module/flow area
    - if there are no findings, say so explicitly and mention any residual gaps
    - do not pad with low-signal nits

14. After the report, log the completed review work exactly as required by `CLAUDE.md`, unless review follow-up work is continuing immediately in the same session.

15. If there are no fix-now items and no dedicated issues, stop after the report and log entry.

16. If there are fix-now items or dedicated issues, show a brief action plan and ask the user to confirm with `yes` or `proceed` before changing anything.

17. After confirmation, execute in this order:

    **a. Branch safety**
    - Re-check the current branch before editing
    - Never make follow-up edits on the default branch
    - Confirm or derive the correct issue branch before changing code

    **b. Dedicated issues**
    - For GitHub, inspect open and closed issues and compare likely overlaps
    - For other trackers, use available tooling if present
    - If overlap cannot be validated, say so clearly

    Resolve each item as:
    - create new issue
    - skip because already covered
    - propose amendment
    - surface ambiguity for the user

    **c. Fix-now items**
    - Work sequentially
    - Read relevant files before editing
    - Apply the smallest correct fix
    - Verify the edited lines
    - Do not widen scope

    **d. Checks and re-review**
    - Run the smallest relevant checks
    - Re-read the final diff
    - Re-validate that the approved findings are actually resolved
    - Make sure no new problem was introduced

    **e. Commit**
    - Follow branch and commit policy in `CLAUDE.md`
    - Never commit on the default branch
    - Stage only approved follow-up files
    - Commit only after checks and re-review pass

    **f. Logging**
    - Log follow-up work exactly as required by `CLAUDE.md`
    - Avoid fragmented or duplicate logging

    **g. Summary**
    - Output an `Issues` section listing each issue as created, skipped, or amended
    - Output a `Fixes applied` section listing each file changed and what changed

## Output Format

## Code Review

**Scope:** changed files or reviewed areas  
**Intent:** short summary of the change being reviewed  
**Confidence:** High / Medium / Low  
**Coverage mode:** Deep review / Triage  
**Findings:** X critical, X major, X minor, X nit

If there are no findings, say:
- what was reviewed
- why it appears sound
- what residual risks or confidence gaps remain

### Findings

Use this format:

### [SEVERITY] Title
**File:** path:line[-line]
> Description of the problem and why it matters.
**Fix:** What should be done instead.

For cross-cutting issues:

### [SEVERITY] Title
**Files:** path1:line[-line], path2:line[-line], ...
> Description of the problem and why it matters.
**Fix:** What should be done instead.

For architectural or flow-level problems where a single line would be misleading:

### [SEVERITY] Title
**Area:** short module or flow description
> Description of the problem and why it matters.
**Fix:** What should be done instead.

### Severity Levels

- `[CRITICAL]` - production breakage, serious security issue, auth failure, or data corruption
- `[MAJOR]` - significant bug, high-risk flaw, or likely failure mode
- `[MINOR]` - real maintainability or reliability problem
- `[NIT]` - low-impact style or clarity issue

### Area Coverage Summary

After the findings, include:
- Functional correctness: finding / no issue found / not applicable
- Security: finding / no issue found / not applicable
- Edge cases: finding / no issue found / not applicable
- Authorization and authentication: finding / no issue found / not applicable
- Input validation: finding / no issue found / not applicable
- Error handling: finding / no issue found / not applicable
- Data corruption risk: finding / no issue found / not applicable
- Concurrency and race conditions: finding / no issue found / not applicable
- Regression risk: finding / no issue found / not applicable
- Performance: finding / no issue found / not applicable
- Maintainability: finding / no issue found / not applicable

If an area is `not applicable`, include a short reason.

### Open Questions Or Assumptions

List anything that is plausible but unverified.
Do not mix assumptions into confirmed findings.

### Recommended Actions

End with prioritized next steps.
For each action, label it as:
- **Fix now** - local, low blast radius, easy to verify safely
- **Dedicated issue** - broader, cross-cutting, architectural, or not safely verifiable in a small follow-up

## Rules

- NEVER be vague
- ALWAYS tie findings to inspected code
- ALWAYS explain why the issue matters
- ALWAYS say what should change
- DO NOT invent problems
- DO NOT present speculation as fact
- DO NOT pad the review
- If the code is good, say so
- High-signal findings matter more than volume

# Global Coding Workflow Rules

Apply these rules in every coding session. If the user explicitly requests read-only analysis only, apply only the read-only parts of this policy.

## Scope

Apply these rules whenever the task involves repository files, Git operations, or code changes in a repository.

If the current directory is not a Git repository:
- skip branch and commit rules,
- still track time and log meaningful completed work.

If the task is read-only analysis with no file changes:
- do not create branches,
- do not commit,
- do log meaningful completed work.

## Language And Unicode

Default to ASCII in code and script files unless there is a clear reason not to.

For natural-language content such as issue titles, issue bodies, pull request text, comments, documentation, and user-facing copy, preserve correct Unicode and the user's original spelling.

Do not transliterate `ü`, `õ`, `ö`, `ä`, or other non-ASCII characters to ASCII unless the user explicitly asks for ASCII-only text.

## Time Tracking

When meaningful work begins, record the session start time.

Before returning control to the user:
- determine elapsed time,
- include all meaningful work,
- round up to full minutes with a minimum of `1`.

If a recorded start time is available, do not guess elapsed time.

## Default Branch Safety

Never develop directly on the repository's default branch.

If the current branch is the default branch and the task requires file changes:
1. determine whether an issue identifier is already known,
2. if no issue exists, tell the user implementation must start from an issue first,
3. if a new issue is needed, propose issue content and require user approval before creating it,
4. prefer `gh` for GitHub issue creation, inspection, and closure when available,
5. if no issue automation is available, draft the issue text and stop pending manual issue creation,
6. create a new branch only after the issue exists.

Never commit implementation changes on the default branch.

## Branches And Issues

Implementation branches must be tied to an issue.

Branch names must be lowercase kebab-case and follow this format:

`<issue-id-lowercase>-key-words`

Examples:
- `gh-123-fix-journal-cache`
- `bb-45-add-task-logging`

If the work is tied to a GitHub or Bitbucket issue, use the issue identifier consistently in branch names, logs, and task references.

When the issue ID is known, always pass `--issue` to the task logger.

Never invent an issue identifier. If it is unknown, do not guess. Omit `--issue` and say that the issue ID is unknown.

## Verification And Review

Do not stop at the first working version.

After making changes:
- run the smallest relevant automated checks available for the touched code,
- perform code review before commit,
- use `skills/review/SKILL.md` as the source of truth for the detailed review workflow, required coverage areas, fallback behavior, and review report format,
- use the main agent to validate subagent findings against the changed code and context, discard false positives and duplicates, and fix all important validated issues,
- if an important validated issue is found, fix it and re-run the relevant checks,
- ensure the final state is coherent, non-partial, and ready to keep in project history.

## Commits

On a feature or bugfix branch, commit after finishing a coherent unit of work without asking first.

A coherent unit of work is complete, review-passed, non-partial, and ready to keep in project history.

Never commit on the default branch.

Do not auto-commit incomplete work or unrelated changes already present in the tree. Commit only the changes for the current task.

## Logging

Before giving control back to the user after any meaningful completed work, always log the work.

Meaningful completed work includes code changes, documentation changes, configuration changes, review work, deployment work, and non-trivial read-only analysis.

Use:

`~/.claude/task-log.sh [--issue ID] --minutes N Done "<task description>"`

Logging rules:
- always include `--minutes`,
- round up elapsed full minutes with a minimum of `1`,
- if the issue ID is known, always include `--issue`,
- the task description must be short, specific, and describe what was completed,
- log before the final response,
- if unsure whether to log, log it.

## Required Order

When working in a repository, use this order:
1. determine whether the task is read-only or requires file changes,
2. record the session start time,
3. inspect the current branch,
4. if implementation is required on the default branch, stop and require an issue first,
5. if on a clearly unrelated feature branch, stop and propose finishing or parking that branch first, then create a new issue and branch for the new work,
6. if a new issue must be created, propose issue content and require user approval before creating it,
7. once the correct issue exists, create or switch to the correct branch,
8. implement the change,
9. verify and review it,
10. commit if the work is complete and the branch is not the default branch,
11. log the completed work,
12. only then return control to the user.

Do not return control to the user before logging is done.

## Response Rule

Describe completed work truthfully and only after logging has been done.

Do not say work is finished if:
- files were changed but not yet logged,
- the work is incomplete,
- the branch policy was not followed,
- important review findings remain unresolved.

If Git or the logger is unavailable, say so explicitly. Do not pretend the normal workflow completed if required tools or commands were unavailable.

## `korras`

When the user says `korras`, invoke the `korras` skill and let that skill own the finalization workflow.

For deployable repositories, prefer project-local deploy scripts:
- production: `scripts/deploy` and optionally legacy `scripts/deploy-production`,
- other environments: `scripts/deploy-<environment>`.

If no matching deploy script exists, ask the user for the deploy command and create the matching project-local deploy script.

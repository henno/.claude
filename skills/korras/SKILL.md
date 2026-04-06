---
name: korras
description: Finalize and deploy work. Supports feature branches and default-branch latest-commit deploys, prefers project deploy scripts, creates missing deploy scripts from a user-provided command, and uses production by default when the user says "korras".
---

# Korras (Deploy)

Automated deploy workflow. "Korras" is Estonian for "done" / "in order".

## Process

### 1. Resolve target environment

- If the user says only `korras`, treat it as a production deploy.
- If the user says `korras <environment>`, use that environment.
- Prefer project-local deploy scripts:
  - production: `scripts/deploy` and then legacy `scripts/deploy-production`
  - other environments: `scripts/deploy-<environment>`
- If no matching deploy script exists, ask the user for the exact deploy command and generate the matching project-local deploy script with:

```sh
node "$CLAUDE_SKILL_DIR/scripts/create-deploy-script.js" <environment> "<command>"
```

### 2. Assess current state

Run in parallel:
- `git branch --show-current`
- `git status --short`
- `git log --oneline -5`
- `bash "$CLAUDE_SKILL_DIR/scripts/get-default-branch.sh"`
- `bash "$CLAUDE_SKILL_DIR/scripts/parse-branch.sh"`

### 3. Use the helper flow script for deterministic steps

The main entrypoint is:

```sh
bash "$CLAUDE_SKILL_DIR/scripts/korras-flow.sh" <environment>
```

This script handles the fast path:
- default-branch detection,
- historical and current branch-name parsing,
- deploy-script discovery,
- rebase onto the latest default branch,
- squash merge,
- push,
- deploy,
- GitHub issue close when applicable,
- branch deletion.

It stops immediately when a problem needs judgment.

### 4. If the flow script stops, handle the problem and rerun it

Common blocked states:
- `REASON=dirty_worktree`: review the changes, commit them if appropriate, then rerun the same command.
- `REASON=rebase_conflict`: resolve conflicts carefully, run `git rebase --continue`, and rerun the same command.
- `REASON=on_default_branch`: use the default-branch review/deploy path below.
- `STATUS=missing`: ask the user for the exact deploy command, create the missing deploy script, then rerun the same command.
- `REASON=detached_head`, `REASON=default_branch_unknown`, or `REASON=missing_origin_remote`: stop and explain the repository state clearly before proceeding.
- `REASON=fetch_failed`: inspect the remote failure and retry only after the fetch problem is understood.

When resolving conflicts:
- read the conflicted file, conflict markers, and relevant recent commits on both sides,
- decide case by case which resolution is best in context,
- do not blindly prefer upstream or branch changes,
- combine both sides when they are complementary,
- only ask the user if the conflict is genuinely ambiguous or high-risk.

### 5. Default-branch latest-commit review/deploy path

Sometimes work is already on the default branch because of manual intervention.
In that case:
- review the latest relevant commit before deploying,
- do not make new implementation changes on the default branch,
- if deployment should proceed, run:

```sh
KORRAS_ALLOW_DEFAULT_BRANCH=1 bash "$CLAUDE_SKILL_DIR/scripts/korras-flow.sh" <environment>
```

This path deploys the latest default-branch state but does not close issues or delete branches.

### 6. Commit message handling

- If the worktree is dirty before running `korras`, create a normal task commit first following the repository's commit workflow.
- The helper flow script finalizes the default-branch squash commit automatically.
- For GitHub issue branches like `gh-123-...`, it uses the issue title as the squash commit message.
- For historical or non-GitHub branch names, it falls back to the current commit subject unless you provide `KORRAS_FINAL_COMMIT_MESSAGE`.

### 7. Logging and wrap-up

- Log the finalization and deployment work before returning control to the user.
- After a successful GitHub release flow, run `gh issue list --state open` and recommend what to pick next, giving preference to bugs and blockers.

### 8. Important rules

- NEVER force push
- NEVER skip pre-commit hooks (`--no-verify`)
- Always rebase the feature branch onto the latest default branch before the final squash merge
- Always use squash merge for feature branches (`git merge --squash`), never regular merge
- Use `-D` to delete the feature branch (squash merge is not a real merge commit, so `-d` would refuse)
- Support historical branch names as well as the current issue-first naming convention
- Treat `korras` with no environment as production by default
- Deploy before closing the issue and deleting the branch
- If any step in the chain fails, stop and diagnose before retrying from that step
- If the deploy command fails, report the error and stop; do not retry blindly

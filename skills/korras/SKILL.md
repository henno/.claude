---
name: korras
description: Deploy workflow - commit, squash-merge feature branch to master (if applicable), push, and deploy to production. Use when user says "korras". Reads deploy command from project CLAUDE.md.
---

# Korras (Deploy)

Automated deploy workflow. "Korras" is Estonian for "done" / "in order".

## Process

### 1. Assess current state

Run in parallel:
- `git branch --show-current`
- `git status --short`
- `git log --oneline -5`

### 2. Determine deploy command

Search the project's `CLAUDE.md` for a deploy command. Look for patterns like:
- `ssh ... && ./topograph restart` or similar remote deploy commands
- A section mentioning "korras" or "deploy" instructions
- A `DEPLOY_CMD` or deploy script reference

If no deploy command is found, skip the deploy step (do not ask).

### 3. Execute as one command chain

**If on a feature branch** — extract `BRANCH` and `NUMBER` from the branch name (format: `GH-{number}-{desc}`), then run everything as a single `&&` chain:

```sh
git add -A && git commit -m "<message>" && git checkout main && git pull --ff-only && git merge --squash "$BRANCH" && git commit -m "$(gh issue view {number} --json title -q .title)" && git push && gh issue close {number} && git branch -D "$BRANCH"
```

If the project has a deploy command, append it:
```sh
... && git branch -D "$BRANCH" && <deploy-command>
```

If there are no uncommitted changes, omit the `git add -A && git commit` prefix.

If `git push` fails, local main is ahead of origin — fix the push issue and re-run `git push` alone. Do not reset main.

**If already on main** — commit any uncommitted changes, then:

```sh
git add -A && git commit -m "<message>" && git push
```

Append the deploy command if one exists.

### 4. After completion

Run `gh issue list --state open` and display the open issues. Recommend which to pick next, giving preference to bugs over features and to issues that unblock others.

### 5. Important rules

- NEVER force push
- NEVER skip pre-commit hooks (--no-verify)
- Always use squash merge for feature branches (`git merge --squash`), never regular merge
- Use `-D` to delete the feature branch (squash merge is not a real merge commit, so `-d` would refuse)
- If any step in the chain fails, stop and diagnose before retrying from that step
- If the deploy command fails, report the error and stop — do not retry blindly

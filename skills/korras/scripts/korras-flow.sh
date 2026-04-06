#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENVIRONMENT="${1:-production}"
ALLOW_DEFAULT_BRANCH="${KORRAS_ALLOW_DEFAULT_BRANCH:-0}"

emit() {
  printf '%s\n' "$1"
}

block() {
  emit 'STATUS=blocked'
  emit "REASON=$1"
  shift
  while [ "$#" -gt 0 ]; do
    emit "$1"
    shift
  done
}

run_step() {
  reason=$1
  shift

  if "$@"; then
    return 0
  fi

  block "$reason" "BRANCH=$(git branch --show-current 2>/dev/null || printf '%s' "$CURRENT_BRANCH")" "DEFAULT_BRANCH=$DEFAULT_BRANCH" "ISSUE_ID=${ISSUE_ID:-}"
  exit 30
}

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  block 'not_git_repo'
  exit 10
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

DEFAULT_BRANCH=$($SCRIPT_DIR/get-default-branch.sh 2>/dev/null) || {
  block 'default_branch_unknown'
  exit 12
}
CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
  block 'detached_head' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
  exit 15
fi

if [ -d "$(git rev-parse --git-path rebase-merge 2>/dev/null)" ] || [ -d "$(git rev-parse --git-path rebase-apply 2>/dev/null)" ]; then
  block 'rebase_in_progress' "BRANCH=$CURRENT_BRANCH" "DEFAULT_BRANCH=$DEFAULT_BRANCH"
  exit 20
fi

DEPLOY_INFO=$(node "$SCRIPT_DIR/resolve-deploy-target.js" "$ENVIRONMENT") || {
  status=$?
  if [ -n "${DEPLOY_INFO:-}" ]; then
    printf '%s\n' "$DEPLOY_INFO"
  else
    block 'deploy_target_lookup_failed'
  fi
  exit "$status"
}

DEPLOY_COMMAND=$(printf '%s\n' "$DEPLOY_INFO" | sed -n 's/^COMMAND=//p')
BRANCH_INFO=$($SCRIPT_DIR/parse-branch.sh "$CURRENT_BRANCH" "$DEFAULT_BRANCH")
ISSUE_TRACKER=$(printf '%s\n' "$BRANCH_INFO" | sed -n 's/^ISSUE_TRACKER=//p')
ISSUE_NUMBER=$(printf '%s\n' "$BRANCH_INFO" | sed -n 's/^ISSUE_NUMBER=//p')
ISSUE_ID=$(printf '%s\n' "$BRANCH_INFO" | sed -n 's/^ISSUE_ID=//p')
if [ "$CURRENT_BRANCH" = "$DEFAULT_BRANCH" ]; then
  if [ "$ALLOW_DEFAULT_BRANCH" != '1' ]; then
    block 'on_default_branch' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
    exit 11
  fi

  if [ -n "$(git status --porcelain)" ]; then
    block 'dirty_worktree' "BRANCH=$CURRENT_BRANCH"
    exit 13
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    block 'missing_origin_remote' "BRANCH=$CURRENT_BRANCH"
    exit 14
  fi

  if ! git fetch origin "$DEFAULT_BRANCH"; then
    block 'fetch_failed' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
    exit 21
  fi

  local_head=$(git rev-parse HEAD)
  remote_head=$(git rev-parse "refs/remotes/origin/$DEFAULT_BRANCH")

  if [ "$local_head" != "$remote_head" ]; then
    if git merge-base --is-ancestor "$local_head" "$remote_head"; then
      run_step default_branch_not_fast_forward git merge --ff-only "origin/$DEFAULT_BRANCH"
    elif git merge-base --is-ancestor "$remote_head" "$local_head"; then
      run_step push_default_branch git push origin "$DEFAULT_BRANCH"
    else
      block 'default_branch_diverged' "BRANCH=$CURRENT_BRANCH" "DEFAULT_BRANCH=$DEFAULT_BRANCH"
      exit 31
    fi
  fi

  run_step deploy_failed sh -lc "$DEPLOY_COMMAND"
  emit 'STATUS=ok'
  emit 'MODE=default_branch_deploy'
  emit "BRANCH=$CURRENT_BRANCH"
  emit "DEFAULT_BRANCH=$DEFAULT_BRANCH"
  emit "ENVIRONMENT=$ENVIRONMENT"
  emit "DEPLOY_COMMAND=$DEPLOY_COMMAND"
  exit 0
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  block 'missing_origin_remote' "BRANCH=$CURRENT_BRANCH"
  exit 14
fi

if [ -n "$(git status --porcelain)" ]; then
  block 'dirty_worktree' "BRANCH=$CURRENT_BRANCH"
  exit 13
fi

if ! git fetch origin "$DEFAULT_BRANCH"; then
  block 'fetch_failed' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
  exit 21
fi

if ! git rebase "origin/$DEFAULT_BRANCH"; then
  block 'rebase_conflict' "BRANCH=$CURRENT_BRANCH" "DEFAULT_BRANCH=$DEFAULT_BRANCH" "ISSUE_ID=$ISSUE_ID"
  exit 20
fi

FINAL_MESSAGE=${KORRAS_FINAL_COMMIT_MESSAGE:-}
if [ -z "$FINAL_MESSAGE" ]; then
  if [ "$ISSUE_TRACKER" = 'GH' ] && [ -n "$ISSUE_NUMBER" ]; then
    if ISSUE_TITLE=$(gh issue view "$ISSUE_NUMBER" --json title -q .title 2>/dev/null); then
      FINAL_MESSAGE="$ISSUE_TITLE (#$ISSUE_NUMBER)"
    else
      FINAL_MESSAGE=$(git log -1 --format=%s)
    fi
  else
    FINAL_MESSAGE=$(git log -1 --format=%s)
  fi
fi

run_step checkout_default_branch git checkout "$DEFAULT_BRANCH"
run_step pull_default_branch git pull --ff-only origin "$DEFAULT_BRANCH"
run_step squash_merge_failed git merge --squash "$CURRENT_BRANCH"
run_step commit_failed git commit -m "$FINAL_MESSAGE"
run_step push_failed git push origin "$DEFAULT_BRANCH"
run_step deploy_failed sh -lc "$DEPLOY_COMMAND"

if [ "$ISSUE_TRACKER" = 'GH' ] && [ -n "$ISSUE_NUMBER" ]; then
  run_step issue_close_failed gh issue close "$ISSUE_NUMBER"
fi

run_step branch_delete_failed git branch -D "$CURRENT_BRANCH"

emit 'STATUS=ok'
emit 'MODE=feature_branch_finalize'
emit "BRANCH=$CURRENT_BRANCH"
emit "DEFAULT_BRANCH=$DEFAULT_BRANCH"
emit "ISSUE_ID=$ISSUE_ID"
emit "ENVIRONMENT=$ENVIRONMENT"
emit "DEPLOY_COMMAND=$DEPLOY_COMMAND"

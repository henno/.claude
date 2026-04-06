#!/bin/sh
set -eu

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' 'ERROR: not in a git repository' >&2
  exit 10
fi

pick_newest_ref() {
  best_ref=''
  best_ts=''

  for ref in "$@"; do
    if ! git show-ref --verify --quiet "$ref"; then
      continue
    fi

    ts=$(git log -1 --format=%ct "$ref" 2>/dev/null || true)
    if [ -z "$ts" ]; then
      continue
    fi

    if [ -z "$best_ref" ] || [ "$ts" -gt "$best_ts" ]; then
      best_ref=$ref
      best_ts=$ts
    fi
  done

  if [ -n "$best_ref" ]; then
    printf '%s\n' "${best_ref##*/}"
    return 0
  fi

  return 1
}

remote_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
if [ -n "$remote_head" ]; then
  printf '%s\n' "${remote_head#origin/}"
  exit 0
fi

if git remote get-url origin >/dev/null 2>&1; then
  default_branch="$(git ls-remote --symref origin HEAD 2>/dev/null | sed -n 's#^ref: refs/heads/\([^[:space:]]*\)[[:space:]]\+HEAD$#\1#p' | sed -n '1p')"
  if [ -n "$default_branch" ]; then
    printf '%s\n' "$default_branch"
    exit 0
  fi

  if newest_remote=$(pick_newest_ref \
    refs/remotes/origin/trunk \
    refs/remotes/origin/main \
    refs/remotes/origin/master \
    refs/remotes/origin/develop); then
    printf '%s\n' "$newest_remote"
    exit 0
  fi
fi

if newest_local=$(pick_newest_ref \
  refs/heads/main \
  refs/heads/master \
  refs/heads/trunk \
  refs/heads/develop); then
  printf '%s\n' "$newest_local"
  exit 0
fi

printf '%s\n' 'ERROR: could not determine default branch' >&2
exit 11

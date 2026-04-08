#!/bin/sh
set -eu

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '%s\n' 'ERROR: not in a git repository' >&2
  exit 10
fi

pick_only_ref() {
  selected_ref=''
  count=0

  for ref in "$@"; do
    if ! git show-ref --verify --quiet "$ref"; then
      continue
    fi

    selected_ref=$ref
    count=$((count + 1))
  done

  if [ "$count" -eq 1 ]; then
    printf '%s\n' "${selected_ref##*/}"
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
  if ls_remote_output=$(git ls-remote --symref origin HEAD 2>&1); then
    default_branch="$(printf '%s\n' "$ls_remote_output" | sed -n 's#^ref: refs/heads/\([^[:space:]]*\)[[:space:]]\+HEAD$#\1#p' | sed -n '1p')"
    if [ -n "$default_branch" ]; then
      printf '%s\n' "$default_branch"
      exit 0
    fi
  else
    printf '%s\n' "WARN: failed to query origin HEAD: $ls_remote_output" >&2
  fi

  if only_remote=$(pick_only_ref \
    refs/remotes/origin/trunk \
    refs/remotes/origin/main \
    refs/remotes/origin/master \
    refs/remotes/origin/develop); then
    printf '%s\n' "$only_remote"
    exit 0
  fi
fi

if only_local=$(pick_only_ref \
  refs/heads/main \
  refs/heads/master \
  refs/heads/trunk \
  refs/heads/develop); then
  printf '%s\n' "$only_local"
  exit 0
fi

printf '%s\n' 'ERROR: could not determine default branch' >&2
exit 11

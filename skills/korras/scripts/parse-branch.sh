#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BRANCH_INPUT="${1:-$(git branch --show-current)}"
DEFAULT_BRANCH="${2:-$($SCRIPT_DIR/get-default-branch.sh)}"

BRANCH_BASENAME=${BRANCH_INPUT##*/}
NORMALIZED=$(printf '%s' "$BRANCH_BASENAME" | tr '[:upper:]_' '[:lower:]-')

if [ "$BRANCH_INPUT" = "$DEFAULT_BRANCH" ] || [ "$BRANCH_BASENAME" = "$DEFAULT_BRANCH" ] || [ "$NORMALIZED" = "$DEFAULT_BRANCH" ]; then
  printf '%s\n' "BRANCH=$BRANCH_INPUT"
  printf '%s\n' "BRANCH_BASENAME=$BRANCH_BASENAME"
  printf '%s\n' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
  printf '%s\n' 'BRANCH_KIND=default_branch'
  exit 0
fi

TRACKER=''
NUMBER=''
ISSUE_ID=''
BRANCH_KIND='other_branch'

case "$NORMALIZED" in
  gh-[0-9]* )
    NUMBER=${NORMALIZED#gh-}
    NUMBER=${NUMBER%%-*}
    TRACKER='GH'
    ISSUE_ID="GH-$NUMBER"
    BRANCH_KIND='issue_branch'
    ;;
  bb-[0-9]* )
    NUMBER=${NORMALIZED#bb-}
    NUMBER=${NUMBER%%-*}
    TRACKER='BB'
    ISSUE_ID="BB-$NUMBER"
    BRANCH_KIND='issue_branch'
    ;;
  [0-9]* )
    NUMBER=${NORMALIZED%%-*}
    TRACKER=''
    ISSUE_ID="$NUMBER"
    BRANCH_KIND='issue_branch'
    ;;
esac

printf '%s\n' "BRANCH=$BRANCH_INPUT"
printf '%s\n' "BRANCH_BASENAME=$BRANCH_BASENAME"
printf '%s\n' "DEFAULT_BRANCH=$DEFAULT_BRANCH"
printf '%s\n' "BRANCH_KIND=$BRANCH_KIND"
printf '%s\n' "ISSUE_TRACKER=$TRACKER"
printf '%s\n' "ISSUE_NUMBER=$NUMBER"
printf '%s\n' "ISSUE_ID=$ISSUE_ID"

#!/bin/bash
# Usage: task-log.sh [--issue ID] [--minutes N] <Started|Finished|Done> <description>
# Example: task-log.sh --issue GH-123 Started "adding user authentication"
# Example: task-log.sh --issue BB-45 --minutes 3 Done "fixed typo in readme"
# Example: task-log.sh --minutes 5 Done "quick config change"

issue=""
minutes=""

while [[ "$1" == --* ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --minutes) minutes="$2"; shift 2 ;;
    *) shift ;;
  esac
done

action="$1"
shift
description="$*"

suffix=""
if [ "$action" = "Done" ] && [ -n "$minutes" ]; then
  suffix=" (${minutes}min)"
fi

if [ -n "$issue" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M') $(pwd | sed "s|$HOME|~|")] $action $issue: $description$suffix" >> ~/tasks.md
else
  echo "[$(date '+%Y-%m-%d %H:%M') $(pwd | sed "s|$HOME|~|")] $action $description$suffix" >> ~/tasks.md
fi

# Sync to Kristella (OpenClaw VM)
scp -q ~/tasks.md root@157.180.21.22:/home/openclaw/.openclaw/workspace/tasks.md 2>/dev/null &

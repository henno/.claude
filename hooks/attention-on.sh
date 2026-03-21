#!/bin/bash
# Send a persistent macOS notification when Claude is waiting for input
# Uses terminal-notifier with -group for per-session notification management

# Read JSON input from stdin
INPUT=$(cat)

# Extract fields
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# Derive project name
PROJECT=""
if [ -n "$CWD" ] && [ "$CWD" != "null" ]; then
  PROJECT=$(basename "$CWD")
fi

# Get git branch
BRANCH=""
if [ -n "$CWD" ] && [ "$CWD" != "null" ] && git -C "$CWD" rev-parse --git-dir &>/dev/null; then
  BRANCH=$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null)
fi

# Read task description
TASK=""
if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
  TASK_FILE="$HOME/.claude/sessions/task_$SESSION_ID"
  if [ -f "$TASK_FILE" ]; then
    TASK=$(cat "$TASK_FILE" 2>/dev/null)
  fi
fi

# Line 1: project @branch
TITLE="${PROJECT:-Claude}"
if [ -n "$BRANCH" ]; then
  TITLE="$TITLE @$BRANCH"
fi

# Line 2: task description
SUBTITLE="${TASK:-}"

# Line 3: last assistant message (strip markdown, truncate)
BODY="Waiting for input"
if [ -n "$LAST_MSG" ] && [ "$LAST_MSG" != "null" ]; then
  # Strip markdown formatting and take first 200 chars
  BODY=$(echo "$LAST_MSG" | sed 's/[*#`_~]//g' | tr '\n' ' ' | sed 's/  */ /g' | head -c 200)
fi

# Group by session_id so we can clear per-session
GROUP="${SESSION_ID:-claude}"

# Build terminal-notifier command
CMD=(terminal-notifier -title "$TITLE" -message "$BODY" -group "$GROUP" -sound default -activate com.googlecode.iterm2 -contentImage "$HOME/.claude/notification-icon-square.png")
if [ -n "$SUBTITLE" ]; then
  CMD+=(-subtitle "$SUBTITLE")
fi

"${CMD[@]}" 2>/dev/null

exit 0

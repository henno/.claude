#!/bin/bash
# Hook to update iTerm2 window title with current directory, git branch, and task

# Read JSON input from stdin
INPUT=$(cat)

# Extract current working directory and session_id
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

if [ -z "$CWD" ] || [ "$CWD" = "null" ]; then
  exit 0
fi

# Convert home path to ~ (use explicit home detection in case $HOME isn't set)
HOME_DIR="${HOME:-$(eval echo ~)}"
DISPLAY_PATH="${CWD/#$HOME_DIR/\~}"

# Get git branch if in a git repository
BRANCH=""
if git -C "$CWD" rev-parse --git-dir &>/dev/null 2>&1; then
  BRANCH="@$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null || git -C "$CWD" rev-parse --short HEAD 2>/dev/null)"
fi

# Find the terminal TTY by looking at ancestor processes
find_tty() {
  local pid=$$
  local tty=""
  while [ "$pid" -gt 1 ]; do
    tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$tty" ] && [ "$tty" != "??" ] && [ -e "/dev/$tty" ]; then
      echo "$tty"
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# Save TTY -> session_id mapping for set_title.sh to use
TTY_NAME=$(find_tty)
SESSION_DIR="$HOME/.claude/sessions"
mkdir -p "$SESSION_DIR"
if [ -n "$TTY_NAME" ] && [ -n "$SESSION_ID" ]; then
  # Save mapping (TTY name without /dev/)
  TTY_SAFE=$(echo "$TTY_NAME" | tr '/' '_')
  echo "$SESSION_ID" > "$SESSION_DIR/tty_$TTY_SAFE"
fi

# Check if skill has set a task description (session-specific)
TASK=""
if [ -n "$SESSION_ID" ]; then
  TASK_FILE="$SESSION_DIR/task_$SESSION_ID"
  if [ -f "$TASK_FILE" ]; then
    TASK=$(cat "$TASK_FILE" 2>/dev/null)
  fi
fi

# Build the final title
if [ -n "$TASK" ]; then
  TITLE="${DISPLAY_PATH}${BRANCH} | ${TASK}"
else
  TITLE="${DISPLAY_PATH}${BRANCH}"
fi

# Set terminal title
if [ -n "$TTY_NAME" ]; then
  printf '\e]0;%s\a' "$TITLE" > "/dev/$TTY_NAME" 2>/dev/null
fi

exit 0

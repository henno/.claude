#!/bin/bash
# Set terminal window title
# Usage: ./set_title.sh "Your Title Here"
#
# Optional: Set CLAUDE_TITLE_PREFIX environment variable for custom prefix
# Example: export CLAUDE_TITLE_PREFIX="🤖 Claude"
#          Results in: "🤖 Claude | ~/projects/myproject@main | Your Title"

# Exit silently if no title provided (fail-safe behavior)
if [ -z "$1" ]; then
    exit 0
fi

# Get current working directory with ~ replacement
CWD=$(pwd)
HOME_DIR=$(eval echo ~)
if [[ "$CWD" == "$HOME_DIR"* ]]; then
    CWD="~${CWD#$HOME_DIR}"
fi

# Get current git branch (if in a git repo)
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# Validate and sanitize input
# Remove control characters (0x00-0x1F) and limit length to 80 characters
TITLE=$(echo "$1" | tr -d '\000-\037' | head -c 80)

# Ensure title is not empty after sanitization
if [ -z "$TITLE" ]; then
    exit 0
fi

# Build the final title with cwd@branch prefix
if [ -n "$GIT_BRANCH" ]; then
    CONTEXT="${CWD}@${GIT_BRANCH}"
else
    CONTEXT="${CWD}"
fi

# Add optional custom prefix
if [ -n "$CLAUDE_TITLE_PREFIX" ]; then
    # Sanitize prefix as well
    PREFIX=$(echo "$CLAUDE_TITLE_PREFIX" | tr -d '\000-\037' | head -c 40)
    if [ -n "$PREFIX" ]; then
        FINAL_TITLE="${PREFIX} | ${CONTEXT} | ${TITLE}"
    else
        FINAL_TITLE="${CONTEXT} | ${TITLE}"
    fi
else
    FINAL_TITLE="${CONTEXT} | ${TITLE}"
fi

# Find session_id via TTY mapping
SESSION_DIR="${HOME}/.claude/sessions"
mkdir -p "$SESSION_DIR"

# Find our TTY
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

TTY_NAME=$(find_tty)
SESSION_ID=""
if [ -n "$TTY_NAME" ]; then
  TTY_SAFE=$(echo "$TTY_NAME" | tr '/' '_')
  MAPPING_FILE="$SESSION_DIR/tty_$TTY_SAFE"
  if [ -f "$MAPPING_FILE" ]; then
    SESSION_ID=$(cat "$MAPPING_FILE" 2>/dev/null)
  fi
fi

# Store the task description for the update-title hook and statusline to read
# Use session-specific file if we have session_id, otherwise fall back to global
if [ -n "$SESSION_ID" ]; then
  TASK_FILE="$SESSION_DIR/task_$SESSION_ID"
else
  TASK_FILE="${HOME}/.claude/terminal_title_task"
fi

# Atomic write using temp file + rename
TEMP_FILE="${TASK_FILE}.tmp.$$"
echo "$TITLE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$TASK_FILE" 2>/dev/null || rm -f "$TEMP_FILE"

# Set the terminal title using ANSI escape sequences
# Detect terminal type and set title accordingly
case "$TERM" in
    xterm*|rxvt*|screen*|tmux*)
        # Standard xterm-compatible terminals
        printf '\033]0;%s\007' "$FINAL_TITLE"
        ;;
    *)
        # Fallback: try anyway, suppress errors
        # This works for iTerm2, Alacritty, and most modern terminals
        printf '\033]0;%s\007' "$FINAL_TITLE" 2>/dev/null
        ;;
esac

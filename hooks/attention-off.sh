#!/bin/bash
# Clear the notification when the user submits a prompt

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // ""')

GROUP="${SESSION_ID:-claude}"
terminal-notifier -remove "$GROUP" 2>/dev/null

exit 0

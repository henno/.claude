#!/bin/bash
# Launch Claude Code with attention indicator
# Usage: ~/.claude/claude-with-attention.sh [claude arguments]

SIGNAL_FILE="/tmp/claude-waiting-for-input"
RED_BG="#441111"

# Cleanup function
cleanup() {
    printf "\033]111\007"
    rm -f "$SIGNAL_FILE"
    # Kill background watcher if running
    [ -n "$WATCHER_PID" ] && kill "$WATCHER_PID" 2>/dev/null
}

trap cleanup EXIT INT TERM

# Start background watcher
(
    was_waiting=false
    while true; do
        if [ -f "$SIGNAL_FILE" ]; then
            if [ "$was_waiting" = false ]; then
                printf "\033]11;${RED_BG}\007"
                was_waiting=true
            fi
        else
            if [ "$was_waiting" = true ]; then
                printf "\033]111\007"
                was_waiting=false
            fi
        fi
        sleep 0.3
    done
) &
WATCHER_PID=$!

# Run Claude with all passed arguments
claude "$@"

# Cleanup happens via trap

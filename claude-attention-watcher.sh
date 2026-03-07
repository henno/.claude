#!/bin/bash
# Background watcher for Claude Code attention indicator
# Start this before running claude: ~/.claude/claude-attention-watcher.sh &

SIGNAL_FILE="/tmp/claude-waiting-for-input"
RED_BG="#441111"
was_waiting=false

cleanup() {
    # Reset background on exit
    printf "\033]111\007"
    rm -f "$SIGNAL_FILE"
    exit 0
}

trap cleanup EXIT INT TERM

echo "Claude attention watcher started (PID $$)"
echo "Background will turn red when Claude waits for input"

while true; do
    if [ -f "$SIGNAL_FILE" ]; then
        if [ "$was_waiting" = false ]; then
            # Claude started waiting - turn red
            printf "\033]11;${RED_BG}\007"
            was_waiting=true
        fi
    else
        if [ "$was_waiting" = true ]; then
            # Claude stopped waiting - reset
            printf "\033]111\007"
            was_waiting=false
        fi
    fi
    sleep 0.3
done

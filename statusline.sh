#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract current directory, context usage, and model info
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
# Calculate remaining context (100 - used)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
context_pct=$((100 - used_pct))
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id' | sed 's/Claude //')

# Shorten path: use ~ for home, show only last 2 dirs
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|" | awk -F/ '{if(NF>3) print $(NF-1)"/"$NF; else print $0}')

# Get git branch if in a git repository (skip optional locks for performance)
branch=""
dirty=""
ahead=""
if [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Check for uncommitted changes (staged or unstaged)
    if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        dirty="*"
    fi

    # Check for unpushed commits
    if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
        ahead_count=$(git -C "$cwd" --no-optional-locks rev-list --count @{upstream}..HEAD 2>/dev/null)
        if [ -n "$ahead_count" ] && [ "$ahead_count" -gt 0 ]; then
            ahead="↑$ahead_count"
        fi
    fi
fi

# Get session_id and read session-specific task file
session_id=$(echo "$input" | jq -r '.session_id // ""')
task=""
if [ -n "$session_id" ]; then
    task_file="$HOME/.claude/sessions/task_$session_id"
    if [ -f "$task_file" ]; then
        task=$(head -n 1 "$task_file" 2>/dev/null | tr -d '\n' | sed 's/^[^:]*: //')
    fi
fi

# Display compact status line with model name
if [ -n "$branch" ]; then
    if [ -n "$task" ]; then
        printf "%s | %s%% %s@%s%s%s | %s" "$model_name" "$context_pct" "$short_cwd" "$branch" "$dirty" "$ahead" "$task"
    else
        printf "%s | %s%% %s@%s%s%s" "$model_name" "$context_pct" "$short_cwd" "$branch" "$dirty" "$ahead"
    fi
else
    if [ -n "$task" ]; then
        printf "%s | %s%% %s | %s" "$model_name" "$context_pct" "$short_cwd" "$task"
    else
        printf "%s | %s%% %s" "$model_name" "$context_pct" "$short_cwd"
    fi
fi

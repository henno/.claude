#!/bin/bash
# Usage: task-log.sh <Started|Finished> <description>
# Example: task-log.sh Started "adding user authentication"

action="$1"
shift
description="$*"

echo "[$(date '+%Y-%m-%d %H:%M') $(pwd | sed "s|$HOME|~|")] $action $description" >> ~/tasks.md

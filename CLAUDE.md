- Never put "version: '3.8'" (or any other version) in Dockerfile. Specifying version is now deprecated.
- Always confirm with the user if they want to commit existing changes before starting working with a new task and there are uncommitted changes.
- Always suggest creating a branch when starting working with a new task. Ask the user for the branch name
- For simple/quick tasks, log only once: ~/.claude/task-log.sh [--issue ID] --minutes N Done "<task description>"
  - Always include --minutes with elapsed time in full minutes (round up, minimum 1)
- For longer tasks, log start and finish separately:
  ~/.claude/task-log.sh [--issue ID] Started "<task description>"
  ~/.claude/task-log.sh [--issue ID] Finished "<task description>"
- When working on a GitHub or Bitbucket issue, ALWAYS pass --issue with the issue identifier (e.g. --issue GH-123, --issue BB-45) to task-log.sh
- IMPORTANT: Always invoke /terminal-title skill at the START of each new session (after user's first prompt) and when switching to a substantially different task. This updates the terminal title and statusline with the current task summary.

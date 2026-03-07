---
name: terminal-title
description: Automatically updates terminal window title to reflect the current high-level task, including current working directory and git branch. Use at the start of every Claude Code session when the user provides their first prompt, and whenever the user switches to a distinctly new high-level task. Helps developers manage multiple Claude Code terminals by providing clear, at-a-glance identification of what each terminal is working on.
min_claude_code_version: "1.0.0"
version: "1.2.0"
---

# Terminal Title

## Overview

Automatically sets descriptive terminal window titles based on the task Claude is working on, with the current working directory and git branch automatically prefixed. Essential for developers running multiple Claude Code instances who need to quickly identify which terminal is handling which task, in which directory, on which branch.

**Example title format:** `~/projects/myapp@main | Build: Dashboard UI`

## When to Use

**Always trigger this skill:**
- At the start of every new Claude Code session (after receiving the first user prompt)
- When switching to a substantially different task (e.g., from "API Integration" to "Database Migration")

**Trigger on task switches like these:**
- Switching from frontend work to backend work
- Moving from debugging to new feature development
- Changing from one module/component to a completely different one
- Starting work on a different part of the system (e.g., from auth to payments)

**Do NOT trigger for:**
- Follow-up questions about the same task ("Can you add a comment to that function?")
- Small refinements to current work ("Make it blue instead of red")
- Debugging the same feature you just built
- Clarifications ("What did you mean by X?")
- Iterating on the same component or module
- Mid-task status updates or progress checks

## How It Works

1. **Extract Task Summary**: Analyze the user's prompt to identify the high-level task
2. **Generate Title**: Create a concise, descriptive title (max 40 characters)
3. **Set Title**: Execute `~/.claude/skills/terminal-title/scripts/set_title.sh` with the generated title
4. **No Confirmation Needed**: This happens automatically in the background

## Title Format Guidelines

**Good titles:**
- "API Integration: Auth Flow"
- "Fix: Login Bug"
- "DB Migration: Users Table"
- "Build: Dashboard UI"
- "Refactor: Payment Module"

**Final terminal title will include cwd and git branch:**
- `~/projects/myapp@main | Build: Dashboard UI`
- `~/work/api@feature/auth | Fix: Login Bug`
- `~/db-migrations@develop | DB Migration: Users Table`

**Bad titles:**
- Too long: "Implementing the new authentication system with OAuth2.0 support" (exceeds 40 chars)
- Too generic: "Working" or "Coding"
- Too verbose: "The user wants me to help them with..."

**Format pattern:**
```
[Action/Category]: [Specific Focus]
```

Keep titles concise, actionable, and immediately recognizable. The cwd and git branch will be automatically prefixed.

## Common Mistakes to Avoid

**❌ Too Verbose:**
- Bad: "Working on implementing the user authentication system with JWT tokens"
- Good: "Build: JWT Auth"

**❌ Too Vague:**
- Bad: "Code stuff"
- Bad: "Working"
- Good: "Refactor: API Layer"

**❌ Including System Information:**
- Bad: "john-macbook-pro: Debug app"
- Bad: "/Users/john/project: Build feature"
- Good: "Debug: App Issues"

**❌ Using Complete Sentences:**
- Bad: "I am working on the dashboard component"
- Good: "Build: Dashboard UI"

## Implementation

**Execute the title script using its absolute path:**
```bash
bash ~/.claude/skills/terminal-title/scripts/set_title.sh "Your Title Here"
```

**Example workflow:**
```bash
# User asks: "Help me debug the authentication flow in the API"
# Terminal in ~/projects/api on main branch
# Result: ~/projects/api@main | Debug: Auth API Flow
bash ~/.claude/skills/terminal-title/scripts/set_title.sh "Debug: Auth API Flow"

# User asks: "Create a React component for the user profile page"
# Terminal in ~/projects/frontend on feature/ui branch
# Result: ~/projects/frontend@feature/ui | Build: User Profile UI
bash ~/.claude/skills/terminal-title/scripts/set_title.sh "Build: User Profile UI"

# User asks: "Write tests for the payment processing module"
# Terminal in ~/work/payment-service on develop branch
# Result: ~/work/payment-service@develop | Test: Payment Module
bash ~/.claude/skills/terminal-title/scripts/set_title.sh "Test: Payment Module"
```

## Script Details

The `~/.claude/skills/terminal-title/scripts/set_title.sh` script uses ANSI escape sequences to set the terminal title. It's compatible with:
- macOS Terminal
- iTerm2
- Alacritty
- Most modern terminal emulators (xterm, rxvt, screen, tmux)

The script accepts a single argument (the title string) and exits silently if no title is provided (fail-safe behavior).

## Optional Customization

Users can optionally customize terminal titles with a prefix by setting the `CLAUDE_TITLE_PREFIX` environment variable:

```bash
export CLAUDE_TITLE_PREFIX="🤖 Claude"
```

This produces titles like: `🤖 Claude | ~/projects/myapp@main | Build: Dashboard UI`

Without the prefix, titles use the standard format: `~/projects/myapp@main | Build: Dashboard UI`

**Note:** You don't need to check for this variable or modify your behavior. The script handles this automatically. The cwd and git branch are always included automatically.

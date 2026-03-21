#!/usr/bin/env node
// Claude Code Statusline - GSD Edition
// Shows: model directory@branch: task context%

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// Read JSON from stdin
let input = '';
// Timeout guard: if stdin doesn't close within 3s (e.g. pipe issues on
// Windows/Git Bash), exit silently instead of hanging. See #775.
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);
    const rawModel = data.model?.display_name || 'Claude';
    const model = rawModel.replace(/\s*\(.*?\)/, '').replace(/Sonnet/, 'S').replace(/Haiku/, 'H');
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // Context window display (shows USED percentage scaled to usable context)
    // Claude Code reserves ~16.5% for autocompact buffer, so usable context
    // is 83.5% of the total window. We normalize to show 100% at that point.
    const AUTO_COMPACT_BUFFER_PCT = 16.5;
    let ctx = '';
    if (remaining != null) {
      // Normalize: subtract buffer from remaining, scale to usable range
      const usableRemaining = Math.max(0, ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100);
      const used = Math.max(0, Math.min(100, Math.round(100 - usableRemaining)));

      // Write context metrics to bridge file for the context-monitor PostToolUse hook.
      // The monitor reads this file to inject agent-facing warnings when context is low.
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
          const bridgeData = JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000)
          });
          fs.writeFileSync(bridgePath, bridgeData);
        } catch (e) {
          // Silent fail -- bridge is best-effort, don't break statusline
        }
      }

      // Color based on usable context thresholds (no progress bar, just %)
      if (used < 50) {
        ctx = ` \x1b[32m${used}%\x1b[0m`;
      } else if (used < 65) {
        ctx = ` \x1b[33m${used}%\x1b[0m`;
      } else if (used < 80) {
        ctx = ` \x1b[38;5;208m${used}%\x1b[0m`;
      } else {
        ctx = ` \x1b[5;31m💀${used}%\x1b[0m`;
      }
    }

    // Current task from session file (written by set_title.sh)
    let task = '';
    const homeDir = os.homedir();
    const claudeDir = process.env.CLAUDE_CONFIG_DIR || path.join(homeDir, '.claude');
    if (session) {
      try {
        const taskFile = path.join(claudeDir, 'sessions', `task_${session}`);
        task = fs.readFileSync(taskFile, 'utf8').trim();
      } catch (e) {}
    }

    // GSD update available?
    let gsdUpdate = '';
    const cacheFile = path.join(claudeDir, 'cache', 'gsd-update-check.json');
    if (fs.existsSync(cacheFile)) {
      try {
        const cache = JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
        if (cache.update_available) {
          gsdUpdate = '\x1b[33m⬆ /gsd:update\x1b[0m │ ';
        }
      } catch (e) {}
    }

    // Git branch (truncated to 40 chars)
    let branch = '';
    try {
      const raw = execSync('git -C ' + JSON.stringify(dir) + ' rev-parse --abbrev-ref HEAD 2>/dev/null', { encoding: 'utf8', timeout: 2000 }).trim();
      if (raw && raw !== 'HEAD') {
        branch = raw.length > 40 ? raw.slice(0, 39) + '…' : raw;
      }
    } catch (e) {}

    // Line 1: "Opus 4.6 dir@branch 5%"
    // Line 2: "▸ Task description" (if task exists)
    const dirname = path.basename(dir);
    let dirPart = dirname;
    if (branch) dirPart += `\x1b[33m@${branch}\x1b[0m`;
    const line1Parts = [gsdUpdate, `\x1b[2m${model}\x1b[0m`, dirPart + ctx];
    let output = line1Parts.filter(Boolean).join(' ');
    if (task) output += `\n\x1b[36m▸\x1b[0m \x1b[1m${task}\x1b[0m`;
    process.stdout.write(output);
  } catch (e) {
    // Silent fail - don't break statusline on parse errors
  }
});

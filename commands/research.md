---
description: Research information from the web using Playwright browser automation
argument-hint: <search query or topic>
allowed-tools: [mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_press_key, mcp__playwright__browser_wait_for, mcp__playwright__browser_tabs]
---

# Web Research Task

Research the following topic using Playwright browser automation: $ARGUMENTS

## Instructions

Use the Playwright MCP tools to research this topic by browsing the web. This approach is necessary because many websites block direct AI fetch requests with 403 errors, but Playwright uses a real browser that works.

### Research Strategy

1. **Start with Google Search**: Construct the search URL directly to skip the front page:
   - URL format: `https://www.google.com/search?q=your+search+terms`
   - Replace spaces with `+` signs in the query
   - Example: `https://www.google.com/search?q=playwright+mcp+cookie+storage`

2. **Browse multiple sources**: Visit 2-4 relevant results to gather comprehensive information
   - Prioritize official documentation, reputable sources, and recent content
   - Use browser_snapshot to read page content (more reliable than screenshots for text)
   - Take screenshots if visual information is important

3. **Extract key information**: For each page visited:
   - Read the main content using browser_snapshot
   - Note important facts, code examples, or instructions
   - Record the source URL for reference

4. **Synthesize findings**: Compile the research into a clear, organized summary

### Important Notes

- If a page requires interaction (clicking tabs, expanding sections), use browser_click
- If a page has a search feature, use browser_type to search within the site
- Wait for pages to load using browser_wait_for when necessary
- **DO NOT close the browser** - keep the session alive for future research tasks
- **Reuse existing browser session**: Before navigating, check if there's already an open browser tab using browser_tabs. If a session exists, continue using it instead of opening a new one

### Captcha Handling

- If you encounter a captcha, reCAPTCHA, or any human verification challenge, **wait for the user to solve it**
- Use browser_wait_for with a reasonable timeout (e.g., 60 seconds) to wait for the captcha to be resolved
- The user is watching the browser and will intervene manually when needed
- After the captcha is solved, continue with the research task

### Output Format

Provide a well-organized summary that includes:
- Key findings and information
- Source URLs for reference
- Any code examples or step-by-step instructions found
- Relevant caveats or considerations

Begin the research now.

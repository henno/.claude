---
name: update-readme
description: Check if README.md matches reality and update if needed
disable-model-invocation: true
---

# Update README

Check if the README.md content accurately reflects the current state of the project and update any outdated information.

## Current Project State

Gather information from these sources:

1. **Build & runtime config**: Look for `docker-compose.yml`, `Dockerfile`, `Makefile`, `package.json`, `pyproject.toml`, `Cargo.toml`, or similar
2. **Commands & scripts**: Check for CLI scripts, npm scripts, entry point scripts, or task runners
3. **Project structure**: Check actual directory structure
4. **Technologies**: Check dependency files for the stack in use
5. **Environment variables**: Check `.env.example`, `.env.template`, `docker-compose.yml`, or docs
6. **Reverse proxy / ports**: Check for Nginx, Caddy, Traefik configs, or port mappings

## Verification Checklist

Compare README.md against reality:

- [ ] Port numbers and URLs are correct
- [ ] Architecture description matches actual setup
- [ ] All listed commands exist and work as described
- [ ] Project structure matches actual directories
- [ ] Technology and dependency list is accurate
- [ ] Setup and install instructions are current
- [ ] Environment variable documentation is complete
- [ ] Deployment instructions match actual process

## Instructions

1. Read README.md
2. Read the source files listed above to understand current state
3. Identify any discrepancies between README and reality
4. If discrepancies found:
   - List what needs to be updated
   - Make the edits to README.md
   - Show a summary of changes made
5. If no discrepancies:
   - Report that README is up to date

## Important

- Keep the same structure and formatting style
- Keep text in Estonian where it's already in Estonian
- Don't add new sections unless necessary
- Focus on factual accuracy, not style improvements

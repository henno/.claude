#!/usr/bin/env node
const fs = require('fs')
const path = require('path')
const { execFileSync } = require('child_process')

function repoRoot() {
  return execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim()
}

function normalizeEnv(env) {
  return (env || 'production').trim().toLowerCase()
}

function isValidEnv(env) {
  return /^[a-z0-9][a-z0-9-]*$/.test(env)
}

function scriptRelativePath(env) {
  return env === 'production' ? 'scripts/deploy' : `scripts/deploy-${env}`
}

function renderScript(command) {
  return `#!/bin/sh
set -eu

${command}
`
}

const environment = normalizeEnv(process.argv[2])
const command = process.argv.slice(3).join(' ').trim()

if (!isValidEnv(environment)) {
  process.stderr.write(`Invalid environment: ${environment}\n`)
  process.exit(3)
}

if (!command) {
  process.stderr.write('Usage: create-deploy-script.js <environment> <command>\n')
  process.exit(1)
}

const root = repoRoot()
const relativePath = scriptRelativePath(environment)
const filePath = path.join(root, relativePath)

fs.mkdirSync(path.dirname(filePath), { recursive: true })

if (fs.existsSync(filePath)) {
  process.stderr.write(`Deploy script already exists: ${filePath}\n`)
  process.exit(2)
}

fs.writeFileSync(filePath, renderScript(command), { mode: 0o755 })
fs.chmodSync(filePath, 0o755)

process.stdout.write(`SCRIPT_PATH=${filePath}\n`)
process.stdout.write(`RELATIVE_PATH=${relativePath}\n`)
process.stdout.write(`ENVIRONMENT=${environment}\n`)
process.stdout.write(`COMMAND=${command}\n`)

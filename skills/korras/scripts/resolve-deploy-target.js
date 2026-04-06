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

function scriptCandidates(env) {
  if (env === 'production') {
    return ['./scripts/deploy', './scripts/deploy-production']
  }
  return [`./scripts/deploy-${env}`]
}

function listScriptEnvironments(root) {
  const scriptsDir = path.join(root, 'scripts')
  if (!fs.existsSync(scriptsDir)) return []

  const envs = new Set()
  for (const entry of fs.readdirSync(scriptsDir)) {
    if (entry === 'deploy') {
      envs.add('production')
      continue
    }
    if (entry === 'deploy-production') {
      envs.add('production')
      continue
    }
    if (entry.startsWith('deploy-')) {
      envs.add(entry.slice('deploy-'.length))
    }
  }
  return [...envs].sort()
}

function output(lines) {
  process.stdout.write(lines.join('\n') + '\n')
}

const env = normalizeEnv(process.argv[2])
const root = repoRoot()

if (!isValidEnv(env)) {
  output([
    'STATUS=blocked',
    'REASON=invalid_environment',
    `ENVIRONMENT=${env}`,
    `REPO_ROOT=${root}`,
  ])
  process.exit(23)
}

for (const candidate of scriptCandidates(env)) {
  const absolutePath = path.join(root, candidate.replace(/^\.\//, ''))
  if (fs.existsSync(absolutePath)) {
    output([
      'STATUS=ok',
      'MODE=script',
      `ENVIRONMENT=${env}`,
      `COMMAND=${candidate}`,
      'SOURCE=script',
      `REPO_ROOT=${root}`,
    ])
    process.exit(0)
  }
}

const availableEnvs = new Set(listScriptEnvironments(root))

output([
  'STATUS=missing',
  `ENVIRONMENT=${env}`,
  `REPO_ROOT=${root}`,
  `AVAILABLE_ENVIRONMENTS=${[...availableEnvs].sort().join(',')}`,
])
process.exit(22)

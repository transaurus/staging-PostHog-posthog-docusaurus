#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/PostHog/posthog-docusaurus"
BRANCH="master"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

# --- Node version ---
# This repo is a Docusaurus plugin; we install @docusaurus/core alongside it.
# Docusaurus 3.x requires Node >=18.
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    nvm use 20 2>/dev/null || nvm install 20
fi
NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
echo "[INFO] Using Node $(node --version)"
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "[ERROR] Node $NODE_MAJOR is too old; Docusaurus 3.x requires Node >=18"
    exit 1
fi

# --- Package manager: Yarn ---
if ! command -v yarn &>/dev/null; then
    echo "[INFO] Installing yarn..."
    npm install -g yarn
fi
echo "[INFO] Yarn version: $(yarn --version)"

# --- Dependencies ---
yarn install

# --- Install @docusaurus/core so we can run write-translations ---
# posthog-docusaurus is a plugin package with no docusaurus site of its own.
# We add docusaurus core + preset + react as dev deps to enable CLI commands.
yarn add --dev @docusaurus/core@latest @docusaurus/preset-classic@latest react react-dom

# --- Create a minimal docusaurus.config.js if not present ---
if [ ! -f "docusaurus.config.js" ]; then
    echo "[INFO] Creating minimal docusaurus.config.js..."
    cat > docusaurus.config.js << 'DOCCONFIG'
// @ts-check
/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'PostHog Docusaurus Plugin',
  tagline: 'PostHog analytics plugin for Docusaurus',
  url: 'https://posthog.com',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  presets: [
    [
      'classic',
      {
        docs: false,
        blog: false,
        theme: {},
      },
    ],
  ],
};

module.exports = config;
DOCCONFIG
fi

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."

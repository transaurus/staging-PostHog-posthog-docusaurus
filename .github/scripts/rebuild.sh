#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for PostHog/posthog-docusaurus
# Runs on existing source tree (no clone). Installs deps, runs pre-build steps, builds.

# --- Node version ---
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    nvm use 20 2>/dev/null || nvm install 20
fi
echo "[INFO] Using Node $(node --version)"

# --- Package manager: Yarn ---
if ! command -v yarn &>/dev/null; then
    echo "[INFO] Installing yarn..."
    npm install -g yarn
fi

# --- Dependencies ---
yarn install

# --- Install @docusaurus/core if not already present ---
# posthog-docusaurus is a plugin package; we need docusaurus core + preset to build.
if [ ! -d "node_modules/@docusaurus/core" ]; then
    yarn add --dev @docusaurus/core@latest @docusaurus/preset-classic@latest react react-dom
fi

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

# --- Build ---
./node_modules/.bin/docusaurus build

echo "[DONE] Build complete."

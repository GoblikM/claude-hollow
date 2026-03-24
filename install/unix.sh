#!/usr/bin/env bash
# Installs Claude Hollow — clones the repo here and adds the command to PATH.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/GoblikM/claude-hollow.git"
BRANCH="main"
DEST="$PWD/claude-hollow"

echo "Cloning Claude Hollow into $DEST ..."
git clone --branch "$BRANCH" "$REPO_URL" "$DEST"

LINK_DIR="$HOME/.local/bin"
mkdir -p "$LINK_DIR"
ln -sf "$DEST/scripts/hollow.sh" "$LINK_DIR/claude-hollow"

echo ""
echo "✅ Installed: claude-hollow → $DEST"

if [[ ":$PATH:" != *":$LINK_DIR:"* ]]; then
  echo ""
  echo "⚠️  $LINK_DIR is not in your PATH."
  echo "   Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

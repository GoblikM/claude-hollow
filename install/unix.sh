#!/usr/bin/env bash
# Installs or updates Claude Hollow — clones the repo and adds the command to PATH.
# Run again at any time to update to the latest version.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/GoblikM/claude-hollow/main/install/unix.sh | bash

set -euo pipefail

REPO_URL="https://github.com/GoblikM/claude-hollow.git"
BRANCH="main"
LINK_DIR="$HOME/.local/bin"
LINK="$LINK_DIR/claude-hollow"

# Detect existing installation via the symlink
if [[ -L "$LINK" ]]; then
  SCRIPT_PATH="$(readlink -f "$LINK")"
  DEST="$(dirname "$(dirname "$SCRIPT_PATH")")"

  if [[ -d "$DEST/.git" ]]; then
    echo "Updating Claude Hollow in $DEST ..."
    git -C "$DEST" fetch --tags origin
    git -C "$DEST" pull --ff-only origin "$BRANCH"
    echo ""
    echo "✅ Updated: claude-hollow → $DEST"
    exit 0
  fi
fi

# Fresh install
DEST="$PWD/claude-hollow"
echo "Installing Claude Hollow into $DEST ..."
git clone --branch "$BRANCH" "$REPO_URL" "$DEST"

mkdir -p "$LINK_DIR"
ln -sf "$DEST/scripts/hollow.sh" "$LINK"

echo ""
echo "✅ Installed: claude-hollow → $DEST"

if [[ ":$PATH:" != *":$LINK_DIR:"* ]]; then
  echo ""
  echo "⚠️  $LINK_DIR is not in your PATH."
  echo "   Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

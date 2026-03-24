#!/usr/bin/env bash
# install.sh – Installs the `claude-hollow` command globally
#
# Creates a symlink in ~/.local/bin/claude-hollow pointing to this repo's hollow.sh.
# After running this, you can type `claude-hollow` from anywhere.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/scripts/hollow.sh"
LINK_DIR="$HOME/.local/bin"
LINK="$LINK_DIR/claude-hollow"

mkdir -p "$LINK_DIR"

if [[ -L "$LINK" ]]; then
  echo "Updating existing symlink: $LINK"
  ln -sf "$TARGET" "$LINK"
elif [[ -e "$LINK" ]]; then
  echo "❌ $LINK already exists and is not a symlink. Remove it manually first."
  exit 1
else
  ln -s "$TARGET" "$LINK"
fi

echo "✅ Installed: claude-hollow → $TARGET"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LINK_DIR:"* ]]; then
  echo ""
  echo "⚠️  $LINK_DIR is not in your PATH."
  echo "   Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

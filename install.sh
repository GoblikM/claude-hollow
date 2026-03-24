#!/usr/bin/env bash
# install.sh – Installs the `claude-hollow` command globally
#
# Linux/macOS: creates a symlink in ~/.local/bin/claude-hollow
# Windows (Git Bash / MSYS2 / Cygwin): adds the repo root to the Windows user PATH
#   so that `claude-hollow.bat` is accessible from CMD, PowerShell, and any terminal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Detect platform ──────────────────────────────────────────────────────────

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    # ── Windows ──────────────────────────────────────────────────────────────
    REPO_WIN="$(cygpath -w "$SCRIPT_DIR")"

    # Check if already in PATH (case-insensitive)
    CURRENT_PATH="$(powershell.exe -NoProfile -Command '[Environment]::GetEnvironmentVariable("PATH","User")' 2>/dev/null | tr -d '\r')"
    REPO_WIN_LOWER="${REPO_WIN,,}"
    CURRENT_PATH_LOWER="${CURRENT_PATH,,}"

    if [[ "$CURRENT_PATH_LOWER" == *"$REPO_WIN_LOWER"* ]]; then
      echo "✅ Already installed: $REPO_WIN is already in your PATH."
    else
      NEW_PATH="${CURRENT_PATH};${REPO_WIN}"
      powershell.exe -NoProfile -Command \
        "[Environment]::SetEnvironmentVariable('PATH', '$NEW_PATH', 'User')" 2>/dev/null
      echo "✅ Installed: $REPO_WIN added to your user PATH."
      echo ""
      echo "   Restart your terminal (or open a new CMD/PowerShell window) and type:"
      echo "   claude-hollow"
    fi
    ;;

  *)
    # ── Linux / macOS ─────────────────────────────────────────────────────────
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

    if [[ ":$PATH:" != *":$LINK_DIR:"* ]]; then
      echo ""
      echo "⚠️  $LINK_DIR is not in your PATH."
      echo "   Add this to your ~/.bashrc or ~/.zshrc:"
      echo ""
      echo '   export PATH="$HOME/.local/bin:$PATH"'
    fi
    ;;
esac

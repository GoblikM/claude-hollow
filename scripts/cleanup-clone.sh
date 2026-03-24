#!/usr/bin/env bash
# cleanup-clone.sh – Removes an isolated clone after merging a task branch
#
# Usage:
#   ./scripts/cleanup-clone.sh <project-dir> <task-slug>
#
# Example:
#   ./scripts/cleanup-clone.sh ~/dev/my-project fix-login-bug

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_DIR="${1:-}"
TASK_SLUG="${2:-}"

if [[ -z "$PROJECT_DIR" || -z "$TASK_SLUG" ]]; then
  echo "Usage: $0 <project-dir> <task-slug>" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR")
CLONES_DIR="$PROJECT_DIR/../.clones"
CLONE_DIR="$CLONES_DIR/task-$TASK_SLUG"
ALLOWED_PREFIX=$(realpath "$CLONES_DIR")

if [[ ! -d "$CLONE_DIR" ]]; then
  echo "ℹ️  Clone '$CLONE_DIR' does not exist, nothing to delete"
  exit 0
fi

# Safety check
CLONE_REAL=$(realpath "$CLONE_DIR")
if [[ "$CLONE_REAL" != "$ALLOWED_PREFIX"* ]]; then
  echo "❌ Error: '$CLONE_DIR' is outside the allowed area '$ALLOWED_PREFIX'" >&2
  exit 1
fi

echo "🗑️  Deleting clone: $CLONE_DIR"
rm -rf "$CLONE_DIR"
echo "✅ Done"

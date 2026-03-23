#!/usr/bin/env bash
# cleanup-clone.sh – Smaže izolovaný klon po mergi task větve
#
# Použití:
#   ./scripts/cleanup-clone.sh <project-dir> <task-slug>
#
# Příklad:
#   ./scripts/cleanup-clone.sh ~/dev/cestynak fix-vowel-highlight

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_DIR="${1:-}"
TASK_SLUG="${2:-}"

if [[ -z "$PROJECT_DIR" || -z "$TASK_SLUG" ]]; then
  echo "Použití: $0 <project-dir> <task-slug>" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR")
CLONES_DIR="$PROJECT_DIR/../.clones"
CLONE_DIR="$CLONES_DIR/task-$TASK_SLUG"
ALLOWED_PREFIX=$(realpath "$CLONES_DIR")

if [[ ! -d "$CLONE_DIR" ]]; then
  echo "ℹ️  Klon '$CLONE_DIR' neexistuje, nic ke smazání"
  exit 0
fi

# Bezpečnostní kontrola
CLONE_REAL=$(realpath "$CLONE_DIR")
if [[ "$CLONE_REAL" != "$ALLOWED_PREFIX"* ]]; then
  echo "❌ Chyba: '$CLONE_DIR' je mimo povolenou oblast '$ALLOWED_PREFIX'" >&2
  exit 1
fi

echo "🗑️  Mažu klon: $CLONE_DIR"
rm -rf "$CLONE_DIR"
echo "✅ Hotovo"

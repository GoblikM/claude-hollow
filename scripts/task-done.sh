#!/usr/bin/env bash
# task-done.sh – Moves a completed task to done/
#
# Usage:
#   ./scripts/task-done.sh <feature-name> <task-slug>
#
# Example:
#   ./scripts/task-done.sh my-feature fix-login-bug

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

PROJECT_SLUG="${1:-}"
FEATURE_NAME="${2:-}"
TASK_SLUG="${3:-}"

if [[ -z "$PROJECT_SLUG" || -z "$FEATURE_NAME" || -z "$TASK_SLUG" ]]; then
  echo "Usage: $0 <project-slug> <feature-name> <task-slug>" >&2
  exit 1
fi

FEATURE_SLUG=$(slugify "$FEATURE_NAME")
FEATURE_DIR="$OFFICE_DIR/features/$PROJECT_SLUG/$FEATURE_SLUG"
TASK_SRC="$FEATURE_DIR/tasks/$TASK_SLUG"
TASK_DST="$FEATURE_DIR/tasks/done/$TASK_SLUG"
ALLOWED_PREFIX=$(realpath "$FEATURE_DIR")

if [[ ! -d "$TASK_SRC" ]]; then
  echo "Error: task '$TASK_SLUG' does not exist in '$FEATURE_DIR/tasks/'" >&2
  exit 1
fi

if [[ -d "$TASK_DST" ]]; then
  echo "Error: task '$TASK_SLUG' is already in done/" >&2
  exit 1
fi

mkdir -p "$FEATURE_DIR/tasks/done"
safe_move "$TASK_SRC" "$TASK_DST" "$ALLOWED_PREFIX"

echo "✅ Task '$TASK_SLUG' moved to done/"

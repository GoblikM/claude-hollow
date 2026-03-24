#!/usr/bin/env bash
# feature-done.sh – Cleanup after a feature branch has been merged to main
#
# Removes the git worktree and deletes the feature branch from the project repo.
# Run this manually after you have merged feature/<name> into main.
#
# Usage:
#   ./scripts/feature-done.sh <feature-name> --project <path>
#   ./scripts/feature-done.sh <feature-name>   # auto-detects project from CLAUDE.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

FEATURE_NAME=""
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$FEATURE_NAME" ]]; then
        FEATURE_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$FEATURE_NAME" ]]; then
  echo "Usage: $0 <feature-name> [--project <path>]" >&2
  exit 1
fi

FEATURE_SLUG=$(slugify "$FEATURE_NAME")

# Auto-detect project from CLAUDE.md if --project not given
if [[ -z "$PROJECT_DIR" ]]; then
  for candidate in "$OFFICE_DIR/features"/*/"$FEATURE_SLUG/CLAUDE.md"; do
    [[ -f "$candidate" ]] || continue
    found_path=$(grep -oP '(?<=\*\* \| `)[^`]+(?=` \|)' "$candidate" | head -1 || true)
    [[ -n "$found_path" ]] && PROJECT_DIR="$found_path" && break
  done
fi

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Error: feature '$FEATURE_SLUG' not found (no --project given and could not auto-detect)" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
PROJECT_SLUG=$(slugify "$(basename "$PROJECT_DIR")")
FEATURE_DIR="$OFFICE_DIR/features/$PROJECT_SLUG/$FEATURE_SLUG"
WORKTREE_DIR="$FEATURE_DIR/workspace"
FEATURE_BRANCH="feature/$FEATURE_SLUG"

if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "Error: feature directory not found: $FEATURE_DIR" >&2
  exit 1
fi

echo "🧹 Cleaning up feature: $FEATURE_SLUG"

# Remove worktree
if [[ -d "$PROJECT_DIR" ]] && git -C "$PROJECT_DIR" worktree list 2>/dev/null | grep -q "$WORKTREE_DIR"; then
  echo "   Removing worktree: $WORKTREE_DIR"
  git -C "$PROJECT_DIR" worktree remove "$WORKTREE_DIR" --force
  echo "   ✅ Worktree removed"
elif [[ -d "$WORKTREE_DIR" ]]; then
  echo "   ⚠️  Worktree directory exists but is not registered — removing manually"
  rm -rf "$WORKTREE_DIR"
fi

# Delete feature branch
if [[ -d "$PROJECT_DIR" ]] && git -C "$PROJECT_DIR" show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH" 2>/dev/null; then
  echo "   Deleting branch: $FEATURE_BRANCH"
  git -C "$PROJECT_DIR" branch -d "$FEATURE_BRANCH" 2>/dev/null || \
    git -C "$PROJECT_DIR" branch -D "$FEATURE_BRANCH"
  echo "   ✅ Branch deleted"
fi

echo ""
echo "✅ Feature '$FEATURE_SLUG' cleaned up."

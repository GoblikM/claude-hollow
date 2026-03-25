#!/usr/bin/env bash
# feature.sh – Initializes a feature workspace and starts the orchestrator
#
# Usage:
#   ./scripts/feature.sh <feature-name> --project <path>  # new feature
#   ./scripts/feature.sh <feature-name>                   # reopen existing feature
#   ./scripts/feature.sh <feature-name> [--from <branch>] --project <path>
#   ./scripts/feature.sh -D <feature-name>                # delete feature
#
# Examples:
#   ./scripts/feature.sh my-feature --project ../my-project
#   ./scripts/feature.sh my-feature
#   ./scripts/feature.sh -D my-feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ─── Arguments ───────────────────────────────────────────────────────────────

DELETE_MODE=false
FEATURE_NAME=""
PROJECT_DIR=""
FROM_BRANCH=""
FEATURE_GOAL=""
EXPLAIN_MODE="off"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -D|--delete)
      DELETE_MODE=true
      shift
      ;;
    --from)
      FROM_BRANCH="$2"
      shift 2
      ;;
    --goal)
      FEATURE_GOAL="$2"
      shift 2
      ;;
    --explain)
      EXPLAIN_MODE="on"
      shift
      ;;
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

# ─── Validation ──────────────────────────────────────────────────────────────

if [[ -z "$FEATURE_NAME" ]]; then
  echo "Error: missing <feature-name>" >&2
  echo "Usage: $0 <feature-name> [--project <path>]" >&2
  exit 1
fi

FEATURE_SLUG=$(slugify "$FEATURE_NAME")

# If --project not provided, search across all project dirs for the feature
if [[ -z "$PROJECT_DIR" ]]; then
  for candidate in "$OFFICE_DIR/features"/*/"$FEATURE_SLUG/CLAUDE.md"; do
    [[ -f "$candidate" ]] || continue
    found_path=$(grep -oP '(?<=\*\* \| `)[^`]+(?=` \|)' "$candidate" | head -1 || true)
    [[ -n "$found_path" ]] && PROJECT_DIR="$found_path" && break
  done
fi

# ─── Delete mode ─────────────────────────────────────────────────────────────

if [[ "$DELETE_MODE" == true ]]; then
  # For delete mode, find the feature dir by searching if no project given
  if [[ -z "$PROJECT_DIR" ]]; then
    # Search was already done above; if still empty, error
    echo "Error: feature '$FEATURE_SLUG' not found (no --project given and could not auto-detect)" >&2
    exit 1
  fi
  PROJECT_DIR=$(realpath "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
  PROJECT_SLUG=$(slugify "$(basename "$PROJECT_DIR")")
  FEATURE_DIR="$OFFICE_DIR/features/$PROJECT_SLUG/$FEATURE_SLUG"

  if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Error: feature '$FEATURE_SLUG' does not exist" >&2
    exit 1
  fi

  echo "⚠️  Deleting feature: $FEATURE_SLUG"
  echo "   Directory: $FEATURE_DIR"
  read -r -p "Confirm deletion? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Cancelled."
    exit 0
  fi

  # Remove git worktree if it exists
  if [[ -d "$PROJECT_DIR" ]]; then
    WORKTREE_DIR="$FEATURE_DIR/workspace"
    if git -C "$PROJECT_DIR" worktree list 2>/dev/null | grep -q "$WORKTREE_DIR"; then
      echo "🌿 Removing git worktree..."
      git -C "$PROJECT_DIR" worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
  fi

  rm -rf "$FEATURE_DIR"
  echo "✅ Feature '$FEATURE_SLUG' deleted."
  exit 0
fi

# ─── Project dir validation ──────────────────────────────────────────────────

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Error: missing --project <path>" >&2
  echo "Usage: $0 <feature-name> --project <path-to-git-repo>" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR")

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Error: '$PROJECT_DIR' is not a git repository" >&2
  exit 1
fi

PROJECT_SLUG=$(slugify "$(basename "$PROJECT_DIR")")
FEATURE_DIR="$OFFICE_DIR/features/$PROJECT_SLUG/$FEATURE_SLUG"
MAIN_BRANCH=$(_detect_main_branch "$PROJECT_DIR")

# ─── GTD structure initialization ────────────────────────────────────────────

FEATURE_BRANCH="feature/$FEATURE_SLUG"
WORKTREE_DIR="$FEATURE_DIR/workspace"

_init_feature() {
  local label="$1"
  echo "$label"
  mkdir -p "$FEATURE_DIR"/{tasks/done,blocked,icebox,docs}

  BASE_BRANCH="${FROM_BRANCH:-$MAIN_BRANCH}"
  echo "🌿 Creating feature branch: $FEATURE_BRANCH (from $BASE_BRANCH)"

  git -C "$PROJECT_DIR" fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || true

  if git -C "$PROJECT_DIR" show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH" 2>/dev/null; then
    echo "   Branch '$FEATURE_BRANCH' already exists"
  else
    git -C "$PROJECT_DIR" checkout -b "$FEATURE_BRANCH" "origin/$BASE_BRANCH" 2>/dev/null || \
      git -C "$PROJECT_DIR" checkout -b "$FEATURE_BRANCH" "$BASE_BRANCH"
    echo "   ✅ Branch created"
    git -C "$PROJECT_DIR" checkout "$MAIN_BRANCH" --quiet 2>/dev/null || true
  fi

  echo "📂 Creating git worktree: $WORKTREE_DIR"
  git -C "$PROJECT_DIR" worktree add "$WORKTREE_DIR" "$FEATURE_BRANCH" 2>/dev/null || {
    echo "   (worktree already exists or branch is checked out elsewhere)"
  }

  if [[ -f "$OFFICE_DIR/features/_templates/feature-claude.md" ]]; then
    sed \
      -e "s|{{FEATURE_NAME}}|$FEATURE_SLUG|g" \
      -e "s|{{FEATURE_BRANCH}}|$FEATURE_BRANCH|g" \
      -e "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" \
      -e "s|{{PROJECT_SLUG}}|$PROJECT_SLUG|g" \
      -e "s|{{MAIN_BRANCH}}|$MAIN_BRANCH|g" \
      -e "s|{{WORKSPACE_DIR}}|$WORKTREE_DIR|g" \
      -e "s|{{DATE}}|$(date +%Y-%m-%d)|g" \
      -e "s|{{FEATURE_GOAL}}|${FEATURE_GOAL:-*(not provided — gather during requirements)*}|g" \
      -e "s|{{EXPLAIN_MODE}}|$EXPLAIN_MODE|g" \
      "$OFFICE_DIR/features/_templates/feature-claude.md" \
      > "$FEATURE_DIR/CLAUDE.md"
    echo "📝 CLAUDE.md generated"
  fi

  echo ""
  echo "✅ Feature '$FEATURE_SLUG' initialized:"
  echo "   📁 $FEATURE_DIR"
  echo "   🌿 $FEATURE_BRANCH"
  echo ""
}

if [[ -d "$FEATURE_DIR" ]] && ( [[ -d "$WORKTREE_DIR/.git" ]] || [[ -f "$WORKTREE_DIR/.git" ]] ); then
  echo "♻️  Feature '$FEATURE_SLUG' already exists, opening..."
elif [[ -d "$FEATURE_DIR" ]]; then
  _init_feature "🔄 Re-initializing archived feature: $FEATURE_SLUG"
else
  _init_feature "🏗️  Initializing feature: $FEATURE_SLUG"
fi

# ─── Stale branch check ───────────────────────────────────────────────────────

if [[ -d "$WORKTREE_DIR/.git" ]] || [[ -f "$WORKTREE_DIR/.git" ]]; then
  warn_if_stale "$PROJECT_DIR" "$FEATURE_BRANCH" "Feature branch"
fi

# ─── Start orchestrator ───────────────────────────────────────────────────────

echo "🤖 Starting orchestrator for feature: $FEATURE_SLUG"
echo "   Context: $FEATURE_DIR/CLAUDE.md"
echo ""

cd "$FEATURE_DIR"
claude

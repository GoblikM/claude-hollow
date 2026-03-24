#!/usr/bin/env bash
# cc.sh – Launches a task agent in an isolated git clone
#
# Usage:
#   ./scripts/cc.sh <project-dir> --task <path-to-task.md> [--branch <branch>] [--timeout <minutes>]
#   ./scripts/cc.sh <project-dir> [--branch <branch>]   # interactive agent
#
# Examples:
#   ./scripts/cc.sh ~/dev/my-project --task features/my-feature/tasks/fix-bug/task.md
#   ./scripts/cc.sh ~/dev/my-project --branch feature/my-feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ─── Arguments ───────────────────────────────────────────────────────────────

PROJECT_DIR=""
TASK_FILE=""
BRANCH=""
TIMEOUT_MINUTES=20
INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task)
      TASK_FILE="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_MINUTES="$2"
      shift 2
      ;;
    --interactive)
      INTERACTIVE=true
      shift
      ;;
    -*)
      echo "Unknown flag: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# ─── Validation ──────────────────────────────────────────────────────────────

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Error: missing <project-dir>" >&2
  echo "Usage: $0 <project-dir> --task <task.md>" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR")

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Error: '$PROJECT_DIR' is not a git repository" >&2
  exit 1
fi

if [[ -z "$TASK_FILE" && "$INTERACTIVE" == false ]]; then
  echo "Error: provide --task <file> or --interactive" >&2
  exit 1
fi

# Resolve task file
if [[ -n "$TASK_FILE" ]]; then
  if [[ "$TASK_FILE" = /* ]]; then
    TASK_FILE_ABS="$TASK_FILE"
  else
    TASK_FILE_ABS="$OFFICE_DIR/$TASK_FILE"
  fi

  if [[ ! -f "$TASK_FILE_ABS" ]]; then
    echo "Error: task file '$TASK_FILE_ABS' does not exist" >&2
    exit 1
  fi

  # Slug from file name (parent directory)
  TASK_SLUG=$(basename "$(dirname "$TASK_FILE_ABS")")
else
  TASK_SLUG="interactive-$(date +%Y%m%d-%H%M%S)"
fi

# ─── Branch detection ────────────────────────────────────────────────────────

if [[ -z "$BRANCH" ]]; then
  CURRENT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)

  # Agents must not work directly on master/main
  if [[ "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "main" ]]; then
    echo "❌ Error: Cannot run agent on branch '$CURRENT_BRANCH'." >&2
    echo "   Create a feature branch: git checkout -b feature/<name>" >&2
    exit 1
  fi

  BRANCH="$CURRENT_BRANCH"
fi

echo "📋 Task: ${TASK_FILE:-interactive}"
echo "🌿 Branch: $BRANCH"
echo "📁 Project: $PROJECT_DIR"

# ─── Isolated clone ──────────────────────────────────────────────────────────

CLONES_DIR="$PROJECT_DIR/../.clones"
CLONE_DIR="$CLONES_DIR/task-$TASK_SLUG"

mkdir -p "$CLONES_DIR"

if [[ -d "$CLONE_DIR" ]]; then
  echo "♻️  Existing clone found: $CLONE_DIR"
  echo "   Updating..."
  git -C "$CLONE_DIR" fetch origin --quiet
  git -C "$CLONE_DIR" checkout "$BRANCH" --quiet 2>/dev/null || \
    git -C "$CLONE_DIR" checkout -b "$BRANCH" "origin/$BRANCH" --quiet
  git -C "$CLONE_DIR" reset --hard "origin/$BRANCH" --quiet
else
  echo "🔄 Creating isolated clone..."
  git clone "$PROJECT_DIR" "$CLONE_DIR" --quiet
  git -C "$CLONE_DIR" fetch origin "$BRANCH" --quiet 2>/dev/null || true
  git -C "$CLONE_DIR" checkout "$BRANCH" 2>/dev/null || \
    git -C "$CLONE_DIR" checkout -b "$BRANCH" "origin/$BRANCH"
fi

echo "✅ Clone ready: $CLONE_DIR"

# ─── Create task branch ───────────────────────────────────────────────────────

TASK_BRANCH="task/$TASK_SLUG"

if git -C "$CLONE_DIR" show-ref --verify --quiet "refs/heads/$TASK_BRANCH" 2>/dev/null; then
  echo "🌿 Task branch exists: $TASK_BRANCH"
  git -C "$CLONE_DIR" checkout "$TASK_BRANCH" --quiet
else
  echo "🌿 Creating task branch: $TASK_BRANCH"
  git -C "$CLONE_DIR" checkout -b "$TASK_BRANCH" --quiet
fi

# ─── Launch agent ────────────────────────────────────────────────────────────

LOG_FILE="$OFFICE_DIR/features"
# Try to find the feature directory for the log
if [[ -n "$TASK_FILE" ]]; then
  FEATURE_FROM_TASK=$(echo "$TASK_FILE" | sed 's|features/\([^/]*\)/.*|\1|')
  LOG_DIR="$OFFICE_DIR/features/$FEATURE_FROM_TASK/tasks/$TASK_SLUG"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"
fi

echo ""
echo "🤖 Launching agent (timeout: ${TIMEOUT_MINUTES}min)..."
echo "   Log: ${LOG_FILE:-stdout}"
echo ""

# Set timeout
TIMEOUT_SECS=$((TIMEOUT_MINUTES * 60))

# Launch Claude Code agent
if [[ -n "$TASK_FILE" ]]; then
  cd "$CLONE_DIR"
  TASK_PROMPT=$(cat "$TASK_FILE_ABS")
  if command -v timeout &>/dev/null; then
    timeout "$TIMEOUT_SECS" claude --dangerously-skip-permissions -p "$TASK_PROMPT" 2>&1 | tee "$LOG_FILE"
    AGENT_EXIT=${PIPESTATUS[0]}
  else
    claude --dangerously-skip-permissions -p "$TASK_PROMPT" 2>&1 | tee "$LOG_FILE"
    AGENT_EXIT=${PIPESTATUS[0]}
  fi
else
  # Interactive
  cd "$CLONE_DIR"
  claude
  AGENT_EXIT=$?
fi

echo ""

# ─── Post-task: fetch commits back ───────────────────────────────────────────

if [[ "$AGENT_EXIT" -eq 0 ]] || [[ "$AGENT_EXIT" -eq 124 ]]; then
  echo "📥 Fetching commits from clone back to project..."
  git -C "$PROJECT_DIR" fetch "$CLONE_DIR" "$TASK_BRANCH:refs/agent-commits/$TASK_SLUG" 2>/dev/null || {
    echo "   (no new commits)"
  }

  # Show what the agent did
  COMMIT_COUNT=$(git -C "$CLONE_DIR" rev-list "origin/$BRANCH..$TASK_BRANCH" --count 2>/dev/null || echo 0)
  if [[ "$COMMIT_COUNT" -gt 0 ]]; then
    echo "✅ Agent created $COMMIT_COUNT commit(s):"
    git -C "$CLONE_DIR" log "origin/$BRANCH..$TASK_BRANCH" --oneline
    echo ""
    echo "📌 To merge the task branch run:"
    echo "   git -C $PROJECT_DIR fetch $CLONE_DIR $TASK_BRANCH:$TASK_BRANCH"
    echo "   git -C $PROJECT_DIR merge $TASK_BRANCH"
  else
    echo "ℹ️  Agent created no commits"
  fi
else
  echo "❌ Agent exited with error (exit code: $AGENT_EXIT)"
fi

if [[ "$AGENT_EXIT" -eq 124 ]]; then
  echo "⏱️  Timeout: agent exceeded ${TIMEOUT_MINUTES} minutes"
fi

exit "${AGENT_EXIT:-0}"

#!/usr/bin/env bash
# cc.sh – Spustí task agenta v izolovaném git klonu
#
# Použití:
#   ./scripts/cc.sh <project-dir> --task <path-to-task.md> [--branch <branch>] [--timeout <minutes>]
#   ./scripts/cc.sh <project-dir> [--branch <branch>]   # interaktivní agent
#
# Příklady:
#   ./scripts/cc.sh ~/dev/cestynak --task features/my-feature/tasks/fix-bug/task.md
#   ./scripts/cc.sh ~/dev/cestynak --branch feature/my-feature

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ─── Argumenty ───────────────────────────────────────────────────────────────

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
      echo "Neznámý přepínač: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR="$1"
      else
        echo "Neočekávaný argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

# ─── Validace ────────────────────────────────────────────────────────────────

if [[ -z "$PROJECT_DIR" ]]; then
  echo "Chyba: chybí <project-dir>" >&2
  echo "Použití: $0 <project-dir> --task <task.md>" >&2
  exit 1
fi

PROJECT_DIR=$(realpath "$PROJECT_DIR")

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Chyba: '$PROJECT_DIR' není git repozitář" >&2
  exit 1
fi

if [[ -z "$TASK_FILE" && "$INTERACTIVE" == false ]]; then
  echo "Chyba: zadej --task <soubor> nebo --interactive" >&2
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
    echo "Chyba: task soubor '$TASK_FILE_ABS' neexistuje" >&2
    exit 1
  fi

  # Slug z názvu souboru (rodičovský adresář)
  TASK_SLUG=$(basename "$(dirname "$TASK_FILE_ABS")")
else
  TASK_SLUG="interactive-$(date +%Y%m%d-%H%M%S)"
fi

# ─── Určení větve ────────────────────────────────────────────────────────────

if [[ -z "$BRANCH" ]]; then
  CURRENT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD)

  # Agenti nesmí pracovat přímo na master/main
  if [[ "$CURRENT_BRANCH" == "master" || "$CURRENT_BRANCH" == "main" ]]; then
    echo "❌ Chyba: Nelze spustit agenta na větvi '$CURRENT_BRANCH'." >&2
    echo "   Vytvoř feature větev: git checkout -b feature/<nazev>" >&2
    exit 1
  fi

  BRANCH="$CURRENT_BRANCH"
fi

echo "📋 Task: ${TASK_FILE:-interaktivní}"
echo "🌿 Větev: $BRANCH"
echo "📁 Projekt: $PROJECT_DIR"

# ─── Izolovaný klon ──────────────────────────────────────────────────────────

CLONES_DIR="$PROJECT_DIR/../.clones"
CLONE_DIR="$CLONES_DIR/task-$TASK_SLUG"

mkdir -p "$CLONES_DIR"

if [[ -d "$CLONE_DIR" ]]; then
  echo "♻️  Existující klon nalezen: $CLONE_DIR"
  echo "   Aktualizuji..."
  git -C "$CLONE_DIR" fetch origin --quiet
  git -C "$CLONE_DIR" checkout "$BRANCH" --quiet 2>/dev/null || \
    git -C "$CLONE_DIR" checkout -b "$BRANCH" "origin/$BRANCH" --quiet
  git -C "$CLONE_DIR" reset --hard "origin/$BRANCH" --quiet
else
  echo "🔄 Vytvářím izolovaný klon..."
  git clone "$PROJECT_DIR" "$CLONE_DIR" --quiet
  git -C "$CLONE_DIR" fetch origin "$BRANCH" --quiet 2>/dev/null || true
  git -C "$CLONE_DIR" checkout "$BRANCH" 2>/dev/null || \
    git -C "$CLONE_DIR" checkout -b "$BRANCH" "origin/$BRANCH"
fi

echo "✅ Klon připraven: $CLONE_DIR"

# ─── Vytvoření task větve ─────────────────────────────────────────────────────

TASK_BRANCH="task/$TASK_SLUG"

if git -C "$CLONE_DIR" show-ref --verify --quiet "refs/heads/$TASK_BRANCH" 2>/dev/null; then
  echo "🌿 Task větev existuje: $TASK_BRANCH"
  git -C "$CLONE_DIR" checkout "$TASK_BRANCH" --quiet
else
  echo "🌿 Vytvářím task větev: $TASK_BRANCH"
  git -C "$CLONE_DIR" checkout -b "$TASK_BRANCH" --quiet
fi

# ─── Spuštění agenta ─────────────────────────────────────────────────────────

LOG_FILE="$OFFICE_DIR/features"
# Zkus najít feature adresář pro log
if [[ -n "$TASK_FILE" ]]; then
  FEATURE_FROM_TASK=$(echo "$TASK_FILE" | sed 's|features/\([^/]*\)/.*|\1|')
  LOG_DIR="$OFFICE_DIR/features/$FEATURE_FROM_TASK/tasks/$TASK_SLUG"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/run-$(date +%Y%m%d-%H%M%S).log"
fi

echo ""
echo "🤖 Spouštím agenta (timeout: ${TIMEOUT_MINUTES}min)..."
echo "   Log: ${LOG_FILE:-stdout}"
echo ""

# Nastav timeout
TIMEOUT_SECS=$((TIMEOUT_MINUTES * 60))

# Spuštění Claude Code agenta
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
  # Interaktivní
  cd "$CLONE_DIR"
  claude
  AGENT_EXIT=$?
fi

echo ""

# ─── Post-task: fetch commitů zpět ───────────────────────────────────────────

if [[ "$AGENT_EXIT" -eq 0 ]] || [[ "$AGENT_EXIT" -eq 124 ]]; then
  echo "📥 Načítám commity z klonu zpět do projektu..."
  git -C "$PROJECT_DIR" fetch "$CLONE_DIR" "$TASK_BRANCH:refs/agent-commits/$TASK_SLUG" 2>/dev/null || {
    echo "   (žádné nové commity)"
  }

  # Zobraz co agent udělal
  COMMIT_COUNT=$(git -C "$CLONE_DIR" rev-list "origin/$BRANCH..$TASK_BRANCH" --count 2>/dev/null || echo 0)
  if [[ "$COMMIT_COUNT" -gt 0 ]]; then
    echo "✅ Agent vytvořil $COMMIT_COUNT commit(ů):"
    git -C "$CLONE_DIR" log "origin/$BRANCH..$TASK_BRANCH" --oneline
    echo ""
    echo "📌 Pro merge task větve spusť:"
    echo "   git -C $PROJECT_DIR fetch $CLONE_DIR $TASK_BRANCH:$TASK_BRANCH"
    echo "   git -C $PROJECT_DIR merge $TASK_BRANCH"
  else
    echo "ℹ️  Agent nevytvořil žádné commity"
  fi
else
  echo "❌ Agent skončil s chybou (exit code: $AGENT_EXIT)"
fi

if [[ "$AGENT_EXIT" -eq 124 ]]; then
  echo "⏱️  Timeout: agent překročil ${TIMEOUT_MINUTES} minut"
fi

exit "${AGENT_EXIT:-0}"

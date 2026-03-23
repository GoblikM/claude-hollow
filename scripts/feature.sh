#!/usr/bin/env bash
# feature.sh – Inicializuje feature workspace a spustí orchestrátora
#
# Použití:
#   ./scripts/feature.sh <feature-name> [--from <branch>]
#   ./scripts/feature.sh -D <feature-name>   # smaž feature
#
# Příklady:
#   ./scripts/feature.sh oprava-pismena
#   ./scripts/feature.sh -D oprava-pismena

# Cesta k cestynak projektu
DEFAULT_PROJECT_DIR="/c/Users/goldb/dev/cestynak"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib.sh"

# ─── Argumenty ───────────────────────────────────────────────────────────────

DELETE_MODE=false
FEATURE_NAME=""
PROJECT_DIR=""
FROM_BRANCH=""

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
    --project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -*)
      echo "Neznámý přepínač: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$FEATURE_NAME" ]]; then
        FEATURE_NAME="$1"
      else
        echo "Neočekávaný argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

PROJECT_DIR="${PROJECT_DIR:-$DEFAULT_PROJECT_DIR}"

# ─── Validace ────────────────────────────────────────────────────────────────

if [[ -z "$FEATURE_NAME" ]]; then
  echo "Chyba: chybí <feature-name>" >&2
  echo "Použití: $0 <feature-name>" >&2
  exit 1
fi

FEATURE_SLUG=$(slugify "$FEATURE_NAME")
FEATURE_DIR="$OFFICE_DIR/features/$FEATURE_SLUG"

# ─── Delete mode ─────────────────────────────────────────────────────────────

if [[ "$DELETE_MODE" == true ]]; then
  if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Chyba: feature '$FEATURE_SLUG' neexistuje" >&2
    exit 1
  fi

  echo "⚠️  Mažu feature: $FEATURE_SLUG"
  echo "   Složka: $FEATURE_DIR"
  read -r -p "Potvrdit smazání? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Zrušeno."
    exit 0
  fi

  # Smaž git worktree pokud existuje
  if [[ -d "$PROJECT_DIR" ]]; then
    WORKTREE_DIR="$FEATURE_DIR/workspace"
    if git -C "$PROJECT_DIR" worktree list 2>/dev/null | grep -q "$WORKTREE_DIR"; then
      echo "🌿 Odstraňuji git worktree..."
      git -C "$PROJECT_DIR" worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
    fi
  fi

  rm -rf "$FEATURE_DIR"
  echo "✅ Feature '$FEATURE_SLUG' smazána."
  exit 0
fi

# ─── Validace project dir ────────────────────────────────────────────────────

PROJECT_DIR=$(realpath "$PROJECT_DIR")

if [[ ! -d "$PROJECT_DIR/.git" ]]; then
  echo "Chyba: '$PROJECT_DIR' není git repozitář" >&2
  exit 1
fi

# ─── Inicializace GTD struktury ──────────────────────────────────────────────

FEATURE_BRANCH="feature/$FEATURE_SLUG"

if [[ -d "$FEATURE_DIR" ]]; then
  echo "♻️  Feature '$FEATURE_SLUG' již existuje, otevírám..."
else
  echo "🏗️  Inicializuji feature: $FEATURE_SLUG"
  mkdir -p "$FEATURE_DIR"/{tasks/done,blocked,icebox,docs}

  # Detekuj main branch
  MAIN_BRANCH=$(_detect_main_branch "$PROJECT_DIR")
  BASE_BRANCH="${FROM_BRANCH:-$MAIN_BRANCH}"

  echo "🌿 Vytvářím feature větev: $FEATURE_BRANCH (z $BASE_BRANCH)"

  # Fetch a vytvoř feature větev
  git -C "$PROJECT_DIR" fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || true

  if git -C "$PROJECT_DIR" show-ref --verify --quiet "refs/heads/$FEATURE_BRANCH" 2>/dev/null; then
    echo "   Větev '$FEATURE_BRANCH' již existuje"
  else
    git -C "$PROJECT_DIR" checkout -b "$FEATURE_BRANCH" "origin/$BASE_BRANCH" 2>/dev/null || \
      git -C "$PROJECT_DIR" checkout -b "$FEATURE_BRANCH" "$BASE_BRANCH"
    echo "   ✅ Větev vytvořena"
    git -C "$PROJECT_DIR" checkout "$MAIN_BRANCH" --quiet 2>/dev/null || true
  fi

  # Vytvoř git worktree
  WORKTREE_DIR="$FEATURE_DIR/workspace"
  echo "📂 Vytvářím git worktree: $WORKTREE_DIR"
  git -C "$PROJECT_DIR" worktree add "$WORKTREE_DIR" "$FEATURE_BRANCH" 2>/dev/null || {
    echo "   (worktree již existuje nebo větev je checkout jinde)"
  }

  # Generuj CLAUDE.md z šablony
  if [[ -f "$OFFICE_DIR/features/_templates/feature-claude.md" ]]; then
    sed \
      -e "s|{{FEATURE_NAME}}|$FEATURE_SLUG|g" \
      -e "s|{{FEATURE_BRANCH}}|$FEATURE_BRANCH|g" \
      -e "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" \
      -e "s|{{WORKSPACE_DIR}}|$WORKTREE_DIR|g" \
      -e "s|{{DATE}}|$(date +%Y-%m-%d)|g" \
      "$OFFICE_DIR/features/_templates/feature-claude.md" \
      > "$FEATURE_DIR/CLAUDE.md"
    echo "📝 CLAUDE.md vygenerováno"
  fi

  echo ""
  echo "✅ Feature '$FEATURE_SLUG' inicializována:"
  echo "   📁 $FEATURE_DIR"
  echo "   🌿 $FEATURE_BRANCH"
  echo ""
fi

# ─── Kontrola stáří větve ────────────────────────────────────────────────────

WORKTREE_DIR="$FEATURE_DIR/workspace"
if [[ -d "$WORKTREE_DIR/.git" ]] || [[ -f "$WORKTREE_DIR/.git" ]]; then
  warn_if_stale "$PROJECT_DIR" "$FEATURE_BRANCH" "Feature větev"
fi

# ─── Spuštění orchestrátora ──────────────────────────────────────────────────

echo "🤖 Spouštím orchestrátora pro feature: $FEATURE_SLUG"
echo "   Kontext: $FEATURE_DIR/CLAUDE.md"
echo ""

cd "$FEATURE_DIR"
claude

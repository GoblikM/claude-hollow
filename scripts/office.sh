#!/usr/bin/env bash
# office.sh – Main entry point for Office
#
# Usage:
#   ./scripts/office.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$OFFICE_DIR/.projects"
source "$SCRIPT_DIR/lib.sh"

# ─── Registry helpers ─────────────────────────────────────────────────────────

# Format: name|path (one per line)

_registry_load() {
  [[ -f "$REGISTRY" ]] || touch "$REGISTRY"
}

_registry_list() {
  _registry_load
  grep -v '^#' "$REGISTRY" | grep -v '^$' || true
}

_registry_add() {
  local name="$1"
  local path="$2"
  _registry_load
  # Remove existing entry with same name or path
  local tmp
  tmp=$(grep -v "^${name}|" "$REGISTRY" | grep -v "|${path}$" || true)
  echo "$tmp" > "$REGISTRY"
  echo "${name}|${path}" >> "$REGISTRY"
}

_registry_remove() {
  local name="$1"
  _registry_load
  local tmp
  tmp=$(grep -v "^${name}|" "$REGISTRY" || true)
  echo "$tmp" > "$REGISTRY"
}

_registry_get_path() {
  local name="$1"
  _registry_load
  grep "^${name}|" "$REGISTRY" | cut -d'|' -f2 || true
}

# ─── Display ──────────────────────────────────────────────────────────────────

_show_header() {
  echo ""
  echo "🏠 Office"
  echo "─────────────────────────────────────"
}

_show_projects() {
  local entries
  entries=$(_registry_list)

  if [[ -z "$entries" ]]; then
    echo "  No projects registered yet."
    return
  fi

  echo "  Projects:"
  local i=1
  while IFS='|' read -r name path; do
    if [[ -d "$path/.git" ]]; then
      echo "  $i) $name   ($path)"
    else
      echo "  $i) $name   ($path) ⚠️  not found"
    fi
    ((i++))
  done <<< "$entries"
}

# ─── Actions ─────────────────────────────────────────────────────────────────

_add_existing_project() {
  echo ""
  read -e -r -p "Path to existing git repository: " project_path
  project_path=$(eval echo "$project_path")  # expand ~

  if [[ ! -d "$project_path/.git" ]]; then
    echo "❌ '$project_path' is not a git repository."
    return
  fi

  project_path=$(realpath "$project_path")
  local default_name
  default_name=$(basename "$project_path")

  read -r -p "Project name [$default_name]: " project_name
  project_name="${project_name:-$default_name}"
  project_name=$(slugify "$project_name")

  _registry_add "$project_name" "$project_path"
  echo "✅ Project '$project_name' registered."
}

_create_new_project() {
  echo ""
  read -r -p "New project name: " project_name
  if [[ -z "$project_name" ]]; then
    echo "❌ Name cannot be empty."
    return
  fi

  local slug
  slug=$(slugify "$project_name")

  read -e -r -p "Where to create it (directory path): " project_path
  project_path=$(eval echo "$project_path")  # expand ~

  if [[ -z "$project_path" ]]; then
    echo "❌ Path cannot be empty."
    return
  fi

  if [[ -d "$project_path/.git" ]]; then
    echo "❌ '$project_path' already has a git repository."
    return
  fi

  echo ""
  echo "Creating new project '$project_name' at: $project_path"
  mkdir -p "$project_path"
  git -C "$project_path" init -b main --quiet
  git -C "$project_path" commit --allow-empty -m "chore: initial commit" --quiet

  project_path=$(realpath "$project_path")
  _registry_add "$slug" "$project_path"
  echo "✅ Project '$slug' created and registered."
  echo "   $project_path"
}

_remove_project() {
  local entries
  entries=$(_registry_list)

  if [[ -z "$entries" ]]; then
    echo "  No projects to remove."
    return
  fi

  echo ""
  echo "  Which project to remove?"
  local names=()
  local i=1
  while IFS='|' read -r name path; do
    echo "  $i) $name   ($path)"
    names+=("$name")
    ((i++))
  done <<< "$entries"
  echo "  q) Cancel"
  echo ""

  read -r -p "Choice: " choice
  [[ "$choice" == "q" ]] && return

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#names[@]} )); then
    local name="${names[$((choice-1))]}"
    _registry_remove "$name"
    echo "✅ Project '$name' removed from registry (directory untouched)."
  else
    echo "❌ Invalid choice."
  fi
}

_start_feature() {
  local project_name="$1"
  local project_path="$2"

  echo ""
  read -r -p "Feature name: " feature_name
  if [[ -z "$feature_name" ]]; then
    echo "❌ Feature name cannot be empty."
    return
  fi

  echo ""
  "$SCRIPT_DIR/feature.sh" "$feature_name" --project "$project_path"
}

_select_project() {
  local entries
  entries=$(_registry_list)

  if [[ -z "$entries" ]]; then
    echo "  No projects registered. Add one first."
    return
  fi

  local names=()
  local paths=()
  local i=1
  while IFS='|' read -r name path; do
    names+=("$name")
    paths+=("$path")
    ((i++))
  done <<< "$entries"

  echo ""
  read -r -p "Select project number: " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#names[@]} )); then
    local name="${names[$((choice-1))]}"
    local path="${paths[$((choice-1))]}"

    if [[ ! -d "$path/.git" ]]; then
      echo "❌ Project path not found: $path"
      return
    fi

    echo ""
    echo "Project: $name ($path)"
    echo ""
    echo "  f) Start a feature"
    echo "  q) Back"
    read -r -p "Action: " action

    case "$action" in
      f) _start_feature "$name" "$path" ;;
      q) return ;;
      *) echo "❌ Unknown action." ;;
    esac
  else
    echo "❌ Invalid choice."
  fi
}

# ─── Main loop ────────────────────────────────────────────────────────────────

while true; do
  _show_header
  _show_projects
  echo ""
  echo "  a) Add existing project"
  echo "  n) Create new project"
  echo "  r) Remove project"
  echo "  q) Quit"
  echo ""
  read -r -p "Choice: " choice

  case "$choice" in
    [0-9]*)
      _select_project
      ;;
    a)
      _add_existing_project
      ;;
    n)
      _create_new_project
      ;;
    r)
      _remove_project
      ;;
    q)
      echo ""
      exit 0
      ;;
    *)
      echo "❌ Unknown choice."
      ;;
  esac
done

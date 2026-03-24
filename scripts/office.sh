#!/usr/bin/env bash
# office.sh – Main entry point for Office
#
# Usage:
#   ./scripts/office.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$OFFICE_DIR/.projects"
source "$SCRIPT_DIR/lib.sh"

# ─── Registry helpers ─────────────────────────────────────────────────────────

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

# ─── Helpers ──────────────────────────────────────────────────────────────────

_short_path() {
  echo "${1/#$HOME/~}"
}

_list_features() {
  local project_slug="$1"
  local feature_base="$OFFICE_DIR/features/$project_slug"
  [[ -d "$feature_base" ]] || return
  find "$feature_base" -maxdepth 1 -mindepth 1 -type d ! -name '_*' -printf '%f\n' 2>/dev/null | sort
}

# ─── Screens ──────────────────────────────────────────────────────────────────

_screen_main() {
  local entries
  entries=$(_registry_list)

  local names=() paths=()
  if [[ -n "$entries" ]]; then
    while IFS='|' read -r name path; do
      names+=("$name")
      paths+=("$path")
    done <<< "$entries"
  fi

  while true; do
    clear
    echo ""
    echo "  🏠  Office"
    echo "  ──────────────────────────────────────────"

    if [[ ${#names[@]} -eq 0 ]]; then
      echo ""
      echo "  No projects yet."
    else
      echo ""
      echo "  Projects"
      echo ""
      for i in "${!names[@]}"; do
        local num=$(( i + 1 ))
        local display
        display=$(_short_path "${paths[$i]}")
        if [[ -d "${paths[$i]}/.git" ]]; then
          printf "  [%d] %-20s %s\n" "$num" "${names[$i]}" "$display"
        else
          printf "  [%d] %-20s %s  ⚠️  not found\n" "$num" "${names[$i]}" "$display"
        fi
      done
    fi

    echo ""
    echo "  ──────────────────────────────────────────"
    echo "  [a] Add existing project"
    echo "  [n] Create new project"
    [[ ${#names[@]} -gt 0 ]] && echo "  [r] Remove project"
    echo "  [q] Quit"
    echo ""
    read -r -p "  › " choice

    case "$choice" in
      q) echo ""; exit 0 ;;
      a) _action_add_project && { entries=$(_registry_list); names=(); paths=()
           [[ -n "$entries" ]] && while IFS='|' read -r n p; do names+=("$n"); paths+=("$p"); done <<< "$entries" ;} ;;
      n) _action_create_project && { entries=$(_registry_list); names=(); paths=()
           [[ -n "$entries" ]] && while IFS='|' read -r n p; do names+=("$n"); paths+=("$p"); done <<< "$entries" ;} ;;
      r) [[ ${#names[@]} -gt 0 ]] && _action_remove_project "${names[@]}" && { entries=$(_registry_list); names=(); paths=()
           [[ -n "$entries" ]] && while IFS='|' read -r n p; do names+=("$n"); paths+=("$p"); done <<< "$entries" ;} ;;
      [0-9]*)
        if (( choice >= 1 && choice <= ${#names[@]} )); then
          _screen_project "${names[$((choice-1))]}" "${paths[$((choice-1))]}"
        else
          echo "  ❌ Invalid choice."; sleep 1
        fi ;;
      *) ;;
    esac
  done
}

_screen_project() {
  local project_name="$1"
  local project_path="$2"
  local project_slug
  project_slug=$(slugify "$project_name")

  while true; do
    local features=()
    while IFS= read -r f; do
      [[ -n "$f" ]] && features+=("$f")
    done < <(_list_features "$project_slug")

    clear
    echo ""
    echo "  🏠  Office  ›  $project_name"
    echo "  ──────────────────────────────────────────"
    echo "  $(_short_path "$project_path")"
    echo ""

    if [[ ${#features[@]} -gt 0 ]]; then
      echo "  Features"
      echo ""
      for i in "${!features[@]}"; do
        printf "  [%d] %s\n" "$(( i + 1 ))" "${features[$i]}"
      done
      echo ""
      echo "  ──────────────────────────────────────────"
    fi

    echo "  [f] Start new feature"
    echo "  [b] Back"
    echo ""
    read -r -p "  › " choice

    case "$choice" in
      b) return ;;
      f) _action_start_feature "$project_name" "$project_path" ;;
      [0-9]*)
        if (( choice >= 1 && choice <= ${#features[@]} )); then
          local feature="${features[$((choice-1))]}"
          echo ""
          "$SCRIPT_DIR/feature.sh" "$feature" --project "$project_path"
          echo ""; read -r -p "  Press Enter to continue..." _
        else
          echo "  ❌ Invalid choice."; sleep 1
        fi ;;
      *) ;;
    esac
  done
}

# ─── Actions ──────────────────────────────────────────────────────────────────

_action_add_project() {
  echo ""
  read -e -r -p "  Path to git repository: " project_path
  project_path=$(eval echo "$project_path")

  if [[ -z "$project_path" ]]; then return; fi

  if [[ ! -d "$project_path/.git" ]]; then
    echo "  ❌ Not a git repository: $project_path"
    sleep 2; return
  fi

  project_path=$(realpath "$project_path")
  local default_name
  default_name=$(basename "$project_path")

  read -r -p "  Project name [$default_name]: " project_name
  project_name="${project_name:-$default_name}"
  project_name=$(slugify "$project_name")

  _registry_add "$project_name" "$project_path"
  echo "  ✅ Project '$project_name' registered."
  sleep 1
}

_action_create_project() {
  echo ""
  read -r -p "  Project name: " project_name
  if [[ -z "$project_name" ]]; then return; fi

  local slug
  slug=$(slugify "$project_name")

  read -e -r -p "  Where to create it: " project_path
  project_path=$(eval echo "$project_path")

  if [[ -z "$project_path" ]]; then return; fi

  if [[ -d "$project_path/.git" ]]; then
    echo "  ❌ Directory already has a git repository."
    sleep 2; return
  fi

  mkdir -p "$project_path"
  git -C "$project_path" init -b main --quiet
  git -C "$project_path" commit --allow-empty -m "chore: initial commit" --quiet

  project_path=$(realpath "$project_path")
  _registry_add "$slug" "$project_path"
  echo "  ✅ Project '$slug' created at $(_short_path "$project_path")"
  sleep 1
}

_action_remove_project() {
  local names=("$@")

  echo ""
  echo "  Remove which project?"
  echo ""
  for i in "${!names[@]}"; do
    printf "  [%d] %s\n" "$(( i + 1 ))" "${names[$i]}"
  done
  echo ""
  read -r -p "  › " choice

  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#names[@]} )); then
    local name="${names[$((choice-1))]}"
    _registry_remove "$name"
    echo "  ✅ '$name' removed (directory untouched)."
    sleep 1
  fi
}

_action_start_feature() {
  local project_name="$1"
  local project_path="$2"

  echo ""
  read -r -p "  Feature name: " feature_name
  if [[ -z "$feature_name" ]]; then return; fi

  echo ""
  "$SCRIPT_DIR/feature.sh" "$feature_name" --project "$project_path"
  echo ""; read -r -p "  Press Enter to continue..." _
}

# ─── Entry point ──────────────────────────────────────────────────────────────

_screen_main

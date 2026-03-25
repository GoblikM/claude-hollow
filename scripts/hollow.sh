#!/usr/bin/env bash
# hollow.sh – Main entry point for Claude Hollow
#
# Usage:
#   ./scripts/hollow.sh

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
  local name="$1" path="$2"
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

_short_path() { echo "${1/#$HOME/~}"; }

_list_features() {
  local project_slug="$1"
  local feature_base="$OFFICE_DIR/features/$project_slug"
  [[ -d "$feature_base" ]] || return
  while IFS= read -r name; do
    [[ -d "$feature_base/$name/workspace" ]] && echo "$name"
  done < <(find "$feature_base" -maxdepth 1 -mindepth 1 -type d ! -name '_*' -printf '%f\n' 2>/dev/null | sort)
}

_is_initialized() {
  [[ -f "$1/CLAUDE.md" ]] && ! head -1 "$1/CLAUDE.md" | grep -q "^__CLAUDE_HOLLOW_INIT__$"
}

# ─── Screens ──────────────────────────────────────────────────────────────────

_screen_main() {
  while true; do
    local entries
    entries=$(_registry_list)

    local names=() paths=()
    if [[ -n "$entries" ]]; then
      while IFS='|' read -r name path; do
        names+=("$name")
        paths+=("$path")
      done <<< "$entries"
    fi

    clear
    echo ""
    echo "  🏠  Claude Hollow"
    echo "  ──────────────────────────────────────────"

    if [[ ${#names[@]} -eq 0 ]]; then
      echo ""
      echo "  No projects yet."
    else
      echo ""
      echo "  Projects"
      echo ""
      for i in "${!names[@]}"; do
        local display
        display=$(_short_path "${paths[$i]}")
        if [[ -d "${paths[$i]}/.git" ]]; then
          printf "  [%d] %-20s %s\n" "$(( i + 1 ))" "${names[$i]}" "$display"
        else
          printf "  [%d] %-20s %s  ⚠️  not found\n" "$(( i + 1 ))" "${names[$i]}" "$display"
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
      a) _action_add_project ;;
      n) _action_create_project ;;
      r) [[ ${#names[@]} -gt 0 ]] && _action_remove_project "${names[@]}" ;;
      [0-9]*)
        if (( ${#names[@]} > 0 && choice >= 1 && choice <= ${#names[@]} )); then
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
    echo "  🏠  Claude Hollow  ›  $project_name"
    echo "  ──────────────────────────────────────────"
    echo "  $(_short_path "$project_path")"

    if [[ ${#features[@]} -gt 0 ]]; then
      echo ""
      echo "  Features"
      echo ""
      for i in "${!features[@]}"; do
        printf "  [%d] %s\n" "$(( i + 1 ))" "${features[$i]}"
      done
    fi

    echo ""
    echo "  ──────────────────────────────────────────"
    if ! _is_initialized "$project_path"; then
      echo "  [i] Init project"
    fi
    echo "  [f] Start new feature"
    [[ ${#features[@]} -gt 0 ]] && echo "  [d] Feature done (cleanup after merge)"
    echo "  [b] Back"
    echo ""
    read -r -p "  › " choice

    case "$choice" in
      b) return ;;
      i) ! _is_initialized "$project_path" && _action_init_project "$project_name" "$project_path" ;;
      f) _action_start_feature "$project_name" "$project_path" ;;
      d) [[ ${#features[@]} -gt 0 ]] && _action_feature_done "$project_name" "$project_path" "${features[@]}" ;;
      [0-9]*)
        if (( ${#features[@]} > 0 && choice >= 1 && choice <= ${#features[@]} )); then
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
  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  Add project"
  echo "  ──────────────────────────────────────────"
  echo ""
  read -e -r -p "  Path to git repository: " project_path
  project_path=$(eval echo "$project_path")
  [[ -z "$project_path" ]] && return

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
  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  Create project"
  echo "  ──────────────────────────────────────────"
  echo ""
  read -r -p "  Project name: " project_name
  [[ -z "$project_name" ]] && return

  local slug
  slug=$(slugify "$project_name")

  read -e -r -p "  Where to create it: " base_path
  base_path=$(eval echo "$base_path")
  [[ -z "$base_path" ]] && return

  local project_path="$base_path/$slug"

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
  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  Remove project"
  echo "  ──────────────────────────────────────────"
  echo ""
  for i in "${!names[@]}"; do
    printf "  [%d] %s\n" "$(( i + 1 ))" "${names[$i]}"
  done
  echo "  [q] Cancel"
  echo ""
  read -r -p "  › " choice

  [[ "$choice" == "q" ]] && return
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#names[@]} )); then
    local name="${names[$((choice-1))]}"
    _registry_remove "$name"
    echo "  ✅ '$name' removed (directory untouched)."
    sleep 1
  fi
}

_action_feature_done() {
  local project_name="$1"
  local project_path="$2"
  shift 2
  local features=("$@")

  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  $project_name  ›  Feature done"
  echo "  ──────────────────────────────────────────"
  echo ""
  echo "  Select the feature to clean up (after merging to main):"
  echo ""
  for i in "${!features[@]}"; do
    printf "  [%d] %s\n" "$(( i + 1 ))" "${features[$i]}"
  done
  echo "  [q] Cancel"
  echo ""
  read -r -p "  › " choice

  [[ "$choice" == "q" ]] && return
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#features[@]} )); then
    local feature="${features[$((choice-1))]}"
    echo ""
    "$SCRIPT_DIR/feature-done.sh" "$feature" --project "$project_path"
    echo ""; read -r -p "  Press Enter to continue..." _
  fi
}

_action_init_project() {
  local project_name="$1"
  local project_path="$2"

  local template="$OFFICE_DIR/features/_templates/init-claude.md"
  if [[ ! -f "$template" ]]; then
    echo "  ❌ Template not found: $template"
    sleep 2; return
  fi

  local sentinel="__CLAUDE_HOLLOW_INIT__"
  local rendered
  rendered=$(sed \
    -e "s|{{PROJECT_DIR}}|$project_path|g" \
    -e "s|{{PROJECT_NAME}}|$project_name|g" \
    "$template")

  printf '%s\n\n%s\n' "$sentinel" "$rendered" > "$project_path/CLAUDE.md"

  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  $project_name  ›  Init project"
  echo "  ──────────────────────────────────────────"
  echo ""
  echo "  Claude will ask you about your project and write CLAUDE.md."
  echo ""

  (cd "$project_path" && claude)

  if [[ -f "$project_path/CLAUDE.md" ]] && head -1 "$project_path/CLAUDE.md" | grep -q "$sentinel"; then
    rm "$project_path/CLAUDE.md"
  fi

  echo ""; read -r -p "  Press Enter to continue..." _
}

_action_start_feature() {
  local project_name="$1"
  local project_path="$2"

  clear
  echo ""
  echo "  🏠  Claude Hollow  ›  $project_name  ›  New feature"
  echo "  ──────────────────────────────────────────"
  echo ""
  read -r -p "  Feature name: " feature_name
  [[ -z "$feature_name" ]] && return

  read -r -p "  Feature goal (optional, one line): " feature_goal

  echo ""
  if [[ -n "$feature_goal" ]]; then
    "$SCRIPT_DIR/feature.sh" "$feature_name" --project "$project_path" --goal "$feature_goal"
  else
    "$SCRIPT_DIR/feature.sh" "$feature_name" --project "$project_path"
  fi
  echo ""; read -r -p "  Press Enter to continue..." _
}

# ─── Entry point ──────────────────────────────────────────────────────────────

_screen_main

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

# ─── Arrow-key picker ─────────────────────────────────────────────────────────
#
# _pick <title> <item1> <item2> ...
# Prints the selected item to stdout, or empty string if cancelled.
#
_pick() {
  local title="$1"; shift
  local items=("$@")
  local cur=0
  local count=${#items[@]}

  # Save terminal state
  tput civis 2>/dev/null  # hide cursor
  local old_stty
  old_stty=$(stty -g)
  stty -echo -icanon min 1 time 0

  _pick_cleanup() {
    stty "$old_stty"
    tput cnorm 2>/dev/null  # show cursor
  }
  trap _pick_cleanup RETURN INT TERM

  _pick_draw() {
    # Move cursor up to redraw (skip on first draw)
    if [[ "${_pick_drawn:-0}" -eq 1 ]]; then
      tput cuu $(( count + 1 )) 2>/dev/null
    fi
    _pick_drawn=1

    echo "  $title"
    for i in "${!items[@]}"; do
      if [[ $i -eq $cur ]]; then
        printf "  \033[1;36m❯ %s\033[0m\n" "${items[$i]}"
      else
        printf "    %s\n" "${items[$i]}"
      fi
    done
  }

  echo ""
  _pick_draw

  local result=""
  while true; do
    local key
    IFS= read -r -s -n1 key

    # Escape sequences (arrows)
    if [[ "$key" == $'\x1b' ]]; then
      local seq
      IFS= read -r -s -n2 -t 0.1 seq || true
      case "$seq" in
        '[A'|'OA') (( cur > 0 )) && (( cur-- )) ;;          # up
        '[B'|'OB') (( cur < count - 1 )) && (( cur++ )) ;;  # down
      esac
    elif [[ "$key" == $'\x0a' || "$key" == $'\x0d' ]]; then  # Enter
      result="${items[$cur]}"
      break
    elif [[ "$key" == 'q' || "$key" == $'\x1b' ]]; then      # q or Esc
      break
    elif [[ "$key" == 'k' ]]; then
      (( cur > 0 )) && (( cur-- ))
    elif [[ "$key" == 'j' ]]; then
      (( cur < count - 1 )) && (( cur++ ))
    fi

    _pick_draw
  done

  echo ""
  echo "$result"
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

_short_path() { echo "${1/#$HOME/~}"; }

_list_features() {
  local project_slug="$1"
  local feature_base="$OFFICE_DIR/features/$project_slug"
  [[ -d "$feature_base" ]] || return
  find "$feature_base" -maxdepth 1 -mindepth 1 -type d ! -name '_*' -printf '%f\n' 2>/dev/null | sort
}

# ─── Screens ──────────────────────────────────────────────────────────────────

_screen_main() {
  while true; do
    local entries
    entries=$(_registry_list)

    local names=() paths=() labels=()
    if [[ -n "$entries" ]]; then
      while IFS='|' read -r name path; do
        names+=("$name")
        paths+=("$path")
        local display
        display=$(_short_path "$path")
        if [[ -d "$path/.git" ]]; then
          labels+=("$(printf '%-20s %s' "$name" "$display")")
        else
          labels+=("$(printf '%-20s %s  ⚠️  not found' "$name" "$display")")
        fi
      done <<< "$entries"
    fi

    clear
    echo ""
    echo "  🏠  Claude Hollow"
    echo "  ──────────────────────────────────────────"

    local actions=("+ Add existing project" "* Create new project")
    [[ ${#names[@]} -gt 0 ]] && actions+=("- Remove project")
    actions+=("  Quit")

    local all_items=()
    [[ ${#labels[@]} -gt 0 ]] && all_items+=("${labels[@]}")
    [[ ${#labels[@]} -gt 0 ]] && all_items+=("──────────────────────────────────────")
    all_items+=("${actions[@]}")

    local title=""
    [[ ${#names[@]} -gt 0 ]] && title="Projects" || title="No projects yet"

    local chosen
    chosen=$(_pick "$title" "${all_items[@]}")

    [[ -z "$chosen" ]] && { echo ""; exit 0; }

    # Match chosen to project
    local matched=false
    for i in "${!labels[@]}"; do
      if [[ "$chosen" == "${labels[$i]}" ]]; then
        _screen_project "${names[$i]}" "${paths[$i]}"
        matched=true
        break
      fi
    done
    $matched && continue

    case "$chosen" in
      "+ Add existing project") _action_add_project ;;
      "* Create new project")   _action_create_project ;;
      "- Remove project")       _action_remove_project "${names[@]}" ;;
      "  Quit"|"──────────────────────────────────────") echo ""; exit 0 ;;
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

    local items=()
    [[ ${#features[@]} -gt 0 ]] && items+=("${features[@]}")
    [[ ${#features[@]} -gt 0 ]] && items+=("──────────────────────────────────────")
    items+=("+ Start new feature" "  Back")

    local title=""
    [[ ${#features[@]} -gt 0 ]] && title="Features" || title="No features yet"

    local chosen
    chosen=$(_pick "$title" "${items[@]}")

    [[ -z "$chosen" ]] && return

    case "$chosen" in
      "+ Start new feature") _action_start_feature "$project_name" "$project_path" ;;
      "  Back"|"──────────────────────────────────────") return ;;
      *)
        # It's a feature name
        echo ""
        "$SCRIPT_DIR/feature.sh" "$chosen" --project "$project_path"
        echo ""; read -r -p "  Press Enter to continue..." _
        ;;
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

  read -e -r -p "  Where to create it: " project_path
  project_path=$(eval echo "$project_path")
  [[ -z "$project_path" ]] && return

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

  local chosen
  chosen=$(_pick "Which project to remove?" "${names[@]}" "  Cancel")

  [[ -z "$chosen" || "$chosen" == "  Cancel" ]] && return

  _registry_remove "$chosen"
  echo "  ✅ '$chosen' removed (directory untouched)."
  sleep 1
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

  echo ""
  "$SCRIPT_DIR/feature.sh" "$feature_name" --project "$project_path"
  echo ""; read -r -p "  Press Enter to continue..." _
}

# ─── Entry point ──────────────────────────────────────────────────────────────

_screen_main

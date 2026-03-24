#!/usr/bin/env bash
# Shared utilities for office scripts

set -euo pipefail

# Finds the main branch (master or main)
_detect_main_branch() {
  local repo_dir="${1:-.}"
  if git -C "$repo_dir" show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
    echo "master"
  elif git -C "$repo_dir" show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
    echo "main"
  elif git -C "$repo_dir" show-ref --verify --quiet refs/heads/master 2>/dev/null; then
    echo "master"
  else
    echo "main"
  fi
}

# Checks that a feature branch is up to date with origin/master (or main)
# Returns 0 if OK, 1 if behind
check_master_ancestry() {
  local repo_dir="$1"
  local branch="$2"
  local main_branch
  main_branch=$(_detect_main_branch "$repo_dir")

  git -C "$repo_dir" fetch origin "$main_branch" --quiet 2>/dev/null || true

  local merge_base
  merge_base=$(git -C "$repo_dir" merge-base "origin/$main_branch" "$branch" 2>/dev/null || echo "")

  local main_commit
  main_commit=$(git -C "$repo_dir" rev-parse "origin/$main_branch" 2>/dev/null || echo "")

  if [[ "$merge_base" == "$main_commit" ]]; then
    return 0
  else
    return 1
  fi
}

# Prints a warning if the branch is behind main
warn_if_stale() {
  local repo_dir="$1"
  local branch="$2"
  local label="${3:-branch}"

  if ! check_master_ancestry "$repo_dir" "$branch"; then
    echo "⚠️  WARNING: $label ($branch) is behind origin/master. Consider rebasing." >&2
  fi
}

# Slugifies a name (lowercase, hyphens instead of spaces/special chars)
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# Safely moves files only within an allowed path
safe_move() {
  local src="$1"
  local dst="$2"
  local allowed_prefix="$3"

  # Resolve absolute paths
  src=$(realpath "$src")
  dst_parent=$(realpath "$(dirname "$dst")")

  if [[ "$src" != "$allowed_prefix"* ]]; then
    echo "❌ Error: Source '$src' is outside the allowed area '$allowed_prefix'" >&2
    exit 1
  fi

  if [[ "$dst_parent" != "$allowed_prefix"* ]]; then
    echo "❌ Error: Destination '$dst' is outside the allowed area '$allowed_prefix'" >&2
    exit 1
  fi

  mv "$src" "$dst"
}

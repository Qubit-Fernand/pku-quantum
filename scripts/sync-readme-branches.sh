#!/usr/bin/env bash
set -euo pipefail

remote="${REMOTE:-origin}"
source_branch="${SOURCE_BRANCH:-main}"
target_branches="${TARGET_BRANCHES:-2022 2023 2024 2025 2026}"
sync_files="${SYNC_FILES:-readme.md public/readme-preview.png}"
commit_message="${COMMIT_MESSAGE:-docs: sync readme from ${source_branch}}"
allow_unpushed="${ALLOW_UNPUSHED:-0}"

repo_root="$(git rev-parse --show-toplevel)"
repo_common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
worktree_path="${WORKTREE_PATH:-$(dirname "$repo_root")/pku-quantum-readme-sync}"

IFS=' ' read -r -a branches <<< "$target_branches"
IFS=' ' read -r -a files <<< "$sync_files"

cleanup() {
  local rc=$?

  if [[ $rc -eq 0 && ( -d "$worktree_path/.git" || -f "$worktree_path/.git" ) ]]; then
    if [[ -z "$(git -C "$worktree_path" status --porcelain)" ]]; then
      git -C "$worktree_path" switch --detach "$source_branch" >/dev/null 2>&1 || true
    fi
  elif [[ $rc -ne 0 ]]; then
    printf 'Sync failed. Inspect the sync worktree at: %s\n' "$worktree_path" >&2
  fi
}
trap cleanup EXIT

cd "$repo_root"

git rev-parse --verify "${source_branch}^{commit}" >/dev/null

for file in "${files[@]}"; do
  git cat-file -e "${source_branch}:${file}"
done

git fetch "$remote" --prune

if [[ ! -e "$worktree_path" ]]; then
  mkdir -p "$(dirname "$worktree_path")"
  git worktree add --detach "$worktree_path" "$source_branch"
elif [[ ! -d "$worktree_path/.git" && ! -f "$worktree_path/.git" ]]; then
  printf 'Refusing to use %s: path exists but is not a git worktree.\n' "$worktree_path" >&2
  exit 1
elif [[ "$(git -C "$worktree_path" rev-parse --path-format=absolute --git-common-dir)" != "$repo_common_dir" ]]; then
  printf 'Refusing to use %s: it belongs to a different repository.\n' "$worktree_path" >&2
  exit 1
fi

if [[ -n "$(git -C "$worktree_path" status --porcelain)" ]]; then
  printf 'Refusing to sync: %s has uncommitted changes.\n' "$worktree_path" >&2
  exit 1
fi

for branch in "${branches[@]}"; do
  printf '\n==> Syncing %s from %s\n' "$branch" "$source_branch"

  git rev-parse --verify "${branch}^{commit}" >/dev/null

  if git rev-parse --verify "${remote}/${branch}^{commit}" >/dev/null 2>&1; then
    ahead_count="$(git rev-list --count "${remote}/${branch}..${branch}")"
    if [[ "$ahead_count" != '0' && "$allow_unpushed" != '1' ]]; then
      printf 'Refusing to sync %s: local branch is %s commit(s) ahead of %s/%s.\n' "$branch" "$ahead_count" "$remote" "$branch" >&2
      printf 'Push or inspect that branch first, or rerun with ALLOW_UNPUSHED=1.\n' >&2
      exit 1
    fi
  fi

  current_branch="$(git -C "$repo_root" branch --show-current)"
  if [[ "$current_branch" == "$branch" ]]; then
    printf 'Refusing to sync %s: that branch is checked out in %s.\n' "$branch" "$repo_root" >&2
    printf 'Switch the main worktree to %s or another non-target branch first.\n' "$source_branch" >&2
    exit 1
  fi

  git -C "$worktree_path" switch --quiet "$branch"

  git archive "$source_branch" -- "${files[@]}" | tar -x -C "$worktree_path"

  if git -C "$worktree_path" diff --quiet -- "${files[@]}"; then
    printf 'No README changes for %s; skipping commit.\n' "$branch"
  else
    git -C "$worktree_path" add -- "${files[@]}"
    git -C "$worktree_path" commit -m "$commit_message"
    git -C "$worktree_path" push "$remote" "$branch"
  fi
done

printf '\nDone. Synced files from %s via %s: %s\n' "$source_branch" "$worktree_path" "$sync_files"

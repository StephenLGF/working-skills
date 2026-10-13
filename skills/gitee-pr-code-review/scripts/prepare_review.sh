#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 <repo> <pr-number> [base-ref]" >&2
  exit 2
fi

review_repo=$1
review_pr=$2
review_base=${3:-}

if [[ ! $review_pr =~ ^[0-9]+$ ]]; then
  echo "PR number must contain digits only: $review_pr" >&2
  exit 2
fi

git -C "$review_repo" rev-parse --git-dir >/dev/null

head_ref="refs/working-skills/review/pr-${review_pr}-head"
merge_ref="refs/working-skills/review/pr-${review_pr}-merge"

git -C "$review_repo" fetch origin "+refs/pull/${review_pr}/head:${head_ref}"

if git -C "$review_repo" fetch origin "+refs/pull/${review_pr}/MERGE:${merge_ref}"; then
  review_base=$(git -C "$review_repo" rev-parse "${merge_ref}^1")
elif [[ -n $review_base ]]; then
  review_base=$(git -C "$review_repo" rev-parse "$review_base")
else
  echo "Gitee merge ref is unavailable; pass an explicit base ref." >&2
  exit 1
fi

review_head=$(git -C "$review_repo" rev-parse "$head_ref")
review_merge_base=$(git -C "$review_repo" merge-base "$review_base" "$review_head")
review_dir=$(mktemp -d "/tmp/gitee-pr-${review_pr}.XXXXXX")
git -C "$review_repo" worktree add --detach "$review_dir" "$review_head" >/dev/null

printf 'review_dir=%q\n' "$review_dir"
printf 'base_sha=%q\n' "$review_base"
printf 'head_sha=%q\n' "$review_head"
printf 'merge_base_sha=%q\n' "$review_merge_base"
printf 'diff_range=%q\n' "${review_base}...${review_head}"
printf 'snapshot_diff_range=%q\n' "${review_base}..${review_head}"
printf 'target_only_range=%q\n' "${review_merge_base}..${review_base}"

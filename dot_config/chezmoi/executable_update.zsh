#!/usr/bin/env zsh
set -euo pipefail

main_branch="main"
main_remote="origin"
main_ref="${main_remote}/${main_branch}"
current_branch="$(git branch --show-current)"

if [[ -z "$current_branch" ]]; then
  print -u2 "chezmoi update: source repo is not on a branch"
  exit 1
fi

if [[ "$current_branch" == "$main_branch" ]]; then
  git pull --autostash --rebase "$main_remote" "$main_branch"
  exit 0
fi

git fetch "$main_remote" "$main_branch"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-update-rebase.XXXXXX")"
cleanup() {
  git worktree remove --force "$tmpdir" >/dev/null 2>&1 || true
  rmdir "$tmpdir" >/dev/null 2>&1 || true
}
trap cleanup EXIT

git worktree add --detach --quiet "$tmpdir" HEAD

if git -C "$tmpdir" rebase --quiet "$main_ref" >/dev/null 2>&1; then
  print "chezmoi update: rebasing $current_branch onto $main_ref"
  git rebase --autostash "$main_ref"
else
  print -u2 "chezmoi update: rebase onto $main_ref has conflicts."
  print -u2 "Resolve conflicts, then run:"
  print -u2 "  git -C $(pwd) rebase --continue"
  print -u2 "Or abort with:"
  print -u2 "  git -C $(pwd) rebase --abort"
  git rebase --autostash "$main_ref"
fi

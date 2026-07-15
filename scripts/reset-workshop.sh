#!/usr/bin/env bash
#
# reset-workshop.sh — reset every group repo back to the workshop starting point,
# while preserving each group's work behind an immutable tag.
#
# What it does, for each group remote:
#   1. fetch the remote
#   2. tag the group's CURRENT main as <session-tag> on the remote (preserves their work)
#   3. force-reset the remote's main to the starting point
#   4. (re)push the start tag so the remote always carries it
#
# Group branches other than main (claude/*, solution/*, gh-pages, …) are left
# UNTOUCHED, so nothing is lost. The old main commits stay reachable through
# the session tag, so they are never garbage-collected either.
#
# Usage:
#   scripts/reset-workshop.sh <session-tag> [options]
#
# Example:
#   scripts/reset-workshop.sh session-2026-06-16-morning
#
# Options:
#   --start <tag>        Starting-point tag to reset to. Default: newest start/* tag.
#   --remotes "a b c"    Space-separated remotes to reset. Default: all five groups.
#   -n, --dry-run        Print what would happen, change nothing.
#   -y, --yes            Skip the confirmation prompt.
#   -h, --help           Show this help.

set -euo pipefail

REMOTES_DEFAULT="group1 group2 group3 group4 group5"
SESSION_TAG=""
START_TAG=""
REMOTES="$REMOTES_DEFAULT"
DRY_RUN=0
ASSUME_YES=0

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//' | sed '$d'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --start)   START_TAG="$2"; shift 2 ;;
    --remotes) REMOTES="$2"; shift 2 ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -y|--yes)     ASSUME_YES=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  if [[ -z "$SESSION_TAG" ]]; then SESSION_TAG="$1"; shift
        else echo "Unexpected argument: $1" >&2; exit 2; fi ;;
  esac
done

if [[ -z "$SESSION_TAG" ]]; then
  echo "ERROR: a <session-tag> is required (used to preserve each group's work)." >&2
  echo >&2
  usage >&2
  exit 2
fi

# Resolve the starting-point tag: explicit --start, else newest start/* tag.
if [[ -z "$START_TAG" ]]; then
  START_TAG="$(git tag -l 'start/*' --sort=-creatordate | head -n1 || true)"
fi
if [[ -z "$START_TAG" ]]; then
  echo "ERROR: no starting-point tag found. Create one first, e.g.:" >&2
  echo "  git tag start/\$(date +%F) main && for r in $REMOTES_DEFAULT; do git push \$r start/\$(date +%F); done" >&2
  exit 1
fi
if ! git rev-parse -q --verify "refs/tags/$START_TAG" >/dev/null; then
  echo "ERROR: start tag '$START_TAG' does not exist locally." >&2
  exit 1
fi

START_SHA="$(git rev-parse --short "refs/tags/$START_TAG")"

run() {
  if [[ $DRY_RUN -eq 1 ]]; then echo "  [dry-run] $*"; else echo "  + $*"; eval "$@"; fi
}

echo "Workshop reset"
echo "  session tag (preserves work) : $SESSION_TAG"
echo "  start tag   (reset target)   : $START_TAG ($START_SHA)"
echo "  remotes                      : $REMOTES"
[[ $DRY_RUN -eq 1 ]] && echo "  mode                         : DRY RUN (no changes)"
echo

if [[ $DRY_RUN -eq 0 && $ASSUME_YES -eq 0 ]]; then
  read -r -p "Force-reset main on these repos to '$START_TAG'? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  echo
fi

for remote in $REMOTES; do
  echo "== $remote =="
  if ! git remote get-url "$remote" >/dev/null 2>&1; then
    echo "  ! no such remote, skipping (run scripts/setup-remotes.sh first)" >&2
    continue
  fi
  run "git fetch --quiet $remote"

  # Guard: refuse to silently re-use a session tag that already exists on the remote.
  if git ls-remote --tags "$remote" "refs/tags/$SESSION_TAG" 2>/dev/null | grep -q .; then
    echo "  ! tag '$SESSION_TAG' already exists on $remote — skipping this remote to avoid clobbering work." >&2
    echo "    Pick a fresh session tag, or delete the existing one deliberately." >&2
    continue
  fi

  # 1. Preserve the group's current main under the session tag (on the remote only).
  run "git push $remote refs/remotes/$remote/main:refs/tags/$SESSION_TAG"
  # 2. Force-reset the remote's main to the starting point.
  run "git push --force-with-lease $remote refs/tags/$START_TAG:refs/heads/main"
  # 3. Make sure the remote also carries the start tag.
  run "git push $remote refs/tags/$START_TAG"
  echo
done

echo "Done."
if [[ $DRY_RUN -eq 1 ]]; then echo "(dry run — nothing was changed)"; fi

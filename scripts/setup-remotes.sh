#!/usr/bin/env bash
#
# setup-remotes.sh — wire this repo up to the five workshop group repos.
#
# Adds (or updates) remotes group1..group5 pointing at
# martinsson/AI-kata-non-dev-group<N>, then fetches each remote with tags so
# the start/* and session tags are available locally. Run once after cloning
# this repo; publish-session.sh and reset-workshop.sh rely on these remotes.
#
# Usage:
#   scripts/setup-remotes.sh [options]
#
# Options:
#   --token <PAT>    Use HTTPS URLs with this token (for CI). Default: SSH URLs.
#   --no-fetch       Only configure the remotes, skip fetching.
#   -h, --help       Show this help.

set -euo pipefail

OWNER="martinsson"
REPO_PREFIX="AI-kata-non-dev-group"
GROUPS_N="1 2 3 4 5"
TOKEN=""
DO_FETCH=1

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//' | sed '$d'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)    TOKEN="$2"; shift 2 ;;
    --no-fetch) DO_FETCH=0; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

for n in $GROUPS_N; do
  remote="group$n"
  if [[ -n "$TOKEN" ]]; then
    url="https://x-access-token:${TOKEN}@github.com/$OWNER/$REPO_PREFIX$n.git"
  else
    url="git@github.com:$OWNER/$REPO_PREFIX$n.git"
  fi
  if git remote get-url "$remote" >/dev/null 2>&1; then
    git remote set-url "$remote" "$url"
    echo "updated remote $remote"
  else
    git remote add "$remote" "$url"
    echo "added remote $remote"
  fi
  if [[ $DO_FETCH -eq 1 ]]; then
    # Only start/* tags: they are identical across repos, whereas each group's
    # session-* tags point at different commits and would clash locally.
    git fetch --quiet "$remote"
    git fetch --quiet "$remote" 'refs/tags/start/*:refs/tags/start/*' 2>/dev/null || true
    echo "  fetched (incl. start/* tags)"
  fi
done

echo "Done. start tags available: $(git tag -l 'start/*' | tr '\n' ' ')"

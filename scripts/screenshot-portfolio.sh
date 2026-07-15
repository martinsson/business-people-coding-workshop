#!/usr/bin/env bash
#
# screenshot-portfolio.sh — capture a preview.png for portfolio apps.
#
# Serves the portfolio dir over http (so relative paths / ES modules work) and
# uses Playwright (fetched on demand via npx — no committed deps) to screenshot
# each app at its initial load. Writes preview.png into each app's folder.
#
# Usage:
#   scripts/screenshot-portfolio.sh <portfolio-dir> [entry ...]
#
#   entry   relative path inside the portfolio, either a folder ("2026-06-18/group1")
#           or a file ("2026-06-10/group4/recensement.html"). preview.png is written
#           next to it. With NO entries, every folder containing an index.html
#           (except the portfolio root) is captured.
#
# Env:
#   PW_VERSION   playwright version to use (default 1.48.0)
#   VIEWPORT     viewport size (default 1280,800)
#   WAIT_MS      ms to wait after load before the shot (default 2500)

set -euo pipefail

PW="playwright@${PW_VERSION:-1.48.0}"
VIEWPORT="${VIEWPORT:-1280,800}"
WAIT_MS="${WAIT_MS:-2500}"
PORT="${PORT:-8769}"

PORTFOLIO="${1:?usage: screenshot-portfolio.sh <portfolio-dir> [entry ...]}"; shift || true
PORTFOLIO="$(cd "$PORTFOLIO" && pwd)"

entries=("$@")
if [[ ${#entries[@]} -eq 0 ]]; then
  while IFS= read -r f; do
    rel="${f#"$PORTFOLIO"/}"
    entries+=("$(dirname "$rel")")
  done < <(find "$PORTFOLIO" -name index.html -not -path "$PORTFOLIO/index.html" | sort)
fi

echo "Ensuring Chromium for $PW …"
npx --yes "$PW" install chromium >/dev/null 2>&1 || true

echo "Serving $PORTFOLIO on :$PORT"
python3 -m http.server "$PORT" --directory "$PORTFOLIO" >/dev/null 2>&1 &
SRV=$!
trap 'kill "$SRV" 2>/dev/null || true' EXIT
sleep 1

for entry in "${entries[@]}"; do
  entry="${entry#./}"; entry="${entry%/}"
  if [[ "$entry" == *.html ]]; then
    url="http://localhost:$PORT/$entry"
    out="$PORTFOLIO/$(dirname "$entry")/preview.png"
  else
    url="http://localhost:$PORT/$entry/"
    out="$PORTFOLIO/$entry/preview.png"
  fi
  printf '  %-44s → %s\n' "$entry" "${out#"$PORTFOLIO"/}"
  npx --yes "$PW" screenshot --browser chromium \
    --viewport-size "$VIEWPORT" --wait-for-timeout "$WAIT_MS" \
    "$url" "$out" >/dev/null 2>&1 || echo "    ! failed to capture $entry"
done

echo "Done — ${#entries[@]} preview(s)."

#!/usr/bin/env bash
#
# publish-session.sh — close out a workshop session.
#
# The portfolio lives on unlockers.ai (repo martinsson/unlockers-site, subfolder
# public/business-people-coding/), which deploys from main via GitHub Actions.
# That repo's convention is changes-via-PR, so this script delivers as a
# branch → PR → immediate merge (gh CLI), not a direct push to main.
#
# For each group repo it:
#   0. prepares the site repo: requires a clean tree, updates main, branches
#   1. fetches and snapshots site/ from the group's main into the portfolio
#      subfolder under <date>/<group>/ (the published, decoupled copy)
#   2. captures a preview.png of each app (screenshot-portfolio.sh)
#   3. adds a card section to the portfolio's index.html — UNLESS a section for
#      this date already exists (so hand-curated cards are never clobbered)
#   4. commits, pushes the branch, opens a PR and merges it (deploy = automatic)
# Then, unless --no-reset, it chains into reset-workshop.sh to preserve each
# group's work behind the session tag and rewind their main to the start point.
# (The reset is reversible: it only creates a tag + force-rewinds main.)
#
# Usage:
#   scripts/publish-session.sh [<session-date>] [options]
#     <session-date>   YYYY-MM-DD, default: today
#
# Options:
#   --site <dir>        unlockers-site repo checkout
#                       (default: ~/Documents/Claude/Projects/unlockers landing and funnel)
#   --remotes "a b c"   group remotes (default: group1 group2 group3 group4 group5)
#   --no-shots          skip screenshots
#   --no-reset          publish only; do NOT reset the group repos afterwards
#   --no-push           commit on the branch but skip push + PR + merge
#   -n, --dry-run       print what would happen, change nothing
#   -y, --yes           skip confirmation prompts (also passed to the reset)
#   -h, --help          show this help

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$REPO_ROOT/scripts"

SESSION_DATE=""
SITE_REPO="$HOME/Documents/Claude/Projects/unlockers landing and funnel"
SUBDIR="public/business-people-coding"
REMOTES="group1 group2 group3 group4 group5"
DO_SHOTS=1; DO_RESET=1; DO_PUSH=1; DRY_RUN=0; ASSUME_YES=0

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; s/^#$//' | sed '$d'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --site)      SITE_REPO="$2"; shift 2 ;;
    --remotes)   REMOTES="$2"; shift 2 ;;
    --no-shots)  DO_SHOTS=0; shift ;;
    --no-reset)  DO_RESET=0; shift ;;
    --no-push)   DO_PUSH=0; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -y|--yes)     ASSUME_YES=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  if [[ -z "$SESSION_DATE" ]]; then SESSION_DATE="$1"; shift
        else echo "Unexpected argument: $1" >&2; exit 2; fi ;;
  esac
done

[[ -z "$SESSION_DATE" ]] && SESSION_DATE="$(date +%F)"
[[ "$SESSION_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { echo "ERROR: session date must be YYYY-MM-DD" >&2; exit 2; }
SESSION_TAG="session-$SESSION_DATE"

if [[ ! -d "$SITE_REPO/.git" ]]; then
  echo "ERROR: unlockers-site repo not found at: $SITE_REPO  (use --site)" >&2; exit 1
fi
PORTFOLIO="$SITE_REPO/$SUBDIR"
INDEX="$PORTFOLIO/index.html"
BRANCH="portfolio/session-$SESSION_DATE"

run() { if [[ $DRY_RUN -eq 1 ]]; then echo "  [dry-run] $*"; else echo "  + $*"; eval "$@"; fi; }

echo "Publish session"
echo "  date / tag : $SESSION_DATE  ($SESSION_TAG)"
echo "  site repo  : $SITE_REPO"
echo "  portfolio  : $SUBDIR/  →  https://unlockers.ai/business-people-coding/"
echo "  remotes    : $REMOTES"
echo "  steps      : snapshot$([[ $DO_SHOTS = 1 ]] && echo ' + shots') + index$([[ $DO_PUSH = 1 ]] && echo ' + PR + merge')$([[ $DO_RESET = 1 ]] && echo ' + reset')"
[[ $DRY_RUN -eq 1 ]] && echo "  mode       : DRY RUN"
echo

if [[ $DRY_RUN -eq 0 && $ASSUME_YES -eq 0 ]]; then
  read -r -p "Proceed? [y/N] " reply; [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  echo
fi

# 0. prepare the site repo: clean tree, fresh main, session branch -------------
echo "== site repo =="
if [[ -n "$(git -C "$SITE_REPO" status --porcelain)" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  ! WARNING: $SITE_REPO has uncommitted changes (a real run would abort here)"
  else
    echo "ERROR: $SITE_REPO has uncommitted changes — commit or stash them first." >&2
    echo "       (the publish commit must contain only this session's files)" >&2
    exit 1
  fi
fi
run "git -C '$SITE_REPO' switch --quiet main"
run "git -C '$SITE_REPO' pull --quiet --ff-only"
run "git -C '$SITE_REPO' switch --quiet -C '$BRANCH'"
echo

# 1. snapshot each group's site/ into the portfolio --------------------------
shot_entries=()
for remote in $REMOTES; do
  echo "== $remote =="
  git remote get-url "$remote" >/dev/null 2>&1 || { echo "  ! no such remote, skipping (run scripts/setup-remotes.sh first)" >&2; continue; }
  run "git fetch --quiet $remote"
  dest="$PORTFOLIO/$SESSION_DATE/$remote"
  if git ls-tree --name-only "$remote/main" site/ 2>/dev/null | grep -q .; then
    run "mkdir -p '$dest'"
    run "git archive '$remote/main' site | tar -x --strip-components=1 -C '$dest'"
    shot_entries+=("$SESSION_DATE/$remote")
  else
    echo "  ! no site/ on $remote/main, skipping snapshot" >&2
  fi
  echo
done

# 2. previews -----------------------------------------------------------------
if [[ $DO_SHOTS -eq 1 && ${#shot_entries[@]} -gt 0 && $DRY_RUN -eq 0 ]]; then
  echo "== previews =="
  "$SCRIPT_DIR/screenshot-portfolio.sh" "$PORTFOLIO" "${shot_entries[@]}" || echo "  ! screenshots failed (continuing)"
  echo
elif [[ $DO_SHOTS -eq 1 && $DRY_RUN -eq 1 ]]; then
  echo "  [dry-run] screenshot-portfolio.sh $PORTFOLIO ${shot_entries[*]}"; echo
fi

# 3. index cards (only if no section exists for this date) --------------------
if grep -q "$SESSION_TAG" "$INDEX" 2>/dev/null || grep -q "$SESSION_DATE/" "$INDEX" 2>/dev/null; then
  echo "== index =="
  echo "  section for $SESSION_DATE already present in index.html — leaving cards as-is."
  echo
else
  echo "== index (generating stub cards — edit descriptions afterwards) =="
  # soft gradient palette per group (matches the hand-curated sessions)
  c1=(_ "#ffe9d6" "#d6f0ff" "#e2dcff" "#d8f5e6" "#e8f5d6")
  c2=(_ "#ffd0a8" "#a8d8f5" "#c2b6f5" "#aee6c8" "#cce8a8")
  cards=""
  for remote in $REMOTES; do
    [[ -d "$PORTFOLIO/$SESSION_DATE/$remote" ]] || continue
    n="${remote#group}"
    title="$(sed -n 's:.*<title>\(.*\)</title>.*:\1:p' "$PORTFOLIO/$SESSION_DATE/$remote/index.html" 2>/dev/null | head -1)"
    [[ -z "$title" ]] && title="Groupe $n"
    slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
    [[ -z "$slug" ]] && slug="$remote"
    ci=$(( (n - 1) % 5 + 1 ))
    # Browser-framed card carrying data-fr/data-en so the index.html toggle keeps
    # new sessions bilingual. The h3 (app/brand name) is identical in both languages.
    cards+="      <a class=\"card\" href=\"$SESSION_DATE/$remote/\" style=\"--c1:${c1[$ci]};--c2:${c2[$ci]}\">
        <div class=\"frame\"><div class=\"bar\"><i></i><i></i><i></i><span class=\"url\">$slug</span></div>
          <div class=\"shot\"><span class=\"emoji\">📦</span><img src=\"$SESSION_DATE/$remote/preview.png\" alt=\"\" loading=\"lazy\"></div></div>
        <div class=\"meta\"><span class=\"who\" data-fr=\"Groupe $n\" data-en=\"Group $n\">Groupe $n</span><h3>$title</h3>
          <p data-fr=\"Décrivez l'appli ici.\" data-en=\"Describe the app here.\">Décrivez l'appli ici.</p></div>
      </a>
"
  done
  # human-readable dates, portable (no BSD/GNU date, no locale needed on CI)
  months_fr=(_ janvier février mars avril mai juin juillet août septembre octobre novembre décembre)
  months_en=(_ January February March April May June July August September October November December)
  dy="${SESSION_DATE:0:4}"; dm=$((10#${SESSION_DATE:5:2})); dd=$((10#${SESSION_DATE:8:2}))
  human_fr="$dd ${months_fr[$dm]} $dy"
  human_en="${months_en[$dm]} $dd, $dy"
  section="
  <section>
    <div class=\"sec-head\"><h2 data-fr=\"Session du $human_fr\" data-en=\"Session of $human_en\">Session du $human_fr</h2><span class=\"tag\">tag <code>$SESSION_TAG</code></span></div>
    <div class=\"grid\">
$cards    </div>
  </section>
"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] would insert a section for $SESSION_DATE into index.html"
  else
    MARKER="publish-session.sh insère" SECTION="$section" python3 - "$INDEX" <<'PY'
import os, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    html = f.read()
marker, section = os.environ["MARKER"], os.environ["SECTION"]
for line in html.splitlines(keepends=True):
    if marker in line:
        html = html.replace(line, line + section, 1)
        break
else:
    html = html.replace("<main>", "<main>\n" + section, 1)
with open(path, "w", encoding="utf-8") as f:
    f.write(html)
print("  inserted stub section for", os.path.basename(path))
PY
  fi
  echo
fi

# 4. commit → PR → merge (deploy to unlockers.ai is automatic on main) ---------
echo "== deliver (PR to unlockers-site) =="
if [[ $DRY_RUN -eq 1 ]]; then
  echo "  [dry-run] git add $SUBDIR && commit on $BRANCH"
  echo "  [dry-run] git push -u origin $BRANCH"
  echo "  [dry-run] gh pr create + gh pr merge --merge --delete-branch"
else
  git -C "$SITE_REPO" add "$SUBDIR"
  if git -C "$SITE_REPO" diff --cached --quiet; then
    echo "  nothing to commit."
    git -C "$SITE_REPO" switch --quiet main
  else
    git -C "$SITE_REPO" commit -q -m "Add workshop session $SESSION_DATE to the portfolio"
    echo "  committed on $BRANCH."
    if [[ $DO_PUSH -eq 1 ]]; then
      git -C "$SITE_REPO" push -q -u origin "$BRANCH"
      pr_url="$(cd "$SITE_REPO" && \
        gh pr create --title "Portfolio: workshop session $SESSION_DATE" \
                     --body "Adds the $SESSION_DATE workshop session (snapshots, previews, index cards) to public/business-people-coding/. Opened and merged by publish-session.sh." )"
      echo "  PR opened: $pr_url"
      (cd "$SITE_REPO" && gh pr merge "$BRANCH" --merge --delete-branch) \
        && echo "  merged — deploy to unlockers.ai runs automatically." \
        || echo "  ! merge failed — merge the PR manually: $pr_url"
      git -C "$SITE_REPO" switch --quiet main
      git -C "$SITE_REPO" pull --quiet --ff-only || true
    else
      echo "  (push/PR skipped — branch $BRANCH left in place)"
    fi
  fi
fi
echo

# 5. reset the group repos (chained, reversible) ------------------------------
if [[ $DO_RESET -eq 1 ]]; then
  echo "== reset =="
  reset_args=("$SESSION_TAG" --remotes "$REMOTES")
  [[ $DRY_RUN -eq 1 ]]   && reset_args+=(--dry-run)
  [[ $ASSUME_YES -eq 1 ]] && reset_args+=(--yes)
  "$SCRIPT_DIR/reset-workshop.sh" "${reset_args[@]}"
else
  echo "(reset skipped — run scripts/reset-workshop.sh $SESSION_TAG when ready)"
fi

echo
echo "Published session $SESSION_DATE → https://unlockers.ai/business-people-coding/"

# Workshop facilitation

Facilitator notes for running the "petite appli avec une IA, sans coder" kata
across the five group repositories. Not needed by participants.

> **This repo (`business-people-coding-workshop`) is the facilitation home.**
> The group repos stay pure session workspaces — none of this tooling ever
> propagates to them (reset distributes the `start/*` tag, which lives in the
> group repos themselves).

## At a glance — the two entry points

Both are runnable **from the Actions tab** (no local setup — "Publish session"
and "Init / reset group repos", both manual triggers; they need the
`WORKSHOP_PAT` repo secret, a PAT with write access to the five group repos and
`unlockers-site`) or **locally** as scripts. The code is the documentation;
here is just where to start.

| Script | What it does |
| ------ | ------------ |
| **`scripts/publish-session.sh [date]`** | **Close a session.** Snapshots each group's app into the unlockers.ai portfolio, screenshots it, adds cards, opens + merges a PR on `unlockers-site` — then chains into the reset. This is the one command you usually run. |
| `scripts/reset-workshop.sh <tag>` | Preserve each group's `main` behind a tag, then rewind `main` to the start point. Called by publish; also runnable standalone. |
| `scripts/screenshot-portfolio.sh <dir> [entry…]` | Capture `preview.png` for portfolio apps (used by publish; standalone for backfilling old sessions). |

```bash
# One-time after cloning: wire up the five group remotes (+ fetch tags)
./scripts/setup-remotes.sh

# End-to-end: publish today's session and reset the group repos
./scripts/publish-session.sh --dry-run      # preview everything first
./scripts/publish-session.sh                # publish → PR + merge → reset
```

The portfolio lives at <https://unlockers.ai/business-people-coding/> — the
`public/business-people-coding/` subfolder of the `unlockers-ai/unlockers-site`
repo (checkout: `~/clients/unlockers/unlockers-site`).
The publish script delivers there via branch → PR → merge; merging `main`
auto-deploys. The old changit.fr portfolio (`martinsson/business-people-coding`)
is frozen and no longer published to. Giving participants an easy way
to call a real LLM from their static app: see [LLM-FOR-APPS.md](LLM-FOR-APPS.md).

## Layout

- **The starting point** every group repo is reset to is the newest `start/*`
  tag, which lives in the group repos themselves (fetched locally by
  `setup-remotes.sh`).
- Five Git remotes point at the five group repos (`scripts/setup-remotes.sh`
  configures them):

  | remote   | repo                                            |
  | -------- | ----------------------------------------------- |
  | `group1` | `martinsson/AI-kata-non-dev-group1`             |
  | `group2` | `martinsson/AI-kata-non-dev-group2`             |
  | `group3` | `martinsson/AI-kata-non-dev-group3`             |
  | `group4` | `martinsson/AI-kata-non-dev-group4`             |
  | `group5` | `martinsson/AI-kata-non-dev-group5`             |

  (`git remote -v` to confirm.)

- During a session each group works on **their own repo's `main`** (and on
  `claude/*` branches Claude creates). Between sessions we reset their `main`
  back to the starting point without losing what they did.

## Tag conventions

| Tag                 | Lives on   | Means                                                              |
| ------------------- | ---------- | ----------------------------------------------------------------- |
| `start/hello-world` | all repos  | The canonical starting point (`97fa88e`): bare `site/index.html` saying "Hello, world!" + the Pages deploy workflow. Reset rewinds `main` here. |
| `<session-tag>`     | each group | A snapshot of *that group's* `main` work, taken just before reset. |

> The starting point is the minimal "hello world" scaffold every group branches
> from — **not** any one group's app. The reset script auto-detects the newest
> `start/*` tag, so `start/hello-world` is used by default.

Both are **immutable tags**, so a group's work is preserved and is never
garbage-collected even after `main` is rewound. Tags are simpler and safer than
branches for this — they don't move and won't be touched on the next reset.

# Publishing a session

`scripts/publish-session.sh [<date>]` closes out a session end to end. For each
group remote it first checks the group made **real progress** vs the start point
(`start/*`): unchanged groups are skipped, a borderline trivial/dummy change is
asked about, and only groups with genuine work are published. It then snapshots
`site/` from their `main` into the portfolio subfolder under `<date>/<group>/`,
captures a `preview.png`, and (if no section for that date exists yet) adds
bilingual cards to the portfolio's `index.html`; it then commits on a
`portfolio/session-<date>` branch, opens a PR on `unlockers-site` and merges it
(deploy is automatic), then **chains into the reset** below (which runs for
*every* group, so skipped groups still start clean next session).

```bash
./scripts/publish-session.sh --dry-run        # preview (default date = today)
./scripts/publish-session.sh 2026-06-18        # publish that session, then reset
```

Useful flags: `--all` (publish every group, skip the progress gate),
`--min-lines N` (progress threshold, default 20), `--start <tag>` (baseline to
compare/reset against), `--no-reset` (publish only), `--no-shots` (skip
screenshots), `--no-push` (commit on the branch, skip push/PR/merge),
`--site <dir>` (the `unlockers-site` checkout), `-y`.
If you hand-curate the cards for a date, re-running is safe: the script detects an
existing section and leaves your cards untouched.

# Reset workflow (between sessions)

`publish-session.sh` runs this for you at the end; run it standalone only to reset
without publishing. The script preserves work, then rewinds each group's `main`
to the starting point.

### 1. (Only if the starting point changes) tag a new starting point

The canonical starting point is `start/hello-world` (`97fa88e`). You only need
a new `start/*` tag if you deliberately change the scaffold groups begin from.
Tag the new commit and push it everywhere:

```bash
TAG=start/$(date +%F)
git tag "$TAG" <commit>
for r in group1 group2 group3 group4 group5; do git push "$r" "$TAG"; done
```

The reset script otherwise picks up the newest `start/*` tag automatically.

### 2. Preview the reset (always do this first)

```bash
./scripts/reset-workshop.sh session-$(date +%F) --dry-run
```

Pick a `<session-tag>` that identifies the session you are closing, e.g.
`session-2026-06-16-morning`. It must be **fresh** each time — the script
refuses to overwrite a session tag that already exists on a remote.

### 3. Run the reset

```bash
./scripts/reset-workshop.sh session-2026-06-16-morning
```

For each remote the script:

1. `git fetch <remote>` — get their latest `main`.
2. Push `<session-tag>` pointing at their current `main` → **their work is saved.**
3. Force-reset their `main` to the `start/*` tag (with `--force-with-lease`).
4. Re-push the `start/*` tag so the repo always carries it.

`claude/*`, `solution/*`, `gh-pages` and any other branches are **left
untouched** — only `main` is rewound.

### Options

```
./scripts/reset-workshop.sh <session-tag> [options]

  --start <tag>       Reset target. Default: newest start/* tag.
  --remotes "g1 g3"   Limit to specific remotes. Default: all five.
  -n, --dry-run       Show the plan, change nothing.
  -y, --yes           Skip the confirmation prompt.
```

## Recovering a group's work later

Each session tag is a normal Git ref on the group's repo:

```bash
git fetch group3 --tags
git log group3/main..session-2026-06-16-morning   # what they added that session
git switch -c review-group3 session-2026-06-16-morning
```

List what has been preserved on a remote:

```bash
git ls-remote --tags group3
```

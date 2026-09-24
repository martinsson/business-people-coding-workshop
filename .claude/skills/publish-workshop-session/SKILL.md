---
name: publish-workshop-session
description: Close out a workshop session — snapshot each group's app into the unlockers.ai portfolio, then reset the group repos back to the starting point. Use whenever the user wants to publish, close, wrap up, or reset a workshop session, or asks how publishing/reset between workshops works.
---

# Publish & reset a workshop session

At the end of a workshop, each of the five group repos (`group1`–`group5`,
i.e. `martinsson/AI-kata-non-dev-group<N>`) has an app under `site/` on its
`main`. Closing the session means two things, done by chained scripts in
`scripts/`:

1. **Publish** — copy each group's `site/` into the public portfolio at
   <https://unlockers.ai/business-people-coding/> (repo `unlockers-site`,
   subfolder `public/business-people-coding/`).
2. **Reset** — preserve each group's work behind a tag, then rewind their
   `main` to the starting point so the next session starts clean.

`scripts/publish-session.sh` does both — publish first, then it chains into the
reset. **This is the one command you normally run.**

## The normal flow

```bash
# One-time, after cloning this repo (wires up the five group remotes):
scripts/setup-remotes.sh

# Always preview first — changes nothing:
scripts/publish-session.sh --dry-run

# Publish today's session → PR + merge on unlockers-site → reset the groups:
scripts/publish-session.sh
```

The date argument defaults to today; pass `YYYY-MM-DD` to publish a specific
session (`scripts/publish-session.sh 2026-06-18`).

**Always run `--dry-run` first** and show the user the plan before running for
real. The reset force-rewinds `main` on the group repos, so confirm the date,
remotes, and start tag look right before proceeding.

## What publish does (`scripts/publish-session.sh`)

For each group remote it:

1. Prepares the `unlockers-site` repo (default checkout
   `~/clients/unlockers/unlockers-site`): requires a
   clean tree, updates `main`, branches `portfolio/session-<date>`.
2. **Progress gate (on by default).** Compares the group's `site/` against the
   start point (newest `start/*` tag) and decides:
   - unchanged → **skip** (nothing worth publishing);
   - clear progress (≥ 20 changed lines, or ≥ 2 files touched) → **publish**;
   - borderline (one file, a few lines — a name change or dummy edit) →
     **ask**, showing the diffstat. Under `-y`/`--dry-run` borderline groups
     are skipped (no one to answer).
   Then snapshots `site/` from the group's `main` into
   `public/business-people-coding/<date>/<group>/` (a decoupled copy).
   Reset still runs for **every** group afterwards, so skipped groups start
   clean next session too.
3. Screenshots each published app to `preview.png` (`screenshot-portfolio.sh`).
4. Inserts bilingual stub cards into the portfolio's `index.html` — **only if
   no section for that date exists yet**, so hand-curated cards are never
   clobbered. Card descriptions are placeholders; edit them afterwards.
5. Commits, pushes the branch, opens a PR with `gh` and merges it. Merging
   `main` auto-deploys via GitHub Actions.

Then, unless `--no-reset`, it chains into the reset below.

Useful flags: `--all` (publish every group, bypassing the progress gate),
`--min-lines N` (tune the progress threshold, default 20), `--start <tag>`
(baseline to compare against / reset to), `--no-reset` (publish only),
`--no-shots` (skip screenshots), `--no-push` (commit on the branch but skip
PR + merge), `--site <dir>`, `--remotes "..."`, `-y/--yes` (skip prompts, also
passed to the reset — borderline groups are then skipped, not published).

## What reset does (`scripts/reset-workshop.sh`)

For each group remote it:

1. Tags the group's current `main` as `<session-tag>` on the remote —
   preserves their work; the old commits stay reachable and won't be
   garbage-collected.
2. Force-resets `main` to the starting point (newest `start/*` tag by default;
   canonically `start/hello-world`). Override with `--start <tag>`.
3. Re-pushes the start tag so the remote always carries it.

Branches other than `main` (`claude/*`, `solution/*`, `gh-pages`, …) are left
untouched. The reset **refuses to run** on a remote where `<session-tag>`
already exists, so it can't clobber a previous session — pick a **fresh**
session tag each time (e.g. `session-2026-06-16-morning`).

Run standalone (only if you skipped the reset during publish):

```bash
scripts/reset-workshop.sh session-$(date +%F) --dry-run   # preview
scripts/reset-workshop.sh session-$(date +%F)
```

## Reversibility & safety notes

- The reset only creates a tag and rewinds `main` — fully reversible via the
  `<session-tag>` it just created.
- The whole publish is delivered as a branch → PR → merge on `unlockers-site`
  (that repo's convention is changes-via-PR, not direct pushes to `main`).
- A new `start/*` tag is only needed if you deliberately change the scaffold
  groups begin from — see `docs/WORKSHOP-FACILITATION.md`.

Full prose walkthrough: `docs/WORKSHOP-FACILITATION.md`.

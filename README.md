# Business People Coding — workshop facilitation

Facilitator home for the workshop **« Faire une petite appli avec une IA, sans
coder »**, run across five group repos (`martinsson/AI-kata-non-dev-group1…5`).
Extracted from the group1 repo's `facilitation` branch so the group repos stay
pure session workspaces.

- **Pages site** (slides, LLM demo, links): the facilitation content is served
  via GitHub Pages from this repo.
- **Portfolio of finished apps**: <https://unlockers.ai/business-people-coding/>

## Layout

| Path | What |
| ---- | ---- |
| `slides/` | Workshop presentation — `workshop-web.html` (standalone web deck), `workshop.md`/`workshop.html` (Marp) |
| `docs/WORKSHOP-FACILITATION.md` | How to run a session end to end |
| `docs/LLM-FOR-APPS.md` | How participants call a real LLM from a static app |
| `assets/llm.js`, `assets/llm-demo.html` | The keyless LLM helper + live demo |
| `scripts/` | `setup-remotes.sh`, `publish-session.sh`, `reset-workshop.sh`, `screenshot-portfolio.sh` |
| `.github/workflows/` | Pages deploy + manually-triggered publish & init/reset |

## Running from GitHub Actions (no local setup)

Both operations are `workflow_dispatch` — trigger them from the **Actions** tab:

- **Publish session** — snapshots each group's `site/`, screenshots it, adds
  portfolio cards, opens **and merges** a PR on `unlockers-site` (deploy to
  unlockers.ai is automatic), then chains into the reset. Inputs: date
  (default today), reset on/off, dry-run.
- **Init / reset group repos** — preserves each group's `main` behind a
  session tag, then force-rewinds `main` to the newest `start/*` tag.

One-time setup: add a repo secret **`WORKSHOP_PAT`** — a GitHub PAT with
write access to the five group repos and `martinsson/unlockers-site`.

## Running locally

```bash
./scripts/setup-remotes.sh              # once: wire group1..5 remotes + fetch tags
./scripts/publish-session.sh --dry-run  # preview
./scripts/publish-session.sh            # publish → PR + merge on unlockers-site → reset
```

`publish-session.sh` expects a local `unlockers-site` checkout (`--site <dir>`
to override) and the `gh` CLI authenticated.

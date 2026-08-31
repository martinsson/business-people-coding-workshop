# business-people-coding-workshop

Facilitation hub for the "petite appli avec une IA, sans coder" workshop:
slides, docs, and the publish/reset tooling for the five `AI-kata-non-dev-group*`
repos. See [docs/WORKSHOP-FACILITATION.md](docs/WORKSHOP-FACILITATION.md).

## Never deploy uncommitted changes

Publishing a session is a **deploy of two repos at once** — it merges a PR into
`unlockers-site` (which deploys unlockers.ai on merge) and force-rewinds the five
group repos. Both must run from committed, pushed sources:

```bash
git status --porcelain   # must be empty, here and in the site checkout
git push
```

`publish-session.sh` already refuses a dirty `unlockers-site` checkout, so that
half is enforced. **This** repo is not: running a locally-edited
`publish-session.sh` publishes real sessions with logic that exists nowhere else,
and the *Publish session* workflow — which runs the committed script from a
runner — will then behave differently from your laptop for reasons no diff shows.
Commit and push the script before you use it on a real session.

Prefer the workflow (Actions → *Publish session*) precisely because it can only
run committed code.

## The reset is the destructive half

`reset-workshop.sh` **force-rewinds** each group's `main` to the start tag. It is
reversible only because it tags the old head first (`session-<date>`) — so never
skip the tag, and never run it before the publish step has captured the work.
Dry-run first: `./scripts/publish-session.sh --dry-run`.

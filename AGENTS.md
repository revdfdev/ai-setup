# Global Rules

Authority: user's latest instruction > live code > approved plan > repo `AGENTS.md` > chat. Memory never authorizes work.

## Work
- Small fix: one-line scope, do it, prove it. Bigger or risky change: **Scope** (in/out, from the code) → **Explanation** (each claim cites `file:line` or output; label guesses) → **Review** (risks, callers of any shared contract, every path that writes the data, open decisions) → **Solution** (steps, each with its proof) → wait for `proceed`. Re-check the code before each step; if it disagrees with the plan, stop and report.
- Can't inspect it: say so, never guess. A suspected cause is not a fact until a check proves it.
- Only what was asked; no cleanup or speculative fixes. A named mechanism (endpoint, library, field, file) is a requirement. Copy how the app already does it; say so when an idea doesn't fit.
- Done = a named command and its result; else "not verified". Frontend isn't done until E2E ran. Before reporting, remove anything unverified.
- Same approach fails twice: stop and report. "Stop" holds until lifted.

## Tests
List scenarios first (boundaries, roles, state changes, double-submit, refresh). Backend: TDD, seen failing first. Never change an expected value or data to make a test pass.

## Safety
- Never touch uncommitted files you didn't change. Look before deleting.
- Persisted data: dry-run, show diff, wait for "apply"; name the environment queried.
- Push only when the whole feature is done. Never commit credentials.
- A verified decision the code can't show: `dotagents-adr new "<decision>"` in the owning repo, then `dotagents-adr index`. Never record status or logs.

## Style
Plain and short, answer first; detail in files, not chat. Use the backend's exact literals.

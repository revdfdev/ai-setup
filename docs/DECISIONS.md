# Decisions

- 2026-11-16: Memory lives in Git, not in the tools: project facts are ADRs in the owning repo (`dotagents-adr`), habits are lines in `AGENTS.md`. Claude auto-memory off (`autoMemoryEnabled: false`) so there is one source. Loop is Scope, Explanation (with evidence), Review, Solution, Proceed for bigger changes; live code ranks above an approved plan.
- 2026-11-16: Rebuilt from a rule-by-rule review of `ai-config-ccg`. Codex dropped (uninstalled).
- 2026-11-16: Sync copies instead of linking, so the tools keep working if this repo moves or is deleted.
- 2026-11-16: Only the `guard-bash` hook kept. `prompt-reminder` cost tokens on every prompt and repeated the rules; `proof-gate` forced extra turns; `quality-gate` ran up to 600 s per stop.
- 2026-11-16: 13 skills, all call-only. Dropped duplicates of Claude built-ins (`review`, `simplify`, `memory`), duplicates (`diagnosing-bugs`, `grill-me`), the `flow` router and `teach`. `e2e-analysis` merged into `e2e`.
- 2026-11-16: `effortLevel: low` set again for all models (reverses 2026-11-08). Raise it per session with `/config` for incident or infra work.
- 2026-11-16: "No trackers" and the handoff request removed from the rules; they conflicted with the user's stated preferences.
- 2026-11-08: Bash guard matches subcommands after global flags (`kubectl -n x delete`, `helm -n x upgrade`). Reason: a real prod `helm -n … upgrade` passed the old guard.

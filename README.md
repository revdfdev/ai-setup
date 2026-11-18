# ai-setup

Global rules, skills and the shell guard hook for Claude Code and Antigravity
(both profiles). Replaces `ai-config-ccg`.

| Path | Goes to |
|---|---|
| `AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.antigravity-profile-2/.gemini/GEMINI.md` |
| `skills/` | `~/.claude/skills`, each Antigravity profile's `.gemini/config/skills` |
| `hooks/*.py` (guard, proof gate) | `~/.claude/hooks`, `~/.gemini/hooks`, profile 2's `.gemini/hooks` |
| `bin/*` (`workspace`, `handoff-facts`) | `~/.local/bin` |
| `claude/settings.json` | merged into `~/.claude/settings.json` (these keys win, others kept) |
| `antigravity/hooks.json` | replaces each profile's `.gemini/config/hooks.json` |
| `mcp/servers.json` (`executive-email`, `executive-whatsapp`) | `claude mcp add -s user`; merged into each profile's `.gemini/config/mcp_config.json` (these servers win, others kept) |

```sh
workspace setup      # clone/enable hooks for the repos in hrms-shared/WORKSPACE-REPOS.txt
workspace pull       # fast-forward only the active repos; prints what is new
workspace status     # branch, ahead/behind, dirty per active repo
./sync.sh --dry-run   # show what would change
./sync.sh             # copy everything in; start new sessions afterwards
./tests/test-guard.sh # check the guard's deny/ask/allow decisions
./tests/test-proof-gate.sh
```

Edit files here, never in the tool folders; the next sync overwrites them.
All skills are call-only (`disable-model-invocation: true`): type `/name`.
Reasons for each choice: `docs/DECISIONS.md`.

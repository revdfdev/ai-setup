# ai-setup

Global rules, skills and the shell guard hook for Claude Code and Antigravity
(both profiles). Replaces `ai-config-ccg`.

| Path | Goes to |
|---|---|
| `AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.antigravity-profile-2/.gemini/GEMINI.md` |
| `skills/` | `~/.claude/skills`, `~/.gemini/antigravity/skills` (profile 2 links to it) |
| `hooks/guard-bash.py` | `~/.claude/hooks`, `~/.gemini/hooks`, profile 2's `.gemini/hooks` |
| `claude/settings.json` | merged into `~/.claude/settings.json` (these keys win, others kept) |
| `antigravity/hooks.json` | replaces each profile's `.gemini/config/hooks.json` |

```sh
./sync.sh --dry-run   # show what would change
./sync.sh             # copy everything in; start new sessions afterwards
./tests/test-guard.sh # check the guard's deny/ask/allow decisions
```

Edit files here, never in the tool folders; the next sync overwrites them.
All skills are call-only (`disable-model-invocation: true`): type `/name`.
Reasons for each choice: `docs/DECISIONS.md`.

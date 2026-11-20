---
name: retro
disable-model-invocation: true
description: Review a finished session and propose fixes to the agents' setup (rules, hooks, skills, checks, tools), most severe first.
---

# Retro

A retrospective improves the **environment** for future runs, never the code from the session. Every finding is a proposal with evidence; the user approves before anything changes.

Adapted from mattpocock/skills `retro` (MIT).

## Steps

1. **Read the writing guide**: [`../writing-for-agents/SKILL.md`](../writing-for-agents/SKILL.md) and its `SKILL-MECHANICS.md`, in full. Proposed rule and skill text follows it.

2. **Read the session** the user names; default to the current one. Read every line of the transcript, in chunks if long:
   - Claude Code: `~/.claude/projects/<cwd with / as ->/<session-id>.jsonl`
   - Antigravity: `~/.gemini/antigravity/brain/<id>/.system_generated/logs/transcript.jsonl`, and the same under `~/.antigravity-profile-2/`
   Done when you can list each user request, each mistake the agent made, and each correction the user had to give.

3. **Read the current setup** a finding would change: `~/ai-setup/AGENTS.md`, `~/ai-setup/hooks/`, `~/ai-setup/skills/`, `~/ai-setup/claude/settings.json`, `~/ai-setup/antigravity/hooks.json`, the workspace `CLAUDE.md`, and the touched repo's `.woodpecker.yml` and lint/test config. A fix that already exists but is unwired or broken is the finding, not a new one.

4. **Find candidates** in each category below. Each candidate cites its evidence: a transcript moment (quote the user or the tool result) or a `file:line`.

5. **Present** the candidates, most severe first. Severity: the user had to correct it > it caused a wrong change or a failed retry > it cost time or tokens. For each: evidence, proposed fix, exact file it changes, and how the fix gets checked. Then ask which to apply. Changes go into `~/ai-setup` and reach both agents through `./sync.sh`, following the user's dry-run-then-"apply" rule.

## Categories

- **Repeated correction**: the user told the agent the same thing twice, or said a rule was ignored. The fix is a hook or check first, a rule second.
- **Automated checks**: a mistake a lint, type check, test, hook or CI step could have caught. Mechanical rules (a banned pattern, a file location, a command shape) get a deterministic check: a hook in `~/ai-setup/hooks/`, the repo's linter, or a `.woodpecker.yml` step. A repo with no pre-commit hook and no CI running its checks is itself a finding.
- **Rule conflicts**: two instructions the agent cannot both obey (a harness default versus a user rule, a rule versus a hook). Name both sources; propose the one place to settle it.
- **No-ops**: a rule in `AGENTS.md` or a skill that changed nothing in the session's behaviour, or that the model does by default. Propose deleting the whole sentence.
- **Navigation**: the agent searched long for a file or fact, or missed a hidden dependency between files. The fix is a pointer in the nearest `AGENTS.md`/`CLAUDE.md` or doc.
- **Tool economy**: expensive or wasted tool calls: repeated reads, broad searches, guessed commands retried, a slow MCP tool.
- **Information access**: something the agent needed but could not see (logs, a service's read-only state, a doc). Propose the access, scoped read-only.

## Where fixes belong

- `AGENTS.md` is loaded into every turn of both agents: keep it to rules that change behaviour and pointers. Move detail into a skill or doc behind a pointer.
- Hooks enforce; rules only ask. Prefer a hook when the session shows a rule was ignored.
- Skills hold procedures for one kind of task. Follow `writing-for-agents` for their wording and invocation.

#!/usr/bin/env bash
# Copy this repo's rules, skills and hook into Claude Code, Antigravity and
# Antigravity profile 2. Copies, never links, so the tools keep working if this
# repo moves. Skills this script installed earlier but the repo no longer has
# are removed; skills installed by anything else are left alone.
# Usage: ./sync.sh [--dry-run]
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
run() { if [ $DRY = 1 ]; then echo "would: $*"; else "$@"; fi; }

sync_skills() { # $1 = skills dir
  local dir="$1" manifest="$1/.ai-setup-managed" name
  run mkdir -p "$dir"
  if [ -f "$manifest" ]; then
    while read -r name; do
      [ -n "$name" ] && [ ! -d "$REPO/skills/$name" ] && run rm -rf "${dir:?}/${name:?}"
    done < "$manifest"
  fi
  for s in "$REPO"/skills/*/; do
    name="$(basename "$s")"
    run rm -rf "${dir:?}/${name:?}"
    run cp -r "$s" "$dir/$name"
  done
  [ $DRY = 1 ] || ls "$REPO/skills" > "$manifest"
}

install_hook() { # $1 = hooks dir, $2 = template, $3 = target json, $4 = merge|replace
  run mkdir -p "$1"
  for h in "$REPO"/hooks/*.py; do run cp "$h" "$1/$(basename "$h")"; done
  [ $DRY = 1 ] && { echo "would: write $3 from $2"; return; }
  python3 - "$2" "$3" "$1" "$4" <<'PY'
import json, os, sys
tpl, target, hooks, mode = sys.argv[1:]
new = json.loads(open(tpl).read().replace("@HOOKS@", hooks))
cur = {}
if mode == "merge" and os.path.exists(target):
    cur = json.load(open(target))
cur.update(new)  # template keys win; other settings are kept
json.dump(cur, open(target, "w"), indent=2)
open(target, "a").write("\n")
PY
}

install_mcp() { # $1 = Antigravity mcp_config.json; servers in mcp/servers.json win, others kept
  [ $DRY = 1 ] && { echo "would: merge mcp/servers.json into $1"; return; }
  python3 - "$REPO/mcp/servers.json" "$1" "$HOME" <<'PY'
import json, os, sys
src, target, home = sys.argv[1:]
new = json.loads(open(src).read().replace("@HOME@", home))
cur = {}
if os.path.exists(target) and os.path.getsize(target):
    cur = json.load(open(target))
cur.setdefault("mcpServers", {}).update(new)
json.dump(cur, open(target, "w"), indent=2)
open(target, "a").write("\n")
PY
}

install_claude_mcp() { # user-scope servers; an existing one is replaced so args stay current
  python3 -c 'import json,sys;[print(k, v.get("command", "python3"), *v["args"]) for k,v in json.loads(open(sys.argv[1]).read().replace("@HOME@",sys.argv[2])).items()]' \
    "$REPO/mcp/servers.json" "$HOME" | while read -r name cmd rest; do
    if [ $DRY = 1 ]; then echo "would: claude mcp add $name -s user -- $cmd $rest"; continue; fi
    claude mcp remove "$name" -s user >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    claude mcp add "$name" -s user -- "$cmd" $rest >/dev/null
  done
}

# Claude Code
run cp "$REPO/AGENTS.md" "$HOME/.claude/CLAUDE.md"
install_claude_mcp
sync_skills "$HOME/.claude/skills"
install_hook "$HOME/.claude/hooks" "$REPO/claude/settings.json" "$HOME/.claude/settings.json" merge

# Antigravity (profile 1 and 2). Global skills load from ~/.gemini/config/skills
# (Antigravity's builtin agy-customizations guide; confirmed in its session logs).
for home in "$HOME" "$HOME/.antigravity-profile-2"; do
  [ -d "$home/.gemini" ] || continue
  run cp "$REPO/AGENTS.md" "$home/.gemini/GEMINI.md"
  install_hook "$home/.gemini/hooks" "$REPO/antigravity/hooks.json" "$home/.gemini/config/hooks.json" replace
  sync_skills "$home/.gemini/config/skills"
  install_mcp "$home/.gemini/config/mcp_config.json"
done

# Command-line helpers (e.g. handoff-facts) into ~/.local/bin
run mkdir -p "$HOME/.local/bin" "$HOME/.local/share/ai-setup/handoffs"
for b in "$REPO"/bin/*; do run cp "$b" "$HOME/.local/bin/$(basename "$b")"; done

echo "synced from $REPO$([ $DRY = 1 ] && echo ' (dry run)')"

#!/usr/bin/env bash
# Checks read-gate.py PreToolUse decisions: deny or allow (no output).
cd "$(dirname "$0")/.." || exit 1
fail=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
seq 1 20 > "$tmp/doc.md"
# Transcript: one prompt, then the given Bash command as this turn's only tool call.
transcript() {
  python3 - "$1" "$tmp/t.jsonl" <<'PY'
import json, sys
cmd, out = sys.argv[1:]
rows = [{"type": "user", "message": {"content": "go"}},
        {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": cmd}}]}}]
open(out, "w").write("\n".join(json.dumps(r) for r in rows))
PY
}
check() { # $1 = expected, $2 = edit target, $3 = bash command this turn
  local out got
  transcript "$3"
  out=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"},"transcript_path":"%s","cwd":"%s"}' "$2" "$tmp/t.jsonl" "$tmp" | python3 -I hooks/read-gate.py)
  got=$([ -n "$out" ] && echo deny || echo allow)
  if [ "$got" = "$1" ]; then echo "ok   $1  $2 after: $3"; else echo "FAIL want $1 got $got: $2 after: $3"; fail=1; fi
}
check deny  "$HOME/.claude/CLAUDE.md"         'ls'
check deny  "$HOME/.gemini/GEMINI.md"         'ls'
check deny  "$HOME/repo/main.go"              "sed -n 1,5p $tmp/doc.md"
check allow "/tmp/claude-1000/x/scratch.py"   "sed -n 1,5p $tmp/doc.md"
check allow "$HOME/repo/main.go"              "head -1 $tmp/doc.md"
check allow "$HOME/repo/main.go"              "cat $tmp/doc.md"
exit $fail

#!/usr/bin/env bash
# Checks guard-bash.py decisions: deny, ask, or allow (no output).
cd "$(dirname "$0")/.." || exit 1
fail=0
check() { # $1 = expected (deny|ask|allow), $2 = command
  local out got
  out=$(printf '{"tool_input":{"command":%s}}' "$(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$2")" | python3 -I hooks/guard-bash.py)
  got=$(python3 -c 'import json,sys;d=sys.stdin.read().strip();print(json.loads(d)["hookSpecificOutput"]["permissionDecision"] if d else "allow")' <<<"$out")
  if [ "$got" = "$1" ]; then echo "ok   $1  $2"; else echo "FAIL want $1 got $got: $2"; fail=1; fi
}
check deny  'git commit --no-verify -m x'
check deny  'git commit -m "x" -m "Co-Authored-By: a <b>"'
check ask   'git push origin main'
check ask   'git reset --hard HEAD~1'
check ask   'rm -rf build'
check ask   'kubectl -n prod delete pod x'
check ask   'helm -n x upgrade app ./chart'
check ask   'mongosh --eval "db.x.deleteMany({})"'
check allow 'git status'
check allow 'ls -la'
check allow 'kubectl get pods'
exit $fail

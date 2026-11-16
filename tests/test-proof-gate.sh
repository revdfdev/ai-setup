#!/usr/bin/env bash
# proof-gate.py: blocks a stop that edited code but ran no check or reported no result.
set -euo pipefail
cd "$(dirname "$0")/.."
PY=/usr/bin/python3
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

user_prompt='{"type":"user","message":{"role":"user","content":"fix it"}}'
edit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{}}]}}'
bash_call='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{}}]}}'
result='{"type":"user","message":{"content":[{"type":"tool_result","content":"ok"}]}}'
doc_edit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Write","input":{"file_path":"/repo/docs/plans/x.md"}}]}}'
code_edit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"/repo/src/a.go"}}]}}'
say() { jq -nc --arg t "$1" '{type:"assistant",message:{content:[{type:"text",text:$t}]}}'; }

gate() {
  printf '%s\n' "$@" >"$work/t.jsonl"
  jq -n --arg p "$work/t.jsonl" '{transcript_path:$p,stop_hook_active:false}' |
    "$PY" -I hooks/proof-gate.py | jq -rs '.[0].decision // "allow"'
}
n=0
expect() { local want=$1; shift; local got; got=$(gate "$@"); n=$((n+1)); [[ $got == "$want" ]] || { echo "FAIL claude #$n: want $want got $got"; exit 1; }; }

expect allow "$user_prompt" "$(say 'Answer only.')"
expect block "$user_prompt" "$edit" "$result" "$(say 'Done.')"
expect block "$user_prompt" "$bash_call" "$result" "$edit" "$result" "$(say 'Checks: go test passed')"
expect block "$user_prompt" "$edit" "$result" "$bash_call" "$result" "$(say 'Done, looks good.')"
expect allow "$user_prompt" "$edit" "$result" "$bash_call" "$result" "$(say 'Checks: `go test ./...` -> ok')"
expect allow "$user_prompt" "$edit" "$result" "$(say 'Changed X. Not verified: no test runner here.')"
expect allow "$edit" "$result" "$user_prompt" "$(say 'Next answer.')"
expect allow "$user_prompt" "$doc_edit" "$result" "$(say 'Plan written.')"
expect block "$user_prompt" "$code_edit" "$result" "$doc_edit" "$result" "$(say 'Done.')"
# second stop in a row is let through, so it can never loop
printf '%s\n' "$user_prompt" "$edit" >"$work/t.jsonl"
[[ -z "$(jq -n --arg p "$work/t.jsonl" '{transcript_path:$p,stop_hook_active:true}' | "$PY" -I hooks/proof-gate.py)" ]]
# missing transcript: no crash, no block
[[ -z "$(jq -n '{transcript_path:"/nonexistent/t.jsonl",stop_hook_active:false}' | "$PY" -I hooks/proof-gate.py)" ]]

ag_user='{"step_index":"0","type":"USER_INPUT","source":"USER_EXPLICIT","content":"fix it"}'
ag_edit='{"step_index":"1","type":"PLANNER_RESPONSE","tool_calls":[{"name":"edit_file","args":{}}]}'
ag_run='{"step_index":"2","type":"PLANNER_RESPONSE","tool_calls":[{"name":"run_command","args":{"CommandLine":"go test ./..."}}]}'
ag_out='{"step_index":"3","type":"GENERIC","content":"ok"}'
ag_say() { jq -nc --arg t "$1" '{step_index:"9",type:"PLANNER_RESPONSE",content:$t}'; }
ag_gate() {
  printf '%s\n' "$@" >"$work/a.jsonl"
  jq -n --arg p "$work/a.jsonl" '{transcriptPath:$p,executionNum:1,terminationReason:"NO_TOOL_CALL"}' |
    "$PY" -I hooks/proof-gate.py | jq -rs '.[0].decision // "stop"'
}
expect_ag() { local want=$1; shift; local got; got=$(ag_gate "$@"); n=$((n+1)); [[ $got == "$want" ]] || { echo "FAIL antigravity #$n: want $want got $got"; exit 1; }; }
expect_ag stop "$ag_user" "$(ag_say 'Answer only.')"
expect_ag continue "$ag_user" "$ag_edit" "$ag_out" "$(ag_say 'Done.')"
expect_ag continue "$ag_user" "$ag_run" "$ag_out" "$ag_edit" "$ag_out" "$(ag_say 'Checks: go test ok')"
expect_ag stop "$ag_user" "$ag_edit" "$ag_out" "$ag_run" "$ag_out" "$(ag_say 'Checks: `go test ./...` -> ok')"
expect_ag stop "$ag_user" "$ag_edit" "$ag_out" "$(ag_say 'Not verified: no runner.')"

echo "proof-gate: $n cases + 2 safety checks PASS"

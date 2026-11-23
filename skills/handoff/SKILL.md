---
name: handoff
disable-model-invocation: true
description: Write a handoff file so a new session can continue the full scope without the old chat, and without trusting this session's memory.
---

# Handoff

A handoff fails when it is written from memory: the next session trusts it and guesses
the gaps. So facts come from a script, every other claim carries a source, and the
next session checks before acting.

1. **Record decisions first.** Each verified decision that should outlive the task:
   `mem_save` each to engram (type `decision`, the repo as project).
   The handoff names the engram topic; it does not retell them.
2. **Collect facts with the script**, passing only the repos this task touched:
   `handoff-facts <repo> [<repo> ...]` (add `--since "<date>"` if the work started
   before today). Paste its output unchanged; never type commits or file lists yourself.
3. **Write the file** `<repo>/handoffs/<YYYY-MM-DD>-<topic>.md` (root of the main repo the task touched):

```markdown
# Handoff: <topic> (<date>)

Read this, then check every item against its source before acting. Anything not
here or not checkable is unknown: ask the user, don't guess.

## Goal
<the user's goal in their own words, quoted>

## Decisions (each with a source)
- <decision> — source: <user quote "…" | ADR id | commit | file:line>

## Rejected (don't propose again)
- <option> — why: <user quote or evidence>

## Test status
| Item | e2e | Manual (user) |
|---|---|---|
| <item> | <spec file → passed/failed, date> or not run | tested — source: <user quote "…"> or not tested |

## Done (each with proof)
- <what> — proof: <commit | command → result>

## Not done / open
- <item> — status: <not started | partial: what exists> — blocker or question

## Next step
<one action; say if it needs the user's approval>

## Traps already hit
- <mistake and the fact that avoids it>

## Unverified
- <anything believed but not checked this session>

## Git facts
<handoff-facts output, unchanged>
```

Rules:
- No length cap. Cover the full scope of the user's request, including what was
  asked but not done. Re-read the user's messages in this session to find it.
- A claim without a source goes under **Unverified**, never elsewhere.
- Label every data claim *history* (from logs or saved copies) or *comparison* (against a named file or the current record).
- **Test status** has a row for every item that was built or fixed. Done means the
  user tested it manually; an e2e pass alone is "e2e passed, awaiting manual". Carry
  rows over from the previous handoff, updated, never dropped.
- The next session trusts Test status: it does not re-run or re-ask about a row
  marked tested unless that item's code changed after the test.
- Quote the user for goals, decisions and rejections; don't paraphrase what they meant.
- No secrets. Other agents' uncommitted files stay listed as the script prints them.
- In chat, give only the file path and one line for the next session:
  `Read <repo>/handoffs/<file> and verify each item before acting.`

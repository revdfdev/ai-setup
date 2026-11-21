"""PreToolUse on edits + Stop (Claude Code, Antigravity): a .md document opened
this turn must be read in full before code is edited or the turn ends, or the
reply must say "not read: <file> lines X-Y". Edits to the CLAUDE.md/GEMINI.md
copies that sync.sh generates are denied."""
import json
import os
import re
import shlex
import sys

DOC = (".md", ".markdown")
CLAUDE_READ_DEFAULT = 2000
# sync.sh overwrites these from ~/ai-setup/AGENTS.md, so an edit here is lost.
GENERATED = tuple(os.path.expanduser(p) for p in (
    "~/.claude/CLAUDE.md", "~/.gemini/GEMINI.md", "~/.antigravity-profile-2/.gemini/GEMINI.md"))
PROBE_LINES = 5  # head -n 5 or less is a peek, not a read


def unquote(value):
    # Antigravity stores string args JSON-encoded ("\"/path\"").
    value = str(value or "")
    try:
        return json.loads(value) if value.startswith('"') else value
    except ValueError:
        return value


def line_count(path):
    try:
        with open(path, errors="replace") as f:
            return sum(1 for _ in f)
    except OSError:
        return 0


def shell_reads(command, cwd):
    """Yield (path, start, end) for cat/head/tail/sed -n on .md files; end None = to EOF."""
    for part in re.split(r"&&|\|\||[;|\n]", command):
        try:
            words = shlex.split(part)
        except ValueError:
            continue
        if not words:
            continue
        cmd, args = os.path.basename(words[0]), words[1:]
        files = [a for a in args if a.lower().endswith(DOC)]
        if not files:
            continue
        if cmd == "cat":
            ranges = [(1, None)]
        elif cmd in ("head", "tail"):
            n = 10
            for i, a in enumerate(args):
                if re.fullmatch(r"-\d+", a):
                    n = int(a[1:])
                elif a == "-n" and i + 1 < len(args) and args[i + 1].lstrip("+").isdigit():
                    n = int(args[i + 1].lstrip("+"))
            if cmd == "head" and n <= PROBE_LINES:
                continue
            ranges = [(1, n)] if cmd == "head" else [(-n, None)]
        elif cmd == "sed" and "-n" in args:
            ranges = [(int(a), int(b or a)) for a, b in re.findall(r"(\d+)(?:,(\d+))?p", " ".join(args))]
        else:
            continue
        for f in files:
            path = os.path.normpath(os.path.join(cwd, os.path.expanduser(f)))
            for start, end in ranges:
                yield path, start, end


def turn_calls(entries, session=False):
    """(name, args) for each tool call since the last user prompt (or the whole session), both transcript formats."""
    if any(e.get("type") == "USER_INPUT" for e in entries):
        start = -1 if session else max(i for i, e in enumerate(entries) if e.get("type") == "USER_INPUT")
        for e in entries[start + 1:]:
            if e.get("type") == "PLANNER_RESPONSE":
                for call in e.get("tool_calls") or []:
                    yield call.get("name") or "", {k: unquote(v) for k, v in (call.get("args") or {}).items()}
        return

    def blocks(e):
        c = (e.get("message") or {}).get("content")
        return c if isinstance(c, list) else []

    def is_prompt(e):
        return (e.get("type") == "user" and not e.get("isSidechain")
                and not any(b.get("type") == "tool_result" for b in blocks(e)))

    start = -1 if session else max((i for i, e in enumerate(entries) if is_prompt(e)), default=-1)
    for e in entries[start + 1:]:
        if e.get("type") == "assistant" and not e.get("isSidechain"):
            for b in blocks(e):
                if b.get("type") == "tool_use":
                    yield b.get("name") or "", b.get("input") or {}


def doc_reads(calls, cwd):
    """{path: [(start, end), ...]} line ranges of .md docs read by these tool calls."""
    seen = {}
    for name, args in calls:
        reads = []
        if name == "Read":
            path = str(args.get("file_path") or "")
            first = int(args.get("offset") or 1)
            reads = [(path, first, first + int(args.get("limit") or CLAUDE_READ_DEFAULT) - 1)]
        elif name == "read_file":
            path = str(args.get("Path") or "")
            first = int(args.get("StartLine") or 1)
            reads = [(path, first, int(args["EndLine"]) if args.get("EndLine") else None)]
        elif name in ("Bash", "run_command"):
            reads = list(shell_reads(str(args.get("command") or args.get("CommandLine") or ""), cwd))
        for path, first, last in reads:
            if path.lower().endswith(DOC):
                seen.setdefault(os.path.normpath(path), []).append((first, last))
    return seen


def unread(entries, cwd):
    """{path: [(start, end), ...]} unread line ranges of .md docs opened this turn;
    reads from earlier turns of the session count toward coverage."""
    session = doc_reads(turn_calls(entries, session=True), cwd)
    gaps = {}
    for path in doc_reads(turn_calls(entries), cwd):
        ranges = session[path]
        total = line_count(path)
        covered = set()
        for first, last in ranges:
            if first < 0:  # tail -n N
                first = total + first + 1
            covered.update(range(max(first, 1), min(last or total, total) + 1))
        missing = []
        for n in range(1, total + 1):
            if n in covered:
                continue
            if missing and missing[-1][1] == n - 1:
                missing[-1] = (missing[-1][0], n)
            else:
                missing.append((n, n))
        if missing:
            gaps[path] = missing
    return gaps


def last_text(entries):
    for e in reversed(entries):
        if e.get("type") == "PLANNER_RESPONSE" and not e.get("tool_calls"):
            return e.get("content") or ""
        if e.get("type") == "assistant":
            content = (e.get("message") or {}).get("content")
            texts = [b.get("text", "") for b in content or [] if isinstance(b, dict) and b.get("type") == "text"]
            if texts:
                return "".join(texts)
    return ""


def describe(gaps):
    return "; ".join(
        f"{p} lines " + ", ".join(f"{a}-{b}" if a != b else str(a) for a, b in r)
        for p, r in gaps.items())


def load(path):
    entries = []
    if path and os.path.isfile(path):
        with open(path) as f:
            for line in f:
                try:
                    entries.append(json.loads(line))
                except ValueError:
                    continue
    return entries


def main():
    payload = json.load(sys.stdin)
    antigravity = "transcriptPath" in payload
    cwd = payload.get("cwd") or os.getcwd()
    entries = load(payload.get("transcript_path") or payload.get("transcriptPath"))

    if "toolCall" in payload or "tool_name" in payload:  # PreToolUse on an edit
        if "toolCall" in payload:
            target = unquote((payload["toolCall"].get("args") or {}).get("Path"))
        else:
            target = str((payload.get("tool_input") or {}).get("file_path") or "")
        if os.path.normpath(target) in GENERATED:
            reason = "This file is generated: edit ~/ai-setup/AGENTS.md, then run ./sync.sh."
        elif target.lower().endswith(DOC) or target.startswith("/tmp/"):
            return
        else:
            gaps = unread(entries, cwd)
            if not gaps:
                return
            reason = f"Finish reading before editing code: {describe(gaps)}."
        if "toolCall" in payload:
            json.dump({"decision": "deny", "reason": reason}, sys.stdout)
        else:
            json.dump({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                       "permissionDecision": "deny", "permissionDecisionReason": reason}}, sys.stdout)
        return

    # Stop
    if payload.get("stop_hook_active") or payload.get("executionNum", 1) > 1:
        return
    if antigravity and payload.get("terminationReason") != "NO_TOOL_CALL":
        return
    gaps = unread(entries, cwd)
    final = payload.get("last_assistant_message") or last_text(entries)
    gaps = {p: r for p, r in gaps.items()
            if not re.search(r"(?i)not read[^\n]*" + re.escape(os.path.basename(p)), final)}
    if gaps:
        reason = (f"You only partly read: {describe(gaps)}. Read the rest, or list it in "
                  "your reply as \"not read: <file> lines X-Y\".")
        json.dump({"decision": "continue" if antigravity else "block", "reason": reason}, sys.stdout)


if __name__ == "__main__":
    main()

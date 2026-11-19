"""UserPromptSubmit hook: warn when the conversation context is large."""
import json
import sys

WARN_TOKENS = 200_000


def last_context_tokens(path):
    tokens = 0
    with open(path) as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("subtype") == "compact_boundary":
                tokens = 0  # usage before a compact no longer reflects the context
                continue
            if d.get("type") != "assistant" or d.get("isSidechain"):
                continue
            u = (d.get("message") or {}).get("usage")
            if u:
                tokens = (u.get("input_tokens", 0)
                          + u.get("cache_read_input_tokens", 0)
                          + u.get("cache_creation_input_tokens", 0))
    return tokens


def main():
    data = json.load(sys.stdin)
    path = data.get("transcript_path")
    if not path:
        return
    tokens = last_context_tokens(path)
    if tokens < WARN_TOKENS:
        return
    k = tokens // 1000
    msg = f"Context is ~{k}k tokens. Consider /compact, or /handoff and a new thread."
    print(json.dumps({
        "systemMessage": msg,
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": f"{msg} Mention this to the user in one line at the start of your reply.",
        },
    }))


if __name__ == "__main__":
    main()

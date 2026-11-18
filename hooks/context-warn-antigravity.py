"""Antigravity PreInvocation hook: warn when the conversation context is large."""
import json
import os
import sys

WARN_TOKENS = 150_000
STEP_TOKENS = 25_000  # PreInvocation runs before every model call; warn once per 25k step
STATE = os.path.expanduser("~/.gemini/hooks/.context-warn-state.json")


def last_input_tokens(path):
    tokens = 0
    with open(path) as f:
        for line in f:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if "input_tokens" in d:
                tokens = d["input_tokens"]
    return tokens


def main():
    data = json.load(sys.stdin)
    path = data.get("transcriptPath")
    if not path or not os.path.exists(path):
        print("{}")
        return
    tokens = last_input_tokens(path)
    if tokens < WARN_TOKENS:
        print("{}")
        return
    try:
        with open(STATE) as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = {}
    conv = data.get("conversationId", "")
    step = tokens // STEP_TOKENS
    if state.get(conv, -1) >= step:
        print("{}")
        return
    state[conv] = step
    with open(STATE, "w") as f:
        json.dump(state, f)
    msg = f"Context is ~{tokens // 1000}k tokens. Consider compacting, or a handoff and a new thread."
    print(json.dumps({"injectSteps": [{"systemMessage": {
        "systemMessage": msg + " Mention this to the user in one line at the start of your reply.",
        "metadata": {"user_markdown": f"**{msg}**"},
    }}]}))


if __name__ == "__main__":
    main()

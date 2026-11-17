# tests/lib/user-prompt-hook.sh: driving the user-prompt hook and reading what it sent.
# Used by 0240 (builds them), 0250 and 0590. Moved from parts/0240-continued.sh:
# RHK (line 388), _hook (392), _ctx (393).
# Definitions only. _user_prompt_hook_vars assigns RHK (the same string every
# time, so a second call changes nothing).

_user_prompt_hook_vars() {
  RHK="$FROOT/harness/hooks/user-prompt"
}
_hook() { ( cd "$REPO" && printf '%s' "$1" | "$RHK" 2>&1 ); }
_ctx() { printf '%s' "$1" | python3 -c 'import json,sys;print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>/dev/null; }

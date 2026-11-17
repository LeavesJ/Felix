# tests/lib/attempt-step.sh: the unattended template's attempt step, taken out of
# the shipped template and run under bash -e with npm and claude stubbed.
# Used by 0140 (builds it, runs the install cases) and 0150 (runs it again with
# a claude that records its arguments).
# Moved from parts/0140-the-unattended-repair-acts-only-on-a-brief.sh:
# _attempt_build is lines 163-175 (AT, the extracted step.sh, brief.txt, the npm
# and claude stubs) and _attempt is lines 176-177 (verbatim).
# Definitions only. The builder sets AT first and does nothing more when the stub
# is already there, so in the serial run only 0140's call builds; 0150 then
# overwrites the claude stub as it did.

_attempt_build() {
  AT="$TMP/attempt"
  [ -x "$AT/bin/npm" ] && return 0
mkdir -p "$AT/repo" "$AT/bin"
awk '/- name: Attempt a repair/ { f = 1 } f && /^        run: \|/ { r = 1; next }
     r && /^      [^ ]/ { exit } r { sub(/^          /, ""); print }' \
  "$REAL_HARNESS/templates/unattended.yml" | sed "s#/tmp/brief.txt#$AT/brief.txt#" > "$AT/step.sh"
printf 'brief\n' > "$AT/brief.txt"
cat > "$AT/bin/npm" <<'STUB'
#!/usr/bin/env bash
[ -z "${ATTEMPT_NPM_FAILS:-}" ] && exit 0
printf 'npm error code E404\nnpm error 404 Not Found - GET https://registry.npmjs.org/@anthropic-ai%%2fclaude-code\n' >&2
exit 1
STUB
printf '#!/usr/bin/env bash\nprintf "claude\\n" >> "%s/claude.log"\n' "$AT" > "$AT/bin/claude"
chmod +x "$AT/bin/npm" "$AT/bin/claude"
}
_attempt() { : > "$AT/claude.log"
  ( cd "$AT/repo" && ATTEMPT_NPM_FAILS="$1" PATH="$AT/bin:$PATH" bash -e "$AT/step.sh" ) > "$AT/out" 2>&1; }

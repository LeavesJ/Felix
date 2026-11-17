printf '\ndated lessons mount their claim (audit b14, C026, blind)\n'
# Written blind on 2026-10-24 from the contract alone
# (docs/2026-10-24-audit-fixes/b14-lessons-handoff-and-maintenance-records.md:
# B1 to B11, and section 4's fixture L with A1 to A15), before the fix and
# without reading the lessons code, the CLI or the hooks: felix and the prompt
# hook are run as black boxes. The defect: `felix lesson "T"` writes
# `- **YYYY-MM-DD** T`, and the mount keeps only the first bold span, so every
# lesson written that way is mounted as a bare date. The rule: a lesson whose
# first bold span is exactly a date is mounted as that date, one space and the
# first sentence after it; any other lesson is mounted as today.
#
# Fixture L, all under one mktemp -d in $TMP: a home with project lsn, a memory
# of its own, and a bound repository L/repo committed through _fx_cd. E1 to E6
# are written with `felix lesson`, in that order, then H1 and H2 appended by
# hand, each after a blank line. D is the date felix lesson wrote, read back
# from the E1 line of lessons.md, never computed here. A matched line is a line
# `felix lessons --for` prints under `matched to this change`, with its
# two-space indent; the hook's lessons block is read as the lines of its
# additionalContext that begin `  - **`, which is every mounted line's shape.
# Readings of mine, where the contract leaves room: an assertion that a text is
# absent also asks that something was mounted (or, for the hook, that its JSON
# was read), so an empty output never reads as a pass; and A14 asks that at
# least one mounted line was read at all. Every assertion is emitted on every
# run; when the fixture could not be built, each FAILs and says why (A15, the
# writer's own control, says what the writer did instead). Every felix and hook
# call runs under a 120 s alarm, since macOS ships no timeout.

_b14l_fx0=""
_b14l_L="$(mktemp -d "$TMP/b14l.XXXXXX" 2>/dev/null)"
if [ -n "$_b14l_L" ] && [ -d "$_b14l_L" ]; then _b14l_L="$(cd "$_b14l_L" && pwd -P)"
else _b14l_fx0="mktemp -d under \$TMP made no directory"; _b14l_L="$TMP/b14l-not-made"; fi
_b14l_H="$_b14l_L/home"; _b14l_M="$_b14l_L/mem"; _b14l_R="$_b14l_L/repo"; _b14l_O="$_b14l_L/out"
_b14l_F="$_b14l_M/lsn/lessons.md"
if [ -z "$_b14l_fx0" ]; then
  mkdir -p "$_b14l_H/projects/lsn" "$_b14l_M/lsn" "$_b14l_R" "$_b14l_O" 2>/dev/null \
    && printf '{"name":"lsn","remote_match":"example.invalid/lsn-marker-only","gate":"true"}\n' > "$_b14l_H/projects/lsn/project.json" \
    && printf '# lsn\n' > "$_b14l_H/projects/lsn/CLAUDE.md" \
    || _b14l_fx0="the fixture home under $_b14l_L could not be written"
fi
if [ -z "$_b14l_fx0" ]; then
  ( _fx_cd "$_b14l_R" && git init -q -b main && printf 'lsn\n' > .felix && printf 'a\n' > a.txt && git add .felix a.txt \
    && git -c user.name=b14 -c user.email=b14@example.invalid -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1 \
    || _b14l_fx0="the bound repository $_b14l_R could not be made"
fi
_b14l_fx="$_b14l_fx0"

# TAG STDIN CMD [ARGS...]: CMD run in the repository with the fixture's home and
# memory, under the alarm, both streams to out/TAG.out and the status to out/TAG.rc.
_b14l_go() {
  local t="$1" i="$2"; shift 2
  ( [ -n "$_b14l_R" ] && cd "$_b14l_R" || exit 125
    perl -e 'alarm shift; exec @ARGV or exit 127' 120 \
      env -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$_b14l_H" FELIX_MEMORY="$_b14l_M" "$@" < "$i" ) \
    > "$_b14l_O/$t.out" 2>&1
  printf '%s\n' "$?" > "$_b14l_O/$t.rc" 2>/dev/null
}
_b14l_rc() { cat "$_b14l_O/$1.rc" 2>/dev/null || printf 'none'; }

# ---- the lessons: E1 to E6 through felix lesson, then H1 and H2 by hand
_b14l_E1='Background jobs ignore INT and QUIT signals. Evidence: on 2026-10-22 a gate started with an ampersand skipped the signal tests.'
_b14l_E2='Version 3.2 of bash reads lib/lessons.sh slowly. Second sentence about quadratic expansions.'
_b14l_E3='**A record written inside the tree it describes invalidates itself.** The gate wrote it there.'
_b14l_E4='**2026-09-21** A raise-only reader fails open through its own failure. The walker printed nothing when awk failed.'
_b14l_E5=""; _b14l_i=0
while [ "$_b14l_i" -lt 12 ]; do _b14l_E5="${_b14l_E5}Overflowing claims keep going "; _b14l_i="$((_b14l_i + 1))"; done
_b14l_E6='Quantum widgets need a teleport check before merging. Nobody needs this evidence.'
_b14l_S1='Background jobs ignore INT and QUIT signals.'
# TEXT -> yes when a line of lessons.md holds `** ` and TEXT (trailing blanks aside).
_b14l_inf() {
  local t
  t="$1"; while [ "${t% }" != "$t" ]; do t="${t% }"; done
  LC_ALL=C awk -v t="** $t" 'index($0, t) { f = 1 } END { print (f ? "yes" : "no") }' "$_b14l_F" 2>/dev/null || printf 'no'
}
if [ -z "$_b14l_fx" ]; then
  _b14l_go E1 /dev/null "$FELIX" lesson "$_b14l_E1"
  _b14l_go E2 /dev/null "$FELIX" lesson "$_b14l_E2"
  _b14l_go E3 /dev/null "$FELIX" lesson "$_b14l_E3"
  _b14l_go E4 /dev/null "$FELIX" lesson "$_b14l_E4"
  _b14l_go E5 /dev/null "$FELIX" lesson "$_b14l_E5"
  _b14l_go E6 /dev/null "$FELIX" lesson "$_b14l_E6"
  _b14l_w=""
  for _b14l_i in 1 2 3 4 5 6; do
    [ "$(_b14l_rc "E$_b14l_i")" = 0 ] || _b14l_w="$_b14l_w E$_b14l_i exited $(_b14l_rc "E$_b14l_i");"
  done
  if [ ! -f "$_b14l_F" ]; then _b14l_w="$_b14l_w felix lesson wrote no $_b14l_F;"
  else
    [ "$(_b14l_inf "$_b14l_E1")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E1;"
    [ "$(_b14l_inf "$_b14l_E2")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E2;"
    [ "$(_b14l_inf "$_b14l_E3")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E3;"
    [ "$(_b14l_inf "$_b14l_E4")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E4;"
    [ "$(_b14l_inf "$_b14l_E5")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E5;"
    [ "$(_b14l_inf "$_b14l_E6")" = yes ] || _b14l_w="$_b14l_w lessons.md lacks E6;"
    { printf '\n- **L-7 Rollbacks need a dry run.** Long evidence about rollbacks that nobody needs mounted.\n'
      printf '\n- **2026-09-01** Multi-line claims carry their sentence\n  across a line break. Trailing evidence stays in the file.\n'
    } >> "$_b14l_F" 2>/dev/null || _b14l_w="$_b14l_w H1 and H2 could not be appended;"
  fi
  [ -z "$_b14l_w" ] || _b14l_fx="felix lesson did not write the six entries:${_b14l_w%;}"
fi
# D, from the E1 line: what lies between `- **` and the `** ` that opens E1's text.
_b14l_D="$(LC_ALL=C awk -v t="** $_b14l_S1" 'index($0, "- **") == 1 && (i = index($0, t)) > 5 { print substr($0, 5, i - 5); exit }' "$_b14l_F" 2>/dev/null)"
[ -n "$_b14l_D" ] || [ -n "$_b14l_fx" ] || _b14l_fx="no date could be read from the E1 line of $_b14l_F"
_b14l_D="${_b14l_D:-(no date read)}"

# ---- the runs
_b14l_go F1  /dev/null "$FELIX" lessons --for "background jobs signals"
_b14l_go F4  /dev/null "$FELIX" lessons --for "version slowly"
_b14l_go F5  /dev/null "$FELIX" lessons --for "record written inside invalidates"
_b14l_go F6  /dev/null "$FELIX" lessons --for "raise-only reader fails open"
_b14l_go F7  /dev/null "$FELIX" lessons --for "multi-line claims carry"
_b14l_go F8  /dev/null "$FELIX" lessons --for "overflowing"
_b14l_go F9  /dev/null "$FELIX" lessons --for "rollbacks"
_b14l_go F10 /dev/null "$FELIX" lessons --for "rollbacks background jobs signals"
_b14l_go F11 /dev/null "$FELIX" lessons --for "zebra xylophone"
printf '%s' '{"prompt":"why do background jobs ignore signals"}' > "$_b14l_O/U12.in" 2>/dev/null
_b14l_go U12 "$_b14l_O/U12.in" "$FROOT/harness/hooks/user-prompt"
# The hook's additionalContext, read with python3's json from what it printed:
# the whole output first, then the first object found in it.
_b14l_py='import json, sys
t = open(sys.argv[1], "rb").read().decode("utf-8", "replace")
d = None
try:
    d = json.loads(t)
except Exception:
    dec = json.JSONDecoder(); i = t.find("{")
    while i != -1 and not isinstance(d, dict):
        try:
            d = dec.raw_decode(t, i)[0]
        except Exception:
            d = None
        i = t.find("{", i + 1)
if not isinstance(d, dict):
    sys.exit(3)
h = d.get("hookSpecificOutput")
v = h.get("additionalContext") if isinstance(h, dict) else None
if not isinstance(v, str):
    sys.exit(4)
sys.stdout.buffer.write((v if v.endswith("\n") else v + "\n").encode("utf-8"))'
python3 -c "$_b14l_py" "$_b14l_O/U12.out" > "$_b14l_O/U12.ctx" 2>/dev/null; _b14l_cx=$?

# ---- readers: each prints ok, or what it found instead
_b14l_m() { LC_ALL=C awk 'f && index($0, "  ") == 1 { print } index($0, "matched to this change") { f = 1 }' "$_b14l_O/$1.out" 2>/dev/null; }
_b14l_hl() { LC_ALL=C awk 'index($0, "  - **") == 1 { print }' "$_b14l_O/U12.ctx" 2>/dev/null; }
_b14l_flat() { printf '%s' "$1" | LC_ALL=C tr '\n' '|' | cut -c1-600; }
_b14l_eq() {   # TAG LINE: a matched line is exactly LINE
  local m; m="$(_b14l_m "$1")"
  if printf '%s\n' "$m" | LC_ALL=C awk -v l="$2" '$0 == l { f = 1 } END { exit (f ? 0 : 1) }'; then printf ok
  else printf 'no matched line of --for (%s) is [%s]; its matched lines: [%s]' "$1" "$2" "$(_b14l_flat "$m")"; fi
}
_b14l_bc() {   # TAG PREFIX PART: a matched line begins PREFIX and holds PART
  local m; m="$(_b14l_m "$1")"
  if printf '%s\n' "$m" | LC_ALL=C awk -v p="$2" -v s="$3" 'index($0, p) == 1 && index($0, s) { f = 1 } END { exit (f ? 0 : 1) }'; then printf ok
  else printf 'no matched line of --for (%s) begins [%s] and holds [%s]; its matched lines: [%s]' "$1" "$2" "$3" "$(_b14l_flat "$m")"; fi
}
_b14l_no() {   # TAG TEXT: something was mounted, and the output holds no TEXT
  local l
  if [ -z "$(_b14l_m "$1")" ]; then
    printf 'felix lessons --for (%s) printed no matched line, so the absence of [%s] says nothing: [%s]' "$1" "$2" "$(_b14l_flat "$(cat "$_b14l_O/$1.out" 2>/dev/null)")"
    return 0
  fi
  l="$(LC_ALL=C awk -v t="$2" 'index($0, t) { print; exit }' "$_b14l_O/$1.out" 2>/dev/null)"
  if [ -z "$l" ]; then printf ok; else printf 'the output of --for (%s) holds [%s]: [%s]' "$1" "$2" "$l"; fi
}
_b14l_and() { if [ "$1" = ok ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
_b14l_ck() {   # NAME VERDICT
  if [ -n "$_b14l_fx" ]; then bad "$1" "the fixture was not built: $_b14l_fx"
  elif [ "$2" = ok ]; then ok "$1"
  else bad "$1" "$2"; fi
}

# ---- A1 to A15
_b14l_A1="  - **$_b14l_D** $_b14l_S1"
_b14l_A9='  - **L-7 Rollbacks need a dry run.**'
_b14l_ck "dated lesson: felix lessons --for mounts a felix lesson entry as its date and its first sentence" \
  "$(_b14l_eq F1 "$_b14l_A1")"
_b14l_ck "dated lesson: and not the evidence after that sentence" "$(_b14l_no F1 'Evidence:')"
_b14l_ck "dated lesson: and not a lesson the context does not match" "$(_b14l_no F1 'Quantum widgets')"
_b14l_ck "dated lesson: a period inside a version or a file name does not end the sentence" \
  "$(_b14l_eq F4 "  - **$_b14l_D** Version 3.2 of bash reads lib/lessons.sh slowly.")"
_b14l_ck "dated lesson: a bold claim after the date is mounted with its bold, and nothing after it" \
  "$(_b14l_and "$(_b14l_eq F5 "  - **$_b14l_D** **A record written inside the tree it describes invalidates itself.**")" "$(_b14l_no F5 'The gate wrote it there')")"
_b14l_ck "dated lesson: a date repeated in bold after the date still mounts the claim sentence" \
  "$(_b14l_and "$(_b14l_bc F6 "  - **$_b14l_D** " 'A raise-only reader fails open through its own failure.')" "$(_b14l_no F6 'The walker printed nothing')")"
_b14l_v="$(_b14l_m F7 | LC_ALL=C awk 'index($0, "  - **2026-09-01** ") == 1 && index($0, "Multi-line claims carry their sentence") && index($0, "across a line break.") { f = 1 } END { printf "%s", (f ? "ok" : "none") }')"
[ "$_b14l_v" = ok ] || _b14l_v="no matched line of --for (F7) begins [  - **2026-09-01** ] and holds both [Multi-line claims carry their sentence] and [across a line break.]; its matched lines: [$(_b14l_flat "$(_b14l_m F7)")]"
_b14l_ck "dated lesson: a sentence that crosses a line break is mounted whole on one line, without what follows it" \
  "$(_b14l_and "$_b14l_v" "$(_b14l_no F7 'Trailing evidence')")"
_b14l_v="$(_b14l_m F8 | LC_ALL=C awk -v p="  - **$_b14l_D** Overflowing claims keep going" '
  index($0, p) == 1 && !f { n = length($0) - 2; f = 1 }
  END { if (!f) printf "none"; else if (n < 200 || n > 240) printf "that line is %d characters without its indent", n; else printf "ok" }')"
[ "$_b14l_v" != none ] || _b14l_v="no matched line of --for (F8) begins [  - **$_b14l_D** Overflowing claims keep going]; its matched lines: [$(_b14l_flat "$(_b14l_m F8)")]"
_b14l_ck "dated lesson: a text with no sentence end is mounted from its first words, cut to 240 characters" "$_b14l_v"
_b14l_ck "dated lesson: an L-numbered entry is still mounted as its bold span alone" \
  "$(_b14l_and "$(_b14l_eq F9 "$_b14l_A9")" "$(_b14l_no F9 'Long evidence')")"
_b14l_ck "dated lesson: an L-numbered and a dated entry matched together are each mounted by their own rule" \
  "$(_b14l_and "$(_b14l_eq F10 "$_b14l_A1")" "$(_b14l_eq F10 "$_b14l_A9")")"
if LC_ALL=C awk 'index($0, "nothing matched this context") { f = 1 } END { exit (f ? 0 : 1) }' "$_b14l_O/F11.out" 2>/dev/null; then _b14l_v=ok
else _b14l_v="felix lessons --for (F11) does not say nothing matched this context: [$(_b14l_flat "$(cat "$_b14l_O/F11.out" 2>/dev/null)")]"; fi
_b14l_ck "dated lesson: a context that matches nothing still says nothing matched" "$_b14l_v"
if [ "$_b14l_cx" -ne 0 ]; then
  _b14l_v="no hookSpecificOutput.additionalContext could be read from the hook's output (python3 exited $_b14l_cx): [$(_b14l_flat "$(cat "$_b14l_O/U12.out" 2>/dev/null)")]"
elif LC_ALL=C awk -v l="$_b14l_A1" '$0 == l { f = 1 } END { exit (f ? 0 : 1) }' "$_b14l_O/U12.ctx" 2>/dev/null; then _b14l_v=ok
else _b14l_v="no line of the hook's additionalContext is [$_b14l_A1]; its lesson lines: [$(_b14l_flat "$(_b14l_hl)")]"; fi
_b14l_ck "dated lesson: the prompt hook mounts the dated lesson's claim sentence" "$_b14l_v"
if [ "$(_b14l_rc U12)" != 0 ]; then _b14l_v="the hook exited $(_b14l_rc U12)"
elif [ "$_b14l_cx" -ne 0 ]; then _b14l_v="no additionalContext could be read from the hook's output (python3 exited $_b14l_cx)"
else
  _b14l_v="$(LC_ALL=C awk 'index($0, "Evidence:") { print; exit }' "$_b14l_O/U12.ctx" 2>/dev/null)"
  if [ -z "$_b14l_v" ]; then _b14l_v=ok; else _b14l_v="the hook's context holds [$_b14l_v]"; fi
fi
_b14l_ck "dated lesson: and the hook exits 0 with no evidence sentence in its context" "$_b14l_v"
_b14l_v="$({ for _b14l_t in F1 F4 F5 F6 F7 F8 F9 F10; do _b14l_m "$_b14l_t"; done; _b14l_hl; } | LC_ALL=C awk '
  { n++; if (length($0) > m) { m = length($0); w = $0 } }
  END { if (!n) printf "no mounted line was read from any of the runs"; else if (m > 242) printf "a mounted line is %d characters with its indent: [%s]", m, w; else printf "ok" }')"
_b14l_ck "dated lesson: every mounted line is at most 240 characters" "$_b14l_v"
# A15 is the writer's own control: it rests on the home and the repository, and
# says itself what felix lesson wrote instead.
_b14l_v=""
LC_ALL=C awk -v l="- **$_b14l_D** $_b14l_E1" '$0 == l { f = 1 } END { exit (f ? 0 : 1) }' "$_b14l_F" 2>/dev/null \
  || _b14l_v="$_b14l_v lessons.md has no line [- **$_b14l_D** $_b14l_E1];"
case "$_b14l_D" in
  [0123456789][0123456789][0123456789][0123456789]-[0123456789][0123456789]-[0123456789][0123456789]) ;;
  *) _b14l_v="$_b14l_v D [$_b14l_D] does not have the shape YYYY-MM-DD;" ;;
esac
[ "$(_b14l_rc E1)" = 0 ] || _b14l_v="$_b14l_v felix lesson exited $(_b14l_rc E1) for E1;"
if [ -n "$_b14l_fx0" ]; then
  bad "dated lesson: felix lesson still writes the entry as a bold date and the text" "the fixture was not built: $_b14l_fx0"
elif [ -n "$_b14l_v" ]; then
  _b14l_v="${_b14l_v# }"; bad "dated lesson: felix lesson still writes the entry as a bold date and the text" "${_b14l_v%;}"
else ok "dated lesson: felix lesson still writes the entry as a bold date and the text"; fi

# ---- review round, M1 (A43): this batch's parts pass part 0590's local scan
# Part 0590's check `no local assignment reads one declared beside it` runs a
# python scanner, written from 0590's own text, over every suite file. A helper
# of this part once declared a local and assigned it again on the same line,
# which that scanner reports (it does not tell a declaration from a later plain
# assignment), so 0590 failed on the branch. This lifts the scanner from 0590's
# text as it stands (the lines after the one that begins `cat > "$SR"`, up to
# the line `PY`), so it follows the scanner when the scanner changes, and runs
# it over every part numbered 1890 to 1909 that exists: it must report none of
# them. The same scanner, run over one planted line of the shape it exists for,
# must report that line, so a lift that went wrong, or a scanner that reports
# nothing at all, never reads as a pass. A missing 0590, or a file set without
# this part in it, is a FAIL that says so.
_b14l_n="b14 parts: part 0590's local-assignment scanner, lifted from its text, reports no line of this batch's parts"
_b14l_v=""; _b14l_sp=""; _b14l_bp=(); _b14l_me=""
for _b14l_t in "$HERE"/parts/0590-*.sh; do if [ -f "$_b14l_t" ]; then _b14l_sp="$_b14l_t"; break; fi; done
for _b14l_t in "$HERE"/parts/189[0123456789]-*.sh "$HERE"/parts/190[0123456789]-*.sh; do
  if [ -f "$_b14l_t" ]; then
    _b14l_bp[${#_b14l_bp[@]}]="$_b14l_t"
    case "${_b14l_t##*/}" in 1890-*) _b14l_me=yes ;; esac
  fi
done
_b14l_sr="$_b14l_L/selfref.py"; _b14l_pl="$_b14l_L/b14-planted.sh"
if [ -n "$_b14l_fx0" ]; then _b14l_v="no scratch directory to lift the scanner into: $_b14l_fx0"
elif [ -z "$_b14l_sp" ]; then _b14l_v="no part 0590 under $HERE/parts to lift the scanner from"
elif [ -z "$_b14l_me" ]; then _b14l_v="the parts numbered 1890 to 1909 under $HERE/parts do not include this part (1890): [${_b14l_bp[*]:-none}]"
elif ! LC_ALL=C awk 'f && $0 == "PY" { e = 1; exit } f { print } !f && index($0, "cat > \"$SR\"") == 1 { f = 1 } END { exit (e ? 0 : 1) }' \
       "$_b14l_sp" > "$_b14l_sr" 2>/dev/null; then
  _b14l_v="no scanner could be lifted from $_b14l_sp: no line beginning [cat > \"\$SR\"] is followed by a line [PY]"
elif ! printf '  %s q="$1"; q="${q}x"\n' local > "$_b14l_pl" 2>/dev/null; then
  _b14l_v="the planted line could not be written to $_b14l_pl"
else
  _b14l_t="$(perl -e 'alarm shift; exec @ARGV or exit 127' 120 python3 "$_b14l_sr" / "$_b14l_pl" 2>&1)"
  case "$_b14l_t" in
    *b14-planted.sh:1*)
      _b14l_t="$(perl -e 'alarm shift; exec @ARGV or exit 127' 120 python3 "$_b14l_sr" / "${_b14l_bp[@]}" 2>&1)"; _b14l_rc=$?
      if [ "$_b14l_rc" -ne 0 ]; then _b14l_v="the lifted scanner exited $_b14l_rc over this batch's parts: [$(_b14l_flat "$_b14l_t")]"
      elif [ -n "$_b14l_t" ]; then _b14l_v="it reports [$(_b14l_flat "$_b14l_t")]: a line that begins local and then assigns, reading it, a name declared on that line"
      fi ;;
    *) _b14l_v="the lifted scanner does not report the planted line [  local q=\"\$1\"; q=\"\${q}x\"], so its silence says nothing: it printed [$(_b14l_flat "$_b14l_t")]" ;;
  esac
fi
if [ -z "$_b14l_v" ]; then ok "$_b14l_n"; else bad "$_b14l_n" "$_b14l_v"; fi

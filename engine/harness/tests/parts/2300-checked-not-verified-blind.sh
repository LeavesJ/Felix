# >>> checked-not-verified
printf '\nchecked, not verified: the engine'"'"'s own words say what ran and claim no proof (C1-C18; blind)\n'
# Blind, written on 2026-10-31 from docs/2026-10-31-checked-not-verified-contract.md alone (C1-C18), before the
# change existed, without reading any branch past b190f928. Engine source was read only as far as calling it needs:
# a name, its arguments, the files it reads. Assertion names start `cnv A`; each says which clause it holds.
#
# Behaviour where a fixture reaches it: felix help (C1), felix install against a claude stub (C2), felix classify
# (C4, C5), hooks/stop (C6, C7, C15), felix_hold_tree_seen (C7), felix receipt (C8), felix_pulse_backup (C9),
# _fn_sentence (C10), felix_stop_debt (C15) and hooks/subagent-stop (C16), each from $REAL_HARNESS (the CLI and the
# hooks from a content copy of it in this part's own home). Text where behaviour is out of reach or the thing is text
# by nature, read from the engine under test ($REAL_HARNESS and its parent): C3 (the race in felix merge), C11 (the
# tick's deploy-owed reason needs a plugin cache entry and a land tick), C12, C13, C14 (templates) and C17 (/felix).
# C18 is a check this part implements (_cnv_check) and runs over the engine under test and over fixtures.
#
# Readings, where the contract leaves room:
# - Every assertion that a word is gone also asserts the new word is there (the contract's How it is tested).
# - C1: the receipt line is asserted as a whole line of felix help's output; the rest of help is not.
# - C2: "both paths": the first comparison is felix install --no-bump with the source tree equal to the cache; "after
#   a bump" is felix install with the source one line ahead and the version equal to the cache's, against a claude
#   stub whose `plugin update` installs the source at the bumped version. Each run prints exactly one line ending in
#   "the installed engine matches this tree", equal byte for byte (so the label column is the clause's eleven). The
#   no-match case is --no-bump with the trees differing: the WARNING line and neither label.
# - C4, C5: felix classify --base HEAD~1 on a docs change (green, no evidence.tsv) and on src/safe/x.js under a
#   project whose risk.tsv makes ^src/safe/ green and whose evidence.tsv wants a test for ^src/. <why> is not pinned:
#   C5's first line is matched as "Reversible, but " ... ". Not auto-merge eligible: a green".
# - C6: "the overnight charge" is read as the night log's refused row (felix_overnight_log_event), whose detail
#   carries "gate <reason>;"; "the cloud debt message" as the hook's output on the debt stop of a cloud session.
#   "<8 chars>" is the session id's first eight characters.
#   The cloud debt stop prints its message as stdout with no decision, as it does today (other:0:1:debt).
# - C7: records are laid by hand at state/held-tree/<sid> under the home, one line, tab-separated. "Every other
#   reason" includes never verified given as the reason: it matches only its own exact line, so the widening is one
#   way (the reason never checked accepts the old line; the reason never verified does not accept the new one).
# - C8: felix receipt --base <the base commit>. Checked: a gate receipt written by felix_verify_record with status 0
#   for felix_tree_id of the tree, and a docs-only change (green tier, no evidence.tsv). Unchecked: the same tree
#   edited after the gate (stale), then with the gate receipt removed (none). "The receipt's own fixed text holds
#   neither word" is read as: the whole receipt, lower-cased, holds neither verified nor unverified as a word (the
#   fixture's names hold neither). Indeterminate (a base that names nothing) is the control for what does not change.
# - C9: felix_pulse_backup under /bin/bash. Disk: a bare repository by path. Network: origin ssh://example.invalid/
#   <path>, with GIT_SSH_COMMAND naming a stub that runs git's pack commands on this machine. Not known: origin
#   ext::git %s <path>, with protocol.ext.allow=always in the memory repository. "The stamp" is state/pulse.last-push.
# - C10: _fn_sentence's whole output and status; landed, deploy-owed and paused are the controls.
# - C15: felix_stop_debt called with CLAUDE_CODE_REMOTE=true, and the hook's debt stop of a cloud session; the whole
#   message is asserted with the reason in parentheses; without CLAUDE_CODE_REMOTE=true it prints nothing (control).
# - C16: the SubagentStop hook in a governed checkout dirty with work no gate has passed.
# - C17: "ends" is the file's last two non-empty lines.
# - C18: an allowed name is removed with nothing put in its place; lines are named FILE:LINE:TEXT, FILE relative to
#   the directory, files in byte order; a tracked file absent from the working tree is skipped; a directory that is
#   not inside a git work tree is read whole (find -type f). The check over the engine also says it read many files,
#   so it cannot pass by reading none.
#
# Round 2, not blind (2026-10-31, after the blind run): the contract's C18 gained one name allowed in one file,
# `never verified` in harness/lib/verify.sh, because C7 cannot accept the old reason without naming it. The check
# reads it from a second list, and A43 shows it allowed there and refused in any other file.
#
# Round 3, not blind (2026-10-31, after the first adversarial review and its tests lens). The contract's round 3
# rewrote C11, C15 and C16, so A29, A34, A35 and A37 now expect its words and refuse round 1's too. C18 as amended
# matches proves as well, allows each name only in the files that need it (the old reason only as the pattern
# lib/verify.sh greps for), reads a Markdown file's # lines as the headings they are, and reads a directory git
# tracks nothing of whole. A40 and A43 moved to that rule; A44-A48 are new, and the last review round widened A45
# to every allowed text and added A48. The other round-3 clauses are part 2301's, written blind.
CNV="$TMP/cnv"; mkdir -p "$CNV"; CNV="$(cd "$CNV" && pwd -P)"
CNVCH="$CNV/home"; CNVCM="$CNV/mem"; CNVCU="$CNV/user"; CNV_CP="$CNVCH/projects/cp"; CNV_CE="$CNVCH/projects/ce"
mkdir -p "$CNV_CP" "$CNV_CE" "$CNVCM" "$CNVCU" "$CNV/plain" "$CNV/bin"
_copy_content "$REAL_HARNESS" "$CNVCH/harness"
printf '{"name": "cp", "gate": "true"}\n' > "$CNV_CP/project.json"; printf '# cp\n' > "$CNV_CP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$CNV_CP/probes.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$CNV_CP/risk.tsv"
printf '{"name": "ce", "gate": "true"}\n' > "$CNV_CE/project.json"; printf '# ce\n' > "$CNV_CE/CLAUDE.md"
cp "$CNV_CP/probes.tsv" "$CNV_CE/probes.tsv"
{ cat "$REAL_HARNESS/templates/risk.tsv"; printf 'green\tpath\t^src/safe/\tdeclared safe by this project\n'; } > "$CNV_CE/risk.tsv"
printf 'unit\t^src/\t^tests?/\tcode changes need a test\n' > "$CNV_CE/evidence.tsv"
CNV_VLOG="$CNVCM/cp/verification.log"

# ---- helpers ----
_cnv_repo() {   # DIR PROJECT -> a checkout of PROJECT at DIR, .felix and WORK.txt committed on main
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf '%s\n' "$2" > .felix && printf 'base\n' > WORK.txt && git add -A \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1
}
_cnv_commit() { ( _fx_cd "$1" && git add -A && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm "$2" ) >/dev/null 2>&1; }
_cnv_lib() { ( export FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU"
               . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/verify.sh"; "$@" ); }
_cnv_cli() {   # DIR ARGS... -> what the home's felix printed in DIR, both streams
  local d="$1"; shift
  ( cd "${d:?}" && env -u CLAUDE_CODE_REMOTE HOME="$CNVCU" FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" "$CNVCH/harness/felix" "$@" 2>&1 )
}
_cnv_yn() { if [ "$1" -gt 0 ] 2>/dev/null; then printf yes; else printf no; fi; }
_cnv_in() { case "$1" in *"$2"*) printf yes ;; *) printf no ;; esac; }
_cnv_hasl() { case "
$1
" in *"
$2
"*) printf yes ;; *) printf no ;; esac; }
# FILE NEEDLE -> lines of FILE holding NEEDLE; _cnv_eqn FILE LINE -> lines of FILE that, leading blanks aside, are LINE.
_cnv_cnt() { CNV_NEEDLE="$2" LC_ALL=C awk 'index($0, ENVIRON["CNV_NEEDLE"]) { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 0; }
_cnv_eqn() { CNV_NEEDLE="$2" LC_ALL=C awk '{ s = $0; sub(/^[ \t]+/, "", s) } s == ENVIRON["CNV_NEEDLE"] { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 0; }
_cnv_rows() { [ -f "$1" ] || { printf 0; return 0; }; LC_ALL=C awk 'END { print NR + 0 }' "$1" 2>/dev/null || printf 0; }
_cnv_tree() {   # PID -> it and everything below it
  ps -A -o pid= -o ppid= 2>/dev/null | LC_ALL=C awk -v root="$1" '
    { kids[$2] = kids[$2] " " $1 }
    END { q = root; out = ""
          while (q != "") { n = split(q, a, " "); q = ""
                            for (i = 1; i <= n; i++) if (a[i] != "") { out = out " " a[i]; q = q kids[a[i]] } }
          print out }'
}
# HOOK DIR PAYLOAD [NAME=value ...] -> one hook run in DIR, killed with its tree at 30 s (exit 124). CNV_RC, CNV_O
# (stdout), CNV_NV (rows it added to cp's verification.log) and CNV_LV (the last of them).
_cnv_run() {
  local hook="$1" dir="$2" pay="$3" pid n=0 k v0
  shift 3
  v0="$(_cnv_rows "$CNV_VLOG")"
  rm -f "$CNV/h.o" "$CNV/h.e" "$CNV/h.rc"
  ( cd "${dir:?}" && printf '%s' "$pay" \
      | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU" \
            "$@" "$hook" > "$CNV/h.o" 2> "$CNV/h.e"
    echo "$?" > "$CNV/h.rc" ) &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    for k in $(_cnv_tree "$pid"); do kill -9 "$k" 2>/dev/null; done
    wait "$pid" 2>/dev/null; CNV_RC=124
  else
    wait "$pid" 2>/dev/null; CNV_RC="$(cat "$CNV/h.rc" 2>/dev/null)"; CNV_RC="${CNV_RC:-none}"
  fi
  CNV_O="$(cat "$CNV/h.o" 2>/dev/null)"
  CNV_NV=$(( $(_cnv_rows "$CNV_VLOG") - v0 ))
  CNV_LV=""; [ "$CNV_NV" -gt 0 ] && CNV_LV="$(tail -n 1 "$CNV_VLOG" 2>/dev/null)"
  return 0
}
_cnv_pay() {   # SID FLAG [TRANSCRIPT] -> a Stop payload
  local t=""
  [ -n "${3:-}" ] && t=",\"transcript_path\":\"$3\""
  printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"%s}' "$2" "$1" "$t"
}
_cnv_stop() { local sid="$1" flag="$2"; shift 2; _cnv_run "$CNVCH/harness/hooks/stop" "$CNVCR" "$(_cnv_pay "$sid" "$flag")" "$@"; }
_cnv_f() { cut -f"$1" <<< "$CNV_LV"; }
# What the last run did: <block|silent|other>:<exit status>:<rows added>:<field 2 of the last row, or ->
_cnv_sum() {
  local kind v="-"
  case "$CNV_O" in '') kind=silent ;; *'"decision"'*'"block"'*) kind=block ;; *) kind=other ;; esac
  [ "$CNV_NV" -gt 0 ] && v="$(_cnv_f 2)"
  printf '%s:%s:%s:%s' "$kind" "$CNV_RC" "$CNV_NV" "$v"
}
_cnv_seed() { mkdir -p "$CNVCH/state/held-tree" && printf '%s\t%s\t%s\n' "$2" "$3" "$4" > "$CNVCH/state/held-tree/$1"; }
_cnv_jf() {   # JSON PATH -> the field, a string as it is and anything else as JSON
  python3 -c 'import json, sys
d = json.loads(sys.stdin.read())
for p in sys.argv[1].split("."): d = d[p]
print(d if isinstance(d, str) else json.dumps(d))' "$2" <<< "$1" 2>/dev/null
}
# TEXT -> yes when TEXT, lower-cased, holds verified or unverified as a word
_cnv_vword() { LC_ALL=C awk 'tolower($0) ~ /(^|[^a-z0-9_])(un)?verified([^a-z0-9_]|$)/ { n++ } END { print (n ? "yes" : "no") }' <<< "$1"; }

# C18's check. The allowed names, one a line, read as bytes by the check's awk (getline), never through awk -v,
# which would turn the backslash and t of 'unverified\t into a tab.
# Round 3, not blind (after the tests review, 2026-10-31): no name is allowed everywhere. Each is allowed in the files
# that need it, as FILE<TAB>NAME with FILE relative to the directory read; everything after the first tab is the name.
# Round 2 added the first such row, the old hold reason C7 cannot accept without naming; round 3 narrows it to the
# pattern text the compatibility greps for.
: > "$CNV/allowed"
# Round 4, not blind (docs/2026-11-07-not-green-deploy-failed-contract.md, K12): the two kinds #482 kept moved. The entries
# deployed-unverified (green-tick.sh, notify.sh), 'unverified\t (escape.sh) and == "unverified" (green-install.sh) are gone;
# the old ledger kind is allowed only as the case label notify.sh accepts it by, and the old blocker kind only as the
# clause green-install.sh's _gt_class reads it by. Round 5 (K12, K14), not blind: and as the text by which green-tick.sh's quiet
# check reads a refusal recorded before the rename.
printf '%s\t%s\n' 'harness/hooks/stop' 'state/verified' 'harness/lib/notify.sh' 'deployed-unverified)' \
  'harness/hooks/subagent-stop' 'subagent-unverified' 'harness/lib/green-install.sh' '$1 == "unverified"' \
  'harness/lib/green-tick.sh' 'old="  unverified  ${b#"  not-green   "}"' \
  'harness/lib/verify.sh' "$(printf -- '-e "$3\tnever verified\t${5:-}"')" > "$CNV/allowed-in"
_cnv_list() {   # DIR -> the files the check reads, relative to DIR, in byte order, harness/tests/ left out
  # Round 3, not blind: git's list only where git tracks something under DIR, as _copy_content asks. A directory in a
  # work tree that tracks none of it (a plugin cache under a home kept in git) is read whole, not as nothing.
  if [ -n "$(git -C "$1" ls-files -c . 2>/dev/null | head -1)" ]; then
    git -C "$1" ls-files -z -- . 2>/dev/null | tr '\0' '\n'
  else
    ( cd "${1:?}" && find . -type f 2>/dev/null | sed 's|^\./||' )
  fi | LC_ALL=C awk 'index($0, "harness/tests/") != 1' | LC_ALL=C sort
}
_cnv_check() {   # DIR -> FILE:LINE:TEXT for each line the check fails on; 0 when none, 1 when some, 2 when nothing to read
  local d="$1" f n=0 files=()
  [ -d "$d" ] || return 2
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$d/$f" ] || continue
    files[n]="$d/$f"; n=$((n + 1))
  done < <(_cnv_list "$d")
  [ "$n" -gt 0 ] || return 2
  CNV_PRE="$d/" LC_ALL=C awk -v A="$CNV/allowed" -v B="$CNV/allowed-in" '
    BEGIN { k = 0; while ((getline l < A) > 0) if (l != "") al[++k] = l; close(A); p = ENVIRON["CNV_PRE"]
            m = 0; while ((getline l < B) > 0) if ((q = index(l, "\t")) > 1) { bf[++m] = substr(l, 1, q - 1); bn[m] = substr(l, q + 1) }
            close(B) }
    { f = FILENAME; if (index(f, p) == 1) f = substr(f, length(p) + 1)
      # Round 3, not blind: in a Markdown file a # line is a heading a person reads, not a comment.
      s = $0; sub(/^[ \t]+/, "", s); if (substr(s, 1, 1) == "#" && f !~ /\.md$/) next
      t = $0
      for (i = 1; i <= k; i++) while ((j = index(t, al[i])) > 0) t = substr(t, 1, j - 1) substr(t, j + length(al[i]))
      for (i = 1; i <= m; i++) if (bf[i] == f) while ((j = index(t, bn[i])) > 0) t = substr(t, 1, j - 1) substr(t, j + length(bn[i]))
      t = tolower(t)
      # Round 3, not blind: proves, the claim form of proven (contract C18 as amended).
      if (t ~ /(^|[^a-z0-9_])((un)?(verified|proven)|proves)([^a-z0-9_]|$)/) {
        printf "%s:%d:%s\n", f, FNR, $0; hit = 1 }
    }
    END { exit (hit ? 1 : 0) }' "${files[@]}"
}

# ---- C1: felix help --------------------------------------------------------------------------------------------------
CNV_HELP="$(_cnv_cli "$CNV/plain" help)"
is "cnv A1 (C1): felix help prints the line [    felix receipt          what changed, its risk, and whether anything checked it], and no line saying whether anything verified it" \
   "new=$(_cnv_hasl "$CNV_HELP" '    felix receipt          what changed, its risk, and whether anything checked it') old=$(_cnv_in "$CNV_HELP" 'whether anything verified it')" \
   "new=yes old=no"

# ---- C2: felix install, against a claude stub ------------------------------------------------------------------------
# The stub answers plugin list from a file naming the live install, and its `plugin update` installs the source at the
# manifest's version when that differs from the live one, as the real CLI moves a bumped version into its cache.
CNVCI="$CNV/inst"; CNVCIH="$CNVCI/home"; CNVCIS="$CNVCI/src"; CNVCIB="$CNVCI/bin"; CNVCIC="$CNVCIH/.claude/plugins/cache/felix/felix"
mkdir -p "$CNVCIC/0.49.9/.claude-plugin" "$CNVCIS/engine/.claude-plugin" "$CNVCIS/.claude-plugin" "$CNVCIB"
_copy_content "$REAL_HARNESS" "$CNVCIS/engine/harness"
cp -R "$CNVCIS/engine/harness" "$CNVCIC/0.49.9/harness"
printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$CNVCIS/engine/.claude-plugin/plugin.json"
cp "$CNVCIS/engine/.claude-plugin/plugin.json" "$CNVCIC/0.49.9/.claude-plugin/plugin.json"
printf '{\n  "name": "felix",\n  "plugins": [ { "name": "felix", "source": "./engine" } ]\n}\n' > "$CNVCIS/.claude-plugin/marketplace.json"
printf '%s' "$CNVCIC/0.49.9" > "$CNVCIB/live"
{ printf '#!/bin/bash\n'; printf 'CNVCIS=%q; CNVCIC=%q; L=%q\n' "$CNVCIS" "$CNVCIC" "$CNVCIB/live"
  cat <<'CNV_CLAUDE_STUB'
case "$*" in
  "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$(cat "$L")" ;;
  "plugin marketplace add "*) [ -f "$4/.claude-plugin/marketplace.json" ] || exit 1 ;;
  "plugin update felix@felix")
    v="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CNVCIS/engine/.claude-plugin/plugin.json" | head -1)"
    cur="$(cat "$L")"
    if [ -n "$v" ] && [ "$v" != "${cur##*/}" ]; then
      mkdir -p "$CNVCIC/$v" && cp -R "$CNVCIS/engine/." "$CNVCIC/$v/" && printf '%s' "$CNVCIC/$v" > "$L"
    fi ;;
esac
exit 0
CNV_CLAUDE_STUB
} > "$CNVCIB/claude"
chmod +x "$CNVCIB/claude"
_cnv_inst() { ( cd "${CNVCIS:?}" && env -u CLAUDE_PLUGIN_ROOT HOME="$CNVCIH" FELIX_HOME="$CNVCIS" PATH="$CNVCIB:$PATH" "$CNVCIS/engine/harness/felix" install "$@" 2>&1 ); }
_cnv_match() { LC_ALL=C awk 'index($0, "the installed engine matches this tree")' <<< "$1"; }
CNV_I1="$(_cnv_inst --no-bump)"
is "cnv A2 (C2): felix install whose first comparison finds the installed engine matching prints exactly one such line, [  checked    the installed engine matches this tree], and no verified line" \
   "[$(_cnv_match "$CNV_I1")] old=$(_cnv_in "$CNV_I1" '  verified   the installed engine')" \
   "[  checked    the installed engine matches this tree] old=no"
printf '\n# a line the deployed engine does not have\n' >> "$CNVCIS/engine/harness/lib/escape.sh"
CNV_I2="$(_cnv_inst)"
is "cnv A3 (C2): felix install that bumps to 0.49.10 and then finds the installed engine matching prints the checked line, label column eleven wide, and no verified line" \
   "bumped=$(_cnv_in "$CNV_I2" '  bumped     0.49.10') [$(_cnv_match "$CNV_I2")] old=$(_cnv_in "$CNV_I2" '  verified   the installed engine')" \
   "bumped=yes [  checked    the installed engine matches this tree] old=no"
printf '\n# and another the deployed engine does not have\n' >> "$CNVCIS/engine/harness/lib/escape.sh"
CNV_I3="$(_cnv_inst --no-bump)"
is "cnv A4 (C2, control): felix install where the installed engine does not match and bumping is declined prints the warning and neither the checked nor the verified line" \
   "warn=$(_cnv_in "$CNV_I3" 'WARNING  the installed engine does NOT match this tree') [$(_cnv_match "$CNV_I3")] checked=$(_cnv_in "$CNV_I3" '  checked    ') verified=$(_cnv_in "$CNV_I3" '  verified   ')" \
   "warn=yes [] checked=no verified=no"

# ---- C3: felix merge, a moved checkout (text: the race is out of a fixture's reach) ----------------------------------
CNV_FX="$REAL_HARNESS/felix"
is "cnv A5 (C3): harness/felix holds the moved-checkout lines [The checkout moved while this ran, so what was checked is not what] and [would be merged. Nothing was merged.], and not [so what was verified is not what]" \
   "first=$(_cnv_yn "$(_cnv_cnt "$CNV_FX" 'The checkout moved while this ran, so what was checked is not what')") second=$(_cnv_yn "$(_cnv_cnt "$CNV_FX" 'would be merged. Nothing was merged.')") old=$(_cnv_yn "$(_cnv_cnt "$CNV_FX" 'so what was verified is not what')")" \
   "first=yes second=yes old=no"

# ---- C4, C5: felix classify, a green tier ---------------------------------------------------------------------------
CNVCK4="$CNV/k4"; _cnv_repo "$CNVCK4" cp; printf 'notes\n' > "$CNVCK4/README.md"; _cnv_commit "$CNVCK4" docs
CNVCK5="$CNV/k5"; _cnv_repo "$CNVCK5" ce; mkdir -p "$CNVCK5/src/safe"; printf 'x\n' > "$CNVCK5/src/safe/x.js"; _cnv_commit "$CNVCK5" safe
CNV_K4="$(_cnv_cli "$CNVCK4" classify --base HEAD~1)"
is "cnv A6 (C4): felix classify on a green tier that owes no evidence prints [Reversible, and no evidence is owed. Eligible for auto-merge once] and [every required check passes.], and not nothing is unproven" \
   "tier=$(_cnv_in "$CNV_K4" 'tier:  green') first=$(_cnv_hasl "$CNV_K4" 'Reversible, and no evidence is owed. Eligible for auto-merge once') second=$(_cnv_hasl "$CNV_K4" 'every required check passes.') old=$(_cnv_in "$CNV_K4" 'unproven')" \
   "tier=yes first=yes second=yes old=no"
CNV_K5="$(_cnv_cli "$CNVCK5" classify --base HEAD~1)"
is "cnv A7 (C5): felix classify on a green tier that owes evidence prints [Reversible, but <why>. Not auto-merge eligible: a green], [tier means no risky path was touched, not that the change was tested.] and [Run felix evidence.], and not proven" \
   "tier=$(_cnv_in "$CNV_K5" 'tier:  green') first=$(_cnv_yn "$(LC_ALL=C awk 'index($0, "Reversible, but ") == 1 && substr($0, length($0) - 33) == ". Not auto-merge eligible: a green" { n++ } END { print n + 0 }' <<< "$CNV_K5")") second=$(_cnv_hasl "$CNV_K5" 'tier means no risky path was touched, not that the change was tested.') third=$(_cnv_hasl "$CNV_K5" 'Run felix evidence.') old=$(_cnv_in "$CNV_K5" 'proven')" \
   "tier=yes first=yes second=yes third=yes old=no"

# ---- C6: the Stop hook's reason for a checkout with no gate receipt ----------------------------------------------------
CNVCR="$CNV/repo"; _cnv_repo "$CNVCR" cp; CNVCR="$(cd "$CNVCR" && pwd -P)"; printf 'one more line\n' >> "$CNVCR/WORK.txt"
CNV_T="$(_cnv_lib felix_tree_id "$CNVCR" "$CNVCH" 2>/dev/null)"
_cnv_stop cnv-sess-a1 false
CNV_A8="$(_cnv_sum)|$(_cnv_f 3)|$(_cnv_f 4)"; CNV_A9="$CNV_O"
is "cnv A8 (C6): the first hold on a checkout with no gate receipt writes a blocked row whose reason is never checked, and records exactly <tid>\\tnever checked\\t<checkout> in state/held-tree/<sid>" \
   "$CNV_A8|$(cat "$CNVCH/state/held-tree/cnv-sess-a1" 2>/dev/null)" \
   "block:0:1:blocked|$CNV_T|never checked|$(printf '%s\t%s\t%s' "$CNV_T" 'never checked' "$CNVCR")"
is "cnv A9 (C6, control): that hold's text is unchanged: The gate has never run in this checkout. and do not describe this work as complete" \
   "never=$(_cnv_in "$CNV_A9" 'The gate has never run in this checkout.') complete=$(_cnv_in "$CNV_A9" 'Do not describe this work as complete until it has passed.')" \
   "never=yes complete=yes"
_cnv_stop cnv-sess-a1 true; _cnv_stop cnv-sess-a1 false
is "cnv A10 (C6): the same session's next unflagged stop on that tree is a debt row whose reason is exactly [never checked; held once on this tree already (session cnv-sess)]" \
   "$(_cnv_sum)|$(_cnv_f 4)" "silent:0:1:debt|never checked; held once on this tree already (session cnv-sess)"
# The night: granted to one session, which then stops flagged with a tool call in its transcript, so the hold is charged.
CNV_TX="$CNV/transcript.jsonl"
printf '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash"}]}}\n' > "$CNV_TX"
( export FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU"; . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/overnight.sh"
  felix_overnight_start "$CNV_CP" 8 12 cnv-night-1 "the cnv part's night" ) >/dev/null 2>&1
CNV_NLOG="$( export FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU"; . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/overnight.sh"
             _felix_overnight_log "$CNV_CP" 2>/dev/null )"
_cnv_run "$CNVCH/harness/hooks/stop" "$CNVCR" "$(_cnv_pay cnv-night-1 true "$CNV_TX")"
CNV_A11="$(_cnv_sum)|$(LC_ALL=C awk -F'\t' '$2 == "refused" { d = $3 } END { print d }' "$CNV_NLOG" 2>/dev/null)"
( export FELIX_HOME="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU"; . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/overnight.sh"
  felix_overnight_end "$CNV_CP" "the cnv part's night is over" cnv-night-1 ) >/dev/null 2>&1
is "cnv A11 (C6): a night's flagged stop on that checkout is held and charged, and the night log's refused row says gate never checked" \
   "${CNV_A11%%|*}|$(_cnv_in "$CNV_A11" 'gate never checked;')|$(_cnv_in "$CNV_A11" 'never verified')" \
   "block:0:1:blocked|yes|no"
_cnv_stop cnv-cloud-1 false CLAUDE_CODE_REMOTE=true; _cnv_stop cnv-cloud-1 true CLAUDE_CODE_REMOTE=true
_cnv_stop cnv-cloud-1 false CLAUDE_CODE_REMOTE=true
CNV_CLOUD="$CNV_O"
is "cnv A12 (C6): a cloud session's debt stop prints its message (no decision), writes the debt row with never checked, and the message carries (never checked), not (never verified)" \
   "$(_cnv_sum)|$(_cnv_f 4)|decision=$(_cnv_in "$CNV_CLOUD" '"decision"') new=$(_cnv_in "$CNV_CLOUD" 'not passed on this tree (never checked).') old=$(_cnv_in "$CNV_CLOUD" '(never verified)')" \
   "other:0:1:debt|never checked; held once on this tree already (session cnv-clou)|decision=no new=yes old=no"

# ---- C7: a hold recorded under the old word is the same hold ----------------------------------------------------------
CNV_TX7="1111111111111111111111111111111111111111"; CNV_CO7="/cnv/checkout"
_cnv_seen() {   # RECORD-LINE REASON CHECKOUT -> the status of felix_hold_tree_seen over a record holding that one line
  mkdir -p "$CNV/fh/state/held-tree"; printf '%s\n' "$1" > "$CNV/fh/state/held-tree/cnv-seen"
  ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/verify.sh"
    felix_hold_tree_seen "$CNV/fh" cnv-seen "$CNV_TX7" "$2" "$3" ) >/dev/null 2>&1
  printf '%s' "$?"
}
_cnv_l7() { printf '%s\t%s\t%s' "$CNV_TX7" "$1" "${2:-$CNV_CO7}"; }
is "cnv A13 (C7): felix_hold_tree_seen HOME SID TID [never checked] CHECKOUT returns 0 when the record holds TID\\tnever verified\\tCHECKOUT" \
   "$(_cnv_seen "$(_cnv_l7 'never verified')" 'never checked' "$CNV_CO7")" "0"
is "cnv A14 (C7, control): it returns 0 for never checked over a never checked line, and every other reason only over its own exact line (never checked over another checkout 1, failed over never verified 1, failed over never checked 1, failed over failed 0, never verified over never checked 1)" \
   "$(_cnv_seen "$(_cnv_l7 'never checked')" 'never checked' "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 'never verified' /cnv/other)" 'never checked' "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 'never verified')" failed "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 'never checked')" failed "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 failed)" failed "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 'never checked')" 'never verified' "$CNV_CO7")" \
   "0 1 1 1 0 1"
# Round 3, not blind (after the tests review): a match is a whole line, for the old reason's line as for the new one.
is "cnv A44 (C7, round 3, not blind): never checked is not seen over a record line that only holds the expected line inside it (old reason, new reason, the checkout extended, the tree id extended)" \
   "$(_cnv_seen "$(_cnv_l7 'never verified' /cnv/checkout-b)" 'never checked' "$CNV_CO7") $(_cnv_seen "$(_cnv_l7 'never checked' /cnv/checkout-b)" 'never checked' "$CNV_CO7") $(_cnv_seen "x$(_cnv_l7 'never verified')" 'never checked' "$CNV_CO7") $(_cnv_seen "x$(_cnv_l7 'never checked')" 'never checked' "$CNV_CO7")" \
   "1 1 1 1"
_cnv_seed cnv-oldv-1 "$CNV_T" 'never verified' "$CNVCR"; _cnv_stop cnv-oldv-1 false
is "cnv A15 (C7): through the hook, a session whose record holds <tid>\\tnever verified\\t<checkout> stops again on that tree with no gate receipt: let go, one debt row, reason never checked" \
   "$(_cnv_sum)|$(_cnv_f 3)|$(_cnv_f 4)" "silent:0:1:debt|$CNV_T|never checked; held once on this tree already (session cnv-oldv)"
_cnv_seed cnv-newc-1 "$CNV_T" 'never checked' "$CNVCR"; _cnv_stop cnv-newc-1 false
is "cnv A16 (C7): through the hook, a session whose record holds <tid>\\tnever checked\\t<checkout> is let go the same way, with one debt row" \
   "$(_cnv_sum)|$(_cnv_f 3)|$(_cnv_f 4)" "silent:0:1:debt|$CNV_T|never checked; held once on this tree already (session cnv-newc)"
_cnv_seed cnv-fail-1 "$CNV_T" failed "$CNVCR"; _cnv_stop cnv-fail-1 false; CNV_A17="$(_cnv_sum)"
_cnv_seed cnv-stal-1 "$CNV_T" 'stale receipt' "$CNVCR"; _cnv_stop cnv-stal-1 false; CNV_A17="$CNV_A17 $(_cnv_sum)"
_cnv_seed cnv-else-1 "$CNV_T" 'never verified' "$CNV/elsewhere"; _cnv_stop cnv-else-1 false; CNV_A17="$CNV_A17 $(_cnv_sum)"
is "cnv A17 (C7, control): a record of that tree and checkout with the reason failed, or stale receipt, still holds, and so does a never verified record of another checkout" \
   "$CNV_A17" "block:0:1:blocked block:0:1:blocked block:0:1:blocked"

# ---- C8: felix receipt ------------------------------------------------------------------------------------------------
CNVCRC="$CNV/rc"; _cnv_repo "$CNVCRC" cp; CNVCRC="$(cd "$CNVCRC" && pwd -P)"
CNV_RB="$(git -C "$CNVCRC" rev-parse HEAD 2>/dev/null)"
printf 'notes\n' > "$CNVCRC/README.md"; _cnv_commit "$CNVCRC" docs
_cnv_lib felix_verify_record "$CNVCRC" "$CNVCH" 0 cnv-gate "$(_cnv_lib felix_tree_id "$CNVCRC" "$CNVCH" 2>/dev/null)" "" >/dev/null 2>&1
CNV_R1="$(_cnv_cli "$CNVCRC" receipt --base "$CNV_RB")"
printf 'edited after the gate\n' >> "$CNVCRC/README.md"
CNV_R2="$(_cnv_cli "$CNVCRC" receipt --base "$CNV_RB")"
rm -f "$(_cnv_lib _felix_receipt_path "$CNVCRC" "$CNVCH" 2>/dev/null)"
CNV_R3="$(_cnv_cli "$CNVCRC" receipt --base "$CNV_RB")"
CNV_R4="$(_cnv_cli "$CNVCRC" receipt --base deadbeefdeadbeefdeadbeefdeadbeefdeadbeef)"
is "cnv A18 (C8): felix receipt on a tree whose gate receipt is current and green, with no evidence gap, prints schema felix.receipt/2 and status checked" \
   "schema=$(_cnv_jf "$CNV_R1" schema) status=$(_cnv_jf "$CNV_R1" status) state=$(_cnv_jf "$CNV_R1" verification.state) result=$(_cnv_jf "$CNV_R1" verification.result) gap=$(_cnv_jf "$CNV_R1" evidence.gap)" \
   "schema=felix.receipt/2 status=checked state=current result=green gap=[]"
is "cnv A19 (C8): felix receipt says unchecked where the gate receipt is for another tree (stale) and where there is none" \
   "stale: schema=$(_cnv_jf "$CNV_R2" schema) status=$(_cnv_jf "$CNV_R2" status) state=$(_cnv_jf "$CNV_R2" verification.state); none: status=$(_cnv_jf "$CNV_R3" status) state=$(_cnv_jf "$CNV_R3" verification.state)" \
   "stale: schema=felix.receipt/2 status=unchecked state=stale; none: status=unchecked state=none"
is "cnv A20 (C8): none of the three receipts holds verified or unverified as a word, in its status, its keys or its limits, and each holds its new status" \
   "$(_cnv_vword "$CNV_R1") $(_cnv_vword "$CNV_R2") $(_cnv_vword "$CNV_R3") | $(_cnv_in "$CNV_R1" '"status": "checked"') $(_cnv_in "$CNV_R2" '"status": "unchecked"') $(_cnv_in "$CNV_R3" '"status": "unchecked"')" \
   "no no no | yes yes yes"
is "cnv A21 (C8, control): a receipt over a base that names nothing is still indeterminate, with what it could not read listed" \
   "status=$(_cnv_jf "$CNV_R4" status) known=$(_cnv_jf "$CNV_R4" changed.known) unknown=$(_cnv_in "$(_cnv_jf "$CNV_R4" unknown)" changed)" \
   "status=indeterminate known=false unknown=yes"

# ---- C9: the pulse's backup line after a push the remote reads back ---------------------------------------------------
_cnv_mem() {   # DIR -> a memory repository on main with one commit, then one change not yet committed
  mkdir -p "$1"
  ( _fx_cd "$1" && git init -q -b main && printf 'l\n' > l.md && git add -A \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm base ) >/dev/null 2>&1
  printf 'a new lesson\n' >> "$1/l.md"
}
_cnv_bk() {   # HOME REPO [NAME=value ...] -> CNV_BK, what felix_pulse_backup printed for REPO with FELIX_HOME_DIR=HOME
  local h="$1" m="$2"; shift 2
  mkdir -p "$h/state"
  CNV_BK="$(env -u CLAUDE_PLUGIN_ROOT -u GIT_SSH_COMMAND -u GIT_SSH HOME="$CNVCU" FELIX_HOME="$h" FELIX_HOME_DIR="$h" PATH="$CNV/bin:$PATH" "$@" \
            /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/pulse.sh" || exit 97; felix_pulse_backup "$2"' bk "$REAL_HARNESS" "$m" 2>/dev/null)"
}
_cnv_h12() { git -C "$1" rev-parse HEAD 2>/dev/null | cut -c1-12; }
_cnv_stamp() { if [ -s "$1/state/pulse.last-push" ]; then printf yes; else printf no; fi; }
printf '#!/bin/sh\nexit 0\n' > "$CNV/bin/claude"; chmod +x "$CNV/bin/claude"
# The ssh stand-in: no -G (so git takes it as a simple ssh), then the host, then the command it runs here.
cat > "$CNV/bin/cnv-ssh" <<'CNV_SSH_STUB'
#!/bin/sh
[ "$1" = -G ] && exit 1
shift
c="$1"
case "$c" in
  git-receive-pack*) c="git receive-pack${c#git-receive-pack}" ;;
  git-upload-pack*)  c="git upload-pack${c#git-upload-pack}" ;;
esac
exec /bin/sh -c "$c"
CNV_SSH_STUB
chmod +x "$CNV/bin/cnv-ssh"
( _fx_cd "$CNV" && git init -q --bare -b main r1.git && git init -q --bare -b main r2.git && git init -q --bare -b main r3.git \
  && git init -q --bare -b main r4f.git && git init -q --bare -b main r4p.git ) >/dev/null 2>&1
CNVCP1="$CNV/m1"; _cnv_mem "$CNVCP1"; _fx_git "$CNVCP1" remote add origin "$CNV/r1.git" >/dev/null 2>&1
_cnv_bk "$CNV/ph1" "$CNVCP1"; CNV_S1="$(_cnv_h12 "$CNVCP1")"
is "cnv A22 (C9): a push to a path that the remote reads back prints [backup\\tpushed and read back: origin holds <12 hex>; origin is a path on this machine, ...], not pushed and verified, and stamps the push" \
   "line=$(_cnv_hasl "$CNV_BK" "$(printf 'backup\tpushed and read back: origin holds %s; origin is a path on this machine, so this copy is only as far from this disk as whatever syncs that path' "$CNV_S1")") old=$(_cnv_in "$CNV_BK" 'pushed and verified') stamp=$(_cnv_stamp "$CNV/ph1")" \
   "line=yes old=no stamp=yes"
CNVCP2="$CNV/m2"; _cnv_mem "$CNVCP2"; _fx_git "$CNVCP2" remote add origin "ssh://example.invalid$CNV/r2.git" >/dev/null 2>&1
_cnv_bk "$CNV/ph2" "$CNVCP2" GIT_SSH_COMMAND="$CNV/bin/cnv-ssh"; CNV_S2="$(_cnv_h12 "$CNVCP2")"
is "cnv A23 (C9): a push to a network remote that it reads back prints exactly [backup\\tpushed and read back: origin holds <12 hex>], not pushed and verified, and stamps the push" \
   "line=$(_cnv_hasl "$CNV_BK" "$(printf 'backup\tpushed and read back: origin holds %s' "$CNV_S2")") old=$(_cnv_in "$CNV_BK" 'pushed and verified') stamp=$(_cnv_stamp "$CNV/ph2")" \
   "line=yes old=no stamp=yes"
CNVCP3="$CNV/m3"; _cnv_mem "$CNVCP3"; _fx_git "$CNVCP3" config protocol.ext.allow always >/dev/null 2>&1
_fx_git "$CNVCP3" remote add origin "ext::git %s $CNV/r3.git" >/dev/null 2>&1
_cnv_bk "$CNV/ph3" "$CNVCP3"; CNV_S3="$(_cnv_h12 "$CNVCP3")"
is "cnv A24 (C9): a push through a remote helper that it reads back prints [backup\\tpushed and read back: origin holds <12 hex>; where origin is could not be read], not pushed and verified, and stamps the push" \
   "line=$(_cnv_hasl "$CNV_BK" "$(printf 'backup\tpushed and read back: origin holds %s; where origin is could not be read' "$CNV_S3")") old=$(_cnv_in "$CNV_BK" 'pushed and verified') stamp=$(_cnv_stamp "$CNV/ph3")" \
   "line=yes old=no stamp=yes"
CNVCP4="$CNV/m4"; _cnv_mem "$CNVCP4"; _fx_git "$CNVCP4" remote add origin "$CNV/r4f.git" >/dev/null 2>&1
_fx_git "$CNVCP4" remote set-url --push origin "$CNV/r4p.git" >/dev/null 2>&1
_cnv_bk "$CNV/ph4" "$CNVCP4"
is "cnv A25 (C9, control): a push the remote does not read back still prints backup\\tpushed, but origin reads back ..., no read-back or verified line, and no stamp" \
   "but=$(_cnv_in "$CNV_BK" "$(printf 'backup\tpushed, but origin reads back ')") success=$(_cnv_in "$CNV_BK" 'pushed and read back:')$(_cnv_in "$CNV_BK" 'pushed and verified') stamp=$(_cnv_stamp "$CNV/ph4")" \
   "but=yes success=nono stamp=no"

# ---- C10: the notifier ------------------------------------------------------------------------------------------------
_cnv_fn() { ( . "$REAL_HARNESS/lib/resolve.sh"; . "$REAL_HARNESS/lib/notify.sh"; _fn_sentence "$1"; printf '|%s' "$?" ) 2>/dev/null; }
is "cnv A26 (C10): _fn_sentence deployed prints exactly [The engine on main was installed and passed its deploy checks.]" \
   "$(_cnv_fn deployed)" "The engine on main was installed and passed its deploy checks.|0"
is "cnv A27 (C10): _fn_sentence deployed-unverified prints exactly [A deploy of main stopped at a failed step or check, and landing is paused.]" \
   "$(_cnv_fn deployed-unverified)" "A deploy of main stopped at a failed step or check, and landing is paused.|0"
is "cnv A28 (C10, control): every other kind's sentence is unchanged: landed, deploy-owed and paused, and a kind with none is status 1" \
   "$(_cnv_fn landed) $(_cnv_fn deploy-owed) $(_cnv_fn paused) $(_cnv_fn no-such-kind)" \
   "A green pull request was merged into main.|0 A deploy of main is owed and has not run, so nothing lands.|0 Landing is paused until felix land --resume.|0 |1"

# ---- C11-C14, C17: text -----------------------------------------------------------------------------------------------
CNV_GT="$REAL_HARNESS/lib/green-tick.sh"
is "cnv A29 (C11, round 3): lib/green-tick.sh gives the deploy-owed reason [the home checkout is not at origin/main, so main's engine has not been deployed from it and checked], and neither the verified wording nor round 1's" \
   "new=$(_cnv_yn "$(_cnv_cnt "$CNV_GT" "the home checkout is not at origin/main, so main's engine has not been deployed from it and checked")") old=$(_cnv_yn "$(_cnv_cnt "$CNV_GT" 'has not been deployed and verified')") r1=$(_cnv_yn "$(_cnv_cnt "$CNV_GT" 'the engine it holds has not been deployed')")" \
   "new=yes old=no r1=no"
CNV_UA="$REAL_HARNESS/templates/unattended.yml"
is "cnv A30 (C12): templates/unattended.yml commits with the subject [fix: unattended repair, checked by the gate], and nothing says verified by the gate" \
   "new=$(_cnv_eqn "$CNV_UA" 'git commit -qam "fix: unattended repair, checked by the gate') old=$(_cnv_cnt "$CNV_UA" 'verified by the gate')" \
   "new=1 old=0"
is "cnv A31 (C12, control): the commit's body is unchanged" \
   "$(_cnv_eqn "$CNV_UA" 'Produced by the unattended loop. Pushed only because it changed no') $(_cnv_eqn "$CNV_UA" 'diff red, and the gate went green on it. Scope was checked before')" "1 1"
is "cnv A32 (C13): templates/moments.tsv holds the row [pre-conclude\\tbefore work is called done: what was checked, recorded, and handed over], and not the verified one" \
   "new=$(_cnv_eqn "$REAL_HARNESS/templates/moments.tsv" "$(printf 'pre-conclude\tbefore work is called done: what was checked, recorded, and handed over')") old=$(_cnv_cnt "$REAL_HARNESS/templates/moments.tsv" 'what was verified, recorded')" \
   "new=1 old=0"
is "cnv A33 (C14): templates/lifecycle.tsv holds the row [Stop\\twired\\trefuse completion on a tree the gate has not passed, then ask that the claims be checked], and not the unverified one" \
   "new=$(_cnv_eqn "$REAL_HARNESS/templates/lifecycle.tsv" "$(printf 'Stop\twired\trefuse completion on a tree the gate has not passed, then ask that the claims be checked')") old=$(_cnv_cnt "$REAL_HARNESS/templates/lifecycle.tsv" 'refuse completion on an unverified tree')" \
   "new=1 old=0"

# ---- C15: the cloud debt message --------------------------------------------------------------------------------------
CNV_DEBT='This cloud session was let go with the gate not passed on this tree (never checked). Felix held it once and the gate did not run. The record of that sits in this session'"'"'s memory, which ends with the VM, so nothing outside it says the gate has not passed on this work. Run the gate before the VM goes, or open a pull request so CI judges the branch.'
_cnv_debt() {   # [NAME=value ...] -> what felix_stop_debt cp "never checked" cnv-debt-1 printed
  ( cd "${CNV:?}/plain" && env -u CLAUDE_CODE_REMOTE FELIX_HOME="$CNVCH" FELIX_HOME_DIR="$CNVCH" FELIX_MEMORY="$CNVCM" HOME="$CNVCU" "$@" /bin/bash -c '
      . "$1/lib/resolve.sh"; . "$1/lib/verify.sh"; . "$1/lib/hook-faults.sh"; . "$1/lib/say.sh"
      felix_stop_debt "$2" "never checked" cnv-debt-1' dt "$REAL_HARNESS" "$CNV_CP" 2>/dev/null )
}
CNV_D1="$(_cnv_debt CLAUDE_CODE_REMOTE=true)"
is "cnv A34 (C15, round 3): felix_stop_debt with CLAUDE_CODE_REMOTE=true ends its third sentence [so nothing outside it says the gate has not passed on this work.], the rest unchanged, and says neither went unverified nor went unchecked" \
   "new=$(_cnv_in "$CNV_D1" "$CNV_DEBT") old=$(_cnv_in "$CNV_D1" 'went unverified') r1=$(_cnv_in "$CNV_D1" 'went unchecked')" "new=yes old=no r1=no"
is "cnv A35 (C15): the Stop hook's debt stop of a cloud session carries that message, its reason (never checked) in parentheses" \
   "new=$(_cnv_in "$CNV_CLOUD" "$CNV_DEBT") old=$(_cnv_in "$CNV_CLOUD" 'went unverified') r1=$(_cnv_in "$CNV_CLOUD" 'went unchecked')" "new=yes old=no r1=no"
is "cnv A36 (C15, control): felix_stop_debt without CLAUDE_CODE_REMOTE=true prints nothing" "[$(_cnv_debt)]" "[]"

# ---- C16: the SubagentStop message ------------------------------------------------------------------------------------
_cnv_run "$CNVCH/harness/hooks/subagent-stop" "$CNVCR" '{"hook_event_name":"SubagentStop","session_id":"cnv-sub-1","stop_hook_active":false}'
is "cnv A37 (C16, round 3): the SubagentStop hook on a checkout holding work no gate has passed says [must say so plainly: partial, failing, or unchecked — not done, working, or passing.], and neither partial, or unverified nor round 1's partial, or unchecked" \
   "rc=$CNV_RC new=$(_cnv_in "$CNV_O" 'must say so plainly: partial, failing, or unchecked — not done, working, or passing.') old=$(_cnv_in "$CNV_O" 'partial, or unverified') r1=$(_cnv_in "$CNV_O" 'partial, or unchecked')" \
   "rc=0 new=yes old=no r1=no"

# ---- C17: the /felix command ------------------------------------------------------------------------------------------
is "cnv A38 (C17): engine/commands/felix.md ends [this is a tool whose entire value is that it refuses to report success it has] / [not checked.]" \
   "$(LC_ALL=C awk 'NF { a = b; b = $0 } END { printf "%s / %s", a, b }' "$REAL_HARNESS/../commands/felix.md" 2>/dev/null)" \
   "this is a tool whose entire value is that it refuses to report success it has / not checked."

# ---- C18: the class, not the instance ---------------------------------------------------------------------------------
mkdir -p "$CNV/c18a/b" "$CNV/c18b"
printf '%s\n' "printf 'Verified by the gate\\n'" > "$CNV/c18a/a.sh"
printf '%s\n' 'ok' 'the claim stays unproven' > "$CNV/c18a/b/c.txt"
CNV_C1="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18a")"; CNV_C1R=$?
is "cnv A39 (C18): the check over a fixture holding a printed line with Verified and a line with unproven fails and names those two lines" \
   "rc=$CNV_C1R [$CNV_C1]" "rc=1 [a.sh:1:printf 'Verified by the gate\\n'
b/c.txt:2:the claim stays unproven]"
# Round 3, not blind: each allowed name sits in a file that may hold it, since no name is allowed everywhere.
mkdir -p "$CNV/c18b/harness/hooks" "$CNV/c18b/harness/lib"
printf '%s\n' '# Verified, and unproven: a comment' "	  # an indented comment says verified too" > "$CNV/c18b/x.sh"
printf '%s\n' 'mkdir -p "$H/state/verified"' > "$CNV/c18b/harness/hooks/stop"
printf '%s\n' 'felix_say p subagent-unverified body' > "$CNV/c18b/harness/hooks/subagent-stop"
printf '%s\n' "    deploy-failed|deployed-unverified) printf '%s' 'A deploy stopped at a failed step' ;;" > "$CNV/c18b/harness/lib/notify.sh"
printf '%s\n' '{ if ($1 == "not-green" || $1 == "unverified") h = 1 }' > "$CNV/c18b/harness/lib/green-install.sh"
printf '%s\n' 'case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac' > "$CNV/c18b/harness/lib/green-tick.sh"
CNV_C2="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18b")"; CNV_C2R=$?
is "cnv A40 (C18): the check over a fixture holding only # comments with the words and a line with each allowed name, each in a file that may hold it, passes" \
   "rc=$CNV_C2R [$CNV_C2]" "rc=0 []"
mkdir -p "$CNV/c18c/harness/lib"
printf '%s\n' 'grep -Fxq -e "$3	never checked	${5:-}" -e "$3	never verified	${5:-}" "$path"' 'printf "never verified\n"' > "$CNV/c18c/harness/lib/verify.sh"
printf '%s\n' 'echo "never verified"' > "$CNV/c18c/harness/lib/other.sh"
CNV_C6="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18c")"; CNV_C6R=$?
is "cnv A43 (C18, rounds 2 and 3, not blind): the old hold reason is allowed only as the pattern lib/verify.sh greps for, there and nowhere else" \
   "rc=$CNV_C6R [$CNV_C6]" "rc=1 [harness/lib/other.sh:1:echo \"never verified\"
harness/lib/verify.sh:2:printf \"never verified\\n\"]"
# One line for each allowed text, in a file none may be in: widening any one name to every file drops its line.
mkdir -p "$CNV/c18d/harness/lib"
printf '%s\n' "case \"\$k\" in deployed-unverified) echo not-checked ;; esac" 'echo "state/verified: the tree passed"' \
  'felix_say p subagent-unverified body' '{ if ($1 == "unverified") h = 1 }' \
  'case "$b" in "  not-green   "*) old="  unverified  ${b#"  not-green   "}" ;; esac' \
  "$(printf -- 'grep -Fxq -e "$3\tnever verified\t${5:-}" "$path"')" > "$CNV/c18d/harness/lib/other.sh"
printf '%s\n' "    deploy-failed|deployed-unverified) printf '%s' 'A deploy stopped at a failed step' ;;" > "$CNV/c18d/harness/lib/notify.sh"
CNV_C7="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18d")"; CNV_C7R=$?
CNV_C7W="$(LC_ALL=C awk '{ printf "harness/lib/other.sh:%d:%s\n", NR, $0 }' "$CNV/c18d/harness/lib/other.sh")"
is "cnv A45 (C18, round 3, not blind): each allowed text outside the files that may hold it fails, all six of them, and the one inside its file passes" \
   "rc=$CNV_C7R lines=$(printf '%s\n' "$CNV_C7" | LC_ALL=C awk 'NF { n++ } END { print n + 0 }') same=$([ "$CNV_C7" = "$CNV_C7W" ] && printf yes || printf no)" \
   "rc=1 lines=6 same=yes"
# Round 4, not blind (K12 of the not-green / deploy-failed contract): the four entries that were removed, each in the file that
# used to allow it, now fail; the narrow form that replaced two of them, in the same file, passes.
mkdir -p "$CNV/c18h/harness/lib"
printf '%s\n' 'kind=deployed-unverified' > "$CNV/c18h/harness/lib/green-tick.sh"
printf '%s\n' "printf 'unverified\\ttree\\t%s\\n' x" > "$CNV/c18h/harness/lib/escape.sh"
printf '%s\n' 'kind=deployed-unverified' > "$CNV/c18h/harness/lib/notify.sh"
printf '%s\n' '[ "$1" == "unverified" ] && exit 0' > "$CNV/c18h/harness/lib/green-install.sh"
CNV_C11="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18h")"; CNV_C11R=$?
is "cnv A49 (C18, round 4, not blind): the old ledger kind in green-tick.sh and notify.sh, the old blocker kind's printf in escape.sh and the wide clause in green-install.sh each fail now, in the file that used to allow them" \
   "rc=$CNV_C11R lines=$(printf '%s\n' "$CNV_C11" | LC_ALL=C awk 'NF { n++ } END { print n + 0 }') files=$(printf '%s\n' "$CNV_C11" | LC_ALL=C cut -d: -f1 | LC_ALL=C tr '\n' ' ')" \
   "rc=1 lines=4 files=harness/lib/escape.sh harness/lib/green-install.sh harness/lib/green-tick.sh harness/lib/notify.sh "
# Round 5, not blind (review round 2): the quiet check's entry is that one line, not the text anywhere in the file.
mkdir -p "$CNV/c18i/harness/lib"
printf '%s\n' 'x="  unverified  y"' > "$CNV/c18i/harness/lib/green-tick.sh"
CNV_C12="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18i")"; CNV_C12R=$?
is "cnv A49b (C18, round 5, not blind): the old name between two blanks on another line of green-tick.sh fails; only the quiet check's own line is allowed" \
   "rc=$CNV_C12R [$CNV_C12]" "rc=1 [harness/lib/green-tick.sh:1:x=\"  unverified  y\"]"
mkdir -p "$CNV/c18e"
printf '%s\n' "printf 'it decides how work gets built, and Proves it\\n'" "printf 'what a fix must prove\\n'" \
  "printf 'with nothing proving it\\n'" 'git rev-parse --verify -q HEAD' "printf 'improves, approves, provenance\\n'" > "$CNV/c18e/p.sh"
CNV_C8="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18e")"; CNV_C8R=$?
is "cnv A46 (C18, round 3, not blind): proves fails, and prove, proving, verify and words that only hold the letters pass" \
   "rc=$CNV_C8R [$CNV_C8]" "rc=1 [p.sh:1:printf 'it decides how work gets built, and Proves it\\n']"
mkdir -p "$CNV/c18f"
printf '%s\n' '## Every command here is verified' '# Usage' > "$CNV/c18f/README.md"
printf '%s\n' '## a shell comment that says verified' > "$CNV/c18f/s.sh"
CNV_C9="$(GIT_CEILING_DIRECTORIES="$CNV" _cnv_check "$CNV/c18f")"; CNV_C9R=$?
is "cnv A47 (C18, round 3, not blind): a Markdown heading is read, since a person reads it, and a shell # line is not" \
   "rc=$CNV_C9R [$CNV_C9]" "rc=1 [README.md:1:## Every command here is verified]"
CNV_G="$CNV/c18g"; mkdir -p "$CNV_G/harness/tests" "$CNV_G/lib"
printf '%s\n' "printf 'verified\\n'" > "$CNV_G/harness/tests/t.sh"; printf 'echo fine\n' > "$CNV_G/lib/b.sh"
( _fx_cd "$CNV_G" && git init -q -b main && git add harness/tests/t.sh lib/b.sh ) >/dev/null 2>&1
printf 'echo unproven\n' > "$CNV_G/lib/a.sh"
CNV_C3="$(_cnv_check "$CNV_G")"; CNV_C3R=$?
_fx_git "$CNV_G" add lib/a.sh >/dev/null 2>&1
CNV_C4="$(_cnv_check "$CNV_G")"; CNV_C4R=$?
is "cnv A41 (C18): inside a git work tree the check reads only tracked files and skips harness/tests/: an untracked line passes, then fails once tracked" \
   "before rc=$CNV_C3R [$CNV_C3] after rc=$CNV_C4R [$CNV_C4]" "before rc=0 [] after rc=1 [lib/a.sh:1:echo unproven]"
# Round 3, not blind (the last review round): a directory inside a work tree that git tracks nothing of, as a plugin
# cache under a home kept in git is, is read whole; asking only whether it is inside a work tree read nothing (rc 2).
CNV_U="$CNV/c18u"; mkdir -p "$CNV_U/sub"; printf 'echo fine\n' > "$CNV_U/top.sh"
( _fx_cd "$CNV_U" && git init -q -b main && git add top.sh ) >/dev/null 2>&1
printf '%s\n' "printf 'it proves it\\n'" > "$CNV_U/sub/p.sh"
CNV_C10="$(_cnv_check "$CNV_U/sub")"; CNV_C10R=$?
is "cnv A48 (C18, round 3, not blind): a directory inside a work tree that git tracks nothing of is read whole, and its line is named" \
   "rc=$CNV_C10R [$CNV_C10]" "rc=1 [p.sh:1:printf 'it proves it\\n']"
CNV_ENG="$(cd "$REAL_HARNESS/.." && pwd -P)"
CNV_C5="$(_cnv_check "$CNV_ENG")"; CNV_C5R=$?; CNV_C5N="$(_cnv_list "$CNV_ENG" | LC_ALL=C awk 'END { print NR + 0 }')"
is "cnv A42 (C18): the check over the engine under test (the parent of REAL_HARNESS, harness/tests/ aside, tracked files when in a work tree) reads many files and names no line" \
   "files=$([ "${CNV_C5N:-0}" -ge 50 ] && printf many || printf '%s' "$CNV_C5N") rc=$CNV_C5R [$CNV_C5]" "files=many rc=0 []"

# ---- the restore ----
for _cnv_v in $(compgen -v | LC_ALL=C grep -E '^CNV[A-Z0-9_]*$'); do unset "$_cnv_v"; done
for _cnv_v in $(compgen -A function | LC_ALL=C grep -E '^_cnv_'); do unset -f "$_cnv_v"; done
unset _cnv_v
# <<< checked-not-verified

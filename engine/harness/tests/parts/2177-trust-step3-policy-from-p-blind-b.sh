# >>> trust-step3-policy-from-p-b
printf '\ntrust plane step 3, slice 1, continued: S2.1, S3, S4, the workflows control, S1.8 for a product, and S1.5 (spec section 2; blind)\n'
# Blind, as part 2176 is, and its continuation: cut from it on 2026-11-07 when it passed 550 lines. It runs after 2176 in
# the same shell (group ts3 in tests/groups.tsv, so tests/run -j N keeps the two in one process, and --part takes both),
# uses 2176's fixture R, its entry, its helpers and its readings, and removes what 2176 built at its end. Not read, as
# for 2176: engine/harness/felix, lib/*.sh, hooks, bin, projects/*/gate.sh, any lib/policy.sh.
#
# Readings, where the spec leaves room (the rest are 2176's):
# - S2.1's cases each have a P of their own, a commit off main adding tools/run.sh (parses) and tools/marker.txt
#   (present) and the one contract the case names, with origin/main moved to it and the receipts read against an
#   archive of its projects/ts3, so that one case's fail-closed refusal (S2.1's "the merge refuses") is not another's.
#   The quoted, wrapper and group cases' P replaces the fx row's contract with the case's; the others add a row (run,
#   mark, subst, show). "A policy line naming X" is a blocker line of kind policy holding X; that nothing else is judged
#   is not asserted. On main the option and placeholder cases are refused for their obligation (the candidate's file is
#   read) and print no policy line, and the quoted case passes: all three red.
# - The wrapper and group cases use the quoted case's candidate, as the spec says: tools/check-fx rewritten to exit 0 and
#   MARKER deleted. The wrapper is nice, not timeout, which macOS lacks (the spec's correction). On main the candidate's
#   checker runs in both, so the dry run passes: red. The interpreter-as-an-argument and standard-input cases use the
#   same candidate and are red on main the same way. Over P's own tree the standard-input contract does not exit 0:
#   section 2's tools/check-fx sources lib.sh beside $0, and $0 is bash when bash reads the script from standard input,
#   so ./lib.sh is not found and fx_check is not a command (127). The fixture control records that; it does not change
#   what the case asks, a policy line, and on main the candidate's checker (exit 0) is what runs.
# - The substitution and path-read cases are controls for false blocks; each candidate only adds NOTES.md, and both pass
#   on main. The path-read row is show, its contract reading HEAD:tools/check-fx through git show in a quoted substitution.
# - S1.8's product cases: the product Q at $TS3/prod is main's tools, MARKER, PROBE.txt, .gitignore and gate workflow
#   with .felix naming ts3p and no engine/, origin github.com/example/ts3p and origin/main at its main. Its home HR at
#   $TS3/phome is a repository of its own (no remote; refs/remotes/origin/main set to its one commit) holding
#   projects/ts3p, P's tables with project.json's name and remote_match renamed, and memory $MEM/ts3p. Each candidate
#   is a branch checked out in Q; FELIX_HOME is HR, and the receipts are recorded with HR as it stands, its projects/ts3p
#   (the link, or the loosened working tree) as the project directory, as S1.8's first case does, so on main the
#   loosened row is read and the dry run passes: red. After the change those receipts may read stale beside the
#   refusal; only the refusal and the obligations line for fx are held. The planted repository is `git init` in
#   HR/projects, its one commit holding ts3p loosened, with its own refs/remotes/origin/main at it.
is  "trust-step3: (fixture control, part 2177): part 2176 ran first in this shell, so R is its repository under the suite's temporary directory and origin/main is main's commit" \
    "$(case "${TS3R:-}" in ("$(cd "$TMP" && pwd -P)/ts3/repo") echo here ;; (*) echo "not 2176's [${TS3R:-}]" ;; esac)|$(_fx_git "${TS3R:-$TMP/no-ts3}" rev-parse -q --verify refs/remotes/origin/main 2>/dev/null)" \
    "here|${TS3_M:-unset}"

# ------------------------------------------------------------------- S2.1 ---
_ts3_p2_begin() {   # BRANCH: R on a new branch off main, with tools/run.sh (parses) and tools/marker.txt (present)
  ( _fx_cd "$TS3R" && git checkout -q -f -B "$1" main ) >/dev/null 2>&1
  printf '#!/usr/bin/env bash\nprintf '"'"'run\\n'"'"'\n' > "$TS3R/tools/run.sh"; printf 'present\n' > "$TS3R/tools/marker.txt"
}
_ts3_p2_end() {   # OBLIGATION [LABEL]: commit; TS3_PX the commit, origin/main moved to it, TS3_RP its tables' archive, and
                  # the obligation's contract run over P's tree as the table holds it onto TS3_FX21 as LABEL:rc
  local c
  _ts3_commit "$TS3R" "p-${2:-$1}"; TS3_PX="$(_jr_sha "$TS3R" HEAD)"
  _fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_PX" >/dev/null 2>&1
  rm -rf "${TS3:?}/px"; mkdir -p "$TS3/px"
  _fx_git "$TS3R" archive -o "$TS3/px.tar" "$TS3_PX" projects/ts3 >/dev/null 2>&1 && tar -x -C "$TS3/px" -f "$TS3/px.tar"; rm -f "$TS3/px.tar"
  TS3_RP="$TS3/px/projects/ts3"
  c="$(LC_ALL=C awk -F'\t' -v o="$1" '$1 == o { print $5 }' "$TS3P/obligations.tsv")"
  TS3_FX21="$TS3_FX21 ${2:-$1}:$( cd "$TS3R" && bash -c "$c" >/dev/null 2>&1; printf '%s' "$?")"
}
_ts3_cand() { ( _fx_cd "$TS3R" && git checkout -q -f -B "$1" "$TS3_PX" ) >/dev/null 2>&1; }   # BRANCH: a candidate off P
_ts3_ob() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" RELEASE_BLOCKING deterministic - "$2" - "$3" >> "$TS3P/obligations.tsv"; }
_ts3_p2_fx() {   # LABEL CONTRACT: a P whose fx row's contract is CONTRACT, then the quoted case's candidate on ts3-LABEL
                 # (tools/check-fx rewritten to exit 0, MARKER deleted), judged from the entry; the row and the candidate's
                 # checker onto TS3_FX21. CONTRACT holds no backslash (awk -v would read one).
  _ts3_p2_begin "ts3-p-$1"
  LC_ALL=C awk -F'\t' -v OFS='\t' -v c="$2" '$1 == "fx" { $5 = c } { print }' "$TS3P/obligations.tsv" > "$TS3/ob.tmp" && cat "$TS3/ob.tmp" > "$TS3P/obligations.tsv"
  _ts3_p2_end fx "$1"
  _ts3_cand "ts3-$1"; printf '#!/usr/bin/env bash\nexit 0\n' > "$TS3R/tools/check-fx"; _fx_git "$TS3R" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3R" "$1"
  TS3_FX21="$TS3_FX21 $1-row:$(LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }' "$TS3P/obligations.tsv") $1-check:$( cd "$TS3R" && tools/check-fx >/dev/null 2>&1; printf '%s' "$?")$([ -e "$TS3R/MARKER" ] && echo ' MARKER' || echo ' no MARKER')"
  _ts3_entry "S2.1-$1"
}
_ts3_p2_ctl() {   # NAME CONTRACT REASON: a P adding row NAME, then a candidate on ts3-NAME that only adds NOTES.md, judged
  _ts3_p2_begin "ts3-p-$1"; _ts3_ob "$1" "$2" "$3"; _ts3_p2_end "$1"
  _ts3_cand "ts3-$1"; printf 'notes the candidate adds\n' > "$TS3R/NOTES.md"; _ts3_commit "$TS3R" "$1"
  _ts3_entry "S2.1-$1"
}
TS3_FX21=""

_ts3_p2_begin ts3-p-run; _ts3_ob run 'bash -n tools/run.sh' 'an option after an interpreter'; _ts3_p2_end run
_ts3_cand ts3-opt; printf 'if then\n' > "$TS3R/tools/run.sh"; _ts3_commit "$TS3R" opt
TS3_FX21="$TS3_FX21 opt-parses:$( cd "$TS3R" && bash -n tools/run.sh >/dev/null 2>&1 && echo yes || echo no)"
_ts3_entry S2.1-option
_ts3_check "trust-step3: S2.1 (an option after an interpreter): with P's contract bash -n tools/run.sh, a candidate whose tools/run.sh does not parse is refused with a policy line naming tools/run.sh" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/run.sh -)" "refused|yes" "$(_ts3_why)"

_ts3_p2_begin ts3-p-mark; _ts3_ob mark "printf '%s\\n' present | xargs -I{} grep -qxF {} tools/marker.txt" 'a placeholder'; _ts3_p2_end mark
_ts3_cand ts3-mark; printf 'gone\n' > "$TS3R/tools/marker.txt"; _ts3_commit "$TS3R" mark
TS3_FX21="$TS3_FX21 mark-reads:$(cat "$TS3R/tools/marker.txt" 2>&1)"
_ts3_entry S2.1-placeholder
_ts3_check "trust-step3: S2.1 (the rewrite stops at a placeholder): with P's contract piping into xargs -I{} grep over tools/marker.txt, a candidate whose tools/marker.txt reads gone is refused with a policy line naming tools/marker.txt" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/marker.txt -)" "refused|yes" "$(_ts3_why)"

_ts3_p2_fx quoted '"tools/check-fx"'
_ts3_check "trust-step3: S2.1 (a quoted instrument): with P's contract \"tools/check-fx\" quoted in command position, a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with a policy line naming tools/check-fx" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/check-fx -)" "refused|yes" "$(_ts3_why)"
_ts3_p2_fx wrapper 'nice tools/check-fx'
_ts3_check "trust-step3: S2.1 (a wrapper): with P's contract nice tools/check-fx, a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with a policy line naming tools/check-fx" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/check-fx -)" "refused|yes" "$(_ts3_why)"
_ts3_p2_fx group '{ tools/check-fx; }'
_ts3_check "trust-step3: S2.1 (a group): with P's contract { tools/check-fx; }, a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with a policy line naming tools/check-fx" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/check-fx -)" "refused|yes" "$(_ts3_why)"
_ts3_p2_fx argint 'f() { "$@"; }; f bash tools/check-fx'
_ts3_check "trust-step3: S2.1 (an interpreter as an argument): with P's contract defining a function f that runs its arguments and calling f bash tools/check-fx, a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with a policy line naming tools/check-fx" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/check-fx -)" "refused|yes" "$(_ts3_why)"
_ts3_p2_fx stdin 'cat tools/check-fx | bash'
_ts3_check "trust-step3: S2.1 (an interpreter reading standard input): with P's contract piping tools/check-fx into bash, a candidate that rewrites tools/check-fx to exit 0 and deletes MARKER is refused with a policy line naming tools/check-fx" \
  "$(_ts3_refused)|$(_ts3_bl policy - tools/check-fx -)" "refused|yes" "$(_ts3_why)"

_ts3_p2_ctl subst 'n="$(git ls-files tools | grep -cE "^(tools/lib.sh|tools/check-fx)$")"; [ "$n" = 2 ]' 'a substitution in quotes'
_ts3_check "trust-step3: S2.1 (the rewrite stops at a substitution in quotes, control): with P's contract counting tools/lib.sh and tools/check-fx inside a quoted command substitution, an unrelated candidate passes the dry run" \
  "$(_ts3_passed)" "passed" "$(_ts3_why)"
_ts3_p2_ctl show 'v="$(git show "HEAD:tools/check-fx" | head -1)"; [ -n "$v" ]' 'a path read inside a substitution'
_ts3_check "trust-step3: S2.1 (a path read inside a substitution, control): with P's contract reading HEAD:tools/check-fx through git show inside a quoted command substitution, an unrelated candidate passes the dry run" \
  "$(_ts3_passed)" "passed" "$(_ts3_why)"
_ts3_check "trust-step3: S2.1 (fixture control): on each case's own P its contract over P's tree as the table holds it exits 0, the standard-input one 127 (P's checker finds lib.sh from \$0, which is bash there); the option candidate's tools/run.sh does not parse, the placeholder candidate's tools/marker.txt reads gone, and the quoted, wrapper, group, argument and standard-input candidates' tools/check-fx exits 0 with MARKER gone" \
  "$TS3_FX21" " run:0 opt-parses:no mark:0 mark-reads:gone quoted:0 quoted-row:\"tools/check-fx\" quoted-check:0 no MARKER wrapper:0 wrapper-row:nice tools/check-fx wrapper-check:0 no MARKER group:0 group-row:{ tools/check-fx; } group-check:0 no MARKER argint:0 argint-row:f() { \"\$@\"; }; f bash tools/check-fx argint-check:0 no MARKER stdin:127 stdin-row:cat tools/check-fx | bash stdin-check:0 no MARKER subst:0 show:0"
TS3_RP=""
( _fx_cd "$TS3R" && git checkout -q -f main ) >/dev/null 2>&1
_fx_git "$TS3R" update-ref refs/remotes/origin/main "$TS3_M" >/dev/null 2>&1

# --------------------------------------------------------------------- S3 ---
_ts3_case ts3-comma
LC_ALL=C awk -F'\t' '!d && $1 == "green" { print $0 ","; d = 1; next } { print }' "$TS3P/risk.tsv" > "$TS3/risk.tmp" && cat "$TS3/risk.tmp" > "$TS3P/risk.tsv"
_ts3_commit "$TS3R" comma
_ts3_check "trust-step3: S3 (fixture control): the candidate's only change is a comma appended to the last cell of one risk.tsv row" \
  "$(git -C "$TS3R" diff --numstat main HEAD 2>&1 | tr '\t\n' '| ')|$(git -C "$TS3R" diff main HEAD 2>/dev/null | LC_ALL=C awk '/^\+[^+]/ { print substr($0, length($0)) }')" \
  "1|1|projects/ts3/risk.tsv |,"
_ts3_entry S3-comma
_ts3_check "trust-step3: S3: a comma appended to the last cell of an existing risk.tsv row is refused with an escape line for verifier naming risk.tsv" \
  "$(_ts3_refused)|$(_ts3_bl escape verifier risk.tsv -)" "refused|yes" "$(_ts3_why)"

_ts3_case ts3-jsonkey
LC_ALL=C awk '$0 == "  \"gate_workflow\": \"gate.yml\"" { print $0 ","; print "  \"note\": \"a key the candidate adds\""; next } { print }' \
  "$TS3P/project.json" > "$TS3/pj.tmp" && cat "$TS3/pj.tmp" > "$TS3P/project.json"
_ts3_commit "$TS3R" jsonkey
_ts3_entry S3-json
case "$(_ts3_passed)|$(_ts3_refused)" in passed\|*|*\|refused) _ts3_v=verdict ;; *) _ts3_v="no verdict, exit $TS3RC" ;; esac
_ts3_check "trust-step3: S3 (control): a candidate that adds one key to project.json, its previous last line gaining a comma, reaches a verdict with no escape line for verifier naming project.json" \
  "$_ts3_v|$(_ts3_bl escape verifier project.json -)" "verdict|no" "$(_ts3_why)"

# --------------------------------------------------------------------- S4 ---
_ts3_case ts3-s4; _fx_git "$TS3R" rm -q engine/.claude-plugin/plugin.json >/dev/null 2>&1
printf '\nfelix_escapes() { return 0; }\n' >> "$TS3R/engine/harness/lib/escape.sh"
printf 'on: push\njobs: {}\n' > "$TS3R/.github/workflows/x.yml"; _ts3_commit "$TS3R" s4
_ts3_check "trust-step3: S4 (fixture control): the candidate no longer tracks the manifest, BASE does, and the candidate's felix_escapes prints nothing" \
  "$(git -C "$TS3R" ls-files engine/.claude-plugin/plugin.json 2>&1)|$(git -C "$TS3R" cat-file -t refs/remotes/origin/main:engine/.claude-plugin/plugin.json 2>&1)|$( ( . "$TS3R/engine/harness/lib/escape.sh" >/dev/null 2>&1; felix_escapes "$TS3P" main "$TS3R" "$TS3R" 2>/dev/null ) | LC_ALL=C awk 'END { print NR }')" \
  "|blob|0"
_ts3_run S4-own "$TS3R" "$TS3R/engine/harness/felix"
_ts3_check "trust-step3: S4: a branch that deletes the manifest and disarms its own felix_escapes, run by its own felix, is still judged by main's engine: refused with an escape line for execute naming .github/workflows/x.yml" \
  "$(_ts3_refused)|$(_ts3_bl escape execute .github/workflows/x.yml -)" "refused|yes" "$(_ts3_why)"

# ---------------------------------------------------------- workflows, control ---
_ts3_case ts3-wf; printf '# the candidate edits the gate workflow\n' >> "$TS3R/.github/workflows/gate.yml"
printf 'green\tpath\t^\\.github/\tthe candidate calls its workflows harmless\n' >> "$TS3P/risk.tsv"; _ts3_commit "$TS3R" wf
_ts3_entry workflows
_ts3_check "trust-step3: workflows (control): a candidate that edits .github/workflows/gate.yml and only adds a table row is refused with an escape line for execute naming the workflow" \
  "$(_ts3_refused)|$(_ts3_bl escape execute .github/workflows/gate.yml -)" "refused|yes" "$(_ts3_why)"

# ------------------------------------------------- S1.8, a product's home ---
# Q, a product: main's tools, MARKER, PROBE.txt, .gitignore and gate workflow, .felix naming ts3p, no engine. HR, its
# home, a repository of its own: projects/ts3p is P's tables renamed, committed, with origin/main at that commit.
TS3Q="$TS3/prod"; TS3HR="$TS3/phome"; TS3HP="$TS3/phome/projects/ts3p"; mkdir -p "$TS3Q" "$TS3HR/projects" "$MEM/ts3p"
( _fx_cd "$TS3Q" && git init -q -b main && git remote add origin https://github.com/example/ts3p.git \
  && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
_fx_git "$TS3R" archive -o "$TS3/q.tar" "$TS3_M" tools MARKER PROBE.txt .gitignore .github >/dev/null 2>&1 && tar -x -C "$TS3Q" -f "$TS3/q.tar"; rm -f "$TS3/q.tar"
printf 'ts3p\n' > "$TS3Q/.felix"; _ts3_commit "$TS3Q" base; TS3_QM="$(_jr_sha "$TS3Q" HEAD)"
_fx_git "$TS3Q" update-ref refs/remotes/origin/main "$TS3_QM" >/dev/null 2>&1
( _fx_cd "$TS3HR" && git init -q -b main && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
cp -R "$TS3PP" "$TS3HP"; printf 'state/\n*.log\n' > "$TS3HR/.gitignore"
LC_ALL=C sed -e 's|"name": "ts3"|"name": "ts3p"|' -e 's|example.com/ts3"|example.com/ts3p"|' "$TS3PP/project.json" > "$TS3HP/project.json"
_ts3_commit "$TS3HR" home; TS3_HM="$(_jr_sha "$TS3HR" HEAD)"; _fx_git "$TS3HR" update-ref refs/remotes/origin/main "$TS3_HM" >/dev/null 2>&1
mkdir -p "$TS3/hp"; _fx_git "$TS3HR" archive -o "$TS3/hp.tar" "$TS3_HM" projects/ts3p >/dev/null 2>&1 && tar -x -C "$TS3/hp" -f "$TS3/hp.tar"; rm -f "$TS3/hp.tar"
_ts3_qcand() { ( _fx_cd "$TS3Q" && git checkout -q -f -B "$1" main ) >/dev/null 2>&1; }   # BRANCH: a candidate in Q off main
_ts3_check "trust-step3: S1.8 (a product's home) (fixture control): Q holds no engine manifest at main or in its tree and names ts3p, origin/main is main, and its home HR is a repository of its own whose origin/main holds projects/ts3p with the fx row's evidence contract tools/check-fx" \
  "$(git -C "$TS3Q" ls-tree -r --name-only main -- engine 2>&1 | LC_ALL=C awk 'END { print NR }')$([ -e "$TS3Q/engine/.claude-plugin/plugin.json" ] && echo ' in tree')|$(cat "$TS3Q/.felix")|$(_jr_sha "$TS3Q" refs/remotes/origin/main)|$(git -C "$TS3HR" rev-parse --show-toplevel 2>&1)|$(git -C "$TS3HR" show refs/remotes/origin/main:projects/ts3p/obligations.tsv 2>&1 | LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }')" \
  "0|ts3p|$TS3_QM|$TS3HR|tools/check-fx"

# Linked: HR's projects/ts3p moved out of the home under another name, loosened there, and a link put back, uncommitted.
_ts3_qcand ts3p-link; _fx_git "$TS3Q" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3Q" link
mv "$TS3HP" "$TS3/moved-ts3p"; _ts3_loosen "$TS3/moved-ts3p"; ln -s "$TS3/moved-ts3p" "$TS3HP"
_ts3_check "trust-step3: S1.8 (a product's home, linked) (fixture control): HR's projects/ts3p is a link, uncommitted (HR's HEAD is its origin/main), to a directory outside the home that differs from HR's committed tables only in the fx row's evidence contract, now true, and the candidate in Q only deletes MARKER" \
  "$([ -L "$TS3HP" ] && echo link)|$(readlink "$TS3HP" 2>&1)|$(_jr_sha "$TS3HR" HEAD) $(_jr_sha "$TS3HR" refs/remotes/origin/main)|$(_ts3_ndiff "$TS3/hp/projects/ts3p" "$TS3/moved-ts3p") lines differ|$(_ts3_ns "$TS3Q" main)" \
  "link|$TS3/moved-ts3p|$TS3_HM $TS3_HM|2 lines differ|D MARKER;"
TS3_RH="$TS3HR"; TS3_RP="$TS3HP"; _ts3_entry S1.8-product-linked "$TS3Q"
_ts3_check "trust-step3: S1.8 (a product's home, linked): a candidate in the product Q that deletes MARKER, while its home HR's projects/ts3p is a link to a loosened copy outside the home, is refused with an obligations line for fx (P is HR's origin/main)" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"
rm -f "$TS3HP"; rm -rf "${TS3:?}/moved-ts3p"; ( _fx_cd "$TS3HR" && git checkout -q -- projects/ts3p ) >/dev/null 2>&1
_ts3_qcand ts3p-notes; printf 'notes the candidate adds\n' > "$TS3Q/NOTES.md"; _ts3_commit "$TS3Q" notes
_ts3_entry S1.8-product-control "$TS3Q"
_ts3_check "trust-step3: S1.8 (a product's home, linked, control): with HR's committed projects/ts3p back, an unrelated candidate in Q passes the dry run" \
  "$(_ts3_passed)" "passed" "$(_ts3_why)"

# Planted: a repository made in HR's projects/, holding the loosened tables at its HEAD and origin/main, and HR's
# working-tree table loosened to match.
_ts3_qcand ts3p-planted; _fx_git "$TS3Q" rm -q MARKER >/dev/null 2>&1; _ts3_commit "$TS3Q" planted
_ts3_loosen "$TS3HP"
( _fx_cd "$TS3HR/projects" && git init -q -b main && git config gc.auto 0 && git config maintenance.auto false ) >/dev/null 2>&1
_ts3_commit "$TS3HR/projects" planted; _fx_git "$TS3HR/projects" update-ref refs/remotes/origin/main "$(_jr_sha "$TS3HR/projects" HEAD)" >/dev/null 2>&1
_ts3_check "trust-step3: S1.8 (a product's home, a planted repository) (fixture control): git in HR's projects answers with the planted repository, whose HEAD and origin/main hold ts3p with the fx row's evidence contract true, as HR's working tree does, while HR's origin/main holds tools/check-fx" \
  "$(git -C "$TS3HR/projects" rev-parse --show-toplevel 2>&1)|$(git -C "$TS3HR/projects" show HEAD:ts3p/obligations.tsv 2>&1 | LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }')|$(git -C "$TS3HR/projects" show refs/remotes/origin/main:ts3p/obligations.tsv 2>&1 | LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }')|$(LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }' "$TS3HP/obligations.tsv")|$(git -C "$TS3HR" show refs/remotes/origin/main:projects/ts3p/obligations.tsv 2>&1 | LC_ALL=C awk -F'\t' '$1 == "fx" { print $5 }')|$(_ts3_ns "$TS3Q" main)" \
  "$TS3HR/projects|true|true|true|tools/check-fx|D MARKER;"
_ts3_entry S1.8-product-planted "$TS3Q"
_ts3_check "trust-step3: S1.8 (a product's home, a planted repository): a candidate in the product Q that deletes MARKER, while a repository planted in HR's projects holds loosened tables and HR's working tree matches them, is refused with an obligations line for fx (P is HR's origin/main)" \
  "$(_ts3_refused)|$(_ts3_bl obligations fx - -)" "refused|yes" "$(_ts3_why)"
TS3_RH=""; TS3_RP=""; rm -rf "${TS3HR:?}/projects/.git"; ( _fx_cd "$TS3HR" && git checkout -q -- projects/ts3p ) >/dev/null 2>&1

# ------------------------------------------------------------------- S1.5 ---
_ts3_check "trust-step3: S1.5: no felix-policy.* entry remains under any run's TMPDIR after it ends, though one existed while the passing control judged (P's check-fx ran from it)" \
  "runs $TS3_RUNS|copy seen $TS3_PCOPY|left [$TS3_LEFT]" "runs $TS3_RUNS|copy seen yes|left []"

( _fx_cd "$TS3R" && git checkout -q -f main ) >/dev/null 2>&1
rm -rf "$MEM/ts3" "$MEM/ts32" "$MEM/ts3p" "${TS3:?}"
# <<< trust-step3-policy-from-p-b

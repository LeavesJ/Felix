_locale_bytes_vars
# G1. Project binding. A home holding Web (acme/web) and web-admin
# (acme/web-admin), and a checkout whose origin is acme/web-admin, so both
# remote_match cells occur in the remote and the first project the glob
# yields wins. Which one that is in C is a separate defect (byte order picks
# the less specific one); what is asserted here is only that the locale does
# not change it. The remote is set with `git config` on the fixture, because
# a deny row refuses `git remote add`.
LGB_D_GH="$TMP/lgb-d-bind-home"; LGB_D_GR="$TMP/lgb-d-bind-repo"
mkdir -p "$LGB_D_GH/projects/Web" "$LGB_D_GH/projects/web-admin" "$LGB_D_GR"
printf '{\n  "name": "Web",\n  "remote_match": "acme/web"\n}\n' > "$LGB_D_GH/projects/Web/project.json"
printf '{\n  "name": "web-admin",\n  "remote_match": "acme/web-admin"\n}\n' > "$LGB_D_GH/projects/web-admin/project.json"
( _fx_cd "$LGB_D_GR" && git init -q -b main ) >/dev/null 2>&1
LGB_D_GR="$(cd "$LGB_D_GR" && pwd -P)" || LGB_D_GR=""
LGB_D_GH="$(cd "$LGB_D_GH" && pwd -P)" || LGB_D_GH=""
[ -n "$LGB_D_GR" ] && [ -d "$LGB_D_GR/.git" ] \
  && _fx_git "$LGB_D_GR" config remote.origin.url git@github.com:acme/web-admin.git
_lgb_d_bind() {  # the project felix_resolve_project binds the fixture checkout to, and its status
  [ -n "$LGB_D_GR" ] && [ -d "$LGB_D_GR/.git" ] || { printf 'no fixture'; return 0; }
  ( . "$FROOT/harness/lib/resolve.sh"; felix_resolve_project "$LGB_D_GR" "$LGB_D_GH"; printf ' rc=%s' "$?" ) </dev/null 2>/dev/null
}
_lgb_d_glob1() {  # the first entry a glob over the fixture's projects yields
  local d; for d in "$LGB_D_GH"/projects/*/project.json; do d="${d%/project.json}"; printf '%s' "${d##*/}"; return 0; done
}
# G2. Which installed copy of a plugin is read. A cache holding the same
# plugin under two marketplaces, Zeta and alpha, which a glob yields in
# opposite orders in C and UTF-8.
LGB_D_PC="$TMP/lgb-d-cache"
mkdir -p "$LGB_D_PC/Zeta/p/1.0.0" "$LGB_D_PC/alpha/p/2.0.0"
_lgb_d_tool() {  # the path felix_toolbox_path returns for p, and its status
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/toolbox.sh"
    FELIX_PLUGIN_CACHE="$LGB_D_PC"; felix_toolbox_path p; printf ' rc=%s' "$?" ) </dev/null 2>/dev/null
}
_lgb_d_cache1() { local d; for d in "$LGB_D_PC"/*/p; do d="${d%/p}"; printf '%s' "${d##*/}"; return 0; done; }
# The two controls below are on the fixtures and the host, not on the engine:
# they show each glob changes order with the locale, and that in C the engine
# answers at all, so the UTF-8 lines can only fail for the locale.
if [ -n "$LCB_U8" ]; then
  is  "the binding fixture's projects glob Web first in C and web-admin first in the UTF-8 locale, and in C felix_resolve_project binds one of them" \
      "$(_lgb_d_in C _lgb_d_glob1)|$(_lgb_d_in all _lgb_d_glob1)|$(_lgb_d_in C _lgb_d_bind | LC_ALL=C sed 's/.* //')" "Web|web-admin|rc=0"
  is  "the plugin cache fixture globs Zeta first in C and alpha first in the UTF-8 locale, and in C felix_toolbox_path returns a copy" \
      "$(_lgb_d_in C _lgb_d_cache1)|$(_lgb_d_in all _lgb_d_cache1)|$(_lgb_d_in C _lgb_d_tool | LC_ALL=C sed 's/.* //')" "Zeta|alpha|rc=0"
  is  "in a UTF-8 locale with LANG set and LC_ALL unset, felix_resolve_project binds a checkout two projects' remote_match both occur in to the project it binds in C" \
      "$(_lgb_d_in lang _lgb_d_bind)" "$(_lgb_d_in C _lgb_d_bind)"
  is  "and with LC_ALL set to that locale, felix_resolve_project binds the same project as in C" \
      "$(_lgb_d_in all _lgb_d_bind)" "$(_lgb_d_in C _lgb_d_bind)"
  is  "in a UTF-8 locale, felix_toolbox_path returns the same installed copy of a plugin held under two marketplaces as in C" \
      "$(_lgb_d_in all _lgb_d_tool)" "$(_lgb_d_in C _lgb_d_tool)"
else
  for a in "the binding fixture's projects glob Web first in C and web-admin first in the UTF-8 locale, and in C felix_resolve_project binds one of them" \
           "the plugin cache fixture globs Zeta first in C and alpha first in the UTF-8 locale, and in C felix_toolbox_path returns a copy" \
           "in a UTF-8 locale with LANG set and LC_ALL unset, felix_resolve_project binds a checkout two projects' remote_match both occur in to the project it binds in C" \
           "and with LC_ALL set to that locale, felix_resolve_project binds the same project as in C" \
           "in a UTF-8 locale, felix_toolbox_path returns the same installed copy of a plugin held under two marketplaces as in C"; do
    skip "$a" "$LCB_NONE"
  done
fi

# G3. Discover's capability rules. A project declaring `Security`, which is
# not an identifier (uppercase), and `infra`, which is, against a template
# with no curated rows: only the declarations drive the rules, and only
# identifiers of five characters up become one.
LGB_D_DT="$TMP/lgb-d-rules-tpl"; LGB_D_DP="$TMP/lgb-d-rules-proj"; mkdir -p "$LGB_D_DT" "$LGB_D_DP"
printf 'Security\ninfra\n' > "$LGB_D_DP/capabilities"
_lgb_d_rules() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/discover.sh"
    _felix_discover_rules "$LGB_D_DT" "$LGB_D_DP" ) </dev/null 2>/dev/null
}
# G4 and G5. Two range checks over person-written names: a commissioning
# answer's provider form, and the .felix marker's project name. Each is given
# a name whose letters are an e-acute in UTF-8 (\303\251), which C refuses,
# and a plain one, which both must accept (so a check that refuses everything
# cannot pass).
_lgb_d_ans() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission.sh"
    _felix_commission_answer_ok "$(printf 'provider:\303\251x:\303\251y')"; printf '%s' "$?"
    _felix_commission_answer_ok 'provider:plug:skill'; printf ' %s' "$?" ) </dev/null 2>/dev/null
}
_lgb_d_name() {
  ( . "$FROOT/harness/lib/resolve.sh"
    _felix_name_ok "$(printf 'caf\303\251')"; printf '%s' "$?"
    _felix_name_ok 'cafe'; printf ' %s' "$?" ) </dev/null 2>/dev/null
}
is  "in C, discover's rules for a project declaring Security and infra are infra's alone" \
    "$(_lgb_d_in C _lgb_d_rules | LC_ALL=C tr '\t\n' ': ')" "infra:infra "
is  "in C, a commissioning answer naming a provider in e-acute letters is refused and provider:plug:skill accepted" "$(_lgb_d_in C _lgb_d_ans)" "1 0"
is  "in C, a project name with an e-acute is refused and cafe accepted" "$(_lgb_d_in C _lgb_d_name)" "1 0"
LGB_D_G3="in a UTF-8 locale, discover makes no capability rule for a declared Security, as in C"
LGB_D_G4="in a UTF-8 locale, _felix_commission_answer_ok refuses a provider and skill spelt with an e-acute, as in C"
LGB_D_G5="in a UTF-8 locale, _felix_name_ok refuses a project name ending in an e-acute, as in C"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_D_G3" "$(_lgb_d_in all _lgb_d_rules | LC_ALL=C tr '\t\n' ': ')" "infra:infra "
  is  "$LGB_D_G4" "$(_lgb_d_in all _lgb_d_ans)" "1 0"
  is  "$LGB_D_G5" "$(_lgb_d_in all _lgb_d_name)" "1 0"
else
  for a in "$LGB_D_G3" "$LGB_D_G4" "$LGB_D_G5"; do skip "$a" "$LCB_NONE"; done
fi

is  "the bash-collation lints' scope reaches felix, the libraries, the hooks, the bin scripts and the workflow template" \
    "$(_lgb_d_scope "$REAL_HARNESS" | LC_ALL=C sed "s|^$REAL_HARNESS/||; s|/.*||" | LC_ALL=C sort -u | LC_ALL=C tr '\n' ' ')" \
    "bin felix hooks lib templates "

# L1. Every `[[ ... =~` in runtime code sits in a function that has already
# declared LC_ALL=C in a `local` line (bash's ERE matches by the locale, and
# never matches a string holding a byte that is not UTF-8). A function starts
# at a `name()` line and, at top level, ends at the next column-0 `}`; a
# `local` line counts when one of its words, after the segment is cut at ; &
# and |, is exactly LC_ALL=C. A `[[` counts only at a command position (line
# start, blank, or one of ; & | ( ! {) followed by a blank, and the =~ only
# with blanks around it, which is how an awk or grep string holding
# `[[:space:]]=~` stays out. A `local` is read at a command position (line
# start, or after ; & | {) up to the next ;, so a value holding ${1:-} or a
# quoted | does not hide a LC_ALL=C after it. A whole-line comment is not code. A `[[ =~` at
# top level, outside every function, cannot declare a local and is named too.
_lgb_d_relint() {  # <prefix to strip> <file>...: file:line for each finding
  local pre="$1"; shift
  LC_ALL=C awk -v pre="$pre" '
    FNR == 1 { infn = 0; has = 0 }
    /^[[:space:]]*#/ { next }
    { line = $0
      one = 0
      if (line ~ /^[[:space:]]*(function[[:space:]]+)?[A-Za-z_][A-Za-z0-9_:.-]*[[:space:]]*\(\)/) {
        infn = 1; has = 0; one = (line ~ /\)[[:space:]]*\{.*\}[[:space:]]*;?[[:space:]]*$/) }
      t = line
      while (match(t, /(^|[;&|{])[[:space:]]*local[[:space:]][^;]*/)) {
        m = split(substr(t, RSTART, RLENGTH), w, /[[:space:]]+/)
        for (j = 1; j <= m; j++) if (w[j] == "LC_ALL=C") has = 1
        t = substr(t, RSTART + RLENGTH)
      }
      if (line ~ /(^|[[:space:];&|(!{])\[\[[[:space:]].*[[:space:]]=~([[:space:]]|$)/ && (!infn || !has)) {
        f = FILENAME; if (index(f, pre) == 1) f = substr(f, length(pre) + 1)
        printf "%s:%d\n", f, FNR
      }
      if (one || line ~ /^}/) { infn = 0; has = 0 } }' "$@" \
    || printf 'the lint itself failed\n'
}
LGB_D_LF="$TMP/lgb-d-lint"; mkdir -p "$LGB_D_LF"
cat > "$LGB_D_LF/re-catch.sh" <<'EOF'
f1() {
  [[ "$x" =~ $re ]] && return 0
}
f2() {
  local LC_ALL=en_US.UTF-8
  [[ "$x" =~ $re ]]
}
f3() {
  local a LC_COLLATE=C
  if [[ $x =~ ^a ]]; then :; fi
}
f4() { local LC_ALL=C; }
f5() {
  [[ $x =~ y ]] || return 1
}
f6() { local LC_ALL=C; :; }
[[ $x =~ y ]] && echo top-level
EOF
cat > "$LGB_D_LF/re-clean.sh" <<'EOF'
g1() {
  local pattern="$1" subj="$2" start="$3" gdir="$4" LC_ALL=C
  local out line
  [[ "$subj" =~ $pattern ]] || return 1
}
# a comment: [[ "$x" =~ y ]]
    # an indented one: [[ $a =~ b ]]
g2() {
  LC_ALL=C awk '/[[:space:]]=~[[:space:]]/ { print }' f
  LC_ALL=C grep -qE '[[:space:]]=~' f
  LC_ALL=C grep -q '\[\[ .* =~' f
}
g3() { local LC_ALL=C; [[ $x =~ y ]]; }
g4() {
  local raw="${1:-}" home="${2:-}" re='^[[:space:]]*:(a|b)"([^"]*)"' LC_ALL=C
  [[ $raw =~ $re ]] || return 0
}
EOF
is  "the =~ lint names a [[ =~ ]] in a function with no local, with LC_ALL set to a UTF-8 locale, with LC_COLLATE=C, after another function's local, and at top level after a one-line function" \
    "$(_lgb_d_relint "$LGB_D_LF/" "$LGB_D_LF/re-catch.sh" | LC_ALL=C tr '\n' ' ')" "re-catch.sh:2 re-catch.sh:6 re-catch.sh:10 re-catch.sh:14 re-catch.sh:17 "
is  "and names none of where.sh's shape, a local whose values hold a parameter default and a quoted bar, comment lines, an awk or grep string holding =~, or a one-line function declaring it first" \
    "$(_lgb_d_relint "$LGB_D_LF/" "$LGB_D_LF/re-clean.sh" | LC_ALL=C tr '\n' ' ')" ""
LGB_D_L1="$(_lgb_d_scope "$REAL_HARNESS" | _lgb_d_files _lgb_d_relint "$REAL_HARNESS/")"
is  "every [[ =~ ]] in the engine's runtime code sits in a function that declares local LC_ALL=C" \
    "$(printf '%s' "$LGB_D_L1" | LC_ALL=C tr '\n' ' ')" ""

# L2 and L3 read named functions. A function on a list is a top-level
# `name()` line at column 0 through the next column-0 `}`, and every name on a
# list must be found exactly once across runtime code: a name that is gone
# reads `missing:<name>`, one defined twice `twice:<name>`, so the list cannot
# shrink by a rename. Both lists are the contract's
# (audits/2026-10-08-locale-glob-bsd-tools/contract.md, "The fix"), copied
# as data.
#
# L2, the Rule 2 list: functions that exist to decide from bytes the engine did
# not write. Inside each, every grep, egrep, fgrep, sed, tr, cut, awk, paste,
# fold, column, rev and expand at a command position is written
# `LC_ALL=C <tool>`. The command position is read as the neighbour's lint
# reads it (segments cut at | ; & ( ) { } and the backtick, leading reserved
# words, wrappers, assignments, glued redirections and opening quotes read
# off), copied under this prefix with this class's tools. The last eight
# lines of L2 and the last line of L3 are the adversarial review's of
# 15e707de (contract, Amendment 2).
LGB_D_R2='_felix_escape_confined _felix_escape_fewer _felix_escape_lines felix_escapes
felix_json_str felix_added_lines _felix_plugin_version felix_version_bump felix_head_branch felix_home felix_binding_broken felix_resolve_project
_felix_classify_pass
_felix_any_match
felix_verify_current felix_verify_epoch_fields
felix_epoch
felix_receipt
felix_review_passed
felix_overnight_field
_felix_obligation_scan _felix_obligation_field felix_obligations_orphans felix_obligation_names
felix_probes_run felix_probe_state felix_probe_rows felix_probe_malformed felix_probes_record
_felix_exceptions_scan felix_exception_for
_felix_land_scan
felix_maint_status _felix_maint_rows
felix_incident_paths felix_incident_severity
felix_repair_excerpt
felix_coverage_check
felix_adopt_capability
felix_handoff_check felix_handoff_in_flight
felix_ledger_summary
felix_mem_handoff
felix_commission_counts _felix_commission_functions_present
felix_setup_status _felix_setup_norm _felix_setup_classify
felix_discover_candidates felix_discover_adopt _felix_discover_mcp_facts _felix_discover_lsp_facts felix_plugin_description _felix_cap_tokens
felix_commission_admit felix_commission_apply_declares felix_commission_request felix_commission_provider_rows felix_commission_provider_state _felix_commission_provider_lines
felix_toolbox_routed
felix_candidates_rules
_felix_bs_have_perms
_felix_dep_grep felix_guess_gate
felix_route_context felix_route_state_guessed
felix_deny_code felix_deny_subject
felix_epoch_topology
_felix_commission_provider_toolong felix_commission_provider_rejects
felix_candidates_record
felix_route_render
felix_ready_report
_felix_discover_hooks_facts'
# L3, the Rule 1 list: functions whose answer can depend on bash's own
# collation. Two the contract names by line at b434425f: setup.sh:121/:141
# sit in _felix_setup_classify, guard.sh:231 in _felix_guard_owed.
LGB_D_R1='felix_resolve_project _felix_name_ok _felix_hook_dir_set
felix_toolbox_path
_felix_discover_rules
_felix_commission_answer_ok
felix_gate_workflow
_felix_setup_classify
_felix_deny_first felix_deny_overbroad
_felix_guard_owed
_felix_hold_path _felix_overnight_sid_ok _felix_mem_sid'
_lgb_d_vlint() {  # <prefix to strip> <names> <file>...: file:line per unpinned tool in a listed function, then missing:/twice: names
  local pre="$1" names; names="$(printf '%s' "$2" | LC_ALL=C tr '\n' ' ')"; shift 2
  LC_ALL=C awk -v pre="$pre" -v names="$names" '
    BEGIN { nn = split(names, NM, /[[:space:]]+/); for (k = 1; k <= nn; k++) if (NM[k] != "") want[NM[k]] = 1 }
    FNR == 1 { infn = "" }
    { one = 0
      if (match($0, /^[A-Za-z_][A-Za-z0-9_:.-]*[[:space:]]*\(\)/)) {
        nm = substr($0, 1, RLENGTH); sub(/[[:space:]]*\(\)$/, "", nm)
        if (nm in want) { infn = nm; cnt[nm]++ } else infn = ""
        one = ($0 ~ /\)[[:space:]]*\{.*\}[[:space:]]*;?[[:space:]]*$/)
      }
      if (infn == "") next
      if ($0 ~ /^}/) { infn = ""; next }
      if ($0 ~ /^[[:space:]]*#/) next
      line = $0; gsub(/(grep|egrep|fgrep|sed|tr|cut|awk|paste|fold|column|rev|expand)\(/, "_&", line)
      n = split(line, seg, /[|;&(){}`]/)
      for (i = 1; i <= n; i++) {
        s = seg[i]; last = ""; viaenv = 0; wrap = 0
        while (1) {
          sub(/^[[:space:]]+/, "", s)
          if (s ~ /^["\047]/) { s = substr(s, 2); continue }
          if (!match(s, /^[^[:space:]]+([[:space:]]|$)/)) break
          w = substr(s, 1, RLENGTH); sub(/[[:space:]]+$/, "", w)
          if (w ~ /^(!|if|then|else|elif|do|while|until|time|eval)$/) wrap = 0
          else if (w ~ /^(env|command|exec|nice|nohup|xargs|bash|sh)$/) { wrap = 1; if (w == "env") viaenv = 1 }
          else if (wrap && w ~ /^-/) { }
          else if (w ~ /^[0-9]*[<>]+[^<>[:space:]]/) { }
          else if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) wrap = 0
          else break
          last = w; s = substr(s, RLENGTH + 1)
        }
        if (s !~ /^\\?([^[:space:]]*\/)?(grep|egrep|fgrep|sed|tr|cut|awk|paste|fold|column|rev|expand)([[:space:]<>)"\047]|$)/) continue
        if (last == "LC_ALL=C" && !viaenv) continue
        f = FILENAME; if (index(f, pre) == 1) f = substr(f, length(pre) + 1)
        printf "%s:%d\n", f, FNR; break
      }
      if (one) infn = "" }
    END { for (k = 1; k <= nn; k++) { x = NM[k]; if (x == "" || seen[x]++) continue
            if (!(x in cnt)) printf "missing:%s\n", x; else if (cnt[x] > 1) printf "twice:%s\n", x } }' "$@" \
    || printf 'the lint itself failed\n'
}
_lgb_d_r1lint() {  # <prefix to strip> <names> <file>...: lacks:<name> for a listed function with no local LC_ALL=C, then missing:/twice:
  local pre="$1" names; names="$(printf '%s' "$2" | LC_ALL=C tr '\n' ' ')"; shift 2
  LC_ALL=C awk -v names="$names" '
    BEGIN { nn = split(names, NM, /[[:space:]]+/); for (k = 1; k <= nn; k++) if (NM[k] != "") want[NM[k]] = 1 }
    FNR == 1 { infn = "" }
    { one = 0
      if (match($0, /^[A-Za-z_][A-Za-z0-9_:.-]*[[:space:]]*\(\)/)) {
        nm = substr($0, 1, RLENGTH); sub(/[[:space:]]*\(\)$/, "", nm)
        if (nm in want) { infn = nm; cnt[nm]++ } else infn = ""
        one = ($0 ~ /\)[[:space:]]*\{.*\}[[:space:]]*;?[[:space:]]*$/)
      }
      if (infn == "") next
      if ($0 !~ /^[[:space:]]*#/) {
        t = $0
        while (match(t, /(^|[;&|{])[[:space:]]*local[[:space:]][^;]*/)) {
          m = split(substr(t, RSTART, RLENGTH), w, /[[:space:]]+/)
          for (j = 1; j <= m; j++) if (w[j] == "LC_ALL=C") has[infn] = 1
          t = substr(t, RSTART + RLENGTH)
        }
      }
      if (one || $0 ~ /^}/) infn = "" }
    END { for (k = 1; k <= nn; k++) { x = NM[k]; if (x == "" || seen[x]++) continue
            if (!(x in cnt)) printf "missing:%s\n", x
            else if (cnt[x] > 1) printf "twice:%s\n", x
            else if (!(x in has)) printf "lacks:%s\n", x } }' "$@" \
    || printf 'the lint itself failed\n'
}
cat > "$LGB_D_LF/v-catch.sh" <<'EOF'
lgb_vcatch() {
  x="$(printf '%s' "$a" | cut -f2)"
  y="$(sed -n 's/x/y/p' f)"
  grep -qE "$p" <<<"$x" && return 0
  awk '/re/' f
  X=y awk '/re/' f
  if ! grep -q x f; then :; fi
  while grep -q x f; do :; done
  { printf x; cut -f2 f; }
}
lgb_vone() { printf '%s' "$1" | tr a b; }
EOF
cat > "$LGB_D_LF/v-clean.sh" <<'EOF'
lgb_vclean() {
  x="$(printf '%s' "$a" | LC_ALL=C cut -f2)"
  y="$(LC_ALL=C sed -n 's/x/y/p' f)"
  LC_ALL=C grep -qE "$p" <<<"$x" && return 0
  LC_ALL=C awk '/re/' f
  X=y LC_ALL=C awk '/re/' f
  if ! LC_ALL=C grep -q x f; then :; fi
  while LC_ALL=C grep -q x f; do :; done
  { printf x; LC_ALL=C cut -f2 f; }
  # a comment: printf x | cut -f2
  die "grep found nothing to cut"
}
lgb_unlisted() {
  x="$(cut -f2 f)"
}
lgb_vone2() { printf '%s' "$1" | LC_ALL=C tr a b; }
y="$(cut -f1 f)"
EOF
cat > "$LGB_D_LF/v-twice.sh" <<'EOF'
lgb_vclean() {
  :
}
EOF
cat > "$LGB_D_LF/r1.sh" <<'EOF'
r1_ok() {
  local a="${1:-}" re='^(a|b)$' LC_ALL=C
  case "$a" in *[!a-z]*) return 1 ;; esac
}
r1_utf8() {
  local LC_ALL=en_US.UTF-8
}
r1_collate() {
  local a LC_COLLATE=C
}
r1_export() {
  export LC_ALL=C
}
r1_comment() {
  # local LC_ALL=C
  :
}
r1_prefix() {
  LC_ALL=C grep -q x f
}
r1_one() { local LC_ALL=C; case "$1" in [a-z]*) return 0 ;; esac; return 1; }
r1_after() {
  :
}
local LC_ALL=C
EOF
cat > "$LGB_D_LF/r1-twice.sh" <<'EOF'
r1_ok() {
  case "$1" in *[!a-z]*) return 1 ;; esac
}
EOF
is  "the verdict-function lint names an unpinned cut after a pipe, sed in \$( ), grep before <<<, awk with a regex, awk after an assignment, grep after if !, grep after while, cut inside { }, and tr in a one-line function, by file and line" \
    "$(_lgb_d_vlint "$LGB_D_LF/" 'lgb_vcatch lgb_vone' "$LGB_D_LF/v-catch.sh" | LC_ALL=C tr '\n' ' ')" \
    "v-catch.sh:2 v-catch.sh:3 v-catch.sh:4 v-catch.sh:5 v-catch.sh:6 v-catch.sh:7 v-catch.sh:8 v-catch.sh:9 v-catch.sh:11 "
is  "and names none of the eight pinned, an assignment before LC_ALL=C among them, a comment, a tool name inside a string, a tool in a function not on its list, or one after a listed one-line function ends" \
    "$(_lgb_d_vlint "$LGB_D_LF/" 'lgb_vclean lgb_vone2' "$LGB_D_LF/v-clean.sh" | LC_ALL=C tr '\n' ' ')" ""
is  "and names a listed function defined twice, and one that is gone, in the list's order" \
    "$(_lgb_d_vlint "$LGB_D_LF/" 'lgb_vclean lgb_vgone' "$LGB_D_LF/v-clean.sh" "$LGB_D_LF/v-twice.sh" | LC_ALL=C tr '\n' ' ')" \
    "twice:lgb_vclean missing:lgb_vgone "
is  "the Rule 1 lint accepts a local LC_ALL=C, in a one-line function too, and names a local UTF-8 LC_ALL, a local LC_COLLATE=C, an export, a comment, a command prefix, one past the function's end and a missing function" \
    "$(_lgb_d_r1lint "$LGB_D_LF/" 'r1_ok r1_utf8 r1_collate r1_export r1_comment r1_prefix r1_one r1_after r1_gone' "$LGB_D_LF/r1.sh" | LC_ALL=C tr '\n' ' ')" \
    "lacks:r1_utf8 lacks:r1_collate lacks:r1_export lacks:r1_comment lacks:r1_prefix lacks:r1_after missing:r1_gone "
is  "and names a listed function defined a second time in another file without the local, twice:r1_ok, ahead of the rest in the list's order" \
    "$(_lgb_d_r1lint "$LGB_D_LF/" 'r1_ok r1_utf8 r1_one r1_gone' "$LGB_D_LF/r1.sh" "$LGB_D_LF/r1-twice.sh" | LC_ALL=C tr '\n' ' ')" \
    "twice:r1_ok lacks:r1_utf8 missing:r1_gone "
LGB_D_L2="$(_lgb_d_scope "$REAL_HARNESS" | _lgb_d_files _lgb_d_vlint "$REAL_HARNESS/" "$LGB_D_R2")"
if [ -z "$LGB_D_L2" ]; then
  ok  "every listed verdict function is found once, and every grep, sed, tr, cut, awk and their kin inside it is written LC_ALL=C <tool>"
else
  bad "every listed verdict function is found once, and every grep, sed, tr, cut, awk and their kin inside it is written LC_ALL=C <tool>" \
      "$(printf '%s\n' "$LGB_D_L2" | LC_ALL=C grep -c .) findings: $(printf '%s\n' "$LGB_D_L2" | LC_ALL=C tr '\n' ' ')"
fi
LGB_D_L3="$(_lgb_d_scope "$REAL_HARNESS" | _lgb_d_files _lgb_d_r1lint "$REAL_HARNESS/" "$LGB_D_R1")"
is  "every function on the Rule 1 list is found once and declares LC_ALL=C in a local line" \
    "$(printf '%s' "$LGB_D_L3" | LC_ALL=C tr '\n' ' ')" ""

# fragment e: digit ranges, U+2185 (E22-E25, L4)
#
# bash 3.2 collates a bracket range in its own patterns, and under en_US.UTF-8
# on macOS one character outside ASCII collates as a digit: U+2185 ROMAN
# NUMERAL SIX LATE FORM (bytes e2 86 85) matches [1-9] and [0-9], so
# `*[!0-9]*` does not refuse it. Measured 2026-10-08, bash 3.2.57, macOS 26
# (contract, Amendment 1). What the admitted value then meets: `[ -ne ]`
# returns 2 and reads as "not different", `$((...))` aborts the rest of the
# caller's line, and a positive arm like `[1-9]` simply admits it. The value
# is built with printf, so no byte outside ASCII sits in this file. Each case
# runs the one call under test in a subshell set to the UTF-8 locale, reads
# the answer outside it with LC_ALL=C tools, and has a C control on the same
# fixture. glibc's bash collates its own patterns too, so where Linux has the
# locale and a code point collating as a digit these can fail there as well.
LGB_E_U="$(printf '\342\206\205')"
_lgb_e_in() {  # C|lang|all <command...>: one call in a chosen locale, in a subshell
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}

# E22. commission-provider.sh: felix_commission_provider_state over a
# model-written answer: the topology line, three automation rows and a last
# row `done<TAB>v`. The guard `''|*[!0-9]*` lets U+2185 by in UTF-8, and the
# `[ "$n" -ne "$rows" ]` after it returns 2, so the answer read `answered`
# whatever count the model gave. Both shapes: the character alone, and after a
# digit. The fixture is written in the suite's own locale; only the reading is
# in the subshell. The topology is the real one for an empty checkout, so a
# fixture the reader takes for another topology reads stale and fails the
# controls rather than passing anything.
LGB_E_MEM="$TMP/lgb-e-mem"; LGB_E_PJ="$TMP/lgb-e-home/projects/lgbe"; LGB_E_RT="$TMP/lgb-e-root"
mkdir -p "$LGB_E_MEM" "$LGB_E_PJ" "$LGB_E_RT"
_lgb_e_answer() {  # <done value>: writes the answer file over three rows ending in that done row
  ( export FELIX_MEMORY="$LGB_E_MEM"
    . "$FROOT/harness/lib/commission-provider.sh" || exit 1
    f="$(felix_commission_answer_path "$LGB_E_PJ" lgb_need)"
    [ -n "$f" ] && mkdir -p "${f%/*}" || exit 1
    { printf '# topology %s\n' "$(felix_commission_topology "$LGB_E_PJ" "$LGB_E_RT")"
      printf 'plugin\tlgb-a\tcap\tx\tthe first row\n'
      printf 'plugin\tlgb-b\tcap\tx\tthe second row\n'
      printf 'plugin\tlgb-c\tcap\tx\tthe third row\n'
      printf 'done\t%s\n' "$1"; } > "$f" ) </dev/null >/dev/null 2>&1
}
_lgb_e_state() {  # felix_commission_provider_state over that answer, raw
  ( export FELIX_MEMORY="$LGB_E_MEM"
    . "$FROOT/harness/lib/commission-provider.sh"
    felix_commission_provider_state "$LGB_E_PJ" "$LGB_E_RT" lgb_need ) </dev/null 2>/dev/null
}
_lgb_e_st() {  # <C|lang|all> <done value>: the state word that locale reads over that answer
  _lgb_e_answer "$2" || { printf 'no fixture'; return 0; }
  _lgb_e_in "$1" _lgb_e_state | LC_ALL=C cut -f1
}
is  "in C, a commissioning answer whose done row is U+2185 over three rows reads partial" \
    "$(_lgb_e_st C "$LGB_E_U")" "partial"
is  "in C, a commissioning answer whose done row is 3 then U+2185 over three rows reads partial" \
    "$(_lgb_e_st C "3$LGB_E_U")" "partial"
is  "in C, the same answer with done 3 over three rows reads answered, and with done 2 partial" \
    "$(_lgb_e_st C 3)|$(_lgb_e_st C 2)" "answered|partial"
LGB_E_22A="in a UTF-8 locale with LC_ALL set, a commissioning answer whose done row is U+2185 does not read answered, and reads as in C"
LGB_E_22L="in a UTF-8 locale with LANG set and LC_ALL unset, a commissioning answer whose done row is U+2185 does not read answered, and reads as in C"
LGB_E_22B="in a UTF-8 locale with LC_ALL set, a commissioning answer whose done row is 3 then U+2185 does not read answered, and reads as in C"
LGB_E_22M="in a UTF-8 locale with LANG set and LC_ALL unset, a commissioning answer whose done row is 3 then U+2185 does not read answered, and reads as in C"
LGB_E_22K="in a UTF-8 locale, the same answer with done 3 over three rows still reads answered, and with done 2 partial"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_E_22A" "$(_lgb_e_st all  "$LGB_E_U")"  "$(_lgb_e_st C "$LGB_E_U")"
  is  "$LGB_E_22L" "$(_lgb_e_st lang "$LGB_E_U")"  "$(_lgb_e_st C "$LGB_E_U")"
  is  "$LGB_E_22B" "$(_lgb_e_st all  "3$LGB_E_U")" "$(_lgb_e_st C "3$LGB_E_U")"
  is  "$LGB_E_22M" "$(_lgb_e_st lang "3$LGB_E_U")" "$(_lgb_e_st C "3$LGB_E_U")"
  # Holds on the engine as it was; pins that the fixture is read in this
  # locale at all, and that a fix does not refuse a well-formed answer.
  is  "$LGB_E_22K" "$(_lgb_e_st all 3)|$(_lgb_e_st all 2)" "answered|partial"
else
  for a in "$LGB_E_22A" "$LGB_E_22L" "$LGB_E_22B" "$LGB_E_22M" "$LGB_E_22K"; do skip "$a" "$LCB_NONE"; done
fi

# E23, an arithmetic expansion after the guard. budget.sh: felix_budget_limit
# over project.json's unattended_daily_limit, a person's file. In C a limit
# holding U+2185 is refused and the default ceiling of 10 applies; in UTF-8 the
# guard admits it and cmd_budget's `left=$((limit - used))` aborts the felix
# dispatch line, so `felix budget --record` exits 1 with nothing recorded. That
# is closed for the spend, but the report, the exhaustion check and the record
# are all lost to a value a person typed. The real CLI, in a home, memory and
# checkout of this fragment's own; the limit is written outside the subshell.
LGB_E_BH="$TMP/lgb-e-budget"; LGB_E_BP="$LGB_E_BH/home/projects/lgbe"; LGB_E_BR="$LGB_E_BH/repo"
mkdir -p "$LGB_E_BH/h" "$LGB_E_BH/mem" "$LGB_E_BH/kc" "$LGB_E_BP" "$LGB_E_BR"
printf '# lgbe\n' > "$LGB_E_BP/CLAUDE.md"
( _fx_cd "$LGB_E_BR" && git init -q -b main && printf 'lgbe\n' > .felix ) >/dev/null 2>&1
LGB_E_BR="$(cd "$LGB_E_BR" && pwd -P)" || LGB_E_BR=""
_lgb_e_blim() {  # <limit>: project.json with that daily limit, and an empty ledger
  printf '{\n  "name": "lgbe",\n  "unattended_daily_limit": "%s"\n}\n' "$1" > "$LGB_E_BP/project.json"
  rm -f "$LGB_E_BP/budget.log"
}
_lgb_e_brec() {  # felix budget --record's exit status, in the fragment's checkout
  [ -n "$LGB_E_BR" ] && [ -f "$LGB_E_BR/.felix" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_E_BR" || exit 99
    HOME="$LGB_E_BH/h" FELIX_KERNEL='' FELIX_KERNEL_CACHE="$LGB_E_BH/kc" FELIX_HOME="$LGB_E_BH/home" \
      FELIX_MEMORY="$LGB_E_BH/mem" "$FELIX" budget --record --why lgb-e ) </dev/null >/dev/null 2>&1
  printf 'rc=%s' "$?"
}
_lgb_e_bud() {  # <C|all> <limit>: the record's status and the ledger's line count after it
  _lgb_e_blim "$2"
  printf '%s ledger=%s' "$(_lgb_e_in "$1" _lgb_e_brec)" \
    "$(LC_ALL=C grep -c . "$LGB_E_BP/budget.log" 2>/dev/null || true)"
}
is  "in C, felix budget --record under a daily limit of 1 then U+2185 falls back to the default ceiling and records the run" \
    "$(_lgb_e_bud C "1$LGB_E_U")" "rc=0 ledger=1"
is  "in C, felix budget --record under a daily limit of 3 records the run" "$(_lgb_e_bud C 3)" "rc=0 ledger=1"
LGB_E_23="in a UTF-8 locale, felix budget --record under a daily limit of 1 then U+2185 still falls back to the default ceiling and records the run, as in C"
LGB_E_23K="in a UTF-8 locale, felix budget --record under a daily limit of 3 still records the run"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_E_23"  "$(_lgb_e_bud all "1$LGB_E_U")" "rc=0 ledger=1"
  is  "$LGB_E_23K" "$(_lgb_e_bud all 3)" "rc=0 ledger=1"
else
  for a in "$LGB_E_23" "$LGB_E_23K"; do skip "$a" "$LCB_NONE"; done
fi

# E24, a positive [0-9] case arm. commission.sh: _felix_commission_step_ok's
# `-|[1-9]|10` over commissioning.tsv's step column, a project table a person
# or a session writes. In C a step of U+2185 is malformed and the row is not
# admitted; in UTF-8 the arm admits it, felix_commission_rows takes the row and
# felix_commission_malformed stops naming it, so the gate's commission FAIL,
# the merge blocker built from the malformed list and the receipt's
# indeterminate are all lost. Real library, nothing stubbed. Printed as the
# admitted rows' count, a bar, and the malformed rows' needs.
LGB_E_CP="$TMP/lgb-e-step/projects/lgbe"; mkdir -p "$LGB_E_CP" "$TMP/lgb-e-step/mem"
_lgb_e_step() {  # <step>: the commissioning table, one provider row with that step
  printf 'need_lgb\t-\t-\t-\tprovider:lgb-plug:lgb-skill\t-\t%s\n' "$1" > "$LGB_E_CP/commissioning.tsv"
}
_lgb_e_rows() {  # felix_commission_rows, a bar, then felix_commission_malformed, raw
  ( export FELIX_MEMORY="$TMP/lgb-e-step/mem"
    . "$FROOT/harness/lib/commission.sh"
    felix_commission_rows "$LGB_E_CP"; printf '|\n'; felix_commission_malformed "$LGB_E_CP" ) </dev/null 2>/dev/null
}
_lgb_e_cm() {  # <C|all> <step>: admitted count|malformed needs
  local out; _lgb_e_step "$2"; out="$(_lgb_e_in "$1" _lgb_e_rows)"
  printf '%s|%s' "$(printf '%s\n' "${out%%|*}" | LC_ALL=C grep -c .)" \
    "$(printf '%s\n' "${out#*|}" | LC_ALL=C cut -f1 | LC_ALL=C grep . | LC_ALL=C tr '\n' ' ')"
}
is  "in C, a commissioning row whose step is U+2185 is not admitted and is named malformed" \
    "$(_lgb_e_cm C "$LGB_E_U")" "0|need_lgb "
is  "in C, the same row with step 6 is admitted and nothing is malformed" "$(_lgb_e_cm C 6)" "1|"
LGB_E_24="in a UTF-8 locale, a commissioning row whose step is U+2185 is still not admitted and still named malformed, as in C"
LGB_E_24K="in a UTF-8 locale, the same row with step 6 is still admitted and nothing is malformed"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_E_24"  "$(_lgb_e_cm all "$LGB_E_U")" "0|need_lgb "
  is  "$LGB_E_24K" "$(_lgb_e_cm all 6)" "1|"
else
  for a in "$LGB_E_24" "$LGB_E_24K"; do skip "$a" "$LCB_NONE"; done
fi
# No E25. The contract's third shape is a numeric test after the guard, and
# the sweep's only demonstrated fail-open of that shape is E22's own site:
# audit.sh's month and day tests return 2 and refuse, which is closed, and
# bin/handoff-in-flight's second abort sits in a substitution whose failure
# still exits 2.

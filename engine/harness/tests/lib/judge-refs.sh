# tests/lib/judge-refs.sh: the helpers and fixtures parts 1400 and 1401 share, and the builders that give 1401 the
# state 1400 handed it in the serial run (gate friction C, contract C2). Moved from parts/1400-judge-refs-residue-blind.sh,
# verbatim: lines 17-37 (_jr_commit to _jr_off), 49-55 (_jr_record), 273-289 (_js_entry, _js_dry, _js_refused) and
# 326-342 (_jg_entry, _jg_inst, _jg_check); lines 42-48 (the jrr project) are the body of _jr_project, 257-272 (the
# self-governed checkout JS and its decoy judge) the body of _js_build, and 311-325 (the gate fixture JG) the body of
# _jg_build. Definitions only. Each builder makes its fixture afresh under $TMP and $FROOT; 1400 removes what it built
# at its end, and 1401 builds its own and removes it, so neither reads what the other left.

_jr_commit() {   # REPO MSG [FILE TEXT]: FILE written with TEXT (MSG when none), then one commit of everything
  [ -z "${3:-}" ] || { mkdir -p "$(dirname "$1/$3")"; printf '%s\n' "${4:-$2}" > "$1/$3"; }
  _fx_git "$1" add -A >/dev/null 2>&1
  _fx_git "$1" -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm "$2" >/dev/null 2>&1
}
_jr_sha() { git -C "$1" rev-parse --verify -q "$2^{commit}" 2>/dev/null; }   # REPO REV -> its commit, or nothing
_jr_side() {   # REPO FROM MSG FILE TEXT -> the sha of a commit off FROM writing FILE, on a branch deleted after
  ( _fx_cd "$1" && git checkout -q -b jr-tmp-side "$2" ) >/dev/null 2>&1
  _jr_commit "$1" "$3" "$4" "${5:-}"; _jr_sha "$1" jr-tmp-side
  ( _fx_cd "$1" && git checkout -q - && git branch -q -D jr-tmp-side ) >/dev/null 2>&1
}
_jr_stub() {   # FILE MARKER: FILE ends by defining a felix_accepted_deploy_diff that prints MARKER and exits 0
  printf '\nfelix_accepted_deploy_diff() { printf "%%s\\n" "%s"; return 0; }\n' "$2" >> "$1"
}
_jr_decoy_judge() {   # REPO FROM MARKER -> the sha of a commit off FROM whose resolve.sh always accepts
  ( _fx_cd "$1" && git checkout -q -b jr-tmp-judge "$2" ) >/dev/null 2>&1
  _jr_stub "$1/engine/harness/lib/resolve.sh" "$3"; _jr_commit "$1" decoy-judge; _jr_sha "$1" jr-tmp-judge
  ( _fx_cd "$1" && git checkout -q - && git branch -q -D jr-tmp-judge ) >/dev/null 2>&1
}
_jr_on()  { local r="$1" s="$2" f; shift 2; for f in "$@"; do _fx_git "$r" update-ref "$f" "$s" >/dev/null 2>&1; done; }
_jr_off() { local r="$1" f; shift; for f in "$@"; do _fx_git "$r" update-ref -d "$f" >/dev/null 2>&1; done; }

_jr_project() {   # -> JP: the project jrr, which binds the checkouts the CLI is run in
JP="$FROOT/projects/jrr"; mkdir -p "$JP" "$MEM/jrr"
printf '{\n  "name": "jrr",\n  "remote_match": "example.com/jrr",\n  "gate": "true"\n}\n' > "$JP/project.json"
printf '# jrr\n' > "$JP/CLAUDE.md"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$JP/probes.tsv"
printf 'fixture\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\ta fixture owes one thing, and it holds\n' > "$JP/obligations.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$JP/commissioning.tsv"
cp "$REAL_HARNESS/templates/risk.tsv" "$JP/risk.tsv"
}
_jr_record() {   # REPO: a green gate receipt and a commissioning stamp for the tree as it stands
  ( cd "$1" && . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$1" "$FROOT" 0 "true" "$(felix_tree_id "$1" "$FROOT")" ) >/dev/null 2>&1
  ( cd "$1" && FELIX_HOME_DIR="$FROOT"; . "$FROOT/harness/lib/commission.sh"
    _o="$(felix_commission_run "$JP" "$1" -)"
    felix_commission_receipt_write "$FROOT" "$JP" "$1" "$_o" "" ) >/dev/null 2>&1
}

_js_build() {   # -> JS, JSK, JSR, JS_M, JS_D: the self-governed checkout on jr-prose, and a decoy judge off main
JS="$TMP/jr-sg"; JSK="$JS/kc"; mkdir -p "$JS/repo" "$JS/gh" "$JSK"; JSR="$(cd "$JS/repo" && pwd -P)"
cat > "$JS/gh/gh" <<'JSSTUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GHSTUB_LOG"
# The provider's two reads at the merge (lib/bind.sh, spec S5.2), answered with git at call time from the checkout
# the stub runs in: the pull request open at this HEAD into main, and main at the commit it names here.
case "$*" in
  "pr view "*"--json number,state,baseRefName,headRefOid"*)
    printf '7\tOPEN\t%s\t%s\n' "${GHSTUB_BASE:-main}" "$(git rev-parse HEAD)"; exit 0 ;;
  "api repos/"*"/git/ref/heads/"*)
    n="${2#*/git/ref/heads/}"
    printf 'commit\t%s\n' "$(git rev-parse --verify -q "refs/remotes/origin/$n^{commit}" || git rev-parse --verify -q "refs/heads/$n^{commit}")"
    exit 0 ;;
esac
case "$1 $2" in "pr view") printf '{"number":7,"state":"OPEN"}\n' ;; "pr merge") printf 'merged\n' ;; esac
exit 0
JSSTUB
chmod +x "$JS/gh/gh"
( _fx_cd "$JSR" && git init -q -b main && git remote add origin https://github.com/example/jrr.git ) >/dev/null 2>&1
_copy_content "$REAL_HARNESS" "$JSR/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$JSR/engine/hooks"
[ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$JSR/engine/commands"
printf '*.log\n.DS_Store\n' > "$JSR/.gitignore"; printf 'jrr\n' > "$JSR/.felix"
_jr_commit "$JSR" base engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "1.0.0" }'
JS_M="$(_jr_sha "$JSR" HEAD)"; _jr_on "$JSR" "$JS_M" refs/remotes/origin/main
( _fx_cd "$JSR" && git checkout -q -b jr-prose ) >/dev/null 2>&1; _jr_commit "$JSR" prose NOTES.md 'prose notes'
JS_D="$(_jr_decoy_judge "$JSR" "$JS_M" "$JSK/1.0.0")"
}
_js_entry() {   # -> the cache entry for 1.0.0 is main's engine, cut from the commit
  rm -rf "$JSK/1.0.0" "$JS/x" "$JS/x.tar"; mkdir -p "$JSK/1.0.0" "$JS/x"
  _fx_git "$JSR" archive -o "$JS/x.tar" "$JS_M" engine >/dev/null 2>&1 && tar -x -C "$JS/x" -f "$JS/x.tar"
  for _d in harness hooks commands .claude-plugin; do [ -d "$JS/x/engine/$_d" ] && cp -R "$JS/x/engine/$_d" "$JSK/1.0.0/$_d"; done
  rm -rf "$JS/x" "$JS/x.tar"
}
_js_dry() {   # -> JSRC and $JS/out: felix merge --dry-run in the checkout, a fresh receipt first
  _jr_record "$JSR"; : > "$JS/gh.log"
  ( cd "$JSR" && env -u FELIX_KERNEL PATH="$JS/gh:$PATH" GHSTUB_LOG="$JS/gh.log" FELIX_KERNEL_CACHE="$JSK" \
      "$FELIX" merge --dry-run ) > "$JS/out" 2>&1; JSRC=$?
}
_js_refused() {   # NAME -> ok when the last dry run exited non-zero saying the judge is not the engine main accepted
  local r="" j=""
  [ "$JSRC" -eq 0 ] || r=refused
  ! LC_ALL=C grep -Fq 'the judge is not the engine main accepted' "$JS/out" || j=judge
  if [ "$r|$j" = "refused|judge" ]; then ok "$1"; else bad "$1" "expected [refused|judge] got [$r|$j], exit $JSRC: $(head -8 "$JS/out" | tr '\n' ' ')"; fi
}

_jg_build() {   # -> JG, JGC, JG_ON, and with a gate beside this harness JGT, JG_M, JG_D: the gate's installed fixture
JG="$TMP/jr-gate"; JGC="$JG/home/.claude/plugins/cache/felix/felix"; JG_ON=0
_JRG="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/gate.sh"
if [ -f "$_JRG" ] && grep -q '^# -* tests -*$' "$_JRG"; then
  JG_ON=1; mkdir -p "$JG/tree/engine/.claude-plugin" "$JGC" "$JG/bin"; JGT="$(cd "$JG/tree" && pwd -P)"
  _copy_content "$REAL_HARNESS" "$JGT/engine/harness"; _copy_content "$REAL_HARNESS/../hooks" "$JGT/engine/hooks"
  [ -d "$REAL_HARNESS/../commands" ] && _copy_content "$REAL_HARNESS/../commands" "$JGT/engine/commands"
  printf '*.log\n' > "$JGT/.gitignore"; sed '/^# -* tests -*$/,$d' "$_JRG" > "$JGT/gate.sh"
  ( _fx_cd "$JGT" && git init -q -b main ) >/dev/null 2>&1
  _jr_commit "$JGT" seed engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "0.0.1" }'
  JG_M="$(_jr_sha "$JGT" HEAD)"; _jr_on "$JGT" "$JG_M" refs/remotes/origin/main
  JG_D="$(_jr_decoy_judge "$JGT" "$JG_M" JR-DECOY-ACCEPTS)"
  printf '#!/usr/bin/env bash\ncase "$*" in "plugin list --json") printf '"'"'{ "felix@felix": { "installPath": "%%s" } }\\n'"'"' "%s" ;; esac\nexit 0\n' \
    "$JGC/0.0.1" > "$JG/bin/claude"; chmod +x "$JG/bin/claude"
  printf '{\n  "felix": {\n    "installLocation": "/served/elsewhere"\n  }\n}\n' > "$JG/home/.claude/plugins/known_marketplaces.json"
fi
}
_jg_entry() {   # -> the cache entry for 0.0.1 is main's engine, cut from the commit
  rm -rf "$JGC/0.0.1" "$JG/x" "$JG/x.tar"; mkdir -p "$JGC/0.0.1" "$JG/x"
  _fx_git "$JGT" archive -o "$JG/x.tar" "$JG_M" engine >/dev/null 2>&1 && tar -x -C "$JG/x" -f "$JG/x.tar"
  for _d in harness hooks commands .claude-plugin; do [ -d "$JG/x/engine/$_d" ] && cp -R "$JG/x/engine/$_d" "$JGC/0.0.1/$_d"; done
  rm -rf "$JG/x" "$JG/x.tar"
}
_jg_inst() {   # -> the installed verdict word, then |decoy when the decoy's marker reached the output
  ( cd "$JGT" && unset FELIX_KERNEL FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE
    HOME="$JG/home" PATH="$JG/bin:$PATH" bash gate.sh --quick ) > "$JG/out" 2>&1
  printf '%s|%s' "$(awk '/^  installed/ { print $2; exit }' "$JG/out")" "$(LC_ALL=C grep -c JR-DECOY-ACCEPTS "$JG/out")"
}
_jg_check() {   # NAME WANT -> the installed verdict|marker held to WANT, the installed lines the detail; a skip with no gate
  local v
  if [ "$JG_ON" != 1 ]; then skip "$1" "no projects/felix/gate.sh with a tests marker beside this harness"; return 0; fi
  v="$(_jg_inst)"
  if [ "$v" = "$2" ]; then ok "$1"; else bad "$1" "expected [$2] got [$v]: $(awk '/^  installed/ { on = 1 } on' "$JG/out" | head -6 | tr '\n' ' ')"; fi
}

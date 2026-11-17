# >>> lander-alerts-reach-github
printf '\nthe lander tells the founder through one standing issue on the governed repository (audit b05: C018; B1-B13, R1-R9, blind)\n'
# Blind, written on 2026-10-24 from docs/2026-10-24-audit-fixes/b05-lander-install-guard-and-off-mac-notifie.md
# alone (section 4, A14-A35, fixture F2), and rewritten in its review round on 2026-10-26 from the same file
# (section 9, R1-R9; A16, A18-A20 and A22-A34 restated; A36-A39 new): an alert is a dispatch of felix-alert.yml,
# never a comment made as the gh login. lib/green-tick.sh, lib/green-install.sh, lib/status.sh, lib/notify.sh,
# the hooks and the felix CLI were not read; the CLI's line that sources lib/green-tick.sh is found by 1285's
# pattern only. One assertion per contract item, each a composite of what the item names; fixture controls
# are their own.
# Restated on 2026-10-28 for docs/2026-10-24-audit-fixes/wave-1-combine.md (C1, C2 and its section 5), written
# blind from that file: felix land --pause raises the paused event itself (b02 B22), its record's field 8 drops
# the ; by session suffix, and the brakes --resume, --install and --uninstall alert nothing. A14-A18, the
# control after A17, A24, A26 and A27 keep their A-numbers and what each checks; their names say restated.
#
# F2 is the shared land fixture (_lg_build amend), whose origin is a local path. The GitHub state points the
# home's origin at https://github.com/fixture/lgh.git and rewrites that URL back to the local origin with
# insteadOf, so fetch stays offline; each run then carries GIT_ALLOW_PROTOCOL=file, GH_HOST=evil.example and
# GH_REPO=someone/else. A gh wrapper takes the fixture's gh's place for the part: it logs every call (its kind,
# whether GH_HOST and GH_REPO are set, GH_PROMPT_DISABLED, the argv) to this scenario's log and to the part's,
# keeps the standard input of issue create and issue comment and the argv and body= value of workflow run,
# answers user, repos/fixture/lgh, issue list, issue create, issue comment and workflow run as the contract's
# F2 says (a control file per step makes it exit a status or hang; ctl/workflow makes the workflow missing),
# and hands every other call to the fixture's gh. The part puts all of it back at its end.
_lg_build amend
L20="$LG/alerts20"; rm -rf "$L20"; mkdir -p "$L20/s" "$L20/ctl" "$L20/gitbin" "$L20/noproj" "$L20/nohome/projects"
L20T="$(printf '\t')"; L20CWD="$(pwd -P)"; L20PJ="$LGH/projects/lgh/project.json"; L20PL="$LGH/engine/.claude-plugin/plugin.json"
L20DL='details: felix land --status on the machine that runs the lander'
_fx_git "$LGH" fetch -q origin >/dev/null 2>&1; _fx_git "$LGH" checkout -q main >/dev/null 2>&1
_fx_git "$LGH" reset -q --hard refs/remotes/origin/main >/dev/null 2>&1
L20V="$(_l3_mainv)"; [ -n "$L20V" ] && _lg_cache "$L20V"
cp -p "$L20PJ" "$L20/project.json.keep"; cp -p "$L20PL" "$L20/plugin.json.keep"; command -v git > "$L20/realgit"
_lg_reset; _lg_land --uninstall; _lg_reset
is "the land fixture: the home is on main at origin's main, clean, and main's check accepts its cached entry (fixture control)" \
   "$(git -C "$LGH" rev-parse HEAD 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(_l4_acc refs/remotes/origin/main)" "$(git -C "$LGO" rev-parse main 2>&1)||0"

/bin/mv "$LGB/gh" "$L20/gh.prev"
sed "s#@L20@#$L20#g" > "$LGB/gh" <<'L20GH'
#!/bin/bash
L='@L20@'; C="$L/ctl"; S="$L/s"; mkdir -p "$S"
kind="${1:-} ${2:-}"
case "${1:-}" in
  api) kind="api ?"; for a in "$@"; do case "$a" in user) kind="api user" ;; repos/fixture/lgh) kind="api repos/fixture/lgh" ;; esac; done ;;
  issue) if [ "${2:-}" = comment ]; then n=""; sk=""; i=0
           for a in "$@"; do i=$((i+1)); [ "$i" -le 2 ] && continue
             if [ -n "$sk" ]; then sk=""; continue; fi
             case "$a" in -R|--repo|-F|--body-file|-b|--body|-q|--jq|-t|--template) sk=1 ;; -*) ;; *) [ -n "$n" ] || n="$a" ;; esac
           done; kind="issue comment $n"; fi ;;
esac
h=unset; [ -n "${GH_HOST+x}" ] && h=set; r=unset; [ -n "${GH_REPO+x}" ] && r=set
line="$kind	H=$h	R=$r	P=${GH_PROMPT_DISABLED-unset}"
for a in "$@"; do a="${a//$'\n'/ }"; line="$line	${a//	/ }"; done
printf '%s\t\n' "$line" >> "$S/calls.log"; printf '%s\t\n' "$line" >> "$L/all.log"
step=""
case "$kind" in "api user") step=user ;; "api repos/fixture/lgh") step=repos ;; "issue list") step=list ;;
  "issue create") step=create ;; "issue comment "*) step=comment ;; "workflow run") step=dispatch ;; esac
[ -n "$step" ] || exec "$L/gh.prev" "$@"
jqx=""; bf=""; t=""; prev=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -F|--body-file) bf="$a" ;; -t|--title) t="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --body-file=*) bf="${a#--body-file=}" ;; --title=*) t="${a#--title=}" ;; esac
  prev="$a"
done
k=0
if [ "$step" = create ] || [ "$step" = comment ] || [ "$step" = dispatch ]; then
  [ -f "$S/k" ] && k="$(cat "$S/k")"; k=$((k+1)); printf '%s\n' "$k" > "$S/k"
fi
if [ "$step" = create ] || [ "$step" = comment ]; then
  if [ -n "$bf" ] && [ "$bf" != - ]; then cp "$bf" "$S/body.$k" 2>/dev/null; else cat > "$S/body.$k"; fi
  printf '%s\t%s\n' "$k" "$step" >> "$S/bodies.log"
fi
if [ "$step" = dispatch ]; then
  : > "$S/argv.$k"; pv=""
  for a in "$@"; do
    w="$a"
    case "$pv" in -f|-F|--field|--raw-field) case "$a" in body=*) printf '%s' "${a#body=}" > "$S/body.$k"; w="body=BODY" ;; esac ;; esac
    printf '%s\n' "${w//$'\n'/ }" >> "$S/argv.$k"; pv="$a"
  done
  printf '%s\t%s\n' "$k" dispatch >> "$S/bodies.log"
  if [ -f "$C/workflow" ] || [ "${3:-}" != felix-alert.yml ]; then
    printf 'could not find any workflows named %s\n' "${3:-}" >&2; exit 1
  fi
fi
if [ -f "$C/$step" ]; then
  v="$(cat "$C/$step")"
  if [ "$v" = hang ]; then printf '%s\n' "$$" > "$L/hung.pid"; exec sleep 300; fi
  echo "HTTP 500: the fixture's $step step fails" >&2; exit "$v"
fi
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
login=fixture-bot; [ -f "$C/login" ] && login="$(cat "$C/login")"
case "$step" in
  user) printf '{"login":"%s"}\n' "$login" | out ;;
  repos) fn=fixture/lgh; ty=User; pu=true
    [ -f "$C/full_name" ] && fn="$(cat "$C/full_name")"; [ -f "$C/type" ] && ty="$(cat "$C/type")"; [ -f "$C/push" ] && pu="$(cat "$C/push")"
    printf '{"full_name":"%s","owner":{"login":"fixture","type":"%s"},"permissions":{"admin":false,"maintain":false,"push":%s}}\n' "$fn" "$ty" "$pu" | out ;;
  list) { printf '['; s=""
      if [ -f "$L/issues.tsv" ]; then while IFS='	' read -r n ti au; do
        printf '%s{"number":%s,"title":"%s","author":{"login":"%s"},"state":"OPEN"}' "$s" "$n" "$ti" "$au"; s=","; done < "$L/issues.tsv"; fi
      printf ']\n'; } | out ;;
  create) n=1; [ -f "$L/issues.tsv" ] && n=$(( $(awk 'END { print NR }' "$L/issues.tsv") + 1 ))
    printf '%s\t%s\t%s\n' "$n" "$t" "$login" >> "$L/issues.tsv"
    if [ -f "$C/create.out" ]; then cat "$C/create.out"; else printf 'https://github.com/fixture/lgh/issues/%s\n' "$n"; fi ;;
  comment) printf 'https://github.com/fixture/lgh/issues/%s#issuecomment-%s\n' "${kind##* }" "$k" ;;
  dispatch) printf 'Created workflow_dispatch event for felix-alert.yml at main\n' >&2
    printf 'https://github.com/fixture/lgh/actions/runs/%s\n' "$((k + 900))" | tee "$S/runurl" ;;
esac
exit 0
L20GH
chmod +x "$LGB/gh"; : > "$L20/all.log"
printf '#!/bin/bash\nprintf '"'"'%%s\\n'"'"' "$*" >> '"'"'%s/git.log'"'"'\nexec "$(cat '"'"'%s/realgit'"'"')" "$@"\n' "$L20" "$L20" > "$L20/gitbin/git"
chmod +x "$L20/gitbin/git"

# ---------------------------------------------------------------- helpers ---
_l20_on() { _fx_git "$LGH" config remote.origin.url https://github.com/fixture/lgh.git >/dev/null 2>&1
            _fx_git "$LGH" config "url.$LGO.insteadOf" https://github.com/fixture/lgh.git >/dev/null 2>&1; }
_l20_off() { _fx_git "$LGH" config remote.origin.url "$LGO" >/dev/null 2>&1; _fx_git "$LGH" config --unset-all "url.$LGO.insteadOf" >/dev/null 2>&1; }
_l20_clear() { rm -rf "$L20/s"; mkdir -p "$L20/s"; : > "$L20/git.log"; }
_l20_reset() {   # [gh] -> land state, wrapper controls, issues and scenario log emptied; with gh, the GitHub state
  _lg_reset; rm -rf "$L20/ctl" "$L20/issues.tsv" "$L20/hung.pid"; mkdir -p "$L20/ctl"; _l20_clear
  if [ "${1:-}" = gh ]; then _l20_on; LGX=(GIT_ALLOW_PROTOCOL=file GH_HOST=evil.example GH_REPO=someone/else); else _l20_off; fi
}
_l20_pj() {   # [ALERT-LOGIN] -> projects/lgh/project.json as kept, with alert_login when given
  if [ -z "${1:-}" ]; then cp -p "$L20/project.json.keep" "$L20PJ"; return 0; fi
  printf '{\n  "name": "lgh",\n  "remote_match": "github.com/fixture/lgh",\n  "gate": "true",\n  "alert_login": "%s"\n}\n' "$1" > "$L20PJ"
}
_l20_ev() { _lg_land --pause "$1"; L20PRC="$LGRC"; _lg_land --tick; }   # REASON -> one paused event: --pause REASON (its status L20PRC), then --tick
# REASON -> a new paused event after one: --resume, --pause, the ledger aged past the hour, --tick. Since b02 the
# --pause raises the event (wave-1-combine.md C1); the aged tick then writes its hourly paused row for the same
# reason, the same event raised again (the control after A17 counts its row).
_l20_next() { _lg_land --resume; _lg_land --pause "$1"; _l20_age; _lg_land --tick; }
_l20_age() {   # the ledger's rows a year older, so the newest paused row is past its hour (1280's G2 reading)
  [ -f "$LAND/ledger.tsv" ] || return 0
  LC_ALL=C awk -F'\t' -v OFS='\t' -v y="$(date -u +%Y)" '{ if (index($1, y)) sub(y, y - 1, $1); print }' "$LAND/ledger.tsv" > "$LAND/ledger.aged" \
    && /bin/mv "$LAND/ledger.aged" "$LAND/ledger.tsv"
}
_l20_kinds() { [ -f "$L20/s/calls.log" ] && LC_ALL=C awk -F'\t' '{ printf "%s%s", s, $1; s = "," }' "$L20/s/calls.log"; }   # -> this scenario's calls, by kind
_l20_nk() { if [ -f "$L20/s/calls.log" ]; then LC_ALL=C awk -F'\t' -v r="$1" '$1 ~ r { n++ } END { print n + 0 }' "$L20/s/calls.log"; else echo 0; fi; }   # REGEX -> calls of that kind
_l20_lack() {   # KIND-REGEX VALUE OPT... -> calls of that kind that carry none of OPT VALUE, OPT=VALUE
  [ -f "$L20/s/calls.log" ] || { echo 0; return; }
  LC_ALL=C awk -F'\t' -v r="$1" -v v="$2" -v o="${*:3}" 'BEGIN { m = split(o, os, " ") }
    $1 ~ r { f = 0; for (i = 5; i <= NF; i++) for (j = 1; j <= m; j++) if (($i == os[j] && $(i + 1) == v) || $i == os[j] "=" v) f = 1; if (!f) n++ }
    END { print n + 0 }' "$L20/s/calls.log"
}
_l20_cb() { [ -f "$L20/s/bodies.log" ] && LC_ALL=C awk -F'\t' -v d="$L20/s" '$2 == "dispatch" { print d "/body." $1 }' "$L20/s/bodies.log"; }   # -> each dispatch's BODY file
_l20_crb() { [ -f "$L20/s/bodies.log" ] && LC_ALL=C awk -F'\t' -v d="$L20/s" '$2 == "create" { print d "/body." $1; exit }' "$L20/s/bodies.log"; }   # -> the first issue create's body file
_l20_av() {   # -> the first dispatch's argv, one space between, its body= value written BODY
  local k; k="$([ -f "$L20/s/bodies.log" ] && LC_ALL=C awk -F'\t' '$2 == "dispatch" { print $1; exit }' "$L20/s/bodies.log")"
  [ -n "$k" ] && LC_ALL=C awk '{ printf "%s%s", s, $0; s = " " }' "$L20/s/argv.$k" 2>/dev/null
}
_l20_lines() { [ -f "${1:-/nonexistent}" ] && LC_ALL=C awk '{ printf "%s%s", s, $0; s = "|" }' "$1"; }   # FILE -> its lines, joined by |
_l20_l1s() { local b; _l20_cb | while IFS= read -r b; do printf '%s|' "$(sed -n 1p "$b")"; done; }   # -> each BODY's line 1, then |
_l20_body() { local b; _l20_cb | while IFS= read -r b; do case "$(sed -n 1p "$b")" in "$1"*) printf '%s' "$b"; break ;; esac; done; }   # LINE1-PREFIX -> that BODY's file
_l20_n() { if [ -f "$LAND/alerts.tsv" ]; then LC_ALL=C awk -F'\t' -v k="${1:-}" 'k == "" || $2 == k { n++ } END { print n + 0 }' "$LAND/alerts.tsv"; else echo 0; fi; }   # [STATE] -> records
_l20_f() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' -v r="$1" -v k="$2" 'r == "last" || NR == r + 0 { v = $k } END { printf "%s", v }' "$LAND/alerts.tsv"; }   # ROW|last FIELD
_l20_nf() { [ -f "$LAND/alerts.tsv" ] && LC_ALL=C awk -F'\t' '{ printf "%s%s", s, NF; s = "," }' "$LAND/alerts.tsv"; }   # -> each record's field count
_l20_starts() { case "$1" in "$2"*) printf ok ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT PREFIX -> ok, or the text
_l20_in() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT NEEDLE TAG -> TAG when TEXT holds NEEDLE, or the text
_l20_lacks() { case "$1" in *"$2"*) printf '[%s]' "$1" ;; *) printf '%s' "$3" ;; esac; }   # TEXT NEEDLE TAG -> TAG when TEXT lacks NEEDLE, or the text
_l20_yn() { case "$1" in *"$2"*) printf '%s' "$3" ;; *) printf 'no-%s' "$3" ;; esac; }   # TEXT NEEDLE TAG -> TAG when TEXT holds NEEDLE, else no-TAG
_l20_like() { case "$1" in $2) printf '%s' "$3" ;; *) printf '[%s]' "$1" ;; esac; }   # TEXT GLOB TAG -> TAG when TEXT matches GLOB, or the text
_l20_osa() { _lg_logs osa | LC_ALL=C grep -c "with title \"Felix: $1" ; }   # TITLE -> banners sent with it
_l20_tramp() {   # HOME-DIR [PATH-PREFIX] -> the trampoline as launchd runs it, FELIX_HOME_DIR as given; status in LARC
  ( cd "$TMP/cwd" 2>/dev/null || cd "$LG" || exit 97
    exec env -i HOME="$LGU" FELIX_HOME_DIR="$1" PATH="${2-}$LGB:$PATH" GIT_CEILING_DIRECTORIES="${GIT_CEILING_DIRECTORIES-}" \
      "$LATR" ) > "$LG/out.tramp" 2>&1
  LARC=$?
}
_l20_felix() {   # HOME-DIR ARGS... -> felix ARGS from the home's checkout with that home; stdout $LG/out, stderr $LG/err
  local hd="$1"; shift
  ( cd "$LGH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$hd" \
      FELIX_HOME_DIR="$hd" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" "$@" ) > "$LG/out" 2> "$LG/err"
  LGRC=$?
}
L20F="$FROOT/harness/felix-l20fn"
LC_ALL=C awk '{ print } index($0, ". \"${SCRIPT_DIR}/lib/green-tick.sh\"") == 1 && !d { print "_FN_SECS=2"; d = 1 }' "$FELIX" > "$L20F" && chmod +x "$L20F"
_l20_slow() {   # ARGS... -> the patched CLI's felix ARGS in a process group of its own, ended at 20 seconds (124); L20RC, L20EL seconds
  local p n=0 t0="$SECONDS"
  ( cd "$LGH" || exit 97
    exec perl -e 'setpgrp(0, 0); exec @ARGV or exit 127' env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE \
      ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$LGH" FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" \
      PATH="$LGB:$PATH" "$L20F" "$@" ) > "$LG/out.slow" 2>&1 &
  p=$!
  while kill -0 "$p" 2>/dev/null && [ "$n" -lt 200 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$p" 2>/dev/null; then kill -KILL -- "-$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null; L20RC=124
  else wait "$p"; L20RC=$?; fi
  L20EL=$(( SECONDS - t0 ))
}
_l20_hung() {   # -> alive or gone: the pid the hung step wrote, given two seconds to be reaped
  local h n=0; h="$(cat "$L20/hung.pid" 2>/dev/null)"
  [ -n "$h" ] || { echo "no-hang"; return; }
  while kill -0 "$h" 2>/dev/null && [ "$n" -lt 20 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$h" 2>/dev/null; then kill -KILL "$h" 2>/dev/null; echo alive; else echo gone; fi
}

is "the land fixture: a copy of the CLI sets _FN_SECS=2 on the line after it sources lib/green-tick.sh, and differs in nothing else (fixture control)" \
   "$(LC_ALL=C awk 'p && $0 == "_FN_SECS=2" { n++ } { p = (index($0, ". \"${SCRIPT_DIR}/lib/green-tick.sh\"") == 1) } END { print n + 0 }' "$L20F" 2>&1)|$(diff "$FELIX" "$L20F" 2>&1 | LC_ALL=C grep -c '^[<>]')" "1|1"
_l20_reset gh
if command -v jq >/dev/null 2>&1; then
  is "the land fixture: the gh wrapper answers user and repos as F2 says, applies --jq, and hands auth status to the fixture's gh (fixture control)" \
     "$(PATH="$LGB:$PATH" gh api --hostname github.com user --jq .login)|$(PATH="$LGB:$PATH" gh api --hostname github.com repos/fixture/lgh --jq '[.full_name, .owner.login, .owner.type, .permissions.push] | join(" ")')|$(PATH="$LGB:$PATH" gh auth status >/dev/null 2>&1; echo $?)|$(_lg_cnt gh)" \
     "fixture-bot|fixture/lgh fixture User true|0|1"
else skip "the land fixture: the gh wrapper answers user and repos as F2 says, applies --jq, and hands auth status to the fixture's gh (fixture control)" "no jq"; fi
_l20_reset gh
L20W1="$(PATH="$LGB:$PATH" gh workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body="$(printf 'one\ntwo')" 2>/dev/null; echo "rc=$?")"
: > "$L20/ctl/workflow"; L20W2="$(PATH="$LGB:$PATH" gh workflow run felix-alert.yml --repo x -f issue=1 -f body=b 2>&1 >/dev/null; echo "rc=$?")"
is "the land fixture: the gh wrapper answers workflow run felix-alert.yml with a run URL, keeps its argv and BODY by line, and with ctl/workflow says gh's not-found line and exits 1 (fixture control)" \
   "$(printf '%s' "$L20W1" | tr '\n' ' ')|$(_l20_lines "$(_l20_cb | head -n 1)")|$(_l20_av)|$(printf '%s' "$L20W2" | tr '\n' ' ')" \
   "https://github.com/fixture/lgh/actions/runs/901 rc=0|one|two|workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body=BODY|could not find any workflows named felix-alert.yml rc=1"
_l20_reset gh; : > "$L20/all.log"
is "the land fixture: in the GitHub state the origin reads as github.com, fetch stays on the local origin, and felix land --status --tsv from the home still exits 0 (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(GIT_ALLOW_PROTOCOL=file git -C "$LGH" ls-remote origin refs/heads/main 2>&1 | cut -f1)|$(_lg_land --status --tsv; echo "$LGRC")" \
   "https://github.com/fixture/lgh.git|$(git -C "$LGO" rev-parse main 2>&1)|0"

# ------------------------------------------------------------ B2, B7 ---
# Restated for wave-1-combine.md C1: the --pause writes the one paused row and makes the one attempt; the tick
# within the hour adds neither, and field 8 is the reason without ; by session -.
_l20_reset; _l20_ev r1
is "A14 (B2, control; restated for wave-1-combine.md C1): with the origin a local path, --pause then --tick writes one paused row, the pause's, sends one banner titled Felix: paused, and asks gh nothing" \
   "$(_lg_n paused)|$(_l20_osa paused)|fixture-gh=$(_lg_cnt gh)|wrapper=$(_l20_nk .)" "1|1|fixture-gh=0|wrapper=0"
is "A15 (B2, B7; restated for wave-1-combine.md C1): and that run appends one eight-field alerts.tsv record, failed, of kind paused, whose note starts origin:, holding no text of the origin URL, its field 8 the reason r1 alone" \
   "$(_l20_n)|$(_l20_nf)|$(_l20_f 1 2)|$(_l20_f 1 3)|$(_l20_starts "$(_l20_f 1 7)" origin:)|$(LC_ALL=C grep -cF "$LGO" "$LAND/alerts.tsv" 2>/dev/null)|$(_l20_f 1 8)" "1|8|failed|paused|ok|0|r1"

# ------------------------------------------------- B3, B5, R1, R2, R3 ---
_l20_reset gh; _l20_ev "held for the alerts test"
L20B="$(_l20_body "@")"; L20CB="$(_l20_crb)"
# Restated for wave-1-combine.md C1: the calls are the --pause's, and the tick within the hour makes none.
is "A16 (B3, B5, R1-R3; restated for wave-1-combine.md C1): a paused event raised by --pause in the GitHub state, then a tick, calls user, repos, issue list, issue create and workflow run, in that order and no more, with the title, --state all, --repo github.com/fixture/lgh, GH_HOST and GH_REPO unset and the dispatch's GH_PROMPT_DISABLED=1; creates the issue with no @ and no detail; dispatches exactly felix-alert.yml with issue=1 and BODY @fixture Felix land: paused, empty, the paused sentence, the details line; and records it dispatched on fixture/lgh#1 with the run URL, through felix-alert.yml mentioning @fixture, the detail in field 8" \
   "$(_l20_kinds)|title-lacking=$(_l20_lack '^issue create' 'Felix needs you' --title -t)|state-lacking=$(_l20_lack '^issue list' all --state -s)|repo-lacking=$(_l20_lack '^issue ' github.com/fixture/lgh --repo -R)|env-set=$(LC_ALL=C awk -F'\t' '$1 ~ /^(api|issue|workflow) / && ($2 != "H=unset" || $3 != "R=unset") { n++ } END { print n + 0 }' "$L20/s/calls.log" 2>/dev/null)|prompt-unset=$(LC_ALL=C awk -F'\t' '$1 ~ /^workflow / && $4 != "P=1" { n++ } END { print n + 0 }' "$L20/s/calls.log" 2>/dev/null)|create-body=$(LC_ALL=C grep -c '@' "$L20CB" 2>/dev/null),$(_l20_yn "$(cat "$L20CB" 2>/dev/null)" "alerts test" detail)|$(_l20_av)|$(_l20_lines "$L20B")|$(_l20_n)|$(_l20_nf)|$(_l20_f 1 2) $(_l20_f 1 3) $(_l20_f 1 4) $(_l20_f 1 5)|$(if [ -n "$(_l20_f 1 6)" ] && [ "$(_l20_f 1 6)" = "$(cat "$L20/s/runurl" 2>/dev/null)" ]; then echo run-url; else printf '[%s]' "$(_l20_f 1 6)"; fi)|$(_l20_f 1 7)|$(_l20_f 1 8)" \
   "api user,api repos/fixture/lgh,issue list,issue create,workflow run|title-lacking=0|state-lacking=0|repo-lacking=0|env-set=0|prompt-unset=0|create-body=0,no-detail|workflow run felix-alert.yml --repo github.com/fixture/lgh -f issue=1 -f body=BODY|@fixture Felix land: paused||Landing is paused until felix land --resume.|$L20DL|1|8|dispatched paused - fixture/lgh#1|run-url|through felix-alert.yml mentioning @fixture|held for the alerts test"
_l20_felix "$LGH" status --tsv; L20S2="$(LC_ALL=C awk -F'\t' '$1 == "alerts"' "$LG/out")"; L20S2F6="$(_l20_f last 6)"
_l20_felix "$LGH" status; L20S2P="$(cat "$LG/out")"

# ---------------------------------------------------------------- B8 ---
# Restated for wave-1-combine.md C1: the tick's hourly row carries the reason alone, the detail the --pause's attempt recorded.
_l20_age; _l20_clear; _lg_land --tick
is "A17 (B8; restated for wave-1-combine.md C1): the tick's hourly paused row past its hour, for the reason the --pause gave, is the same event: one more paused row and banner, but no gh call and no second record" \
   "$(_lg_n paused)|$(_l20_osa paused)|$(_l20_nk .)|$(_l20_n)" "2|2|0|1"

# ------------------------------------------------------------ B5, B1 ---
# Restated for wave-1-combine.md C1 and C2: --pause r2 is the new event; the --resume before it and the aged tick's
# r2 row after it add no attempt that sends.
_l20_clear; _l20_next r2
is "the land fixture: --resume, --pause r2, the ledger aged past the hour and --tick write two more paused rows, the pause's and the aged tick's (fixture control; restated for wave-1-combine.md C1)" "$(_lg_n paused)" "4"
is "A18 (B5, B1; restated for wave-1-combine.md C1, C2): the --pause with a new reason dispatches once for the standing issue, issue 1, without creating another; the resume and the aged tick's same event add nothing, so two records, both dispatched" \
   "create=$(_l20_nk '^issue create')|dispatch=$(_l20_nk '^workflow run')|$(_l20_yn "$(_l20_av)" ' -f issue=1 ' issue-1)|dispatched=$(_l20_n dispatched)|records=$(_l20_n)" "create=0|dispatch=1|issue-1|dispatched=2|records=2"

# ------------------------------------------------------------ B1, R2 ---
_l20_reset gh; printf '1\n' > "$LGK/gh-auth.rc"; _lg_land --tick
is "A19 (B1, R2): a tick whose gh auth status fails writes one gh row and dispatches @fixture Felix land: gh with the gh sentence" \
   "$(_lg_n gh)|$(_l20_l1s)|$(sed -n 3p "$(_l20_body "@fixture Felix land: gh")" 2>&1)" "1|@fixture Felix land: gh||gh auth status failed, so nothing lands."
_l20_reset gh; _lg_prs "$(_lg_pr 42)" "$(_lg_pr 41)"; _lg_green 41 42
printf 'felix merge: refused\n  blocker one: the receipt is stale\n' > "$LGK/merge.b41.out"; printf '1\n' > "$LGK/merge.b41.rc"
printf 'merged\n' > "$LGK/merge.b42.out"; _lg_land --tick
is "the land fixture: the tick over 41 and 42 refused 41 and landed 42 (fixture control)" "$(_lg_n refused 41)|$(_lg_n landed 42)" "1|1"
L20B="$(_l20_body "@fixture Felix land: refused #41")"; L20B2="$(_l20_body "@fixture Felix land: landed #42")"
is "A20 (B1, R2): a refused and a landed pull request each get a dispatch: @fixture Felix land: refused #41 with the refused sentence and none of the refusal's text, and @fixture Felix land: landed #42 with the landed sentence" \
   "$(sed -n 1p "$L20B" 2>&1)|$(sed -n 3p "$L20B" 2>&1)|$(_l20_yn "$(cat "$L20B" 2>/dev/null)" "blocker one" blocker)|$(_l20_yn "$(cat "$L20B" 2>/dev/null)" " [main " main)|$(sed -n 1p "$L20B2" 2>&1)|$(sed -n 3p "$L20B2" 2>&1)" \
   "@fixture Felix land: refused #41|felix merge refused a green pull request.|no-blocker|no-main|@fixture Felix land: landed #42|A green pull request was merged into main."
_l20_reset gh; _lg_prs "$(_lg_pr 21 true)"; _lg_green 21; _lg_land --tick
is "A21 (B1): a skip row is no event: a draft pull request gets its skip row and no api, issue or workflow call" \
   "$(_lg_n skip 21)|$(_l20_nk '^(api|issue|workflow) ')" "1|0"

# ------------------------------------------------------------ B4, R8 ---
_l20_b4() {   # CASE PREFIX -> after one paused event: CASE:prefix-or-text,failed/records,creates+dispatches-or-comments,calls
  _l20_ev "a22 $1"
  printf '%s:%s,%s,%s+%s,%s;' "$1" "$(_l20_starts "$(_l20_f last 7)" "$2")" "$(_l20_n failed)/$(_l20_n)" \
    "$(_l20_nk '^issue create')" "$(_l20_nk '^(issue comment|workflow run)')" "$(_l20_kinds)"
}
L20A22=""
_l20_reset gh; printf 'fixture/other\n' > "$L20/ctl/full_name"; L20A22="$L20A22$(_l20_b4 full_name full_name:)"
_l20_reset gh; printf 'false\n' > "$L20/ctl/push"; L20A22="$L20A22$(_l20_b4 push permission:)"
_l20_reset gh; printf 'Organization\n' > "$L20/ctl/type"; L20A22="$L20A22$(_l20_b4 org owner:)"
_l20_reset gh; _l20_pj "bad login"; L20A22="$L20A22$(_l20_b4 login alert_login:)"; _l20_pj
_l20_reset gh; printf 'https://github.com/fixture/other/issues/1\n' > "$L20/ctl/create.out"; L20A22="$L20A22$(_l20_b4 create 'gh issue create:')"
_l20_reset gh; printf '1\n' > "$L20/ctl/user"; L20A22="$L20A22$(_l20_b4 user 'gh api user:')"
L20A22="$L20A22$(_l20_in "$(_l20_f last 7)" "exited 1" exited-1)"
# Review round (M1, R8): the create case makes its one issue create, which B4 then judges, so its count is 1+0.
is "A22 (B4, R8): the alert is refused and recorded failed, with no dispatch or comment, when GitHub names another repository, the account cannot push, the owner is an organization with no alert_login, alert_login is not a login (no gh call at all), create answers another repository's issue (after its one issue create), or gh api user exits 1 (exited 1, no later call)" \
   "$L20A22" \
   "full_name:ok,1/1,0+0,api user,api repos/fixture/lgh;push:ok,1/1,0+0,api user,api repos/fixture/lgh;org:ok,1/1,0+0,api user,api repos/fixture/lgh;login:ok,1/1,0+0,;create:ok,1/1,1+0,api user,api repos/fixture/lgh,issue list,issue create;user:ok,1/1,0+0,api user;exited-1"

# ------------------------------------------------------------ R2, R4 ---
_l20_reset gh; _l20_pj someone-else; _l20_ev a23; _l20_pj
is "A23 (R2): with alert_login someone-else in project.json the dispatch mentions @someone-else" \
   "$(_l20_starts "$(_l20_l1s)" '@someone-else Felix land:')" "ok"
# Restated for wave-1-combine.md C1, C2 and R4: with the dispatch failing, --pause r24a, --pause r24b and the aged
# tick's r24b row (the same event, attempted again since no record of it was dispatched) leave three failed records,
# and the resumes none; --pause r24c is then dispatched, counting the three, and the aged tick's r24c row adds nothing.
_l20_reset gh; printf '1\n' > "$L20/ctl/dispatch"; _l20_ev r24a; _l20_next r24b; rm -f "$L20/ctl/dispatch"; _l20_next r24c
L20NL="Not delivered before this one: 3 (the newest: $(_l20_f 3 3) at $(_l20_f 3 1))."; L20B="$(_l20_cb | tail -n 1)"
is "A24 (R2-R4; restated for wave-1-combine.md C1, C2): three attempts whose dispatch fails leave three failed records noting gh workflow run:, and the next event, dispatched, says on line 4 Not delivered before this one: 3 with the newest's kind and time, then the details line; four records in all" \
   "$(_l20_f 1 2) $(_l20_f 2 2) $(_l20_f 3 2) $(_l20_f 4 2)|$(_l20_n)|$(_l20_starts "$(_l20_f 1 7)" 'gh workflow run:')$(_l20_starts "$(_l20_f 2 7)" 'gh workflow run:')$(_l20_starts "$(_l20_f 3 7)" 'gh workflow run:')|$(sed -n 4p "$L20B" 2>&1)|$(sed -n 5p "$L20B" 2>&1)" \
   "failed failed failed dispatched|4|okokok|$L20NL|$L20DL"
# The token is put together at run time, so no token-shaped text is written in this file.
L20TOK="ghp_$(printf '%s%s%s%s' a1B2c3D4e5 f6G7h8I9j0 k1L2m3N4o5 p6Q7r8)"
_l20_reset gh; _l20_ev "$L20TOK $LGU/x and a@b"; L20B="$(_l20_cb | head -n 1)"
is "A25 (R2, B7): a detail holding a token, \$HOME/ and an @ reaches no gh argument and no body; BODY's one @ is line 1's; field 8 keeps the detail with ~/" \
   "argv=$(_l20_yn "$(cat "$L20/s/calls.log" 2>/dev/null)" "$L20TOK" token)|bodies=$(cat "$L20/s/body."* 2>/dev/null | LC_ALL=C grep -cF -e "$L20TOK" -e "$LGU" -e 'x and' -e 'a@b')|at=$(LC_ALL=C grep -c '@' "$L20B" 2>/dev/null)/$(sed -n 1p "$L20B" 2>/dev/null | LC_ALL=C grep -c '^@fixture Felix land: paused')|field8=$(_l20_yn "$(_l20_f last 8)" '~/x and a@b' home-folded)" \
   "argv=no-token|bodies=0|at=1/1|field8=home-folded"

# ---------------------------------------------------------------- B9 ---
# Restated for wave-1-combine.md C1: the --pause raises the event, so the patched CLI's --pause meets the hang.
_l20_reset gh; printf 'hang\n' > "$L20/ctl/dispatch"; _l20_slow land --pause r9
is "A26 (B9; restated for wave-1-combine.md C1): with _FN_SECS=2 and the dispatch hanging, --pause r9 exits 0 within 20 seconds, the hung gh is no longer running, and one failed record says timed out" \
   "$L20RC|$([ "$L20EL" -le 20 ] && echo within || echo "took-$L20EL")|$(_l20_hung)|$(_l20_n failed)/$(_l20_n)|$(_l20_in "$(_l20_f last 7)" "timed out" timed-out)" \
   "0|within|gone|1/1|timed-out"

# --------------------------------------------------------------- B10 ---
# Restated for wave-1-combine.md C1: the row is the --pause's, its detail ending ; by session - (0004 unsets the
# session id), and the exit statuses are the --pause's and the tick's; the hang is met by the patched --pause.
_l20_b10() { printf 'n=%s;%s;osa=%s;rc=%s' "$(_lg_rows)" "$(cut -f2-7 "$LAND/ledger.tsv" 2>/dev/null | tr '\n' '|')" "$(_lg_cnt osa)" "$1"; }
_l20_reset; _l20_ev "r27 the same pause"; L20K1="$(_l20_b10 "$L20PRC/$LGRC")"
_l20_reset gh; printf '1\n' > "$L20/ctl/user"; _l20_ev "r27 the same pause"; L20K2="$(_l20_b10 "$L20PRC/$LGRC")"
_l20_reset gh; printf 'hang\n' > "$L20/ctl/dispatch"; _l20_slow land --pause "r27 the same pause"; L20PRC="$L20RC"
_l20_slow land --tick; L20K3="$(_l20_b10 "$L20PRC/$L20RC")"; _l20_hung >/dev/null
is "A27 (B10; restated for wave-1-combine.md C1): the paused scenario writes the same ledger fields 2-7, the --pause's one row ending ; by session -, one banner and exit 0 for --pause and --tick, with a local origin, with gh api user failing, and with the dispatch hanging" \
   "$(_l20_like "$L20K1" "n=1;paused$L20T-$L20T-$L20T-$L20T*${L20T}r27 the same pause; by session -|;osa=1;rc=0/0" one-paused-row) // $L20K2 // $L20K3" \
   "one-paused-row // $L20K1 // $L20K1"

# ----------------------------------------------------------- B11, R7 ---
_l20_reset gh; _lg_land --install; L20I="$LGRC|$(_l20_nk .)"; _l20_clear; _l20_tramp "$L20/no-home"
is "A28 (B11, R7): --install calls no gh; the trampoline with a home that does not exist exits 1, writes one deploy-owed row, dispatches @fixture Felix land: deploy-owed once with the deploy-owed sentence, and records it dispatched" \
   "$L20I|$LARC|$(_lg_n deploy-owed)|$(_l20_l1s)|$(sed -n 3p "$(_l20_body "@fixture Felix land: deploy-owed")" 2>&1)|$(_l20_f last 2) $(_l20_f last 3)" \
   "0|0|1|1|@fixture Felix land: deploy-owed||A deploy of main is owed and has not run, so nothing lands.|dispatched deploy-owed"
# A31 follows A28 with no reset between: the tick's attempt rewrites alerts.repo from a local origin.
_l20_off; _l20_ev r31; _l20_clear; _l20_tramp "$L20/no-home"
is "the land fixture: after the paused tick the trampoline wrote its deploy-owed row again, the ledger's newest (fixture control)" \
   "$(tail -n 1 "$LAND/ledger.tsv" 2>/dev/null | cut -f2)" "deploy-owed"
is "A31 (B11): once a tick with a local origin rewrote alerts.repo, the trampoline calls no gh and its newest record is failed" \
   "$(_l20_nk .)|$(_l20_f last 2)" "0|failed"
_l20_reset gh; _lg_land --install; /bin/mv "$L20PL" "$L20/plugin.json.moved"; mkdir "$L20PL"
_l20_clear; _l20_tramp "$LGH" "$L20/gitbin:"; rm -rf "$L20PL"; cp -p "$L20/plugin.json.keep" "$L20PL"
is "A29 (B11, R7): with plugin.json unopenable the trampoline dispatches @fixture Felix land: unreadable with the unreadable sentence and runs no git" \
   "$(_l20_l1s)|$(sed -n 3p "$(_l20_body "@fixture Felix land: unreadable")" 2>&1)|git=$(if [ -f "$L20/git.log" ]; then LC_ALL=C awk 'END { print NR }' "$L20/git.log"; else echo none; fi)" \
   "@fixture Felix land: unreadable||The lander could not read the home, so nothing lands.|git=0"
_l20_reset gh; _lg_land --install
printf ': > "%s/tripwire"\n' "$L20" > "$LGH/engine/harness/lib/notify.sh"; cp "$LGH/engine/harness/lib/notify.sh" "$LGV/$L20V/harness/lib/notify.sh"
is "the land fixture: the tripwire notify.sh is untracked in the home and sits in main's cache entry (fixture control)" \
   "$(git -C "$LGH" status --porcelain -- engine 2>&1)|$([ -f "$LGV/$L20V/harness/lib/notify.sh" ] && echo cached)" "?? engine/harness/lib/notify.sh|cached"
_l20_clear; _l20_tramp "$LGH"
is "A30 (B11): the trampoline sources no notify.sh from the home or the cache: its deploy-owed row names the untracked file, it dispatches, and the tripwire is never written" \
   "$(_l20_in "$(_lg_f deploy-owed "" 7)" lib/notify.sh names-it)|$(_l20_l1s)|$([ -e "$L20/tripwire" ] && echo tripped || echo untouched)" \
   "names-it|@fixture Felix land: deploy-owed||untouched"
rm -f "$LGH/engine/harness/lib/notify.sh" "$LGV/$L20V/harness/lib/notify.sh" "$L20/tripwire"

# --------------------------------------------------------------- B12 ---
_l20_reset gh; _l20_ev a32; _lg_land --resume; L20M0="$(find "$LGM" -name alerts.tsv 2>/dev/null | LC_ALL=C sort)|$(cksum < "$LAND/alerts.tsv" 2>/dev/null)"
L20M1="$([ -s "$LAND/alerts.tsv" ] && echo record || echo no-record)"
_l20_clear
( cd "$L20/noproj" || exit 97
  exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u FELIX_LAND_LEDGER ${LGX[@]+"${LGX[@]}"} HOME="$LGU" FELIX_HOME="$LGH" \
    FELIX_HOME_DIR="$LGH" FELIX_MEMORY="$LGM" FELIX_PLUGIN_CACHE="$LGC" PATH="$LGB:$PATH" "$FELIX" land --tick ) > "$LG/out" 2>&1
is "A32 (B12): a hand-run tick that resolves no project, with no FELIX_LAND_LEDGER, makes no gh call and writes no alerts record anywhere" \
   "$L20M1|$(_l20_nk '^(api|issue|workflow) ')|$(find "$LGM" -name alerts.tsv 2>/dev/null | LC_ALL=C sort)|$(cksum < "$LAND/alerts.tsv" 2>/dev/null)" "record|0|$L20M0"

# ----------------------------------------------------------- B13, R5 ---
# Review round (M2, R9): _l20_st sets L20SR, L20SD and L20ST in the caller's shell, so it is never called inside $( ).
_l20_st() {   # [HOME-DIR] -> felix status --tsv's alerts row: L20SR the row, L20SD its detail, L20ST its state and value, and whether the run wrote or called anything
  local s0; s0="$(_lgsnap)"; _l20_clear; _l20_felix "${1:-$LGH}" status --tsv
  L20SR="$(LC_ALL=C awk -F'\t' '$1 == "alerts"' "$LG/out")"
  L20ST="$(printf '%s' "$L20SR" | LC_ALL=C cut -f2) $(printf '%s' "$L20SR" | LC_ALL=C cut -f3)"
  L20SD="$(printf '%s' "$L20SR" | LC_ALL=C cut -f4)"
  [ "$(_lgsnap)" = "$s0" ] || L20ST="$L20ST (wrote)"; [ "$(_l20_nk .)" = 0 ] || L20ST="$L20ST (called gh)"
}
_l20_has() { [ -n "$2" ] || { printf '[nothing to look for]'; return 0; }; case "$1" in *"$2"*) printf ok ;; *) printf '[%s lacks %s]' "$1" "$2" ;; esac; }
_l20_reset gh; L20A33="rows=$(_l20_felix "$LGH" status --tsv; cut -f1 "$LG/out" | tr '\n' ' ')"
_l20_st; L20A33="$L20A33|none=$L20ST"
L20A33="$L20A33|dispatched=$(printf '%s' "$L20S2" | cut -f2,3 | tr '\t' ' ') $(_l20_has "$(printf '%s' "$L20S2" | cut -f4)" "$L20S2F6")"
L20A33="$L20A33|plain=$(_l20_has "$L20S2P" "$(printf '%s\n' "$L20S2" | LC_ALL=C awk -F'\t' '{ s = ($2 == "value") ? $3 : $2; printf "%-9s %-12s %s", $1, s, $4 }')")"
_l20_ev a33a; printf '1\n' > "$L20/ctl/dispatch"; _l20_next a33c
_l20_st; L20A33="$L20A33|failed=$L20ST $(_l20_has "$L20SD" "$(_l20_f last 7)")"
printf 'a\tb\tc\n' >> "$LAND/alerts.tsv"; _l20_st; L20A33="$L20A33|three=$L20ST"
printf '%s\tposted\tpaused\t-\tfixture/lgh#1\thttps://github.com/fixture/lgh/issues/1#issuecomment-1\tas @fixture-bot mentioning @fixture\told\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LAND/alerts.tsv"; _l20_st; L20A33="$L20A33|posted=$L20ST"
_l20_st "$L20/nohome"; L20A33="$L20A33|nohome=$L20ST"
# Combined with b04 (docs/2026-10-24-audit-fixes/wave-1-combine.md, S1) and b18: b04's land and hooks rows
# precede alerts and b18's icloud row follows it, so the rows are nine.
# Changed by the lane counter contract (docs/2026-10-29-lane-slice-0-plan.md, C6): the lane row was added at the end, as the status header allows.
is "A33 (B13, R5): felix status --tsv prints ten rows, alerts before icloud and lane last, and alerts reads none, dispatched with the run URL, failed with its note, and unknown for an unreadable record, an old posted record or a home with no project, writing nothing and calling no gh; plain status aligns it" \
   "$L20A33" "rows=settings schedule pulse reach gate land hooks alerts icloud lane |none=none -|dispatched=value dispatched ok|plain=ok|failed=value failed ok|three=unknown -|posted=unknown -|nohome=unknown -"

# ------------------------------------------------ review round, R1-R6 ---
_l20_reset gh; printf 'fixture\n' > "$L20/ctl/login"; _l20_ev a36
L20K36="$(_l20_kinds)|comment=$(_l20_nk '^issue comment')|$(_l20_f last 2)|$(_l20_f last 7)"; _l20_st
is "A36 (R1, R5, M3): when the gh login is the owner it mentions (the founder's case), the alert is still dispatched to felix-alert.yml, nothing is commented as that login, and felix status says dispatched, never posted-self" \
   "$L20K36|$L20ST|$(_l20_yn "$L20SD" posted-self says-self)|$(_l20_yn "$(_lg_lc "$L20SD")" "own actions" own)" \
   "api user,api repos/fixture/lgh,issue list,issue create,workflow run|comment=0|dispatched|through felix-alert.yml mentioning @fixture|value dispatched|no-says-self|no-own"
_l20_ss() {   # -> L20SS the session-start hook's stdout, L20SSE ended|killed, L20SSK the scratch alerts.tsv's cksum before|after
  # The hook runs under a 30 s bound, in a process group of its own that is then killed whole, in a clone of the
  # home (origin the GitHub URL) used as the home, with a fresh HOME and a memory holding $LAND/alerts.tsv as it is.
  local h="$L20/ssh" p n=0
  rm -rf "$h" "$L20/ssm" "$L20/ssu"; mkdir -p "$L20/ssm/lgh/land" "$L20/ssu"
  _fx_git "$L20" clone -q "$LGH" ssh >/dev/null 2>&1; _fx_git "$h" config remote.origin.url https://github.com/fixture/lgh.git >/dev/null 2>&1
  cp -p "$LAND/alerts.tsv" "$L20/ssm/lgh/land/alerts.tsv" 2>/dev/null
  printf '{"session_id":"l20","source":"startup","cwd":"%s"}' "$h" > "$L20/ss.in"
  L20SSK="$(cksum < "$L20/ssm/lgh/land/alerts.tsv" 2>&1)"
  ( cd "$h" || exit 97
    exec perl -e 'setpgrp(0, 0); exec @ARGV or exit 127' env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE \
      HOME="$L20/ssu" FELIX_HOME="$h" FELIX_HOME_DIR="$h" FELIX_MEMORY="$L20/ssm" PATH="$LGB:$PATH" CLAUDE_PLUGIN_ROOT="$FROOT" \
      "$FROOT/harness/hooks/session-start" ) < "$L20/ss.in" > "$L20/ss.out" 2> "$L20/ss.err" &
  p=$!
  while kill -0 "$p" 2>/dev/null && [ "$n" -lt 300 ]; do sleep 0.1; n=$((n+1)); done
  if kill -0 "$p" 2>/dev/null; then L20SSE=killed; else L20SSE=ended; fi
  kill -KILL -- "-$p" 2>/dev/null; kill -KILL "$p" 2>/dev/null; wait "$p" 2>/dev/null
  L20SS="$(cat "$L20/ss.out" 2>/dev/null)"; L20SSK="$L20SSK|$(cksum < "$L20/ssm/lgh/land/alerts.tsv" 2>&1)"
}
_l20_reset gh; : > "$L20/ctl/workflow"; _l20_ev a37
L20R1="$(sed -n 1p "$LAND/alerts.tsv" 2>/dev/null)"; L20T1="$(_l20_f 1 1)"
L20K37="$(_l20_nk '^workflow run')|$(_l20_n)|$(_l20_f last 2)|$(_l20_starts "$(_l20_f last 7)" 'gh workflow run:')+$(_l20_in "$(_l20_f last 7)" felix-alert.yml names)|$(_lg_n paused)|$(_l20_osa paused)"
_l20_st; L20K37="$L20K37|$L20ST|$(_l20_yn "$L20SD" felix-alert.yml names-it)"
is "A37 (R3, R5, B10): with no felix-alert.yml workflow on the repository the dispatch is tried once and recorded no-alert-workflow naming it, landing is as before, and felix status says no-alert-workflow naming the file" \
   "$L20K37" "1|1|no-alert-workflow|ok+names|1|1|value no-alert-workflow|names-it"
_l20_ss; L20SS1="$L20SS"; L20SSE1="$L20SSE"; L20SSK1="$L20SSK"
rm -f "$L20/ctl/workflow"; _l20_age; _l20_clear; _lg_land --tick; L20B="$(_l20_cb | tail -n 1)"
is "A39 (R4): once the workflow exists, the same event raised again is dispatched; the no-alert-workflow record stays as it was, and BODY's line 4 counts it with its kind and time" \
   "$(_l20_nk '^workflow run')|$(_l20_n)|$(_l20_f 2 2)|$(if [ -n "$L20R1" ] && [ "$(sed -n 1p "$LAND/alerts.tsv" 2>/dev/null)" = "$L20R1" ]; then echo first-unchanged; else echo first-changed; fi)|$(sed -n 4p "$L20B" 2>&1)" \
   "1|2|dispatched|first-unchanged|Not delivered before this one: 1 (the newest: paused at $L20T1)."
_l20_ss; L20SS2="$L20SS"; L20SSE2="$L20SSE"
is "the land fixture: the session-start hook ended by itself within 30 s, both times (fixture control)" "$L20SSE1 $L20SSE2" "ended ended"
is "A38 (R6): with the newest record no-alert-workflow the session start says no-alert-workflow and names felix-alert.yml, leaving alerts.tsv as it was; with the newest dispatched it says no-alert-workflow nowhere" \
   "$(_l20_yn "$L20SS1" no-alert-workflow says-it) $(_l20_yn "$L20SS1" felix-alert.yml names-it)|$(if [ "${L20SSK1%%|*}" = "${L20SSK1#*|}" ]; then echo unchanged; else echo changed; fi)|$(_l20_yn "$L20SS2" no-alert-workflow says-it)" \
   "says-it names-it|unchanged|no-says-it"

# --------------------------------------------------------------- B10 ---
_l20_reset gh; _l20_ev a35
is "A35 (B10, control): in the GitHub state a paused tick still writes one seven-field paused row and one banner titled Felix: paused" \
   "$(_lg_n paused)|$(LC_ALL=C awk -F'\t' 'NF != 7' "$LAND/ledger.tsv" 2>/dev/null | wc -l | tr -d ' ')|$(_l20_osa paused)" "1|0|1"

# ----------------------------------------------------------- B3, R1 ---
is "A34 (B3, R1): across the part, gh saw no issue call but list and create (no comment), no pr call but the tick's list and view, no label call, no workflow call but workflow run felix-alert.yml, and no api call that writes (and some dispatch was made)" \
   "$(LC_ALL=C awk -F'\t' '
      $1 ~ /^issue / && $1 !~ /^issue (list|create)/ { i++ }
      $1 ~ /^issue comment/ { c++ }
      $1 ~ /^pr / && $1 != "pr list" && $1 != "pr view" { p++ }
      $1 ~ /^label / { l++ }
      $1 ~ /^workflow / && !($1 == "workflow run" && $7 == "felix-alert.yml") { w++ }
      $1 ~ /^api / { for (k = 5; k <= NF; k++) if ($k ~ /^(-X|--method|-f|-F|--field|--raw-field|--input)(=.*)?$/ || $k ~ /^-X./) { a++; break } }
      $1 == "workflow run" && $7 == "felix-alert.yml" { d++ }
      END { printf "issue=%d|comment=%d|pr=%d|label=%d|workflow=%d|api-writes=%d|%s", i, c, p, l, w, a, (d ? "dispatched" : "no-dispatch") }' "$L20/all.log" 2>&1)" \
   "issue=0|comment=0|pr=0|label=0|workflow=0|api-writes=0|dispatched"

# ------------------------------------------------------------- undone ---
_l20_off; _l20_pj; rm -rf "$L20PL"; cp -p "$L20/plugin.json.keep" "$L20PL"; /bin/mv "$L20/gh.prev" "$LGB/gh"; rm -f "$L20F"
_lg_reset; _lg_land --uninstall; _lg_reset; rm -rf "$L20"
is "the land fixture: the part put the home back: origin is the local path, no insteadOf, the home clean, the fixture's gh in place, and the working directory where it was (fixture control)" \
   "$(git -C "$LGH" config --get remote.origin.url 2>&1)|$(git -C "$LGH" config --get-regexp '^url\.' 2>&1)|$(git -C "$LGH" status --porcelain 2>&1)|$(LC_ALL=C grep -c 'amend/gh.1280' "$LGB/gh" 2>&1)|$(pwd -P)" \
   "$LGO|||1|$L20CWD"

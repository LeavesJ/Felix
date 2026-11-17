printf '\nunattended work runs only in the bound project'"'"'s own checkout\n'
# The contract is docs/2026-10-13-unattended-own-checkout-spec.md, and these were
# written from it alone, before any of it was built (B1-B42, section 5). Each
# name is the sentence it proves. Some hold against the engine before the change
# on purpose: the own checkouts still run everything (B10, B18, B20, B22), the
# quiet projects stay quiet (B12), attended commissioning and the reach refresh
# are untouched. Those are the positive controls; every "never ran" waits on the
# same lock or log the control was seen to write, for a window three times as
# long as the control took, so a stub nothing could reach cannot pass one.
# Everything lives under one private directory: a Felix home, a HOME, a memory
# root, a harness copy whose felix is a stub, and stubs for claude, gh and
# graphify that log their working directory and arguments.
OWBASE="${RXBASE:-}"
# Part 1100's base is adopted only while it is a root of the fixture guard, so an inherited RXBASE is never used unproven.
if [ -z "$OWBASE" ] || [ ! -d "$OWBASE" ] || ! _fx_root_for "$(cd "$OWBASE" 2>/dev/null && pwd -P)/."; then   # part 1120 removes a base it made outside $TMP
  OWBASE=""
  for _owc in "$TMP" "${XDG_RUNTIME_DIR:-}" "${RUNNER_TEMP:-}" "${HOME:-}"; do
    [ -n "$_owc" ] && command -v _rx_base_ok >/dev/null 2>&1 && _rx_base_ok "$_owc" || continue
    if [ "$_owc" = "$TMP" ]; then OWBASE="$TMP"; else OWBASE="$(mktemp -d "$_owc/.felix-suite-ow.XXXXXX" 2>/dev/null)" || OWBASE=""; fi
    [ -n "$OWBASE" ] && break
  done
  [ -n "$OWBASE" ] || OWBASE="$TMP"
fi
# A base outside $TMP is a root of the fixture guard (part 0002), or its git lines are refused.
_fx_root_add "$OWBASE"
OW="$(mktemp -d "$OWBASE/ow.XXXXXX")"; OW="$(cd "$OW" && pwd -P)"
OWT="$OW/tmp"; OWH="$OW/home"; OWP="$OWH/projects"; OWL="$OW/log"; OWCO="$OW/co"; OWHH="$OW/h/harness"
mkdir -p "$OWT" "$OWP" "$OWL" "$OWCO" "$OW/bin" "$OW/user" "$OW/mem" "$OW/cache" "$OW/gitbad" "$OW/h"
chmod 700 "$OWT"
for _w in felix claude gh graphify; do : > "$OWL/$_w.log"; done
cp -R "$FROOT/harness" "$OWHH"
_ow_stub() {   # <path> <log name> <body>: logs "$(pwd -P)<TAB>$*<TAB>.felix=<marker or ->" and runs the body
  { printf '#!/bin/bash\n'
    printf '%s\n' 'f=-; [ -f ./.felix ] && f="$(tr -d '"'"'\n'"'"' < ./.felix)"' \
                   'printf '"'"'%s\t%s\t.felix=%s\n'"'"' "$(pwd -P)" "$*" "$f" >> "OW_STUB_LOG"' "$3"
  } | sed "s|OW_STUB_LOG|$OWL/$2.log|" > "$1"; chmod +x "$1"
}
_ow_stub "$OWHH/felix" felix 'case "$*" in "discover --inspect --quiet") printf "# stamp stub\n"; exit "${OW_FELIX_RC:-0}" ;; esac; exit 0'
_ow_stub "$OW/bin/claude" claude 'case "$*" in "plugin list --json --available") printf "[]\n"; exit 0 ;; "mcp list"|"plugin list"|"plugin marketplace list") exit 0 ;; esac; exit 2'
_ow_stub "$OW/bin/gh" gh 'exit 0'
_ow_stub "$OW/bin/graphify" graphify 'exit 0'
printf '#!/bin/sh\nexit 69\n' > "$OW/gitbad/git"; chmod +x "$OW/gitbad/git"

_ow_env() {   # the fixture's HOME, home, memory and TMPDIR, the stubs first on PATH
  local t="TMPDIR=${OW_TMPDIR-$OWT}"; [ "${OW_NOTMP:-0}" = 1 ] && t="OW_NOTMP=1"
  env -u CLAUDE_CONFIG_DIR -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR -u TMPDIR -u GIT_DIR -u GIT_WORK_TREE \
      HOME="$OW/user" FELIX_HOME="$OWH" FELIX_MEMORY="$OW/mem" FELIX_PLUGIN_CACHE="$OW/cache" "$t" \
      PATH="${OW_PATH:-$OW/bin:$PATH}" CLAUDE_PLUGIN_ROOT="$OW/h" OW_FELIX_RC="${OW_FELIX_RC:-0}" "$@"
}
_ow_lib() {   # <lib> <code> [arg]: resolve.sh and one lib under /bin/bash; 97 when the lib cannot be sourced
  _ow_env /bin/bash -c '. "$1/lib/resolve.sh" && . "$1/lib/$2.sh" || exit 97; c="$3"; set -- "$4"; eval "$c"' owl "$OWHH" "$1" "$2" "${3:-}"
}
_ow_wait() { local i=0 n=$(( $1 * 5 )); while [ "$i" -lt "$n" ]; do eval "$2" && return 0; sleep 0.2; i=$((i+1)); done; eval "$2"; }
_ow_n() { awk -F'\t' -v p="$2" -v a="$3" '(p == "*" || $1 == p) && (a == "*" || $2 == a) { n++ } END { print n + 0 }' "$OWL/$1.log"; }
_ow_bg() { [ -f "$OWH/state/commission/$1.bg.log" ] || { echo 0; return; }
           awk -F'\t' -v r="$2" -v s="$3" '$3 == r && (s == "*" || $2 == s) { n++ } END { print n + 0 }' "$OWH/state/commission/$1.bg.log"; }
_ow_disc() { awk -F'\t' '$2 == "discover --inspect --quiet"' "$OWL/felix.log"; }
_ow_dn() { _ow_disc | wc -l | tr -d ' '; }
_ow_json() { printf '%s' "$OWO" | python3 -c 'import json, sys
try: d = json.loads(sys.stdin.read())
except Exception: sys.exit(3)
sys.stdout.write(d.get(sys.argv[1]) or (d.get("hookSpecificOutput") or {}).get(sys.argv[1]) or "")' "$1" 2>/dev/null; }
_ow_last() { printf '%s' "$OWC" | python3 -c 'import sys; print(sys.stdin.read().rstrip("\n").split("\n\n")[-1])'; }
_ow_has() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "lacks [$3]" ;; esac; }
_ow_lacks() { case "$2" in *"$3"*) bad "$1" "holds [$3]" ;; *) ok "$1" ;; esac; }
_ow_proj() {   # <name> <remote_match, or - for none>
  mkdir -p "$OWP/$1"
  if [ "$2" = - ]; then printf '{"name": "%s", "gate": "true"}\n' "$1"
  else printf '{"name": "%s", "remote_match": "%s", "gate": "true"}\n' "$1" "$2"; fi > "$OWP/$1/project.json"
  printf '# %s\n' "$1" > "$OWP/$1/CLAUDE.md"
}
_ow_stamp() { ( . "$OWHH/lib/resolve.sh"; . "$OWHH/lib/detect.sh"; . "$OWHH/lib/commission.sh"
                felix_commission_policy_version "$OWP/$1" ) > "$OWP/$1/autonomy.commission" 2>/dev/null; }
_ow_rival() { mkdir -p "$1/scripts"; printf '#!/bin/sh\necho repo copy\n' > "$1/scripts/prepush.sh"; chmod +x "$1/scripts/prepush.sh"; }
_ow_co() {   # <name> <project or -> <origin or -> [cargo] [nograph] [norival]: two commits, a held rival, a graph one behind
  local d="$OWCO/$1"; mkdir -p "$d"
  ( _fx_cd "$d" && git init -q -b main && { [ "$2" = - ] || printf '%s\n' "$2" > .felix; } && printf 'a\n' > f.txt \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm one \
    && printf 'b\n' > f.txt && git -c user.name=t -c user.email=t@t commit -qam two ) >/dev/null 2>&1
  [ "$3" = - ] || _fx_git "$d" config remote.origin.url "$3"
  case " $* " in *" nograph "*) ;; *) mkdir -p "$d/graphify-out"
    printf '{"nodes":[],"built_at_commit":"%s"}\n' "$(git -C "$d" rev-list --max-parents=0 HEAD)" > "$d/graphify-out/graph.json" ;; esac
  case " $* " in *" norival "*) ;; *) _ow_rival "$d" ;; esac
  case " $* " in *" cargo "*) printf '[package]\nname = "x"\n' > "$d/Cargo.toml" ;; esac
}
OWDISC=1; _ow_ns=0
_ow_run() {   # <checkout> [harness]: one SessionStart there; sets OWO OWC OWM OWRC OWD (the discover line it launched)
  local d0; d0="$(_ow_dn)"; _ow_ns=$((_ow_ns+1))
  [ "${OW_KEEP:-0}" = 1 ] || rm -f "$OWH/state/discover/"*.tsv
  OWO="$(cd "$1" && printf '{"session_id":"ow-%s","hook_event_name":"SessionStart","source":"startup"}' "$_ow_ns" \
         | _ow_env "${2:-$OWHH}/hooks/session-start" 2>/dev/null)"; OWRC=$?; OWT1="$(date +%s)"
  OWC="$(_ow_json additionalContext)"; OWM="$(_ow_json systemMessage)"; OWD=""
  if [ "$OWDISC" = 1 ]; then _ow_wait 20 '[ "$(_ow_dn)" -gt '"$d0"' ]'; OWD="$(_ow_disc | sed -n "$((d0+1))p")"; fi
  _ow_wait 20 "[ ! -d '$OWH/state/discover/.lock' ] && [ ! -d '$1/graphify-out/.felix-refresh.lock' ]"
}
_ow_neutral() {   # <name> <discover line> <project>: it ran in <TMPDIR>/felix-discover.?????? holding .felix=<project>
  local p f; p="$(printf '%s' "$2" | cut -f1)"; f="$(printf '%s' "$2" | cut -f3)"
  case "$p" in "$OWT"/felix-discover.??????) [ "$f" = ".felix=$3" ] && ok "$1" || bad "$1" "[$f]" ;;
               *) bad "$1" "ran in [${p:-nothing}]" ;; esac
}
OWDP="$OWP/ownp"; OWLINE="Nothing ran here unattended:"
TAB="$(printf '\t')"

# ---- the projects and checkouts (section 6.2)
_ow_proj ownp OwnerX/ownp-repo; _ow_proj ownq OwnerX/ownq-repo
printf 'commission\ntidy\n' > "$OWDP/autonomy"
printf 'debug\tbroken failing crash\tcore\tsuperpowers:systematic-debugging\n' > "$OWDP/routes.tsv"
printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$OWDP/commissioning.tsv"
printf '#!/bin/sh\necho felix copy\n' > "$OWDP/prepush.sh"; chmod +x "$OWDP/prepush.sh"
: > "$OWP/ownq/capabilities"
_ow_co own-https ownp https://github.com/OwnerX/ownp-repo
_ow_co own-scp   ownp git@github.com:OwnerX/ownp-repo.git
_ow_co own-case  ownp https://GitHub.com/ownerx/OWNP-REPO.git/
_ow_co own-ssh   ownp ssh://git@github.com/OwnerX/ownp-repo.git
_ow_co lookalike ownp git@evil.example:OwnerX/ownp-repo.git
_ow_co fork      ownp https://github.com/OwnerX/ownp-repo-fork.git
_ow_co none      ownp -
_ow_co substring -    git@evil.example:OwnerX/ownp-repo.git
( . "$OWHH/lib/resolve.sh"; . "$OWHH/lib/detect.sh"; felix_detect "$OWCO/own-https" ) > "$OWDP/capabilities" 2>/dev/null
_ow_stamp ownp
cp -R "$OWDP" "$OW/ownp.keep"

printf '\nthe slug of a remote (B1, B2)\n'
_ow_slug() { _ow_lib own 'o="$(felix_remote_github_slug "$1")"; r=$?; printf "%s|%s" "$o" "$r"' "$1" 2>/dev/null; }
for _u in https://github.com/OwnerX/ownp-repo https://github.com/OwnerX/ownp-repo.git https://GitHub.com/ownerx/OWNP-REPO.git/ \
          https://tok@github.com/OwnerX/ownp-repo.git https://github.com:443/OwnerX/ownp-repo git@github.com:OwnerX/ownp-repo.git \
          github.com:OwnerX/ownp-repo ssh://git@github.com/OwnerX/ownp-repo.git ssh://git@github.com:22/OwnerX/ownp-repo \
          git://github.com/OwnerX/ownp-repo.git; do
  is "felix_remote_github_slug prints ownerx/ownp-repo and returns 0 for $_u" "$(_ow_slug "$_u")" "ownerx/ownp-repo|0"
done
for _u in git@evil.example:OwnerX/ownp-repo.git https://github.com.evil.example/OwnerX/ownp-repo \
          https://evil.example/github.com/OwnerX/ownp-repo https://github.com/OwnerX/ownp-repo/extra https://github.com/OwnerX \
          http://github.com/OwnerX/ownp-repo file:///tmp/ownp-repo /tmp/ownp-repo git@github.com:/OwnerX/ownp-repo \
          'https://github.com/OwnerX/ownp-repo?x=1' 'https://github.com/Owner X/ownp-repo' \
          'https://evil.example#@github.com/OwnerX/ownp-repo' 'https://evil.example?@github.com/OwnerX/ownp-repo' \
          'https://evil.example\@github.com/OwnerX/ownp-repo' ''; do
  is "felix_remote_github_slug prints nothing and returns 1 for [$_u]" "$(_ow_slug "$_u")" "|1"
done
is "the fork URL is a valid slug, ownerx/ownp-repo-fork, refused only by the predicate" \
   "$(_ow_slug https://github.com/OwnerX/ownp-repo-fork.git)" "ownerx/ownp-repo-fork|0"

printf '\nthe predicate (B3-B6)\n'
_ow_own() { _ow_lib own 'felix_checkout_is_own "$1" "'"$2"'"; printf "%s %s" "$?" "$_FELIX_OWN_WHY"' "$1" 2>/dev/null; }
OWPR="$OWCO/pred"; _ow_co pred ownp - nograph norival
for _u in https://github.com/OwnerX/ownp-repo https://github.com/OwnerX/ownp-repo.git https://GitHub.com/ownerx/OWNP-REPO.git/ \
          https://tok@github.com/OwnerX/ownp-repo.git https://github.com:443/OwnerX/ownp-repo git@github.com:OwnerX/ownp-repo.git \
          github.com:OwnerX/ownp-repo ssh://git@github.com/OwnerX/ownp-repo.git ssh://git@github.com:22/OwnerX/ownp-repo \
          git://github.com/OwnerX/ownp-repo.git; do
  _fx_git "$OWPR" config remote.origin.url "$_u"
  is "a checkout whose origin is $_u is own (0 own)" "$(_ow_own "$OWDP" "$OWPR")" "0 own"
done
_fx_git "$OWCO/own-https" worktree add -q "$OWCO/own-wt" -b wt >/dev/null 2>&1
is "a worktree of an own checkout is own" "$(_ow_own "$OWDP" "$OWCO/own-wt")" "0 own"
for _u in git@evil.example:OwnerX/ownp-repo.git https://github.com/OwnerX/ownp-repo-fork.git https://github.com.evil.example/OwnerX/ownp-repo \
          'https://evil.example#@github.com/OwnerX/ownp-repo'; do
  _fx_git "$OWPR" config remote.origin.url "$_u"
  is "a checkout whose origin is $_u is not own (1 other)" "$(_ow_own "$OWDP" "$OWPR")" "1 other"
done
is "a repository with no origin is not own (1 no-origin)" "$(_ow_own "$OWDP" "$OWCO/none")" "1 no-origin"
_ow_proj pm-empty ""; _ow_proj pm-absent -; _ow_proj pm-dotcom example.com; _ow_proj pm-abc a/b/c
for _pm in pm-empty pm-absent pm-dotcom pm-abc; do
  printf '%s\n' "$_pm" > "$OWPR/.felix"; _fx_git "$OWPR" config remote.origin.url "https://github.com/OwnerX/$_pm"
  is "a project whose remote_match is ${_pm#pm-} has no own checkout, its own .felix and origin included (1 no-match)" \
     "$(_ow_own "$OWP/$_pm" "$OWPR")" "1 no-match"
done
printf 'ownp\n' > "$OWPR/.felix"; rm -rf "$OWP"/pm-*
mkdir -p "$OW/notrepo"
is "a directory that is not a repository is unknown (2 unread)" "$(_ow_own "$OWDP" "$OW/notrepo")" "2 unread"
is "a repository is unknown when git exits 69 (2 unread)" "$(OW_PATH="$OW/gitbad:$OW/bin:$PATH" _ow_own "$OWDP" "$OWCO/own-https")" "2 unread"
for _u in https://github.com/OwnerX/ownp-repo git@evil.example:OwnerX/ownp-repo.git -; do
  if [ "$_u" = - ]; then _fx_git "$OWPR" config --unset remote.origin.url; else _fx_git "$OWPR" config remote.origin.url "$_u"; fi
  _a="$(_ow_own "$OWDP" "$OWPR")"; rm -f "$OWPR/.felix"; _b="$(_ow_own "$OWDP" "$OWPR")"; printf 'ownp\n' > "$OWPR/.felix"
  [ -n "$_a" ] && [ "$_a" = "$_b" ] && ok "a .felix marker changes nothing: origin $_u reads the same with and without it" \
    || bad "a .felix marker changes nothing: origin $_u reads the same with and without it" "[$_a] vs [$_b]"
done

printf '\nthe gate and the withheld line, as functions (section 3)\n'
is "felix_own_gate returns 0 on status 0 and withholds nothing, 1 otherwise, each kind once, comma-joined" \
   "$(_ow_lib own '_FELIX_OWN_WITHHELD=""; felix_own_gate adoption 0; a=$?; felix_own_gate tidying 1; b=$?; felix_own_gate tidying 2; felix_own_gate commissioning 1; printf "%s %s [%s]" "$a" "$b" "$_FELIX_OWN_WITHHELD"' 2>/dev/null)" \
   "0 1 [tidying, commissioning]"
is "with nothing withheld the line prints nothing" \
   "$(_ow_lib own '_FELIX_OWN_WITHHELD=""; felix_own_withheld_line "'"$OWDP"'" "'"$OWCO/lookalike"'" "'"$OW/h3"'"; printf "|"' 2>/dev/null)" "|"
_ow_wl() { _ow_lib own '_FELIX_OWN_WITHHELD="tidying"; o="$(felix_own_withheld_line "'"$OWDP"'" "'"$1"'" "'"$2"'")"; printf "%s|" "$o"' 2>/dev/null; }
is "the line is a blank line then the sentence, the first time" "$(_ow_wl "$OWCO/lookalike" "$OW/h3")" \
   "
$OWLINE ownp is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownp-repo. Withheld: tidying.|"
is "and nothing the second time for the same checkout and kinds" "$(_ow_wl "$OWCO/lookalike" "$OW/h3")" "|"
mkdir -p "$OW/h4/state"; : > "$OW/h4/state/own"
_ow_has "a .seen that cannot be written does not stop the line" "$(_ow_wl "$OWCO/lookalike" "$OW/h4")" "Withheld: tidying."
_ow_has "and it is said again, since it could not be recorded" "$(_ow_wl "$OWCO/lookalike" "$OW/h4")" "Withheld: tidying."

printf '\nthe neutral directory (section 3, D1)\n'
_ow_nd() { _ow_lib reach 'felix_neutral_dir "$1"; r=$?; printf "%s %s" "$r" "${_FELIX_NEUTRAL_DIR:-}"' "$1" 2>/dev/null; }
_owo="$(_ow_nd felix-discover)"
case "$_owo" in "0 $OWT"/felix-discover.??????) [ -d "${_owo#0 }" ] && ok "felix_neutral_dir makes a fresh <TMPDIR>/<prefix>.XXXXXX and returns 0" \
                  || bad "felix_neutral_dir makes a fresh <TMPDIR>/<prefix>.XXXXXX and returns 0" "not a directory" ;;
  *) bad "felix_neutral_dir makes a fresh <TMPDIR>/<prefix>.XXXXXX and returns 0" "[$_owo]" ;; esac
_ow_lib reach 'felix_neutral_rm "$1" felix-discover' "${_owo#0 }" >/dev/null 2>&1
# Harness mistake, fixed in the build stage: a case pattern without its opening paren inside $( ) is a syntax error in bash 3.2, so this assertion read the code as the answer.
is "felix_neutral_rm removes it" "$(case "$_owo" in ("0 /"*) [ -e "${_owo#0 }" ] && echo left || echo gone ;; (*) echo "nothing was made" ;; esac)" "gone"
mkdir -p "$OW/d777" "$OW/mcp/tmp" "$OWT/real-target"; chmod 777 "$OW/d777"; chmod 700 "$OW/mcp/tmp"; printf '{}\n' > "$OW/mcp/.mcp.json"
is "a relative TMPDIR returns 1" "$(OW_TMPDIR=rel-tmp _ow_nd felix-discover | cut -d' ' -f1)" "1"
is "a TMPDIR others can write returns 2" "$(OW_TMPDIR="$OW/d777" _ow_nd felix-discover | cut -d' ' -f1)" "2"
is "a prefix that is not lowercase letters and dashes returns 3" "$(_ow_nd Bad_1 | cut -d' ' -f1)" "3"
is "a TMPDIR under a .mcp.json returns 4" "$(OW_TMPDIR="$OW/mcp/tmp" _ow_nd felix-discover | cut -d' ' -f1)" "4"
is "and on 3 and 4 nothing it made is left" "$(ls -A "$OW/mcp/tmp" | wc -l | tr -d ' ')$(ls -d "$OWT"/Bad_1* 2>/dev/null | wc -l | tr -d ' ')" "00"
ln -s "$OWT/real-target" "$OWT/felix-discover.abcdef"
_ow_lib reach 'felix_neutral_rm "$1" felix-discover' "$OWT/felix-discover.abcdef" >/dev/null 2>&1
is "felix_neutral_rm leaves a symlink and its target alone" "$([ -L "$OWT/felix-discover.abcdef" ] && [ -d "$OWT/real-target" ] && echo kept)" "kept"
rm -f "$OWT/felix-discover.abcdef"; rmdir "$OWT/real-target"
_owo="$(_ow_lib reach 'felix_neutral_run "$1" felix-discover /bin/sh -c "pwd -P; cat .felix; exit 7"; printf "|%s" "$?"' "$OWDP" 2>/dev/null)"
case "$_owo" in "$OWT"/felix-discover.??????"
ownp
|7") ok "felix_neutral_run runs the command in the fresh directory, a .felix naming the project, and returns its status" ;;
  *) bad "felix_neutral_run runs the command in the fresh directory, a .felix naming the project, and returns its status" "[$_owo]" ;; esac
is "and removes the directory after" "$(ls -d "$OWT"/felix-discover.* 2>/dev/null | wc -l | tr -d ' ')" "0"

printf '\nan own checkout runs everything, as on main (B10, B14, B18, B20, B34)\n'
_ow_run "$OWCO/own-https"; _owr="$OWCO/own-https"
_ow_wait 30 '[ "$(_ow_bg ownp "$_owr" ran)" -ge 1 ]'; _owlat=$(( $(date +%s) - OWT1 ))
OWNEG=$(( _owlat * 3 + 2 )); [ "$OWNEG" -lt 3 ] && OWNEG=3; [ "$OWNEG" -gt 12 ] && OWNEG=12
_ow_wait 20 '[ "$(_ow_n graphify "$_owr" "update $_owr")" -ge 1 ]'
is "B10: an own checkout with a current grant runs felix commission once, in the checkout root" "$(_ow_n felix "$_owr" commission)" "1"
is "B10: and bg.log gains a ran line for the root" "$(_ow_bg ownp "$_owr" ran)" "1"
_ow_neutral "B14: in an own checkout discovery runs felix discover --inspect --quiet from a fresh felix-discover directory holding .felix=ownp" "$OWD" ownp
is "B14: and never from the checkout" "$(_ow_n felix "$_owr" 'discover --inspect --quiet')" "0"
is "B18: an own checkout whose graph is behind runs graphify update <graph home> once, from the graph home" "$(_ow_n graphify "$_owr" "update $_owr")" "1"
is "B20: an own checkout granted tidy removes the held untracked rival" "$([ -e "$_owr/scripts/prepush.sh" ] && echo kept || echo removed)" "removed"
is "B20: and backs it up under state/rivals" "$(ls "$OWH/state/rivals/" 2>/dev/null | grep -c prepush)" "1"
_ow_has "B20: and the context says what it removed" "$OWC" "Removed, as copies Felix already holds: scripts/prepush.sh"
_ow_lacks "B34: an own checkout's context never holds the withheld line" "$OWC" "$OWLINE"
OWM_OWN="$OWM"
for _c in own-scp own-case own-ssh; do
  _owr="$OWCO/$_c"; _ow_run "$_owr"; _ow_wait 30 '[ "$(_ow_bg ownp "$_owr" ran)" -ge 1 ]'
  is "B10: the $_c spelling runs felix commission once, in the checkout root" "$(_ow_n felix "$_owr" commission)" "1"
  is "B10: and bg.log gains its ran line ($_c)" "$(_ow_bg ownp "$_owr" ran)" "1"
  _ow_lacks "B34: no withheld line in the $_c checkout" "$OWC" "$OWLINE"
done

printf '\nunowned checkouts run none of it, and say so once (B11, B14, B19, B21, B30-B32, B35)\n'
_owf0="$(_ow_n felix "*" commission)"; _owg0="$(_ow_n graphify "*" "*")"
for _c in lookalike fork none substring; do
  cp "$OWCO/$_c/scripts/prepush.sh" "$OW/rival.$_c"; _ow_run "$OWCO/$_c"
  eval "OWC_$_c=\"\$OWC\"; OWM_$_c=\"\$OWM\"; OWD_$_c=\"\$OWD\"; OWLP_$_c=\"\$(_ow_last)\""
done
_ow_wait "$OWNEG" '[ "$(_ow_n felix "*" commission)" -gt '"$_owf0"' ] || [ "$(_ow_n graphify "*" "*")" -gt '"$_owg0"' ]'
for _c in lookalike fork none substring; do
  _owr="$OWCO/$_c"; eval "_owc=\"\$OWC_$_c\"; _owm=\"\$OWM_$_c\"; _owd=\"\$OWD_$_c\""
  is "B11: the $_c checkout never runs felix commission" "$(_ow_n felix "$_owr" commission)" "0"
  _owb="$(awk -F'\t' -v r="$_owr" '$3 == r' "$OWH/state/commission/ownp.bg.log" 2>/dev/null)"
  case "$_owb" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z"${TAB}refused-not-own${TAB}$_owr")
       ok "B11: and bg.log gains exactly one line <UTC ts> refused-not-own <root> ($_c)" ;;
    *) bad "B11: and bg.log gains exactly one line <UTC ts> refused-not-own <root> ($_c)" "[$_owb]" ;; esac
  _ow_neutral "B14: in the $_c checkout discovery still runs, from a fresh felix-discover directory holding .felix=ownp" "$_owd" ownp
  is "B19: the $_c checkout never runs graphify" "$(_ow_n graphify "$_owr" "*")" "0"
  _ow_has "B19: and the graph line is still in its context ($_c)" "$_owc" "Knowledge graph: 1 commit(s) behind this checkout"
  cmp -s "$OW/rival.$_c" "$_owr/scripts/prepush.sh" && ok "B21: the $_c checkout keeps its rival, byte-identical" \
    || bad "B21: the $_c checkout keeps its rival, byte-identical"
  _ow_lacks "B21: and its context holds no Removed, as copies line ($_c)" "$_owc" "Removed, as copies"
  case "$_owm" in "Felix: ownp"*) ok "the binding is unchanged: $_c still resolves to ownp" ;; *) bad "the binding is unchanged: $_c still resolves to ownp" "[$_owm]" ;; esac
  _ow_has "and still gets the gate line ($_c)" "$_owc" "Gate:"
  _ow_lacks "B35: the systemMessage carries no withheld line ($_c)" "$_owm" "$OWLINE"
  is "B35: and is the same status line an own checkout gets ($_c)" "$_owm" "$OWM_OWN"
done
_owk="Withheld: graph refresh, tidying, commissioning."
is "B30: the lookalike checkout's last paragraph is the one line" "$OWLP_lookalike" \
   "$OWLINE ownp is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownp-repo. $_owk"
is "B33: a different checkout with the same kinds withheld (fork) says it again" "$OWLP_fork" \
   "$OWLINE ownp is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownp-repo. $_owk"
is "B32: with no origin remote the reason is it has no origin remote" "$OWLP_none" \
   "$OWLINE ownp is bound to this checkout by its .felix marker, and it has no origin remote. $_owk"
is "B31: the substring-bound checkout says it was bound by an origin that only contains the remote_match" "$OWLP_substring" \
   "$OWLINE ownp is bound to this checkout by an origin that only contains OwnerX/ownp-repo, and its origin is not github.com/OwnerX/ownp-repo. $_owk"
_ow_has "B35: the line is in additionalContext" "$OWC_lookalike" "$OWLINE"

printf '\nonce per checkout and set of kinds (B33)\n'
_owr="$OWCO/lookalike"; _ow_run "$_owr"
_ow_lacks "B33: a second session in the same checkout with the same kinds adds no line" "$OWC" "$OWLINE"
is "B33: and its commissioning is refused again, one more bg.log line" "$(_ow_bg ownp "$_owr" refused-not-own)" "2"
printf '{"nodes":[],"built_at_commit":"%s"}\n' "$(git -C "$_owr" rev-parse HEAD)" > "$_owr/graphify-out/graph.json"
_ow_run "$_owr"
is "B33: the same checkout with a different set of kinds says it again" "$(_ow_last)" \
   "$OWLINE ownp is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownp-repo. Withheld: tidying, commissioning."

printf '\na submodule is never own: its origin is the superproject'"'"'s to choose (found in review)\n'
# A hostile superproject's tracked .gitmodules gives the submodule its origin. Offline: insteadOf serves that URL from a local bare repo.
_ow_co sub-seed ownp - nograph norival; git clone -q --bare "$OWCO/sub-seed" "$OW/sub.git" >/dev/null 2>&1; git init -q -b main "$OW/sup-seed" >/dev/null 2>&1
( _fx_cd "$OW/sup-seed" && printf 'a\n' > f.txt && git add f.txt && git -c user.name=t -c user.email=t@t commit -qm one \
  && git -c protocol.file.allow=always submodule add -q "file://$OW/sub.git" vendor/x && git config -f .gitmodules submodule.vendor/x.url https://github.com/OwnerX/ownp-repo \
  && git add .gitmodules && git -c user.name=t -c user.email=t@t commit -qm two ) >/dev/null 2>&1
git clone -q --bare "$OW/sup-seed" "$OW/sup.git" >/dev/null 2>&1
git -c "url.file://$OW/sub.git.insteadOf=https://github.com/OwnerX/ownp-repo" -c protocol.file.allow=always clone -q --recurse-submodules "file://$OW/sup.git" "$OWCO/hostile" >/dev/null 2>&1
_owsub="$OWCO/hostile/vendor/x"; _owu="$(git -C "$_owsub" remote get-url origin 2>/dev/null)"
_ow_rival "$_owsub"; cp "$_owsub/scripts/prepush.sh" "$OW/rival.sub"   # no graph here: felix_graph_home of a submodule is its gitdir's parent, so a refresh is never due
is "B8: the fixture is the hostile shape: the submodule's origin reads as the project's and the slug accepts it" "$_owu|$(_ow_slug "$_owu")" \
   "https://github.com/OwnerX/ownp-repo|ownerx/ownp-repo|0"
is "B8: a submodule is not own though its origin is the project's (1 submodule)" "$(_ow_own "$OWDP" "$_owsub")" "1 submodule"
_fx_git "$OWCO/hostile" config remote.origin.url https://github.com/OwnerX/ownp-repo
is "B8: a repository that holds a submodule is still own when its own origin is the project's" "$(_ow_own "$OWDP" "$OWCO/hostile")" "0 own"
mkdir -p "$OW/gitsp"; printf '#!/bin/sh\ncase "$*" in *--show-superproject-working-tree*) exit 69 ;; esac\nexec %s "$@"\n' "$(command -v git)" > "$OW/gitsp/git"; chmod +x "$OW/gitsp/git"
is "B8: a repository is unknown when git cannot say whether it is a submodule (2 unread)" "$(OW_PATH="$OW/gitsp:$OW/bin:$PATH" _ow_own "$OWDP" "$OWCO/own-https")" "2 unread"
_ow_run "$_owsub"; _ow_wait "$OWNEG" '[ "$(_ow_n felix "$_owsub" commission)" -gt 0 ]'
is "B9: a session start in a submodule runs no felix commission and logs one refused-not-own line, none ran" \
   "$(_ow_n felix "$_owsub" commission) $(_ow_bg ownp "$_owsub" refused-not-own) $(_ow_bg ownp "$_owsub" ran)" "0 1 0"
cmp -s "$OW/rival.sub" "$_owsub/scripts/prepush.sh" && ok "B9: and keeps its untracked rival, byte-identical" || bad "B9: and keeps its untracked rival, byte-identical"
_owk="$OWLINE ownp is bound to this checkout by its .felix marker, and it is a submodule, whose origin the repository holding it chooses. Withheld:"
is "B9: and says what was withheld, and why" "$(_ow_last)" "$_owk tidying, commissioning."
printf '[package]\nname = "x"\n' > "$_owsub/Cargo.toml"; _ow_run "$_owsub"
is "B9: and with a Cargo.toml it adopts nothing into the project's capabilities" "$(grep -c '^rust$' "$OWDP/capabilities")" "0"
is "B9: and says adoption was withheld too" "$(_ow_last)" "$_owk adoption, tidying, commissioning."
rm -rf "$OWDP"; cp -R "$OW/ownp.keep" "$OWDP"   # a run that did adopt would leave the project changed for every part after this one

printf '\nadoption (B22, B23, B30, B32, B34)\n'
OWDISC=0
_ow_co q-own ownq https://github.com/OwnerX/ownq-repo cargo nograph norival
_ow_co q-look ownq git@evil.example:OwnerX/ownp-repo.git cargo nograph norival
_ow_co q-nomatch ownq https://github.com/OwnerX/ownq-repo cargo nograph norival
_ow_co q-quiet ownq git@evil.example:OwnerX/ownq-repo.git nograph norival
cp -R "$OWP/ownq" "$OW/ownq.keep"
_ow_run "$OWCO/q-own"
is "B22: an own checkout holding Cargo.toml appends rust to capabilities" "$(grep -c '^rust$' "$OWP/ownq/capabilities")" "1"
_ow_has "B22: and the context says it adopted rust" "$OWC" "Adopted automatically, because the checkout grew them: rust("
rm -rf "$OWP/ownq"; cp -R "$OW/ownq.keep" "$OWP/ownq"
_ow_run "$OWCO/q-look"
_owdf=""
for _f in capabilities stack.tsv setup.tsv setup; do
  { [ -e "$OW/ownq.keep/$_f" ] || [ -e "$OWP/ownq/$_f" ]; } && ! diff -r "$OW/ownq.keep/$_f" "$OWP/ownq/$_f" >/dev/null 2>&1 && _owdf="$_owdf $_f"
done
is "B23: an unowned checkout leaves capabilities, stack.tsv, setup.tsv and setup/ byte-identical" "$_owdf" ""
_ow_lacks "B23: and its context holds no Adopted automatically line" "$OWC" "Adopted automatically"
_ow_lacks "B23: nor a Not adopted line" "$OWC" "Not adopted"
is "B30: adoption alone withheld says Withheld: adoption." "$(_ow_last)" \
   "$OWLINE ownq is bound to this checkout by its .felix marker, and its origin is not github.com/OwnerX/ownq-repo. Withheld: adoption."
_ow_proj ownq -; _ow_run "$OWCO/q-nomatch"
is "B32: a project with no remote_match says so as the reason" "$(_ow_last)" \
   "$OWLINE ownq is bound to this checkout by its .felix marker, and ownq declares no remote_match naming a github.com owner/repo, so no checkout is its own. Withheld: adoption."
rm -rf "$OWP/ownq"; cp -R "$OW/ownq.keep" "$OWP/ownq"
_ow_run "$OWCO/q-quiet"
_ow_lacks "B34: an unowned checkout where nothing was due holds no withheld line" "$OWC" "$OWLINE"

printf '\nquiet projects stay quiet (B12)\n'
for _p in ownu ownv ownw; do
  _ow_proj "$_p" "OwnerX/$_p-repo"; printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n' > "$OWP/$_p/commissioning.tsv"
  _ow_co "$_p-look" "$_p" "git@evil.example:OwnerX/$_p-repo.git" nograph norival
done
printf 'tidy\n' > "$OWP/ownu/autonomy"
printf 'commission\n' > "$OWP/ownv/autonomy"; printf 'stale\n' > "$OWP/ownv/autonomy.commission"
printf 'commission\n' > "$OWP/ownw/autonomy"; rm -f "$OWP/ownw/commissioning.tsv"; _ow_stamp ownw
for _p in ownu ownv ownw; do _ow_run "$OWCO/$_p-look"; done
_ow_wait "$OWNEG" '[ -e "$OWH/state/commission/ownu.bg.log" ] || [ -e "$OWH/state/commission/ownv.bg.log" ] || [ -e "$OWH/state/commission/ownw.bg.log" ]'
for _p in ownu:ungranted ownv:stale-stamped ownw:tableless; do
  is "B12: a ${_p#*:} project in an unowned checkout writes no bg.log line of any kind" \
     "$([ -e "$OWH/state/commission/${_p%%:*}.bg.log" ] && echo written || echo silent)" "silent"
done

printf '\nthe discovery cache (B15, B16)\n'
OWDISC=1; _owr="$OWCO/none"; _ow_run "$_owr"
is "B15: on success the cache is the command's stdout" "$(cat "$OWH/state/discover/ownp.tsv" 2>/dev/null)" "# stamp stub"
is "B15: the lock is gone and TMPDIR holds no felix-discover directory" \
   "$([ -d "$OWH/state/discover/.lock" ] && echo held)$(ls -d "$OWT"/felix-discover.* 2>/dev/null | wc -l | tr -d ' ')" "0"
printf '# previous cache\n' > "$OWH/state/discover/ownp.tsv"; cp "$OWH/state/discover/ownp.tsv" "$OW/disc.keep"
_owd0="$(_ow_dn)"; OW_KEEP=1 OW_FELIX_RC=1 _ow_run "$_owr"
is "B15: a failing refresh still ran" "$([ "$(_ow_dn)" -gt "$_owd0" ] && echo ran)" "ran"
cmp -s "$OW/disc.keep" "$OWH/state/discover/ownp.tsv" && ok "B15: and on a non-zero exit the previous cache is unchanged" \
  || bad "B15: and on a non-zero exit the previous cache is unchanged"
is "B15: no .new file is left, the lock is gone, TMPDIR holds no felix-discover directory" \
   "$(ls "$OWH/state/discover/" | grep -c '\.new\.')$([ -d "$OWH/state/discover/.lock" ] && echo held)$(ls -d "$OWT"/felix-discover.* 2>/dev/null | wc -l | tr -d ' ')" "00"
OWDISC=0
for _t in unset rel d777 mcp; do
  _owd0="$(_ow_dn)"; _owc0="$(_ow_n claude "*" "*")"
  case "$_t" in unset) OW_NOTMP=1 _ow_run "$_owr" ;; rel) OW_TMPDIR=rel-tmp _ow_run "$_owr" ;;
                d777) OW_TMPDIR="$OW/d777" _ow_run "$_owr" ;; mcp) OW_TMPDIR="$OW/mcp/tmp" _ow_run "$_owr" ;; esac
  _ow_wait "$OWNEG" '[ "$(_ow_dn)" -gt '"$_owd0"' ]'
  is "B16: with TMPDIR $_t the refresh runs no felix and no claude" "$(_ow_dn) $(_ow_n claude "*" "*")" "$_owd0 $_owc0"
  is "B16: and writes no cache and leaves no lock (TMPDIR $_t)" \
     "$([ -e "$OWH/state/discover/ownp.tsv" ] && echo cache)$([ -d "$OWH/state/discover/.lock" ] && echo lock)" ""
done
is "B17: nothing a session start launched ran claude with a checkout as its working directory" \
   "$(awk -F'\t' -v c="$OWCO/" 'index($1, c) == 1' "$OWL/claude.log" | head -3)" ""

printf '\nthe reach refresh is untouched (P5)\n'
_ow_proj ownr OwnerX/ownr-repo; printf 'plugin\tx@m\t-\tlow\talways\n' > "$OWP/ownr/stack.tsv"
_ow_co r-co ownr - nograph norival; _ow_run "$OWCO/r-co"
# The stub answers mcp list with nothing, so no cache is asserted here; parts 1100-1120 hold the cache and its sentences.
_ow_reach() { awk -F'\t' -v t="$OWT/felix-reach." '$2 == "mcp list" && index($1, t) == 1 && substr($1, length(t) + 1) ~ /^[A-Za-z0-9]+$/ { n++ } END { print n + 0 }' "$OWL/claude.log"; }
_ow_wait 20 '[ "$(_ow_reach)" -gt 0 ]'
is "an unowned checkout still reads mcp list from a fresh felix-reach directory" "$([ "$(_ow_reach)" -gt 0 ] && echo yes)" "yes"

printf '\nthe origin is never written anywhere (B7)\n'
OWDISC=1
_ow_co own-sec ownp https://SECRETTOKEN@github.com/OwnerX/ownp-repo.git
_ow_co fork-sec ownp https://SECRETTOKEN@github.com/OwnerX/ownp-repo-fork.git
_ow_run "$OWCO/own-sec"; _owo1="$OWO"; _ow_wait 30 '[ "$(_ow_bg ownp "$OWCO/own-sec" ran)" -ge 1 ]'
is "B7: an origin carrying a token as userinfo is own (it ran)" "$(_ow_n felix "$OWCO/own-sec" commission)" "1"
_ow_run "$OWCO/fork-sec"; _owo2="$OWO"
_ow_has "B7: and the unowned one with a token still says its line" "$OWC" "$OWLINE"
_owo3="$(_ow_lib own 'felix_checkout_is_own "$1" "'"$OWCO/fork-sec"'"; _FELIX_OWN_WITHHELD=tidying; felix_own_withheld_line "$1" "'"$OWCO/fork-sec"'" "'"$OW/h5"'"' "$OWDP" 2>&1)"
_ow_has "B7: the predicate and the line, called directly, answer" "$_owo3" "$OWLINE"
is "B7: no file under the home, the memory root, HOME, TMPDIR or the logs holds the token, nor any output" \
   "$(grep -rlF SECRETTOKEN "$OWH" "$OW/mem" "$OW/user" "$OWT" "$OWL" "$OW/h5" 2>/dev/null; printf '%s\n%s\n%s\n' "$_owo1" "$_owo2" "$_owo3" | grep -c SECRETTOKEN)" "0"

printf '\nend to end with the real CLI (B13), and attended commissioning (section 5)\n'
OWDISC=0; OWHH2="$OW/h2/harness"; mkdir -p "$OW/h2"; cp -R "$FROOT/harness" "$OWHH2"
rm -rf "$OWDP"; cp -R "$OW/ownp.keep" "$OWDP"
printf 'ghrow\t-\t-\t-\t-\tgh repo view >/dev/null 2>&1\t9\n' > "$OWDP/commissioning.tsv"; _ow_stamp ownp
_ow_co own-b13 ownp https://github.com/OwnerX/ownp-repo; _owr="$OWCO/own-b13"; _owl="$OWCO/lookalike"
_ow_run "$_owr" "$OWHH2"; _ow_wait 120 '[ "$(_ow_bg ownp "$_owr" "*")" -ge 1 ]'
is "B13: a granted session start in an own checkout makes the real felix commission run gh there" "$([ "$(_ow_n gh "$_owr" "*")" -ge 1 ] && echo ran)" "ran"
_owb0="$(_ow_bg ownp "$_owl" "*")"; _ow_run "$_owl" "$OWHH2"; _ow_wait 120 '[ "$(_ow_bg ownp "$_owl" "*")" -gt '"$_owb0"' ]'
is "B13: in the lookalike checkout gh logs nothing" "$(_ow_n gh "$_owl" "*")" "0"
is "B13: and the lookalike checkout gains no .github directory" "$([ -e "$_owl/.github" ] && echo made || echo none)" "none"
_ow_att() { ( cd "$1" && shift && _ow_env "$OWHH2/felix" commission "$@" 2>&1 ); }
_owao="$(_ow_att "$_owr")"; _owaorc=$?; _owg0="$(_ow_n gh "$_owl" "*")"
_owal="$(_ow_att "$_owl")"; _owalrc=$?
is "attended felix commission typed in an unowned checkout still runs its rows there" "$([ "$(_ow_n gh "$_owl" "*")" -gt "$_owg0" ] && echo ran)" "ran"
is "and exits as it does in an own checkout" "$_owalrc" "$_owaorc"
is "and prints what it prints there, roots aside" "$(printf '%s' "$_owal" | sed "s|$_owl|ROOT|g")" "$(printf '%s' "$_owao" | sed "s|$_owr|ROOT|g")"
is "felix commission --status likewise" "$(_ow_att "$_owl" --status | sed "s|$_owl|ROOT|g"; printf '|%s' "$?")" \
   "$(_ow_att "$_owr" --status | sed "s|$_owr|ROOT|g"; printf '|%s' "$?")"

printf '\nan engine whose own.sh cannot be sourced fails closed (B42)\n'
OWDISC=0; rm -rf "$OWDP"; cp -R "$OW/ownp.keep" "$OWDP"; _ow_stamp ownp; cp "$OWDP/capabilities" "$OW/caps.keep"
_ow_co own-b42 ownp https://github.com/OwnerX/ownp-repo cargo; _owr="$OWCO/own-b42"
mv "$OWHH/lib/own.sh" "$OW/own.sh.aside" 2>/dev/null
_ow_run "$_owr"
_ow_wait "$OWNEG" '[ "$(_ow_n felix "$_owr" commission)" -gt 0 ] || [ "$(_ow_n graphify "$_owr" "*")" -gt 0 ]'
is "B42: the hook still emits its JSON and exits 0" "$OWRC $(_ow_json systemMessage >/dev/null; echo $?)" "0 0"
is "B42: no commissioning, no graph refresh, no tidying and no adoption ran in an own checkout" \
   "$(_ow_n felix "$_owr" commission) $(_ow_n graphify "$_owr" "*") $([ -e "$_owr/scripts/prepush.sh" ] && echo kept) $(cmp -s "$OW/caps.keep" "$OWDP/capabilities" && echo same)" \
   "0 0 kept same"
[ -e "$OW/own.sh.aside" ] && mv "$OW/own.sh.aside" "$OWHH/lib/own.sh"

printf '\nsize and shape (B40, B41)\n'
_ow_wc() { [ -f "$1" ] && awk 'END { print NR }' "$1" || echo absent; }
# B40 bounded what this build added to three shared files (726, 731, 1516).
# Restated 2026-10-16 to the sizes the weekly batch's slots 7 to 11b leave,
# 36, 78 and 49 lines more than main held: a later change that grows one
# restates its bound here, so the growth is seen in review, never unremarked.
# Restated 2026-10-17 for slots 13 to 20: 18 more lines in session-start (the
# caller-environment preamble every hook gained), 32 in commission.sh (the
# template drift report) and 15 in discover.sh (no digest over a file git
# could not read).
for _f in hooks/session-start:780 lib/commission.sh:808 lib/discover.sh:1580; do
  _owv="$(_ow_wc "$FROOT/harness/${_f%%:*}")"
  [ "$_owv" != absent ] && [ "$_owv" -le "${_f#*:}" ] && ok "B40: ${_f%%:*} is no longer than ${_f#*:} lines" || bad "B40: ${_f%%:*} is no longer than ${_f#*:} lines" "$_owv"
done
for _f in "$FROOT/harness/lib/own.sh" "$FROOT/harness/lib/reach-read.sh" "$HERE/parts/1130-unattended-work-runs-only-in-its-own-checkout.sh"; do
  _owv="$(_ow_wc "$_f")"
  [ "$_owv" != absent ] && [ "$_owv" -lt 500 ] && ok "B40: ${_f##*/} is under 500 lines" || bad "B40: ${_f##*/} is under 500 lines" "$_owv"
done
_ownames=""
for _m in "$REAL_HARNESS"/../../projects/*/project.json; do
  _n="${_m%/project.json}"; _n="${_n##*/}"; [ "$_n" = felix ] && continue
  [ -f "$FROOT/harness/lib/own.sh" ] && grep -qiF -- "$_n" "$FROOT/harness/lib/own.sh" && _ownames="$_ownames $_n"
done
is "B41: lib/own.sh exists and names no governed project" "$([ -f "$FROOT/harness/lib/own.sh" ] && echo present)$_ownames" "present"
is "B41: lib/own.sh parses under /bin/bash and uses no \${x,,}" \
   "$(/bin/bash -n "$FROOT/harness/lib/own.sh" 2>&1 && grep -c ',,}' "$FROOT/harness/lib/own.sh")" "0"
_fx_git "$OWCO/own-https" worktree remove --force "$OWCO/own-wt" >/dev/null 2>&1
[ "$OWBASE" = "$TMP" ] || [ "$OWBASE" = "${RXBASE:-}" ] || { _fx_root_del "$OWBASE"; rm -rf "$OWBASE"; }

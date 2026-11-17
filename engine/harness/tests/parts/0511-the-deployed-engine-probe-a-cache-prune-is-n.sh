printf '\nthe deployed engine probe: a cache prune is not a fact the gate rests on\n'
# Seen 2026-10-08: a gate on main passed after hours, and two minutes later
# the Stop hook called its receipt stale because the grounded facts moved. The
# one fact that had moved was a directory under the plugin cache. Claude Code
# prunes old cached versions, felix's deployed_engine row enumerated every one
# of them, and its count went from 40 to 39, which moved the topology hash.
# Nothing the verdict rests on had moved. The gate's `installed` check and the
# merge judge read one entry, the one for the version main declares; every
# other directory in that cache is history.
#
# The row is read from projects/felix beside this harness and never restated
# here, because what is under test is the table: a copy of the row in the
# suite would keep passing after the table changed. The fixture is a HOME of
# its own, holding a cache with main's entry and one older one and a registry
# naming main's, and a repository whose main declares that version while HEAD
# sits on another branch, so main can move while the tree the receipt names
# stays put. The project directory is outside the fixture home, so no later
# section that lists projects finds it.
DEP_T="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/probes.tsv"
DEP_ROW="$(grep "^deployed_engine$(printf '\t')" "$DEP_T" 2>/dev/null | head -1)"
_dei() { if [ -n "$DEP_ROW" ]; then is  "$@"; else skip "$1" "no deployed_engine row in projects/felix beside this harness"; fi; }
_deh() { if [ -n "$DEP_ROW" ]; then has "$@"; else skip "$1" "no deployed_engine row in projects/felix beside this harness"; fi; }
DEH="$TMP/depeng-home"; DEC="$DEH/.claude/plugins/cache/felix/felix"
mkdir -p "$DEC/0.0.7/harness" "$DEC/0.0.8/harness"
# The registry Claude Code keeps, in its shape: one entry per scope, with the
# version's directory as its installPath.
_de_reg() { printf '{\n  "version": 2,\n  "plugins": {\n    "felix@felix": [\n      {\n        "scope": "user",\n        "installPath": "%s/%s",\n        "version": "%s"\n      }\n    ]\n  }\n}\n' \
              "$DEC" "$1" "$1" > "$DEH/.claude/plugins/installed_plugins.json"; }
_de_reg 0.0.8
DEP="$TMP/depeng-project"; mkdir -p "$DEP"
cat > "$DEP/project.json" <<'EOF'
{
  "name": "depeng",
  "remote_match": "example.com/depeng",
  "gate": "true"
}
EOF
{ printf '# predicate\tgrounds\twhen\tprobe\twitness\n'; printf '%s\n' "$DEP_ROW"; } > "$DEP/probes.tsv"
DER="$TMP/depeng-repo"; mkdir -p "$DER/engine/.claude-plugin"
_de_ver() { printf '{ "name": "felix", "version": "%s" }\n' "$1" > "$DER/engine/.claude-plugin/plugin.json"; }
( _fx_cd "${DER:?}" || exit 1
  git init -q -b main && _de_ver 0.0.8 && git add -A \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm base && git checkout -q -b work ) >/dev/null 2>&1
DER="$(cd "$DER" && pwd -P)"
# Main declares $1 in a commit of its own, and HEAD goes back to `work`, whose
# tree never changed.
_de_main() { ( _fx_cd "${DER:?}" || exit 1
               git checkout -q main && _de_ver "$1" && git add -A \
                 && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm "declare $1" && git checkout -q work ) >/dev/null 2>&1; }
_de_lib()   { . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
              . "$FROOT/harness/lib/probes.sh";  . "$FROOT/harness/lib/epoch.sh"; }
_de_tid()   { ( _fx_cd "${DER:?}" || exit 1; export HOME="$DEH"; _de_lib; felix_tree_id "$DER" "$FROOT" ); }
_de_topo()  { ( _fx_cd "${DER:?}" || exit 1; export HOME="$DEH"; _de_lib; felix_epoch_topology "$DEP" "$DER" ); }
# The row's state as the probe library computes it, for the checkout $1.
_de_state() { ( cd "${1:-${DER:?}}" || exit 1; export HOME="$DEH"; _de_lib; felix_probes_run "$DEP" "${1:-$DER}" ) 2>/dev/null \
                | awk -F'\t' '$1 == "deployed_engine" { print $3 }'; }
_de_rec()   { ( _fx_cd "${DER:?}" || exit 1; export HOME="$DEH"; _de_lib
                felix_verify_record "$DER" "$FROOT" 0 "gate.sh" "$(felix_tree_id "$DER" "$FROOT")" "" "" \
                  "$(felix_epoch "$DEP" "$DER")" \
                  "$(felix_epoch_components "$DEP" "$DER" | cut -f2 | paste -sd, -)" >/dev/null 2>&1 ); }
_de_cur()   { ( _fx_cd "${DER:?}" || exit 1; export HOME="$DEH"; _de_lib; felix_verify_current "$DER" "$FROOT" "$DEP" ) 2>/dev/null; }

_dei "the felix deployed_engine row finds the entry main declares in a fixture cache" "$(_de_state)" "found"
de_tid0="$(_de_tid)"; de_topo0="$(_de_topo)"
# Every "where it was" below compares against these two, and two empty
# strings compare equal: a fixture that computed neither would pass them all.
_dei "the fixture has a tree id and a topology before anything moves" \
     "$( [ -n "$de_tid0" ] && [ -n "$de_topo0" ] && echo both )" "both"
_de_rec
_dei "a green receipt stamped under that cache is current" "$(_de_cur)" "current"

# An install of a version main does not declare, which is what `felix install`
# from a worktree does with every candidate.
mkdir -p "$DEC/0.0.9/harness"
_dei "a version installed beside main's leaves the tree id where it was" "$(_de_tid)" "$de_tid0"
_dei "and leaves the grounded facts where they were" "$(_de_topo)" "$de_topo0"
_dei "so a green receipt stays current across an install main does not declare" "$(_de_cur)" "current"
# And the prune of 2026-10-08: an older version leaves the cache. Stamped
# again first, so the prune is measured on its own. Against the install
# above, a row that counted directories would read the prune as the install
# undone and pass.
_de_rec; de_topo1="$(_de_topo)"
rmdir "$DEC/0.0.7/harness" "$DEC/0.0.7"
_dei "an older version pruned from the cache leaves the grounded facts where they were" "$(_de_topo)" "$de_topo1"
_dei "so a green receipt stays current across a prune" "$(_de_cur)" "current"

# The control, without which the two above prove nothing: the row still moves
# when the entry the verdict rests on goes. With the registry still naming
# that entry, the registry points at nothing, which is blind and blocks.
mv "$DEC/0.0.8" "$DEH/0.0.8.away"
_dei "with main's entry gone and the registry still naming it, the row is blind" "$(_de_state)" "blind"
_deh "and the receipt is stale, because a fact the verdict rests on moved" "$(_de_cur)" "the grounded facts moved"
# Main's entry missing while the registry names another version is not a
# broken probe. It is main's engine not deployed yet, which the gate's
# `installed` check fails on and names the remedy for, so the row reads empty:
# said every time, and never mistaken for a probe that cannot see.
_de_reg 0.0.9
_dei "with the registry naming another version, main's entry missing reads empty, not blind" "$(_de_state)" "empty"
mv "$DEH/0.0.8.away" "$DEC/0.0.8"; _de_reg 0.0.8
_dei "and with main's entry back the same receipt is current again" "$(_de_cur)" "current"

# Main moves on and this tree does not. The entry the verdict rests on is now
# one nothing is installed at, so the receipt is stale until it is deployed,
# and current once it is: the epoch rests on main's entry being there, not on
# which version that is, and not on what else the cache holds.
_de_main 0.0.10
_dei "main declaring a new version leaves this tree id where it was" "$(_de_tid)" "$de_tid0"
_dei "and with nothing installed at that version the row reads empty" "$(_de_state)" "empty"
_deh "so the receipt is stale until main's version is deployed" "$(_de_cur)" "the grounded facts moved"
mkdir -p "$DEC/0.0.10/harness"
_dei "and current again once main's new version is deployed" "$(_de_cur)" "current"

# origin/main before main, the order the gate reads them in: a remote main
# that declares a version nothing is installed at is the one the verdict rests
# on, whatever the local main says. Main is moved on and back, so origin/main
# holds 0.0.11 and main holds 0.0.10, which is installed.
_de_main 0.0.11
( _fx_cd "${DER:?}" || exit 1
  git update-ref refs/remotes/origin/main main && git update-ref refs/heads/main main~1 ) >/dev/null 2>&1
_dei "a remote main declaring a version nothing is installed at reads empty over an installed local main" \
     "$(_de_state)" "empty"

# A checkout that cannot say what main declares cannot say which entry the
# verdict rests on. Unknown blocks, and empty here would be the permissive
# misreading; the gate's `installed` check fails the same checkout.
DEN="$TMP/depeng-nomain"; mkdir -p "$DEN"
( _fx_cd "${DEN:?}" || exit 1
  git init -q -b trunk && printf 'x\n' > x && git add -A \
    && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -qm x ) >/dev/null 2>&1
_dei "a checkout with no main to read leaves the row unknown, never empty" "$(_de_state "$DEN")" "unknown"

printf '\ndeployed_engine counts the entry main declares, and no other version in the cache\n'
# Felix's own probes.tsv carries a deployed_engine row. On 2026-10-08 Claude
# Code pruned one old cached version, the row's count went 40 -> 39, and a green
# receipt went stale for a world in which nothing main accepted had moved. The
# member COUNT is in the topology hash and the member names are not, so the
# row's contract is that it counts one thing: the entry for the version main
# declares, installed (a harness/ subdirectory), whatever else the cache holds.
#
# Authored blind to the row, from the contract in prose. The row is read from
# the table under test and copied into a fixture project, never restated here,
# so this block judges whatever the table holds. Fixture choices that carry it:
#
#   - a fixture HOME, exported only inside the subshells that run probes,
#     epochs and receipts, holding a felix/felix cache and a registry;
#   - a fixture checkout whose HEAD sits on a branch of its own that declares a
#     newer candidate version, installed too, so a probe that read the working
#     tree instead of main would be found where main's entry is missing;
#   - main and origin/main moved with update-ref only, so the tree id the
#     receipt is keyed on never moves and every stale verdict below is the
#     epoch's, never the tree check's;
#   - main declares 0.49.27 and 0.49.270 is always installed beside it, so a
#     prefix match on the version string is caught both in the cache and in
#     the registry.
BLTABLE="$(cd "$REAL_HARNESS/../.." && pwd)/projects/felix/probes.tsv"
BLROW="$(grep "^deployed_engine$(printf '\t')" "$BLTABLE" 2>/dev/null | sed -n 1p)"
BLWHY="no deployed_engine row in $BLTABLE"

# Assertions route through these, so that with no row every one of them is a
# named skip rather than a pass or a failure about a probe that does not exist.
_bl_is()  { if [ -n "$BLROW" ]; then is  "$1" "$2" "$3"; else skip "$1" "$BLWHY"; fi; }
_bl_has() { if [ -n "$BLROW" ]; then has "$1" "$2" "$3"; else skip "$1" "$BLWHY"; fi; }
# Equal AND non-empty: two hashes that both failed to compute are not a match.
_bl_same() {
  [ -n "$BLROW" ] || { skip "$1" "$BLWHY"; return 0; }
  if [ -n "$2" ] && [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi
}
# Passes when the value is non-empty and is none of the words after it.
_bl_none() {
  local _bl_n="$1" _bl_g="$2" _bl_w; shift 2
  [ -n "$BLROW" ] || { skip "$_bl_n" "$BLWHY"; return 0; }
  [ -n "$_bl_g" ] || { bad "$_bl_n" "the row produced no state at all"; return 0; }
  for _bl_w in "$@"; do
    [ "$_bl_g" = "$_bl_w" ] && { bad "$_bl_n" "got [$_bl_g]"; return 0; }
  done
  ok "$_bl_n"
}

# ------------------------------------------------------------- fixture ------
# The versions. Main declares BLVMAIN; origin and a later main declare BLVNEXT;
# the checked-out branch declares BLVCAND, a candidate installed from a
# worktree; BLVPRE has main's version as a prefix; BLOLD is forty older ones.
BLVMAIN=0.49.27; BLVNEXT=0.49.28; BLVPRE=0.49.270; BLVCAND=0.49.300; BLVCAND2=0.49.301
BLOLD=""; for ((_bl_i = 200; _bl_i < 240; _bl_i++)); do BLOLD="$BLOLD 0.48.$_bl_i"; done

BLHOME="$TMP/bl-home"; BLBARE="$TMP/bl-home-bare"; BLFH="$TMP/bl-felix-home"
mkdir -p "$BLHOME" "$BLBARE" "$BLFH"
# Resolved, because the registry records absolute paths and a probe that
# compares them with a resolved $HOME must see the same spelling.
BLHOME="$(cd "$BLHOME" || exit 1; pwd -P)"; BLBARE="$(cd "$BLBARE" || exit 1; pwd -P)"
BLC="$BLHOME/.claude/plugins/cache/felix/felix"
BLREG="$BLHOME/.claude/plugins/installed_plugins.json"

_bl_inst() {   # version: an installed entry, harness/ and all
  mkdir -p "$BLC/$1/harness" "$BLC/$1/.claude-plugin"
  printf '#!/bin/sh\n' > "$BLC/$1/harness/felix"
  printf '{\n  "name": "felix",\n  "version": "%s"\n}\n' "$1" > "$BLC/$1/.claude-plugin/plugin.json"
}
_bl_bare() {   # version: the directory exists and holds no harness/
  rm -rf "${BLC:?}/${1:?}"
  mkdir -p "$BLC/$1/.claude-plugin"
  printf '{\n  "name": "felix",\n  "version": "%s"\n}\n' "$1" > "$BLC/$1/.claude-plugin/plugin.json"
}
_bl_uninst() { rm -rf "${BLC:?}/${1:?}"; }
# The Claude Code plugin registry, in the shape it writes: another plugin
# first, whose version is $3 (default 1.0.0), then felix's entry naming $2 as
# its installPath. `-` for $2 removes the registry.
_bl_reg_at() {
  mkdir -p "$1/.claude/plugins"
  [ "$2" = "-" ] && { rm -f "$1/.claude/plugins/installed_plugins.json"; return 0; }
  cat > "$1/.claude/plugins/installed_plugins.json" <<BLREGEOF
{
  "version": 2,
  "plugins": {
    "other@market": [
      {
        "scope": "user",
        "installPath": "$1/.claude/plugins/cache/market/other/${3:-1.0.0}",
        "version": "${3:-1.0.0}",
        "installedAt": "2026-10-01T00:00:00.000Z",
        "lastUpdated": "2026-10-01T00:00:00.000Z"
      }
    ],
    "felix@felix": [
      {
        "scope": "user",
        "installPath": "$1/.claude/plugins/cache/felix/felix/$2",
        "version": "$2",
        "installedAt": "2026-10-08T00:00:00.000Z",
        "lastUpdated": "2026-10-08T00:00:00.000Z",
        "gitCommitSha": "0000000000000000000000000000000000000000"
      }
    ]
  }
}
BLREGEOF
}
_bl_reg() { _bl_reg_at "$BLHOME" "$@"; }

# Git in the fixture runs under the fixture HOME, so no global config, hook
# path or excludes file of this machine reaches it.
BLREPO="$TMP/bl-repo"; mkdir -p "$BLREPO"
_bl_git() { [ -n "$BLREPO" ] || return 1; ( export HOME="$BLHOME"; unset XDG_CONFIG_HOME
              _fx_git "$BLREPO" -c user.name=t -c user.email=t@t -c commit.gpgsign=false \
                -c core.hooksPath=/dev/null "$@" ); }
_bl_manifest() {   # version, `-` for a manifest with no version, `none` for no manifest
  mkdir -p "$BLREPO/engine/.claude-plugin"
  case "$1" in
    none) rm -f "$BLREPO/engine/.claude-plugin/plugin.json" ;;
    -)    printf '{\n  "name": "felix",\n  "description": "fixture engine"\n}\n' \
            > "$BLREPO/engine/.claude-plugin/plugin.json" ;;
    *)    printf '{\n  "name": "felix",\n  "version": "%s",\n  "description": "fixture engine"\n}\n' "$1" \
            > "$BLREPO/engine/.claude-plugin/plugin.json" ;;
  esac
}
_bl_commit() { _bl_git add -A >/dev/null 2>&1; _bl_git commit -qm "$1" >/dev/null 2>&1; _bl_git rev-parse HEAD 2>/dev/null; }
_bl_git init -q -b main >/dev/null 2>&1
BLREPO="$(cd "$BLREPO" || exit 1; pwd -P)"
# The checkout looks like the one the row is written for: an engine with the
# libraries under test in it, so a row that reads them from the checkout can.
mkdir -p "$BLREPO/engine/harness"; printf '#!/bin/sh\n' > "$BLREPO/engine/harness/felix"
cp -R "$FROOT/harness/lib" "$BLREPO/engine/harness/lib"
_bl_manifest "$BLVMAIN"; BLCMAIN="$(_bl_commit "main declares $BLVMAIN")"
_bl_manifest "$BLVNEXT"; BLCNEXT="$(_bl_commit "main declares $BLVNEXT")"
_bl_manifest -;          BLCNOVER="$(_bl_commit "a manifest with no version")"
_bl_manifest none;       BLCNOMAN="$(_bl_commit "no manifest at all")"
_bl_git checkout -q -b work "$BLCMAIN" >/dev/null 2>&1
_bl_manifest "$BLVCAND"; BLCWORK="$(_bl_commit "the candidate bump on its own branch")"

_bl_ref() {   # main|origin, a commit or `-` to delete the ref
  local _bl_r=refs/heads/main
  [ "$1" = origin ] && _bl_r=refs/remotes/origin/main
  if [ "$2" = "-" ]; then _bl_git update-ref -d "$_bl_r" >/dev/null 2>&1 || true
  else _bl_git update-ref "$_bl_r" "$2" >/dev/null 2>&1; fi
}

# The project: the row under test, verbatim, and a project.json for the subject.
BLPROJ="$TMP/bl-projects/blengine"; mkdir -p "$BLPROJ"
cat > "$BLPROJ/project.json" <<'BLPJEOF'
{
  "name": "blengine",
  "remote_match": "example.com/blengine",
  "gate": "true"
}
BLPJEOF
printf '# predicate\tgrounds\twhen\tprobe\twitness\n%s\n' "$BLROW" > "$BLPROJ/probes.tsv"

# The bare HOME: a registry that names main's version, and a plugin cache with
# another marketplace in it, but no felix/felix.
mkdir -p "$BLBARE/.claude/plugins/cache/market/other/1.0.0"
_bl_reg_at "$BLBARE" "$BLVMAIN"

# The baseline: main at BLVMAIN with no origin/main, the registry naming the
# live candidate, and forty-three versions cached, main's among them.
_bl_reset() {
  _bl_ref main "$BLCMAIN"; _bl_ref origin -
  rm -rf "${BLC:?}"; mkdir -p "$BLC"
  for _bl_v in "$BLVMAIN" "$BLVPRE" "$BLVCAND" $BLOLD; do _bl_inst "$_bl_v"; done
  _bl_reg "$BLVCAND"
}

# The sourcing shape the reader is specified under, and the environment every
# probe, epoch and receipt call runs in: the fixture HOME and nothing that
# relocates the plugin cache or the release target.
_bl_lib() { . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
            . "$FROOT/harness/lib/probes.sh";  . "$FROOT/harness/lib/epoch.sh"; }
_bl_env() { export HOME="${1:-$BLHOME}"; unset FELIX_KERNEL_CACHE FELIX_PLUGIN_CACHE FELIX_RELEASE_TARGET XDG_CONFIG_HOME; }
_bl_probe() {   # [home] -> state <TAB> count of the deployed_engine row
  [ -n "$BLROW" ] || return 0
  ( cd "${BLREPO:?}" || exit 1; _bl_env "${1:-}"; _bl_lib
    felix_probes_run "$BLPROJ" "$BLREPO" ) 2>/dev/null \
    | awk -F'\t' '$1 == "deployed_engine" { print $3 "\t" $4 }'
}
_bl_state() { _bl_probe "$@" | cut -f1; }
_bl_sc()    { _bl_probe "$@" | tr '\t' ' '; }
_bl_tid()   { [ -n "$BLROW" ] || return 0
              ( cd "${BLREPO:?}" || exit 1; _bl_env; _bl_lib; felix_tree_id "$BLREPO" "$BLFH" ) 2>/dev/null; }
_bl_topo()  { [ -n "$BLROW" ] || return 0
              ( cd "${BLREPO:?}" || exit 1; _bl_env; _bl_lib; felix_epoch_topology "$BLPROJ" "$BLREPO" ) 2>/dev/null; }
_bl_stamp() { [ -n "$BLROW" ] || return 0
              ( cd "${BLREPO:?}" || exit 1; _bl_env; _bl_lib
                felix_verify_record "$BLREPO" "$BLFH" 0 "gate.sh" "$(felix_tree_id "$BLREPO" "$BLFH")" "" "" \
                  "$(felix_epoch "$BLPROJ" "$BLREPO")" \
                  "$(felix_epoch_components "$BLPROJ" "$BLREPO" | cut -f2 | paste -sd, -)" ) >/dev/null 2>&1; }
_bl_cur()   { [ -n "$BLROW" ] || return 0
              ( cd "${BLREPO:?}" || exit 1; _bl_env; _bl_lib
                felix_verify_current "$BLREPO" "$BLFH" "$BLPROJ" ) 2>/dev/null; }

# ------------------------------------------- 1. where the row applies ------
_bl_reset
_bl_is "deployed_engine: under a HOME with no felix/felix plugin cache the row is not-applicable, even with a registry naming main's version" \
  "$(_bl_state "$BLBARE")" "not-applicable"
rm -rf "${BLC:?}"; mkdir -p "$BLC"
_bl_is "deployed_engine: an empty felix/felix cache makes the row apply, and with nothing installed and the registry naming another version it is empty" \
  "$(_bl_state)" "empty"

# ------------------------------ 2. one member: main's entry, installed ------
_bl_reset
_bl_is "deployed_engine: main's $BLVMAIN installed among forty-two other cached versions is found with exactly one member" \
  "$(_bl_sc)" "found 1"
_bl_uninst 0.48.200
_bl_is "deployed_engine: an older version pruned from the cache leaves the row found with one member" \
  "$(_bl_sc)" "found 1"
_bl_inst "$BLVCAND2"
_bl_is "deployed_engine: a newer candidate installed beside main's entry leaves the row found with one member" \
  "$(_bl_sc)" "found 1"
_bl_reset; _bl_bare "$BLVMAIN"
_bl_is "deployed_engine: main's version directory with no harness subdirectory is not installed, so with the registry naming another version the row is empty" \
  "$(_bl_state)" "empty"
_bl_reset; _bl_uninst "$BLVMAIN"
_bl_is "deployed_engine: with main's $BLVMAIN gone, neither the checked-out branch's installed $BLVCAND nor an installed $BLVPRE stands in for it" \
  "$(_bl_sc)" "empty 0"

# origin/main before main, and local main only when origin/main does not resolve.
_bl_reset; _bl_ref origin "$BLCNEXT"
_bl_is "deployed_engine: origin/main is read before local main, so origin's $BLVNEXT uninstalled is empty though local main's $BLVMAIN is installed" \
  "$(_bl_state)" "empty"
_bl_inst "$BLVNEXT"
_bl_is "deployed_engine: and once origin's $BLVNEXT is installed the row is found with one member, local main's entry not counted beside it" \
  "$(_bl_sc)" "found 1"
_bl_uninst "$BLVMAIN"
_bl_is "deployed_engine: while origin/main resolves, local main's own entry going away changes nothing" \
  "$(_bl_sc)" "found 1"
_bl_inst "$BLVMAIN"; _bl_uninst "$BLVNEXT"; _bl_ref origin -
_bl_is "deployed_engine: with origin/main deleted, local main is read and its installed $BLVMAIN is found with one member" \
  "$(_bl_sc)" "found 1"

# ------------------------------- 3. missing: blind or empty, by registry ------
_bl_reset; _bl_uninst "$BLVMAIN"; _bl_reg "$BLVMAIN"
_bl_is "deployed_engine: main's entry missing while the registry names main's version as felix's installPath is blind" \
  "$(_bl_state)" "blind"
_bl_reg "$BLVCAND"
_bl_is "deployed_engine: main's entry missing while the registry names another version is empty, never blind" \
  "$(_bl_state)" "empty"
_bl_reg "$BLVPRE"
_bl_is "deployed_engine: a registry naming $BLVPRE does not name main's $BLVMAIN, so the row is empty, not blind" \
  "$(_bl_state)" "empty"
_bl_reg "$BLVCAND" "$BLVMAIN"
_bl_is "deployed_engine: another plugin's registry entry carrying main's version string does not make felix's entry name it, so the row is empty" \
  "$(_bl_state)" "empty"
_bl_reg -
_bl_none "deployed_engine: with no registry at all, main's missing entry is neither found nor blind" \
  "$(_bl_state)" found blind
_bl_bare "$BLVMAIN"; _bl_reg "$BLVMAIN"
_bl_is "deployed_engine: a registry naming main's version over a directory with no harness subdirectory is blind" \
  "$(_bl_state)" "blind"

# --------------------------------- 4. main's version cannot be read ------
_bl_reset; _bl_ref main -
_bl_is "deployed_engine: with neither origin/main nor main in the checkout the row is unknown" \
  "$(_bl_state)" "unknown"
_bl_ref main "$BLCNOVER"
BLS1="$(_bl_state)"; _bl_reg -; BLS2="$(_bl_state)"; _bl_reg "$BLVMAIN"; BLS3="$(_bl_state)"
_bl_is "deployed_engine: a main whose plugin.json declares no version is unknown whatever the registry names, with the checked-out version installed" \
  "$BLS1 $BLS2 $BLS3" "unknown unknown unknown"
_bl_reg "$BLVCAND"; _bl_ref main "$BLCNOMAN"
_bl_is "deployed_engine: a main with no plugin.json at all is unknown" \
  "$(_bl_state)" "unknown"
_bl_ref main "$BLCMAIN"; _bl_ref origin "$BLCNOVER"
_bl_is "deployed_engine: an origin/main that declares no version is unknown, though local main declares an installed version" \
  "$(_bl_state)" "unknown"
_bl_ref origin -

# --------------------------------------------- 5. what a receipt rests on ------
_bl_reset
BLT0="$(_bl_tid)"
_bl_stamp
_bl_is "deployed_engine: a green receipt stamped with main's entry installed among forty-three versions is current" \
  "$(_bl_cur)" "current"
BLH0="$(_bl_topo)"
_bl_uninst 0.48.200
_bl_same "deployed_engine: pruning one of the forty older cached versions leaves the topology hash where it was" \
  "$(_bl_topo)" "$BLH0"
_bl_is "deployed_engine: so the green receipt stays current after the prune, which is the 2026-10-08 incident" \
  "$(_bl_cur)" "current"
# Stamped again before each movement, so that no step can pass by undoing the
# one before it: a prune and an install would cancel in a count of every entry.
_bl_stamp
_bl_inst "$BLVCAND2"
_bl_is "deployed_engine: a receipt stamped after the prune stays current when a newer candidate is installed beside main's entry" \
  "$(_bl_cur)" "current"
_bl_stamp
_bl_uninst "$BLVMAIN"
_bl_has "deployed_engine: the control: main's own entry going away stales the receipt because the grounded facts moved" \
  "$(_bl_cur)" "the grounded facts moved"
_bl_inst "$BLVMAIN"
_bl_is "deployed_engine: and with main's entry reinstalled the same receipt is current again" \
  "$(_bl_cur)" "current"
_bl_ref main "$BLCNEXT"
_bl_same "deployed_engine: the fixture: main moving to declare $BLVNEXT leaves the checkout's tree id where the receipt has it" \
  "$(_bl_tid)" "$BLT0"
_bl_has "deployed_engine: main coming to declare $BLVNEXT, which is not installed, stales the receipt because the grounded facts moved" \
  "$(_bl_cur)" "the grounded facts moved"
_bl_inst "$BLVNEXT"
_bl_is "deployed_engine: and once $BLVNEXT is installed the same receipt is current again" \
  "$(_bl_cur)" "current"
_bl_reset

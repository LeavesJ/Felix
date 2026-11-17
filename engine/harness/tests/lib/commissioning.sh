# tests/lib/commissioning.sh: the commissioning fixture, cmproj, and its helpers.
# Used by 0650 (builds it), 0660 0670 0680 0681 0690 0700 (each reads it as the part
# before left it) and 0710 (reads it as 0700 left it). Moved from
# parts/0650-ecosystem.sh: the fixture from lines 269-279 (CMP, CMR, the
# repository, the project files), _cmtable from 280-281, _cm from 282-287 and
# the twelve-row table from 291-302; from parts/0700-continued.sh: _cmcli from
# line 128 and _cmp from line 355. All verbatim; the fixture and the table are
# indented into the builder, and _cm stands at the top level of this file.
# Definitions only. _commissioning_build STATE sets CMP and CMR (and, for the
# state that needs them, CMS, _cmans and _cmreq) before it looks at anything,
# and does nothing more once the fixture (cmproj and its repository) is there, so
# in the serial run only 0650's call builds. STATE names what it leaves:
#   alpha12     the fixture 0650 builds and asserts over: the twelve-row table
#               (eight valid rows, four malformed), an empty capabilities file,
#               no receipt and no log. 0650 0660 0670 0680 and 0690 start here.
#   after-0690  alpha12, then the two-row table, alpha and automation_surveyed,
#               that 0690 leaves in $CMP/commissioning.tsv. 0700 starts here.
#   after-0700  after-0690, then what 0700 leaves for 0710, by the commands that
#               left it: the stranger project `felix new cmstranger` makes in
#               $CMS, the three-row table with two provider rows, an empty log,
#               _cmtopo, the request a full run writes, the answer file $_cmans
#               with four rows, and _cmo, the output of a full run over it.
# _cm is defined here, at the top level of the file. 0370 used to define a
# different _cm (felix_capability_match), which made this file define it inside
# the builder; 0370 now calls its own _capmatch. _cmmal is the
# malformed rows of the twelve-row table: 0650 sets it as it asserts over it, and
# the builder sets it only when it is unset, so that 0690 can read it alone.
# _cmstub_build (cm-stub.sh) gives the CMSTUB that _cm puts first on PATH.

# _cm CMD ARG...: CMD, run in a subshell with the libraries the commissioning
# assertions read sourced and the claude stub first on PATH.
_cm() { ( FELIX_HOME_DIR="$FROOT"; PATH="$CMSTUB:$PATH"
          . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/stack.sh"
          . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/toolbox.sh"
          . "$FROOT/harness/lib/discover.sh"; . "$FROOT/harness/lib/ready.sh"; . "$FROOT/harness/lib/commission.sh"
          . "$FROOT/harness/lib/commission-provider.sh"
          "$@" ); }

# _cmtable ROW...: writes $CMP/commissioning.tsv, the header and then the rows given.
_cmtable() { { printf '# need\tgrounds\tinstrument\twhen\tanswer\tcheck\tstep\n'
               for r in "$@"; do printf '%s\n' "$r"; done; } > "$CMP/commissioning.tsv"; }

# _cmcli ARG...: felix commission, run in the checkout $CMR.
_cmcli() { ( cd "$CMR" && PATH="$CMSTUB:$PATH" "$FELIX" commission "$@" 2>&1 ); }

# _cmp NEED: the state of one provider row, its first field.
_cmp() { _cm felix_commission_provider_state "$CMP" "$CMR" "$1" | cut -f1; }

# _commissioning_build STATE: see the head of this file.
_commissioning_build() {
  local state="${1:-alpha12}"
  _cmstub_build
  CMP="$FROOT/projects/cmproj"; CMR="$TMP/cm-repo"
  if [ "$state" = after-0700 ]; then
    CMS="$TMP/cm-stranger"
    _cmreq="$MEM/cmproj/commission/requests/automation_surveyed.md"
    _cmans="$MEM/cmproj/commission/automation_surveyed.tsv"
  fi
  if [ -f "$CMP/project.json" ] && [ -f "$CMR/.felix" ]; then
    CMR="$(cd "$CMR" && pwd -P)"
    [ -n "${_cmmal+x}" ] || _cmmal="$(_cm felix_commission_malformed "$CMP")"
    return 0
  fi
  mkdir -p "$CMP" "$CMR/src" "$MEM/cmproj"
  ( _fx_cd "$CMR" && git init -q -b main && printf 'x\n' > src/a.txt && printf 'KEY=\n' > .env.example
    git add -A && git -c user.name=t -c user.email=t@t commit -qm init
    printf 'y\n' > src/b.txt && git add -A && git -c user.name=t -c user.email=t@t commit -qm two ) >/dev/null 2>&1
  CMR="$(cd "$CMR" && pwd -P)"
  printf 'cmproj\n' > "$CMR/.felix"
  printf '{"name":"cmproj","gate":"true"}\n' > "$CMP/project.json"
  : > "$CMP/capabilities"
  printf '# k\tn\ts\tr\tc\n' > "$CMP/stack.tsv"
  cp "$FROOT/harness/templates/profiles.tsv" "$FROOT/harness/templates/routes.tsv" "$CMP/"
  _cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
           'plain	-	-	-	-	printf x | grep -q x	9' \
           'beta	-	-	-	felix:toolbox --route	test -f src/made-by-answer	5' \
           'gamma	-	definitely-not-a-real-command-xyz	-	-	true	5' \
           'delta	-	-	definitely-not-a-real-command-xyz	-	true	5' \
           'eps	billing	-	-	-	true	6' \
           'zeta	-	-	-	-	[ -z "$(felix_no_such_function)" ]	7' \
           'eta	-	-	-	-	! true	9' \
           'theta	-	-	-	felix:rm -rf	true	9' \
           'iota	-	-	-	-	true	99' \
           'kappa	-	-	-	-	true' \
           'prov	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
  _cmmal="$(_cm felix_commission_malformed "$CMP")"
  case "$state" in
    after-0690|after-0700)
      _cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
               'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4'
      ;;
  esac
  [ "$state" = after-0700 ] || return 0
  # What 0700 leaves for 0710 (0700 lines 244-248 and 351-358, and the full runs).
  mkdir -p "$CMS"
  ( _fx_cd "$CMS" && git init -q -b main ) >/dev/null 2>&1
  printf '{ "name": "cms", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > "$CMS/package.json"
  : > "$CMSTUB_LOG"
  ( cd "$CMS" && PATH="$CMSTUB:$PATH" "$FELIX" new cmstranger >/dev/null 2>&1 )
  _cmtable 'alpha	-	-	-	-	test -f src/a.txt	3' \
           'automation_surveyed	-	-	-	provider:claude-code-setup:claude-automation-recommender	-	4' \
           'constitution_audited	-	-	-	provider:claude-md-management:claude-md-improver	-	4'
  rm -rf "$MEM/cmproj/commission"; : > "$MEM/cmproj/commissioning.log"
  _cmtopo="$(_cm felix_commission_topology "$CMP" "$CMR")"
  _cmcli >/dev/null 2>&1
  printf '# topology %s\nplugin\tfoo\t-\tllm\twhy\nplugin\tbar\t-\tllm\twhy\thigh\nrocket\tbaz\t-\t-\twhy\nmcp\tsentry\t-\tobservability\twhy\ndone\t4\n' "$_cmtopo" > "$_cmans"
  _cmo="$(_cmcli)"
}

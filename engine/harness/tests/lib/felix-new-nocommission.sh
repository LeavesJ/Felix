# tests/lib/felix-new-nocommission.sh: the felix new --no-commission fixture.
# Used by parts 0820 (builds it) 0840 0850. Moved from
# parts/0820-felix-new-no-commission-governed-not-commiss.sh: lines 2-13 (NC and the _nc* functions; NC into _nc_build).
# The loop that cuts the five repositories 0820 alone reads stays in 0820.
# Definitions only. A builder does nothing more when its fixture is already there.

_nc_repo() { mkdir -p "$NC/$1"
  ( _fx_cd "$NC/$1" && git init -q -b main \
    && printf '{ "name": "cheap", "scripts": { "verify": "echo ok" }, "dependencies": { "express": "^4" } }\n' > package.json ) >/dev/null 2>&1; }
_nc() {  # cwd, then felix new's arguments; the stub's calls land in CMSTUB_LOG
  local d="$1"; shift; : > "$CMSTUB_LOG"
  ( cd "$d" && HOME="$NC/userhome" FELIX_HOME="$NC/home" FELIX_MEMORY="$NC/mem" PATH="$CMSTUB:$PATH" "$FELIX" new "$@" ) 2>&1; }
_nc_calls() { grep -c . "$CMSTUB_LOG" 2>/dev/null | tr -d ' '; }
_nc_ls()    { ( cd "$NC/home/projects/$1" 2>/dev/null && find . -print | LC_ALL=C sort | tr '\n' ' ' ); }
_nc_bound() { [ "$(cat "$NC/$1/.felix" 2>/dev/null)" = "$2" ] && [ -f "$NC/home/projects/$2/project.json" ]; }

# _nc_build: NC, its own home, memory root and user home, and the claude stub the
# _nc runs put first on PATH (cm-stub.sh). mkdir -p of what is there changes nothing.
_nc_build() {
  _cmstub_build
# Its own home and memory root, so no project here is enumerated by the widget
# fixture's tests, and the same stub as every other felix new in this file.
NC="$TMP/nocommission"; mkdir -p "$NC/home/projects" "$NC/mem" "$NC/userhome"; NC="$(cd "$NC" && pwd -P)"
}

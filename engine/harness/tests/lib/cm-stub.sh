# tests/lib/cm-stub.sh: the `claude` stub on PATH, the ungoverned repository, and
# the stranger project; and the other projects whose stack.tsv carries the
# grounding column, which part 0710 judges every row of (contract D, R9).
# Used by parts 0010 (builds all three), 0070 0180 0190 0220 0400 0450 0580 0650
# 0660-0711 0720 0730 0780 0820 0850 (CMSTUB, CMSTUB_LOG), 0070 0200 0220 0250
# 0600 (PLAIN) and 0200 0780 (the stranger project). Moved from
# parts/0010-resolution.sh: _plain_build from line 33 (PLAIN), _cmstub_build from
# lines 183-196 (CMSTUB, CMSTUB_LOG, the stub), _stranger_build from lines 184-193.
# Also 0060 (builds hookproj), 0190 (setupproj), 0700 (cmseventh) and 0710, which
# calls every one of them: _hookproj_build from parts/0060 (HOOKREPO, 396-409),
# _setupproj_build from parts/0190 (175-181), _cmseventh_build from parts/0700
# (520-526). _grounded_projects names what the builders in this file make, and
# cmstranger, which 0710 makes itself with _commissioning_build (commissioning.sh).
# Definitions only. A builder sets its variables first and does nothing more when
# its fixture is already there, so in the serial run only the first caller builds.

# _plain_build: PLAIN is $TMP/unrelated, an ungoverned git repository.
_plain_build() {
  PLAIN="$TMP/unrelated"
  [ -d "$PLAIN/.git" ] && return 0
  mkdir -p "$PLAIN"; ( _fx_cd "$PLAIN" && git init -q -b main )
}

# _cmstub_build: A `claude` that logs every argument line and REFUSES any shape the suite
# never taught it, so an assertion that depends on it can fail. It exists
# because felix new now commissions — runs discover --adopt, stack apply
# --yes and ready --fix — and the real cli on this machine would take those
# to the network. Every test that runs felix new goes through it.
# CMSTUB is the directory holding the stub, CMSTUB_LOG its log (truncated when
# the stub is built, left as it stands when it already exists).
_cmstub_build() {
  CMSTUB="$TMP/cm-stub"; CMSTUB_LOG="$TMP/cm-stub.log"
  [ -x "$CMSTUB/claude" ] && return 0
  mkdir -p "$CMSTUB"; : > "$CMSTUB_LOG"
  cat > "$CMSTUB/claude" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CMSTUB_LOG"
case "\$*" in
  "plugin list --json"|"plugin list --json --available") printf '[]\n' ;;
  "plugin marketplace list"*|"mcp list"*) : ;;
  "plugin install "*|"plugin enable "*|"plugin marketplace add "*|"plugin update"*) : ;;
  *) printf 'stub: untaught shape: %s\n' "\$*" >&2; exit 2 ;;
esac
STUB
  chmod +x "$CMSTUB/claude"
}

# _stranger_build: the stranger project, which 0010 onboards with felix new and
# 0200 (its generated constitution) and 0780 (its exceptions table) read after
# it. Moved from parts/0010-resolution.sh, lines 184-193: a Node app with no git
# remote, nothing to do with anything already here, and `felix new stranger`
# over it through the claude stub. Sets STRANGE, and _stranger_out and
# _stranger_rc, felix new's output and exit status, which 0010 asserts over; they
# are set only when this call builds. Does nothing more once the project
# ($FROOT/projects/stranger) and the checkout's binding are there, so in the
# serial run only 0010's call builds.
_stranger_build() {
  STRANGE="$TMP/stranger"
  [ -f "$FROOT/projects/stranger/project.json" ] && [ -f "$STRANGE/.felix" ] && return 0
  _cmstub_build
  mkdir -p "$STRANGE"
  ( _fx_cd "$STRANGE" && git init -q -b main )
  cat > "$STRANGE/package.json" <<'JSON'
{ "name": "stranger", "scripts": { "verify": "echo ok" },
  "dependencies": { "express": "^4", "stripe": "^17" },
  "devDependencies": { "playwright": "^1" } }
JSON
  _stranger_out="$(cd "$STRANGE" && PATH="$CMSTUB:$PATH" "$FELIX" new stranger 2>&1)"; _stranger_rc=$?
}

# _fsgh_build: the gh and ssh stubs 0190 asks about setup rows with (0190:152-181 made them in the part), in $TMP/fs-gh,
# and _fs_path, the PATH 0190's commands and _setupproj_build's felix new run with: the stubs, the claude stub, PATH.
# Sets _fs_gh, _fs_ghlog, _fs_sshlog and _fs_path; makes the directory only when it is not there.
_fsgh_build() {
  _cmstub_build
  _fs_gh="$TMP/fs-gh"; _fs_ghlog="$TMP/fs-gh.log"; _fs_sshlog="$TMP/fs-ssh.log"; _fs_path="$_fs_gh:$CMSTUB:$PATH"
  [ -x "$_fs_gh/gh" ] && [ -x "$_fs_gh/ssh" ] && return 0
  mkdir -p "$_fs_gh"; : > "$_fs_ghlog"
cat > "$_fs_gh/gh" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$_fs_ghlog"
case "\$*" in
  *"--repo acme/widget"*) printf 'needs-founder\nANTHROPIC_API_KEY\n'; exit 0 ;;
esac
printf 'no git remotes found\n' >&2
exit 1
STUB
chmod +x "$_fs_gh/gh"
# ssh, for the one question the engine asks it: `ssh -G <host>`, what an ssh
# alias stands for. The real one reads the person's own ~/.ssh/config, found
# through the password database rather than $HOME, so no suite HOME can hide
# it; this one knows a single alias, `work`, standing for github.com, and reads
# any other host back as itself, which is what ssh -G does for a host nothing
# configures. It logs its arguments, and refuses anything but -G.
: > "$_fs_sshlog"
cat > "$_fs_gh/ssh" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$_fs_sshlog"
[ "\${1:-}" = "-G" ] || { printf 'stub: only -G\n' >&2; exit 255; }
for _h in "\$@"; do :; done
case "\$_h" in
  work) printf 'user git\nhostname github.com\nport 22\n' ;;
  *)    printf 'user git\nhostname %s\nport 22\n' "\$_h" ;;
esac
STUB
chmod +x "$_fs_gh/ssh"
}

# _setupproj_build: setupproj, which 0190 onboards with felix new --no-commission in
# a checkout with a CI workflow and no remote, and 0710 reads the manifest of. Sets
# _fs_n (the checkout, physical), _fs_p (the project) and _fs_nrc (felix new's exit
# status; set only when this call builds). felix new runs with 0190's gh stub directory first on PATH (_fsgh_build), as 0190 does.
_setupproj_build() {
  _fs_p="$FROOT/projects/setupproj"
  [ -f "$_fs_p/project.json" ] && [ -f "$TMP/fs-new/.felix" ] && { _fs_n="$(cd "$TMP/fs-new" && pwd -P)"; return 0; }
  _fsgh_build
  _fs_n="$TMP/fs-new"; mkdir -p "$_fs_n/.github/workflows"
  ( _fx_cd "$_fs_n" && git init -q -b main ) >/dev/null 2>&1
  printf 'on: push\n' > "$_fs_n/.github/workflows/ci.yml"
  _fs_n="$(cd "$_fs_n" && pwd -P)"
  ( cd "$_fs_n" && PATH="$_fs_path" "$FELIX" new setupproj --no-commission ) >/dev/null 2>&1; _fs_nrc=$?
}

# _cmseventh_build: cmseventh, a web application with a file named hooks.json, which 0700
# creates with felix new and asks about its obligations. Sets CMW and _cmw (felix
# new's output; set only when this call builds).
_cmseventh_build() {
  CMW="$TMP/cm-seventh"
  [ -f "$FROOT/projects/cmseventh/project.json" ] && [ -f "$CMW/.felix" ] && return 0
  _cmstub_build
  mkdir -p "$CMW/src/config"
  ( _fx_cd "$CMW" && git init -q -b main && printf '{"webhooks":[]}\n' > src/config/hooks.json \
    && printf '{ "name": "w", "scripts": { "verify": "echo ok" } }\n' > package.json \
    && git add -A && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
  _cmw="$(cd "$CMW" && PATH="$CMSTUB:$PATH" "$FELIX" new cmseventh 2>&1)"
}

# _hookproj_build: hookproj, the project the session-start hook adopts in 0060, whose
# stack.tsv the adoption gives the grounding header. Sets HOOKREPO (its own checkout),
# and _hook_out1 and _hook_out2, the hook's output in the bare repository and again
# once a requirements.txt names sentry-sdk (set only when this call builds).
_hookproj_build() {
  HOOKREPO="$TMP/hookrepo"
  [ -f "$FROOT/projects/hookproj/stack.tsv" ] && [ -f "$HOOKREPO/requirements.txt" ] && return 0
  mkdir -p "$HOOKREPO"
  ( _fx_cd "$HOOKREPO" && git init -q -b main && git config remote.origin.url https://github.com/example.com/hookproj )  # own checkout, see _anl4_hook
  printf 'hookproj\n' > "$HOOKREPO/.felix"
  mkdir -p "$FROOT/projects/hookproj" "$MEM/hookproj"
  printf '{"name":"hookproj","remote_match":"example.com/hookproj","gate":"true"}\n' > "$FROOT/projects/hookproj/project.json"
  printf '# h\n' > "$FROOT/projects/hookproj/CLAUDE.md"
  _hook_out1="$(cd "$HOOKREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
  printf 'sentry-sdk\n' > "$HOOKREPO/requirements.txt"
  _hook_out2="$(cd "$HOOKREPO" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
}

# _grounded_projects: the projects whose stack.tsv has the grounding column when 0710 starts, one a line: its name,
# a tab, and the function that builds it. 0710 fails when a manifest it finds belongs to none of them, and when one
# of them has no grounded manifest (contract D, R9, R17).
_grounded_projects() {
  printf '%s\t%s\n' cmstranger _commissioning_build cmseventh _cmseventh_build hookproj _hookproj_build \
    setupproj _setupproj_build stranger _stranger_build
}

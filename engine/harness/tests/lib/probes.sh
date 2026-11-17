# tests/lib/probes.sh: probes that ask reality, and the obligations grounded on them.
# Used by 0390 (builds PBP, PBR, PBE and BARE as it goes, and writes PBP's table with
# _pbtable), 0400 (all of those in the state 0390 leaves them, and OBP and OBR with
# _ob, _obrun and _obblk) and 0410 (OBP, OBR and the same three). Moved from
# parts/0390-probes-what-reality-says-and-the-difference.sh: _pbtable from lines
# 25-58, the probe project and its repository from 17-23, the project with no
# probes at all from 484-485, and the bare project from 493-497; and from
# parts/0400-candidates-what-a-model-proposed-and-nothing.sh: _ob, _obrun and
# _obblk from lines 107-114 and the obligation fixture from 103-106. All verbatim,
# the fixtures in the function bodies below.
# Definitions only. Each builder sets its variables first and does nothing more once
# its fixture is there, so in the serial run only 0390's and 0400's first calls build.

# Written by a function rather than patched in place, because the witness has
# to be varied and `sed -i` with a \t is not portable between BSD and GNU sed —
# the substitution silently matches nothing on one of them, which would leave an
# assertion passing for the wrong reason.
_pbtable() {
  { printf '# predicate\tgrounds\twhen\tprobe\twitness\n'
    # found: the probe enumerates, and the members are its own.
    printf 'tracked\t-\t-\tgit ls-files\ttest -e .git\n'
    # empty: nothing came back AND an independent witness agrees there is
    # nothing to come back. The only state here that is a claim about the world.
    printf 'rustcrate\t-\t-\tls -1 Cargo.toml 2>/dev/null\t%s\n' "${1:-test -f Cargo.toml}"
    # blind: the probe saw none of a surface the witness proves is there. The
    # control with teeth — the shape of every failure named in the header.
    printf 'pyfile\t-\t-\tgit ls-files "*.rs"\ttest -d src\n'
    # blind by failure rather than by silence: same verdict, because a probe
    # that could not run against a surface that exists has seen none of it.
    printf 'brokenprobe\t-\t-\tsh -c "exit 3"\ttest -d src\n'
    # unknown: nothing came back and no witness says whether that is true.
    printf 'nowitness\t-\t-\tgit ls-files "*.rs"\t-\n'
    # unknown by absent tooling. 127 is never evidence about the surface.
    printf 'notool\t-\t-\tdefinitely-not-a-real-command-xyz\ttest -d src\n'
    # not-applicable: the row says it does not apply here, so it claims nothing.
    printf 'na\t-\ttest -f Cargo.toml\tls -1 src/*.rs\ttest -d src\n'
    # members AND a failure: partial, so neither found nor nothing-came-back.
    printf 'partial\t-\t-\tls -1 src no-such-path\ttest -d src\n'
    # a probe that reads stdin. With a terminal on stdin this WAITS, and this
    # runs inside a gate — so one row spelt `grep foo` instead of
    # `grep foo file` would hang every gate run on the project forever. The
    # only way this assertion can be reached at all is if stdin is closed.
    printf 'readsstdin\t-\t-\tcat\ttest -d src\n'
    # anything the caller wants appended for one assertion.
    [ -n "${2:-}" ] && printf '%s\n' "$2"
  } > "$PBP/probes.tsv"
}

_ob()    { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"
             . "$FROOT/harness/lib/obligations.sh"; "$@" ) 2>/dev/null; }
_obrun() { _ob felix_obligations_run "$OBP" "$OBR"; }
_obblk() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
             . "$FROOT/harness/lib/verify.sh"; . "$FROOT/harness/lib/evidence.sh"
             . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/probes.sh"
             . "$FROOT/harness/lib/facts.sh"; . "$FROOT/harness/lib/obligations.sh"
             felix_merge_blockers "${1:-$OBP}" "" "$OBR" "$FROOT" ) 2>/dev/null | grep '^obligations'; }

# _probes_build <state>: the fixtures 0390 builds one after another. A state includes
# those before it.
#   base   PBP, the probe project, and PBR, a repository with a source file and a
#          workflow (no probes.tsv yet; _pbtable writes it);
#   empty  PBE, a project that declares no probes;
#   bare   BARE, a repository bound to a project of its own that declares none;
#   end    the state 0390 leaves: PBP holds the table _pbtable writes with no
#          arguments.
_probes_build() {
  local want="${1:-base}"
  PBP="$TMP/probes-proj"; PBR="$TMP/probes-repo"
  if [ ! -d "$PBR/.git" ]; then
    mkdir -p "$PBP" "$MEM/probes-proj"
    mkdir -p "$PBR/src" "$PBR/.github/workflows"
    printf 'x\n' > "$PBR/src/a.py"
    printf 'on: push\n' > "$PBR/.github/workflows/ci.yml"
    ( _fx_cd "$PBR" && git init -q -b main && git add -A \
      && git -c user.name=t -c user.email=t@t commit -qm init ) >/dev/null 2>&1
  fi
  PBR="$(cd "$PBR" && pwd -P)"
  [ "$want" = base ] && return 0
  PBE="$TMP/probes-empty"
  if [ ! -f "$PBE/project.json" ]; then
    mkdir -p "$PBE"
    printf '{\n  "name": "widget",\n  "gate": "true"\n}\n' > "$PBE/project.json"
  fi
  [ "$want" = empty ] && return 0
  BARE="$TMP/bare-repo"
  if [ ! -f "$BARE/.felix" ]; then
    mkdir -p "$FROOT/projects/bare" "$MEM/bare"
    printf '{\n  "name": "bare",\n  "gate": "true"\n}\n' > "$FROOT/projects/bare/project.json"
    mkdir -p "$BARE"
    ( _fx_cd "$BARE" && git init -q -b main && printf 'x\n' > a.txt ) >/dev/null 2>&1
    BARE="$(cd "$BARE" && pwd -P)"; printf 'bare\n' > "$BARE/.felix"
  fi
  BARE="$(cd "$BARE" && pwd -P)"
  [ "$want" = bare ] && return 0
  [ -f "$PBP/probes.tsv" ] || _pbtable
}

# _oblig_build: OBP, a project whose probes.tsv has one row, and OBR, the repository
# that row reads. Its obligations.tsv is written by each case that reads it.
_oblig_build() {
  OBP="$TMP/oblig-proj"; OBR="$TMP/oblig-repo"
  if [ ! -d "$OBR/.git" ]; then
    mkdir -p "$OBP" "$OBR"
    ( _fx_cd "$OBR" && git init -q -b main && printf 'x\n' > x && git add -A && git commit -qm x )
    OBR="$(cd "$OBR" && pwd -P)"
    printf 'thing\t-\t-\tls -1 x\ttest -f x\n' > "$OBP/probes.tsv"
  fi
  OBR="$(cd "$OBR" && pwd -P)"
}

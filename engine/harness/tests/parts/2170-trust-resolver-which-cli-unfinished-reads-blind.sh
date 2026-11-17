# >>> trust-resolver-unfinished-reads
printf '\ntrust plane step 1, the resolver: felix_resolve_project, felix_repo_root, _felix_resolve_remote, _felix_remote_slug, felix_binding_broken and felix_hook_dir say could not tell (spec section 5, properties 1-16, 22, 25-27; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts and examples, before any fix. The expected values are the spec's
# "Must" column and its section 2 contracts; main's code was read for its interfaces only. Each engine function is run
# by the driver of tests/lib/trust-probes.sh (_trp_driver, _trp_drv): a fresh /bin/bash that sources lib/resolve.sh
# alone (own.sh too where a property needs the slug read wrapped), under set -u and -o pipefail, and passes the
# function's stdout and status through.
#
# Faults are bash functions of a command's name (_trp_arm, _trp_go), exported into the driver, acting only when their
# words and the calling functions match; or a wrapper of an engine function (TRP_WRAP) where the property names a whole
# read (the slug, felix_repo_root's outer substitution, a resolve inside the hook directory). Every fault assertion
# carries the probe's TRP_FIRE (or the wrapper's mark), so a probe that never acted fails the assertion instead of
# passing it. Readings where the spec leaves room:
# - "Unknown" for resolve is exit 2 with nothing on stdout (section 5's head); the clean answers are P2's examples.
# - F3 is the fork that fails in the shell that called the command (bash 3.2 ends that subshell with 128); the wrapper's
#   f3z is the substitution around a read that could not fork in the caller's own shell: nothing printed, status 0.
# - P10's "F3 at tr inside it" is the wrapper's f3: the process limit is lowered as felix_remote_github_slug starts in its
#   subshell, so the fork of its own tr pipe fails there, as the spec's R7 describes. Its F1 at tr is not asserted (L2).
# - P14's R2 alone can only fire where the walk finds no .git: it is run from a directory in no repository, whose clean
#   answer is none.
_lf_dir "$TMP/trust-2170"; TRA="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRA/drv"
TRAL='marker remote nest tie badmarker none slug alphabet unread noorigin half'
TRABAD=""
for _tra_l in $TRAL; do _trp_res "$TMP/trust-2170/$_tra_l" "$_tra_l" || TRABAD="$TRABAD $_tra_l"; done
# The other checkout P16 runs from: its origin is the one beta's remote_match names, while the none layout's is not.
_lf_init "$TRA/none/co/other" && printf 'other\n' > "$TRA/none/co/other/README" \
  && _lf_commit "$TRA/none/co/other" 1790000000 $'other\n' "=README" \
  && _lf_origin "$TRA/none/co/other" "https://git.example.org/acme/web.git" || TRABAD="$TRABAD other"
# The second checkout of alpha P25's payload names, bound by its own .felix.
_lf_checkout "$TRA/marker/co/res2" alpha || TRABAD="$TRABAD res2"
_trp_lib "$TRA/noown" own.sh && TRANOOWN="$TRP_LIBC" || TRABAD="$TRABAD noown"
_trp_lib "$TRA/nodetect" detect.sh && TRANODET="$TRP_LIBC" || TRABAD="$TRABAD nodetect"
is "P1 (fixture control): every resolver layout of P2 and this part's own (alphabet, unread, noorigin, half), the second checkouts and the two engine lib copies were built" \
   "${TRABAD:-built}" "built"

# LAYOUT -> the clean answer P2's examples give for resolve from LAYOUT's co/res/sub/dir, as _trp_rcls words it.
_tra_want() {
  case "$1" in
    marker|slug|alphabet) [ "$1" != alphabet ] || { printf 'found:%s' "$TRA/$1/felix-home/projects/alphabet"; return; }
                          printf 'found:%s' "$TRA/$1/felix-home/projects/alpha" ;;
    remote|nest) printf 'found:%s' "$TRA/$1/felix-home/projects/beta" ;;
    *) printf none ;;
  esac
}
# LAYOUT -> LF_RC and TRA/p.out|err: felix_resolve_project from LAYOUT's sub/dir, with whatever probes are armed (none
# when TRP_NAMES is empty). TRAC its class (_trp_rcls), TRAF the probe's mark ("clean" when no probe is armed).
_tra_res() {
  _trp_at "$TRA/$1"
  if [ -n "${TRP_NAMES:-}" ]; then _trp_go _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"; TRAF="$TRP_FIRE"
  else _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"; TRAF=clean; fi
  TRAC="$(_trp_rcls "$TRA/p")"
}
# LABEL LAYOUT ALTS MODE NAME WORDS STACK [NOT] -> one assertion: resolve from LAYOUT under one probe is one of ALTS, and
# the probe acted.
_tra_one() {
  local lab="$1" l="$2" alts="$3"
  shift 3
  _trp_new "$TRA/p.fired"; _trp_arm "$@" || { bad "$lab" "the probe could not be armed: $*"; return; }
  _tra_res "$l"
  is "$lab" "$(_trp_in "$TRAC" "$alts")|$TRAF" "ok|fired"
}
# LABEL LAYOUT ALTS WRAP MODE STACK [ARG1] [FROM] -> one assertion: resolve from LAYOUT (from FROM, LAYOUT's sub/dir by
# default) with the engine function WRAP wrapped (the driver's TRP_WRAP, own.sh sourced) is one of ALTS, and the wrapper
# acted.
_tra_wrap() {
  local lab="$1" l="$2" alts="$3" w="$4" m="$5" k="$6" a="${7-}" from="${8-}" f="$TRA/w.fired"
  rm -f "$f"; _trp_at "$TRA/$l"
  TRP_WRAP="$w" TRP_WMODE="$m" TRP_WSTACK="$k" TRP_WARG1="$a" TRP_WFILE="$f" TRP_OWN=1 \
    _trp_drv "$TRA/p" "${from:-$TRP_S}" resolve "$TRP_S" "$TRP_H"
  TRAC="$(_trp_rcls "$TRA/p")"
  is "$lab" "$(_trp_in "$TRAC" "$alts")|$(LC_ALL=C awk -v w="fired $w" '$0 == w { f = 1 } END { print (f ? "fired" : "not fired") }' "$f" 2>/dev/null)" "ok|fired"
}
TRP_NAMES=""

# --- P1 and P27: every P2 layout, no fault, gives the example; resolve.sh sourced alone loads felix_capture itself.
for _tra_l in marker remote nest tie badmarker none slug; do
  rm -f "$TRA/cap"; _trp_at "$TRA/$_tra_l"
  TRP_CAPF="$TRA/cap" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
  _tra_c="$(_trp_rcls "$TRA/p")"
  is "P1: felix_resolve_project from res layout $_tra_l's co/res/sub/dir, no fault, gives P2's example (found prints the project directory with no LF and exits 0; none prints nothing and exits 1)" \
     "$_tra_c" "$(_tra_want "$_tra_l")"
  is "P27: lib/resolve.sh sourced alone in a fresh /bin/bash, res layout $_tra_l, no fault: the example, and afterwards declare -F felix_capture succeeds (resolve.sh loaded detect.sh itself)" \
     "$_tra_c|$(cat "$TRA/cap" 2>/dev/null)" "$(_tra_want "$_tra_l")|defined"
done
_trp_at "$TRA/slug"
_trp_drv "$TRA/p" "$TRP_S" ghslug 'git@github.com:Acme/Web.git'
is "P1: felix_remote_github_slug on res-slug's origin git@github.com:Acme/Web.git gives P2's example: acme/web and a LF, exit 0" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[acme/web
]"
_trp_drv "$TRA/p" "$TRP_S" ghslug 'https://git.example.org/acme/web.git'
is "P1: felix_remote_github_slug on base's origin https://git.example.org/acme/web.git gives P2's example: nothing, exit 1" \
   "$(_trp_ro "$TRA/p")" "rc=1 out=[]"

# --- P2, P3: a marker read that did not finish.
for _tra_m in f1 f2 f3 f4; do
  _tra_one "P2: base (marker alpha, beta's remote_match also names the origin), $_tra_m at the marker's tr -d [:space:] inside felix_resolve_project: unknown (exit 2, nothing printed), never alpha, a prefix of it, beta or none" \
    marker unknown "$_tra_m" tr "*' -d [:space:] '*" "*' felix_resolve_project '*"
done
_tra_one "P3: the marker names alphabet, projects alpha and alphabet exist, the marker's tr prints its first five bytes (alpha) then exits 1: unknown, never .../projects/alpha" \
  alphabet unknown p5 tr "*' -d [:space:] '*" "*' felix_resolve_project '*"
TRP_NAMES=""; _tra_res alphabet
is "P3 (control): the alphabet layout, no fault: .../projects/alphabet, exit 0" "$TRAC" "$(_tra_want alphabet)"

# --- P4: a marker that cannot be opened names nothing, as main.
if [ "$(id -u)" = 0 ]; then
  skip "P4: base with the marker mode 000: resolve 1" "run as root, so mode 000 does not stop the read"
else
  TRP_NAMES=""; _tra_res unread
  is "P4: base with the marker mode 000 (not root): resolve exits 1 with nothing printed (an unreadable marker names nothing, as main and the lane)" "$TRAC" none
fi

# --- P5, P6: the origin read.
for _tra_m in f1 f127 f2 f3 f5; do
  _tra_one "P5: res-remote, $_tra_m at git remote get-url origin: unknown, never none (that read did not finish)" \
    remote unknown "$_tra_m" git "*' remote get-url origin '*" "*' felix_resolve_project '*"
done
TRP_NAMES=""; _tra_res noorigin
is "P6: res-remote's projects with no origin remote in the checkout, no fault: resolve exits 1, nothing printed (git's no such remote is a finished answer)" "$TRAC" none
_trp_at "$TRA/remote"; _trp_drv "$TRA/p" "$TRP_P" resolve "$TRP_P" "$TRP_H"
is "P6: outside any repository (a plain directory), no fault: resolve exits 1, nothing printed (git's not a repository is a finished answer)" "$(_trp_rcls "$TRA/p")" none

# --- P7, P8, P9: a remote_match unread.
for _tra_m in f1 f2 f3 f4; do
  _tra_one "P7: res-nest, $_tra_m at the sed that reads beta's project.json (the longest match): unknown, never alpha" \
    nest unknown "$_tra_m" sed "*remote_match*'/projects/beta/project.json '*" "*' felix_resolve_project '*"
  _tra_one "P7: res-nest, $_tra_m at the sed that reads alpha's project.json: unknown, never beta (the answer was not read whole)" \
    nest unknown "$_tra_m" sed "*remote_match*'/projects/alpha/project.json '*" "*' felix_resolve_project '*"
done
for _tra_m in f1 f2 f3; do
  for _tra_p in alpha beta; do
    _tra_one "P8: res-tie, $_tra_m at the sed that reads $_tra_p's project.json: unknown, never the other project" \
      tie unknown "$_tra_m" sed "*remote_match*'/projects/$_tra_p/project.json '*" "*' felix_resolve_project '*"
  done
  _tra_one "P9: res-none, $_tra_m at the sed that reads every project.json's remote_match: unknown, never none (an unread remote_match could have named the origin)" \
    none unknown "$_tra_m" sed "*remote_match*'/project.json '*" "*' felix_resolve_project '*"
done

# --- P10, P11: the GitHub slug.
for _tra_m in f2 f3z f5 f3; do
  case "$_tra_m" in
    f3z) _tra_w="F3 at the slug read (its substitution could not fork: nothing, status 0)" ;;
    f3)  _tra_w="F3 at tr inside it (the fork of its own pipe fails in its subshell)" ;;
    f2)  _tra_w="F2 at the slug read (137)" ;;
    *)   _tra_w="F5 at the slug read (exit 0, nothing printed, for a github.com URL)" ;;
  esac
  _tra_wrap "P10: res-slug, $_tra_w, felix_remote_github_slug wrapped as a whole: resolve unknown, never none, never gamma" \
    slug unknown felix_remote_github_slug "$_tra_m" '* _felix_remote_slug *'
done
_trp_at "$TRA/slug"; TRP_LIB="$TRANOOWN" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
is "P11: res-slug with lib/own.sh removed from the engine copy, no fault: resolve exits 1 with nothing printed (main's documented fallback: the owner/repo rule falls to its case-sensitive suffix)" \
   "$(_trp_rcls "$TRA/p")" none

# --- P12: _felix_remote_slug direct.
_trp_drv "$TRA/p" "$TRP_S" slug 'git@github.com:Acme/Web.git'
is "P12: _felix_remote_slug git@github.com:Acme/Web.git: status 0 and _FELIX_RS acme/web" "$(cat "$TRA/p.out")" "rc=0 rs=[acme/web]"
_trp_drv "$TRA/p" "$TRP_S" slug 'https://example.org/a/b'
is "P12: _felix_remote_slug https://example.org/a/b: status 0 and _FELIX_RS empty (not GitHub)" "$(cat "$TRA/p.out")" "rc=0 rs=[]"
for _tra_m in f2 f3z f3 f5; do
  rm -f "$TRA/w.fired"
  TRP_WRAP=felix_remote_github_slug TRP_WMODE="$_tra_m" TRP_WSTACK='* _felix_remote_slug *' TRP_WFILE="$TRA/w.fired" \
    _trp_drv "$TRA/p" "$TRP_S" slug 'git@github.com:Acme/Web.git'
  is "P12: _felix_remote_slug git@github.com:Acme/Web.git with $_tra_m at its read of felix_remote_github_slug: status 2 and _FELIX_RS empty (did not finish)" \
     "$(cat "$TRA/p.out")|$(cat "$TRA/w.fired" 2>/dev/null)" "rc=2 rs=[]|fired felix_remote_github_slug"
done

# --- P13: _felix_resolve_remote direct, from each layout's checkout root.
_tra_rr() { _trp_at "$TRA/$1"; if [ -n "${TRP_NAMES:-}" ]; then _trp_go _trp_drv "$TRA/p" "$TRP_CO" rr "$TRP_CO" "$TRP_H"; TRAF="$TRP_FIRE"
            else _trp_drv "$TRA/p" "$TRP_CO" rr "$TRP_CO" "$TRP_H"; TRAF=clean; fi; TRAC="$(cat "$TRA/p.out" 2>/dev/null)"; }
TRP_NAMES=""; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root: status 0 and _FELIX_RB_P beta, _FELIX_RB_TIE empty" "$TRAC" "rc=0 p=[beta] tie=[]"
TRP_NAMES=""; _tra_rr tie
is "P13: _felix_resolve_remote on res-tie's root: status 2 (a tie)" "${TRAC%% *}" "rc=2"
TRP_NAMES=""; _tra_rr none
is "P13: _felix_resolve_remote on res-none's root: status 1 (none)" "${TRAC%% *}" "rc=1"
_trp_new "$TRA/p.fired"; _trp_arm f2 git "*' remote get-url origin '*" "*' _felix_resolve_remote '*"; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root, F2 at its origin read (R5): status 3, _FELIX_RB_P and _FELIX_RB_TIE empty" "$TRAC|$TRAF" "rc=3 p=[] tie=[]|fired"
_trp_new "$TRA/p.fired"; _trp_arm f2 sed "*remote_match*'/project.json '*" "*' _felix_resolve_remote '*"; _tra_rr remote
is "P13: _felix_resolve_remote on res-remote's root, F2 at every remote_match read (R6): status 3, _FELIX_RB_P and _FELIX_RB_TIE empty" "$TRAC|$TRAF" "rc=3 p=[] tie=[]|fired"

# --- P14, P15: felix_repo_root's two reads.
for _tra_l in marker remote; do
  for _tra_m in f2 f3; do
    _trp_new "$TRA/p.fired"
    _trp_arm "$_tra_m" pwd "*' -P '*" "*' felix_repo_root '*"; _trp_arm "$_tra_m" git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
    _tra_res "$_tra_l"
    is "P14: $_tra_l, $_tra_m at the walk's pwd -P (R1) and at git rev-parse --show-toplevel (R2) together: resolve unknown, never another project, never none" \
       "$TRAC|$TRAF" "unknown|fired"
    _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" pwd "*' -P '*" "*' felix_repo_root '*"
    _tra_res "$_tra_l"
    is "P14: $_tra_l, $_tra_m at the walk's pwd -P (R1) alone, git left to find the root: resolve unknown or the clean answer, never another project, never none" \
       "$(_trp_in "$TRAC" "unknown|$(_tra_want "$_tra_l")")|$TRAF" "ok|fired"
  done
done
for _tra_m in f2 f3; do
  _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
  _trp_at "$TRA/remote"; _trp_go _trp_drv "$TRA/p" "$TRP_P" resolve "$TRP_P" "$TRP_H"
  is "P14: a directory in no repository, $_tra_m at git rev-parse --show-toplevel (R2) alone, the walk having found no .git: resolve unknown or the clean answer (none), never a project" \
     "$(_trp_in "$(_trp_rcls "$TRA/p")" "unknown|none")|$TRP_FIRE" "ok|fired"
done
_trp_at "$TRA/marker"
_trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P15: felix_repo_root from co/res/sub/dir, no fault: prints the checkout root, status 0" "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_CO]"
_trp_new "$TRA/p.fired"; _trp_arm f3 pwd "*' -P '*" "*' felix_repo_root '*"; _trp_arm f3 git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*"
_trp_go _trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P15: felix_repo_root from co/res/sub/dir, F3 at R1 and R2: prints exactly START (main's bytes) and returns 2" "$(_trp_ro "$TRA/p")|$TRP_FIRE" "rc=2 out=[$TRP_S]|fired"
_trp_drv "$TRA/p" "$TRP_P" root "$TRP_P"
is "P15: felix_repo_root from a directory in no repository, no fault: prints START, status 0" "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_P]"

# --- P16: the outer substitution of felix_repo_root inside felix_resolve_project.
TRP_NAMES=""; _trp_at "$TRA/none"; _trp_drv "$TRA/p" "$TRA/none/co/other" resolve "$TRP_S" "$TRP_H"
is "P16 (control): START res-none's sub/dir, run from a checkout whose origin beta's remote_match names, no fault: none (START's origin decides, not the cwd's)" \
   "$(_trp_rcls "$TRA/p")" none
for _tra_m in f2 f3z; do
  _tra_wrap "P16: START res-none's sub/dir, run from a checkout whose origin beta names, $_tra_m at the outer substitution of felix_repo_root inside felix_resolve_project: unknown, never the cwd's project (beta)" \
    none unknown felix_repo_root "$_tra_m" '* felix_resolve_project *' "" "$TRA/none/co/other"
done

# --- P22: the home pointer read.
_trp_at "$TRA/marker"; printf '%s\n' "$TRP_H" > "$TRP_U/.felix-home"
TRP_NOHOME=1 _trp_drv "$TRA/p" "$TRP_S" broken "$TRP_S" "$TRP_H"
is "P22 (control): FELIX_HOME unset, ~/.felix-home naming the real home, base, no fault: felix_binding_broken prints nothing and returns 0 (not broken)" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[]"
for _tra_m in f2 f3; do
  _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" cat "*'/.felix-home '*" "*' _felix_home_pointer '*"
  TRP_NOHOME=1 _trp_go _trp_drv "$TRA/p" "$TRP_S" broken "$TRP_S" "$TRP_H"
  is "P22: FELIX_HOME unset, ~/.felix-home naming the real home, $_tra_m at the cat of it: felix_binding_broken prints nothing and returns 2, never \"is empty, so it names no home\"" \
     "$(_trp_ro "$TRA/p")|$TRP_FIRE" "rc=2 out=[]|fired"
done
rm -f "$TRP_U/.felix-home"

# --- P25: the hook directory.
_trp_at "$TRA/marker"
TRAPL="{\"session_id\":\"t\",\"cwd\":\"$TRP_FX/co/res2\"}"
_trp_drv "$TRA/p" "$TRP_CO" hookdir "$TRAPL" "$TRP_H"
is "P25 (control): felix_hook_dir run from base's checkout, the payload's cwd another checkout of alpha, no fault: prints the payload's cwd, status 0 (the hook moves there)" \
   "$(_trp_ro "$TRA/p")" "rc=0 out=[$TRP_FX/co/res2]"
for _tra_m in f3 f3z; do
  for _tra_a in "$TRP_FX/co/res2" "$TRP_CO"; do
    case "$_tra_a" in "$TRP_CO") _tra_w="the launch directory's resolve" ;; *) _tra_w="the payload cwd's resolve" ;; esac
    rm -f "$TRA/w.fired"
    TRP_WRAP=felix_resolve_project TRP_WMODE="$_tra_m" TRP_WSTACK='* _felix_hook_dir_set *' TRP_WARG1="$_tra_a" TRP_WFILE="$TRA/w.fired" \
      _trp_drv "$TRA/p" "$TRP_CO" hookdir "$TRAPL" "$TRP_H"
    is "P25: felix_hook_dir, the payload's cwd another checkout of the same project, $_tra_m at $_tra_w: prints \$PWD (stays where the platform started the hook), status 0" \
       "$(_trp_ro "$TRA/p")|$(cat "$TRA/w.fired" 2>/dev/null)" "rc=0 out=[$TRP_CO]|fired felix_resolve_project"
  done
done

# --- P26: felix_capture cannot be loaded.
for _tra_l in marker remote nest tie badmarker none slug; do
  _trp_at "$TRA/$_tra_l"; TRP_LIB="$TRANODET" _trp_drv "$TRA/p" "$TRP_S" resolve "$TRP_S" "$TRP_H"
  is "P26: resolve.sh sourced in a fresh shell from a directory holding no detect.sh (felix_capture unloadable), res layout $_tra_l, no fault: unknown, never found, never 1" \
     "$(_trp_rcls "$TRA/p")" unknown
done
_trp_at "$TRA/marker"; TRP_LIB="$TRANODET" _trp_drv "$TRA/p" "$TRP_S" root "$TRP_S"
is "P26: felix_repo_root with felix_capture unloadable, from co/res/sub/dir: still prints main's bytes (the checkout root) and returns 2" \
   "$(_trp_ro "$TRA/p")" "rc=2 out=[$TRP_CO]"

# --- P47 (review round 1): a URL is read only from a git that exited 0. res-half: alpha's remote_match is the origin's
# first 28 bytes, beta's its whole path; the probe prints the first half of git's real answer (https://git.example.org/acme)
# and exits with one of git's finished statuses, 128 (fatal) or 2 (no such remote). Main's answer there is none.
TRP_NAMES=""; _tra_res half
is "P47 (control): res-half (alpha's remote_match git.example.org/acme, beta's the origin's whole path), no fault: .../projects/beta, exit 0" \
   "$TRAC" "found:$TRA/half/felix-home/projects/beta"
for _tra_m in h128 h2; do
  _tra_one "P47: res-half, git remote get-url origin prints the first half of the URL (https://git.example.org/acme) then exits ${_tra_m#h}: resolve none (main's) or unknown, never 0 with a project (never alpha)" \
    half "none|unknown" "$_tra_m" git "*' remote get-url origin '*" "*' felix_resolve_project '*"
  _trp_new "$TRA/p.fired"; _trp_arm "$_tra_m" git "*' remote get-url origin '*" "*' _felix_resolve_remote '*"; _tra_rr half
  is "P47: _felix_resolve_remote on res-half's root, the origin read prints half the URL then exits ${_tra_m#h}: status 1 (no origin, as main) or 3, _FELIX_RB_P and _FELIX_RB_TIE empty" \
     "$(_trp_in "$TRAC" "rc=1 p=[] tie=[]|rc=3 p=[] tie=[]")|$TRAF" "ok|fired"
done

# --- P48 (review round 1): the Stop hook when felix_capture cannot be loaded. Part 1750's b07 fixture rebuilt here: a
# home whose harness is the engine under test, project p (gate true), a checkout bound to p by its committed marker,
# made dirty and never verified. The hook is run once with the whole engine (control), and once with lib/detect.sh moved
# out of the engine's lib/. Held means its stdout carries "decision": "block" (main's hold, or a hold saying the binding
# could not be resolved).
TRAST="$TRA/stop"; TRABAD=""
mkdir -p "$TRAST/home/projects/p" "$TRAST/mem" "$TRAST/user" "$TRAST/aside" "$TRAST/repo" || TRABAD=dirs
_copy_content "$REAL_HARNESS" "$TRAST/home/harness" || TRABAD="$TRABAD harness"
printf '{"name": "p", "gate": "true"}\n' > "$TRAST/home/projects/p/project.json"
printf '# p\n' > "$TRAST/home/projects/p/CLAUDE.md"
( _fx_cd "$TRAST/repo" && git init -q -b main && printf 'base\n' > WORK.txt && printf 'p\n' > .felix && git add -A \
  && git -c user.name=t -c user.email=t@t -c commit.gpgsign=false commit -qm init ) >/dev/null 2>&1 || TRABAD="$TRABAD repo"
printf 'one more line\n' >> "$TRAST/repo/WORK.txt"
# SID [ACTIVE] -> the Stop hook of TRAST's home run from its checkout with a Stop payload for session SID, whose
# stop_hook_active is ACTIVE (default false); TRAST/o.out, o.err, LF_RC; TRAH yes when it held, else no.
_tra_stop() {
  ( _fx_cd "$TRAST/repo" || exit 125
    printf '{"hook_event_name":"Stop","stop_hook_active":%s,"session_id":"%s"}' "${2:-false}" "$1" \
      | env -u FELIX_ALLOW_RED -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR FELIX_HOME="$TRAST/home" \
          FELIX_MEMORY="$TRAST/mem" HOME="$TRAST/user" LANGUAGE=en TZ=UTC GIT_CONFIG_NOSYSTEM=1 "$TRAST/home/harness/hooks/stop" ) \
    > "$TRAST/o.out" 2> "$TRAST/o.err"
  LF_RC=$?
  case "$(cat "$TRAST/o.out" 2>/dev/null)" in (*'"decision"'*'"block"'*) TRAH=yes ;; (*) TRAH=no ;; esac
}
_tra_stop trust-p48-whole
is "P48 (control): the Stop hook with the whole engine, a dirty checkout bound by its marker and never verified: it holds" \
   "${TRABAD:-built}|$TRAH" "built|yes"
mv "$TRAST/home/harness/lib/detect.sh" "$TRAST/aside/detect.sh" 2>/dev/null
_tra_stop trust-p48-nodetect
mv "$TRAST/aside/detect.sh" "$TRAST/home/harness/lib/detect.sh" 2>/dev/null
TRALAB="P48: the same Stop with lib/detect.sh removed from the engine (felix_capture unloadable, resolve says 2): it still holds, as main, never exit 0 with nothing said"
if [ "$TRAH" = yes ]; then ok "$TRALAB"
else bad "$TRALAB" "expected [held] got [exit $LF_RC, stdout [$(head -c 300 "$TRAST/o.out" 2>/dev/null)], stderr [$(head -c 200 "$TRAST/o.err" 2>/dev/null)]]"; fi

# --- P49 (review round 2): the flagged Stop (stop_hook_active true) when felix_capture cannot be loaded, on P48's
# fixture, each run under a session id of its own. A chain another hook started (no hold of Felix's on record) and a
# session's own night (a night state file for the session, started, deadline, turns left, quiet runs, session, note)
# must still hold; a chain Felix started (an unflagged hold, then the flagged stop of the same session) still ends.
# Every nodetect run is armed only when lib/detect.sh was moved out (TRAARM); the night's control also shows the night
# was charged (a refused row in the project's overnight log).
TRANI="$TRAST/mem/p/overnight"
_tra_night() { mkdir -p "$TRANI/nights" && printf '%s\t%s\t20\t0\t%s\tnight\n' "$(date +%s)" "$(( $(date +%s) + 36000 ))" "$1" > "$TRANI/nights/$1"; }
_tra_rows() { grep -c 'refused' "$TRANI/log.tsv" 2>/dev/null || true; }
# LABEL SID MODE: SID's flagged Stop with lib/detect.sh moved out (MODE nodetect) or the whole engine (whole).
_tra_flag() {
  TRAARM=yes
  [ "$3" = whole ] || { mv "$TRAST/home/harness/lib/detect.sh" "$TRAST/aside/detect.sh" 2>/dev/null && [ ! -e "$TRAST/home/harness/lib/detect.sh" ] || TRAARM=no; }
  _tra_stop "$2" true
  [ "$3" = whole ] || mv "$TRAST/aside/detect.sh" "$TRAST/home/harness/lib/detect.sh" 2>/dev/null
  if [ "$TRAARM|$TRAH" = "yes|yes" ]; then ok "$1"
  else bad "$1" "expected [armed, held] got [armed $TRAARM, exit $LF_RC, stdout [$(head -c 300 "$TRAST/o.out" 2>/dev/null)], stderr [$(head -c 200 "$TRAST/o.err" 2>/dev/null)]]"; fi
}
_tra_flag "P49 (control): a flagged Stop with no hold of Felix's on record (another hook's chain), the whole engine: it holds" \
  trust-p49-chain-whole whole
_tra_flag "P49: the same flagged Stop (another hook's chain, no hold on record) with lib/detect.sh removed from the engine: it still holds, as main, never exit 0 with nothing said" \
  trust-p49-chain-nodetect nodetect
_tra_night trust-p49-night-whole; TRAR0="$(_tra_rows)"
_tra_stop trust-p49-night-whole true; TRAR1="$(_tra_rows)"
is "P49 (control): a flagged Stop of a session that holds a night of its own, the whole engine: it holds and charges the night (a refused row in its log)" \
   "$TRAH|$([ "${TRAR1:-0}" -gt "${TRAR0:-0}" ] && echo charged || echo uncharged)" "yes|charged"
_tra_night trust-p49-night-nodetect
_tra_flag "P49: the flagged Stop of a session that holds a night of its own, with lib/detect.sh removed from the engine: it still holds, as main, never exit 0 with nothing said" \
  trust-p49-night-nodetect nodetect
# The guard: Felix's own chain. The unflagged Stop holds (P48), the flagged Stop of the same session that follows ends.
mv "$TRAST/home/harness/lib/detect.sh" "$TRAST/aside/detect.sh" 2>/dev/null && [ ! -e "$TRAST/home/harness/lib/detect.sh" ] && TRAARM=yes || TRAARM=no
_tra_stop trust-p49-own false; TRAH1="$TRAH"
_tra_stop trust-p49-own true
mv "$TRAST/aside/detect.sh" "$TRAST/home/harness/lib/detect.sh" 2>/dev/null
is "P49 (guard): with lib/detect.sh removed, an unflagged Stop that holds, then the flagged Stop of the same session (Felix's own chain, no night): the first holds, the second is not held again" \
   "$TRAARM|$TRAH1|$TRAH" "yes|yes|no"

# --- P50 (the session's review of rounds 1-2): the PreToolUse hook when felix_capture cannot be loaded, on P48's
# fixture with a deny row for p. pre-tool does not load lib/detect.sh itself, and a library that did not load is
# allowed and recorded there (_felix_pt_stop, a pre-tool row in the memory's hook-faults.log). With lib/detect.sh moved
# out of the engine, npm publish from the checkout p binds is refused as on main, or allowed with a row naming
# lib/detect.sh; never allowed with nothing recorded, which would turn the deny rows off in silence.
printf 'Bash\t(^|[;&| ])npm publish\tp refuses a publish\n' > "$TRAST/home/projects/p/deny.tsv" || TRABAD="$TRABAD deny"
# MODE (whole or nodetect) -> TRAPT refused, recorded or what was seen instead; TRAARM as in _tra_flag.
_tra_pt() {
  local n0 n1
  TRAARM=yes; n0="$(grep -c 'pre-tool' "$TRAST/mem/hook-faults.log" 2>/dev/null || true)"
  [ "$1" = whole ] || { mv "$TRAST/home/harness/lib/detect.sh" "$TRAST/aside/detect.sh" 2>/dev/null && [ ! -e "$TRAST/home/harness/lib/detect.sh" ] || TRAARM=no; }
  ( _fx_cd "$TRAST/repo" || exit 125
    printf '{"hook_event_name":"PreToolUse","session_id":"trust-p50-%s","tool_name":"Bash","tool_input":{"command":"npm publish"},"tool_use_id":"toolu_p50"}' "$1" \
      | env -u CLAUDE_CODE_REMOTE -u CLAUDE_CODE_SESSION_ID -u FELIX_HOME_DIR FELIX_HOME="$TRAST/home" FELIX_MEMORY="$TRAST/mem" \
          HOME="$TRAST/user" LANGUAGE=en TZ=UTC GIT_CONFIG_NOSYSTEM=1 "$TRAST/home/harness/hooks/pre-tool" ) \
    > "$TRAST/o.out" 2> "$TRAST/o.err"
  LF_RC=$?
  [ "$1" = whole ] || mv "$TRAST/aside/detect.sh" "$TRAST/home/harness/lib/detect.sh" 2>/dev/null
  n1="$(grep -c 'pre-tool' "$TRAST/mem/hook-faults.log" 2>/dev/null || true)"
  if [ "$LF_RC" -eq 2 ] && grep -q 'Felix refused this command' "$TRAST/o.err" 2>/dev/null; then TRAPT=refused
  elif [ "$LF_RC" -eq 0 ] && [ "${n1:-0}" -gt "${n0:-0}" ] && grep -q 'lib/detect.sh' "$TRAST/mem/hook-faults.log" 2>/dev/null; then TRAPT=recorded
  else TRAPT="exit $LF_RC, rows $n0 to $n1, stderr [$(head -c 200 "$TRAST/o.err" 2>/dev/null)]"; fi
}
_tra_pt whole
is "P50 (control): PreToolUse with the whole engine, npm publish from the checkout p binds, a deny row for it: refused" \
   "${TRABAD:-built}|$TRAARM|$TRAPT" "built|yes|refused"
_tra_pt nodetect
is "P50: the same PreToolUse with lib/detect.sh removed from the engine: refused as main, or recorded as not judged (a hook-faults.log row naming lib/detect.sh), never allowed with nothing recorded" \
   "$TRAARM|$(case "$TRAPT" in (refused|recorded) echo judged-or-said ;; (*) echo "$TRAPT" ;; esac)" "yes|judged-or-said"
TRP_NAMES=""
# <<< trust-resolver-unfinished-reads
# >>> trust-which-unfinished-reads
printf '\ntrust plane step 1, felix which: a resolution that did not finish is said as one, and felix which agrees with felix lane and the resolver (spec section 5, properties 1-9 and 38; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts and examples, before any fix. Felix is run as a black box
# ("$FELIX" which and "$FELIX" lane --tsv, from the checkout's co/res/sub/dir, through _lf_run in the environment
# _lf_use names), and the resolver through the driver of tests/lib/trust-probes.sh.
#
# Each fault is armed once and the three runs are made under it: felix which (asserted, with the probe's TRP_FIRE),
# felix lane --tsv and felix_resolve_project (recorded for P38). The faults match their command's words in any calling
# function, as the spec names them by the read alone ("at the marker's tr"): felix_binding_broken's and the lane's reads
# of the same file are faulted with the resolver's. Readings where the spec leaves room:
# - "Unknown" for which is exit 2, empty stdout, and a line of stderr exactly "felix: the project that governs <dir>
#   could not be resolved: a read it stands on did not finish." (the CLI's sentence, section 0); bash's own note of a
#   fork it could not make may stand on another line, since it is the probe's doing.
# - Broken and none are P2's outcomes.tsv classes (its stderr EREs); found is five lines with the project line.
# - P38's "every fault in 2-21" is read over res layouts only (P2's res-* and base, here and in part 2172), since 20 and 21
#   are a layout no res layout is; felix lane's "could not be resolved" is its C5 line on stderr with exit 2.
_lf_dir "$TMP/trust-2171"; TRB="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRB/drv"
TRBBAD=""
for _trb_l in marker remote nest tie badmarker none slug alphabet unread noorigin half; do
  _trp_res "$TMP/trust-2171/$_trb_l" "$_trb_l" || TRBBAD="$TRBBAD $_trb_l"
done
is "P1 (fixture control): every resolver layout of P2 and this part's own (alphabet, unread, noorigin, half) was built" "${TRBBAD:-built}" built
TRBDIS=""; TRBN=0

# LAYOUT -> TRBWANT the which class the clean run gives (P2's examples): found:P, broken or none.
_trb_want() {
  case "$1" in
    marker|slug) TRBWANT=found:alpha ;; alphabet) TRBWANT=found:alphabet ;; remote|nest) TRBWANT=found:beta ;;
    tie|badmarker|unread) TRBWANT=broken ;; *) TRBWANT=none ;;
  esac
}
# OUT DIR -> unresolved when felix lane (OUT.out, OUT.err, LF_RC) exited 2 with nothing on stdout and a line of stderr
# exactly C5's "could not be resolved" line; else its status and the first line of stderr.
_trb_lane() {
  if [ "$LF_RC" = 2 ] && [ ! -s "$1.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $2 could not be resolved: a read it stands on did not finish." "$1.err" 2>/dev/null; then
    printf unresolved
  else
    printf 'status %s [%s]' "$LF_RC" "$(LC_ALL=C awk 'NR == 1' "$1.err" 2>/dev/null)"
  fi
}
# LAYOUT [FROM] -> with the probes armed now (none when TRP_NAMES is empty), felix which, felix lane --tsv and
# felix_resolve_project, each from FROM (LAYOUT's co/res/sub/dir). TRBW which's class (_trp_wcls), TRBF its probe mark
# (clean when none is armed), TRBL the lane's (_trb_lane), TRBR the resolver's (_trp_rcls). A disagreement P38 forbids
# is added to TRBDIS.
_trb_three() {
  local d r
  _trp_at "$TRB/$1"; d="${2:-$TRP_S}"
  if [ -n "${TRP_NAMES:-}" ]; then
    _trp_go _lf_run "$TRB/w" "$d" - "$FELIX" which; TRBF="$TRP_FIRE"; TRBW="$(_trp_wcls "$TRB/w" "$d")"
    _trp_go _lf_run "$TRB/l" "$d" - "$FELIX" lane --tsv; TRBL="$(_trb_lane "$TRB/l" "$d")"
    _trp_go _trp_drv "$TRB/r" "$d" resolve "$d" "$TRP_H"; TRBR="$(_trp_rcls "$TRB/r")"
  else
    _lf_run "$TRB/w" "$d" - "$FELIX" which; TRBF=clean; TRBW="$(_trp_wcls "$TRB/w" "$d")"
    _lf_run "$TRB/l" "$d" - "$FELIX" lane --tsv; TRBL="$(_trb_lane "$TRB/l" "$d")"
    _trp_drv "$TRB/r" "$d" resolve "$d" "$TRP_H"; TRBR="$(_trp_rcls "$TRB/r")"
  fi
  TRBN=$((TRBN + 1)); r=""
  case "$TRBW:$TRBL" in (unknown:unresolved) ;; (unknown:*) r="which unknown, lane not" ;; (*:unresolved) r="lane unresolved, which $TRBW" ;; esac
  case "$TRBW" in
    found:*) [ "$TRBR" = "found:$TRP_H/projects/${TRBW#found:}" ] || r="${r:+$r; }which $TRBW, resolve $TRBR" ;;
    *) case "$TRBR" in found:*) r="${r:+$r; }resolve $TRBR, which $TRBW" ;; esac ;;
  esac
  [ -z "$r" ] || TRBDIS="$TRBDIS[$1 ${TRBCASE:-clean}: $r] "
}
# LABEL LAYOUT ALTS MODE NAME WORDS -> one assertion: under one probe acting at NAME with WORDS in any calling function,
# felix which from LAYOUT is one of ALTS, and the probe acted.
_trb_one() {
  local lab="$1" l="$2" alts="$3"
  _trp_new "$TRB/p.fired"; _trp_arm "$4" "$5" "$6" '*' || { bad "$lab" "the probe could not be armed: $4 $5 $6"; return; }
  TRBCASE="$4 $5 $6"; _trb_three "$l"; TRBCASE=""
  is "$lab" "$(_trp_in "$TRBW" "$alts")|$TRBF" "ok|fired"
}
TRP_NAMES=""

# --- P1: every P2 layout, no fault.
for _trb_l in marker remote nest tie badmarker none slug; do
  _trb_want "$_trb_l"; _trb_three "$_trb_l"
  case "$TRBWANT" in
    found:*) _trb_p="${TRBWANT#found:}"
      is "P1: felix which from res layout $_trb_l's co/res/sub/dir, no fault, gives P2's example: the five lines for $_trb_p, exit 0" \
         "$(_trp_ro "$TRB/w")" "rc=0 out=[project:      $_trb_p
doctrine:     $TRP_H/projects/$_trb_p/CLAUDE.md
memory:       $TRP_M/$_trb_p/
gate:         gate-$_trb_p
governs:      $TRP_CO
]" ;;
    *) is "P1: felix which from res layout $_trb_l's co/res/sub/dir, no fault, gives P2's example: exit 2, nothing on stdout, stderr of P2's $TRBWANT class" \
         "$TRBW" "$TRBWANT" ;;
  esac
done

# --- P2, P3: the marker read.
for _trb_m in f1 f2 f3 f4; do
  _trb_one "P2: felix which on base, $_trb_m at the marker's tr -d [:space:]: unknown (exit 2, nothing on stdout, the could-not-be-resolved sentence), never alpha's prefix, beta, no project governs or a broken sentence" \
    marker unknown "$_trb_m" tr "*' -d [:space:] '*"
done
_trb_one "P3: felix which, the marker names alphabet beside alpha, the marker's tr prints alpha (its first five bytes) then exits 1: unknown, never alpha" \
  alphabet unknown p5 tr "*' -d [:space:] '*"
TRP_NAMES=""; _trb_three alphabet
is "P3 (control): felix which, the marker names alphabet, no fault: found alphabet" "$TRBW" found:alphabet

# --- P4: an unreadable marker.
if [ "$(id -u)" = 0 ]; then
  skip "P4: felix which on base with the marker mode 000: the broken sentence" "run as root, so mode 000 does not stop the read"
else
  TRP_NAMES=""; _trb_three unread
  is "P4: felix which on base with the marker mode 000 (not root), no fault: exit 2, nothing on stdout, a broken-binding sentence for the marker (main's), never no project governs and never unknown" \
     "$TRBW" broken
fi

# --- P5, P6: the origin read.
for _trb_m in f1 f127 f2 f3 f5; do
  _trb_one "P5: felix which on res-remote, $_trb_m at git remote get-url origin: unknown, never no project governs" \
    remote unknown "$_trb_m" git "*' remote get-url origin '*"
done
TRP_NAMES=""; _trb_three noorigin
is "P6: felix which in a checkout with no origin remote (res-remote's projects), no fault: no project governs (main's sentence class), exit 2" "$TRBW" none
_trp_at "$TRB/remote"; _lf_run "$TRB/w" "$TRP_P" - "$FELIX" which
is "P6: felix which outside any repository, no fault: no project governs (main's sentence class), exit 2" "$(_trp_wcls "$TRB/w" "$TRP_P")" none

# --- P7, P8, P9: a remote_match unread.
for _trb_m in f1 f2 f3 f4; do
  _trb_one "P7: felix which on res-nest, $_trb_m at the sed that reads beta's project.json: unknown, never alpha" \
    nest unknown "$_trb_m" sed "*remote_match*'/projects/beta/project.json '*"
  _trb_one "P7: felix which on res-nest, $_trb_m at the sed that reads alpha's project.json: unknown, never beta" \
    nest unknown "$_trb_m" sed "*remote_match*'/projects/alpha/project.json '*"
done
for _trb_m in f1 f2 f3; do
  for _trb_p in alpha beta; do
    _trb_one "P8: felix which on res-tie, $_trb_m at the sed that reads $_trb_p's project.json: unknown, never the other project, never the tie sentence" \
      tie unknown "$_trb_m" sed "*remote_match*'/projects/$_trb_p/project.json '*"
  done
  _trb_one "P9: felix which on res-none, $_trb_m at the sed that reads every project.json's remote_match: unknown, never no project governs" \
    none unknown "$_trb_m" sed "*remote_match*'/project.json '*"
done

# --- P38, over the res layouts and faults of this part (the badmarker, none and tie faults of 17-19 are part 2172's).
is "P38: over the $TRBN runs of this part (seven res layouts clean, and the faults of P2-P9 on base, res-remote, res-nest, res-tie and res-none, with alphabet, the unreadable marker and no origin), felix which is unknown exactly where felix lane says could not be resolved, and found with P only where felix_resolve_project prints .../projects/P with 0" \
   "${TRBDIS:-agreed}" agreed

# --- P47 (review round 1), after P38's count: the origin read prints half the URL, then exits with a finished status.
TRP_NAMES=""; _trb_three half
is "P47 (control): felix which on res-half, no fault: found beta (the origin's whole path)" "$TRBW" found:beta
for _trb_m in h128 h2; do
  _trb_one "P47: felix which on res-half, git remote get-url origin prints the first half of the URL (https://git.example.org/acme) then exits ${_trb_m#h}: no project governs (main's) or unknown, exit 2, never the five lines (never alpha)" \
    half "none|unknown" "$_trb_m" git "*' remote get-url origin '*"
done
TRP_NAMES=""
# <<< trust-which-unfinished-reads
# >>> trust-cli-refusals-unfinished-reads
printf '\ntrust plane step 1, the CLI refusals: the broken and no-project sentences, every resolve_or_die command, felix which'"'"'s own reads and the merge judge'"'"'s resolve.sh (spec section 5, properties 17-21, 23, 24, 38 and 45; blind)\n'
# Blind, written on 2026-11-05 from .felix/memory/felix/audits/2026-10-31-trust-plane-replay/step1/spec.md (sections 0-8
# and the merge-judge item) and the P2 case's layouts, before any fix. Felix is run as a black box through _lf_run, in
# the environment _lf_use names; the probes are tests/lib/trust-probes.sh's. Readings where the spec leaves room:
# - "Byte for byte" (P17-P21) compares exit, stdout and stderr with the clean run's, leaving out bash's own note of a
#   fork it could not make (_trp_said), which is the probe's doing and no sentence of the engine's.
# - P21's memory-root read may be made fork-free by the fix (R14). Where the probe does not act, the run must equal the
#   clean run, as section 5's head says; where it acts, unknown or the clean sentence. On main it acts.
# - P23's "unknown sentence" is a line of stderr exactly the CLI's; felix land --tick is run with FELIX_LAND_LEDGER, so
#   the unresolved row it writes is read in that file.
# - P24's F3 at felix_repo_root for the governs line is the fork failing at both its reads (the walk's pwd -P, then git),
#   called by cmd_which and not by the resolution; the gate's sed is the read of the gate key called by cmd_which.
# - P45's "suite's judge fixtures" are built here as part 1401 builds them: a home whose main ships engine/ at 4.0.0
#   and a cache entry cut from it, plus that entry with a file more and a cache with no entry. Main's answer is the
#   function's contract there (0 and the entry, 1 naming the path, 2), and the copy holding only resolve.sh must give it.
_lf_dir "$TMP/trust-2172"; TRC="$LF_DIR"
TRP_E="$FROOT/harness"
_trp_driver "$TRC/drv"
TRCBAD=""
for _trc_l in badmarker none tie marker bound boundhome; do
  case "$_trc_l" in bound|boundhome) _trc_k=remote ;; *) _trc_k="$_trc_l" ;; esac
  _trp_res "$TMP/trust-2172/$_trc_l" "$_trc_k" || TRCBAD="$TRCBAD $_trc_l"
done
is "P17 (fixture control): the layouts of this part were built (res-badmarker, res-none, res-tie, base, and two res-remote copies for the bindings record)" \
   "${TRCBAD:-built}" built
TRCDIS=""; TRCN=0

# OUT DIR RC -> unknown when the run exited RC with nothing on stdout and a line of stderr exactly the CLI's
# could-not-be-resolved sentence for DIR; else what it said (_trp_said).
_trc_unk() {
  if [ "$LF_RC" = "$3" ] && [ ! -s "$1.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $2 could not be resolved: a read it stands on did not finish." "$1.err" 2>/dev/null; then
    printf unknown
  else _trp_said "$1"; fi
}
# LAYOUT -> felix which, felix lane --tsv and felix_resolve_project from LAYOUT's sub/dir under the probes armed now,
# as part 2171's _trb_three runs them: TRCW which's class, TRCS what it said (_trp_said), TRCF its probe mark; a
# disagreement P38 forbids is added to TRCDIS.
_trc_three() {
  local d r
  _trp_at "$TRC/$1"; d="$TRP_S"
  _trp_go _lf_run "$TRC/w" "$d" - "$FELIX" which; TRCF="$TRP_FIRE"; TRCW="$(_trp_wcls "$TRC/w" "$d")"; TRCS="$(_trp_said "$TRC/w")"
  _trp_go _lf_run "$TRC/l" "$d" - "$FELIX" lane --tsv
  if [ "$LF_RC" = 2 ] && [ ! -s "$TRC/l.out" ] \
     && LC_ALL=C grep -Fxq "felix: the project that governs $d could not be resolved: a read it stands on did not finish." "$TRC/l.err" 2>/dev/null
  then TRCL=unresolved; else TRCL="status $LF_RC"; fi
  _trp_go _trp_drv "$TRC/r" "$d" resolve "$d" "$TRP_H"; TRCR="$(_trp_rcls "$TRC/r")"
  TRCN=$((TRCN + 1)); r=""
  case "$TRCW:$TRCL" in (unknown:unresolved) ;; (unknown:*) r="which unknown, lane $TRCL" ;; (*:unresolved) r="lane unresolved, which $TRCW" ;; esac
  case "$TRCW" in
    found:*) [ "$TRCR" = "found:$TRP_H/projects/${TRCW#found:}" ] || r="${r:+$r; }which $TRCW, resolve $TRCR" ;;
    *) case "$TRCR" in found:*) r="${r:+$r; }resolve $TRCR, which $TRCW" ;; esac ;;
  esac
  [ -z "$r" ] || TRCDIS="$TRCDIS[$1 $TRCCASE: $r] "
}
# LAYOUT -> TRCCL what felix which says from LAYOUT's sub/dir with no fault (_trp_said), TRCCW its class.
_trc_clean() { _trp_at "$TRC/$1"; _lf_run "$TRC/c" "$TRP_S" - "$FELIX" which; TRCCL="$(_trp_said "$TRC/c")"; TRCCW="$(_trp_wcls "$TRC/c" "$TRP_S")"; }
# LABEL LAYOUT MODE NAME WORDS -> one assertion: under the probe (any calling function), felix which from LAYOUT is
# unknown, or says exactly what the clean run says, when the probe acted; and exactly what the clean run says when the
# probe never acted (P46, review round 1: section 5's head, a read the fix no longer makes cannot fail). A probe that
# acted but whose command still ran to a clean exit is no fault and fails, as everywhere else.
_trc_or_clean() {
  local lab="$1" l="$2" v
  _trp_new "$TRC/p.fired"; _trp_arm "$3" "$4" "$5" '*' || { bad "$lab" "the probe could not be armed"; return; }
  TRCCASE="$3 $4"; _trc_three "$l"
  case "$TRCF" in
    (fired) if [ "$TRCW" = unknown ] || [ "$TRCS" = "$TRCCL" ]; then v=ok; else v="fired: $TRCS"; fi ;;
    ("not fired:"*) if [ "$TRCS" = "$TRCCL" ]; then v=ok; else v="$TRCF, and not the clean run: $TRCS"; fi ;;
    (*) v="$TRCF" ;;
  esac
  is "$lab" "$v" ok
}

# --- P17, P18, P19: the refusal sentences' own reads.
_trc_clean badmarker
is "P17 (control): felix which on res-badmarker, no fault: the broken sentence, which lists the known projects" \
   "$TRCCW|$(case "$TRCCL" in (*"known projects: alpha beta gamma "*) printf listed ;; (*) printf 'not listed' ;; esac)" "broken|listed"
for _trc_m in f2 f3; do
  _trc_or_clean "P17, P46: felix which on res-badmarker (a broken marker), $_trc_m at the ls of the projects directory: unknown, or the clean broken sentence byte for byte; never known projects: none while projects exist" \
    badmarker "$_trc_m" ls "*'/projects '*"
done
_trc_clean none
is "P18 (control): felix which on res-none, no fault: no project governs, with Known projects: alpha beta gamma" \
   "$TRCCW|$(case "$TRCCL" in (*"Known projects: alpha beta gamma "*) printf listed ;; (*) printf 'not listed' ;; esac)" "none|listed"
for _trc_m in f2 f3; do
  _trc_or_clean "P18, P46: felix which on res-none, $_trc_m at the ls behind Known projects: unknown, or main's no-project sentence byte for byte" \
    none "$_trc_m" ls "*'/projects '*"
done
_trc_clean tie
is "P19 (control): felix which on res-tie, no fault: the tie sentence naming alpha, beta" \
   "$TRCCW|$(case "$TRCCL" in (*"fits alpha, beta equally well"*) printf named ;; (*) printf 'not named' ;; esac)" "broken|named"
_trc_or_clean "P19, P46: felix which on res-tie, F3 at the tr -cd [:print:] that cleans the names (_felix_binding_sane): unknown, or the clean tie sentence byte for byte; a cleaner made fork-free (R12) leaves the probe unfired and must leave the clean tie sentence" \
  tie f3 tr "*' -cd [:print:] '*"
is "P38: over the $TRCN runs of P17-P19 (res-badmarker, res-none and res-tie under their faults), felix which is unknown exactly where felix lane says could not be resolved, and found with P only where felix_resolve_project prints .../projects/P with 0" \
   "${TRCDIS:-agreed}" agreed

# --- P20, P21: a checkout once bound by remote whose project.json went missing.
# LAYOUT NOMEM -> the bindings record of LAYOUT's checkout written by felix_binding_broken itself (a clean run, in the
# memory root FELIX_MEMORY names, or HOME's default when NOMEM is 1), then beta's project.json moved to
# project.json.bak. TRCB "built" when the record names beta and the move was made.
_trc_bound() {
  local f
  _trp_at "$TRC/$1"
  if [ "$2" = 1 ]; then f="$TRP_U/.felix/memory/bindings.tsv"; else f="$TRP_M/bindings.tsv"; fi
  TRP_NOMEM="$2" _trp_drv "$TRC/b" "$TRP_S" broken "$TRP_S" "$TRP_H"
  TRCB="not built: $(_trp_ro "$TRC/b") record [$(cat "$f" 2>&1)]"
  LC_ALL=C awk -F'\t' '$2 == "beta" { f = 1 } END { exit !f }' "$f" 2>/dev/null || return 1
  mv "$TRP_H/projects/beta/project.json" "$TRP_H/projects/beta/project.json.bak" || return 1
  [ ! -e "$TRP_H/projects/beta/project.json" ] && TRCB=built
}
_trc_bound bound 0
_trp_at "$TRC/bound"; _lf_run "$TRC/c" "$TRP_S" - "$FELIX" which
is "P20 (control): a checkout once bound to beta by remote (its bindings.tsv row written), beta's project.json moved to project.json.bak, no fault: felix which says it no longer resolves (main's), exit 2" \
   "$TRCB|$(_trp_wcls "$TRC/c" "$TRP_S")|$(LC_ALL=C grep -c 'no longer resolves' "$TRC/c.err" 2>/dev/null)" "built|broken|1"
for _trc_m in f2 f3; do
  _trp_new "$TRC/p.fired"; _trp_arm "$_trc_m" git "*' hash-object --stdin '*" '*'
  _trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
  is "P20: the same checkout, $_trc_m at the git hash-object that keys the bindings record: unknown, never no project governs" \
     "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"
done
_trc_bound boundhome 1
_trp_at "$TRC/boundhome"; _lf_run "$TRC/c" "$TRP_S" - env -u FELIX_MEMORY "$FELIX" which; TRCCL="$(_trp_said "$TRC/c")"
is "P21 (control): the same layout with FELIX_MEMORY unset (the record in ~/.felix/memory), no fault: felix which says it no longer resolves, exit 2" \
   "$TRCB|$(_trp_wcls "$TRC/c" "$TRP_S")|$(LC_ALL=C grep -c 'no longer resolves' "$TRC/c.err" 2>/dev/null)" "built|broken|1"
_trp_new "$TRC/p.fired"; _trp_arm f3z printf '*' "*' felix_mem_root '*' _felix_binding_remote '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - env -u FELIX_MEMORY "$FELIX" which
TRCS="$(_trp_said "$TRC/w")"
case "$TRP_FIRE:$(_trp_wcls "$TRC/w" "$TRP_S")" in
  fired:unknown) _trc_v=ok ;;
  fired:*) [ "$TRCS" = "$TRCCL" ] && _trc_v=ok || _trc_v="fired: $TRCS" ;;
  *) [ "$TRCS" = "$TRCCL" ] && _trc_v=ok || _trc_v="not fired, and not the clean run: $TRCS" ;;
esac
is "P21: FELIX_MEMORY unset, F3 at the memory-root read (the substitution around felix_mem_root inside _felix_binding_remote): unknown or the clean sentence, never no project governs (a probe that never acts, the read made fork-free, must leave the clean run)" \
   "$_trc_v" ok

# --- P23: every resolve_or_die command under a marker read that did not finish.
_trp_at "$TRC/marker"
_trc_sha() { ( _fx_cd "$TRP_CO" || exit 1; _lf_g 1700000000 rev-parse HEAD ) 2>/dev/null; }
TRCH0="$(_trc_sha)"
for _trc_c in which merge "land --status" repair "land --tick"; do
  case "$_trc_c" in repair) _trc_rc=4 ;; *) _trc_rc=2 ;; esac
  _trp_new "$TRC/p.fired"; _trp_arm f3 tr "*' -d [:space:] '*" '*'
  # shellcheck disable=SC2086
  _trp_go _lf_run "$TRC/w" "$TRP_S" - env FELIX_LAND_LEDGER="$TRP_FX/land/ledger.tsv" "$FELIX" $_trc_c
  case "$_trc_c" in
    merge) _trc_x="|says.log merged rows $(LC_ALL=C awk '/merged/ { n++ } END { print n + 0 }' "$TRP_M/alpha/says.log" 2>/dev/null || printf 0)|HEAD $( [ "$(_trc_sha)" = "$TRCH0" ] && printf kept || printf moved)"
           _trc_w="|says.log merged rows 0|HEAD kept" ;;
    "land --tick") _trc_x="|unresolved rows $(LC_ALL=C awk -F'\t' '$2 == "unresolved" { n++ } END { print n + 0 }' "$TRP_FX/land/ledger.tsv" 2>/dev/null)"
           _trc_w="|unresolved rows 1" ;;
    *) _trc_x=""; _trc_w="" ;;
  esac
  is "P23: felix $_trc_c on base, F3 at the marker's tr: exit $_trc_rc, nothing on stdout, stderr the could-not-be-resolved sentence${_trc_w:+ (and$(printf '%s' "$_trc_w" | tr '|' ' '))}" \
     "$(_trc_unk "$TRC/w" "$TRP_S" "$_trc_rc")$_trc_x|$TRP_FIRE" "unknown$_trc_w|fired"
done

# --- P24: felix which's own reads.
_trp_new "$TRC/p.fired"
_trp_arm f3 pwd "*' -P '*" "*' felix_repo_root '*' cmd_which '*" "*' resolve_or_die '*|*' felix_resolve_project '*|*' felix_binding_broken '*"
_trp_arm f3 git "*' rev-parse --show-toplevel '*" "*' felix_repo_root '*' cmd_which '*" "*' resolve_or_die '*|*' felix_resolve_project '*|*' felix_binding_broken '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
is "P24: felix which on base, F3 at felix_repo_root for the governs line (the walk's pwd -P and git rev-parse, called by cmd_which): unknown, nothing on stdout (never four lines, never an empty or wrong governs:)" \
   "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"
_trp_new "$TRC/p.fired"; _trp_arm f1 sed "*'\"gate\"'*" "*' cmd_which '*" "*' resolve_or_die '*"
_trp_go _lf_run "$TRC/w" "$TRP_S" - "$FELIX" which
is "P24: felix which on base, F1 at the sed that reads the gate key (called by cmd_which): unknown, nothing on stdout (never an empty gate:)" \
   "$(_trc_unk "$TRC/w" "$TRP_S" 2)|$TRP_FIRE" "unknown|fired"

# --- P45: felix_accepted_deploy_diff from a directory that holds only resolve.sh.
TRCJ="$TRC/judge"; TRCJR="$TRCJ/home"; TRCJC="$TRCJ/cache"; TRCJE="$TRCJC/felix/felix/4.0.0"
mkdir -p "$TRCJR/engine/harness/lib" "$TRCJR/engine/hooks" "$TRCJR/engine/commands" "$TRCJ/alone" "$TRCJ/empty"
printf 'real\n' > "$TRCJR/engine/harness/felix"; printf 'x\n' > "$TRCJR/engine/harness/lib/x.sh"
printf '{}\n' > "$TRCJR/engine/hooks/hooks.json"; printf '# felix\n' > "$TRCJR/engine/commands/felix.md"
( _fx_cd "$TRCJR" && git init -q -b main ) >/dev/null 2>&1
_jr_commit "$TRCJR" main engine/.claude-plugin/plugin.json '{ "name": "felix", "version": "4.0.0" }'
_jr_on "$TRCJR" "$(_jr_sha "$TRCJR" HEAD)" refs/remotes/origin/main
cp "$FROOT/harness/lib/resolve.sh" "$TRCJ/alone/resolve.sh"
# -> TRCJE holds main's engine/{harness,hooks,commands,.claude-plugin}, cut from the commit.
_trc_cut() {
  rm -rf "$TRCJE" "$TRCJ/x" "$TRCJ/x.tar"; mkdir -p "$TRCJE" "$TRCJ/x"
  _fx_git "$TRCJR" archive -o "$TRCJ/x.tar" HEAD engine >/dev/null 2>&1 && tar -x -C "$TRCJ/x" -f "$TRCJ/x.tar"
  for _trc_d in harness hooks commands .claude-plugin; do [ ! -d "$TRCJ/x/engine/$_trc_d" ] || cp -R "$TRCJ/x/engine/$_trc_d" "$TRCJE/$_trc_d"; done
}
# CACHE LIB -> TRCJO: felix_accepted_deploy_diff HOME main, run by the driver from HOME with FELIX_PLUGIN_CACHE CACHE and
# the library directory LIB (the suite's engine lib/ when empty), FELIX_KERNEL_CACHE and GIT_CONFIG_GLOBAL unset, as
# "rc=<status> out=[<stdout>]".
_trc_judge() {
  TRCJO="$( unset FELIX_KERNEL_CACHE GIT_CONFIG_GLOBAL
            FELIX_PLUGIN_CACHE="$1" TRP_LIB="$2" _trp_drv "$TRCJ/o" "$TRCJR" judge "$TRCJR" main; _trp_ro "$TRCJ/o" )"
}
for _trc_v in identical drift nocache; do
  _trc_cut; _trc_cache="$TRCJC"
  case "$_trc_v" in drift) printf 'only in the entry\n' > "$TRCJE/harness/extra.sh" ;; nocache) _trc_cache="$TRCJ/empty" ;; esac
  _trc_judge "$_trc_cache" ""; _trc_full="$TRCJO"
  _trc_judge "$_trc_cache" "$TRCJ/alone"; _trc_one="$TRCJO"
  case "$_trc_v" in
    identical) _trc_ok="$( [ "$_trc_full" = "rc=0 out=[$TRCJE
]" ] && printf contract || printf 'not the contract' )" ;;
    drift) _trc_ok="$(case "$_trc_full" in ("rc=1 out=["*extra.sh*) printf contract ;; (*) printf 'not the contract' ;; esac)" ;;
    *) _trc_ok="$(case "$_trc_full" in ("rc=2 out=["*) printf contract ;; (*) printf 'not the contract' ;; esac)" ;;
  esac
  case "$_trc_v:$_trc_one" in nocache:*) _trc_tell=told ;; *:rc=2*) _trc_tell="cannot tell" ;; *) _trc_tell=told ;; esac
  is "P45: the merge judge's call with the entry $_trc_v: felix_accepted_deploy_diff sourced from a directory holding only resolve.sh gives main's answer (the contract's: identical 0 and the entry, drift 1 naming the path, no cache 2), the same as with every library beside it, and never cannot tell where the full engine tells" \
     "$_trc_ok|$( [ "$_trc_one" = "$_trc_full" ] && printf same || printf 'alone [%s] full [%s]' "$_trc_one" "$_trc_full")|$_trc_tell" "contract|same|told"
done
TRP_NAMES=""
# <<< trust-cli-refusals-unfinished-reads

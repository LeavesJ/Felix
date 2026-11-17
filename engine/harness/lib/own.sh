# Unattended work runs only in the bound project's OWN checkout.
#
# THE RULE, AS A CLASS. Work that runs with nobody present (started by a hook,
# or by a child a hook detached) in a checkout, or that runs a tool whose
# behaviour depends on the checkout's files, runs only when the checkout is the
# bound project's own: its binding is corroborated by something the tree cannot
# choose.
#
# WHY. A checkout is bound to a project by its .felix marker first and by a
# substring of its origin second (felix_resolve_project). The marker is a file
# of the tree, so a repository's authors choose it, and a project's name is
# public: a repository opened on this machine to hunt for bugs can ship a .felix
# naming a governed project and be bound to it. The binding is right for what a
# person is present for (context, deny rows, the gate, the Stop hold) and it is
# left exactly as it was. What it must not unlock is the work nobody watches: the
# commissioning pipeline, which evals the project's table in the checkout and
# runs installers; the graph refresh, which points graphify at the checkout's
# files; tidying, which deletes files in it; and adoption, which writes the
# project's durable tables from what an unowned tree contains.
#
# THE CORROBORATION is the checkout's origin remote, parsed (felix_remote_github_slug)
# and compared as owner/repo on github.com, exactly, with the project's
# project.json remote_match (felix_checkout_is_own). Not a substring: today's
# resolution step 2 is one, and `git@evil.example:Owner/repo.git` and
# `Owner/repo-fork` pass a substring test. A .felix marker never corroborates. A
# project with no usable remote_match has no own checkout, so nothing runs
# unattended for it in any checkout. Only 0 lets the work run; unknown (git could
# not answer) is withheld like not-own.
#
# A SUBMODULE IS NEVER OWN. A plain clone's origin is the URL a person cloned
# from, which the tree cannot choose. A submodule's origin is written by git from
# the superproject's tracked .gitmodules, so the superproject's authors choose
# it, and any project whose GitHub repo they can fork or open a pull request
# against can be named: the gitlink commit only has to be fetchable from there.
# So a checkout that has a superproject is not own whatever its origin reads
# (felix_checkout_is_own, why `submodule`). A linked worktree made with
# `git worktree add` from inside a submodule shares its gitdir and so its origin,
# and git reports no superproject for it, so it is NOT refused; making one is a
# person's act on a repository they already hold, and it is not claimed here.
#
# WHAT THIS DOES NOT DEFEND. A checkout whose .git directory itself came from an
# attacker (a tarball with .git in it) controls its own config, its own origin and
# the code git runs from it, and that is out of Felix's reach and not claimed here.
#
# The gates sit at the session-start call sites, except commissioning, whose
# gate is inside felix_commission_resume_bg because that function has no
# attended caller and its refusal is written to the log it already keeps. The
# libraries the gates sit in front of (tidy, graph refresh, adoption) are
# unchanged, because attended callers and tests reach them too.
#
# Two more since 2026-10-29, both the graph's. SessionEnd starts the same graph
# refresh, behind the same gate. And the user-prompt hook hands the model the
# graph's answer to each prompt (lib/graph-answer.sh, felix_graph_deliver): a
# person is present, but what is handed over is read from graph.json, a file
# of the checkout, so a checkout that is not own is handed nothing. That one is
# not withheld work and records nothing in _FELIX_OWN_WITHHELD; it is simply
# not said.

# Sourced by path because the suite sources libraries alone, in subshells, and a
# call that resolved to nothing would degrade to running nothing (house pattern).
if ! command -v felix_json_str >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# 0 when <path> is exactly owner/repo: two non-empty segments of [a-z0-9._-],
# neither of them . or .. . The characters are listed rather than ranged so that
# no locale's collation can widen them. Wider than GitHub's own names on purpose:
# equality decides, and a remote_match such as example.com/widget stays usable.
_felix_own_pair() {
  local p="${1:-}" o r lc=abcdefghijklmnopqrstuvwxyz0123456789._-
  case "$p" in ''|/*|*/|*/*/*) return 1 ;; */*) ;; *) return 1 ;; esac
  o="${p%%/*}"; r="${p#*/}"
  case "$o" in ''|.|..|*[!$lc]*) return 1 ;; esac
  case "$r" in ''|.|..|*[!$lc]*) return 1 ;; esac
  return 0
}

# The owner/repo a remote URL names on github.com, lowercased, or nothing.
# Prints it and returns 0, or prints nothing and returns 1.
#
# The URL is lowercased whole, and any byte outside printable ASCII, any space,
# and a ?, # or \ anywhere in it refuse. By URL rules the authority ends at the
# first of ? or #: measured 2026-10-13, git 2.54.0 given https://evil.invalid#@github.com/o/r
# (and ?@) resolves evil.invalid, though the text up to its last @ looks like
# userinfo for github.com. A \ is read as a path separator by some URL parsers and
# as userinfo by others (that git connected to github.com), so it refuses too:
# where parsers disagree about the host, no host is corroborated. One trailing /
# and then one trailing .git are dropped. Accepted:
#   https://[userinfo@]H[:port]/P     ssh://[user@]H[:port]/P
#   git://H[:port]/P                  [user@]H:P   (scp-style: no ://, and no /
#                                                   before the first :)
# Userinfo is everything up to the last @ of the authority and is discarded; a
# port is : and digits only. H must be github.com exactly, so github.com.evil.example,
# evil.example and www.github.com refuse, and so does http:// , git+ssh:// ,
# file:// and a local path. P must be exactly owner/repo (_felix_own_pair); a
# leading / in the scp form and a third segment refuse. The URL is never printed
# anywhere: an https remote can carry a token as its userinfo.
felix_remote_github_slug() {
  local u="${1:-}" rest="" auth p host port scp=0
  [ -n "$u" ] || return 1
  u="$(printf '%s' "$u" | LC_ALL=C tr 'A-Z' 'a-z')" || return 1
  [ -z "$(printf '%s' "$u" | LC_ALL=C tr -d '[:print:]')" ] || return 1
  case "$u" in *" "*|*$'\n'*|*[?#\\]*) return 1 ;; esac
  u="${u%/}"; u="${u%.git}"
  case "$u" in
    https://*) rest="${u#https://}" ;;
    ssh://*)   rest="${u#ssh://}" ;;
    git://*)   rest="${u#git://}" ;;
    *://*)     return 1 ;;
    *:*)       scp=1; auth="${u%%:*}"; p="${u#*:}"
               case "$auth" in */*) return 1 ;; esac ;;
    *)         return 1 ;;
  esac
  if [ "$scp" -eq 0 ]; then
    case "$rest" in */*) ;; *) return 1 ;; esac
    auth="${rest%%/*}"; p="${rest#*/}"
  fi
  auth="${auth##*@}"
  host="$auth"
  if [ "$scp" -eq 0 ]; then
    case "$auth" in
      *:*) host="${auth%%:*}"; port="${auth#*:}"
           case "$port" in ''|*[!0123456789]*) return 1 ;; esac ;;
    esac
  fi
  [ "$host" = github.com ] || return 1
  _felix_own_pair "$p" || return 1
  printf '%s\n' "$p"
}

# Is <root> the own checkout of the project <proj> (a path under the Felix home)?
# 0 own, 1 not own, 2 unknown (git could not answer). Sets _FELIX_OWN_WHY to
# exactly one of own, no-match, no-origin, submodule, other, unread.
#
#   1. project.json's remote_match, lowercased with a trailing / and then .git
#      dropped, must be exactly owner/repo (_felix_own_pair). Empty, absent,
#      example.com and a/b/c are not: no-match, and no checkout of that project
#      is its own, whatever its origin and whatever its .felix says.
#   2. git not on PATH is unread.
#   3. `git remote get-url origin`. Measured 2026-10-13 on git 2.54.0: 2 when
#      there is no origin, 128 outside a repository. 2 is no-origin; any other
#      failure (128, 69 under an unaccepted Xcode licence, 127) is unread; on 0:
#   4. `git rev-parse --show-superproject-working-tree` names the superproject
#      of a submodule and nothing for a plain clone, a superproject, or a linked
#      worktree of either. It failing is unread; a path is not own, `submodule`,
#      whatever the origin reads, because a submodule's origin comes from the
#      superproject's tracked .gitmodules and so is the tree's to choose.
#   5. Else own when felix_remote_github_slug of the URL equals the remote_match,
#      and other when it does not.
#
# The .felix marker is never read here and a substring is never enough. The
# origin URL is never printed, logged or written. See the head of this file for
# what that corroboration does not defend.
felix_checkout_is_own() {
  local proj="${1:-}" root="${2:-}" m u rc sp
  _FELIX_OWN_WHY=no-match
  m="$(felix_json_str "$proj/project.json" remote_match 2>/dev/null)"
  m="$(printf '%s' "$m" | LC_ALL=C tr 'A-Z' 'a-z')"
  m="${m%/}"; m="${m%.git}"
  _felix_own_pair "$m" || return 1
  _FELIX_OWN_WHY=unread
  command -v git >/dev/null 2>&1 || return 2
  u="$(git -C "$root" remote get-url origin 2>/dev/null)"; rc=$?
  case "$rc" in
    0) ;;
    2) _FELIX_OWN_WHY=no-origin; return 1 ;;
    *) return 2 ;;
  esac
  sp="$(git -C "$root" rev-parse --show-superproject-working-tree 2>/dev/null)" || return 2
  if [ -n "$sp" ]; then _FELIX_OWN_WHY=submodule; return 1; fi
  if [ "$(felix_remote_github_slug "$u")" = "$m" ]; then _FELIX_OWN_WHY=own; return 0; fi
  _FELIX_OWN_WHY=other
  return 1
}

# The gate itself: `felix_own_gate <kind> <status>`, status being what
# felix_checkout_is_own returned. 0 lets the work run. Anything else records the
# kind in _FELIX_OWN_WITHHELD (", "-joined, a kind once) and returns 1. Called
# only for work that was due, so a quiet session withholds nothing and says
# nothing. The kinds are adoption, graph refresh, tidying and commissioning.
felix_own_gate() {
  [ "${2:-}" = 0 ] && return 0
  case ", ${_FELIX_OWN_WITHHELD:-}, " in
    *", ${1:-}, "*) ;;
    *) _FELIX_OWN_WITHHELD="${_FELIX_OWN_WITHHELD:+$_FELIX_OWN_WITHHELD, }${1:-}" ;;
  esac
  return 1
}

# Is tidying due here: granted, and is there an untracked rival the project holds
# a copy of, which felix_tidy_safe would remove? The same first three checks as
# that function, and read-only (git ls-files). It exists so the line below is
# only said when something was actually withheld.
felix_own_tidy_due() {
  local proj="${1:-}" root="${2:-}" gate rivals state f note
  command -v felix_autonomy_allows >/dev/null 2>&1 && felix_autonomy_allows "$proj" tidy || return 1
  command -v _felix_rival_gates >/dev/null 2>&1 || return 1
  gate="$(felix_json_str "$proj/project.json" gate 2>/dev/null)"
  rivals="$(_felix_rival_gates "$root" "$proj" "$gate" 2>/dev/null)"
  while IFS=$'\t' read -r state f note; do
    [ "${state:-}" = untracked ] && [ -n "${f:-}" ] && [ -f "$proj/${f##*/}" ] && return 0
  done <<EOF
$rivals
EOF
  return 1
}

# The one line a session hears when unattended work was due here and withheld:
# `felix_own_withheld_line <proj> <root> <home>`. Prints nothing when
# _FELIX_OWN_WITHHELD is empty, or when the checkout turns out to be own. Else a
# blank line and
#
#   Nothing ran here unattended: <project> is bound to this checkout <B>, and <R>. Withheld: <K>.
#
# B is "by its .felix marker" when the root holds one and "by an origin that only
# contains <remote_match>" when not; R says why it is not own (origin not
# github.com/<remote_match>, no origin remote, a submodule, the project declares
# no usable remote_match, or the origin could not be read). It is said once per checkout
# and set of kinds: the key "<root><TAB><K>" is kept a line in
# <home>/state/own/<project>.seen, and a key already there prints nothing. A root
# or kinds holding a tab or a newline are not recorded, and a .seen that cannot be
# written does not stop the line: it is then said each time. Stealth rule: a
# session hears from Felix briefly, not every time.
felix_own_withheld_line() {
  local proj="${1:-}" root="${2:-}" home="${3:-}" name rmw by why seen key tab=$'\t' nl=$'\n' rec=1
  [ -n "${_FELIX_OWN_WITHHELD:-}" ] || return 0
  felix_checkout_is_own "$proj" "$root" && return 0
  name="$(basename "$proj")"
  rmw="$(felix_json_str "$proj/project.json" remote_match 2>/dev/null)"
  if [ -f "$root/.felix" ]; then by="by its .felix marker"; else by="by an origin that only contains $rmw"; fi
  case "${_FELIX_OWN_WHY:-}" in
    other)     why="its origin is not github.com/$rmw" ;;
    no-origin) why="it has no origin remote" ;;
    submodule) why="it is a submodule, whose origin the repository holding it chooses" ;;
    no-match)  why="$name declares no remote_match naming a github.com owner/repo, so no checkout is its own" ;;
    *)         why="its origin could not be read" ;;
  esac
  case "$root$_FELIX_OWN_WITHHELD" in *"$tab"*|*"$nl"*) rec=0 ;; esac
  seen="$home/state/own/$name.seen"; key="$root$tab$_FELIX_OWN_WITHHELD"
  if [ "$rec" -eq 1 ] && [ -f "$seen" ] && grep -qxF -- "$key" "$seen" 2>/dev/null; then
    return 0
  fi
  printf '\nNothing ran here unattended: %s is bound to this checkout %s, and %s. Withheld: %s.\n' \
    "$name" "$by" "$why" "$_FELIX_OWN_WITHHELD"
  if [ "$rec" -eq 1 ] && [ -n "$home" ]; then
    mkdir -p "$home/state/own" 2>/dev/null && printf '%s\n' "$key" >> "$seen" 2>/dev/null
  fi
  return 0
}

# The lander's alert that waits for the founder (audit b05, R6): `felix_land_alert_line <mem-dir>`,
# the project's memory directory. When the newest record of <mem-dir>/land/alerts.tsv (eight fields)
# is no-alert-workflow, the lander tried to tell the founder and the repository has no
# .github/workflows/felix-alert.yml yet, so the alert is not sent: a blank line and one sentence
# saying so. Any other newest record, or none, prints nothing. Read-only; the record is left as it was.
felix_land_alert_line() {
  local f="${1:-}/land/alerts.tsv" v
  [ -n "${1:-}" ] && [ -f "$f" ] && [ -r "$f" ] || return 0
  v="$(LC_ALL=C awk -F'\t' '{ n = NF; s = $2; k = $3; t = $1 } END { if (n == 8 && s == "no-alert-workflow") printf "%s at %s", k, t }' "$f" 2>/dev/null)"
  [ -n "$v" ] || return 0
  printf '\nThe lander could not tell the founder off this Mac: its newest alert (%s) is no-alert-workflow. .github/workflows/felix-alert.yml is not on the repository yet, so alerts wait in land/alerts.tsv; felix status shows it.\n' "$v"
  return 0
}

# Run the commissioning pipeline with nobody present, when a person has said it
# may and the checkout is the project's own.
#
# Deliberately thin. It takes no lock of its own: cmd_commission takes one, so
# this is just another caller and a run that arrives while a person is
# commissioning gives up quietly — which is the right answer, where two writers
# appending to one manifest is not.
#
# Refusals before it starts, and each is a different question; all are silent.
#   - Is it granted at all.
#   - Does the grant still cover the table on disk? An ordinary edit to
#     commissioning.tsv must not inherit a person's consent, because two of its
#     columns are eval'd.
#   - Is there a table to run.
# And then the one this file is about: is the checkout the project's own? If
# not, the run is withheld, with a refused-not-own line in the log it already
# keeps and the kind recorded for the session's one line. That is the only
# refusal that is not silent, because it is the only one a person would want to
# find out about: a grant was current and a checkout asked for the run.
# `felix commission` typed by a person is not refused anywhere: a person present
# is the consent.
#
# The outcome is written down. A detached run whose output goes to /dev/null
# fails where nobody can see it, which is the shape this repository keeps
# finding: a silence that reads as success. One line per run, so the next
# session can say what the last unattended one did.
felix_commission_resume_bg() {
  local proj="$1" home="$2" bin="${3:-}" log root
  [ -n "$bin" ] && [ -x "$bin" ] || return 0
  command -v felix_autonomy_commission_current >/dev/null 2>&1 || return 0
  felix_autonomy_commission_current "$proj" || return 0
  [ -f "$proj/commissioning.tsv" ] || return 0
  root="$(felix_repo_root "$PWD")"; [ -n "$root" ] || return 0
  log="$home/state/commission/$(basename "$proj").bg.log"
  mkdir -p "$(dirname "$log")" 2>/dev/null || return 0
  felix_checkout_is_own "$proj" "$root"; [ $? -eq 0 ] || {
    printf '%s\trefused-not-own\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$root" 2>/dev/null >> "$log"
    felix_own_gate commissioning 1; return 0; }
  (
    felix_close_inherited_fds
    cd "$root" 2>/dev/null || exit 0
    if "$bin" commission >/dev/null 2>&1; then
      printf '%s\tran\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$root" >> "$log"
    else
      printf '%s\tdeclined-or-failed\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$root" >> "$log"
    fi
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# The lane's own resolution of the project a directory is bound to (design section 11 items 46 to 48; C2's bullet "The lane's
# resolution" in docs/2026-10-29-lane-slice-0-plan.md).
#
# WHY IT EXISTS. felix_resolve_project, _felix_resolve_remote and felix_binding_broken (lib/resolve.sh) and resolve_or_die
# (felix) are run by felix merge and felix land (resolve_or_die; lib/green-install.sh and lib/status-land.sh), so the lane
# exclusions of the plan's Global Constraints keep them byte for byte as main has them, and the lane cannot change them. They
# answer a read that did not finish as they answer an empty one: a fork that fails in one of their substitutions leaves an
# empty name, an empty origin or an empty remote_match, so the directory reads as one no project governs, status 1, or a
# remote_match left out of the comparison lets a shorter one bind, status 0 with a project. Here the lane checks the answer
# itself, a found project as it checks a miss, and says the resolution did not finish where it did not. Only the lane's own
# output reads this resolution (felix lane, status's lane row, the pulse's lane lines); every other surface takes the shared
# resolver's answer as it comes (design 11 item 49), a limit of that resolver whose change lies outside the lane.
#
# felix_lane_resolve START HOME  Prints the project directory felix_resolve_project prints for START under HOME, returns 0.
#                                Returns 1 for a miss that stands, printing the sentence felix lane says for it (below; every
#                                other caller reads a stdout with a status other than 0 as nothing). Returns 2 when the
#                                resolution did not finish: its process ended with a status other than 0 and 1, or it returned
#                                0 and printed nothing, or the check or the sentence's own reads did not finish, or the check
#                                binds where the resolver found nothing, or binds nothing or another project where the
#                                resolver found one. Any other status of a caller's substitution (128 for a fork that failed,
#                                137 for a signal) is a resolution that did not finish too.
# felix_lane_miss SENTENCE       Says felix_lane_resolve's sentence as felix's die says it, and exits 2.
#
# WHAT THE CHECK DOES. It makes every read the answer stands on again, each ending in a sentinel line as felix_capture does
# (lib/detect.sh), so a substitution that ended early reads as a check that did not finish, never as an empty answer: the
# repository root of START (felix_repo_root); the .felix marker; the origin remote's URL in that root, its trailing LFs
# dropped as the resolver's command substitution drops them; each project.json's remote_match, by a sed of its own and no
# pipe (felix_json_str's pipe ends in head, so its status is head's, and a sed that cannot run reads as a read that found no
# field). It then binds as felix_resolve_project binds, through the unchanged helpers _felix_name_ok, _felix_lc,
# _felix_remote_slug and _felix_remote_match: a marker that is a file decides alone, and binds when it names an existing
# project directory; a marker that exists and cannot be opened names nothing; else the one longest remote_match that names
# the origin binds, and none does on a tie. A miss stands only when every read finished and none binds. A project stands only
# when every read finished and the binding is that same project directory. For a miss it records what the sentence needs:
# the root, and the marker's content with its whitespace removed, or the names of the tied projects in the order it met them.
# WHAT IT DOES NOT SEE. The GitHub slug read that _felix_remote_slug makes for an owner/repo remote_match (it sources
# lib/own.sh: no lane file calls into it), which is read through that function as the resolver reads it, so a fault in it
# changes both bindings alike. That is a stated limit (C2). So are a project directory whose name ends in LF, which no command
# substitution carries, and the two layouts felix_binding_broken tells apart that the check does not read (C5).
# THE SENTENCE (C5, "Not governed") is resolve_or_die's, as main says it for the layout the check read, built here from the
# check's own reads: felix_binding_broken is not run, since its reads go unchecked and it can append to the memory root's
# bindings.tsv. The names of the projects are ls's, run by felix_capture with no pipe in the caller's locale, as resolve_or_die
# runs it, and their LFs turned into spaces in the shell; a value is cleaned as _felix_binding_sane cleans it, without its
# pipe. A read of the sentence that does not finish makes the resolution one that did not finish.
# It runs in a subshell with its stderr off, so a fork that fails or a signal that ends a read, and bash's note of it, leave
# nothing on the surface's stderr; the surface says what it found. Bash 3.2; LC_ALL=C on every text tool.

_LANE_RLIB="${BASH_SOURCE[0]:-$0}"
case "$_LANE_RLIB" in */*) _LANE_RLIB="${_LANE_RLIB%/*}" ;; *) _LANE_RLIB=. ;; esac

# The reads of the check, each run by felix_capture and returning 0 whenever the read itself finished, whatever it found.
_lane_marker() { [ -r "$1" ] || return 0; LC_ALL=C tr -d '[:space:]' 2>/dev/null < "$1"; }   # FILE: a marker that cannot be opened names nothing
_lane_origin() { cd "$1" || return 0; git remote get-url origin 2>/dev/null; return 0; }      # ROOT: no origin, or no repository, is no URL
# PROJECT.JSON: felix_json_str's sed for the key remote_match, on the file and with no pipe, so its status is sed's own. A path
# that is no regular file, or cannot be opened, has no field, and that read finished. The caller takes the first line printed.
_lane_remote_match() { [ -f "$1" ] && [ -r "$1" ] || return 0; LC_ALL=C sed -n 's/.*"remote_match"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1"; }
# DIR: the names resolve_or_die lists, ls's own status being its own (a directory it cannot list is an empty list, as on main);
# a status other than ls's three (a signal, a shell that could not run it) is a read that did not finish.
_lane_ls() { ls "$1" 2>/dev/null; case "$?" in 0|1|2) return 0 ;; esac; return 1; }

# START HOME -> 0 when every read finished, whatever it found, and 1 when one did not. Sets _LANE_BP, the project directory the
# reads bind START to (the one felix_resolve_project prints), empty when they bind none; and, for a miss, _LANE_BR the
# repository root and _LANE_BK its kind with _LANE_BN its content: "unread" for a .felix that is a file that cannot be opened
# (BN empty), "marker" for one that names no project (BN the name, whitespace removed, possibly empty), "tie" for remote_match
# values that name the origin equally (BN their project names, space separated, in the order met), else empty.
_lane_bind() {
  local start="$1" home="$2" root name url ul meta m m2 n best=0 sdone=0 best_p="" tie="" nl=$'\n' LC_ALL=C
  _LANE_BP=""; _LANE_BR=""; _LANE_BK=""; _LANE_BN=""
  felix_capture root felix_repo_root "$start" && [ -n "$root" ] || return 1
  _LANE_BR="$root"
  if [ -f "$root/.felix" ]; then
    [ -r "$root/.felix" ] || { _LANE_BK=unread; return 0; }
    felix_capture name _lane_marker "$root/.felix" || return 1
    if _felix_name_ok "$name" && [ -d "$home/projects/$name" ]; then _LANE_BP="$home/projects/$name"; else _LANE_BK=marker; _LANE_BN="$name"; fi
    return 0
  fi
  felix_capture url _lane_origin "$root" || return 1
  while [ "${url%"$nl"}" != "$url" ]; do url="${url%"$nl"}"; done   # as the resolver's command substitution takes it
  [ -n "$url" ] || return 0
  _felix_lc "$url"; ul="$_FELIX_LC"
  for meta in "$home"/projects/*/project.json; do
    [ -e "$meta" ] || continue
    felix_capture m _lane_remote_match "$meta" || return 1
    m="${m%%$'\n'*}"
    [ -n "$m" ] || continue
    m2="${m%/}"; _felix_lc "${m2%.git}"; case "$ul" in *"$_FELIX_LC"*) ;; *) continue ;; esac
    [ "$sdone" = 1 ] || { sdone=1; _felix_remote_slug "$url"; }
    _felix_remote_match "$m" "$url" "$_FELIX_RS" || continue
    n="${meta%/project.json}"; n="${n##*/}"
    if [ "$_FELIX_RM_LEN" -gt "$best" ]; then best="$_FELIX_RM_LEN"; best_p="$n"; tie=""
    elif [ "$_FELIX_RM_LEN" -eq "$best" ]; then tie="${tie:-$best_p} $n"; fi
  done
  if [ -n "$tie" ]; then _LANE_BK=tie; _LANE_BN="$tie"
  elif [ -n "$best_p" ]; then _LANE_BP="$home/projects/$best_p"; fi
  return 0
}

# VALUE -> _LANE_CL: what _felix_binding_sane prints, with no fork (its printf | tr pipe is not checked): printable ASCII bytes
# only, and a value longer than 80 bytes cut to its first 24 and its last 51 with [...] between.
_lane_clean() {
  local LC_ALL=C s="$1"
  s="${s//[!\ -~]/}"
  if [ "${#s}" -le 80 ]; then _LANE_CL="$s"; else _LANE_CL="${s:0:24}[...]${s:${#s}-51}"; fi
}

# START HOME -> prints the sentence resolve_or_die says on main (without "felix: " or a final LF) for the miss _lane_bind found,
# and returns 0; prints nothing and returns 1 when the list of project names could not be read.
_lane_say() {
  local start="$1" home="$2" names="" known="" nl=$'\n' root="$_LANE_BR" name="$_LANE_BN" what
  case "$_LANE_BK" in
    unread) printf 'The .felix marker in %s cannot be read, so it does not resolve to a project.' "$root"; return 0 ;;
    tie) _lane_clean "${name// /, }"
         printf 'The origin of the checkout at %s fits %s equally well: each declares a remote_match that names it, with the same length. So no project is bound, and nothing is checking this tree.\n\nLengthen one remote_match, or name the project in a .felix marker.' \
           "$root" "$_LANE_CL"
         return 0 ;;
  esac
  felix_capture names _lane_ls "$home/projects" || return 1
  [ -z "$names" ] || known="${names//"$nl"/ } "
  case "$_LANE_BK" in
    marker)
      _lane_clean "$name"
      if [ -z "$name" ]; then what="is empty, so it does not resolve to a project."
      elif ! _felix_name_ok "$name"; then what="names \"$_LANE_CL\", which is not a project name: a name is one directory name under $home/projects, and this is a path or a dot."
      else what="names \"$_LANE_CL\", and that does not resolve to a project under $home/projects."; fi
      printf 'The .felix marker in %s %s A marker is present, so this tree was meant to be governed, and right now nothing is checking it.\n\nName a project that exists, or remove the marker if this tree really is ungoverned:\n\n  known projects: %s' \
        "$root" "$what" "${known:-none}" ;;
    *) printf 'no project governs %s.\n  Either add a .felix file naming one, or declare remote_match in a project.json.\n  Known projects: %s' "$start" "$known" ;;
  esac
}

_lane_resolve() {   # START HOME
  local out rc
  out="$(felix_resolve_project "$1" "$2")"; rc=$?
  case "$rc" in
    0) [ -n "$out" ] || return 2 ;;
    1) ;;
    *) return 2 ;;
  esac
  [ "$(type -t felix_capture)" = function ] || . "$_LANE_RLIB/detect.sh"
  _lane_bind "$1" "$2" || return 2
  if [ "$rc" -eq 0 ]; then [ "$_LANE_BP" = "$out" ] || return 2; printf '%s' "$out"; return 0; fi
  [ -z "$_LANE_BP" ] || return 2
  _lane_say "$1" "$2" || return 2
  return 1
}

felix_lane_resolve() {   # START HOME
  ( exec 2>/dev/null; _lane_resolve "${1:-}" "${2:-}" )
}

# felix_lane_miss SENTENCE  felix_lane_resolve's stdout for a miss that stands, said as die says it, and exit 2. An empty
# sentence is a resolution that did not finish: C5's line for it.
felix_lane_miss() {
  [ -n "${1:-}" ] || die "the project that governs $PWD could not be resolved: a read it stands on did not finish." 2
  die "$1" 2
}

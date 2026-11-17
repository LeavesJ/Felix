# What felix bootstrap asks GitHub, and what it changes there.
#
# Every read says one of three things: yes, no, or that it could not tell. A
# failed call is the third, never the second. Bootstrap used to read any failure
# of `gh api .../protection` (a network error, a rate limit, no admin rights, a
# branch that does not exist) as "not protected", and then wrote a whole
# protection body over whatever was there. Only GitHub's own "Branch not
# protected" is a no.
#
# gh runs through _felix_bs_gh, which keeps its standard output, the first line
# of its standard error and its status apart, so a message GitHub gave is
# passed on and a call that gave none says its exit status. The answers are
# left in _bs_out, _bs_err, _bs_msg and _bs_rc; each reader below leaves its
# verdict in its own _bs_ variables, because a command substitution cannot hand
# a verdict back and each read is made once per run.

# [-i BODY] ARGS...: gh ARGS, with BODY on its standard input when given. gh's
# standard error goes to a file under TMPDIR, removed before this returns. A
# call that cannot keep that file is not made.
_felix_bs_gh() {
  local body="" has=0 ef
  if [ "${1:-}" = "-i" ]; then body="$2"; has=1; shift 2; fi
  _bs_out=""; _bs_err=""; _bs_msg=""; _bs_rc=1
  if ! command -v gh >/dev/null 2>&1; then _bs_msg="gh is not installed"; _bs_rc=127; return 127; fi
  ef="$(mktemp "${TMPDIR:-/tmp}/felix-bsgh.XXXXXX" 2>/dev/null)" || ef=""
  if [ -z "$ef" ]; then _bs_msg="no scratch file for gh's messages"; return 1; fi
  if [ "$has" -eq 1 ]; then
    _bs_out="$(gh "$@" 2>"$ef" <<<"$body")"; _bs_rc=$?
  else
    _bs_out="$(gh "$@" 2>"$ef" </dev/null)"; _bs_rc=$?
  fi
  _bs_err="$(cat "$ef" 2>/dev/null)"
  _bs_msg="$(LC_ALL=C awk 'NR == 1 { sub(/\r$/, ""); print; exit }' "$ef" 2>/dev/null)"
  rm -f "$ef"
  [ -n "$_bs_msg" ] || _bs_msg="exit $_bs_rc"
  return "$_bs_rc"
}

# The facts one JSON document holds at the places bootstrap reads, one per line:
#   d<TAB>V   the top-level default_branch, when it is a string
#   u<TAB>V   the top-level url, when it is a string
#   g<TAB>1   "gate" as an element of required_status_checks.contexts, or as the
#             context of an element of required_status_checks.checks
# Read by position, not by text, so a fork's parent.default_branch, a team
# named gate or a gate-lint check is not mistaken for the answer, and one line
# reads the same as many. Anything that is not an object holds no facts.
_felix_bs_json_facts() {
  LC_ALL=C awk '
    function cur(k) {
      if (kd[k] == "a") return (bp[k] == "" ? "#" : bp[k] "/#")
      return (bp[k] == "" ? ck[k] : bp[k] "/" ck[k])
    }
    function push(kind) {
      d++; kd[d] = kind; ck[d] = ""
      bp[d] = (d > 1 ? cur(d - 1) : "")
      ek = (kind == "o")
    }
    function value(s,   p) {
      if (d < 1 || kd[1] != "o") return
      p = cur(d)
      if (p == "default_branch" && !dset) { dv = s; dset = 1 }
      else if (p == "url" && !uset) { uv = s; uset = 1 }
      else if (s == "gate" && (p == "required_status_checks/contexts/#" || p == "required_status_checks/checks/#/context")) g = 1
    }
    {
      n = length($0); i = 1
      while (i <= n) {
        c = substr($0, i, 1)
        if (c == "\"") {
          s = ""; i++
          while (i <= n) {
            c = substr($0, i, 1)
            if (c == "\\") {
              c = substr($0, i + 1, 1); i += 2
              if (c == "\"" || c == "\\" || c == "/") s = s c; else s = s "\\" c
              continue
            }
            if (c == "\"") break
            s = s c; i++
          }
          i++
          if (d >= 1 && kd[d] == "o" && ek) { ck[d] = s; ek = 0 } else value(s)
          continue
        }
        if (c == "{") push("o")
        else if (c == "[") push("a")
        else if (c == "}" || c == "]") { if (d > 0) d--; ek = 0 }
        else if (c == ",") ek = (d >= 1 && kd[d] == "o")
        else if (c == ":") ek = 0
        i++
      }
    }
    END {
      if (dset) printf "d\t%s\n", dv
      if (uset) printf "u\t%s\n", uv
      if (g) printf "g\t1\n"
    }'
}

# The value of one fact of $1 (a document) named $2 (d, u or g), or nothing.
_felix_bs_fact() {
  printf '%s\n' "$1" | _felix_bs_json_facts | LC_ALL=C awk -F '\t' -v k="$2" '$1 == k { print substr($0, 3); exit }'
}

# SLUG: the repository's default branch, from the top-level default_branch of
# gh api repos/SLUG. Leaves it in _bs_d, empty when it could not be read, and
# says why in _bs_why. It goes into a request path, so a name with anything
# but the plain characters of one is not used.
_felix_bs_default_branch() {
  _bs_d=""; _bs_why=""
  if ! _felix_bs_gh api "repos/$1"; then _bs_why="$_bs_msg"; return 1; fi
  _bs_d="$(_felix_bs_fact "$_bs_out" d)"
  if [ -z "$_bs_d" ]; then _bs_why="gh's answer names no default_branch"; return 1; fi
  case "$_bs_d" in
    *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._/-]*)
      _bs_why="the default branch name has characters a request path should not carry"; _bs_d=""; return 1 ;;
  esac
}

# SLUG BRANCH: whether BRANCH requires the gate. _bs_pst is gate (it does), nogate
# (protected, and the gate is not among its required checks), none (GitHub says
# the branch is not protected) or unknown, with _bs_why.
_felix_bs_prot_read() {
  local u
  _bs_pst="unknown"; _bs_why=""
  if _felix_bs_gh api "repos/$1/branches/$2/protection"; then
    u="$(_felix_bs_fact "$_bs_out" u)"
    case "$u" in
      */protection) ;;
      *) _bs_why="gh's answer is not a branch protection"; return 1 ;;
    esac
    if [ -n "$(_felix_bs_fact "$_bs_out" g)" ]; then _bs_pst="gate"; else _bs_pst="nogate"; fi
    return 0
  fi
  if felix_contains "$_bs_out" "Branch not protected" || felix_contains "$_bs_err" "Branch not protected"; then
    _bs_pst="none"; return 0
  fi
  _bs_why="$_bs_msg"
  return 1
}

# SLUG: which of the five labels the repair loop applies are missing. _bs_lst is
# yes, no (_bs_lmiss names the missing ones) or unknown, with _bs_why. A list
# of a thousand lines may have been cut, so one that lacks a label is not read
# as lacking it.
_felix_bs_labels_read() {
  local r
  _bs_lst="unknown"; _bs_lmiss=""; _bs_why=""
  if ! _felix_bs_gh label list --repo "$1" --limit 1000; then _bs_why="$_bs_msg"; return 1; fi
  r="$(printf '%s\n' "$_bs_out" | LC_ALL=C awk '
    BEGIN { FS = "\t"; n = split("needs-founder needs-architecture risk-green risk-yellow risk-red", w, " ") }
    NF == 0 { next }
    { lines++; s = $1; sub(/\r$/, "", s); for (i = 1; i <= n; i++) if (s == w[i]) have[i] = 1 }
    END { m = ""; for (i = 1; i <= n; i++) if (!have[i]) m = m (m == "" ? "" : " ") w[i]
          printf "%d %s\n", lines, m }')"
  case "${r%% *}" in ''|*[!0123456789]*) _bs_why="gh's list could not be counted"; return 1 ;; esac
  _bs_lmiss="${r#* }"
  if [ -z "$_bs_lmiss" ]; then _bs_lst="yes"; return 0; fi
  if [ "${r%% *}" -ge 1000 ]; then _bs_why="a list of ${r%% *} labels may be cut short"; return 1; fi
  _bs_lst="no"
}

# NAME: the colour and description the label is created with, in _bs_lcol and
# _bs_ldesc. The repair loop and felix incident apply these five.
_felix_bs_label_spec() {
  case "$1" in
    needs-founder)      _bs_lcol=D93F0B; _bs_ldesc="Repair loop hit its ceiling; a human must diagnose" ;;
    needs-architecture) _bs_lcol=5319E7; _bs_ldesc="Failure is a design problem, not a patch" ;;
    risk-green)         _bs_lcol=0E8A16; _bs_ldesc="Reversible" ;;
    risk-yellow)        _bs_lcol=FBCA04; _bs_ldesc="Not obviously safe; look closely, then merge on green CI" ;;
    *)                  _bs_lcol=B60205; _bs_ldesc="Look hardest; an escape channel, not this label, stops a merge" ;;
  esac
}

# SLUG NAME: create one label, and say whether it was made. Returns 1 when not.
_felix_bs_label_create() {
  _felix_bs_label_spec "$2"
  if _felix_bs_gh label create "$2" --repo "$1" --color "$_bs_lcol" --description "$_bs_ldesc"; then
    printf '  created    label %s\n' "$2"
  else
    printf '  FAILED     label %s: %s\n' "$2" "$_bs_msg"; return 1
  fi
}

# SLUG BRANCH STATE: make BRANCH require the gate, and say whether it does. A
# branch GitHub says is unprotected gets the whole rule; enforce_admins stays
# false on purpose: locking the founder out of their own repository during an
# incident is not a safety property. A protected branch only gets the gate
# added to its required checks, so its other rules stay as they are.
_felix_bs_protect() {
  local rc
  if [ "$3" = "none" ]; then
    _felix_bs_gh -i '{"required_status_checks":{"strict":false,"contexts":["gate"]},"enforce_admins":false,"required_pull_request_reviews":null,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}' \
      api -X PUT "repos/$1/branches/$2/protection" --input -
  else
    _felix_bs_gh -i '{"contexts":["gate"]}' \
      api -X POST "repos/$1/branches/$2/protection/required_status_checks/contexts" --input -
  fi
  rc=$?
  if [ "$rc" -eq 0 ]; then printf '  protected  %s requires the gate\n' "$2"
  else printf '  FAILED     protection on %s: %s\n' "$2" "$_bs_msg"; fi
  return "$rc"
}

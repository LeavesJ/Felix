# Land on green: what the founder hears when the lander needs him, away from this Mac
# (docs/2026-10-24-audit-fixes/b05-lander-install-guard-and-off-mac-notifie.md, C018, B1-B11).
#
# A banner reaches Notification Center and nothing else. After a ledger row of an event kind is
# written and its banner sent, one attempt starts the repository's felix-alert workflow, which
# comments in one standing issue on the governed repository as github-actions[bot] and mentions the
# repository owner (or alert_login), so that the GitHub app on a phone hears it: GitHub sends no
# notification for your own actions, so a comment made as the owner's own login would not (section 9
# of the contract, R1: the founder's decision of 2026-10-26). The issue is created once, with a
# fixed title, and reused. One dispatch per new event, never a repeat of an unchanged one. Every
# attempt writes one row to alerts.tsv in the land directory, dispatched, no-alert-workflow or
# failed, and `felix status` reads that row and nothing else. The text sent is enumerated: the event
# kind, the pull request number, one fixed sentence per kind (R2). The ledger's free-text detail
# stays in alerts.tsv and never reaches a gh argument or a body.
#
# This file is shared code and a copy of it is the trampoline's. green-tick.sh sources it for the
# tick, and `felix land --install` writes its text into the installed trampoline, which sources
# nothing from the home or the plugin cache and runs no git (B11). So every function here is a
# function of its arguments and of: _FN_DIR (the land directory), _FN_REPO (OWNER/REPO, or empty),
# _FN_LSET and _FN_LOGIN (alert_login, when the project sets it), _FN_NOTE (why _FN_REPO is empty)
# and _FN_SECS (a test sets it). The tick's side, which reads the home, is in green-install.sh.
#
# Nothing here writes a ledger row, sends a banner, exits or returns non-zero: a post that fails is
# a record, never a fault in landing (B10). gh is called by name through PATH, with GH_HOST and
# GH_REPO taken out of its environment, and no call writes anything but the issue and the dispatch.

_fn_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Tabs and newlines would break the record's eight fields.
_fn_clean() { printf '%s' "${1:-}" | LC_ALL=C tr '\t\r\n' '   '; }
_fn_lc() { printf '%s' "${1:-}" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }

# Every $HOME/ written ~/, so a comment on a repository the world may read names no user directory.
_fn_tilde() {   # TEXT
  if [ -z "${HOME:-}" ] || [ "$HOME" = / ]; then printf '%s' "${1:-}"; return 0; fi
  printf '%s' "${1:-}" | LC_ALL=C awk 'BEGIN { h = ENVIRON["HOME"] "/"; n = length(h) }
    { s = $0; o = ""
      while ((i = index(s, h)) > 0) { o = o substr(s, 1, i - 1) "~/"; s = substr(s, i + n) }
      printf "%s%s", o, s }'
}

# 1-39 characters from letters, digits and hyphen, not starting with a hyphen: a GitHub login, and
# the OWNER of a GitHub origin.
_fn_login_ok() {   # TEXT
  local LC_ALL=C
  case "${1:-}" in ""|-*|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-]*) return 1 ;; esac
  [ "${#1}" -le 39 ]
}

# OWNER/REPO when URL is exactly https://github.com/OWNER/REPO, git@github.com:OWNER/REPO or
# ssh://git@github.com/OWNER/REPO, each optionally ending .git; status 1 for any other URL (a local
# path, another host, a user, a password, a port, a query, a trailing /). REPO is 1-100 characters
# from letters, digits, . _ and -, and is neither . nor ..
_fn_slug() {   # URL
  local u="${1:-}" r o n LC_ALL=C
  case "$u" in
    https://github.com/*)   r="${u#https://github.com/}" ;;
    ssh://git@github.com/*) r="${u#ssh://git@github.com/}" ;;
    git@github.com:*)       r="${u#git@github.com:}" ;;
    *) return 1 ;;
  esac
  r="${r%.git}"
  case "$r" in */*) ;; *) return 1 ;; esac
  o="${r%%/*}"; n="${r#*/}"
  case "$n" in */*) return 1 ;; esac
  _fn_login_ok "$o" || return 1
  case "$n" in ""|.|..|*[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-]*) return 1 ;; esac
  [ "${#n}" -le 100 ] || return 1
  printf '%s/%s' "$o" "$n"
}

# N when URL is https://github.com/REPO/issues/N, or N followed by #fragment, REPO compared without
# regard to case; status 1 for any other URL.
_fn_issue_n() {   # URL REPO
  local l p rest
  l="$(_fn_lc "${1:-}")"; p="https://github.com/$(_fn_lc "${2:-}")/issues/"
  case "$l" in "$p"*) ;; *) return 1 ;; esac
  rest="${l#"$p"}"; rest="${rest%%#*}"
  case "$rest" in ""|*[!0123456789]*) return 1 ;; esac
  printf '%s' "$rest"
}

# The repository to tell, from the land directory's alerts.repo (the trampoline's only source, B11,
# and a tick that resolved no project, B12). Its form is repo=OWNER/REPO or repo=none, then
# login=VALUE when the project sets alert_login. It never holds the origin URL's text.
_fn_from_file() {   # DIR
  local f l seen=0 v
  _FN_DIR="$1"; _FN_REPO=""; _FN_LSET=0; _FN_LOGIN=""; _FN_NOTE=""
  f="$1/alerts.repo"
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    _FN_NOTE="record: $f is absent or unreadable, so the repository to tell is not known: felix land --install writes it"
    return 0
  fi
  while IFS= read -r l || [ -n "$l" ]; do
    case "$l" in
      repo=*)  seen=1; v="${l#repo=}"
               if [ "$v" = none ]; then _FN_NOTE="origin: the home's origin is not a github.com repository URL"
               elif _fn_slug "https://github.com/$v" >/dev/null 2>&1; then _FN_REPO="$v"
               else _FN_NOTE="record: $f names no repository this notifier can read"; fi ;;
      login=*) _FN_LSET=1; _FN_LOGIN="${l#login=}" ;;
    esac
  done < "$f"
  [ "$seen" = 1 ] || _FN_NOTE="record: $f names no repository this notifier can read"
  return 0
}

# --- the record (B7) ---------------------------------------------------------
# Time, dispatched, no-alert-workflow or failed, kind, pull request, issue, run URL, note, detail:
# eight fields, any tab, CR or newline in one becoming a space. A record that cannot be appended
# changes nothing else. No record is ever removed or rewritten (R4).
_fn_rec() {   # STATE KIND PR ISSUE URL NOTE DETAIL
  local tab=$'\t' line
  line="$(_fn_now)$tab$(_fn_clean "$1")$tab$(_fn_clean "$2")$tab$(_fn_clean "$3")$tab$(_fn_clean "$4")$tab$(_fn_clean "$5")"
  line="$line$tab$(_fn_clean "$(_fn_tilde "$6")")$tab$(_fn_clean "$(_fn_tilde "$7")")"
  mkdir -p "$_FN_DIR" 2>/dev/null
  printf '%s\n' "$line" 2>/dev/null >> "$_FN_DIR/alerts.tsv" \
    || echo "felix land: the alert record could not be appended to $_FN_DIR/alerts.tsv" >&2
  return 0
}
_fn_fail() { _fn_rec failed "$_FN_K" "$_FN_P" "${_FN_I:--}" - "$1" "$_FN_D"; }

# B8. The event is the newest dispatched record's: same kind, pull request and detail. A failed or
# no-alert-workflow record never counts, so an event that was not sent is attempted again (R4).
_fn_same() {   # KIND PR DETAIL
  local f="$_FN_DIR/alerts.tsv" tab=$'\t' got
  [ -f "$f" ] || return 1
  got="$(LC_ALL=C awk -F'\t' 'NF == 8 && $2 == "dispatched" { r = $3 "\t" $4 "\t" $8 } END { print r }' "$f" 2>/dev/null)"
  [ -n "$got" ] && [ "$got" = "$1$tab$2$tab$3" ]
}

# R4. The failed and no-alert-workflow records after the newest dispatched one (all of them when
# there is none): their count, and the newest's kind and time.
_fn_missed() {
  [ -f "$_FN_DIR/alerts.tsv" ] || return 0
  LC_ALL=C awk -F'\t' 'NF != 8 { next } $2 == "dispatched" { n = 0; next }
    $2 == "failed" || $2 == "no-alert-workflow" { n++; k = $3; t = $1 }
    END { if (n) printf "%d\t%s\t%s\n", n, k, t }' "$_FN_DIR/alerts.tsv" 2>/dev/null
}

# --- one gh call (B3, B9) ----------------------------------------------------
_fn_secs() {   # -> the seconds a gh call may run: _FN_SECS when it is a positive whole number, else 30
  case "${_FN_SECS:-30}" in ""|0*|*[!0123456789]*) echo 30 ;; *) echo "${_FN_SECS:-30}" ;; esac
}

# gh with GH_HOST and GH_REPO taken out and prompts off, its standard input IN. Ended once it has
# run the limit's seconds: TERM, then KILL if it still runs two seconds later. Its pid is the
# subshell's own (exec), so what is signalled is gh. Answers in $_FN_T/NAME.out and NAME.err; the
# status in _FN_RC, T when it was ended. The braces carry the shell's own report of a killed job.
_fn_gh() {   # NAME IN ARGS...
  local name="$1" in="$2" pid n=0 k lim; shift 2
  lim=$(( $(_fn_secs) * 10 )); _FN_RC=1
  ( exec env -u GH_HOST -u GH_REPO GH_PROMPT_DISABLED=1 gh "$@" < "$in" > "$_FN_T/$name.out" 2> "$_FN_T/$name.err" ) 2>/dev/null &
  pid=$!
  {
    while kill -0 "$pid" 2>/dev/null; do
      if [ "$n" -ge "$lim" ]; then
        kill -TERM "$pid" 2>/dev/null; k=0
        while kill -0 "$pid" 2>/dev/null && [ "$k" -lt 20 ]; do sleep 0.1; k=$((k + 1)); done
        kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
        wait "$pid"; _FN_RC=T; break
      fi
      sleep 0.1; n=$((n + 1))
    done
    [ "$_FN_RC" = T ] || { wait "$pid"; _FN_RC=$?; }
  } 2>/dev/null
  return 0
}
_fn_why() {   # STEP NAME -> the note for a gh call that did not succeed: its status, or that it timed out
  local e
  if [ "$_FN_RC" = T ]; then printf '%s: timed out after %s seconds' "$1" "$(_fn_secs)"; return 0; fi
  e="$(LC_ALL=C sed -n 1p "$_FN_T/$2.err" 2>/dev/null | LC_ALL=C cut -c1-200)"
  printf '%s: exited %s' "$1" "$_FN_RC"
  [ -z "$e" ] || printf ': %s' "$e"
}

# --- the steps ---------------------------------------------------------------
_fn_step_user() {   # call 1: the account that will post
  _fn_gh user /dev/null api --hostname github.com user --jq .login
  [ "$_FN_RC" = 0 ] || { _fn_fail "$(_fn_why 'gh api user' user)"; return 1; }
  _FN_POSTER="$(LC_ALL=C sed -n 1p "$_FN_T/user.out" 2>/dev/null)"
  _fn_login_ok "$_FN_POSTER" || { _fn_fail "gh api user: answered no login this notifier can use"; return 1; }
}

# Call 2, and B4: never outside the governed repository. The name GitHub answers is the repository's
# (a rename, a transfer or a redirect makes it another), the account can write to it, and the
# mention names a person.
_fn_step_repo() {
  local fn="" ol="" ot="" pa="" pm="" pp=""
  _fn_gh repos /dev/null api --hostname github.com "repos/$_FN_REPO" --jq '(.full_name // ""), (.owner.login // ""), (.owner.type // ""), (.permissions.admin // false), (.permissions.maintain // false), (.permissions.push // false)'
  [ "$_FN_RC" = 0 ] || { _fn_fail "$(_fn_why 'gh api repos' repos)"; return 1; }
  { IFS= read -r fn; IFS= read -r ol; IFS= read -r ot; IFS= read -r pa; IFS= read -r pm; IFS= read -r pp; } < "$_FN_T/repos.out" 2>/dev/null
  [ -n "$fn" ] || { _fn_fail "gh api repos: answered no full_name"; return 1; }
  [ "$(_fn_lc "$fn")" = "$(_fn_lc "$_FN_REPO")" ] \
    || { _fn_fail "full_name: GitHub names $_FN_REPO $(_fn_clean "$fn"), not $_FN_REPO: it was renamed, transferred or redirected, so nothing is posted"; return 1; }
  [ "$pa" = true ] || [ "$pm" = true ] || [ "$pp" = true ] \
    || { _fn_fail "permission: $_FN_POSTER cannot write to $_FN_REPO (admin, maintain and push are not true), so nothing is posted there"; return 1; }
  if [ "$_FN_LSET" = 1 ]; then _FN_MENTION="$_FN_LOGIN"
  else
    [ "$ot" = User ] || { _fn_fail "owner: $_FN_REPO is owned by $(_fn_clean "${ot:-no one}"), not a user, and a mention of it notifies no one: set alert_login in the project's project.json to the login to tell"; return 1; }
    _fn_login_ok "$ol" || { _fn_fail "gh api repos: answered no owner login this notifier can use"; return 1; }
    _FN_MENTION="$ol"
  fi
}

# Call 3, and call 4 only when 3 finds none: the standing issue is the lowest-numbered issue titled
# exactly so and opened by the posting account, open or closed (B5). Its body names no one.
_fn_step_issue() {
  local sel url
  _fn_gh list /dev/null issue list --repo "github.com/$_FN_REPO" --state all --limit 1000 --json number,title,author --jq 'length, (.[] | select(.title == "Felix needs you") | "\(.number) \(.author.login // "-")")'
  [ "$_FN_RC" = 0 ] || { _fn_fail "$(_fn_why 'gh issue list' list)"; return 1; }
  sel="$(LC_ALL=C awk -v me="$(_fn_lc "$_FN_POSTER")" 'NR == 1 { if ($0 !~ /^[0123456789]+$/) bad = 1; next }
    { if (NF != 2 || $1 !~ /^[0123456789]+$/) { bad = 1; next }
      if (tolower($2) == me && (!f || $1 + 0 < m)) { f = 1; m = $1 + 0; s = $1 } }
    END { if (NR == 0 || bad) print "bad"; else if (f) print s }' "$_FN_T/list.out" 2>/dev/null)"
  [ "$sel" != bad ] || { _fn_fail "gh issue list: its answer cannot be read"; return 1; }
  if [ -z "$sel" ]; then
    printf '%s\n' "This is Felix's standing issue on this repository. The lander (felix land) starts the felix-alert workflow when" \
      "it needs the repository owner: a pull request it refused or landed, a deploy that stopped at a failed step or check, a job that is paused or" \
      "stopped. The workflow comments here, one comment per event. Felix does not edit, close, reopen, label or assign this issue." > "$_FN_T/create.in"
    _fn_gh create "$_FN_T/create.in" issue create --repo "github.com/$_FN_REPO" --title "Felix needs you" --body-file -
    [ "$_FN_RC" = 0 ] || { _fn_fail "$(_fn_why 'gh issue create' create)"; return 1; }
    url="$(LC_ALL=C awk 'NF { print $1; exit }' "$_FN_T/create.out" 2>/dev/null)"
    sel="$(_fn_issue_n "$url" "$_FN_REPO")" \
      || { _fn_fail "gh issue create: printed no https://github.com/$_FN_REPO/issues/N"; return 1; }
  fi
  _FN_N="$sel"; _FN_I="$_FN_REPO#$sel"
}

# R2. The one sentence for an event kind: fixed text, so no ledger detail ever reaches a body.
# Status 1 for a kind that has none, and a row of such a kind starts no attempt (wave-1-combine C5).
# waiting and unaged are wave-1-combine C3 and C4: nothing that waits stalls silent.
_fn_sentence() {   # KIND
  case "${1:-}" in
    landed)              printf '%s' 'A green pull request was merged into main.' ;;
    paused)              printf '%s' 'Landing is paused until felix land --resume.' ;;
    refused)             printf '%s' 'felix merge refused a green pull request.' ;;
    gh)                  printf '%s' 'gh auth status failed, so nothing lands.' ;;
    founder)             printf '%s' 'A green pull request changes a direction document and waits for your yes.' ;;
    deployed)            printf '%s' 'The engine on main was installed and passed its deploy checks.' ;;
    stuck)               printf '%s' 'A tick has held the lock for more than 45 minutes.' ;;
    deploy-failed|deployed-unverified) printf '%s' 'A deploy of main stopped at a failed step or check, and landing is paused.' ;;
    timeout)             printf '%s' 'A tick ran past its time limit and was stopped.' ;;
    unresolved)          printf '%s' 'The tick resolved no project, so nothing lands.' ;;
    fetch)               printf '%s' 'The home could not fetch its origin, so nothing lands.' ;;
    deploy-owed)         printf '%s' 'A deploy of main is owed and has not run, so nothing lands.' ;;
    unreadable)          printf '%s' 'The lander could not read the home, so nothing lands.' ;;
    waiting)             printf '%s' 'A green pull request has waited more than four hours to land.' ;;
    unaged)              printf '%s' 'A tick could not age what waits, so no waiting pull request is named.' ;;
    *) return 1 ;;
  esac
}

# The first https://github.com/REPO/actions/runs/N in the files given (REPO compared without regard to
# case), as the answer wrote it; nothing when there is none (R3).
_fn_run_url() {   # REPO FILE...
  local r="$1"; shift
  LC_ALL=C awk -v p="$(_fn_lc "https://github.com/$r/actions/runs/")" 'u == "" { for (i = 1; i <= NF; i++) {
      s = tolower($i)
      if (index(s, p) == 1 && substr(s, length(p) + 1) ~ /^[0123456789]+$/) { u = $i; break } } }
    END { if (u != "") print u }' "$@" 2>/dev/null
}

# Call 5 (R1-R4): start the felix-alert workflow, which comments in the standing issue as
# github-actions[bot]. BODY is line 1, the mention (the only @); an empty line; the kind's sentence;
# R4's count of what was not delivered, when there is one; and the details line (R2). The event's
# detail is in none of it. A started run is dispatched; a repository with no such workflow yet is
# no-alert-workflow, kept for the founder to see; anything else is failed. Never recorded as sent.
_fn_step_dispatch() {
  local l1 body sent miss mn mk mt url tab=$'\t' nl=$'\n'
  l1="@$_FN_MENTION Felix land: $_FN_K"
  case "$_FN_P" in ""|-|*[!0123456789]*) ;; *) l1="$l1 #$_FN_P" ;; esac
  sent="$(_fn_sentence "$_FN_K")"
  body="$l1$nl$nl$sent"
  miss="$(_fn_missed)"
  if [ -n "$miss" ]; then
    mn="${miss%%$tab*}"; mk="${miss#*$tab}"; mt="${mk#*$tab}"; mk="${mk%%$tab*}"
    body="$body${nl}Not delivered before this one: $mn (the newest: $(printf '%s' "$mk" | LC_ALL=C tr -d '@') at $(printf '%s' "$mt" | LC_ALL=C tr -d '@'))."
  fi
  body="$body${nl}details: felix land --status on the machine that runs the lander"
  _fn_gh dispatch /dev/null workflow run felix-alert.yml --repo "github.com/$_FN_REPO" -f "issue=$_FN_N" -f "body=$body"
  if [ "$_FN_RC" = 0 ]; then
    url="$(_fn_run_url "$_FN_REPO" "$_FN_T/dispatch.out" "$_FN_T/dispatch.err")"
    _fn_rec dispatched "$_FN_K" "$_FN_P" "$_FN_I" "${url:--}" "through felix-alert.yml mentioning @$_FN_MENTION" "$_FN_D"
  elif [ "$_FN_RC" != T ] && LC_ALL=C grep -qF 'could not find any workflows named felix-alert.yml' "$_FN_T/dispatch.err" 2>/dev/null; then
    _fn_rec no-alert-workflow "$_FN_K" "$_FN_P" "$_FN_I" - "gh workflow run: gh could not find any workflows named felix-alert.yml, so the alert was not sent: .github/workflows/felix-alert.yml is not on $_FN_REPO's default branch" "$_FN_D"
    return 1
  else
    _fn_fail "$(_fn_why 'gh workflow run' dispatch)"; return 1
  fi
}

# One attempt for one event: the kind, the pull request (or -) and the detail the banner shows (B1).
# A record at the end of alerts.tsv, unless the event is the newest dispatched one's (B8).
_fn_attempt() {   # KIND PR DETAIL
  [ -n "${_FN_DIR:-}" ] || return 0
  _FN_K="$(_fn_clean "${1:-}")"; _FN_P="$(_fn_clean "${2:--}")"; _FN_D="$(_fn_clean "$(_fn_tilde "${3:--}")")"; _FN_I=""
  _fn_same "$_FN_K" "$_FN_P" "$_FN_D" && return 0
  if [ -z "${_FN_REPO:-}" ]; then _fn_fail "${_FN_NOTE:-record: no repository is known}"; return 0; fi
  if [ "${_FN_LSET:-0}" = 1 ]; then
    _fn_login_ok "${_FN_LOGIN:-}" || { _fn_fail "alert_login: the project's alert_login is not a GitHub login (1-39 letters, digits or hyphens, not starting with a hyphen), so nothing is posted"; return 0; }
  fi
  # A defence only (wave-1-combine C5): _gt_say and the trampoline's owed() attempt no kind without a sentence.
  _fn_sentence "$_FN_K" >/dev/null \
    || { _fn_fail "kind: $_FN_K is not an event kind this notifier has a sentence for, so nothing is sent"; return 0; }
  _FN_T="$(mktemp -d "${TMPDIR:-/tmp}/felix-alert.XXXXXX" 2>/dev/null)" && [ -d "$_FN_T" ] \
    || { _FN_T=""; _fn_fail "gh: no temporary directory to keep the answers in, so nothing is posted"; return 0; }
  _fn_step_user && _fn_step_repo && _fn_step_issue && _fn_step_dispatch
  rm -rf "$_FN_T" 2>/dev/null; _FN_T=""
  return 0
}

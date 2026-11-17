# Human setup steps.
#
# Some things Felix cannot do and should not pretend to: creating a Sentry
# account, completing an OAuth consent screen, entering a payment method,
# holding a live API key. Those are not gaps in the harness, they are the
# boundary of what an agent should touch.
#
# The failure mode worth designing against is not "Felix cannot do it." It is
# "Felix cannot do it and nobody wrote down what to do instead," which is how a
# half-provisioned environment sits broken for a week because the one person who
# knew was not asked.
#
# So every human step is declared with a check that proves whether it is done.
# The list is derived, never hand-maintained: finish the step and it disappears
# on the next run. Same principle as capability detection, pointed at people.
#
# setup.tsv rows: id <TAB> title <TAB> capability <TAB> check-command

command -v felix_final_filter_lead >/dev/null 2>&1 \
  || . "$(dirname "${BASH_SOURCE[0]:-$0}")/final-filter.sh"

_felix_setup_rows() {
  local proj="$1"
  [ -f "$proj/setup.tsv" ] || return 0
  LC_ALL=C grep -vE '^\s*(#|$)' "$proj/setup.tsv"
}

# Each row led by `-`, or by the sentence refusing its check. The check runs
# in a `bash -c` without pipefail, so one a final filter makes unable to fail
# (final-filter.sh) reads done whatever it asked, and the step it guards
# disappears from the list for good. Such a check is not run: the row stays
# todo, which every reader that counts todo sees, felix_setup_malformed says
# why, and schema-check fails the gate on it.
_felix_setup_judged() {
  _felix_setup_rows "$1" | felix_final_filter_lead setup.tsv
}

# id <TAB> why, for every row whose check is refused, dormant or not.
felix_setup_malformed() {
  local ff id rest
  _felix_setup_judged "$1" | while IFS=$'\t' read -r ff id rest; do
    [ "$ff" != "-" ] && [ -n "${id:-}" ] && printf '%s\t%s\n' "$id" "$ff"
  done
  return 0
}

# {{REPO}} is filled in when a row is read, never when it is written (G5.1,
# U19).
#
# felix new and adopt used to splice the slug in as they wrote, and with no
# GitHub remote the slug is empty: the saved check read `gh label list --repo
# 2>/dev/null`, failed forever, and counted as a step to do, so commissioning's
# human_steps was held on every repository created before its remote, which is
# every repository `felix new` is run in first. Adding the remote later changed
# nothing, because adopt skips an id that exists. Now the file keeps the
# placeholder, and the remote the checkout has today decides what it reads.
#
# What that remote says is one of three things, kept apart because they owe
# different things:
#
#   slug    origin is GitHub and names one owner/name, which is filled in;
#   unread  origin is GitHub, or looks like it, and Felix cannot read one
#           owner/name from it; or no remote is named origin and another one
#           looks like GitHub;
#   none    no remote looks like GitHub at all, or there is no remote.
#
# Only `none` lets a row wait. The first cut read every remote it could not
# turn into owner/name as no remote at all, so an ssh host alias, ssh over port
# 443, a trailing slash, or a GitHub remote not named origin read "waits for a
# GitHub remote" in a repository that had one. The label and the CI secret then
# dropped out of human_steps' count, and commissioning released a step the
# person still owed: a silent false pass. An `unread` row is a step to do, and
# says why Felix cannot check it, so it holds and is seen. The engine before the
# first cut read those rows todo as well, held but unexplained.

# One remote URL -> `slug <owner/name>`, `host <host>` when the host looks like
# GitHub and is neither github.com nor an ssh alias for it, `path` when it is
# GitHub and the path is not one owner/name, and nothing when it is not GitHub.
#
# Parsed here rather than by felix_repo_slug, whose sed strips through the
# first `github.com[:/]` and so reads ssh://git@ssh.github.com:443/o/r as
# `443/o/r` and keeps a trailing slash. Its other readers are left as they are.
# The forms git takes are scheme://[user@]host[:port]/path, and scp-like
# [user@]host:path with no slash before the colon; anything else is a local
# path. Trailing slashes and a final .git are spelling, not the name.
#
# github.com, www.github.com and ssh.github.com are GitHub. Any other host in
# an ssh form may be an alias from the person's ssh config, the usual way to
# keep two GitHub accounts' keys apart, and `ssh -G` says what it stands for: it
# prints the configuration ssh would use, reads only local files, and connects
# to nothing. CanonicalizeHostname is turned off on its command line, which wins
# over the config file, because canonicalising is a DNS lookup. A Match exec
# line in that config does run, as it does on every fetch the person makes.
# Without ssh, the alias is read as written.
#
# The host has to be a plain hostname before ssh is handed it, so a remote
# cannot pass an option; and the owner/name is spliced into a command bash
# runs, so it is accepted only in the shape a GitHub owner/name has. A remote
# carrying shell text is `path`, and nothing from it runs. A host that is still
# not GitHub but has "github" in its name (an alias ssh could not resolve, a
# GitHub Enterprise server) is `host`: probably owed, and not something
# `--repo owner/name` on github.com would check.
_felix_setup_classify() {
  local u="$1" rest host path ssh=0 lh real="" LC_ALL=C
  while :; do case "$u" in */) u="${u%/}" ;; *) break ;; esac; done
  u="${u%.git}"
  case "$u" in
    *://*)
      case "$u" in ssh://*|git+ssh://*|ssh+git://*) ssh=1 ;; esac
      rest="${u#*://}"
      host="${rest%%/*}"
      case "$rest" in */*) path="${rest#*/}" ;; *) path="" ;; esac
      host="${host##*@}"; host="${host%%:*}" ;;
    *:*)
      host="${u%%:*}"
      case "$host" in */*) return 0 ;; esac
      ssh=1; path="${u#*:}"; host="${host##*@}" ;;
    *) return 0 ;;
  esac
  while :; do case "$path" in /*) path="${path#/}" ;; *) break ;; esac; done
  case "$host" in ''|-*|*[!A-Za-z0-9._-]*) return 0 ;; esac
  lh="$(printf '%s' "$host" | LC_ALL=C tr 'A-Z' 'a-z')"
  case "$lh" in
    github.com|www.github.com|ssh.github.com) ;;
    *)
      # awk reads all of ssh's output rather than exiting on the first match,
      # so ssh is never killed mid-write: under pipefail a SIGPIPE'd producer
      # turns the whole pipeline's status to 141.
      if [ "$ssh" -eq 1 ] && command -v ssh >/dev/null 2>&1; then
        real="$(ssh -G -o CanonicalizeHostname=no "$host" </dev/null 2>/dev/null \
                | LC_ALL=C awk '$1 == "hostname" && !s { print $2; s = 1 }' | LC_ALL=C tr 'A-Z' 'a-z')" || real=""
      fi
      case "$real" in
        github.com|www.github.com|ssh.github.com) ;;
        *)
          case "$lh $real" in *github*) printf 'host %s' "$host" ;; esac
          return 0 ;;
      esac ;;
  esac
  case "$path" in
    ''|-*|.*|*/-*|*/|*/*/*|*[!A-Za-z0-9._/-]*|*/.|*/..) printf 'path' ;;
    ?*/?*) printf 'slug %s' "$path" ;;
    *) printf 'path' ;;
  esac
  return 0
}

# The checkout's remote, as the status and the runbook read it: one line,
# `slug <owner/name>`, `unread <why>`, or `none`. Only origin gives a slug,
# because origin is the remote every other part of Felix reads. With no origin,
# a remote under another name that looks like GitHub makes it `unread`, since a
# repository with one owes its GitHub steps, and naming it origin is what lets
# Felix check them.
_felix_setup_remote() {
  local root="${1:-$PWD}" u c n
  u="$(git -C "$root" remote get-url origin 2>/dev/null)" || u=""
  if [ -n "$u" ]; then
    c="$(_felix_setup_classify "$u")"
    case "$c" in
      'slug '*) printf '%s\n' "$c" ;;
      'host '*) printf "unread origin's host %s is not github.com, nor an ssh alias for it\n" "${c#host }" ;;
      path)     printf 'unread origin points at GitHub, but not at one owner/name Felix can read\n' ;;
      *)        printf 'none\n' ;;
    esac
    return 0
  fi
  for n in $(git -C "$root" remote 2>/dev/null); do
    u="$(git -C "$root" remote get-url "$n" 2>/dev/null)" || continue
    if [ -n "$(_felix_setup_classify "$u")" ]; then
      printf 'unread no remote is named origin, the one Felix reads, though another points at GitHub\n'
      return 0
    fi
  done
  printf 'none\n'
}

# Rows and runbooks an older felix new saved with an empty slug are read as if
# they held {{REPO}}: `--repo`, blanks, and then nothing a slug could be (the
# end, another flag, a pipe, a separator, a backtick or a redirection) gets
# the placeholder put back. Only the text in hand changes, never the file.
# `--repo {{REPO}}` and `--repo owner/name` do not match and are left alone.
_felix_setup_norm() {
  LC_ALL=C sed -E 's/--repo([[:space:]]+)(--|[0-9]*[<>]|[|;&`]|$)/--repo {{REPO}}\1\2/g'
}

# done | todo | dormant | unknown, one row each: status <TAB> id <TAB> title,
# and a fourth field only for a row the remote decides: why it waits, or why
# Felix cannot check it.
#
# Until 2026-10-01 this asked _felix_cap_active with `!`, so a declared list
# that could not be read (status 2) printed `dormant`: a step that still needs
# a person, said to be not needed yet. A list nobody read is its own word,
# `unknown`, and its check is not run, as an `unchecked` maintenance row's is
# not: nothing here can say a step is done or todo on a capability it could
# not look up.
#
# A row whose check needs the slug reads, by the remote: with a slug, its check
# run with the slug filled in; `unread`, todo with the reason and its check not
# run, so it holds human_steps and says why; `none`, dormant with `waits for a
# GitHub remote` and its check not run, because it is not a step a person can
# take yet. Once origin points at GitHub the same saved row reads todo or done.
# The remote is asked only when a row could need it, since reading it can run
# ssh. A row whose check is refused (_felix_setup_judged) reads todo before the
# remote is weighed, whatever the remote says: its check is malformed on any
# checkout, so it holds rather than waits.
#
# ROOT is the checkout, defaulting to the one the working directory is in: the
# human_steps row calls this with the project alone, from inside the checkout.
felix_setup_status() {
  local proj="$1" root="${2:-}" rem="none" slug="" why="" rc
  [ -n "$root" ] || root="$(felix_repo_root "$PWD")"
  if [ -f "$proj/setup.tsv" ] && LC_ALL=C grep -qF -e '--repo' -e '{{REPO}}' "$proj/setup.tsv" 2>/dev/null; then
    rem="$(_felix_setup_remote "$root")"
  fi
  case "$rem" in
    'slug '*)   slug="${rem#slug }" ;;
    'unread '*) why="${rem#unread }" ;;
  esac
  _felix_setup_judged "$proj" | while IFS=$'\t' read -r ff id title cap check; do
    [ -n "${id:-}" ] || continue
    _felix_cap_active "${cap:-always}" "$proj"; rc=$?
    case "$rc" in
      0) ;;
      1) printf 'dormant\t%s\t%s\n' "$id" "$title"; continue ;;
      *) printf 'unknown\t%s\t%s\n' "$id" "$title"; continue ;;
    esac
    if [ "$ff" != "-" ]; then
      printf 'todo\t%s\t%s\n' "$id" "$title"
      continue
    fi
    case "${check:-}" in *--repo*) check="$(printf '%s\n' "$check" | _felix_setup_norm)" ;; esac
    case "${check:-}" in
      *'{{REPO}}'*)
        if [ -n "$why" ]; then
          printf 'todo\t%s\t%s\t%s, so Felix cannot check it\n' "$id" "$title" "$why"
          continue
        elif [ -z "$slug" ]; then
          printf 'dormant\t%s\t%s\twaits for a GitHub remote\n' "$id" "$title"
          continue
        fi
        check="${check//\{\{REPO\}\}/$slug}" ;;
    esac
    if [ -n "${check:-}" ] && bash -c "$check" </dev/null >/dev/null 2>&1; then
      printf 'done\t%s\t%s\n' "$id" "$title"
    else
      printf 'todo\t%s\t%s\n' "$id" "$title"
    fi
  done
}

# The runbook, with {{REPO}} filled in the same way the check is. Without a
# slug the placeholder is left as written and the first line says why, so
# nobody pastes a command that names no repository.
#
# Read once, normalised, into a variable, and asked with `case`. The first cut
# asked with `_felix_setup_norm < f | grep -qF`, the producer-into-`grep -q`
# shape resolve.sh already warns of: grep exits on its first match, sed takes a
# SIGPIPE on its next write, and under the CLI's pipefail the pipeline reads
# false. A runbook a person had added to, past the pipe's buffer, then printed
# raw, `--repo  --color` and no preface: a pasteable command naming no
# repository, the thing the preface is there to stop. The `x` keeps a final
# newline the substitution would strip. The slug is put in by sed, which reads
# all of its input, and not by `${t//...}`, which bash does slowly on a long
# string.
felix_setup_runbook() {
  local proj="$1" id="$2" root="${3:-}" f t rem slug
  f="$proj/setup/$id.md"
  if [ ! -f "$f" ]; then
    printf 'No runbook written for "%s" yet.\n' "$id"
    printf 'Add one at %s/setup/%s.md\n' "$proj" "$id"
    return 1
  fi
  t="$(_felix_setup_norm < "$f"; printf x)"; t="${t%x}"
  case "$t" in
    *'{{REPO}}'*) ;;
    *) cat "$f"; return $? ;;
  esac
  [ -n "$root" ] || root="$(felix_repo_root "$PWD")"
  rem="$(_felix_setup_remote "$root")"
  case "$rem" in
    'slug '*)
      slug="${rem#slug }"
      printf '%s' "$t" | sed "s|{{REPO}}|$slug|g" ;;
    'unread '*)
      printf '{{REPO}} below is left as written, because %s: put the repository'"'"'s owner/name in its place.\n' "${rem#unread }"
      printf '%s' "$t" ;;
    *)
      printf 'No GitHub remote yet, so {{REPO}} below is left as written; it fills in once origin points at GitHub.\n'
      printf '%s' "$t" ;;
  esac
}

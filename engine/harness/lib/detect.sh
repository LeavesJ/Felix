# Capability detection.
#
# The guidebook's later phases assume surfaces a young project does not have
# yet: no deploy target, so no preview environments; no Sentry, so no incident
# loop; no Stripe, so no billing gate. Declaring those permanently out of scope
# is wrong, because the day a Dockerfile lands the deploy phase becomes real and
# nobody is watching for it.
#
# So Felix probes for the surface instead of asking. Each probe answers one
# question: does evidence of this capability exist in the checkout right now.
#
# Detection reports. It never enables. A gate that switched itself on would
# block a pull request for a reason no one chose, and the whole doctrine here is
# that a gate's meaning has to be deliberate. `felix doctor` shows the drift;
# adopting it is a decision someone makes.

# Search the dependency manifests of any ecosystem for a token.
_felix_dep_grep() {
  local root="$1" pat="$2" f
  # The globs are quoted here so they reach the inner loop whole and expand
  # against the root there. Bare, they expanded against the current directory
  # first: run from a folder holding requirements/dev.txt, f became that name,
  # the root's requirements/prod.txt was never read, and every probe below
  # missed what it named.
  for f in pyproject.toml requirements.txt 'requirements/*.txt' setup.cfg Pipfile \
           package.json Cargo.toml go.mod Gemfile composer.json build.gradle \
           pom.xml '*.csproj'; do
    # The root is quoted and the pattern is not. An unquoted root splits on
    # IFS, so a checkout whose path holds a space matched nothing at all.
    # shellcheck disable=SC2086
    for m in "$root"/$f; do
      [ -f "$m" ] || continue
      LC_ALL=C grep -qiE "$pat" "$m" && return 0
    done
  done
  return 1
}

# A web surface exists whether or not npm was ever run there. Counted from
# tracked files so a vendored dependency tree cannot manufacture a frontend.
#
# Documentation and presentations are not a frontend (wave-2-docs.md F1): a
# file is not counted when a whole directory name in its path, in any case, is
# docs, doc, documentation, deck, decks or slides. On 2026-10-28 a pitch deck's
# CSS made three with two files under docs/, and session start adopted frontend
# into the home's own tables, which staled the commission. Both listings are
# relative to the root (the fallback runs find from inside it), so only the
# components below the root are judged, and a file's own name never is.
_felix_frontend_assets() {
  local root="$1" n
  n="$( { git -C "$root" ls-files 2>/dev/null \
          || ( CDPATH='' cd -- "$root" 2>/dev/null && find . -type f 2>/dev/null ); } \
        | LC_ALL=C grep -ivE '(^|/)(docs?|documentation|decks?|slides)/' \
        | LC_ALL=C grep -icE '\.(jsx?|tsx?|vue|svelte|s[ac]ss|css)$' )"
  [ "${n:-0}" -ge "${FELIX_FRONTEND_MIN:-3}" ]
}

_felix_any() {
  local root="$1"; shift
  local p
  for p in "$@"; do
    # Quoted root, bare pattern, as in _felix_dep_grep.
    # shellcheck disable=SC2086
    for m in "$root"/$p; do
      [ -e "$m" ] && return 0
    done
  done
  return 1
}

# Print one capability name per line for everything the checkout shows evidence of.
felix_detect() {
  local root="${1:-$PWD}"

  _felix_any "$root" ".github/workflows/*.yml" ".github/workflows/*.yaml" \
                     ".gitlab-ci.yml" "azure-pipelines.yml" && echo ci

  _felix_any "$root" "Dockerfile" "Dockerfile.*" "docker-compose.yml" "Procfile" \
                     "fly.toml" "vercel.json" "render.yaml" "railway.json" \
                     "app.yaml" "k8s" "kubernetes" "helm" && echo deploy

  _felix_any "$root" "*.tf" "terraform" "infra/*.tf" "pulumi.yaml" && echo iac

  _felix_dep_grep "$root" "sentry|opentelemetry|datadog" && echo observability
  _felix_dep_grep "$root" "\"?stripe\"?" && echo billing
  _felix_dep_grep "$root" "playwright|cypress|selenium|puppeteer" && echo e2e
  _felix_dep_grep "$root" "supabase|prisma|alembic|sqlalchemy|drizzle|typeorm" && echo database
  _felix_dep_grep "$root" "fastapi|flask|django|express|next|fastify|starlette" && echo api

  _felix_any "$root" "migrations" "supabase/migrations" "alembic.ini" \
                     "prisma/schema.prisma" && echo database

  # An application built on a model SDK is a different kind of thing from an
  # application that happens to call an API, and none of the probes above can
  # tell. Prompts get pinned, outputs get graded, cost and refusal are failure
  # modes — none of which the ordinary api/tests capabilities imply.
  _felix_dep_grep "$root" \
    "anthropic|openai|langchain|llama-?index|mistralai|cohere|ollama|google-generativeai|litellm|instructor|dspy|transformers" \
    && echo llm

  _felix_any "$root" "Cargo.toml" && echo rust

  # `package.json` alone was the entire frontend test, which misses every web
  # surface served by a backend: a Python app with templates and a static
  # directory has a frontend by any definition a designer would recognise, and
  # Felix called it a backend because npm had never been run there.
  _felix_any "$root" "package.json" && echo frontend
  _felix_frontend_assets "$root" && echo frontend

  _felix_any "$root" "tests" "test" "spec" "__tests__" && echo tests

  _felix_any "$root" ".env.example" ".env.sample" && echo secrets
}

# Capabilities a project has declared it knows about, one per line.
#
# 0 when there is no file or it was read, whether or not it holds a
# capability line, and 2 when something is there and could not be read as a
# list. Only nothing at all is absent: a link whose target is gone, a
# directory or a pipe is something there that is not a list, and is 2 without
# being opened (a pipe must not be opened at all, since a reader would wait on
# it for a writer).
#
# 2026-10-08: until then it read with grep -vE '^\s*(#|$)' in the caller's
# locale, which treated a file that is not text as a list. A NUL made BSD grep
# print "Binary file <path> matches" as the one capability (measured), and by
# GNU grep's manual (not run) stop printing at the first NUL with 0 and, under
# a UTF-8 locale, drop each line holding a byte that is not valid UTF-8; BSD
# grep reads such a byte as text. A byte-order mark before a comment listed the
# comment, a line of only a no-break space was listed in the C locale and
# dropped in UTF-8, and a CR made every name one no table holds. Now a NUL
# anywhere is no list (as #383 refused a qualification.tsv holding one), the
# file is read byte for byte in the C locale, a leading UTF-8 byte-order mark
# is dropped, and a listed line holding a byte outside tab and printable ASCII
# makes the whole file no list, the way qualify calls a row with a CR
# malformed. A file that is no list is 2 with nothing printed.
# It reads with cat into a subshell, not a redirect or a second grep, so that
# the file is opened once by a named command whose status says a read failed
# (the read builtin returns a read error as end of input). The C locale is set
# inside the subshell because bash 4 to 5.2 in a UTF-8 locale reads the byte
# after a UTF-8 lead byte as part of a character without asking whether it is
# the delimiter, so a NUL right after one hid from read -d '' (#383's review);
# the subshell keeps the locale, IFS and set -f its own, and its stderr is
# discarded as grep's was. A caller whose LC_ALL is readonly and not C gets 2
# and no message: bash 3.2 abandons the subshell at the assignment, and the
# second test refuses where a shell would carry on in the caller's locale.
# cat is `command cat`, so no function of that name stands in. The lines are
# judged by two regular expressions, each tried on known input first, since
# one that cannot be compiled returns 2 and `&&` would read that as no match.
# The cost is one process more per call than the grep it replaced, a cat and a
# subshell, measured, and linear in the file: the mark is cut by offset, the
# names kept in an array and each line matched once, because `${x#mark}`,
# string appends, `${x//tab/ }` and stripping leading space by pattern grew
# with the square of a file or a line (5.7 s for 670 KB, 17 s for one line of
# 10,000 tabs; found by review).
felix_declared() {
  local proj="$1" st
  # Declared as the locale rules above felix_json_str in resolve.sh ask of every
  # function holding a [[ =~ ]]. A readonly LC_ALL refuses it, silently here,
  # and the subshell's own test below then returns 2.
  local LC_ALL=C 2>/dev/null
  [ -e "$proj/capabilities" ] || [ -L "$proj/capabilities" ] || return 0
  [ -f "$proj/capabilities" ] || return 2
  command cat -- "$proj/capabilities" 2>/dev/null | (
    [ "${LC_ALL-}" = C ] || LC_ALL=C
    [ "${LC_ALL-}" = C ] || exit 6
    IFS= read -r -d '' _fdb && exit 3
    case "$_fdb" in $'\357\273\277'*) _fdb="${_fdb:3}" ;; esac
    _fdskip='^[[:space:]]*(#|$)' _fdbad=$'[^\t[:print:]]'
    [[ '' =~ $_fdskip ]] && [[ $'\001' =~ $_fdbad ]] && ! [[ $'a\t~' =~ $_fdbad ]] || exit 5
    _fdk=(); IFS=$'\n'; set -f; set -- $_fdb
    for _fdl; do
      [[ $_fdl =~ $_fdskip ]] && continue
      [[ $_fdl =~ $_fdbad ]] && exit 4
      _fdk[${#_fdk[@]}]="$_fdl"
    done
    [ "${#_fdk[@]}" -eq 0 ] || printf '%s\n' "${_fdk[@]}" ) 2>/dev/null
  st="${PIPESTATUS[0]}:${PIPESTATUS[1]}"
  [ "$st" = 0:0 ] || return 2
}

# NAME CMD [ARGS...]: run CMD in one command substitution and assign its output
# to the variable named NAME, minus one trailing newline, only when CMD returned
# 0 and the substitution ran to its end. 0 when it did, the empty string being
# output too, and 2 when it did not, with NAME left as the caller had it. The
# status of CMD is not enough, because a substitution can end with nothing
# printed and status 0 when its fork fails (EAGAIN) or, on bash 3.2, when it
# cannot make its pipe, so a newline and a `.` are printed only after CMD
# returned 0, and output that does not end in them was never whole.
#
# Every status but 0 reads as not whole, so a command captured here returns 0
# only when what it printed is whole. The sentinel is forged by a last line that
# is exactly `.`, printed by a command that then failed, and by nothing else.
# Until 2026-10-01 it was a bare `.`, which a failed felix_declared forged with a
# last line ending in a dot (`billing.`). No locals, because a local of the name
# the caller passed would take the assignment printf -v makes and the caller's
# variable would never see it, and no variable of its own, because a global would
# not hide a caller's variable of the same name but overwrite it (lib/commission.sh
# felix_commission_ask has no locals either, for the first reason only):
# everything is held in the positional parameters. The newlines are stripped
# with a literal one in the pattern, which is the same in bash 3.2 and 5.
felix_capture() {
  set -- "$1" "$(shift; "$@" && printf '\n.')"
  case "$2" in *"
.") ;; *) return 2 ;; esac
  set -- "$1" "${2%"
."}"
  set -- "$1" "${2%"
"}"
  printf -v "$1" '%s' "$2"
  return 0
}

# The declared list read into the variable named $1, one capability per line
# with no trailing newline, and whether it was read. 0 when it was, the empty
# string being a list too (no file, or one that declares nothing), and 2 when it
# was not, with the variable left as the caller had it.
#
# Until 2026-10-01 each reader of the list but _felix_cap_active ran
# `$(felix_declared ...)` and took what came back as the list, so a list that
# could not be read was an empty one and every reader made a claim from it: a
# capability not declared, drift to adopt, an orphan, a gap that was not one, a
# topology that was not the project's. Now they read here and branch on the
# status, and felix_capture says whether the substitution came back whole.
felix_declared_into() {
  felix_capture "$1" felix_declared "$2"
}

# The capabilities this checkout shows and the project declares, one to a line,
# sorted and without repeats: ROOT and LIST, which is the declared list as
# felix_declared_into read it. 0 when the pipeline that made it ran whole, and
# nonzero when either half of it did not, a sort that could not run being as much
# a union that was not made as a list that could not be read. Captured by
# felix_capture, which is what makes the status mean something. Until 2026-10-01
# each caller made this union itself, in a group piped to sort whose status
# nobody asked, so a sort that could not run was a list with nothing in it.
#
# The declared half is printed first, so a felix_detect that exits inside the
# group cannot take it along. The group ends in `:` because felix_detect's own
# status is its last test's, 1 for a checkout with no .env.example, and says
# nothing about whether it ran. A fork that fails inside the group (felix_detect's
# EAGAIN) is another thing: on bash 3.2 it kills the group's subshell with 128, so
# the pipeline's status is nonzero, the union is not made, and its readers say the
# declared list could not be read, the one sentence they have for it. (Until
# 2026-10-08 this said that failure reads as nothing detected, as it did; here it
# does not.) The statuses are taken whole into the positional parameters, which
# pipefail does not change and the first test would reset.
_felix_capability_union() {
  { [ -z "$2" ] || printf '%s\n' "$2"; felix_detect "$1" 2>/dev/null; :; } | LC_ALL=C sort -u
  set -- "${PIPESTATUS[@]}"
  [ "${1:-1}" -eq 0 ] && [ "${2:-1}" -eq 0 ]
}

# Present in the checkout but never declared. This is the drift worth surfacing.
#
# 0 with the surfaces on stdout, and 2 with nothing printed when the declared
# list could not be read. Until 2026-10-01 an unread list subtracted nothing, so
# every detected surface was undeclared drift and session start adopted each one,
# capabilities that may already have been declared. The list is read once, in
# this shell, before the pipeline, and what it holds is skipped by a case, the
# way _felix_cap_active asks, where felix_has_line's here-document is a
# temporary file on bash 3.2. A process substitution would hand a loop an empty
# file when its fork failed, so there is none. The detected half, `felix_detect |
# sort -u`, is the felix_detect lookup, left as it was: a sort that fails there
# reads as less drift, unlike in _felix_capability_union, where a sort that could
# not run is a union that was not made.
felix_undeclared() {
  local root="$1" proj="$2" declared nl=$'\n' cap
  felix_declared_into declared "$proj" || return 2
  felix_detect "$root" | LC_ALL=C sort -u | while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    case "$nl$declared$nl" in *"$nl$cap$nl"*) ;; *) printf '%s\n' "$cap" ;; esac
  done
  return 0
}

# Best guess at the command that proves this project correct. A guess, printed
# for a human to confirm, never silently trusted: a wrong gate that exits 0 is
# the one failure mode worse than having no gate.
felix_guess_gate() {
  local root="${1:-$PWD}"
  if [ -f "$root/package.json" ]; then
    LC_ALL=C grep -q '"verify"' "$root/package.json" && { echo "npm run verify"; return; }
    LC_ALL=C grep -q '"test"'   "$root/package.json" && { echo "npm test"; return; }
  fi
  [ -f "$root/Makefile" ] && LC_ALL=C grep -qE '^(check|verify):' "$root/Makefile" \
    && { echo "make check"; return; }
  [ -f "$root/Cargo.toml" ] && { echo "cargo test"; return; }
  [ -f "$root/go.mod" ]     && { echo "go test ./..."; return; }
  [ -f "$root/pyproject.toml" ] || [ -f "$root/setup.cfg" ] \
    && { echo "python -m pytest -q"; return; }
  echo ""
}

# Scripts in the checkout that look like a gate and are not the gate this
# project declares.
#
# From a real failure. An untracked, day-stale, strictly weaker copy of a gate
# sat inside a governed repo, and it was the file physically in front of any
# session that looked around. A session ran it all day and reported green from a
# gate missing a check. It found out only because the completion gate nagged it
# into running the real one.
#
# A gate with a lookalike is not a gate. It is a coin flip on which file
# somebody reaches for, and the wrong side of the flip reports success — the
# same silent shape as a check that passes by finding nothing.
#
# Deliberately narrow. Executable only, because a broad match flags every note
# with the word in its name. Reports and never deletes: a rival can be
# legitimate, a fast subset a person runs by hand, and Felix does not get to
# decide that.
_felix_rival_gates() {
  local root="$1" proj="$2" gate="$3" state f base note
  { git -C "$root" ls-files            2>/dev/null | sed 's/^/tracked\t/'
    git -C "$root" ls-files --others --exclude-standard 2>/dev/null \
      | sed 's/^/untracked\t/'
  } | while IFS=$'\t' read -r state f; do
      [ -n "${f:-}" ] || continue
      base="${f##*/}"
      # Two ways a file here is a lookalike. Its name says it gates something,
      # or Felix already holds the authoritative copy under that exact name.
      #
      # The second is the real rule and was learned the day the first one was
      # not enough: deleting the stale scripts/gate.sh left scripts/prepush.sh
      # sitting beside it, an untracked copy of a file Felix holds, identical
      # that morning and free to drift by the afternoon. Matching on the word
      # "gate" could never have seen it. The name was never the point.
      held=0; [ -f "$proj/$base" ] && held=1
      if [ "$held" -eq 0 ]; then
        case "$base" in *gate*|*verify*|*check*) ;; *) continue ;; esac
      fi
      [ -x "$root/$f" ] || continue

      # The declared gate itself, when the project stores it in Felix's home and
      # the home happens to be this checkout. Same file, not a rival.
      [ "$root/$f" -ef "$proj/$gate" ] 2>/dev/null && continue

      # Felix's own per-project storage holds every governed project's gate. In
      # any checkout that IS Felix, those are its records, not rivals.
      #
      # Tested on the repository, not on the path. This was a prefix match
      # against $FELIX_HOME_DIR, which is true only when standing in the home
      # itself: from a worktree of Felix the root is elsewhere, the prefix never
      # matched, and doctor reported every governed project's stored gate as a
      # rival — then called one of them "differs from the copy Felix holds",
      # having compared it against another project's file on a shared basename.
      case "$f" in
        projects/*) felix_same_repo "$root" "${FELIX_HOME_DIR:-/nonexistent}" && continue ;;
      esac

      # A project may declare a repo-relative command as its gate. That path is
      # the gate, so naming it here would report the gate as its own rival.
      case " $gate " in *"$f"*) continue ;; esac

      # Compared against whichever copy Felix actually holds: the file of the
      # same name when there is one, otherwise the declared gate.
      local mine=""
      [ "$held" -eq 1 ] && mine="$proj/$base"
      [ -z "$mine" ] && [ -x "$proj/$gate" ] && mine="$proj/$gate"

      if [ -n "$mine" ]; then
        if cmp -s "$root/$f" "$mine"; then
          note="identical today, and nothing keeps it that way"
        else
          note="differs from the copy Felix holds"
        fi
      else
        note="this project gates with a command, not a file"
      fi
      printf '%s\t%s\t%s\n' "$state" "$f" "$note"
    done
}

# owner/name for a GitHub checkout, empty otherwise.
felix_repo_slug() {
  (cd "${1:-$PWD}" 2>/dev/null && git remote get-url origin 2>/dev/null) \
    | sed -E 's#.*github\.com[:/]##; s#\.git$##'
}

# What felix new writes as remote_match, and the checks it makes before it binds (audit b13, C116, C117).
#
# remote_match is the value a checkout is found by (a substring of its origin, felix_resolve_project)
# and the one lib/own.sh compares to say a checkout is the project's own. It lands in a tracked
# project.json, so it must never carry what an origin URL can: a token as userinfo. A GitHub origin
# is owner/repo as ever (felix_repo_slug). Any other origin drops everything through its last @,
# or its scheme when it has no @, then one trailing / and one trailing .git, so the value is still
# a substring of the URL and the checkout still resolves by it. Not for the other readers of
# felix_repo_slug (felix pr, bootstrap, setup), which can still pass such a URL whole.
felix_new_rm_of() {   # URL -> the value felix new writes for it; a value it wrote comes back unchanged
  local u="$1" s lc=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-
  case "$u" in
    *github.com/*|*github.com:*) printf '%s\n' "$u" | sed -E 's#.*github\.com[:/]##; s#\.git$##'; return 0 ;;
    *@*) u="${u##*@}" ;;
    *://*) s="${u%%://*}"; case "$s" in ''|*[!$lc]*) ;; *) u="${u#*://}" ;; esac ;;
  esac
  u="${u%/}"; printf '%s' "${u%.git}"
}
felix_new_remote_match() {   # ROOT -> the value, or nothing without an origin
  local u
  u="$(cd "${1:-$PWD}" 2>/dev/null && git remote get-url origin 2>/dev/null)"
  [ -n "$u" ] || return 0
  felix_new_rm_of "$u"
}

# Does a project already govern the git root felix new would bind? A .felix there naming a project
# that exists, or with no .felix an origin naming the same repository as some project's remote_match:
# the two values compared as felix new writes them (felix_new_rm_of), not by containment, so Widget-api
# is not Widget (audit b13 review, R1). felix new does not rebind: `felix new web apps/web` then
# `felix new api apps/api` used to leave .felix reading api, and web's sessions were judged as api's.
# Prints the refusal and returns 0 when one does.
felix_new_governed() {   # ROOT HOME
  local root="$1" home="$2" x ro m meta LC_ALL=C
  if [ -f "$root/.felix" ]; then
    x="$(LC_ALL=C tr -d '[:space:]' < "$root/.felix" 2>/dev/null)"
    _felix_name_ok "$x" && [ -d "$home/projects/$x" ] || return 1
    printf '%s is already governed by %s through %s, and felix new does not rebind a git root a project governs: one git root has one project, whatever directory below it you name. Nothing was made. If the marker is wrong, remove it and run this again.' "$root" "$x" "$root/.felix"
    return 0
  fi
  ro="$(felix_new_remote_match "$root")"
  [ -n "$ro" ] || return 1
  for meta in "$home"/projects/*/project.json; do
    [ -f "$meta" ] || continue
    m="$(felix_json_str "$meta" remote_match)"
    [ -n "$m" ] || continue
    [ "$m" = "$ro" ] || [ "$(felix_new_rm_of "$m")" = "$ro" ] || continue
    x="${meta%/project.json}"; x="${x##*/}"
    printf '%s is already governed by %s: its origin names the same repository as the remote_match in %s, and felix new does not rebind a checkout a project governs. Nothing was made. To bind it to %s by hand, write %s into %s/.felix; for a project of its own, change that remote_match first.' "$root" "$x" "$meta" "$x" "$x" "$root"
    return 0
  done
  return 1
}

# What the marker held that felix new is about to replace, as the one line it prints, or nothing.
felix_new_replaced_line() {   # ROOT
  local x
  [ -f "$1/.felix" ] || return 0
  x="$(LC_ALL=C tr -d '[:space:]' < "$1/.felix" 2>/dev/null)"
  if _felix_name_ok "$x"; then
    printf '  replaced     %s/.felix, which named %s, and no such project exists\n' "$1" "$x"
  else
    printf '  replaced     %s/.felix, which named no project\n' "$1"
  fi
}

# The lines felix new adds after it has bound: where the marker went, whether git will carry it to a
# worktree, and whether anything runs unattended for the project (audit b13, C116, C117).
felix_new_notes() {   # ROOT TARGET PROJECT-DIR NAME REPLACED-LINE
  local root="$1" target="$2" dir="$3" name="$4" held why
  [ -z "${5:-}" ] || printf '%s\n' "$5"
  if [ "$(cd "$target" 2>/dev/null && pwd -P)" != "$(cd "$root" 2>/dev/null && pwd -P)" ]; then
    printf '  checkout     %s, the git root holding %s: one marker binds all of it\n' "$root" "$target"
  fi
  if [ "$(git -C "$root" rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    held="$(git -C "$root" show HEAD:.felix 2>/dev/null | LC_ALL=C tr -d '[:space:]')"
    [ "$held" = "$name" ] || printf '  commit       .felix is not committed, and a worktree gets only what is committed: commit it, or a session in a worktree is judged at the main checkout\n'
  fi
  if ! felix_checkout_is_own "$dir" "$root"; then
    case "${_FELIX_OWN_WHY:-}" in
      no-origin) why="this checkout has no origin remote" ;;
      submodule) why="this checkout is a submodule" ;;
      other)     why="its origin is not the github.com repository its remote_match names" ;;
      unread)    why="git could not answer" ;;
      *)         why="its remote_match names no github.com owner/repo" ;;
    esac
    printf '  unattended   nothing runs for %s unattended in this checkout: %s. Set remote_match in %s/project.json to the github.com owner/repo once the remote exists.\n' "$name" "$why" "$dir"
  fi
  return 0
}

# felix install copies engine/ as it lies on disk. What git does not track there, an untracked or
# an ignored file such as a Finder .DS_Store, would be deployed with it and then fail the gate's
# installed check, which no version bump clears (audit b13, C064). So install asks the repository
# holding the source first, as the unattended deploy does (green-install.sh, A24), and refuses.
# When git cannot answer it says so and goes on as before.
felix_install_untracked() {   # SRC (the engine directory)
  local repo="${1%/*}" top why="" out n first rest="" p k=0
  # git answers for this source only when the source is its work tree's top level, or that tree tracks the
  # source's engine: a source unpacked inside some other repository is one that repository never saw (audit b13 review, R2).
  top="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null </dev/null)" || why="is not in a git work tree, or git failed"
  if [ -z "$why" ] && ! [ "$top" -ef "$repo" ] \
     && [ -z "$(git -C "$repo" ls-files -- engine/.claude-plugin/plugin.json 2>/dev/null </dev/null)" ]; then
    why="sits inside the git work tree ${top:-(unnamed)}, which tracks none of its engine/"
  fi
  [ -z "$why" ] || { printf '  could not ask git what engine/ holds that it does not track (%s %s), so strays there are not checked\n' "$repo" "$why"; return 0; }
  out="$(git -C "$repo" ls-files --others --directory -- engine/ 2>/dev/null </dev/null)" \
    || { printf '  could not ask git what engine/ holds that it does not track (git failed in %s), so strays there are not checked\n' "$repo"; return 0; }
  [ -n "$out" ] || return 0
  n="$(printf '%s\n' "$out" | LC_ALL=C awk 'END { print NR }')"
  first="$(printf '%s\n' "$out" | LC_ALL=C sed -n '1p')"
  while IFS= read -r p; do
    k=$((k + 1)); [ "$k" -le 5 ] && rest="$rest
  $p"
  done <<EOF
$out
EOF
  [ "$n" -le 5 ] || rest="$rest
  ... and $((n - 5)) more"
  die "engine/ holds $n path(s) git does not track:$rest
felix install copies engine/ as it lies on disk, so these would be deployed with it, and the installed check would then fail on them.
Nothing was deployed or bumped. Remove them, or commit them if they belong, then run felix install again; the first is $first"
}

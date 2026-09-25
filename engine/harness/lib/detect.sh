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
      grep -qiE "$pat" "$m" && return 0
    done
  done
  return 1
}

# A web surface exists whether or not npm was ever run there. Counted from
# tracked files so a vendored dependency tree cannot manufacture a frontend.
_felix_frontend_assets() {
  local root="$1" n
  n="$( { git -C "$root" ls-files 2>/dev/null || find "$root" -type f 2>/dev/null; } \
        | grep -icE '\.(jsx?|tsx?|vue|svelte|s[ac]ss|css)$' )"
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
felix_declared() {
  local proj="$1"
  [ -f "$proj/capabilities" ] || return 0
  grep -vE '^\s*(#|$)' "$proj/capabilities" 2>/dev/null
}

# Present in the checkout but never declared. This is the drift worth surfacing.
felix_undeclared() {
  local root="$1" proj="$2"
  comm -23 \
    <(felix_detect "$root" | sort -u) \
    <(felix_declared "$proj" | sort -u)
}

# Best guess at the command that proves this project correct. A guess, printed
# for a human to confirm, never silently trusted: a wrong gate that exits 0 is
# the one failure mode worse than having no gate.
felix_guess_gate() {
  local root="${1:-$PWD}"
  if [ -f "$root/package.json" ]; then
    grep -q '"verify"' "$root/package.json" && { echo "npm run verify"; return; }
    grep -q '"test"'   "$root/package.json" && { echo "npm test"; return; }
  fi
  [ -f "$root/Makefile" ] && grep -qE '^(check|verify):' "$root/Makefile" \
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

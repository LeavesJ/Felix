# Bring a repository up to the Engineering OS baseline.
#
# The first project onboarded here got its workflow file, escalation labels,
# branch protection, and permission policy applied by hand with gh. That is what
# made the claim false that `felix new` hands a newcomer what the first project
# has: they got a governed directory and none of the enforcement, because a
# person was the automation. This closes that gap.
#
# Every step is idempotent and reports what it found rather than assuming. Plan
# is the default; --yes applies. Branch protection and permission policy change
# what a repository will accept, so they are never a side effect of running a
# read command.

# Present in the working tree, or already on the remote's default branch. A
# checkout that has not pulled since the workflow merged would otherwise be told
# to write a file that already exists upstream, producing a conflict out of
# nothing.
_felix_bs_have_workflow() {
  [ -f "$1/.github/workflows/gate.yml" ] && return 0
  git -C "$1" cat-file -e "origin/HEAD:.github/workflows/gate.yml" 2>/dev/null && return 0
  git -C "$1" cat-file -e "origin/main:.github/workflows/gate.yml" 2>/dev/null
}
_felix_bs_have_labels()   {
  felix_contains "$(gh label list --repo "$1" 2>/dev/null)" "needs-founder"
}
_felix_bs_have_protection() {
  gh api "repos/$1/branches/$2/protection" >/dev/null 2>&1
}
# grep on a file is safe; only pipelines can SIGPIPE.
_felix_bs_have_perms()    { [ -f "$1/.claude/settings.json" ] && \
                            grep -q '"deny"' "$1/.claude/settings.json" 2>/dev/null; }

# Which toolchain CI has to install before the gate can run.
felix_guess_ecosystem() {
  local root="$1"
  [ -f "$root/package.json" ]   && { echo node;   return; }
  [ -f "$root/pyproject.toml" ] && { echo python; return; }
  [ -f "$root/Cargo.toml" ]     && { echo rust;   return; }
  [ -f "$root/go.mod" ]         && { echo go;     return; }
  echo none
}

_felix_bs_setup_block() {
  case "$1" in
    node)   printf '      - uses: actions/setup-node@v4\n        with:\n          node-version: "22"\n      - run: npm ci\n        working-directory: repo\n' ;;
    python) printf '      - uses: actions/setup-python@v5\n        with:\n          python-version: "3.12"\n      - run: pip install -e ".[dev]"\n        working-directory: repo\n' ;;
    rust)   printf '      - uses: dtolnay/rust-toolchain@stable\n' ;;
    go)     printf '      - uses: actions/setup-go@v5\n        with:\n          go-version: stable\n' ;;
    *)      printf '      # no toolchain detected; add the setup step this project needs\n' ;;
  esac
}

# The workflow calls `felix gate` and nothing else. What the gate means stays in
# the project, so changing the checks never means editing CI.
felix_bs_render_workflow() {
  local eco="$1" felix_repo="$2"
  cat <<YAML
name: gate

# The gate lives in Felix, not here. This file is only the wiring that lets
# GitHub run it, which is why it should stay the smallest possible addition to
# this repository.

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: gate-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      # Sibling checkouts. A harness inside the tree being gated shows up in the
      # checks it is running.
      - uses: actions/checkout@v4
        with:
          path: repo

      - uses: actions/checkout@v4
        with:
          repository: ${felix_repo}
          ssh-key: \${{ secrets.FELIX_DEPLOY_KEY }}
          path: felix

$(_felix_bs_setup_block "$eco")
      - name: Confirm the governing project
        working-directory: repo
        run: ../felix/engine/harness/felix which

      - name: Run the gate
        working-directory: repo
        run: ../felix/engine/harness/felix gate
YAML
}

# Guidebook p11, as configuration rather than instruction. Written only when the
# project has no deny list of its own; an existing policy is never overwritten,
# because a permission file someone tightened by hand is not Felix's to relax.
felix_bs_render_perms() {
  cat <<'JSON'
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard origin/*)",
      "Bash(rm -rf /*)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(gh pr merge*)",
      "Bash(gh secret*)",
      "Bash(gh api -X DELETE*)"
    ]
  }
}
JSON
}

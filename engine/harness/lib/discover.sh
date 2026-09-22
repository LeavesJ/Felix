# Discovery: what is worth having that this project does not have.
#
# The catalogue is fifteen hand-written rows. There are 273 plugins in one
# marketplace alone, and the ones that matter most are the ones a general
# recommendation pass is least likely to name: rust-analyzer for a crate,
# deepeval for a model harness, a SAST scanner for anything shipping to users.
#
# Three stages, and the middle one has no platform support whatsoever.
#
#   enumerate   what the marketplaces offer
#   evaluate    fetch the source at its pinned sha and READ it
#   recommend   a row you could add; Felix never adds it
#
# Evaluation has to be built because nothing else does it. `claude plugin
# validate` checks schema only — a plugin whose hook uploads an ssh key passes
# it with one cosmetic warning — and the plugin format has no permission
# declaration at all, so installing is unconditionally granting arbitrary code
# execution. `plugin eval` is not a sandbox and does not claim to be.
#
# What is fetched is read and deleted. Nothing from it is executed, sourced, or
# put on a path. That distinction is the entire safety argument for this stage,
# and any change that weakens it invalidates the design.
#
# The ceiling, stated because it will be forgotten once the output starts
# looking authoritative: this catches carelessness, not an attacker. A plugin
# that ships no hooks, pins its versions and interpolates no secrets can still
# do as it likes the moment it runs, because there is no boundary holding it to
# any of that. What it buys is finding out that something ships hooks BEFORE
# installing it rather than never.

# admit.sh holds the one install policy. Sourced by path because the suite
# sources this library alone, in a subshell, and this file's own rule — stated
# again at the adopt call below — is that a helper from a sibling lib turns
# that into a runtime error rather than a failing assertion. The guard is how
# that rule and the shared policy both hold.
if ! command -v felix_admit >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/admit.sh"
fi

# And the same guard over the one registry reader, for felix_discover_drift.
# The registry has been read by hand in three places in this repository's
# history and the copies diverged; resolve.sh holds the reader that survived
# that, and duplicating it here to keep this file standalone would be choosing
# the defect over the rule. resolve.sh defines functions and does nothing at
# source time, so the guard costs a sourced file and no behaviour.
if ! command -v felix_registry_field >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_DISCOVER_MAX="${FELIX_DISCOVER_MAX:-8}"

# capability <TAB> keywords, for capabilities this project actually declared.
#
# Driven by what the project declared, not by what the table happens to hold.
# Row-first, a capability nobody wrote a row for contributed nothing — no
# score, no candidate, no complaint — and that is not hypothetical: one
# governed project here declares `security`, the table has no `security`
# row, and every security plugin on the machine was invisible to it.
# Measured across three governed projects, the funnel matched 4 of 35
# installed plugins.
#
# A capability's own name is also the highest-precision keyword there is,
# and it is free, so it is added to whatever the table says. It was written
# out by hand for only 4 of 12 rows, which is how a project declaring
# `frontend` failed to match a plugin named `frontend-design`.
#
# Only from five characters up. Short names are substrings of ordinary
# words — `ci` sits inside `specification`, `api` inside `rapid`, `iac`
# inside `hypothetical` — and this matcher is substring-based by design, so
# a three-letter capability used as a keyword would match nearly everything.
# The table's own header records what that costs: a keyword matching
# everything identifies nothing. Every capability detection can adopt that
# is at least five characters keeps working; the shorter ones stay dependent
# on their curated row, and felix_capabilities_unruled says when one has
# none.
# Emitted in two passes, and the order is the point. felix_capability_match
# keeps the FIRST rule at equal score, so emission order breaks ties — and
# driving the whole thing from the capabilities file handed that authority to
# whichever line somebody happened to put first. The `iac` row is the first
# pair in this table that can actually tie (`terraform` belongs to both it
# and `deploy`, and a plugin by that name exists), so reordering two lines in
# a file people edit freely would have silently re-filed a real plugin.
# Curated rows first, in the engine's own table order; then the capabilities
# no row covers, sorted, so a curated row also beats a name-only fallback.
_felix_discover_rules() {
  local tpl="$1" proj="$2" cap kws rcap rkws table="" declared ruled=""
  [ -f "$tpl/discover-rules.tsv" ] \
    && table="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/discover-rules.tsv" 2>/dev/null)"
  declared="$(felix_declared "$proj")"

  while IFS=$'\t' read -r rcap rkws; do
    [ -n "${rcap:-}" ] || continue
    felix_has_line "$declared" "$rcap" || continue
    ruled="$ruled$rcap
"
    kws="$rkws"
    # Appended only when the row does not already say it. Two rows list their
    # own name as the first keyword, and the matcher adds three per
    # occurrence with no dedup, so those scored a name hit twice.
    case " $kws " in
      *" $rcap "*) ;;
      *) [ "${#rcap}" -ge 5 ] && kws="$kws $rcap" ;;
    esac
    printf '%s\t%s\n' "$rcap" "${kws# }"
  done <<EOF
$table
EOF

  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$ruled" "$cap" && continue
    # A capability name is an identifier. felix_declared strips whole-line
    # comments only, so a line carrying a trailing remark survives as one
    # long "capability" — harmlessly dropped while the table drove the loop,
    # and, once declarations drive it, a keyword and a name that
    # `discover --adopt` would write into stack.tsv.
    case "$cap" in *[!a-z0-9_-]*) continue ;; esac
    [ "${#cap}" -ge 5 ] || continue
    printf '%s\t%s\n' "$cap" "$cap"
  done <<EOF
$(printf '%s\n' "$declared" | LC_ALL=C sort -u)
EOF
  return 0
}

# Declared capabilities the table has no curated row for, one per line.
#
# They are not unscored any more — the name carries them — but a single
# keyword is far thinner than a curated row, and which capabilities are in
# that state is a fact about this project's tables that nothing else says
# out loud. Same shape as the overbroad-deny report: a rule quietly doing
# almost nothing is the complaint Felix makes about other people's plugins.
felix_capabilities_unruled() {
  local proj="$1" tpl="$2" cap ruled
  [ -f "$tpl/discover-rules.tsv" ] || return 0
  ruled="$(grep -vE '^[[:space:]]*(#|$)' "$tpl/discover-rules.tsv" 2>/dev/null | cut -f1)"
  while IFS= read -r cap; do
    [ -n "$cap" ] || continue
    felix_has_line "$ruled" "$cap" && continue
    printf '%s\n' "$cap"
  done <<EOF
$(felix_declared "$proj")
EOF
  return 0
}

# Everything the marketplaces offer that this project has not declared.
# score <TAB> capability <TAB> name <TAB> description
#
# Scored only against capabilities the project declared, so a project with no
# database never sees database tooling however loudly a plugin advertises.
#
# Exit 0 is a catalogue that was read, whether or not anything in it matched.
# Exit 3 is a catalogue that could not be read: no CLI, a CLI that failed, or
# a CLI that answered with something other than a listing. The two used to be
# one — a CLI error came back through the pipeline as no rows — and the quiet
# form then wrote "nothing matches" into a cache that stays current for seven
# days. Nothing that reads the cache could tell a marketplace with nothing for
# this project from a morning the CLI was broken. Read by an agent from the
# find-skills plugin, which draws the same line in its own catalogue reader.
felix_discover_candidates() {
  local proj="$1" tpl="$2" rules listing
  command -v claude >/dev/null 2>&1 || return 3
  rules="$(_felix_discover_rules "$tpl" "$proj")"
  [ -n "$rules" ] || return 0

  local declared
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | cut -f2 | sed 's/@.*//')"

  listing="$(claude plugin list --json --available </dev/null 2>/dev/null)" || return 3
  # A listing is a JSON array or object. An error printed to stdout with a
  # zero exit — which the CLI has done — begins with neither, and would have
  # matched no name and read as an empty marketplace.
  #
  # The residual, stated rather than closed: a JSON-SHAPED error with a zero
  # exit, `{"error":"could not reach the marketplace"}`, still passes here and
  # still reads as a catalogue with nothing in it. Requiring a parsed name
  # would catch it, and would also call a genuinely empty marketplace
  # unreadable — an over-refusal in the one direction nobody can act on, which
  # is how a check gets switched off. The measured failure is the plain-text
  # one and that is what this rejects.
  case "$(printf '%s' "$listing" | tr -d '[:space:]' | cut -c1)" in
    '['|'{') ;;
    *) return 3 ;;
  esac

  # The rows are computed into a variable and the status is stated, not
  # inherited from the last pipeline. Two ways this function reported failure
  # over a catalogue it had read perfectly well, both of which mattered only
  # once cmd_discover started reading the status:
  #
  #   a `while` loop's status is that of the last command its body ran, and
  #   the body ended in `[ "$best" -ge N ] && printf ...`. So whenever the LAST
  #   entry in the listing scored below the threshold — the common case, since
  #   most of a marketplace does not match one project — the loop returned 1.
  #   Measured on main as well: it is older than the status being read, and
  #   harmless until something read it.
  #
  #   and `head -N` closes the pipe on the N+1th row, so a catalogue with more
  #   matches than FELIX_DISCOVER_MAX takes SIGPIPE upstream and returns 141
  #   under pipefail. This repository already carries that lesson about grep -q.
  #
  # Reaching this line means the catalogue WAS read. Whether anything in it
  # matched is the answer, not an error, so the status is 0 and the rows say
  # the rest.
  local rows
  rows="$(printf '%s\n' "$listing" \
    | sed -n -e 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/N \1/p' \
             -e 's/.*"description"[[:space:]]*:[[:space:]]*"\(.*\)".*/D \1/p' \
    | awk '/^N /{ if (n != "") print n "\t" d; n=substr($0,3); d="" }
           /^D /{ d=substr($0,3) }
           END{ if (n != "") print n "\t" d }' \
    | while IFS=$'\t' read -r name desc; do
        [ -n "$name" ] || continue
        felix_has_line "$declared" "$name" && continue
        local hit best best_cap
        hit="$(felix_capability_match "$name" "$desc" "$rules")"
        best="$(printf '%s' "$hit" | cut -f1)"
        best_cap="$(printf '%s' "$hit" | cut -f2)"
        if [ "$best" -ge "${FELIX_DISCOVER_MIN:-3}" ]; then
          printf '%s\t%s\t%s\t%s\n' "$best" "$best_cap" "$name" "$desc"
        fi
      done)"
  printf '%s\n' "$rows" | grep . | sort -k1,1nr | head -"$FELIX_DISCOVER_MAX"
  return 0
}

# Source coordinates for one candidate: url <TAB> sha <TAB> subdir
# The CLI reads stdin. Called from inside a `while read` loop it drains the very
# list being iterated, so most candidates silently resolved to nothing while one
# happened to survive — the erratic kind of failure that looks like a network
# problem. Every invocation here is fed /dev/null.
#
# Splitting the document on braces and grepping for the name was the first
# attempt, and it found nothing: a plugin's name and its nested source object
# land in different records, so the record carrying the name never carries the
# url. Tag every interesting line with which field it is, then walk them in
# order and keep whichever entry was open when the url appeared.
#
# A fourth field, the marketplace the entry came from, since 2026-09-21. The
# listing carries no hooks, servers or LSP servers of an entry's own, only its
# source, so the catalogue file that does is found by this name
# (felix_discover_marketplace_file). Appended, so every reader of the first
# three is unchanged.
felix_discover_source() {
  local name="$1"
  command -v claude >/dev/null 2>&1 || return 1
  claude plugin list --json --available </dev/null 2>/dev/null \
    | sed -n -e 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/N \1/p' \
             -e 's/.*"url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/U \1/p' \
             -e 's/.*"sha"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/S \1/p' \
             -e 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/P \1/p' \
             -e 's/.*"marketplaceName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/M \1/p' \
    | awk -v want="$name" '
        # Deliberately reads to the end instead of exiting on the first match.
        # Exiting early closes the pipe, the CLI upstream takes SIGPIPE and
        # reports 141, and under pipefail that becomes the status of this whole
        # pipeline: every candidate resolved to no source while the same call by
        # hand worked perfectly. This repository already carries a lesson about
        # exactly this, written about grep -q.
        /^N /{ if (!found && cur == want && u != "") { U=u; S=s; P=p; M=m; found=1 }
               cur=substr($0,3); u=""; s=""; p=""; m="" }
        /^U /{ u=substr($0,3) }
        /^S /{ s=substr($0,3) }
        /^P /{ p=substr($0,3) }
        /^M /{ m=substr($0,3) }
        END{ if (!found && cur == want && u != "") { U=u; S=s; P=p; M=m; found=1 }
             if (found) print U "\t" S "\t" P "\t" M }'
}

# Git, for the one place Felix talks to a host it does not control.
#
# Two things this fixes, both of which only bite where nobody is watching.
#
# A fetch with no deadline waits forever. In the foreground that is a hang a
# person cancels; behind any caller that is not a person it is a hang nobody
# can see. There is no portable `timeout` — neither it nor gtimeout is on this
# machine, and the enforcing path may not depend on coreutils — so the deadline
# is git's own: abort an http transfer moving less than LIMIT bytes/sec for
# TIME seconds. That covers a stalled transfer, which a wall-clock kill covers
# by also killing a slow success.
#
# And a private or moved URL makes git ask for credentials on a terminal. Asked
# where there is none it blocks; asked where there is one it interrupts a person
# with a prompt from a command that never said it would authenticate. Both are
# refusals dressed as hangs. GIT_TERMINAL_PROMPT=0 turns them into an ordinary
# non-zero exit, which every caller here already handles: a fetch that did not
# complete reads as `unknown` in the admit phase, and unknown holds.
#
# Overridable, so a slow link is a setting rather than a fork.
_felix_discover_git() {
  GIT_TERMINAL_PROMPT=0 \
  GIT_ASKPASS="${GIT_ASKPASS:-/bin/echo}" \
  GIT_HTTP_LOW_SPEED_LIMIT="${FELIX_FETCH_LOW_SPEED_LIMIT:-1000}" \
  GIT_HTTP_LOW_SPEED_TIME="${FELIX_FETCH_LOW_SPEED_TIME:-30}" \
  git "$@"
}

# Fetch a candidate's source, shallow and at its pinned commit, into a scratch
# directory. Read only. Never executed, never sourced, never put on a path.
felix_discover_fetch() {
  local url="$1" sha="$2" dest="$3"
  [ -n "$url" ] || return 1
  rm -rf "$dest" 2>/dev/null
  mkdir -p "$dest" 2>/dev/null || return 1
  if [ -n "$sha" ]; then
    _felix_discover_git -C "$dest" init -q 2>/dev/null || return 1
    _felix_discover_git -C "$dest" remote add origin "$url" 2>/dev/null || return 1
    _felix_discover_git -C "$dest" fetch -q --depth 1 origin "$sha" 2>/dev/null || return 1
    _felix_discover_git -C "$dest" checkout -q FETCH_HEAD 2>/dev/null || return 1
  else
    _felix_discover_git clone -q --depth 1 "$url" "$dest" 2>/dev/null || return 1
  fi
  return 0
}

# The rules for one hooks file, one MCP file and one LSP file, wherever it was
# found: at the default place, at a path the manifest names, or in the manifest
# or the marketplace entry itself. Applied to a whole manifest they also see
# its other keys, which can only add a fact, never remove one.
_felix_discover_hooks_facts() {
  local f="$1"
  printf 'hooks\t%s\n' \
    "$(grep -oE '"(PreToolUse|PostToolUse|SessionStart|SessionEnd|Stop|UserPromptSubmit|PostToolBatch)"' "$f" \
       | tr -d '"' | sort -u | tr '\n' ' ')"
  grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]{0,90}' "$f" \
    | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' \
    | while IFS= read -r c; do printf 'hook-command\t%s\n' "$c"; done
  return 0
}

_felix_discover_mcp_facts() {
  local f="$1"
  grep -qE '"type"[[:space:]]*:[[:space:]]*"(http|sse)"' "$f" \
    && printf 'mcp\tremote endpoint\n' || printf 'mcp\tlocal subprocess\n'
  grep -oE '\$\{[A-Z_]+' "$f" | tr -d '${' | sort -u \
    | while IFS= read -r v; do [ -n "$v" ] && printf 'interpolates\t%s\n' "$v"; done
  grep -qE '@latest|:latest' "$f" && printf 'floating\tan unpinned version in the mcp command\n'
  return 0
}

# An LSP server is a local subprocess and has no other form: Claude Code runs
# its `command` on this machine, as whoever is signed in, the first time a file
# of a language it claims is opened. So it is the MCP local server's fact under
# its own name, and the interpolation and floating-version rules are the MCP
# ones, because a `${VAR}` or an `@latest` means the same thing in either file.
_felix_discover_lsp_facts() {
  local f="$1"
  printf 'lsp\tlocal subprocess\n'
  grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]{0,90}' "$f" \
    | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//' \
    | while IFS= read -r c; do printf 'lsp-command\t%s\n' "$c"; done
  grep -oE '\$\{[A-Z_]+' "$f" | tr -d '${' | sort -u \
    | while IFS= read -r v; do [ -n "$v" ] && printf 'interpolates\t%s\n' "$v"; done
  grep -qE '@latest|:latest' "$f" && printf 'floating\tan unpinned version in the lsp command\n'
  return 0
}

# Where a path the plugin names really lands. Prints the resolved file when it
# is a regular file inside the copy; otherwise prints why not and returns 1.
#
# Refused before anything is opened: an absolute path, a leading ~, and any
# `..` component. Then every link on the way is resolved, and the directory
# the file finally sits in must be the copy or below it, so a link that leaves
# the copy is not followed however it is spelled. What is outside the copy is
# somebody's machine, not what was fetched, and a fact read from it would
# describe the wrong object. Claude Code rejects most of these as well; the
# exception is a link to elsewhere in the same marketplace, which it copies
# in at install. That one is refused here too, and the caller tiers what it
# could not read high, so the difference can only hold a plugin, never pass
# one.
#
# A third argument, `dir`, accepts a directory as well, for `commands` and
# `skills`, which name folders as often as files. The rule is the same one:
# the directory, links resolved, must be the copy or below it.
_felix_discover_inside() {
  local base="$1" p="$2" dirok="${3:-}" real d link n=0
  case "$p" in /*|'~'*) printf 'an absolute path'; return 1 ;; esac
  case "/$p/" in */../*) printf 'a path that climbs out with ..'; return 1 ;; esac
  real="$(cd "$base" 2>/dev/null && pwd -P)" || { printf 'the copy did not resolve'; return 1; }
  p="$real/${p#./}"
  while [ -L "$p" ]; do
    n=$((n+1))
    [ "$n" -le 8 ] || { printf 'a chain of links'; return 1; }
    link="$(readlink "$p" 2>/dev/null)" || { printf 'a link that did not resolve'; return 1; }
    case "$link" in /*) p="$link" ;; *) p="${p%/*}/$link" ;; esac
  done
  if [ -n "$dirok" ] && [ -d "$p" ]; then
    d="$(cd "$p" 2>/dev/null && pwd -P)" || { printf 'no such directory'; return 1; }
    case "$d/" in "$real"/*) ;; *) printf 'a link that leaves the copy'; return 1 ;; esac
    printf '%s' "$d"; return 0
  fi
  [ -f "$p" ] || { printf 'no such file'; return 1; }
  d="$(cd "${p%/*}" 2>/dev/null && pwd -P)" || { printf 'no such directory'; return 1; }
  case "$d/" in "$real"/*) ;; *) printf 'a link that leaves the copy'; return 1 ;; esac
  printf '%s/%s' "$d" "${p##*/}"
}

# What the manifest declares, followed. `hooks`, `mcpServers` and `lspServers`
# may each be a path, a list of paths, or the configuration inline, and the
# platform loads all three forms. A path is read by the same rules as the
# default file, once: `./hooks/hooks.json` spelled out in the manifest is not
# read twice. Inline, the manifest itself is read by those rules.
#
# A declaration that is refused or missing is a fact, `unread`, and it tiers
# high. The manifest says something runs, and Felix only tiers what it read;
# reporting the plugin as if the declaration were absent is exactly the
# defect this closes. An empty `{}`, `[]` or null declares nothing: one
# installed plugin carries `"mcpServers": {}`, and it ships no server.
#
# `commands` and `skills` name where the frontmatter hooks can be, and those
# are followed too. A `commands` path REPLACES the default commands/ folder and
# a `skills` path ADDS to skills/, and until 2026-09-21 only the defaults were
# scanned, so a hook in the frontmatter of a declared command was never seen.
# The defaults are still scanned whatever the manifest says, which can only
# add. A declared folder that is missing is not `unread`: nothing loads from
# it, so nothing runs from it. One refused by the containment rule is.
#
# The second argument is a plugin's entry in its marketplace catalogue, held in
# a file of its own. The entry can carry every one of these keys, inline or as
# paths into the plugin, and the platform loads them alongside the manifest's
# (as the whole definition, where the entry says `"strict": false`). Twelve
# entries in the official catalogue declare their LSP server there and nowhere
# else, and two of them were installed here and tiered `low` with nothing read.
# Its paths resolve against the plugin, like the manifest's.
#
# Only the manifest's top-level keys declare anything. A `hooks` key under
# `userConfig` is a setting's name, and treating it as a declaration would
# refuse a plugin that ships no hooks at all; a pattern over the flattened file
# cannot tell the two apart, so the manifest is walked instead, strings and
# nesting tracked, by the awk below. A value it does not recognise is `unread`
# too, so the reader failing raises rather than passes.
#
# One line per declaration: `path KEY P` for a path, `inline KEY` for a
# non-empty object, `odd KEY` for anything else that is not null.
#
# Strict at the top level, and that is deliberate. A walker that skips what it
# does not expect and resynchronises on the next quote can take a quote inside
# a broken string for the start of a key, and then the declaration after the
# break is read as text and disappears. So a manifest that is not
# `{ "key": value, ... }` all the way to its closing brace is `odd` as a whole,
# and so is one that is not an object at all. Claude Code would not load
# either, but this is a copy Felix read, not the one it would install, and the
# reader failing must raise rather than pass.
_FELIX_DISCOVER_MANIFEST_AWK='
function ws(i) { while (i <= n && substr(s, i, 1) ~ /[ \t\r\n]/) i++; return i }
function broken() { print "odd\tthe manifest"; exit }
function str(i,   d, o) {
  o = ""; i++; UNTERM = 0
  while (i <= n) {
    d = substr(s, i, 1)
    if (d == "\\") { o = o (substr(s, i + 1, 1) == "/" ? "/" : substr(s, i, 2)); i += 2; continue }
    if (d == "\"") { STR = o; return i + 1 }
    o = o d; i++
  }
  STR = o; UNTERM = 1; return i
}
function val(i,   c, dep) {
  c = substr(s, i, 1); UNTERM = 0
  if (c == "\"") { KIND = "string"; return str(i) }
  if (c == "{" || c == "[") {
    KIND = (c == "{") ? "object" : "array"; EMPTY = 1; dep = 0
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == "\"") { EMPTY = 0; i = str(i); continue }
      if (c == "{" || c == "[") { if (dep) EMPTY = 0; dep++ }
      else if (c == "}" || c == "]") { if (--dep == 0) return i + 1 }
      else if (c !~ /[ \t\r\n]/) EMPTY = 0
      i++
    }
    UNTERM = 1; return i
  }
  KIND = (substr(s, i, 4) == "null") ? "null" : "other"
  while (i <= n && substr(s, i, 1) !~ /[],}{:"[ \t\r\n]/) i++
  return i
}
function decl(key) {
  if (KIND == "string") print "path\t" key "\t" STR
  else if (KIND == "object") { if (!EMPTY) print "inline\t" key }
  else if (KIND != "null") print "odd\t" key
}
{ s = s $0 "\n" }
END {
  n = length(s); i = 1
  if (substr(s, 1, 3) == "\357\273\277") i = 4
  i = ws(i)
  if (substr(s, i, 1) != "{") broken()
  i = ws(i + 1)
  if (substr(s, i, 1) == "}") exit
  while (1) {
    if (substr(s, i, 1) != "\"") broken()
    i = str(i); if (UNTERM) broken()
    key = STR; i = ws(i)
    if (substr(s, i, 1) != ":") broken()
    i = ws(i + 1); b = i; i = val(i)
    if (UNTERM || i == b) broken()
    if (key == "hooks" || key == "mcpServers" || key == "lspServers" || key == "commands" || key == "skills") {
      if (KIND != "array") decl(key)
      else {
        j = b + 1
        while (1) {
          j = ws(j)
          if (j >= i) { print "odd\t" key; break }
          if (substr(s, j, 1) == "]") break
          e = j; j = val(j)
          if (UNTERM || j == e) { print "odd\t" key; break }
          if (KIND == "array") KIND = "other"
          decl(key)
          j = ws(j); c = substr(s, j, 1)
          if (c == ",") { j++; continue }
          if (c != "]") print "odd\t" key
          break
        }
      }
    }
    i = ws(i); c = substr(s, i, 1)
    if (c == "}") exit
    if (c != ",") broken()
    i = ws(i + 1)
  }
}'

_felix_discover_manifest() {
  local base="$1" entry="${2:-}" real m src label decls kind key p r dk inline seen="" nl='
'
  real="$(cd "$base" 2>/dev/null && pwd -P)" || return 0
  r="$(_felix_discover_inside "$base" hooks/hooks.json)" && seen="${seen}hooks:$r$nl"
  for r in .mcp.json mcp.json; do
    r="$(_felix_discover_inside "$base" "$r")" && seen="${seen}mcpServers:$r$nl"
  done
  r="$(_felix_discover_inside "$base" .lsp.json)" && seen="${seen}lspServers:$r$nl"
  for r in commands skills; do
    [ -d "$real/$r" ] || continue
    p="$(_felix_discover_inside "$base" "$r" dir)" && seen="${seen}$r:$p$nl"
  done

  for src in manifest entry; do
    if [ "$src" = manifest ]; then
      # The manifest itself is held to the same rule: one linked out of the
      # copy is somebody else's file.
      if ! m="$(_felix_discover_inside "$base" .claude-plugin/plugin.json)"; then
        [ "$m" = "no such file" ] || printf 'unread\tthe manifest: %s\n' "$m"
        continue
      fi
      label=""
    else
      [ -n "$entry" ] && [ -f "$entry" ] || continue
      m="$entry"; label="the marketplace entry's "
    fi
    inline=""
    # An awk that fails prints nothing, and nothing would read as low; its
    # failure is the manifest going unread instead.
    decls="$(LC_ALL=C awk "$_FELIX_DISCOVER_MANIFEST_AWK" "$m" 2>/dev/null)" \
      || decls="$(printf 'odd\tthe manifest')"
    while IFS=$'\t' read -r kind key p; do
      dk=""; case "$key" in commands|skills) dk=dir ;; esac
      case "$kind" in
        path)
          [ -n "$p" ] || continue
          if r="$(_felix_discover_inside "$base" "$p" $dk)"; then
            case "$nl$seen" in *"$nl$key:$r$nl"*) continue ;; esac
            seen="$seen$key:$r$nl"
            case "$key" in
              hooks)           _felix_discover_hooks_facts "$r" ;;
              mcpServers)      _felix_discover_mcp_facts "$r" ;;
              lspServers)      _felix_discover_lsp_facts "$r" ;;
              commands|skills) _felix_discover_fm_scan "$key" "$real" "$r" declared ;;
            esac
          elif [ -n "$dk" ] && [ "$r" = "no such file" ]; then
            :
          else
            printf 'unread\t%s%s %s: %s\n' "$label" "$key" "$(printf '%.120s' "$p" | LC_ALL=C tr '\001-\037\177' '?')" "$r"
          fi ;;
        inline)
          case " $inline " in *" $key "*) continue ;; esac
          inline="$inline $key"
          case "$key" in
            hooks)      _felix_discover_hooks_facts "$m" ;;
            mcpServers) _felix_discover_mcp_facts "$m" ;;
            lspServers) _felix_discover_lsp_facts "$m" ;;
            # A command or skill written out inline has no file to scan for
            # frontmatter, and this reader does not take one apart.
            *)          printf 'unread\t%s%s: an inline form this reader does not parse\n' "$label" "$key" ;;
          esac ;;
        odd)
          case "$key" in
            "the manifest")
              if [ -n "$label" ]; then printf 'unread\tthe marketplace entry: not a JSON object\n'
              else printf 'unread\tthe manifest: not a JSON object\n'; fi ;;
            *) printf 'unread\t%s%s: a value this reader does not parse\n' "$label" "$key" ;;
          esac ;;
      esac
    done <<EOF
$decls
EOF
  done
  return 0
}

# 0 when a file's YAML frontmatter has a top-level `hooks:` with a value in it.
# Read with the builtin, and only as far as the closing `---`, because a skill
# tree is mostly files that have no frontmatter hooks at all.
_felix_discover_fm_hooks() {
  local line v pend=0
  {
    IFS= read -r line || return 1
    line="${line#$'\xef\xbb\xbf'}"
    case "${line%$'\r'}" in ---|---[[:space:]]*) ;; *) return 1 ;; esac
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%$'\r'}"
      if [ "$pend" = 1 ]; then
        case "$line" in
          ---|---[[:space:]]*) return 1 ;;
          [[:space:]]*[![:space:]]*|-*) return 0 ;;
          *[![:space:]]*) pend=0 ;;
        esac
      fi
      case "$line" in ---|---[[:space:]]*) return 1 ;; esac
      case "$line" in
        hooks:*|hooks[[:space:]]*:*)
          v="${line#hooks}"; v="${v#"${v%%[![:space:]]*}"}"; v="${v#:}"; v="${v%%#*}"
          v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
          case "$v" in
            '')                          pend=1 ;;
            '[]'|'{}'|null|Null|NULL|'~') ;;
            *)                           return 0 ;;
          esac ;;
      esac
    done
  } 2>/dev/null < "$1"
  return 1
}

# Hooks a skill or a command registers in its own frontmatter. Claude Code
# registers them when the skill is invoked and keeps them for the rest of the
# session, so for every purpose here they are hooks. Agents are not read for
# this: Claude Code does not honour `hooks` in a plugin agent's frontmatter, and
# a fact about something that never runs would be a false one. The default
# directories here; the folders a manifest or a marketplace entry names are
# followed by _felix_discover_manifest, through the same scan.
_felix_discover_frontmatter() {
  local base="$1" real r
  real="$(cd "$base" 2>/dev/null && pwd -P)" || return 0
  if [ -d "$real/skills" ] && r="$(cd "$real/skills" 2>/dev/null && pwd -P)"; then
    case "$r/" in "$real"/*) _felix_discover_fm_scan skills "$real" "$r" ;; esac
  fi
  if [ -d "$real/commands" ] && r="$(cd "$real/commands" 2>/dev/null && pwd -P)"; then
    case "$r/" in "$real"/*) _felix_discover_fm_scan commands "$real" "$r" ;; esac
  fi
  return 0
}

# One place frontmatter hooks can be: a file, or a folder of commands or of
# skills, already resolved inside the copy. Commands are every .md under the
# folder. Skills are <skill>/SKILL.md; a declared path can also name one
# skill's own folder, which is how every catalogue entry that lists skills
# spells it, so for a declared path its own SKILL.md is read as well.
_felix_discover_fm_scan() {
  local kind="$1" real="$2" r="$3" declared="${4:-}" f
  if [ -f "$r" ]; then
    _felix_discover_fm_hooks "$r" \
      && printf 'hooks\tfrontmatter of %s\n' "$(printf '%s' "${r#"$real"/}" | LC_ALL=C tr '\001-\037\177' '?')"
    return 0
  fi
  if [ "$kind" = commands ]; then
    while IFS= read -r -d '' f; do
      _felix_discover_fm_hooks "$f" \
        && printf 'hooks\tfrontmatter of %s\n' "$(printf '%s' "${f#"$real"/}" | LC_ALL=C tr '\001-\037\177' '?')"
    done < <(find "$r" -type f -name '*.md' -print0 2>/dev/null)
    return 0
  fi
  for f in ${declared:+"$r/SKILL.md"} "$r"/*/SKILL.md; do
    [ -f "$f" ] || continue
    if [ -L "$f" ] || [ -L "${f%/SKILL.md}" ]; then
      _felix_discover_inside "$real" "${f#"$real"/}" >/dev/null || continue
    fi
    _felix_discover_fm_hooks "$f" \
      && printf 'hooks\tfrontmatter of %s\n' "$(printf '%s' "${f#"$real"/}" | LC_ALL=C tr '\001-\037\177' '?')"
  done
  return 0
}

# One member of a JSON document, as its raw text. With a second argument, the
# element of that top-level array whose own "name" is the third; without one,
# the value of the top-level key named by the third. Nothing when there is no
# such member.
#
# A character scanner rather than a grep, and it has to be. A catalogue entry
# is an object among hundreds of others, each with an author object that has a
# "name" of its own and a description that can hold any brace, so neither a
# line nor a pattern bounds it. Strings and escapes are tracked, and a "name"
# counts only at the entry's own depth. Pretty-printed or minified alike: the
# official catalogue, 170 KB, takes 0.13 s one way and 0.4 s the other.
_felix_json_member() {
  awk -v arr="$2" -v want="$3" '
  {
    n = split($0, ch, "")
    for (i = 1; i <= n; i++) {
      c = ch[i]
      if (rec) buf = buf c
      if (instr) {
        if (esc) { esc = 0; s = s c; continue }
        if (c == "\\") { esc = 1; s = s c; continue }
        if (c == "\"") { instr = 0; pend = 1; last = s; lastd = depth; continue }
        s = s c; continue
      }
      if (c == " " || c == "\t" || c == "\r") continue
      if (pend) {
        pend = 0
        if (c == ":") { key[lastd] = last; continue }
        if (arr != "" && inarr && lastd == 3 && key[3] == "name") nm = last
      }
      if (c == "\"") { instr = 1; s = ""; continue }
      if (c == "{" || c == "[") {
        depth++; typ[depth] = c; key[depth] = ""
        if (arr != "") {
          if (depth == 2 && c == "[" && typ[1] == "{" && key[1] == arr) inarr = 1
          else if (depth == 3 && inarr && c == "{") { rec = 1; buf = c; nm = "" }
        } else if (depth == 2 && c == "{" && typ[1] == "{" && key[1] == want) { rec = 1; buf = c }
        continue
      }
      if (c == "}" || c == "]") {
        if (rec && ((arr != "" && depth == 3) || (arr == "" && depth == 2))) {
          rec = 0
          if (arr == "" || nm == want) { print buf; exit }
        }
        if (depth == 2) inarr = 0
        depth--
      }
    }
    if (rec) buf = buf "\n"
  }' "$1" 2>/dev/null
}

# The catalogue a marketplace was installed from, by the location
# known_marketplaces.json records for it. Nothing when the marketplace is not
# registered: a plugin from a marketplace this machine no longer knows has no
# entry anybody can read, and nothing is claimed about one.
#
# resolve.sh's felix_marketplace_root reads the same registry for the felix
# marketplace alone, by a line range that assumes the platform's indentation.
# It is left alone because the gate's `installed` check rests on it; this
# reader is the one that also holds on a minified registry. Overridable, as
# the plugin cache is, so the suite reads a fixture and never this machine.
felix_discover_marketplace_file() {
  local mkt="$1" reg="${FELIX_KNOWN_MARKETPLACES:-$HOME/.claude/plugins/known_marketplaces.json}" loc
  [ -n "$mkt" ] && [ -f "$reg" ] || return 0
  loc="$(_felix_json_member "$reg" "" "$mkt" \
    | sed -n 's/.*"installLocation"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  loc="${loc%%
*}"
  [ -n "$loc" ] || return 0
  printf '%s/.claude-plugin/marketplace.json' "$loc"
}

# A plugin's entry in a catalogue, into the file named third, so the manifest
# rules can read it as they read plugin.json. Prints why it could not, and
# returns 1, when the entry could not be read; returns 1 and prints nothing
# when the catalogue does not list the plugin, which is not a failure.
#
# The catalogue naming the plugin while no entry comes out of it is the reader
# failing, and a reader that fails must raise, never pass: that is `unread`.
_felix_discover_entry() {
  local mf="$1" name="$2" out="$3" flat
  [ -f "$mf" ] && [ -r "$mf" ] || { printf 'its catalogue could not be read'; return 1; }
  _felix_json_member "$mf" plugins "$name" > "$out" 2>/dev/null
  [ -s "$out" ] && return 0
  flat="$(LC_ALL=C tr -d ' \t\r\n' < "$mf" 2>/dev/null)"
  case "$flat" in
    *"\"name\":\"$name\""*) printf 'the catalogue names it and no entry could be isolated'; return 1 ;;
  esac
  return 1
}

# Read what a plugin ships and report facts. fact <TAB> detail, one per line.
# What the platform runs on its own comes first — hooks and MCP servers,
# wherever they are declared; the prose and the bundled scripts, which it runs
# only when an agent is told to, come after (_felix_discover_content).
#
# Where hooks and MCP servers are declared is wider than the two default files.
# The manifest can name either one as a path or carry it inline, and a skill or
# command can register hooks in its own frontmatter. Until 2026-09-21 only the
# default files were read, so a manifest pointing `mcpServers` at a file of its
# own was never opened: two of the plugins installed here did exactly that,
# and one of them sends two interpolated API keys to a remote server while it
# was tiered `low`.
#
# The same day's second pass found two more places nothing looked. An LSP
# server, declared in `.lsp.json` or under `lspServers`, is a subprocess the
# platform starts, and neither was read. And a marketplace entry can declare
# all of it inline, outside the plugin's own files: the third and fourth
# arguments are the catalogue and the plugin's name in it, and without them no
# entry is read, which is what every caller did before.
#
# The default files go through the containment rule now as well. They were
# opened wherever a link sent them, while a path the manifest spelled out was
# held to the copy, so the one form nobody has to declare was the one that
# could be pointed off the copy.
felix_discover_inspect() {
  local dir="$1" sub="${2:-}" mfile="${3:-}" name="${4:-}" base f r entry="" why
  base="$dir"
  [ -n "$sub" ] && [ -d "$dir/$sub" ] && base="$dir/$sub"
  if ! (cd "$base" 2>/dev/null); then
    printf 'unread\tthe copy: it did not resolve\n'; return 0
  fi

  for f in hooks/hooks.json .mcp.json mcp.json .lsp.json; do
    if r="$(_felix_discover_inside "$base" "$f")"; then
      case "$f" in
        hooks/*)   _felix_discover_hooks_facts "$r" ;;
        .lsp.json) _felix_discover_lsp_facts "$r" ;;
        *)         _felix_discover_mcp_facts "$r" ;;
      esac
    elif [ "$r" != "no such file" ]; then
      printf 'unread\t%s: %s\n' "$f" "$r"
    fi
  done

  # The entry is written out for the manifest rules to read, beside the copy
  # and never inside it: a byte added to the copy would change its digest.
  # The name is printed through the same filter as every path, for the reason
  # _felix_discover_content gives: a newline in it would end this fact line
  # and let whatever follows be read as another.
  if [ -n "$mfile" ] && [ -n "$name" ]; then
    entry="$(mktemp "${TMPDIR:-/tmp}/felix-entry.XXXXXX" 2>/dev/null)" || entry=""
    if [ -z "$entry" ]; then
      printf 'unread\tthe marketplace entry for %s: no scratch file to read it into\n' "$(printf '%s' "$name" | LC_ALL=C tr '\001-\037\177' '?')"
    elif ! why="$(_felix_discover_entry "$mfile" "$name" "$entry")"; then
      [ -n "$why" ] && printf 'unread\tthe marketplace entry for %s: %s\n' "$(printf '%s' "$name" | LC_ALL=C tr '\001-\037\177' '?')" "$why"
      rm -f "$entry" 2>/dev/null; entry=""
    fi
  fi
  _felix_discover_manifest "$base" "$entry"
  [ -n "$entry" ] && rm -f "$entry" 2>/dev/null
  _felix_discover_frontmatter "$base"

  if [ -d "$base/skills" ]; then
    printf 'skills\t%s\n' "$(ls "$base/skills" 2>/dev/null | wc -l | tr -d ' ')"
    # Named, not only counted. The count feeds the risk read; the names are
    # manifest facts — what the thing ships — and matching on them is what
    # replaces guessing from a listing's prose (Decision C, 2026-08-30).
    # Printed through the same filter as every path below. A directory named
    # `q<newline>skill<TAB>forged` printed raw is a second skill line the
    # author wrote, and skill lines are what the capability matcher adopts
    # on. Found by the blind assertions for the content scan, which were told
    # no fact line could be forged and tested the line this loop prints.
    for f in "$base"/skills/*/; do
      [ -d "$f" ] || continue
      f="${f%/}"
      printf 'skill\t%s\n' "$(_felix_discover_rel "$base/skills" "$f")"
    done
  fi

  _felix_discover_content "$base"
  return 0
}

# What the prose and the bundled scripts say, as facts.
#
# The three files above are what the platform runs on its own. Everything else
# a plugin ships was, until this, never opened: the skill bodies, commands and
# agents a model reads as instructions, and the scripts those instructions tell
# it to run. So a plugin made only of those tiered `low` without one byte of
# its content being read, and admit.sh adopted it wherever a capability
# matched — invariant 4 says "read and judged", and neither had happened.
#
# Four facts, each a pattern and nothing cleverer:
#
#   executables       regular files with an execute bit under scripts/ or
#                     skills/. Counted and reported, never raises on its own:
#                     4 of the 18 installed plugins tiered low ship one, and
#                     one of the four is a package validator its maintainers
#                     run before publishing, which no skill tells an agent to
#                     run.
#   credential-call   a script under scripts/ or skills/ that names a network
#                     call and a credential variable anywhere in the same file.
#                     Invariant 4: anything touching credentials stops for a
#                     person, so this raises to medium and admit.sh holds it.
#   remote-authority  a skill body, command or agent that holds a URL and has
#                     a line calling remote docs or references the authority.
#                     What the agent will then follow is text Felix did not
#                     read and nobody pinned — the prose form of `mcp remote
#                     endpoint`, and medium for the same reason.
#   pipe-to-shell     a skill body, command or agent with a line that pipes
#                     curl or wget into sh, bash or zsh. The agent is told to
#                     run code that was never fetched, read or pinned — the
#                     prose form of `floating`. Medium and not high, for the
#                     reason written at felix_discover_risk.
#
# Measured before the rules were chosen, on the 27 distinct plugins installed
# here on 2026-09-21: the two raising facts move 4 of the 18 low plugins to
# medium, each read by hand and each carrying what its fact names. The full
# measurement is in the pull request that added this. pipe-to-shell came
# after and was measured the same way: its pattern matches prose in 3 of the
# 27, two of them already high, and moves the third — a vendor CLI whose one
# skill installs it from the vendor's own domain — from low to medium.
#
# The ceiling in this file's header holds here unchanged. A pattern reads
# words, and words are chosen by the author: a credential with no variable
# name (ambient cloud login), a URL assembled at run time, an authority claim
# wrapped across two lines, a NUL byte planted to make a script read as
# binary, or a download that reaches the shell some other way — `bash
# <(curl …)`, `sh -c "$(curl …)"`, `| /bin/bash`, a `tee` in between, a file
# saved on one line and run on the next — all pass. None of those shell forms
# appears in the prose installed here. This finds a careless plugin before it
# is installed; it does not find a hostile one.
#
# It can only raise. Every fact is added beside what was already found, and
# felix_discover_risk matches facts by presence, so nothing added here can
# remove a finding that tiered something higher.
#
# Nothing is executed or sourced, and nothing outside the copy is read:
# `find -type f` never lists a symlink, and a top directory that is itself a
# link is walked only when it resolves inside the copy (_felix_discover_root).
# Paths are walked NUL-separated and printed with control characters
# replaced, so a file named with a newline cannot print a fact line of its own
# choosing — a `skill` line forged that way would feed the capability matcher.
_FELIX_DISCOVER_NET='(^|[^A-Za-z0-9_])(curl|wget|npx|uvx|pipx)([^A-Za-z0-9_]|$)|fetch\(|requests\.(get|post|put|patch|delete|request)\(|urlopen\(|urllib\.request|httpx\.|axios|https?\.(get|request)\(|Invoke-WebRequest|Invoke-RestMethod'
_FELIX_DISCOVER_CRED='(^|[^A-Za-z0-9_])[A-Z0-9_]*(API_KEY|APIKEY|_TOKEN|_SECRET|_PASSWORD)([^A-Za-z0-9_]|$)'
# One line, and the shell straight after the first pipe: `| jq`, `| tee`,
# `| shasum` are not it, and neither is a download saved on one line and run
# on the next, which leaves a file that could have been read first.
_FELIX_DISCOVER_PIPE='(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh([^A-Za-z0-9_]|$)'

# A path under the base, printable. Control characters become `?` so that a
# name cannot end the fact line it is printed in.
_felix_discover_rel() {
  printf '%s' "${2#"$1"/}" | LC_ALL=C tr '\001-\037\177' '?'
}

# One of the directories the scan reads, if it may be read: it exists, and if
# it is a link, the link resolves inside the copy. A repository that serves
# several agent platforms often makes `skills` a link to a shared directory,
# and the skill listing above follows that link by glob; walking it with
# `find -P` would list nothing, and a plugin laid out that way would be read
# as having no content — the defect this scan exists to close. A link that
# leaves the copy is not followed: it points at somebody's machine, not at
# what was fetched. Links below the top directory are not followed either.
_felix_discover_root() {
  local base="$1" dir="$1/$2" real target
  [ -d "$dir" ] || return 0
  if [ -L "$dir" ]; then
    real="$(cd "$base" 2>/dev/null && pwd -P)" || return 0
    target="$(cd "$dir" 2>/dev/null && pwd -P)" || return 0
    case "$target/" in "$real"/*) ;; *) return 0 ;; esac
  fi
  printf '%s' "$dir"
}

_felix_discover_content() {
  local base="$1" f r first n=0 roots=""
  for r in scripts skills; do
    r="$(_felix_discover_root "$base" "$r")"
    [ -n "$r" ] && roots="$roots$r
"
  done

  # POSIX -perm rather than `-perm /111` (GNU) or `+111` (BSD): any of the
  # three execute bits, spelled so both finds read it the same way. -H follows
  # a root that is itself a link, which _felix_discover_root has vetted.
  while IFS= read -r -d '' f; do
    n=$((n+1))
  done < <(printf '%s' "$roots" | while IFS= read -r r; do
             find -H "$r" -type f \( -perm -100 -o -perm -010 -o -perm -001 \) -print0 2>/dev/null
           done)
  [ "$n" -gt 0 ] && printf 'executables\t%s\n' "$n"

  # A script is whatever can be run: an execute bit, a #! line, or a name an
  # interpreter takes as given. `<interpreter> scripts/push.py` needs no mode bit, so
  # the bit alone would miss it; measured, widening from the bit to all three
  # added no plugin that was not already high. The first two bytes are read
  # with the builtin, because a skill tree is mostly markdown and a process
  # per file is most of the cost of this whole scan.
  while IFS= read -r -d '' f; do
    case "$f" in
      *.sh|*.bash|*.zsh|*.py|*.js|*.mjs|*.cjs|*.ts|*.rb|*.pl|*.ps1) ;;
      *)
        if [ ! -x "$f" ]; then
          first=""; IFS= read -r -n 2 first < "$f" 2>/dev/null
          [ "$first" = '#!' ] || continue
        fi ;;
    esac
    # A binary is not a script whatever its mode. Compiled binaries carry both
    # words in their string tables — five of semgrep's matched the credential
    # pattern — and say nothing about what a script was written to do. Asked
    # twice: `grep -I` first, which gives up at a NUL in the first buffer and
    # so skips a 16 MB binary for the cost of opening it (semgrep's five took
    # 16 seconds to regex whole); then the whole file, after both patterns
    # matched, because a NUL past the first buffer is still a NUL.
    LC_ALL=C grep -Iq . "$f" 2>/dev/null || continue
    LC_ALL=C grep -qE "$_FELIX_DISCOVER_NET" "$f" 2>/dev/null || continue
    LC_ALL=C grep -qE "$_FELIX_DISCOVER_CRED" "$f" 2>/dev/null || continue
    LC_ALL=C tr -d '\000' < "$f" 2>/dev/null | cmp -s - "$f" || continue
    printf 'credential-call\t%s\n' "$(_felix_discover_rel "$base" "$f")"
  done < <(printf '%s' "$roots" | while IFS= read -r r; do
             find -H "$r" -type f -print0 2>/dev/null
           done)

  # One line has to carry both the claim and what it is a claim about. Of the
  # 24 lines in the installed skills, commands and agents that say "source of
  # truth", 19 name no remote thing ("the codebase is treated as the primary
  # source of truth"); plural nouns only, because "source" is inside "source
  # of truth" and "reference" is usually a reference implementation.
  #
  # The same walk asks the pipe-to-shell question of the same files, so the
  # prose is listed once and each fact is decided on its own.
  while IFS= read -r -d '' f; do
    if LC_ALL=C awk '
      { l = tolower($0) }
      l ~ /https?:\/\// { url = 1 }
      l ~ /source of truth|authoritative|always (trust|fetch|read|consult|check)|must (fetch|read|consult)/ &&
        (l ~ /https?:\/\// || l ~ /(^|[^a-z0-9_])(docs|documentation|references|sources)([^a-z0-9_]|$)/) { hit = 1 }
      END { exit !(url && hit) }' "$f" 2>/dev/null; then
      printf 'remote-authority\t%s\n' "$(_felix_discover_rel "$base" "$f")"
    fi
    if LC_ALL=C grep -qE "$_FELIX_DISCOVER_PIPE" "$f" 2>/dev/null; then
      printf 'pipe-to-shell\t%s\n' "$(_felix_discover_rel "$base" "$f")"
    fi
  done < <( r="$(_felix_discover_root "$base" skills)"
            [ -n "$r" ] && find -H "$r" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print0 2>/dev/null
            for r in commands agents; do
              r="$(_felix_discover_root "$base" "$r")"
              [ -n "$r" ] && find -H "$r" -type f -name '*.md' -print0 2>/dev/null
            done )
  return 0
}

# What a copy of a plugin IS, as one line, computed from the bytes on disk.
#
# Invariant 4 says Felix installs what it has read and judged low-risk. That is
# literally false today and has been since the day it was written: `discover`
# fetches a candidate at its pinned sha into a scratch directory and reads
# THAT, and `claude plugin install` then fetches its own copy from the
# marketplace. Two fetches, no comparison. "What it read" and "what it
# installed" are two different objects that have never once been shown to be
# the same object.
#
# This is what makes them comparable. Every file under the copy — its path,
# whether it is executable, and the hash of its contents — in C order, hashed
# as one document. Same bytes in the same places, same digest.
#
# The comparison cannot be done by re-fetching later, which is why the digest
# has to be taken at read time and kept. Measured: `claude plugin list --json
# --available` omits everything already installed, so the moment a plugin is
# installed its source coordinates stop being reachable from the catalogue.
# The recorded digest is the only surviving account of what was read.
#
# Two exclusions, both measured on this machine rather than assumed:
#
#   .git     is the fetch's own machinery. It is in the scratch copy because
#            that copy was cloned, and in no installed copy.
#
#   .in_use  is written INTO the installed copy by the platform: one file per
#            running session, named by pid. Four of them under
#            claude-code-setup, none belonging to the plugin. A digest that
#            counted those would change every session, and a check that cries
#            wolf is a check somebody switches off.
#
# Nothing else is normalised, because nothing else needed to be: three plugins
# present both in the marketplace checkout and in the install cache are
# byte-identical once `.in_use` is dropped. The installer is a straight copy,
# so any other difference is a real difference and is meant to be caught.
#
# Symlinks are digested as their target rather than followed. A link swapped
# to point somewhere else is exactly the kind of change this exists to see,
# and `find -type f` would not have seen it at all.
#
# No files is no digest, and no digest is not an empty one. An empty document
# hashes to a perfectly good sha that every other empty directory also has, so
# returning it would say two things are the same copy when neither was read.
felix_discover_digest() {
  local dir="$1" sub="${2:-}" base listing
  base="$dir"
  [ -n "$sub" ] && [ -d "$dir/$sub" ] && base="$dir/$sub"
  [ -d "$base" ] || return 1
  listing="$(
    cd "$base" 2>/dev/null || exit 1
    find . \( -type f -o -type l \) ! -path './.git/*' ! -path './.in_use/*' -print 2>/dev/null \
    | LC_ALL=C sort \
    | while IFS= read -r f; do
        if [ -L "$f" ]; then
          printf 'l %s %s\n' "$(readlink "$f" 2>/dev/null)" "$f"
        elif [ -x "$f" ]; then
          printf 'x %s %s\n' "$(git hash-object "$f" 2>/dev/null)" "$f"
        else
          # `f`, not `-`. A format string beginning with a dash is an
          # OPTION to printf, and this shipped as `- %s %s` for exactly as
          # long as it took to run it: every ordinary file failed to emit,
          # the listing came out empty, and the digest was nothing at all.
          # Two nothings compare equal, so the first demonstration showed
          # two identical copies "agreeing" and a changed byte "agreeing"
          # too. A check that cannot fail is not a check.
          printf 'f %s %s\n' "$(git hash-object "$f" 2>/dev/null)" "$f"
        fi
      done
  )"
  [ -n "$listing" ] || return 1
  printf '%s\n' "$listing" | git hash-object --stdin 2>/dev/null
}

# The digest recorded when this candidate was read, or nothing.
#
# Fourth column of the cache row. Absent from every row written before this
# existed, and absent from any row whose fetch failed, and both of those read
# back as nothing — which every caller here treats as "no claim", never as a
# mismatch. A missing record is not evidence of drift.
felix_discover_read_digest() {
  local proj="$1" home="$2" want="$3" cache name cap risk digest
  [ -n "$want" ] || return 0
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  [ -f "$cache" ] || return 0
  while IFS=$'\t' read -r name cap risk digest; do
    [ "${name:-}" = "$want" ] || continue
    [ -n "${digest:-}" ] || return 0
    printf '%s' "$digest"
    return 0
  done < "$cache"
  return 0
}

# Does the copy on disk match the copy that was read? state <TAB> detail.
#
#   same     the installed bytes are the bytes discovery read and judged
#   drift    they are not, and the tier on file was scored from other bytes
#   unread   nothing was recorded for this name, so nothing is claimed
#   absent   nothing is installed under this name
#
# `drift` is not an accusation either. A marketplace that moves its `main`
# while leaving the version string alone produces it honestly, and measured
# here that is the common case: claude-code-setup is installed at 1.0.0 and
# its source at 1.0.0 has gained rows the installed copy does not have. What
# the state says is that the reading is stale, not that somebody lied.
# The fourth argument is the registry to ask, and it exists so that this can
# be shown failing. A function that can only read $HOME's real registry is one
# nobody can write a control for, and a check nobody can make fail is not a
# check. Callers pass nothing and get the real one.
felix_discover_drift() {
  local proj="$1" home="$2" name="$3" reg="${4:-}" read_digest path now
  # The registry is asked first, and the order was decided rather than fallen
  # into. A name with no recorded digest AND nothing installed is honestly
  # either state, and the blind author of these assertions stopped at exactly
  # that overlap and refused to assert through it. The caller that matters
  # settles it: `--adopt` asks this question one line after installing, and
  # `absent` there means the install did not register — a different failure
  # from "the fetch produced no digest", and the one that would otherwise hide
  # behind `unread`. So: no copy on disk is answered before anything is said
  # about what was read.
  if [ -n "$reg" ]; then
    path="$(felix_registry_field "$name" installPath "$reg" 2>/dev/null)"
  else
    path="$(felix_registry_field "$name" installPath 2>/dev/null)"
  fi
  if [ -z "$path" ] || [ ! -d "$path" ]; then
    printf 'absent\t%s is not installed\n' "$name"; return 0
  fi
  now="$(felix_discover_digest "$path")" || now=""
  if [ -z "$now" ]; then
    printf 'unread\tthe installed copy of %s has no files to read\n' "$name"; return 0
  fi
  read_digest="$(felix_discover_read_digest "$proj" "$home" "$name")"
  if [ -z "$read_digest" ]; then
    printf 'unread\tno digest was recorded when %s was read\n' "$name"; return 0
  fi
  if [ "$now" = "$read_digest" ]; then
    printf 'same\t%s\n' "$read_digest"
  else
    printf 'drift\tread %s, installed %s\n' "$read_digest" "$now"
  fi
  return 0
}

# Facts in, tier out. Same three tiers stack.tsv already uses, so a discovered
# row can be pasted into it unchanged.
#
# Highest first, and every rule is a presence test, which is what makes the
# content facts raise-only: adding a line to the facts can make a pattern
# match, never stop one matching. `executables` is deliberately absent. It is
# a disclosure, not a tier: a script nobody's prose sends a credential through
# is still a script the agent runs only when told to, under its own
# permissions, and raising on it would hold 4 of the 18 low plugins
# measured here to ask a question with no answer in it.
#
# `pipe-to-shell` is medium, and high was the other candidate: what it runs is
# what `floating` names, code nobody read or pinned. What puts a fact in the
# high block is that it acts with nobody choosing at the time — hooks fire
# every session, a floating MCP command is resolved afresh at every session
# start, an interpolated variable is sent whenever the server starts, and an
# `unread` declaration is hooks or servers nobody saw, so it may be any of
# those. A
# download piped into a shell runs when the agent follows the line, as one
# command naming the host it trusts, and whether to trust that host is a
# question a person can answer, which is what medium holds a plugin for. And
# the pattern cannot tell an instruction from a warning: of the five prose
# files it matched in the 27 plugins installed here on 2026-09-21, three
# forbid piping a download into a shell. At medium that error costs a person
# a look. At high it would refuse such a plugin by every flag, with no row a
# person wrote able to admit it, for warning against the thing.
felix_discover_risk() {
  local facts="$1"
  case "$facts" in
    *"unread	"*)       printf 'high';   return ;;
    *"hooks	"*)        printf 'high';   return ;;
    *"floating	"*)     printf 'high';   return ;;
    *"interpolates	"*) printf 'high';   return ;;
  esac
  # An LSP server beside an MCP one: both are a local process the platform
  # starts on its own, with this user's rights, and neither runs on every
  # session event or sees every tool call the way a hook does.
  case "$facts" in
    *"mcp	"*|*"lsp	"*)      printf 'medium'; return ;;
    *"credential-call	"*)  printf 'medium'; return ;;
    *"remote-authority	"*) printf 'medium'; return ;;
    *"pipe-to-shell	"*)    printf 'medium'; return ;;
  esac
  printf 'low'
}

# Why a tier was chosen, in the words of what was actually found.
felix_discover_why() {
  local facts="$1" out=""
  case "$facts" in *"unread	"*)
    out="$out; something it declares was not read ($(printf '%s\n' "$facts" | awk -F'\t' '$1 == "unread" && !n++ { print $2 }'))" ;; esac
  case "$facts" in *"hooks	"*)
    out="$out; ships hooks, which run on your machine every session" ;; esac
  case "$facts" in *"floating	"*)
    out="$out; unpinned version, so its code can change with no manifest change" ;; esac
  case "$facts" in *"interpolates	"*)
    out="$out; interpolates an environment variable, check what it sends where" ;; esac
  case "$facts" in *"mcp	remote"*)
    out="$out; talks to a remote endpoint" ;; esac
  case "$facts" in *"mcp	local"*)
    out="$out; runs a local subprocess" ;; esac
  case "$facts" in *"lsp	"*)
    local c; c="$(printf '%s\n' "$facts" | awk -F'\t' '$1 == "lsp-command" && !n++ { print $2 }')"
    out="$out; runs a local language server${c:+ ($c)}, started when a file it claims is opened" ;; esac
  case "$facts" in *"credential-call	"*)
    out="$out; a bundled script names a credential beside a network call ($(printf '%s\n' "$facts" | awk -F'\t' '$1 == "credential-call" && !n++ { print $2 }'))" ;; esac
  case "$facts" in *"remote-authority	"*)
    out="$out; its prose makes live remote pages the authority, and those were not read ($(printf '%s\n' "$facts" | awk -F'\t' '$1 == "remote-authority" && !n++ { print $2 }'))" ;; esac
  case "$facts" in *"pipe-to-shell	"*)
    out="$out; its prose pipes a download into a shell, code nobody read or pinned ($(printf '%s\n' "$facts" | awk -F'\t' '$1 == "pipe-to-shell" && !n++ { print $2 }'))" ;; esac
  case "$facts" in *"executables	"*)
    out="$out; ships $(printf '%s\n' "$facts" | awk -F'\t' '$1 == "executables" && !n++ { print $2 }') executable file(s), read by pattern only" ;; esac
  printf '%s' "${out#; }"
}

# ---------------------------------------------------------------- cadence ---
#
# Inspection fetches over the network and takes seconds per candidate, so it
# cannot sit in front of a prompt. "Automatic" honestly means: run between
# sessions, cache the answer, and speak only when the answer changed.
#
# Nothing here installs, and nothing here blocks. A refresh that fails leaves
# the previous answer in place, which is the right trade for a background job
# nobody is watching.

FELIX_DISCOVER_STALE_DAYS="${FELIX_DISCOVER_STALE_DAYS:-7}"

_felix_discover_cache() { printf '%s/state/discover/%s' "$2" "$(basename "$1")"; }

# The cache carries the provenance of the verdicts in it. Its rows are
# (name, capability, tier) computed by the matcher against the rules table at
# the time it was written, and on the first live commissioning run a cache
# from five days earlier — written by a matcher that has since been fixed —
# declared and installed a storage plugin under llm, twice: the fix to the
# matcher changed nothing the adopt path read. So the first line is a stamp
# over the rules table and the engine version, and every reader treats a
# cache whose stamp is not the current one as ABSENT, which the foreground
# fill in discover --adopt then recomputes. A stale verdict is not a verdict.
_felix_discover_stamp() {
  local tpl="${1:-$(dirname "${BASH_SOURCE[0]:-$0}")/../templates}" ver
  ver="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
          "$(dirname "${BASH_SOURCE[0]:-$0}")/../../.claude-plugin/plugin.json" 2>/dev/null | head -1)"
  { printf 'matcher=words\nengine=%s\n' "${ver:-?}"; cat "$tpl/discover-rules.tsv" 2>/dev/null; } \
    | git hash-object --stdin 2>/dev/null
}
_felix_discover_stamp_line() { printf '# stamp %s\n' "$(_felix_discover_stamp "${1:-}")"; }

# 0 when the cache exists and was written under the current rules and engine.
felix_discover_cache_current() {
  local proj="$1" home="$2" tpl="${3:-}" cache first
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  [ -f "$cache" ] || return 1
  first="$(head -1 "$cache" 2>/dev/null)"
  [ "$first" = "$(_felix_discover_stamp_line "$tpl" | tr -d '\n')" ]
}

# What a thing looks like, scored once.
#
# There were two of these and they drifted, which is how a plugin was installed
# under a capability it does not have: one scored a marketplace blurb, the other
# scored the name alone, and nothing said they were supposed to agree. A name
# counts triple because it is what a thing IS; a skill name counts triple
# because it is what a thing SHIPS — a manifest fact read off the copy on disk,
# not a word chosen to be found by (Decision C, 2026-08-30); prose counts
# single because it is what a thing mentions.
#
# The fourth argument is optional — skill names, one per line — and every
# caller that has a copy on disk should pass it, because the same read that
# scored the risk already yielded the list.
#
# Emits: score <TAB> capability. The caller applies its own threshold, because
# what is worth reporting and what is worth installing are different bars.
#
# A keyword is a WORD. The first version matched substrings over the token
# string, and on the first live commissioning run `rag` — a keyword of the
# llm rule — matched the name google-cloud-sto*rag*e, scored the name hit of
# 3 that is also the adoption threshold, and a storage plugin was declared
# and installed under llm. The tokeniser now splits on everything that is
# not a letter or digit, hyphens included, so `observability-tool` still
# matches `observability`, and a keyword with a hyphen (`rest-api`) is
# matched as the two-word phrase it tokenises to. `eval` no longer matches
# `evaluation` or `evaltool`, and is not meant to: a keyword that matches
# inside other words is a keyword that matches by accident.
_felix_cap_tokens() { printf ' %s ' "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' ' ' | sed 's/^ *//; s/ *$//')"; }
felix_capability_match() {
  local name="$1" desc="$2" rules="$3" skills="${4:-}"
  local nhay dhay shay cap kws kw kwn score hit best=0 best_cap=""
  nhay="$(_felix_cap_tokens "$name")"
  dhay="$(_felix_cap_tokens "$desc")"
  shay="$(_felix_cap_tokens "$skills")"
  while IFS=$'\t' read -r cap kws; do
    [ -n "${cap:-}" ] || continue
    score=0
    for kw in $kws; do
      hit=0
      kwn="$(_felix_cap_tokens "$kw")"
      [ "$kwn" != "  " ] || continue
      case "$nhay" in *"$kwn"*) score=$((score+3)); hit=1 ;; esac
      case "$shay" in *"$kwn"*) score=$((score+3)); hit=1 ;; esac
      [ "$hit" -eq 1 ] && continue
      case "$dhay" in *"$kwn"*) score=$((score+1)) ;; esac
    done
    if [ "$score" -gt "$best" ]; then best="$score"; best_cap="$cap"; fi
  done <<EOF
$rules
EOF
  printf '%s\t%s' "$best" "$best_cap"
}

# What a plugin says about itself, from the copy on disk.
#
# Preferred over the marketplace listing wherever both exist. The listing is
# written to be chosen from; the manifest is written to describe. Scoring the
# blurb is how a tracing plugin and an inference provider were both filed under
# the capability of the project that happened to be looking.
felix_plugin_description() {
  local dir="$1"
  [ -f "$dir/.claude-plugin/plugin.json" ] || return 0
  sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    "$dir/.claude-plugin/plugin.json" 2>/dev/null | head -1
}

# What discovery has already read, judged, and would declare.
#
# Everything expensive is done by the time this runs: the candidate was fetched
# at its pinned sha, its contents were read, and a risk tier was scored from
# what it actually ships. Stopping there and printing a shopping list was the
# governance charter talking. Declaring is a manifest edit, which detection was
# always permitted to do unattended, and the founder is not supposed to be
# thinking about tooling at all.
#
# Low only. Medium means it ships an MCP server, which usually needs credentials
# a person has to supply anyway, or a script or prose that reaches past what
# was read (a credentialed network call, remote pages made the authority, a
# download piped into a shell);
# high means hooks, a floating version, or an interpolated secret, and no flag
# from any caller installs those.
#
# Emits: action <TAB> name <TAB> capability <TAB> risk
#   declare  low risk, not yet in stack.tsv
#   refuse   medium or high
#   already  named in stack.tsv, whatever the tier
felix_discover_adopt() {
  local proj="$1" home="$2" tpl="${3:-}" cache name cap risk digest declared
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  felix_discover_cache_current "$proj" "$home" "$tpl" || return 0

  # Compared without the marketplace suffix, the same way candidates are
  # filtered, so langfuse@x already declared matches a langfuse candidate.
  declared="$(grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null \
              | cut -f2 | sed 's/@.*//')"

  # Four fields, and the fourth is read even though this function does not use
  # it. A three-field read hands `low<TAB><digest>` to `risk` whole, no tier
  # matches, and every candidate is dropped in silence — the cache would still
  # parse, and adoption would quietly stop happening.
  while IFS=$'\t' read -r name cap risk digest; do
    # The cache is not always rows. When nothing matches, discovery writes prose
    # into it explaining why, and a parser that adopted a sentence would be
    # worse than one that adopted nothing. Three fields and a known tier, or it
    # is not a candidate.
    [ -n "${name:-}" ] && [ -n "${cap:-}" ] || continue
    case "$name" in '#'*) continue ;; esac
    case "${risk:-}" in low|medium|high) ;; *) continue ;; esac
    case "$name" in *' '*) continue ;; esac
    # `-` is inspection's own verdict: the copy on disk ships nothing serving
    # any declared capability, whatever the catalogue blurb promised. Declaring
    # and installing under `-` would act on the claim inspection just refuted,
    # and the row would sit in stack.tsv permanently dormant.
    [ "$cap" = "-" ] && continue

    # Self-contained on purpose: this file is sourced alone by the suite, and a
    # helper from a sibling lib turns that into a runtime error rather than a
    # failing assertion. grep without -q for the usual reason — a consumer that
    # exits on its first match kills the producer under `set -o pipefail`.
    if printf '%s\n' "$declared" | grep -xF "$name" >/dev/null 2>&1; then
      printf 'already\t%s\t%s\t%s\n' "$name" "$cap" "$risk"; continue
    fi
    # A cache row was tiered by this engine reading what the candidate ships,
    # so the policy is asked as OBSERVED. `hold` and `refuse` both read
    # `refuse` here: this command's caller can only declare or not, and the
    # difference between "a person decides" and "nobody may" belongs to the
    # report, not to a manifest edit that either happens or does not.
    case "$(felix_admit "$risk" OBSERVED)" in
      install) printf 'declare\t%s\t%s\t%s\n' "$name" "$cap" "$risk" ;;
      *)       printf 'refuse\t%s\t%s\t%s\n'  "$name" "$cap" "$risk" ;;
    esac
  done < "$cache"
}

# Every cached name whose installed copy is not the copy that was read.
# name <TAB> detail, and nothing at all when nothing has moved.
#
# The install-time check answers "did the installer hand me the bytes I read".
# This answers the other half, which is the half that was actually measured:
# of five plugins present both in the marketplace checkout and in the install
# cache on this machine, two had drifted — a marketplace advanced its branch
# and left the version string at 1.0.0, so the copy on disk stopped being the
# copy that was judged and nothing anywhere said so. A digest nobody ever
# compares is a record, not a check.
felix_discover_drifted() {
  local proj="$1" home="$2" reg="${3:-}" cache name cap risk digest line state detail
  cache="$(_felix_discover_cache "$proj" "$home").tsv"
  [ -f "$cache" ] || return 0
  while IFS=$'\t' read -r name cap risk digest; do
    [ -n "${name:-}" ] || continue
    case "$name" in '#'*) continue ;; esac
    [ -n "${digest:-}" ] || continue
    line="$(felix_discover_drift "$proj" "$home" "$name" "$reg")"
    state="$(printf '%s' "$line" | cut -f1)"
    detail="$(printf '%s' "$line" | cut -f2-)"
    [ "$state" = "drift" ] || continue
    printf '%s\t%s\n' "$name" "$detail"
  done < "$cache"
  return 0
}

# Has the cache aged out, or never existed?
felix_discover_stale() {
  local f; f="$(_felix_discover_cache "$1" "$2").tsv"
  [ -f "$f" ] || return 0
  # Stale by provenance before stale by age: a cache the current rules and
  # engine did not write is due for a refresh whatever its mtime says.
  felix_discover_cache_current "$1" "$2" "${3:-}" || return 0
  local age
  age="$(find "$f" -mtime +"$FELIX_DISCOVER_STALE_DAYS" 2>/dev/null)"
  [ -n "$age" ]
}

# Refresh in the background, at most one at a time. The lock is a directory
# because mkdir is atomic everywhere and a stale lock file is not.
felix_discover_refresh_bg() {
  local proj="$1" home="$2" felix_bin="$3"
  local dir lock
  dir="$home/state/discover"
  lock="$dir/.lock"
  mkdir -p "$dir" 2>/dev/null || return 0
  mkdir "$lock" 2>/dev/null || return 0   # already running; leave it alone
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    felix_close_inherited_fds
    cd "$(felix_repo_root "$PWD")" 2>/dev/null || exit 0
    # A refresh that could not read the marketplaces exits non-zero and writes
    # nothing, and the previous answer stands: an unreadable catalogue is not
    # an empty one, and must not become one for seven days.
    if "$felix_bin" discover --inspect --quiet > "$(_felix_discover_cache "$proj" "$home").new.$$" 2>/dev/null; then
      mv -f "$(_felix_discover_cache "$proj" "$home").new.$$" \
            "$(_felix_discover_cache "$proj" "$home").tsv" 2>/dev/null
    else
      rm -f "$(_felix_discover_cache "$proj" "$home").new.$$" 2>/dev/null
    fi
  ) </dev/null >/dev/null 2>&1 &
  return 0
}

# Findings not yet mentioned. Reporting the same three plugins every session is
# how a useful signal becomes wallpaper.
felix_discover_unseen() {
  local proj="$1" home="$2" base cache seen
  base="$(_felix_discover_cache "$proj" "$home")"
  cache="$base.tsv"; seen="$base.seen"
  [ -s "$cache" ] || return 0
  felix_discover_cache_current "$proj" "$home" || return 0
  if [ -f "$seen" ]; then
    LC_ALL=C comm -23 <(grep -v '^#' "$cache" | cut -f1 | LC_ALL=C sort -u) \
                      <(LC_ALL=C sort -u "$seen") 2>/dev/null
  else
    grep -v '^#' "$cache" | cut -f1 | LC_ALL=C sort -u
  fi
}

felix_discover_mark_seen() {
  local base; base="$(_felix_discover_cache "$1" "$2")"
  [ -s "$base.tsv" ] || return 0
  grep -v '^#' "$base.tsv" | cut -f1 | LC_ALL=C sort -u >> "$base.seen" 2>/dev/null
  LC_ALL=C sort -u -o "$base.seen" "$base.seen" 2>/dev/null
  return 0
}

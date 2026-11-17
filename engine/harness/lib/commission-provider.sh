# Commissioning providers: a skill a session's model runs, ingested offline.
#
# Two of the rows in commissioning.tsv name providers — the claude-md-improver
# and claude-automation-recommender skills — and the engine can run neither:
# both are model-driven, and the enforcing path is bash and git with no model
# (constitution invariant 2). So the protocol is the one the amendments give
# discovery (§1.3): the engine WRITES a request into the memory root, a
# session's model runs the skill and writes an answer file beside it, and the
# engine reads that file with no model and no network. The window between
# request and answer is held by `awaiting`, which is UNKNOWN by class, holds
# nothing, and never reaches the receipt.
#
# An answer is keyed to the TOPOLOGY it was written for — a hash over the
# detected and declared surfaces and the commissioning table, which ingestion
# never writes, so ingesting cannot rotate the key its own answers carry. An
# answer for another topology is `stale` and is not read. An answer without
# its terminal `done <count>` row is `partial`: a skill that stopped halfway
# has not answered. Every row read is INFERRED, carries the file's hash and
# the provider plugin's version and commit as provenance, and installs
# nothing: the admit phase that fetches, reads, tiers and corroborates a
# nomination is the next increment, and until it lands an answered row is a
# record and nothing else.

if ! command -v felix_commission_rows >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/commission.sh"
fi
# commission.sh loads resolve.sh only when felix_mem_dir is missing, so a
# resolve.sh older than felix_end_line would satisfy it, and every declare below
# would then be refused as an append that failed. Keyed on what this file calls.
if ! command -v felix_end_line >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

FELIX_COMMISSION_PROVIDER_KINDS='plugin mcp hook skill subagent'
FELIX_COMMISSION_PROVIDER_MAX="${FELIX_COMMISSION_PROVIDER_MAX:-40}"

# Ceilings on the free-text fields, and the reason they exist at all is the
# log rather than the reader. An accepted row is appended to commissioning.log,
# which is append-only and outlives the answer file the next topology rewrites
# — so a field the log cannot hold whole is not clipped, it is lost. The line
# was bounded at a flat 160 characters, which cut a 238-character sentence
# mid-word while the row still read as accepted.
#
# Bounding the fields and deriving the log's own limit from them is what makes
# these one fact instead of two that drift. The rule the flat number broke is
# #156's: the request states every constraint the reader enforces, so all
# three are written into the request template beside the others.
# Is this exactly one of the known kinds?
#
# The test was `case " $FELIX_COMMISSION_PROVIDER_KINDS " in *" $kind "*`, a
# space-padded substring, so any contiguous RUN of the list passed: `plugin
# mcp`, `mcp hook`. Not cosmetic — felix_commission_admit refuses an mcp row by
# matching the kind exactly, so a row spelled `plugin mcp` skipped that refusal
# and reached the fetch, which is the one thing spec §7 T3 says must never be
# activated unattended. Word-splitting the list compares whole tokens, and a
# kind containing a space can never equal one.
_felix_commission_kind_ok() {
  local one
  for one in $FELIX_COMMISSION_PROVIDER_KINDS; do [ "$1" = "$one" ] && return 0; done
  return 1
}

FELIX_COMMISSION_PROVIDER_SRC_MAX="${FELIX_COMMISSION_PROVIDER_SRC_MAX:-200}"
FELIX_COMMISSION_PROVIDER_CAP_MAX="${FELIX_COMMISSION_PROVIDER_CAP_MAX:-64}"
FELIX_COMMISSION_PROVIDER_WHY_MAX="${FELIX_COMMISSION_PROVIDER_WHY_MAX:-300}"
# source, capability and why, joined by two single-space separators, plus room
# for the `<kind> <name>: ` prefix. Derived, never written down twice.
FELIX_COMMISSION_PROVIDER_LOG_MAX=$(( FELIX_COMMISSION_PROVIDER_SRC_MAX \
                                    + FELIX_COMMISSION_PROVIDER_CAP_MAX \
                                    + FELIX_COMMISSION_PROVIDER_WHY_MAX + 2 ))

# The over-length field of a five-field row, or nothing. Shared by the reader
# and the refusal report so the two can never disagree about which row is too
# long — the failure that reads as "refused for no stated reason".
_felix_commission_provider_toolong() {   # line -> "<field> <limit>" or empty
  local line="$1" src cap why LC_ALL=C
  src="$(printf '%s\n' "$line" | LC_ALL=C cut -f3)"
  cap="$(printf '%s\n' "$line" | LC_ALL=C cut -f4)"
  why="$(printf '%s\n' "$line" | LC_ALL=C cut -f5)"
  [ "${#src}" -gt "$FELIX_COMMISSION_PROVIDER_SRC_MAX" ] \
    && { printf 'source %s' "$FELIX_COMMISSION_PROVIDER_SRC_MAX"; return 0; }
  [ "${#cap}" -gt "$FELIX_COMMISSION_PROVIDER_CAP_MAX" ] \
    && { printf 'capability %s' "$FELIX_COMMISSION_PROVIDER_CAP_MAX"; return 0; }
  [ "${#why}" -gt "$FELIX_COMMISSION_PROVIDER_WHY_MAX" ] \
    && { printf 'why %s' "$FELIX_COMMISSION_PROVIDER_WHY_MAX"; return 0; }
  return 0
}

# The topology an answer is keyed to. Inputs ingestion never writes.
#
# 0 with the hash on stdout. 2 with nothing printed when the declared list could
# not be read, or the union of it and what felix_detect shows could not be made,
# and nowhere else: otherwise the status is the hash's. Until 2026-10-01 an
# unread list hashed a different list, so every provider answer read stale, and a
# request was written under a topology that was not the project's. The status is
# not taken from the `cat` of commissioning.tsv, which is 1 for a project without
# one, so under pipefail (the CLI and the hooks) a list that was read would come
# back as one that was not; a missing table is `|| :`. What is hashed is the
# same bytes as before on a list that was read: the union a line each, nothing
# for none, as the sort printed it. The list is read here, the union built here,
# and the hash is _felix_commission_topology_of's, which felix_commission_request
# asks directly with the union it already holds.
felix_commission_topology() {
  local proj="$1" root="$2" declared="" union=""
  felix_declared_into declared "$proj" || return 2
  felix_capture union _felix_capability_union "$root" "$declared" || return 2
  _felix_commission_topology_of "$union" "$proj"
}

# UNION PROJ: the hash of the topology, and nothing else. UNION is the capabilities
# the checkout shows and the project declares, one to a line as _felix_capability_union
# printed them, and the bytes hashed are those lines, the line `== commissioning.tsv ==`
# and the table. Split out on 2026-10-08, when felix_commission_request read the
# declared list and built the union, and then called felix_commission_topology, which
# read the list and built the union again: two reads, so the names in a request could
# come from one and its topology from another. The status is the hash's; a missing
# table is `|| :`, as above.
#
# The table is read only as a regular file. A pipe at the path held the cat
# open for a writer that never came, and a link to a device read without
# end (2026-10-01). Skipped, it hashes as an absent table hashed before, so
# no hash over ordinary files moves and no keyed answer goes stale.
_felix_commission_topology_of() {
  { [ -z "$1" ] || printf '%s\n' "$1"
    printf '== commissioning.tsv ==\n'
    if [ -f "$2/commissioning.tsv" ]; then cat "$2/commissioning.tsv" 2>/dev/null || :; fi; } | _felix_hash
}

_felix_commission_provider_dir() { printf '%s/commission' "$(felix_mem_dir "$1")"; }
felix_commission_answer_path()  { printf '%s/%s.tsv' "$(_felix_commission_provider_dir "$1")" "$2"; }
felix_commission_request_path() { printf '%s/requests/%s.md' "$(_felix_commission_provider_dir "$1")" "$2"; }

# Render the request for one need from its template, into the memory root.
# Placeholders are substituted the way setup runbooks substitute {{REPO}}.
# Prints the path. Returns 1 when the template is absent — a provider row
# with no request template is a row nobody can answer, and the state says so.
#
# And 2 when the declared list could not be read, with nothing printed and
# nothing written, a request already there left as it was. Until 2026-10-01 an
# unread list gave a request naming the wrong capabilities under the wrong
# topology, and a session that answered it was answering another question. The
# template is still checked first, so no template is 1 whatever the list. The
# list, the union of it with what felix_detect shows, and the topology are each
# captured with felix_capture, since a substitution can end with nothing printed
# and status 0 when its fork fails, and the capabilities the request names are
# that union with its lines joined, by an expansion and not a pipeline whose
# status nobody asks. The topology is the hash of that same union, from
# _felix_commission_topology_of, so the list is read once and the request holds
# the topology of the list whose capabilities it names. Until 2026-10-08 it asked
# felix_commission_topology, which read the list and built the union again.
felix_commission_request() {
  local proj="$1" root="$2" need="$3" tpl="$4" src out caps declared topo dcl="" union=""
  src="$tpl/commission/$need.md"
  [ -f "$src" ] || return 1
  felix_declared_into dcl "$proj" || return 2
  felix_capture union _felix_capability_union "$root" "$dcl" || return 2
  felix_capture topo _felix_commission_topology_of "$union" "$proj" || return 2
  out="$(felix_commission_request_path "$proj" "$need")"
  mkdir -p "$(dirname "$out")" 2>/dev/null || return 1
  caps="${union//$'\n'/ }"
  # stack.tsv only as a regular file, as felix_commission_apply_declares reads
  # it; a pipe at the path held this grep open (2026-10-01).
  declared=""
  [ -f "$proj/stack.tsv" ] && declared="$(LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | LC_ALL=C cut -f2 | LC_ALL=C tr '\n' ' ')"
  # Three placeholders the obligations request needs, computed only when the
  # template names them: the decision epoch, the probe rows as a session can
  # read them, and the admitted ledger. Each may hold newlines, backslashes
  # and `&`, none of which survive `awk -v` or a gsub replacement intact, so
  # they travel through the environment and are spliced by index rather than
  # by pattern.
  local epoch="" probes="" admitted=""
  if LC_ALL=C grep -q '{{EPOCH}}\|{{PROBES}}\|{{ADMITTED}}' "$src" 2>/dev/null; then
    command -v felix_epoch >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/epoch.sh"
    command -v felix_obligation_rows >/dev/null 2>&1 || . "$(dirname "${BASH_SOURCE[0]:-$0}")/obligations.sh"
    epoch="$(felix_epoch "$proj" "$root" 2>/dev/null)" || epoch=""
    probes="$(felix_probes_run "$proj" "$root" 2>/dev/null \
      | LC_ALL=C awk -F'\t' '{ printf "    %-20s %-15s %5s  %s\n", $1, $3, $4, $6 }')"
    admitted="$(felix_obligation_rows "$proj" 2>/dev/null | LC_ALL=C awk -F'\t' '{ printf "    %s (%s): %s\n", $1, $2, $7 }')"
  fi
  FELIX_TPL_EPOCH="${epoch:-unknown}" FELIX_TPL_PROBES="${probes:-    (no probes declared)}" \
  FELIX_TPL_ADMITTED="${admitted:-    (nothing admitted yet)}" \
  LC_ALL=C awk -v project="$(basename "$proj")" -v pdir="$proj" -v root="$root" -v caps="$caps" \
      -v declared="${declared% }" -v topo="$topo" -v ans="$(felix_commission_answer_path "$proj" "$need")" '
    function splice(line, ph, val,   i, out) {
      out = ""
      while ((i = index(line, ph)) > 0) { out = out substr(line, 1, i - 1) val; line = substr(line, i + length(ph)) }
      return out line
    }
    { gsub(/\{\{PROJECT\}\}/, project); gsub(/\{\{PROJ_DIR\}\}/, pdir); gsub(/\{\{ROOT\}\}/, root)
      gsub(/\{\{CAPS\}\}/, (caps == "" ? "nothing yet" : caps)); gsub(/\{\{DECLARED\}\}/, (declared == "" ? "nothing" : declared))
      gsub(/\{\{TOPOLOGY\}\}/, topo); gsub(/\{\{OUT\}\}/, ans)
      $0 = splice($0, "{{EPOCH}}", ENVIRON["FELIX_TPL_EPOCH"])
      $0 = splice($0, "{{PROBES}}", ENVIRON["FELIX_TPL_PROBES"])
      $0 = splice($0, "{{ADMITTED}}", ENVIRON["FELIX_TPL_ADMITTED"])
      print }' "$src" > "$out" 2>/dev/null || return 1
  printf '%s' "$out"
}

# The shape of an answer, decided from the file alone.
# Prints: state <TAB> detail. States: awaiting, stale, partial, answered, and
# unknown when the rows could not be counted. Until 2026-10-01 an empty count,
# as a fork that fails inside its substitution leaves, made the comparison
# with the done line error, which is false, and the answer read answered,
# whole or not, which is the state every ingestion reads. A count is digits or
# it was not taken, and a count over a first grep that failed is not one: the
# second grep counts whatever reached it and prints a number, so the first
# grep's own status is asked too, and the counting grep's, from PIPESTATUS,
# which pipefail does not change. Taken whole into the positional parameters
# first, because the first test resets it.
#
# Also unknown, since 2026-10-01, for an answer file that is there when the
# topology it is keyed to could not be computed. Until then the topology came
# back as another hash, or none, and every answer read stale: a verdict that
# sends a person to run the skill again over a list nobody read. No file is still
# awaiting, whatever the list. The topology is captured with felix_capture, since
# a substitution can end with nothing printed and status 0 when its fork fails.
# The sentence names the declared list, the cause the contract fixes. A union or
# a hash that could not be made, or a capture whose fork failed, is said the same
# way, since the capture cannot tell them apart from a list that was not read.
# Session start prints the sentence as the row's own detail.
# Locale, 2026-10-08: [0-9] let U+2185 through under UTF-8, and an answer read
# whole on a count nobody gave. The rules are above felix_json_str in resolve.sh.
felix_commission_provider_state() {
  local proj="$1" root="$2" need="$3" f first last n rows topo=""
  f="$(felix_commission_answer_path "$proj" "$need")"
  if [ ! -f "$f" ]; then
    printf 'awaiting\tno answer at %s\n' "$f"; return 0
  fi
  first="$(head -1 "$f" 2>/dev/null)"
  if ! felix_capture topo felix_commission_topology "$proj" "$root"; then
    printf 'unknown\tthe topology the answer at %s is keyed to could not be computed: the capabilities this project declares could not be read\n' "$f"; return 0
  fi
  if [ "$first" != "# topology $topo" ]; then
    printf 'stale\tthe answer at %s is for another topology; run the skill again from the request\n' "$f"; return 0
  fi
  last="$(LC_ALL=C grep -vE '^[[:space:]]*$' "$f" | tail -1)"
  rows="$(LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$f" | LC_ALL=C grep -vc $'^done\t'
    set -- "${PIPESTATUS[@]}"; [ "${1:-2}" -le 1 ] && [ "${2:-2}" -le 1 ] || printf '?')"
  n="$(printf '%s' "$last" | LC_ALL=C awk -F'\t' '$1 == "done" && NF == 2 { print $2 }')"
  case "$n" in ''|*[!0123456789]*) printf 'partial\tthe answer at %s has no terminal done row, so the skill did not finish\n' "$f"; return 0 ;; esac
  case "$rows" in ''|*[!0123456789]*) printf 'unknown\tthe rows of the answer at %s could not be counted, so whether it is whole is not known\n' "$f"; return 0 ;; esac
  if [ "$n" -ne "$rows" ]; then
    printf 'partial\tthe answer at %s says done %s and holds %s rows\n' "$f" "$n" "$rows"; return 0
  fi
  printf 'answered\t%s rows at %s\n' "$rows" "$f"
}

# Rows the engine accepts from an answer, one per line, and why it refused
# the rest. A row is a fixed number of tab-separated fields with a known kind
# and a name that could be an identifier; a sixth field on an automation row
# is a risk somebody tried to assign, and risk is not the model's to assign.
# The file is model-written, so this is the place shape is enforced and the
# only place: nothing here is ever executed.
_felix_commission_provider_shape() {   # need -> expected field count
  case "$1" in constitution_audited) printf 3 ;; obligations_surveyed) printf 7 ;; *) printf 5 ;; esac
}

# Which field of a row classifies it, for the report. An automation row ends in
# a sentence and carries its capability in the field before that; a score row
# ends in its grade. Keyed the same way as the shape and kept beside it,
# because the two facts are one fact: a need that adds a shape has to say where
# the classifier is in the same breath, or the report drops a column in silence
# while the log keeps it. That is exactly what happened to the grade on the
# protocol's first real answer, 2026-09-04.
felix_commission_provider_classifier() {   # need -> 1-based field index
  case "$1" in constitution_audited) printf 3 ;; obligations_surveyed) printf 2 ;; *) printf 4 ;; esac
}
_felix_commission_provider_lines() {
  local f; f="$(felix_commission_answer_path "$1" "$2")"; [ -f "$f" ] || return 0
  LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$f" | LC_ALL=C grep -v $'^done\t'
  return 0
}
felix_commission_provider_rows() {
  local proj="$1" need="$2" want line n kind name i=0
  want="$(_felix_commission_provider_shape "$need")"
  _felix_commission_provider_lines "$proj" "$need" | while IFS= read -r line; do
    i=$((i + 1)); [ "$i" -le "$FELIX_COMMISSION_PROVIDER_MAX" ] || break
    n="$(printf '%s\n' "$line" | LC_ALL=C awk -F'\t' '{ print NF }')"
    [ "$n" -eq "$want" ] || continue
    kind="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"; name="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    if [ "$want" -eq 5 ]; then
      _felix_commission_kind_ok "$kind" || continue
      LC_ALL=C grep -qE '^[A-Za-z0-9@._:-]+$' <<<"$name" || continue
      [ -n "$(_felix_commission_provider_toolong "$line")" ] && continue
    fi
    # A candidate obligation carries two shell commands by design, so the
    # metacharacter ban that keeps nomination rows inert would refuse every
    # evidence anyone could propose. candidates.sh applies its own rules to
    # that shape, and never executes a field; the ban stays for every other.
    if [ "$want" -ne 7 ]; then
      case "$line" in *'`'*|*'$('*|*';'*|*'|'*|*'&'*) continue ;; esac
    fi
    printf '%s\n' "$line"
  done
  return 0
}
felix_commission_provider_rejects() {
  local proj="$1" need="$2" want line n kind name long i=0
  want="$(_felix_commission_provider_shape "$need")"
  _felix_commission_provider_lines "$proj" "$need" | while IFS= read -r line; do
    i=$((i + 1))
    name="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    if [ "$i" -gt "$FELIX_COMMISSION_PROVIDER_MAX" ]; then printf '%s\tbeyond the %s-row ceiling\n' "${name:-(unnamed)}" "$FELIX_COMMISSION_PROVIDER_MAX"; continue; fi
    n="$(printf '%s\n' "$line" | LC_ALL=C awk -F'\t' '{ print NF }')"
    kind="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"
    if [ "$n" -ne "$want" ]; then printf '%s\t%s fields where the shape has %s; a risk column is not the model'"'"'s to write\n' "${name:-(unnamed)}" "$n" "$want"; continue; fi
    if [ "$want" -eq 5 ]; then
      _felix_commission_kind_ok "$kind" || { printf '%s\tkind "%s" is not one of %s\n' "$name" "$kind" "$FELIX_COMMISSION_PROVIDER_KINDS"; continue; }
      LC_ALL=C grep -qE '^[A-Za-z0-9@._:-]+$' <<<"$name" || { printf '%s\tnot a name\n' "$name"; continue; }
      long="$(_felix_commission_provider_toolong "$line")"
      if [ -n "$long" ]; then
        printf '%s\ta %s longer than %s characters, which the log could not hold whole\n' \
          "$name" "${long% *}" "${long##* }"; continue
      fi
    fi
    if [ "$want" -ne 7 ]; then
      case "$line" in *'`'*|*'$('*|*';'*|*'|'*|*'&'*) printf '%s\tshell metacharacters, in a row that is never executed anyway\n' "$name" ;; esac
    fi
  done
  return 0
}

# <file>@<hash> of the answer on disk, so the row-level log line for an
# answered provider row names the exact file it was read from.
felix_commission_answer_provenance() {
  local f; f="$(felix_commission_answer_path "$1" "$2")"
  [ -f "$f" ] || { printf -- '-'; return 0; }
  printf '%s@%s' "$(basename "$f")" "$(_felix_hash < "$f")"
}

# <plugin>@<version>/<sha> from the installed-plugin registry, or <plugin>@?/?
# — a provider upgrade is then visible as a provenance change (spec §7 step 7).
felix_commission_provider_provenance() {
  # Read bounded to the plugin's own entry. The shape here before returned the
  # NEXT plugin's version for an entry that carried none, and on a minified
  # registry returned the last plugin's for every name — so a provenance line,
  # the thing a declared row exists to be traceable by, could name the wrong
  # release entirely. Shared with the ledger's classifier rather than fixed
  # twice.
  local plugin="$1" ver sha
  ver="$(felix_registry_field "$plugin" version)"
  sha="$(felix_registry_field "$plugin" gitCommitSha)"
  printf '%s@%s/%s' "$plugin" "${ver:-?}" "${sha:-?}"
}

# The record phase: every accepted row of an answered file, appended to
# commissioning.log as INFERRED with the provider as actor. Offline, so the
# session-start hook may call it. Idempotent per file hash: a file already
# recorded under its current hash is not recorded twice. Prints the number
# of rows appended this call.
felix_commission_record_provider() {
  local proj="$1" root="$2" need="$3" answer="$4" tid="${5:-unknown-tree}" policy="${6:-}"
  local f hash plugin log stamp prov n=0 line kind name rows
  f="$(felix_commission_answer_path "$proj" "$need")"
  [ "$(felix_commission_provider_state "$proj" "$root" "$need" | LC_ALL=C cut -f1)" = "answered" ] || { printf 0; return 0; }
  hash="$(_felix_hash < "$f")"; plugin="$(printf '%s' "${answer#provider:}" | LC_ALL=C cut -d: -f1)"
  prov="$(basename "$f")@$hash;$(felix_commission_provider_provenance "$plugin")"
  log="$(felix_mem_dir "$proj")/commissioning.log"
  if [ -f "$log" ] && grep -qF "	$prov	" "$log" 2>/dev/null; then printf 0; return 0; fi
  mkdir -p "$(dirname "$log")" 2>/dev/null || { printf 0; return 1; }
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  rows="$(felix_commission_provider_rows "$proj" "$need")"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    kind="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"; name="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$stamp" "$tid" "${policy:--}" "$need" "answered" "INFERRED" \
      "$answer" "$prov" "$kind $name: $(printf '%s\n' "$line" | LC_ALL=C cut -f3- | LC_ALL=C tr '\t' ' ' | LC_ALL=C cut -c1-"$FELIX_COMMISSION_PROVIDER_LOG_MAX")" >> "$log" || { printf '%s' "$n"; return 1; }
    n=$((n + 1))
  done <<ROWS
$rows
ROWS
  printf '%s' "$n"
}

# ------------------------------------------------------- the admit phase ----
#
# A nomination is a name in a file a model wrote. Nothing has been fetched,
# nothing read, and the answer shape carries no tier anywhere on purpose —
# risk is not the model's to assign. So a nomination cannot be installed on
# its own authority at any tier, which is what felix_admit says about
# INFERRED, and the only door out is for the engine to go and look.
#
# Looking is what turns INFERRED into OBSERVED: source the plugin, fetch it at
# its pinned sha, read what discovery already reads, marketplace entry
# included, and tier what was actually found. The tier that reaches the
# policy is then the engine's own reading and never the provider's word. This is the panel's finding that
# an INFERRED capability would otherwise be consumed as DECLARED.
#
# Two of the provider's fields are claims, not one, and both are refused as
# evidence. The tier is never claimed and always read. The capability IS
# claimed — `plugin<TAB>foo<TAB>-<TAB>llm<TAB>why` asserts a capability — so it
# is matched again against what the copy on disk actually ships, using the same
# rules and the same threshold discovery uses. A capability the inspection does
# not support leaves the row `unknown` rather than declaring the difference.
#
# What never reaches the network at all:
#
#   mcp       refused on its kind, before anything is fetched. Spec 7 T3: a
#             provider-written mcp row is the one that would have been
#             activated unattended, so it is not fetched, tiered or installed.
#   hook      Felix authors none of these, so there is nothing to fetch and
#   skill     nothing that could be installed. Recorded and reported is the
#   subagent  whole verdict.
#
# Ungroundable is `unknown`, not `refuse`. A name in no marketplace, or a fetch
# that failed, is a question nobody answered — amendments 1.4 and the same
# reading of unknown the probes runner already uses. Unknown holds and
# fabricates nothing, and a later run can still answer it.
#
# This phase decides and writes nothing. Applying a `declare` is the caller's,
# for the same reason `felix_discover_adopt` does not edit stack.tsv itself.
#
# Emits: verdict <TAB> kind <TAB> name <TAB> tier <TAB> capability <TAB> sha <TAB> why
#   declare  | hold | refuse | recorded | unknown | already
# The sha is the commit the copy was read at, or `-` where nothing was fetched;
# it is what a declared row's log line carries as provenance.
# Is this plugin installed on this machine? Read from the same registry
# felix_commission_provider_provenance already parses, so no cli call and no
# network: the admit phase must be able to answer this before it decides
# whether going to look is even the question.
_felix_commission_installed() {   # bare name -> 0 when installed
  # A grep over the whole file, deliberately, and NOT the shared bounded
  # reader. Presence is a question about the file rather than about one entry:
  # the unbounded-scan fault the reader exists to fix is a per-entry field
  # lookup returning a NEIGHBOUR's value, and a boolean over the whole file has
  # no neighbour to confuse. Routing it through the reader was tried and made
  # this depend on the entry carrying a particular field, which is a constraint
  # the question does not have.
  local name="$1" reg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
  [ -n "$name" ] || return 1
  [ -f "$reg" ] || return 1
  grep -q "\"$name@" "$reg" 2>/dev/null
}

felix_commission_admit() {
  local proj="$1" home="$2" need="$3"
  # Declared apart from `home` on purpose: a local statement cannot read a
  # variable it is declaring in the same statement, and the suite asserts that
  # nothing in this tree does. It read empty here, which made every rules
  # lookup miss and turned every verdict into `unknown` — a silent all-refuse.
  local tpl="${4:-}"
  [ -n "$tpl" ] || tpl="$home/harness/templates"
  local rules declared scratch rc=0 nl='
'

  # The automation shape only. A score answer is three fields — `score`,
  # `69/100`, a grade — with neither a kind nor a name in them, so run through
  # here it read "score" as a kind and went looking for a plugin called
  # "69/100". The shape registry already knows which needs carry rows that name
  # something, and asking it is what keeps a third shape from repeating this.
  [ "$(_felix_commission_provider_shape "$need")" -eq 5 ] || return 0

  # Until 2026-10-01 a declared list that could not be read gave no rules, so
  # every nomination that was fetched and read matched no capability and came
  # back `unknown`, "nothing it ships matches a capability this project
  # declares", after the marketplace had been asked for each one. Now one row
  # says the list could not be read, nothing is fetched, and the status is 2.
  # The rules are captured with felix_capture, since a substitution can end with
  # nothing printed and status 0 when its fork fails.
  rules=""
  if ! felix_capture rules _felix_discover_rules "$tpl" "$proj"; then
    printf 'unknown\t-\t-\t-\t-\t-\tthe capabilities this project declares could not be read, so no nomination was matched to one\n'; return 2
  fi
  # Compared without the marketplace suffix, the same way discover's adopt
  # compares, so `hookify@claude-plugins-official` matches a `hookify` row.
  # Only as a regular file, for the reason felix_commission_request gives.
  declared=""
  [ -f "$proj/stack.tsv" ] && declared="$(LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | LC_ALL=C cut -f2 | LC_ALL=C sed 's/@.*//')"
  scratch="${TMPDIR:-/tmp}/felix-admit.$$.$(basename "$proj")"
  rm -rf "$scratch" 2>/dev/null; mkdir -p "$scratch" 2>/dev/null || return 1

  felix_commission_provider_rows "$proj" "$need" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    local kind name bare src sha sub facts tier skills hit score gcap
    kind="$(printf '%s\n' "$line" | LC_ALL=C cut -f1)"
    name="$(printf '%s\n' "$line" | LC_ALL=C cut -f2)"
    bare="${name%%@*}"

    case "$kind" in
      mcp)
        printf 'refuse\t%s\t%s\t-\t-\t-\tan mcp server is never installed from a request\n' "$kind" "$name"
        continue ;;
      hook|skill|subagent)
        printf 'recorded\t%s\t%s\t-\t-\t-\tFelix authors none of these, so there is nothing to fetch\n' "$kind" "$name"
        continue ;;
    esac

    # Membership by case, not a pipe into grep: GNU grep writing to /dev/null
    # stops at its first match as -q does, and a printf still writing a long
    # list dies of SIGPIPE, which pipefail reads as a plugin nobody declared.
    case "$nl$declared$nl" in *"$nl$bare$nl"*)
      printf 'already\t%s\t%s\t-\t-\t-\tnamed in stack.tsv already\n' "$kind" "$name"
      continue ;;
    esac
    # Installed but undeclared is a different answer from unresolvable, and
    # saying the second when the first is true is what the phase did on its
    # first real run. An installed plugin is absent from the available list —
    # that list is what is left to install — so sourcing it fails and the row
    # came back "nothing could be read". The registry answers it offline.
    if _felix_commission_installed "$bare"; then
      printf 'already\t%s\t%s\t-\t-\t-\tinstalled on this machine already, though stack.tsv does not name it\n' "$kind" "$name"
      continue
    fi

    # The network boundary. Both halves fail into `unknown`, because a name
    # nobody could resolve and a fetch that did not complete are the same
    # thing: nothing was read, so nothing is known.
    src="$(felix_discover_source "$bare" 2>/dev/null)" || src=""
    if [ -z "$src" ]; then
      printf 'unknown\t%s\t%s\t-\t-\t-\tnothing to fetch it by: no pinned url and sha in any configured marketplace\n' "$kind" "$name"
      continue
    fi
    sha="$(printf '%s' "$src" | LC_ALL=C cut -f2)"; sub="$(printf '%s' "$src" | LC_ALL=C cut -f3)"
    [ "$sub" = "-" ] && sub=""
    if ! felix_discover_fetch "$(printf '%s' "$src" | LC_ALL=C cut -f1)" "$sha" "$scratch/$bare" 2>/dev/null; then
      printf 'unknown\t%s\t%s\t-\t-\t%s\tcould not be fetched at its pinned commit, so nothing was read\n' "$kind" "$name" "$sha"
      continue
    fi

    facts="$(felix_discover_inspect "$scratch/$bare" "$sub" \
      "$(felix_discover_marketplace_file "$(printf '%s' "$src" | LC_ALL=C cut -f4)")" "$bare")"
    tier="$(felix_discover_risk "$facts")"

    # Risk before grounding, and the order was the other way round until a
    # second project ran this: a nomination fetched, read and tiered `high` was
    # reported `unknown`, "nothing it ships matches a capability this project
    # declares", because the capability gate returned before the policy was
    # ever asked. Invariant 4 says high is refused by every flag from every
    # caller, and a capability mismatch is answerable by declaring a capability
    # while a high tier is not answerable at all — so the weaker statement must
    # not be the one that gets made.
    if [ "$(felix_admit "$tier" OBSERVED)" = "refuse" ]; then
      printf 'refuse\t%s\t%s\t%s\t-\t%s\t%s\n' "$kind" "$name" "$tier" "$sha" "$(felix_discover_why "$facts")"
      continue
    fi

    # The capability, matched against what the copy on disk ships rather than
    # against what the answer file said it would.
    skills="$(printf '%s\n' "$facts" | LC_ALL=C awk -F'\t' '$1 == "skill" { print $2 }' | LC_ALL=C tr '\n' ' ')"
    hit="$(felix_capability_match "$bare" "" "$rules" "$skills")"
    score="$(printf '%s' "$hit" | LC_ALL=C cut -f1)"; gcap="$(printf '%s' "$hit" | LC_ALL=C cut -f2)"
    if [ "${score:-0}" -lt "${FELIX_DISCOVER_MIN:-3}" ]; then
      printf 'unknown\t%s\t%s\t%s\t-\t%s\tnothing it ships matches a capability this project declares\n' "$kind" "$name" "$tier" "$sha"
      continue
    fi

    # Only install and hold can reach here: refuse returned above, before the
    # capability was consulted. The third arm stays as a fail-closed default
    # rather than an assertion that the policy has exactly three answers.
    case "$(felix_admit "$tier" OBSERVED)" in
      install) printf 'declare\t%s\t%s\t%s\t%s\t%s\t%s\n' "$kind" "$name" "$tier" "$gcap" "$sha" "$(felix_discover_why "$facts")" ;;
      hold)    printf 'hold\t%s\t%s\t%s\t%s\t%s\t%s\n'    "$kind" "$name" "$tier" "$gcap" "$sha" "$(felix_admit_why "$tier" OBSERVED)" ;;
      *)       printf 'refuse\t%s\t%s\t%s\t%s\t%s\t%s\n'  "$kind" "$name" "$tier" "$gcap" "$sha" "$(felix_discover_why "$facts")" ;;
    esac
  done
  rc=$?
  rm -rf "$scratch" 2>/dev/null
  return "$rc"
}

# Apply what the admit phase declared.
#
# A `declare` line is a plugin the engine fetched at a pinned sha, read, tiered,
# matched to a capability this project declares, and found installable under
# the policy for what it read. Applying it is a row in stack.tsv carrying
# OBSERVED — the grounding the engine has, never a person's — so that every
# later run reads the row as what it is. This is the decision that kept the
# admit phase from writing at all until it was taken: a manifest with no
# provenance column reads every row as a person's, and person-written is the
# one grounding that installs medium unattended.
#
# The log line carries the sha the copy was read at. Nothing is installed
# here; `stack apply --yes` installs what the policy allows on the next run.
# A name already in the manifest is left alone. Prints how many rows it wrote.
felix_commission_apply_declares() {   # proj, root, admit-output, tid, policy, need -> count
  local proj="$1" root="$2" adm="$3" tid="${4:-unknown-tree}" policy="${5:-}" need="$6"
  local v k n tier gcap sha why log stamp declared c=0 nl='
'
  log="$(felix_mem_dir "$proj")/commissioning.log"
  # Read only as a regular file. A pipe at the path held this read open, so
  # the refusal below was never reached (2026-10-01). Anything else declares
  # nothing here and every row is refused as an append that failed.
  declared=""
  [ -f "$proj/stack.tsv" ] && declared="$(LC_ALL=C grep -vE '^[[:space:]]*(#|$)' "$proj/stack.tsv" 2>/dev/null | LC_ALL=C cut -f2 | LC_ALL=C sed 's/@.*//')"
  stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  while IFS=$'\t' read -r v k n tier gcap sha why; do
    [ "${v:-}" = "declare" ] && [ -n "${n:-}" ] || continue
    # By case, for the reason felix_commission_admit gives: a row already in
    # stack.tsv read as absent would be appended a second time.
    case "$nl$declared$nl" in *"$nl${n%%@*}$nl"*) continue ;; esac
    # Seeded only where nothing is at the path, as adopt.sh seeds it: a link
    # whose target is gone, or a pipe, is refused below rather than written
    # through or waited on in this function (2026-10-01).
    [ -e "$proj/stack.tsv" ] || [ -L "$proj/stack.tsv" ] || printf '# kind\tname\tsource\trisk\tcapability\tgrounding\n' > "$proj/stack.tsv"
    # A manifest whose last line has no newline would otherwise fuse the two
    # rows into one, destroying the row that was there and losing this one.
    # stack.tsv is seeded "Edit freely", so a hand edit that drops the final
    # newline is an ordinary thing rather than a corrupt file.
    #
    # Through felix_end_line since 2026-10-01. The test here was
    # `[ -n "$(tail -c 1 ...)" ]`, and a command substitution drops a NUL as it
    # drops a newline, so a stack.tsv ending in a NUL read as ended and the row
    # fused onto it anyway. A newline that cannot be written is a row that
    # cannot be written, so it takes the same branch as a failed append.
    if ! felix_end_line "$proj/stack.tsv" \
       || ! printf '%s\t%s\t-\t%s\t%s\tOBSERVED\n' "$k" "$n" "$tier" "$gcap" >> "$proj/stack.tsv"; then
      # Said, not skipped. A declare that could not be written is a thing the
      # run tried and failed to do, and reporting it as "nothing was declared"
      # is the same defect one level down from the one this whole column
      # exists to prevent.
      printf 'felix: could not append %s to %s/stack.tsv\n' "$n" "$proj" >&2
      continue
    fi
    # The provenance is not optional. A row in the manifest whose sha nobody
    # recorded is exactly the state this column exists to prevent, so a lost
    # log line is a failure of the whole write and is neither counted nor
    # reported as a declare. The sibling writer guards its append the same way.
    mkdir -p "$(dirname "$log")" 2>/dev/null
    # Actor `felix`, the word felix_commission_actor emits for an engine
    # answer. `felix:commission` is an ANSWER string, and putting one in the
    # actor column makes this line match no reader of the log.
    if ! printf '%s\t%s\t%s\t%s\tdeclared\tOBSERVED\tfelix\t%s@%s\t%s %s: %s %s\n' \
      "$stamp" "$tid" "${policy:--}" "$need" "$n" "${sha:--}" "$k" "$n" "$tier" "$gcap" >> "$log"; then
      continue
    fi
    declared="$declared
${n%%@*}"
    c=$((c + 1))
  done <<ROWS
$adm
ROWS
  printf '%s' "$c"
}

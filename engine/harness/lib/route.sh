# Intent routing.
#
# Felix knows what a project has (stack.tsv), what a kind of work needs
# (profiles.tsv), and what a change risks (risk.tsv). It did not know what the
# current prompt was about, so none of that reached the session while it could
# still change the outcome. Choosing tools stayed manual, and with enough
# options manual means the good ones go unused: a capability nobody remembers to
# invoke is indistinguishable from one nobody installed.
#
# One new link in a chain that was otherwise built:
#
#   prompt + tree -> routes.tsv -> profiles.tsv -> stack.tsv -> the play
#
# A model classifier was designed for the miss case and rejected on measurement,
# not on principle: 4.9-8.6s per call through the CLI, of which about 2s is
# process startup that --effort low does not touch, and --json-schema costs 31x
# more because it forces a tool-use round trip. Quality was fine. A router that
# adds five seconds to a prompt is not a router anyone keeps. The table learns
# from its misses instead, through felix route --promote.
#
# Everything here reads files. Nothing calls the network, and nothing queries
# live mount state: `claude mcp list` runs health checks, and a hook that waits
# on those before every prompt is a hook that gets removed. Declared-versus-not
# is the useful signal here anyway; live mounting is the reconciler's job.

FELIX_ROUTE_MIN_SCORE="${FELIX_ROUTE_MIN_SCORE:-2}"
FELIX_ROUTE_PROMOTE_MIN="${FELIX_ROUTE_PROMOTE_MIN:-3}"
# How much the working tree may contribute, in total, however many of its
# tokens match. Two is exactly the threshold, so a tree can still route when you
# said nothing routable — and can never outvote a word you actually typed.
#
# Uncapped, this fails in the ordinary case rather than a contrived one. A
# checkout carrying a couple of untracked backup directories offers a few
# hundred path tokens; against that, a sentence contributing four is inaudible,
# and prompts route to whatever the stale directories happen to be about.
FELIX_ROUTE_CONTEXT_CAP="${FELIX_ROUTE_CONTEXT_CAP:-2}"

# Only rows with all four fields. A malformed row is skipped rather than fatal:
# one bad line must not silently stop the whole table from routing.
_felix_route_rows() {
  local proj="$1" n p pr pl
  [ -f "$proj/routes.tsv" ] || return 0
  while IFS=$'\t' read -r n p pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pr:-}" ] || continue
    printf '%s\t%s\t%s\t%s\n' "$n" "$p" "$pr" "${pl:--}"
  done < "$proj/routes.tsv"
}

# Same filter the lessons matcher uses, for the same reason: short words and
# filler match everything and would decide what you meant on the word "the".
# The hook is handed the whole payload rather than a parsed prompt, on purpose,
# so the envelope's own field names are in the token stream: session_id, prompt,
# transcript_path, permission_mode and the rest. Any route keyed on one of those
# scored on every turn whatever was typed, and a project whose subject matter IS
# prompts sent everything to one route.
#
# The first fix was a blacklist of those words, and it was worse than the bug:
# `hook` and `prompt` are words people type. Asking about a hook matched nothing
# at all, because the word had been banned to silence a field name.
#
# So the keys are removed and the values are kept. A JSON key is a quoted word
# followed by a colon, which no sentence contains, and stripping those leaves
# every real word usable — including the ones that happen to share a name with
# a field.
# Stripping the keys was half the job, and the half that showed. The VALUES the
# runtime fills in are still machine-generated text nobody typed: transcript_path
# and cwd carry the entire checkout path, so a home directory named Documents put
# "documents" into every prompt, and a branch named ...-review-... put "review"
# there too — both at the double weight reserved for what you actually said. The
# word `continue` routed to a document skill, and the score was a clean 2 typed.
#
# So the pairs are removed whole, key and value together, for the fields the
# runtime owns. `prompt` is deliberately not among them: its value is the one
# thing in the envelope a person did type. A path typed inside the prompt still
# counts, because that is a word you chose.
#
# Naming those fields was the third fix, and it was the same mistake one remove
# further out: a list of the keys the runtime had used so far. The desktop
# harness then added `scratchpad_dir` — an absolute path, and on this machine
# one under a directory called Documents — and `document` was back. 18 of the
# 20 rows that route logged between 2026-08-25 and 2026-09-02 carried it, and
# four declines in decisions.log blamed the table for it. So the rule is now
# the shape the runtime's values share rather than the names they have had: a
# string value that opens with `/` is a path the runtime filled in, and the
# pair goes whole whatever its key is called, including the keys the harness
# has not added yet. Still structure and never vocabulary — nothing here knows
# the word `document`. `prompt` keeps its exemption by having its colon swapped
# out around that rule and back after it: a slash command and a pasted path
# both open with `/`, and reading either as the runtime's would throw away the
# whole prompt on exactly the turns that name a file.
#
# Both directions. felix_route_log runs this on the way in, _felix_envelope_text
# on the way out, so rows written before the rule existed stop proposing
# `documents` to --promote — the way the 2026-08-13 fix below cleaned
# `prompt_id` out of them.
#
# LC_ALL=C on every text stage, and it is load-bearing rather than tidy.
#
# `cut -c` is byte-oriented in the environment the hook actually runs in — LANG
# unset, LC_CTYPE=C — so a prompt truncated at 160 can keep half of a multibyte
# character. Reading that back through `sed -E` under the UTF-8 locale a
# Terminal has raises "illegal byte sequence" and, with `set -o pipefail`, takes
# the whole pipeline down. In the C locale every byte is a valid character and
# no stage can refuse a line. Nothing here is doing character-aware work: the
# patterns are ASCII and the tokeniser splits on an ASCII class.
#
# It also makes the two userlands agree on what a truncated prompt contains.
# Before this the same prompt logged 160 characters on a laptop and 160 bytes on
# CI, so the recorded evidence differed by machine.
_felix_envelope_strip() {
  LC_ALL=C sed -E \
    -e 's/"(session_id|transcript_path|cwd|permission_mode|hook_event_name|session_title|source|model|version)"[[:space:]]*:[[:space:]]*("[^"]*"|[^,}]*)/ /g' \
    -e 's/"prompt"([[:space:]]*):/"prompt"\1=/g' \
    -e 's/"[A-Za-z_][A-Za-z0-9_]*"[[:space:]]*:[[:space:]]*"\/[^"]*"/ /g' \
    -e 's/"prompt"([[:space:]]*)=/"prompt"\1:/g'
}

# What a person actually typed, with the JSON around it gone: the runtime's own
# pairs removed whole, and then every remaining key removed but not its value.
#
# Its own function because the reader needed it and did not have it. Recording
# the payload with only half this applied put the literal words `prompt` and
# `prompt_id` into every miss, and they were the top two rows of
# `felix route --promote` — above every word anybody had typed, in the one
# report that exists to improve the routing table.
#
# Applied on the way OUT only, which also cleans rows written before any of this.
# The first fix applied it on the way in as well and broke `felix monitor`: its
# route panel finds the sentence by looking for the literal `"prompt":` key, so
# stripping keys at write time made every new row render as the JSON around the
# sentence instead of the sentence. The log is a record for a person to read.
# Nothing promote needs is lost by leaving the keys in it.
_felix_envelope_text() {
  _felix_envelope_strip | LC_ALL=C sed 's/"[A-Za-z_][A-Za-z0-9_]*"[[:space:]]*:/ /g'
}

# The words a route may be scored on. Frequency order is the caller's business,
# which is the only reason this is not felix_route_tokens itself: promote counts
# repeats and the router does not.
#
# There were two of these and they drifted. Anything the router discards must be
# absent from promote as well, or the report proposes keywords that could never
# have matched.
_felix_route_words() {
  export LC_ALL=C
  _felix_envelope_text \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9_-' '\n' \
    | grep -E '^.{4,}$' \
    | grep -vE '^(this|that|with|from|have|been|will|when|what|there|their|would|could|should|about|into|then|than|they|them|your|make|does|just|also|only|some|more|most|need|want|please|help|file|code|lets)$' \
    | grep -vE '^(true|false|null)$'
}

felix_route_tokens() {
  printf '%s' "$1" | _felix_route_words | sort -u
}

# The prompt value out of a hook payload, from the FIRST occurrence of the key.
#
# Parameter expansion rather than sed, because `#` is shortest-match-from-left
# and POSIX sed has no non-greedy form: `s/.*"prompt"...` would bind to the LAST
# copy of the key, and this project already has a lesson about a later copy in
# the envelope being read in preference to the real one. Returns the remainder
# of the payload after the opening quote, which is all a prefix test needs.
felix_route_prompt() {
  local raw="$1" rest
  case "$raw" in *'"prompt"'*) ;; *) return 1 ;; esac
  rest="${raw#*\"prompt\"}"
  rest="${rest#*:}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  rest="${rest#\"}"
  printf '%s' "$rest"
}

# Whether this payload is the runtime talking to itself rather than a person.
#
# UserPromptSubmit carries more than what somebody typed: task completions,
# system reminders, and the Stop hook's own feedback all arrive on the same
# channel. Five of the first 89 rows in Felix's own miss log were machine text
# scored as a prompt, and they picked real routes — three `harness`, one
# `research`, one `gate`. Each one announced a play at text nobody wrote, put a
# row in the log that skews `--promote`, and then had the Stop hook ask why the
# named play went unused. That last one is a loop: a question generated by a
# route that fired on a machine's own message.
#
# Structure, never vocabulary. `<task-notification>` opening the payload is a
# tag no sentence begins with; the word "notification" is one people type, and
# this project has already broken a word once by banning it to silence a field
# name. So this anchors at the start and matches the marker, not the noun —
# asking "why did the task-notification route to harness?" is still a prompt.
#
# Erring toward "a person typed it" is the safe direction, and how safe depends
# on the kind below. A false `message` costs that turn's route and nothing else:
# the session is still marked, taught and briefed. A false `session` costs the
# whole turn, the mark Stop's committed-work check reads included when it is
# the first prompt, and the marker it leaves has Stop and SessionEnd pass over
# the session until a later prompt of the person's marks it. That is why the
# session kind is anchored on both fixed ends of the platform's request, the
# opening before the log and the closing after it, and not on a sentence of
# it. A false negative is the loop above, or, for the summary request, a
# session in the ledger that nobody held.
#
# Two kinds, kept apart, because what the prompt hook may do with each is
# different (#264).
#
#   session  the platform's own request, which starts a session of its own and
#            types into it. Nothing in that session was typed by anyone, so the
#            prompt hook records nothing at all for it: no mark, no route, no
#            lessons, no brief.
#   message  a runtime block that lands inside a session a person holds. Not
#            routed, because the router would score the block, and nothing
#            else: the session is marked, taught and briefed as it always was.
#            A person can paste any of these and type a question under it, and
#            recorded as nothing, that person's first prompt lost its mark and
#            with it Stop's check on the work the session went on to commit.
#
# Printed on stdout; a person's prompt prints nothing and returns 1.
#
# The openings, each one a marker and not a word:
#   <task-notification>      message: a background task ended.
#   <system-reminder>        message: a worktree or spawned-task notice put in
#                            front of what the person typed first.
#   Stop hook feedback:      message: the Stop hook's own output, fed back.
#   [SYSTEM NOTIFICATION     message: the runtime's all-caps sentinel.
#   <cross-session-message   message: another session writing through
#                            SendMessage. Its words routed in the sessions it
#                            arrived in, named plays in their ledgers and moved
#                            their route. The tag carries attributes, so the
#                            anchor stops at the space before them.
#   Below is a conversation log from a Claude Code coding session.
#                            session: the platform's summary request. A fixed
#                            request, then the whole log being summarised, whose
#                            `**User:**` lines are what chose its route. All 78
#                            were folded as sessions pointed at a play that
#                            never reached it. Matched on both of its fixed
#                            ends: _FELIX_ROUTE_SESSION_REQUESTS, below.
#
# Handed what felix_route_prompt returns, the rest of the payload from the
# value's opening quote, so the value's closing quote is there to anchor the
# summary request's closing on. A bare value that ends on it is matched too.
felix_route_machine() {
  local p="$1" q i h t
  # Leading whitespace only; anything else before the marker means prose.
  p="${p#"${p%%[![:space:]]*}"}"
  [ -n "$p" ] || return 1
  case "$p" in
    '<task-notification>'*|'<system-reminder>'*|'Stop hook feedback:'*|\
    '[SYSTEM NOTIFICATION'*|'<cross-session-message '*|'<cross-session-message>'*)
      printf 'message\n'; return 0 ;;
  esac
  # The session kind is looked for past the escapes JSON writes whitespace as
  # too, since felix_route_prompt hands the value back still escaped. Only for
  # this kind: the message kinds keep the anchor they always had.
  q="$p"
  while :; do
    q="${q#"${q%%[![:space:]]*}"}"
    case "$q" in
      '\n'*|'\t'*|'\r'*) q="${q#??}" ;;
      *) break ;;
    esac
  done
  for ((i = 0; i + 2 < ${#_FELIX_ROUTE_SESSION_REQUESTS[@]}; i += 3)); do
    h="${_FELIX_ROUTE_SESSION_REQUESTS[i]}"
    t="${_FELIX_ROUTE_SESSION_REQUESTS[i + 1]}"
    case "$q" in "$h"*) ;; *) continue ;; esac
    case "$q" in *"$t"|*"$t\""*) printf 'session\n'; return 0 ;; esac
  done
  return 1
}

# The platform's summary request, as the prompt hook holds it: the JSON value
# still escaped, so each `\n` below is the two characters the payload carries.
#
# The request is fixed at both ends, and the log being summarised sits between
# them. Each wording is three entries, its opening, its closing, and the day
# the prompt hook began to match it:
#
#   opening  from the first character to where the log begins, through
#            `## Conversation log`, the longest stretch at the start that was
#            identical in every request seen.
#   closing  from the end of the log to the last character, the output format
#            it asks for, the longest stretch at the end that was identical in
#            every request seen.
#   matched  the day from which every engine in use matches this wording: the
#            day after the release that ships its match. Until then a request
#            in this wording was briefed like a prompt, and the ledger passes
#            over the sessions whose brief rows were written before this day
#            (_felix_ledger_machine_sessions). Set too late, a person who
#            pasted 200 characters of the opening in the days between is passed
#            over too; set too early, the platform's sessions from the days
#            between are folded back into the ledger. A release that lands
#            later moves it.
#
# The opening and the closing both, because either one alone is words a
# person can reuse and then write their own instruction under. Matched on the
# first two lines, that person's prompt was recorded as nothing; matched on the
# whole opening, so was the prompt of a person who pasted all of it and asked
# their own question after it. A person does not end on the platform's output
# format as well. In the transcripts on 2026-09-22, none of some 7,600 other
# prompts starts with the opening, and none ends with the closing or holds it
# anywhere.
#
# One set of three per wording the platform has used, with when it was seen. A
# release that rewords either end gets past this until its wording is added
# here, which is the safe direction: its sessions are counted, as all 78 were,
# and the matched day set when it is added passes over the ones counted until
# then.
#
#   2026-09-03 to 2026-09-22, Claude Code 2.1.226 (41) and 2.1.260 (43). All
#   84 requests in the transcripts, identical for their first 445 characters
#   through `## Conversation log` and their last 353, from the blank line
#   before `## Output format`, with nothing after it.
_FELIX_ROUTE_SESSION_REQUESTS=(
  'Below is a conversation log from a Claude Code coding session.\nCreate a summary to help the next session quickly understand the context.\n\n## Prioritize including\n- Design decisions and technology choices made this session\n- Bugs and problems solved\n- Files changed or created, with a brief description of changes\n- Unfinished tasks and work to continue in the next session\n- Important context the next session needs to know\n\n## Conversation log\n'
  '\n\n## Output format (Markdown only, no preamble)\n\n## Session Summary\n\n### Tasks\n(main tasks worked on this session)\n\n### Decisions Made\n(design decisions and technology choices)\n\n### Files Modified\n(files changed or created)\n\n### Unresolved Issues\n(unfinished tasks and work to continue)\n\n### Next Session Context\n(important context for the next session)'
  '2026-09-24'
)

# Where you are standing: the branch name, and every path git considers changed
# including untracked ones. `git diff --name-only` was not enough — a brand new
# file is exactly the kind of change that says what the work is about.
#
# `-uall` matters more than it looks. Plain porcelain collapses a wholly new
# directory into one `?? ui/` entry, so starting a feature by creating a folder
# of files contributes a single two-letter token and routes nothing. That is
# precisely the moment the router should have the most to say.
felix_route_context() {
  local root="$1"
  git -C "$root" status --porcelain -uall 2>/dev/null | cut -c4- | tr '/._-' '    '
  git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/-_' '   '
}

# score <TAB> promptscore <TAB> order <TAB> name <TAB> profile <TAB> play, best first.
#
# Prompt words score two and context words one. Each distinct keyword counts at
# most once however often it occurs, so a repeated word cannot dominate. Ties
# break by file order, which is why the table is written specific-to-general.
#
# promptscore is carried separately so the caller can tell a route you asked for
# from one the working tree decided. Both are legitimate — two corroborating
# tree tokens meet the threshold on purpose — but they are different claims, and
# a block that presents the second as the first is quietly lying about why.
felix_route_score() {
  local proj="$1" prompt="$2" ctx="$3"
  local phay chay i=0
  # One space-delimited haystack per source, tested once per keyword, rather
  # than a nested loop re-reading a heredoc for every keyword. Same answer,
  # and the keyword can no longer span a token boundary because the tokens are
  # separated by spaces and keywords never contain one.
  phay=" $(felix_route_tokens "$prompt" | tr '\n' ' ')"
  chay=" $(felix_route_tokens "$ctx"    | tr '\n' ' ')"
  while IFS=$'\t' read -r name kws profile play; do
    [ -n "${name:-}" ] || continue
    i=$((i+1))
    local pscore=0 cscore=0 kw
    for kw in $kws; do
      case "$phay" in
        *"$kw"*) pscore=$((pscore + 2)); continue ;;
      esac
      case "$chay" in
        *"$kw"*) cscore=$((cscore + 1)) ;;
      esac
    done
    [ "$cscore" -gt "$FELIX_ROUTE_CONTEXT_CAP" ] && cscore="$FELIX_ROUTE_CONTEXT_CAP"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$((pscore + cscore))" "$pscore" "$cscore" "$i" "$name" "$profile" "$play"
  done <<EOF
$(_felix_route_rows "$proj")
EOF
}

# Ordered by what you typed first, then by the tree, then by file order.
#
# Sorting on the total let a route win on tree tokens alone against a route you
# had actually named. The prompt is the claim; the tree only corroborates.
felix_route_best() {
  local line
  line="$(felix_route_score "$1" "$2" "$3" | sort -k2,2nr -k3,3nr -k4,4n | head -1)"
  [ -n "$line" ] || return 1
  [ "$(printf '%s' "$line" | cut -f1)" -ge "$FELIX_ROUTE_MIN_SCORE" ] || return 1
  printf '%s' "$line"
}

# What kind of thing a play entry is, according to what the project declared.
#
# Three shapes have to resolve against one manifest. A bare name matches a stack
# row named exactly that, or one qualifying it with a marketplace, so
# `playwright` finds `playwright@claude-plugins-official`. A qualified skill —
# `superpowers:brainstorming`, which is what Claude Code itself calls it — is
# owned by a plugin, and the manifest declares the plugin rather than each of
# its fourteen skills, so the part before the colon is what gets looked up.
# Without that, every play naming a real skill would report itself missing.
_felix_route_kind() {
  local proj="$1" want="$2" owner="$1" kind name
  [ -f "$proj/stack.tsv" ] || { printf 'not declared'; return; }
  case "$want" in
    *:*) owner="${want%%:*}" ;;
    *)   owner="$want" ;;
  esac
  while IFS=$'\t' read -r kind name _rest; do
    case "$kind" in ''|'#'*) continue ;; esac
    case "$name" in
      "$want"|"$want@"*)   printf '%s' "$kind"; return ;;
      "$owner"|"$owner@"*) printf 'skill'; return ;;
    esac
  done < "$proj/stack.tsv"
  printf 'not declared'
}

# The block. Written as an instruction to the model, because that is what it is:
# additionalContext is never rendered to the user, and every context-injecting
# hook on this machine writes second person for the same reason.
# Worded as a requirement, because politeness does not survive contact with a
# model that has its own plan. The nearby superpowers hook is the proof: it says
# YOU DO NOT HAVE A CHOICE and it fires reliably, while "use these, in this
# order" was read as a suggestion and skipped.
#
# The escape is named rather than removed. An agent that silently ignores a bad
# route teaches nobody anything; one that says "this looks like backend work,
# not frontend" surfaces a keyword worth fixing. Obedience is not the goal —
# the goal is that skipping costs a sentence.
felix_route_render() {
  local proj="$1" name="$2" play="$3" root="$4" pscore="${5:-1}" transcript="${6:-}"
  local p kind due rest
  printf 'Felix routed this to: %s\n' "$name"
  [ "${pscore:-1}" -eq 0 ] && \
    printf 'Read off the working tree, not the prompt: nothing you typed named a\nkind of work, so this is a guess from what is currently changed.\n'

  if [ "$play" != "-" ] && [ -n "$play" ]; then
    if due="$(felix_route_due "$transcript" "$play")"; then
      rest="$(printf '%s' "$due" | cut -f2)"
      due="$(printf '%s' "$due" | cut -f1)"
      kind="$(_felix_route_kind "$proj" "$due")"

      if [ "$kind" = "not declared" ]; then
        printf '\nThis kind of work wants %s, which this project has not declared and\n' "$due"
        printf 'is not installed here. Carry on without it and say that you did.\n'
      else
        # Calibrated to the channel's measured accuracy, and that is the point
        # of the wording. The old paragraph opened "This is a requirement, not
        # a suggestion" — language for a channel that is nearly always right.
        # Measured 2026-08-30 against the fixed instrument: 11 mandates
        # rendered in five days, 2 followed, and every mandate audited live in
        # that window was wrong for its turn (#29 holds five distinct causes).
        # A maximal claim from a low-precision source teaches sessions to skim
        # the channel, and then the one right mandate is skimmed with the rest.
        #
        # So the mandate now says where it came from and asks for the decline
        # to be recorded. The ack is what converts a wrong route from noise
        # into a labeled example — the reason lands in decisions.log, where
        # the table's next revision can read it.
        printf '\nUse this now: %s (%s)\n' "$due" "$kind"
        printf '\nNamed by the %s route in this project'\''s table. The table is a\n' "$name"
        printf 'keyword match with a measured error rate, so if this step is wrong for\n'
        printf 'what this turn actually is, decline it on the record:\n'
        printf '\n  felix route --ack "why the step does not fit this turn"\n'
        printf '\nA recorded decline tunes the table and quiets the close-of-session\n'
        printf 'check. A silent skip reads as a fit suggestion ignored, and keeps the\n'
        printf 'table wrong. If it does fit, use it before calling the work done.\n'
      fi
      [ -n "$rest" ] && \
        printf '\nLater, only if the work actually reaches them: %s\n' "$rest"
    fi
  fi
  _felix_route_red "$proj" "$root"
}

# A router that hands you fast tools while you edit the authorization model is
# worse than no router. Only fires when the working tree actually touches a red
# path, and only when the project declared any.
_felix_route_red() {
  local proj="$1" root="$2" paths sev
  [ -f "$proj/risk.tsv" ] || return 0
  command -v felix_incident_severity >/dev/null 2>&1 || return 0
  paths="$(git -C "$root" status --porcelain 2>/dev/null | cut -c4- | grep -v '^$')"
  [ -n "$paths" ] || return 0
  sev="$(felix_incident_severity "$proj" "$paths")"
  [ "$sev" = "red" ] || return 0
  # Injected into the session on a routed turn, so its wording is direction.
  # It said "a person decides here", keyed on tier alone, in every session that
  # touched the engine's own libraries — the loudest of the sentences that left
  # merges for the founder after he had said Felix merges.
  printf '\nThis working tree touches a path the project calls red: a mistake here is\n'
  printf 'silent and reaches every session, so look hard and show the change and its\n'
  printf 'reversal in the pull request. The tier is advice, not a stop; a person\n'
  printf 'decides only where felix merge names an escape channel.\n'
}

# Has a play step actually been used in this session?
#
# The session transcript records it three ways depending on what the step is: a
# skill carries an attribution, a plugin's skill carries its owner, and a plugin
# that ships an MCP server shows up as a tool name. Checked with grep rather
# than parsed — 21ms against a 5MB transcript, and no JSON reader in an engine
# that promises only bash and git.
felix_route_step_used() {
  local transcript="$1" step="$2" owner
  [ -n "$transcript" ] && [ -f "$transcript" ] || return 1
  case "$step" in *:*) owner="${step%%:*}" ;; *) owner="$step" ;; esac
  grep -q "\"attributionSkill\":\"$step\""    "$transcript" 2>/dev/null && return 0
  # Owner-level answers apply ONLY to a step that is a bare plugin name. A
  # qualified step is answered by the exact match above and has nothing left to
  # ask; letting the owner lines speak for it is how one skill came to satisfy
  # every step its plugin ships.
  #
  # Both lines were wrong, in different ways, and repairing either alone changes
  # nothing. The skill line was missing its closing quote, so it prefix-matched
  # the plugin. The plugin line was correctly quoted and asks the wrong question:
  # whether the PLUGIN ran, not whether the STEP did. superpowers ships
  # `using-superpowers`, whose description tells a session to invoke it before
  # anything else, and 16 of the 23 slots in Felix's own table are superpowers:*
  # — so from turn one felix_route_due found every step used and rendered no
  # requirement, while felix_ledger_note_named recorded the play as named
  # anyway. Every follow-through number this project has quoted was computed
  # against suggestions nobody was shown.
  case "$step" in
    *:*) : ;;
    *)   grep -q "\"attributionSkill\":\"$owner:"  "$transcript" 2>/dev/null && return 0
         grep -q "\"attributionPlugin\":\"$owner\"" "$transcript" 2>/dev/null && return 0
         # A plugin that ships an MCP server shows up only as a tool name, so
         # this is the one signal available for it — but it names the PLUGIN and
         # can never name the skill, which is exactly why it belongs in here with
         # the other owner-level answers. The first version of this fix gated the
         # two above and left this one below the case: the same defect, surviving
         # in the one branch no assertion reached. Found by review, not by tests.
         #
         # Still deliberately unanchored. Server names are mangled on the way in
         # — semgrep arrives as mcp__plugin_semgrep_guardian__ — so a tighter
         # pattern stops matching the thing it is for.
         grep -qE "\"name\":\"mcp__[^\"]*$owner" "$transcript" 2>/dev/null && return 0 ;;
  esac
  return 1
}

# The first step of a play that has not been used yet, and everything after it.
#
# Naming the whole play at the first prompt tells an agent to critique and
# browser-test something that does not exist, and spends context saying it. A
# play is a sequence, so only the step that is actually due gets named; the rest
# arrive as the work reaches them, or not at all if it never does.
felix_route_due() {
  local transcript="$1" play="$2" p due="" rest=""
  [ -n "$play" ] && [ "$play" != "-" ] || return 1
  for p in $play; do
    if [ -z "$due" ]; then
      felix_route_step_used "$transcript" "$p" && continue
      due="$p"
    else
      rest="$rest $p"
    fi
  done
  [ -n "$due" ] || return 1
  printf '%s\t%s' "$due" "${rest# }"
}

# Steps a route asked for that the session never used. Read at the finish line,
# where "you are about to call this done and never opened a browser" is a fact
# about the work rather than a rule quoted at turn one.
felix_route_skipped() {
  local transcript="$1" play="$2" p out=""
  [ -n "$play" ] && [ "$play" != "-" ] || return 0
  for p in $play; do
    felix_route_step_used "$transcript" "$p" || out="$out $p"
  done
  printf '%s' "${out# }"
}

# Add a tool to a route's play, in place.
#
# Appended, never reordered. A play is ordered — the router names the first
# entry that has not been used yet — so rewriting one to insert something would
# change what a session is told to reach for first, which is not what "also make
# this reachable" means.
#
# Comments and row order are preserved because this table is written by hand and
# its comments explain why rows sit where they do. Returns 1 when the route does
# not exist or already names the tool, so a caller can tell "wired" from
# "nothing to do".
felix_route_append_play() {
  local proj="$1" route="$2" tool="$3" tmp line n kw pr play found=0
  # Declared separately. A `local` statement does not reliably see a variable
  # being declared by the same statement, and under `set -u` that is an unbound
  # variable rather than an empty one.
  local f="$proj/routes.tsv"
  [ -f "$f" ] || return 1
  [ -n "$route" ] && [ -n "$tool" ] || return 1
  tmp="$(mktemp)" || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      ''|'#'*) printf '%s\n' "$line" >> "$tmp"; continue ;;
    esac
    IFS=$'\t' read -r n kw pr play <<EOF
$line
EOF
    if [ "${n:-}" = "$route" ]; then
      case " ${play:-} " in
        *" $tool "*) : ;;                       # already there
        *)
          # `-` is the template's way of writing "no play", so it is replaced
          # rather than appended to. Leaving it would emit "- playwright", and
          # the router would try to name a tool called "-".
          case "${play:-}" in
            ''|'-') play="$tool" ;;
            *)      play="$play $tool" ;;
          esac
          found=1 ;;
      esac
      printf '%s\t%s\t%s\t%s\n' "$n" "$kw" "$pr" "$play" >> "$tmp"
    else
      printf '%s\n' "$line" >> "$tmp"
    fi
  done < "$f"
  [ "$found" -eq 1 ] || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$f"
}

# Hits and misses both. The misses are the raw material for --promote, and they
# are the only record of what the table failed to understand.
felix_route_log() {
  local proj="$1" name="$2" score="$3" prompt="$4"
  local mem; mem="$(felix_mem_dir "$proj")"
  [ -d "$mem" ] || mkdir -p "$mem" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${name:--}" "${score:-0}" \
    "$(printf '%s' "$prompt" | _felix_envelope_strip | tr '\t\n' '  ' | LC_ALL=C cut -c1-160)" \
    >> "$mem/routes.log" 2>/dev/null || true
}

# Words that keep turning up in prompts the table did not understand.
#
# Frequency, not understanding — the same caveat felix promote already prints
# about the devlog. Felix does not edit routes.tsv itself, for the reason
# felix lesson is a command rather than an inference.
# Whether any route's play names this capability at all.
#
# The question a zero cannot answer on its own. A capability nobody reached for
# means one of two things, and they lead opposite ways: the table names it and
# its keywords never matched the work anybody does, which is a keyword problem;
# or no play mentions it, in which case no keyword could ever have reached it
# and asking somebody to fix the keywords is asking for the impossible.
#
# Matched against the play entries rather than the whole line, and a play entry
# may be qualified — `superpowers:brainstorming` is owned by `superpowers`, so
# the plugin counts as named when a skill of its is. That is the same ownership
# rule `_felix_route_kind` resolves against the manifest.
felix_route_names_capability() {
  local proj="$1" want="$2" n p pr pl entry
  [ -n "$want" ] || return 1
  [ -f "$proj/routes.tsv" ] || return 1
  while IFS=$'\t' read -r n p pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pl:-}" ] && [ "$pl" != "-" ] || continue
    for entry in $pl; do
      case "$entry" in
        "$want"|"$want":*) return 0 ;;
      esac
    done
  done < "$proj/routes.tsv"
  return 1
}

# Whether a recorded route was Felix's guess rather than something asked for.
#
# Lives here rather than inside the Stop hook so it can be tested at all. The
# first version of this decision was hook-internal, and the test written for it
# was vacuous — it drove the whole hook through a fixture whose transcript path
# was empty, so the complaint never fired in either direction and the assertion
# that it stayed quiet passed by finding nothing.
#
# Tab-separated second field. Not a third colon field: a due step is a play
# entry and play entries contain colons, so a colon scheme silently read part of
# the step name instead — and did, in production, while every fixture using a
# due step of `done` passed. Anything that is not `tree` means somebody
# typed words that chose this route, including the empty third field of a state
# file written before provenance existed — which complains, exactly as it did
# before. Hooks bind at session start, so writer and reader are always the same
# version and that case is only ever a stale file from a session that is gone.
felix_route_state_guessed() {
  local state="$1"
  [ -f "$state" ] || return 1
  case "$(cut -f2 < "$state" 2>/dev/null)" in
    tree) return 0 ;;
    *)    return 1 ;;
  esac
}

felix_route_promote() {
  # Two `local` statements, not one. `local proj="$1" log="$proj/…"` expands
  # every word before it assigns any of them, so `$proj` was read before it
  # existed and this looked for `/memory/routes.log` — absent, so the function
  # returned nothing and reported no misses at all. It appeared to work from the
  # CLI and only from there: `cmd_route` happens to hold a variable called
  # `proj`, and bash's scoping handed that one over. Correct output from the one
  # caller anybody ran, and silence from every other.
  local proj="$1"
  local log="$(felix_mem_dir "$proj")/routes.log"
  [ -f "$log" ] || return 0
  awk -F'\t' '$2 == "-" { print $4 }' "$log" \
    | _felix_route_words \
    | sort | uniq -c | sort -rn \
    | awk -v m="$FELIX_ROUTE_PROMOTE_MIN" '$1 >= m { print $1 "\t" $2 }'
}

# ---------------------------------------------------------------- decisions --
# The recording-only half of the deliberation layer, and deliberately nothing
# more. HANDOFF §0z records the founder's architecture — deliberation forcing
# plus decision-action closure — and the gate on building it. It also records
# the measurement floor: "the only way to observe 'the agent considered
# capability X and decided NONE' is to require that decision be emitted", and
# names the way through — a recording-only version that asks, enforces nothing,
# and changes no behaviour. This is that, and it must stay that: anything here
# that begins to *enforce* is the architecture the founder held, being built
# without the decision.
#
# Three verdicts existed before this file and were already recorded: `named`
# (the ledger, written when a mandate is rendered), `reached` (the ledger,
# written when a capability is invoked), and silence. What was missing is the
# one that carries information the others cannot: DECLINED, with the reason.
# A decline is a session saying "I considered this and it does not fit" — the
# labeled example a keyword table cannot generate about itself.
#
# The ack is keyed by repository, not session, because the CLI cannot know the
# session id — that arrives only in hook payloads. Two concurrent sessions in
# one checkout can therefore consume each other's ack, which degrades the safe
# way: one missed close-of-session complaint, never a wrong one. Same argument,
# same direction as the announce dedup in user-prompt.
_felix_route_ack_path() {
  # $1 = repo root, $2 = home
  printf '%s/state/route/ack-%s' "$2" "$(printf '%s' "$1" | _felix_hash)"
}

# Record a decline: one line of state for the Stop hook to consume, one durable
# row in decisions.log for whoever revises the table. The state line is
# best-effort; the record is the point.
felix_route_ack() {
  local proj="$1" root="$2" home="$3" reason="$4" now dir
  [ -n "$reason" ] || return 1
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  dir="$(felix_mem_dir "$proj")"
  mkdir -p "$dir" 2>/dev/null
  printf '%s\t%s\tdeclined\t%s\n' "$now" "$root" "$reason" >> "$dir/decisions.log" || return 1
  mkdir -p "$home/state/route" 2>/dev/null && \
    printf '%s\t%s\n' "$(date +%s)" "$reason" > "$(_felix_route_ack_path "$root" "$home")" 2>/dev/null
  return 0
}

# Has this repo's rendered mandate been declined on the record? Consumes the
# ack when it answers yes, so one decline quiets one complaint rather than all
# future ones — a permanently-standing ack would be a mute button, and a mute
# button on the only compliance signal is how the signal dies.
felix_route_ack_consume() {
  local root="$1" home="$2" path
  path="$(_felix_route_ack_path "$root" "$home")"
  [ -f "$path" ] || return 1
  rm -f "$path" 2>/dev/null
  return 0
}

# The monitor: everything Felix does that nobody can see.
#
# A hook's additionalContext goes to the model and never to the terminal. That
# is the correct channel — it is an instruction, not an announcement — but it
# means the routing decisions, the completion-gate verdicts and the capability
# accounting all happen behind glass. When it works you cannot tell, and when it
# misroutes you cannot tell why. Both are bad, and the second is worse.
#
# So the record becomes a page. Bash reads the logs it already writes and fills
# one self-contained HTML file: no server, no runtime, no network, nothing to
# install. It is a snapshot rather than a live feed, which is honest about what
# a shell script can promise, and re-running the command is the refresh.

# Minimal JSON string escaping. Enough for TSV fields and prompt text, which is
# all this handles; anything richer would mean the logs had outgrown TSV.
#
# Angle brackets become < and >, which is still valid JSON and is the
# point of the exercise: this JSON is embedded inside a <script> element, and an
# HTML parser looks for the literal characters `</script>` without caring that
# they sit inside a string literal. A prompt containing that sequence — and the
# route log records whatever was typed — would close the tag early, breaking the
# page at best and injecting markup into it at worst.
_felix_json_esc() {
  printf '%s' "$1" \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' -e 's/\r//g' \
          -e 's/</\\u003c/g' -e 's/>/\\u003e/g' \
    | tr '\n' ' '
}

# The route log stores the raw hook payload, because the hook does not parse it.
# For a human reading the page, the sentence is the point and the envelope is
# noise, so it is pulled out here rather than polluting the log format.
_felix_mon_prompt() {
  local raw="$1" p
  p="$(printf '%s' "$raw" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"
  [ -n "$p" ] && printf '%s' "$p" || printf '%s' "$raw"
}

# tail -n of a tsv as a json array, newest first, via a per-row formatter.
# How many rows the file actually holds.
#
# _felix_mon_rows below is a `tail -n limit` reader and bounding the payload is
# right — the page does not need 755 rows to draw a list. What was wrong is
# that the template then rendered `array.length` as a labelled TOTAL: "things
# said" read 60 over a log holding 755, and "gate failures" read 20 over 36.
# A window is a fine thing to show and a wrong thing to count, so the count
# travels beside the window rather than being derived from it.
# awk under LC_ALL=C, for a smaller reason than the one first written here. I
# claimed grep mis-counted routes.log; it does not, and the measurement that
# said so was taken through a shell whose `grep` is ugrep with -I, which skips
# a file it reads as binary. Real grep counts it correctly. What survives is
# only that these logs hold whatever a session said — routes.log here is
# "Non-ISO extended-ASCII text" — and awk counts lines without any binary-file
# heuristic in the way, so it does not depend on which grep is on PATH.
_felix_mon_count() {
  [ -f "$1" ] || { printf 0; return 0; }
  LC_ALL=C awk '$0 != "" { n++ } END { print n + 0 }' "$1" 2>/dev/null || printf 0
}

_felix_mon_rows() {
  local file="$1" limit="$2" fmt="$3" first=1 line
  printf '['
  [ -f "$file" ] || { printf ']'; return 0; }
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    "$fmt" "$line"
  done <<EOF
$(tail -n "$limit" "$file" | sed '1!G;h;$!d')
EOF
  printf ']'
}

_felix_mon_route_row() {
  local t r s p
  t="$(printf '%s' "$1" | cut -f1)"; r="$(printf '%s' "$1" | cut -f2)"
  s="$(printf '%s' "$1" | cut -f3)"; p="$(printf '%s' "$1" | cut -f4-)"
  printf '{"t":"%s","route":"%s","score":%s,"prompt":"%s"}' \
    "$(_felix_json_esc "$t")" "$(_felix_json_esc "$r")" "${s:-0}" \
    "$(_felix_json_esc "$(_felix_mon_prompt "$p")")"
}

_felix_mon_verify_row() {
  printf '{"t":"%s","verdict":"%s","tid":"%s","reason":"%s"}' \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f1)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f2)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f3)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f4)")"
}

# What Felix said, verbatim. The newline escaping is undone here so the page
# can show it as it was actually delivered.
# Reads both shapes of this record.
#
# A session column was inserted in the middle of an existing format, and every
# line written before that change has one fewer field: parsed as the new shape,
# the text lands in the cause and the page attributes a gate verdict to a prompt
# nobody typed. Counting the fields costs nothing and means old history stays
# readable instead of being quietly rearranged.
_felix_mon_say_row() {
  local n sess cause text
  n="$(printf '%s' "$1" | awk -F'\t' '{print NF}')"
  if [ "${n:-0}" -ge 5 ]; then
    sess="$(printf '%s' "$1" | cut -f3)"
    cause="$(printf '%s' "$1" | cut -f4)"
    text="$(printf '%s' "$1" | cut -f5-)"
  else
    sess=""
    cause="$(printf '%s' "$1" | cut -f3)"
    text="$(printf '%s' "$1" | cut -f4-)"
  fi
  printf '{"t":"%s","kind":"%s","session":"%s","cause":"%s","text":"%s"}' \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f1)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f2)")" \
    "$(_felix_json_esc "$sess")" \
    "$(_felix_json_esc "$cause")" \
    "$(_felix_json_esc "$text")"
}

_felix_mon_mistake_row() {
  printf '{"date":"%s","branch":"%s","commit":"%s","what":"%s"}' \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f1)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f2)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f3)")" \
    "$(_felix_json_esc "$(printf '%s' "$1" | cut -f4)")"
}

_felix_mon_json_list() {
  local first=1 x
  printf '['
  while IFS= read -r x; do
    [ -n "$x" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '"%s"' "$(_felix_json_esc "$x")"
  done
  printf ']'
}

_felix_mon_project() {
  local proj="$1" home="$2" name gate rec
  name="$(basename "$proj")"
  gate="$(felix_json_str "$proj/project.json" gate)"

  printf '{"name":"%s","gate":"%s"' "$(_felix_json_esc "$name")" "$(_felix_json_esc "$gate")"

  printf ',"capabilities":'
  if [ -f "$proj/capabilities" ]; then
    grep -v '^$' "$proj/capabilities" | _felix_mon_json_list
  else printf '[]'; fi

  printf ',"routes":['
  local first=1 n k pr pl
  while IFS=$'\t' read -r n k pr pl; do
    case "$n" in ''|'#'*) continue ;; esac
    [ -n "${pr:-}" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '{"name":"%s","keywords":"%s","profile":"%s","play":"%s"}' \
      "$(_felix_json_esc "$n")" "$(_felix_json_esc "$k")" \
      "$(_felix_json_esc "$pr")" "$(_felix_json_esc "${pl:--}")"
  done < "${proj}/routes.tsv" 2>/dev/null
  printf ']'

  printf ',"stack":['
  first=1
  # Six, for the reason cmd_profile carries: a trailing read variable absorbs
  # the grounding column and its tab, and _felix_json_esc escapes the tab
  # rather than dropping it, so the payload would carry "llm\tOBSERVED" as a
  # capability — valid JSON saying something untrue.
  local kind sname src risk cap ground
  while IFS=$'\t' read -r kind sname src risk cap ground; do
    case "$kind" in ''|'#'*) continue ;; esac
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '{"kind":"%s","name":"%s","risk":"%s","capability":"%s"}' \
      "$(_felix_json_esc "$kind")" "$(_felix_json_esc "$sname")" \
      "$(_felix_json_esc "${risk:-}")" "$(_felix_json_esc "${cap:-always}")"
  done < "${proj}/stack.tsv" 2>/dev/null
  printf ']'

  local _md; _md="$(felix_mem_dir "$proj")"
  printf ',"routeLog":'
  _felix_mon_rows "$_md/routes.log" 40 _felix_mon_route_row
  printf ',"routeLogTotal":%s' "$(_felix_mon_count "$_md/routes.log")"
  printf ',"verifyLog":'
  _felix_mon_rows "$_md/verification.log" 40 _felix_mon_verify_row
  printf ',"verifyLogTotal":%s' "$(_felix_mon_count "$_md/verification.log")"
  printf ',"mistakes":'
  _felix_mon_rows "$_md/mistakes.log" 20 _felix_mon_mistake_row
  printf ',"mistakesTotal":%s' "$(_felix_mon_count "$_md/mistakes.log")"
  printf ',"says":'
  _felix_mon_rows "$_md/says.log" 60 _felix_mon_say_row
  printf ',"saysTotal":%s' "$(_felix_mon_count "$_md/says.log")"
  # Counted over the whole file, not the window, for the same reason: this is
  # rendered as an absolute "times held", and 20 of the last 60 is not 109.
  printf ',"heldTotal":%s' \
    "$(LC_ALL=C awk -F'\t' '$2 == "held" || $2 == "plugin-blocked" { n++ } END { print n + 0 }' "$_md/says.log" 2>/dev/null || printf 0)"

  printf ',"compliance":['
  first=1
  local cs cd cn cf ci
  while IFS=$'\t' read -r cs cd cn cf ci; do
    [ -n "${cs:-}" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    printf '{"session":"%s","date":"%s","named":%s,"followed":%s,"ignored":%s}' \
      "$(_felix_json_esc "$cs")" "$(_felix_json_esc "$cd")" "$cn" "$cf" "$ci"
  done <<EOF
$(felix_monitor_compliance "$proj")
EOF
  printf ']'

  printf ',"lessons":%s' "$(felix_count '^- \*\*' "$(felix_mem_dir "$proj")/lessons.md")"
  printf '}'
}

# The whole state of the governance layer, as one JSON object.
# Whether the session did what Felix named.
#
# Everything else this file renders is a record of what Felix *said*. This is
# the only figure that speaks to whether any of it lands, which makes it the
# one panel worth having: a route table nobody follows is an expensive way of
# talking to yourself.
#
# Arithmetic on committed rows, never a transcript reader. `named` is what a
# route pointed at, written by UserPromptSubmit at the moment it pointed;
# `calls` is what got reached for, written by PostToolUse. Both were already in
# the ledger and nothing had ever put them side by side.
#
# Emits: session <TAB> date <TAB> named <TAB> followed <TAB> ignored
#
# Rows with no `named` column are skipped entirely rather than counted as zero.
# A ledger written before that column cannot answer this question, and counting
# nothing would render as perfect compliance — the most flattering possible
# reading of an absence, which is the one to refuse.
felix_monitor_compliance() {
  local proj="$1"
  # Split, because `local a=$1 b=$a` expands every word before it assigns any of
  # them, so the second reads an unbound name under set -u.
  local mem="$(felix_mem_dir "$proj")"
  command -v _felix_ledger_rows >/dev/null 2>&1 || return 0
  _felix_ledger_rows "$mem" | awk -F'\t' '
    NF >= 6 && $6 != "" && $6 + 0 > 0 {
      key = $1 SUBSEP $2
      if (!(key in seen)) { seen[key] = 1; order[++n] = key; sess[key] = $1; day[key] = $2 }
      named[key]++
      if ($5 + 0 > 0) followed[key]++
    }
    END {
      for (i = 1; i <= n; i++) {
        k = order[i]
        printf "%s\t%s\t%s\t%s\t%s\n", sess[k], day[k], named[k],
               followed[k] + 0, named[k] - (followed[k] + 0)
      }
    }
  '
}

felix_monitor_json() {
  local home="$1" first=1 p
  printf '{"generated":"%s","home":"%s"' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(_felix_json_esc "$home")"

  printf ',"projects":['
  for p in "$home"/projects/*/; do
    [ -d "$p" ] || continue
    [ -f "${p}project.json" ] || continue
    [ "$first" -eq 1 ] || printf ','
    first=0
    _felix_mon_project "${p%/}" "$home"
  done
  printf ']'

  # There was a `plugins` array here, filled by `claude plugin list --json`. It
  # cost 933ms of a 2.3s render and the page referenced it exactly zero times.
  # That is affordable once a day and not affordable several times a minute,
  # which is what the live mode needs, so it is gone until something reads it.
  printf '}'
}

# Fill the template. The data is injected at a single marker so the page stays
# a plain file that opens with no server and no network.
# The data goes via a file, and the splice is done by hand rather than with
# awk's sub(). Both details are load-bearing: `awk -v` interprets backslash
# escapes, which would eat every \" in the JSON, and sub() treats `&` in a
# replacement as the matched text, which would corrupt any prompt containing an
# ampersand. Neither failure would be visible until a page silently lost data.
felix_monitor_render() {
  local tpl="$1" home="$2" out="$3" tmp
  [ -f "$tpl" ] || return 1
  mkdir -p "$(dirname "$out")" 2>/dev/null || return 1
  tmp="$(mktemp)" || return 1
  felix_monitor_json "$home" > "$tmp" 2>/dev/null
  awk -v df="$tmp" '
    {
      n = index($0, "/*{{FELIX_DATA}}*/")
      if (n > 0) {
        printf "%s", substr($0, 1, n - 1)
        while ((getline line < df) > 0) printf "%s", line
        close(df)
        print substr($0, n + 18)
        next
      }
      print
    }
  ' "$tpl" > "$out" 2>/dev/null
  rm -f "$tmp"
  [ -s "$out" ]
}

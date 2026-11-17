# tests/lib/audit-review.sh: the helpers and fixtures the audit review sections share.
# Used by parts 0820 (builds RV and the hid sessions) 0830 0840 0850. Moved from
# parts/0820-felix-new-no-commission-governed-not-commiss.sh: _rv_new from line 142, RV and _rv_ts from lines 140-141 (into _rv_build)
# and the hid sessions from lines 146-160 (into _rv_hid_build); from
# parts/0830-felix-audit-what-the-reviews-left-open.sh: _rv_one and _rv_says from lines 7-13; from
# parts/0840-felix-audit-what-the-third-review-found.sh: _rv_bigawk from lines 328-339. Definitions only.

_rv_new() { _au_open "$RV/$1/-Users-dev-rv/$2.jsonl" "$2"; }
_rv_one() {  # dir session command [ok|true]: an edit, one Bash call, its result, a stop
  _rv_new "$1" "$2"; _au_edit "$_rv_ts:01.000Z" "msg_$2a" "toolu_$2a"
  _au_bash "$_rv_ts:02.000Z" "msg_$2b" "toolu_$2b" "$3"; _au_res "$_rv_ts:03.000Z" "toolu_$2b" "${4:-ok}"
  _au_stop "$_rv_ts:04.000Z" "msg_$2c"; }
# True when the text, its lines joined and case folded, matches the ERE. It
# reads its whole input, for the reason _au_first gives.
_rv_says() { printf '%s\n' "$1" | awk -v re="$2" '{ s = s " " tolower($0) } END { exit (s ~ re) ? 0 : 1 }'; }
# one(file, id, command) writes a session of an edit, that Bash command, its
# passing result and a stop; rep(s, n) is s n times, in log n concatenations.
# _audit_review_vars: the variables this file's functions read, set when the prelude calls it
# (contract C2: a lib file defines functions and nothing else).
_audit_review_vars() {
_rv_bigawk='
  function A(id, content, sr) {
    return "{\"parentUuid\":\"p\",\"isSidechain\":false,\"message\":{\"model\":\"m\",\"id\":\"" id "\",\"type\":\"message\",\"role\":\"assistant\",\"content\":[" content "],\"stop_reason\":\"" sr "\"},\"type\":\"assistant\",\"uuid\":\"u-" id "\",\"timestamp\":\"2026-04-03T10:00:00.000Z\"}" }
  function one(f, id, cmd) {
    print A("msg_" id "e", "{\"type\":\"tool_use\",\"id\":\"toolu_" id "e\",\"name\":\"Edit\",\"input\":{\"file_path\":\"/w/a.js\"}}", "tool_use") > f
    print A("msg_" id "b", "{\"type\":\"tool_use\",\"id\":\"toolu_" id "b\",\"name\":\"Bash\",\"input\":{\"command\":\"" cmd "\"}}", "tool_use") > f
    print "{\"parentUuid\":\"p\",\"isSidechain\":false,\"type\":\"user\",\"message\":{\"role\":\"user\",\"content\":[{\"tool_use_id\":\"toolu_" id "b\",\"type\":\"tool_result\",\"content\":\"ok\"}]},\"uuid\":\"u-r" id "\",\"timestamp\":\"2026-04-03T10:00:01.000Z\"}" > f
    print A("msg_" id "s", "{\"type\":\"text\",\"text\":\"Done.\"}", "end_turn") > f
    close(f) }
  function rep(s, n,    r) { r = ""; while (n > 0) { if (n % 2) r = r s; s = s s; n = int(n / 2) } return r }'
}

# _rv_build: RV, the root of the review fixtures under AU, and the timestamp they share.
# Needs _au_build first. Makes nothing.
_rv_build() {
RV="$AU/rv"
_rv_ts=2026-04-02T10:00
}

# _rv_hid_build: the five sessions under RV/hid whose checks a pipe, a later command or the
# background hides from the audit; 0840 copies h1 from them. Needs _au_build and _rv_build.
_rv_hid_build() {
  [ -s "$RV/hid/-Users-dev-rv/h5.jsonl" ] && return 0
_rv_new hid h1; _au_edit "$_rv_ts:01.000Z" msg_H1a toolu_H1a
_au_bash "$_rv_ts:02.000Z" msg_H1b toolu_H1b 'npm test 2>&1 | tail -5'; _au_res "$_rv_ts:03.000Z" toolu_H1b ok
_au_stop "$_rv_ts:04.000Z" msg_H1c
_rv_new hid h2; _au_edit "$_rv_ts:01.000Z" msg_H2a toolu_H2a
_au_bash "$_rv_ts:02.000Z" msg_H2b toolu_H2b 'pytest -q; echo done'; _au_res "$_rv_ts:03.000Z" toolu_H2b ok
_au_stop "$_rv_ts:04.000Z" msg_H2c
_rv_new hid h3; _au_edit "$_rv_ts:01.000Z" msg_H3a toolu_H3a
_au_tool toolu_H3b Bash '{"command":"npm test","run_in_background":true}'; _au_a "$_rv_ts:02.000Z" msg_H3b '"tool_use"' "$_AU_B"
_au_res "$_rv_ts:03.000Z" toolu_H3b ok; _au_stop "$_rv_ts:04.000Z" msg_H3c
_rv_new hid h4; _au_edit "$_rv_ts:01.000Z" msg_H4a toolu_H4a
_au_bash "$_rv_ts:02.000Z" msg_H4b toolu_H4b 'set -o pipefail; npm test | tail -3'; _au_res "$_rv_ts:03.000Z" toolu_H4b ok
_au_stop "$_rv_ts:04.000Z" msg_H4c
_rv_new hid h5; _au_edit "$_rv_ts:01.000Z" msg_H5a toolu_H5a
_au_bash "$_rv_ts:02.000Z" msg_H5b toolu_H5b 'cd /w && npm test 2>&1'; _au_res "$_rv_ts:03.000Z" toolu_H5b ok
_au_stop "$_rv_ts:04.000Z" msg_H5c
}

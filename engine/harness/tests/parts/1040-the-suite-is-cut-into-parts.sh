
printf '\nthe suite is a driver and the parts it sources\n'
# tests/run was one file of 43,000 lines and 2.8 MB until 2026-10-10, and an
# editor's post-edit scanner refused to read it ("request payload exceeded
# maximum size") on every edit. It is a driver now, and the assertions are in
# parts beside it, each cut where it parses alone. Four things keep that cut
# from rotting: a part the driver does not source is a section of the suite
# that never runs, and the manifest would only say so after a full record; a
# part that is not named like the others is skipped by nothing and listed by
# nobody; a part that grows without a cut is the file this replaced; and a
# part that does not parse alone was cut inside a construct. The driver sources
# the parts one to a line and not in a loop on purpose: an arithmetic error
# inside $(( )) in bash 3.2 discards the whole top-level command it sits in, and
# a loop would make that the rest of the suite. The parts share its shell, in
# the order of its lines.
_pt="$HERE/parts"
is  "every file in parts is sourced by the driver once and in name order, and the driver sources none that is not there" \
    "$(sed -n 's|^\. "\$HERE/parts/\(.*\)"$|\1|p' "$HERE/run")" "$(cd "$_pt" && LC_ALL=C ls | LC_ALL=C sort)"
is  "and every part is NNNN-name.sh, four digits, so the order is the same under any locale" \
    "$(cd "$_pt" && LC_ALL=C ls | grep -vc '^[0-9][0-9][0-9][0-9]-[a-z0-9-]*[.]sh$')" "0"
# Every part and every lib file (tests/lib, contract C2), not the driver, which has its own limit below.
_pt_files=(); while IFS= read -r _ptf; do case "$_ptf" in */run) ;; *) _pt_files[${#_pt_files[@]}]="$_ptf" ;; esac; done < <(_suite_files)
_pt_mx="$(awk 'FNR == 1 && NR > 1 { if (n > m) { m = n; mf = pf } n = 0 } FNR == 1 { pf = FILENAME } { n++ } END { if (n > m) { m = n; mf = pf } print m + 0 " " mf }' "${_pt_files[@]}")"
_pt_max="${_pt_mx%% *}"
[ "$_pt_max" -le 1000 ] && ok  "no part is longer than 1,000 lines, and the driver is under 500" \
  || bad "no part is longer than 1,000 lines, and the driver is under 500" "the longest part has $_pt_max lines: ${_pt_mx#* }"
[ "$(awk 'END { print NR }' "$HERE/run")" -le 500 ] && ok  "and the driver itself is under 500 lines" \
  || bad "and the driver itself is under 500 lines" "it has $(awk 'END { print NR }' "$HERE/run")"
_pt_syn=""; for _ptf in "${_pt_files[@]}"; do _pt_syn="$_pt_syn$(bash -n "$_ptf" 2>&1)"; done
is  "every part parses on its own, with nothing said on stderr, so no cut sits inside a construct" "$_pt_syn" ""

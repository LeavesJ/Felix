# >>> the-lander-ages-what-waits
printf '\nthe lander ages what waits, and the stuck-PR page names the right actor (audit b03, A1-A28, blind)\n'
# Blind, written on 2026-10-24 from the audit b03 contract alone ("session start
# names what waits", sections 2.1 and 2.5, assertions A1-A28), before the fix and
# without reading lib/green-tick.sh, lib/pr-status*.sh or the felix CLI. Parts
# 1280-1289 and 1300-1360 and the fixture libs were read only for how their
# fixtures and stubs are built. Part 1670 carries A29-A63.
#
# The tick (FX-T): the land-on-green fixture of tests/lib/land-on-green.sh, built
# fresh here (an earlier part may have moved main or the cache), so no deploy is
# owed. Ledger rows are written by hand, their times relative to now. PR 31 has
# no worktree, so a tick reads it as waiting on a session; PR 32's worktree sits
# behind its head; PR 40's worktree holds its head. The page (FX-P): the stuck-PR
# fixture of tests/lib/stuck-pr.sh for the trust base and the waiting rows, and a
# fixture of this part's own for C027: an origin whose path ends
# github.com/acme/app.git, whose gh stub answers `api user` from ctl/user.json
# (the whole body, whatever --jq asks) or fails as ctl/user.rc and ctl/user.err say.
# Where the contract leaves a shape open, these assert only what it states.

# ---- helpers -----------------------------------------------------------------------
_ag_t() {   # SECONDS-AGO -> that moment as UTC ISO
  local t; t="$(( $(date +%s) - $1 ))"
  date -u -r "$t" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "@$t" +%Y-%m-%dT%H:%M:%SZ
}
_ag_row() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$LAND/ledger.tsv"; }   # TIME EVENT PR HEAD WORKTREE WALL DETAIL
_ag_new() { _lg_reset; mkdir -p "$LAND"; : > "$LAND/ledger.tsv"; }
_ag_last() {   # PR -> fields 2-7 of that PR's last row, joined by |
  LC_ALL=C awk -F'\t' -v p="$1" '$3 == p { l = $2 "|" $3 "|" $4 "|" $5 "|" $6 "|" $7 } END { printf "%s", l }' "$LAND/ledger.tsv" 2>/dev/null
}
_ag_wn() { _lg_n waiting "$1"; }
_ag_osa() {   # TEXT -> how many osascript calls carry it
  if [ -f "$LGL/osa.log" ]; then LC_ALL=C awk -v t="$1" 'index($0, t) { n++ } END { print n + 0 }' "$LGL/osa.log"; else echo 0; fi
}
_ag_has() { case "$1" in *"$2"*) printf 'yes' ;; *) printf 'no[%s]' "$1" ;; esac; }
AGNC="no checkout holds the gated head"
AGHOLD='[{"id":"L1","name":"felix:hold","description":"","color":"ededed"}]'
AGNF='[{"id":"L3","name":"needs-founder","description":"","color":"ededed"}]'

# ---- the tick (FX-T) ---------------------------------------------------------------
LGH=""; _lg_build base
H31="$(_lg_sha 31)"; H32="$(_lg_sha 32)"; H32A="$(_lg_sha 32a)"; H40="$(_lg_sha 40)"
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31; _lg_land --tick
is "b03 (fixture control): a tick over green PR 31, which no checkout holds, writes one session row reading no checkout holds the gated head and notifies nothing" \
   "$LGRC|$(_lg_rows)|$(_lg_f session 31 7)|$(_lg_cnt osa)" "0|1|$AGNC|0"
_ag_new; _lg_prs "$(_lg_pr 31 false "$AGNF")"; _lg_green 31; _lg_land --tick
is "b03 (fixture control): the tick's own skip row for a PR labelled needs-founder reads labelled needs-founder" \
   "$(_lg_f skip 31 7)" "labelled needs-founder"

# A1, A2, A11: one session row five hours old, then three ticks.
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
AGT0="$(_ag_t 18000)"; _ag_row "$AGT0" session 31 "$H31" - 1 "$AGNC"
_lg_land --tick
is "b03 A1: a session wait five hours old gets exactly one waiting row, worktree - and wall 0, saying it waits on a session since that row, notified once as Felix: waiting #31" \
   "$(_lg_rows)|$(_ag_last 31)|$(_ag_osa 'with title "Felix: waiting #31"')" \
   "2|waiting|31|$H31|-|0|waits on a session since $AGT0: session: $AGNC|1"
AGr="$(_lg_rows)"; AGo="$(_lg_cnt osa)"; _lg_land --tick
is "b03 A2: a second tick straight after the waiting row adds no row and makes no osascript call" \
   "$(_lg_rows)|$(_lg_cnt osa)" "$AGr|$AGo"
_lg_land --tick
is "b03 A11: a third tick over the same state still holds exactly one session row for #31 and no skip row" \
   "$(_lg_n session 31)|$(_lg_n skip 31)" "1|0"

# A3: a waiting row for the same head, 25 hours old, then 23 hours old.
AGd="waits on a session since $AGT0: session: $AGNC"
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
_ag_row "$AGT0" session 31 "$H31" - 1 "$AGNC"; _ag_row "$(_ag_t 90000)" waiting 31 "$H31" - 0 "$AGd"
_lg_land --tick; AGa="$(_ag_wn 31)"
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
_ag_row "$AGT0" session 31 "$H31" - 1 "$AGNC"; _ag_row "$(_ag_t 82800)" waiting 31 "$H31" - 0 "$AGd"
_lg_land --tick
is "b03 A3: a waiting row for the same PR and head 25 hours old is followed by one new waiting row; one 23 hours old by none, and no notification" \
   "$AGa|$(_ag_wn 31)|$(_ag_osa 'Felix: waiting')" "2|1|0"

# A4: session 6 h, skip conflicting with main 3 h, session 1 h, all at H.
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
AGT6="$(_ag_t 21600)"; _ag_row "$AGT6" session 31 "$H31" - 1 "$AGNC"
_ag_row "$(_ag_t 10800)" skip 31 "$H31" - 0 "conflicting with main"; _ag_row "$(_ag_t 3600)" session 31 "$H31" - 1 "$AGNC"
_lg_land --tick
is "b03 A4: a run of session, conflicting and session rows at one head waits since its first row: one waiting row, since the six-hour row, ending with the newest row's event and detail" \
   "$(_ag_wn 31)|$(_lg_f waiting 31 7)" "1|waits on a session since $AGT6: session: $AGNC"

# A5 [control]: a draft skip between two session rows breaks the run.
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
_ag_row "$(_ag_t 21600)" session 31 "$H31" - 1 "$AGNC"; _ag_row "$(_ag_t 10800)" skip 31 "$H31" - 0 "a draft"
_ag_row "$(_ag_t 7200)" session 31 "$H31" - 1 "$AGNC"
_lg_land --tick
is "b03 A5: a skip for a draft between two session rows ends the run, so a run two hours old gets no waiting row (control)" "$(_ag_wn 31)" "0"

# A6 [control]: a session row at an older head does not start the run at this head.
_ag_new; _lg_prs "$(_lg_pr 32)"; _lg_green 32
_ag_row "$(_ag_t 21600)" session 32 "$H32A" - 1 "$AGNC"; _ag_row "$(_ag_t 3600)" session 32 "$H32" - 1 "$AGNC"
_lg_land --tick
is "b03 A6: a session row at an older head six hours old and one at the listed head an hour old give no waiting row (control)" "$(_ag_wn 32)" "0"

# A7 [control]: hold rows ten days old, gh's list agreeing.
AGa=""; AGT10="$(_ag_t 864000)"
for AGk in draft hold cross base; do
  _ag_new; _lg_green 31
  case "$AGk" in
    draft) _lg_prs "$(_lg_pr 31 true)"; AGd="a draft" ;;
    hold)  _lg_prs "$(_lg_pr 31 false "$AGHOLD")"; AGd="labelled felix:hold" ;;
    cross) _lg_prs "$(_lg_pr 31 false '[]' MERGEABLE true)"; AGd="cross-repository: the head is not in this repository" ;;
    base)  _lg_prs "$(_lg_pr 31 false '[]' MERGEABLE false dev)"; AGd="its base is dev, not main: only pull requests into main are merged" ;;
  esac
  _ag_row "$AGT10" skip 31 "$H31" - 0 "$AGd"; _lg_land --tick
  AGa="$AGa $AGk:$(_ag_wn 31)/$(_lg_cnt osa)"
done
is "b03 A7: a draft, felix:hold, cross-repository or other-base skip ten days old, with gh agreeing, gives no waiting row and no notification (control)" \
   "$AGa" " draft:0/0 hold:0/0 cross:0/0 base:0/0"

# A8: a needs-founder skip five hours old waits on the founder.
_ag_new; _lg_prs "$(_lg_pr 31 false "$AGNF")"; _lg_green 31
_ag_row "$(_ag_t 18000)" skip 31 "$H31" - 0 "labelled needs-founder"; _lg_land --tick
AGd="$(_lg_f waiting 31 7)"
is "b03 A8: a PR labelled needs-founder whose skip row is five hours old gets one waiting row that says it waits on the founder" \
   "$(_ag_wn 31)|${AGd:0:27}" "1|waits on the founder since "

# A9 [control]: gh lists no PR.
_ag_new; _ag_row "$AGT10" session 31 "$H31" - 1 "$AGNC"; _lg_land --tick
is "b03 A9: a PR gh does not list gets no row, whatever its ledger holds, and no notification (control)" "$(_lg_rows)|$(_lg_cnt osa)" "1|0"

# A10 [control]: a paused lander reads no PR list.
_ag_new; printf 'held for b03\n' > "$LAND/paused"; _lg_prs "$(_lg_pr 31)"; _lg_green 31
_ag_row "$(_ag_t 36000)" session 31 "$H31" - 1 "$AGNC"; _lg_land --tick
is "b03 A10: a paused tick writes no waiting row for a listed PR whose session row is ten hours old (control)" "$(_ag_wn 31)" "0"

# A12: a refusal at this head and this main, five hours old, held by a worktree.
AGM="$(git -C "$LGH" rev-parse refs/remotes/origin/main 2>/dev/null)"
_ag_new; _lg_prs "$(_lg_pr 40)"; _lg_green 40
printf 'felix merge: refused\n  blocker: the receipt is stale\n' > "$LGK/merge.b40.out"; printf '1\n' > "$LGK/merge.b40.rc"
_ag_row "$(_ag_t 18000)" refused 40 "$H40" "$LGW/b40" 3 "blocker: the receipt is stale [main $AGM]"
_lg_land --tick; AGd="$(_ag_has "$(_lg_f waiting 40 7)" ": refused: ")"; AGa="$(_lg_merges)"; _lg_land --tick
is "b03 A12: a PR refused at this head and main five hours ago gets a waiting row naming the refusal, and neither that tick nor the next runs felix merge" \
   "$(_ag_wn 40)|$AGd|$AGa|$(_lg_merges)" "1|yes||"

# A71 (review round, written on 2026-10-26 from the contract's section 9 alone)
# [control]: a run of session and conflicting rows 30 hours long with a waiting row
# inside it, then the same run with that waiting row 20 hours old.
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
AGT30="$(_ag_t 108000)"; AGd="waits on a session since $AGT30: session: $AGNC"
_ag_row "$AGT30" session 31 "$H31" - 1 "$AGNC"; _ag_row "$(_ag_t 90000)" waiting 31 "$H31" - 0 "$AGd"
_ag_row "$(_ag_t 68400)" skip 31 "$H31" - 0 "conflicting with main"; _ag_row "$(_ag_t 3600)" session 31 "$H31" - 1 "$AGNC"
_lg_land --tick
AGa="$(_ag_wn 31)|$(_lg_f waiting 31 7)|$(_ag_osa 'with title "Felix: waiting #31"')|$(_lg_n session 31)|$(_lg_n skip 31)"
_ag_new; _lg_prs "$(_lg_pr 31)"; _lg_green 31
_ag_row "$AGT30" session 31 "$H31" - 1 "$AGNC"; _ag_row "$(_ag_t 72000)" waiting 31 "$H31" - 0 "$AGd"
_ag_row "$(_ag_t 68400)" skip 31 "$H31" - 0 "conflicting with main"; _ag_row "$(_ag_t 3600)" session 31 "$H31" - 1 "$AGNC"
_lg_land --tick
is "b03 A71: over a session and conflicting run 30 hours long, a waiting row 25 hours old is followed by one new waiting row since the run's first row, notified once, and no new session or skip row; one 20 hours old by none (control)" \
   "$AGa|$(_ag_wn 31)|$(_ag_osa 'Felix: waiting')" "2|$AGd|1|2|1|1|0"

# ---- the page (FX-P): the stuck-PR fixture -----------------------------------------
_sp_build
AGP="$SP/b03"; mkdir -p "$AGP"; rm -f "$SPK/api.rc" "$SPK/loaded"
# A13, A14: #133's session row, then a later waiting row at the same head.
_sp_ledger; _sp_prs fixture_home "$(_sp_pr 133 notes/133.md:0 green)"
_sp_land "$SPH" --prs --tsv; cp "$SPX/out" "$AGP/w0.tsv"
printf '2026-10-16T13:13:00Z\twaiting\t133\t%s\t-\t0\twaits on a session since 2026-10-16T09:13:00Z: session: %s\n' "$(_sp_sha 133)" "$AGNC" >> "$SPLAND/ledger.tsv"
_sp_land "$SPH" --prs --tsv; cp "$SPX/out" "$AGP/w1.tsv"
AGa="$(_sp_f "$AGP/w0.tsv" 133 8)"; AGd="$(_sp_f "$AGP/w1.tsv" 133 8)"
is "b03 A13: a later waiting row changes nothing the page says of #133: refused, needs a session, the same detail, which says the lander cannot use it" \
   "$(_sp_state "$AGP/w1.tsv" 133)|$(_sp_f "$AGP/w1.tsv" 133 5)|$(_ag_has "$AGd" "the lander cannot use it: $AGNC")|$AGd" \
   "refused|session|yes|$AGa"
AGd="$(_sp_srcf "$AGP/w1.tsv" lander 8)"
is "b03 A14: with the waiting row the ledger's newest, the lander source row still names it as the last ledger row (control)" \
   "$(_ag_has "$AGd" "last ledger row")|$(_ag_has "$AGd" "waiting:")" "yes|yes"

# ---- the page (FX-P): an origin owned by acme, for C027 -----------------------------
AGA="$TMP/b03-acme"; rm -rf "$AGA"; mkdir -p "$AGA"; AGA="$(cd "$AGA" && pwd -P)"
AGAO="$AGA/github.com/acme/app.git"; AGAH="$AGA/home"; AGAM="$AGA/mem"; AGAU="$AGA/user"
AGAB="$AGA/bin"; AGAK="$AGA/ctl"; AGAL="$AGA/log"; AGAX="$AGA/out"; AGAT="$AGA/tmp"
mkdir -p "$AGAO" "$AGAM" "$AGAU/.config/gh" "$AGAB" "$AGAK" "$AGAL" "$AGAX" "$AGAT" "$AGA/cache"
_ag_put() { mkdir -p "$(dirname "$1")" && LC_ALL=C sed "s#@AG@#$AGA#g" > "$1" && chmod +x "$1"; }
_ag_put "$AGAB/gh" <<'AGSTUB'
#!/bin/bash
AG='@AG@'; K="$AG/ctl"
printf '%s\n' "$*" >> "$AG/log/gh.log"
jqx=""; repo=""; prev=""; bill=0; user=0; dflt=""
for a in "$@"; do
  case "$prev" in -q|--jq) jqx="$a" ;; -R|--repo) repo="$a" ;; esac
  case "$a" in --jq=*) jqx="${a#--jq=}" ;; --repo=*) repo="${a#--repo=}" ;; esac
  case "$a" in
    *settings/billing/usage*) bill=1; bq="$a" ;;
    user|/user) user=1 ;;
    repos/acme/app|/repos/acme/app|repos/acme/lib|/repos/acme/lib) dflt="${a#/}" ;;
  esac
  prev="$a"
done
if [ -z "$repo" ]; then
  u="$(git config --get remote.origin.url 2>/dev/null)"; u="${u%/}"; u="${u%.git}"
  n="${u##*/}"; o="${u%/*}"; o="${o##*/}"; [ -n "$n" ] && [ -n "$o" ] && repo="$o/$n"
fi
repo="${repo#https://}"; repo="${repo#github.com/}"; repo="${repo%.git}"
key="$(printf '%s' "$repo" | LC_ALL=C tr '/' '_')"
out() { if [ -n "$jqx" ] && command -v jq >/dev/null 2>&1; then jq -r "$jqx"; else cat; fi; }
case "${1:-} ${2:-}" in
  "pr list")
    [ -f "$K/prs.$key.json" ] || { printf 'stub: no answer for repository [%s]\n' "$repo" >&2; exit 4; }
    out < "$K/prs.$key.json"; exit 0 ;;
esac
if [ "${1:-}" = api ]; then
  if [ "$bill" = 1 ]; then by="${bq##*year=}"; by="${by%%&*}"; bm="${bq##*month=}"; bm="${bm%%&*}"; [ "${#bm}" -eq 1 ] && bm="0$bm"; printf '{"usageItems":[{"date":"%s-%s-01T00:00:00Z","product":"actions","sku":"Actions Linux","quantity":5.0,"unitType":"Minutes","pricePerUnit":0.006,"grossAmount":0.0,"discountAmount":0.0,"netAmount":0.0,"repositoryName":"home"}]}\n' "$by" "$bm" | out; exit 0; fi
  if [ "$user" = 1 ]; then
    if [ -f "$K/user.rc" ]; then cat "$K/user.err" >&2; exit "$(cat "$K/user.rc")"; fi
    cat "$K/user.json"; exit 0
  fi
  if [ -n "$dflt" ]; then printf '{"full_name":"%s","default_branch":"main"}\n' "${dflt#repos/}" | out; exit 0; fi
  printf 'gh: Not Found (HTTP 404)\n' >&2; exit 1
fi
printf 'stub: gh %s is not served\n' "$*" >&2
exit 1
AGSTUB
_ag_put "$AGAB/launchctl" <<'AGSTUB'
#!/bin/bash
printf '%s\n' "$*" >> '@AG@/log/launchctl.log'
case "${1:-}" in print) exit 113 ;; esac
exit 0
AGSTUB
_fx_git "$AGAO" init -q --bare >/dev/null 2>&1
_fx_git "$AGAO" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
_fx_git "$AGA" clone -q "$AGAO" home >/dev/null 2>&1
_fx_git "$AGAH" symbolic-ref HEAD refs/heads/main >/dev/null 2>&1
mkdir -p "$AGAH/projects/app" "$AGAH/projects/lib" "$AGAH/notes"
printf '{\n  "name": "app",\n  "remote_match": "github.com/acme/app",\n  "gate": "true"\n}\n' > "$AGAH/projects/app/project.json"
printf '{\n  "name": "lib",\n  "remote_match": "github.com/acme/lib",\n  "gate": "true"\n}\n' > "$AGAH/projects/lib/project.json"
printf '# app\n' > "$AGAH/projects/app/CLAUDE.md"; printf '# lib\n' > "$AGAH/projects/lib/CLAUDE.md"; printf 'app\n' > "$AGAH/README.md"
_fx_git "$AGAH" add -A >/dev/null 2>&1; _fx_git "$AGAH" -c user.name=t -c user.email=t@t commit -qm base >/dev/null 2>&1
_fx_git "$AGAH" push -q -u origin main >/dev/null 2>&1
_fx_git "$AGAH" fetch -q origin >/dev/null 2>&1; _fx_git "$AGAH" remote set-head origin main >/dev/null 2>&1
_ag_page() {   # ARGS -> felix land ARGS from the acme home; stdout in out/out, status in AGRC
  rm -rf "$AGAL"; mkdir -p "$AGAL"
  ( cd "$AGAH" || exit 97
    exec env -u FELIX_ALLOW_RED -u FELIX_KERNEL -u FELIX_KERNEL_CACHE -u CLAUDE_CODE_SESSION_ID \
      HOME="$AGAU" FELIX_HOME="$AGAH" FELIX_HOME_DIR="$AGAH" FELIX_MEMORY="$AGAM" FELIX_PLUGIN_CACHE="$AGA/cache" \
      XDG_STATE_HOME="$AGAU/.state" XDG_CACHE_HOME="$AGAU/.cache" GH_CONFIG_DIR="$AGAU/.config/gh" \
      TMPDIR="$AGAT" PATH="$AGAB:$PATH" "$FELIX" land "$@" ) > "$AGAX/out" 2> "$AGAX/err"
  AGRC=$?
}
_ag_prs() { local k="$1" s="" o; shift; { printf '['; for o in "$@"; do printf '%s%s' "$s" "$o"; s=","; done; printf ']\n'; } > "$AGAK/prs.$k.json"; }
_ag_user() { rm -f "$AGAK/user.rc" "$AGAK/user.err"; printf '%s\n' "$1" > "$AGAK/user.json"; }
_ag_ucnt() {   # FILE -> the gh calls that ask api for the signed-in account (user or /user)
  [ -f "$1" ] || { echo 0; return; }
  LC_ALL=C awk 'index($0, "api ") == 1 { for (i = 2; i <= NF; i++) if ($i == "user" || $i == "/user") { n++; break } } END { print n + 0 }' "$1"
}
_ag_sn() { printf '%s %s' "$(_sp_state "$1" "$2")" "$(_sp_f "$1" "$2" 5)"; }   # FILE N -> "state needs"
_ag_pra() { _sp_pr "$@" repo=acme/app; }
AGPR7="$(_ag_pra 7 notes/7.md:0 red author=alice mergeable=CONFLICTING mss=DIRTY)"
AGPR8="$(_ag_pra 8 notes/8.md:0 red author=alice)"
AGPR9="$(_ag_pra 9 notes/9.md:0 red author=bob)"
AGPR10="$(_ag_pra 10 notes/10.md:0 red author=ALICE)"
AGPR11="$(_ag_pra 11 notes/11.md:0 red author=acme)"
AGPR12="$(_ag_pra 12 notes/12.md:0 green author=alice cross=true)"

# A15-A17, A20, A21: one run, the signed-in account alice.
_ag_user '{"login":"alice","id":2,"type":"User"}'
_ag_prs acme_app "$AGPR12" "$AGPR10" "$AGPR9" "$AGPR8" "$AGPR7"
_ag_page --prs --tsv; cp "$AGAX/out" "$AGP/acme.tsv"; cp "$AGAL/gh.log" "$AGP/acme.gh.log" 2>/dev/null || : > "$AGP/acme.gh.log"
T3="$AGP/acme.tsv"
is "b03 A15: on acme/app, a same-repository PR by the signed-in account alice reads as an owner's: #7 conflicting needs-session session, #8 red session, #10 by ALICE red session" \
   "$AGRC|$(_ag_sn "$T3" 7)|$(_ag_sn "$T3" 8)|$(_ag_sn "$T3" 10)" "0|needs-session session|red session|red session"
AGd="$(_sp_f "$T3" 9 8)"
is "b03 A16: a PR by bob, neither the owner acme nor the signed-in alice, is outside and needs nobody, its detail naming bob, acme and alice" \
   "$(_ag_sn "$T3" 9)|$(_ag_has "$AGd" bob)|$(_ag_has "$AGd" acme)|$(_ag_has "$AGd" alice)" "outside nobody|yes|yes|yes"
is "b03 A17: a cross-repository PR by alice is outside and needs nobody (control)" "$(_ag_sn "$T3" 12)" "outside nobody"
AGa="$(_ag_ucnt "$AGP/acme.gh.log")"
_ag_prs acme_app "$AGPR12" "$AGPR11"; _ag_page --prs --tsv; AGb="$(_ag_ucnt "$AGAL/gh.log")"
_ag_prs acme_app "$AGPR10" "$AGPR9" "$AGPR8"; _ag_page --prs --tsv --no-gh
AGc="$(if [ -f "$AGAL/gh.log" ]; then LC_ALL=C awk 'END { print NR }' "$AGAL/gh.log"; else echo 0; fi)"
is "b03 A20: the signed-in account is asked once in that run, never when every PR is by acme or cross-repository, and under --no-gh gh is asked nothing" \
   "$AGa|$AGb|$AGc" "1|0|0"
AGd="$(LC_ALL=C awk 'index($0, "pr list") != 1 && index($0, "api") != 1' "$AGP/acme.gh.log" | head -3 | LC_ALL=C tr '\n' '|')"
AGb="$(LC_ALL=C awk 'index($0, "api") == 1' "$AGP/acme.gh.log" | LC_ALL=C grep -cE -- '(^| )(-X|--method|-f|-F|--field|--raw-field|--input)( |=|$)')"
is "b03 A21: every gh call of that run is pr list or api, and no api call carries a method, field or input option (control)" \
   "$([ -s "$AGP/acme.gh.log" ] && echo asked)|$AGd|$AGb" "asked||0"

# A18: the signed-in account fails to read.
rm -f "$AGAK/user.json"; printf '1\n' > "$AGAK/user.rc"; printf 'gh: Not Found (HTTP 404)\n' > "$AGAK/user.err"
_ag_prs acme_app "$AGPR11" "$AGPR8"; _ag_page --prs --tsv; cp "$AGAX/out" "$AGP/acme-nouser.tsv"
is "b03 A18: with gh api user failing, alice's PR is unknown and needs unknown, saying the signed-in account was not read, and acme's own red PR is red session" \
   "$(_ag_sn "$AGP/acme-nouser.tsv" 8)|$(_ag_has "$(_sp_f "$AGP/acme-nouser.tsv" 8 8)" "the signed-in GitHub account was not read")|$(_ag_sn "$AGP/acme-nouser.tsv" 11)" \
   "unknown unknown|yes|red session"

# A19: an answer with no login, then a login that is not one.
_ag_prs acme_app "$AGPR8"
_ag_user '{"message":"Bad credentials"}'; _ag_page --prs --tsv; AGa="$(_ag_sn "$AGAX/out" 8)"
_ag_user '{"login":"al ice"}'; _ag_page --prs --tsv
is "b03 A19: an api user answer with no login field, and one whose login is al ice, are not read: #8 unknown unknown each time" \
   "$AGa|$(_ag_sn "$AGAX/out" 8)" "unknown unknown|unknown unknown"

# A22: --queue over two projects, each with a same-repository PR by a non-owner.
_ag_user '{"login":"alice","id":2,"type":"User"}'
_ag_prs acme_app "$AGPR8"; _ag_prs acme_lib "$(_sp_pr 21 notes/21.md:0 red author=carol repo=acme/lib)"
_ag_page --queue --tsv; AGa="$(_ag_ucnt "$AGAL/gh.log")"
is "b03 A22: a --queue run over two projects, each listing a PR by a non-owner, asks for the signed-in account at most once" \
   "$AGRC|$([ "$AGa" -le 1 ] && echo 'at most once' || echo "$AGa times")" "0|at most once"

# ---- the page (FX-P): the trust base -----------------------------------------------
_sp_ledger
printf '2026-10-16T09:30:00Z\tsession\t162\t%s\t-\t1\t%s\n' "$(_sp_sha 162)" "$AGNC" >> "$SPLAND/ledger.tsv"
printf '2026-10-16T09:31:00Z\trefused\t163\t%s\t%s\t3\tblocker: the receipt is stale [main %s]\n' "$(_sp_sha 163)" "$SPH" "$SPMAIN" >> "$SPLAND/ledger.tsv"
_sp_prs fixture_home "$(_sp_pr 164 "projects/felix/risk.tsv:1 engine/harness/felix:0" green)" \
  "$(_sp_pr 163 engine/harness/felix:0 green)" "$(_sp_pr 162 engine/harness/felix:0 green)" \
  "$(_sp_pr 161 "engine/harness/felix:0 engine/harness/lib/verify.sh:0" green)" "$(_sp_pr 160 engine/harness/felix:0 green)"
_sp_land "$SPH" --prs --tsv; cp "$SPX/out" "$AGP/trust.tsv"; T3="$AGP/trust.tsv"
is "b03 A23: a green PR changing only engine/harness/felix, with no ledger row, is ready for the lander and its detail says it touches the trust base" \
   "$(_ag_sn "$T3" 160)|$(_ag_has "$(_sp_f "$T3" 160 8)" "touches the trust base: engine/harness/felix")" "ready lander|yes"
AGd="$(_sp_f "$T3" 161 8)"
is "b03 A24: a green PR changing engine/harness/felix and lib/verify.sh is ready for the lander and its detail names both paths" \
   "$(_ag_sn "$T3" 161)|$(_ag_has "$AGd" "touches the trust base: ")|$(_ag_has "$AGd" engine/harness/felix)|$(_ag_has "$AGd" engine/harness/lib/verify.sh)" \
   "ready lander|yes|yes|yes"
is "b03 A25: the same trust-base PR with a same-head session row, or a same-head refusal on the current origin/main, is refused and needs a session" \
   "$(_ag_sn "$T3" 162)|$(_ag_sn "$T3" 163)" "refused session|refused session"
is "b03 A27: a green PR changing projects/felix/risk.tsv and engine/harness/felix is the founder's, its detail saying trust base (control)" \
   "$(_ag_sn "$T3" 164)|$(_ag_has "$(_sp_f "$T3" 164 8)" "trust base")" "founder founder|yes"
rm -rf "$SPLAND/ledger.tsv"; mkdir -p "$SPLAND/ledger.tsv"
_sp_prs fixture_home "$(_sp_pr 160 engine/harness/felix:0 green)"; _sp_land "$SPH" --prs --tsv
is "b03 A26: the trust-base PR with the ledger path a directory is unknown and needs unknown" "$(_ag_sn "$SPX/out" 160)" "unknown unknown"
rm -rf "$SPLAND/ledger.tsv"

# A28: part 1310's whole fixture.
_sp_list; _sp_prs fixture_home "${SPLIST[@]}"; _sp_ledger
_sp_land "$SPH" --prs --tsv
is "b03 A28: over part 1310's whole fixture, no pr row of --prs --tsv is in state needs-attended, and every listed PR has a row" \
   "$(LC_ALL=C awk -F'\t' '$1 == "pr" { s = $4; sub(/,.*/, "", s); if (s == "needs-attended") n++ } END { print n + 0 }' "$SPX/out")|$(_sp_prn "$SPX/out")" \
   "0|${#SPLIST[@]}"
rm -rf "$AGP"

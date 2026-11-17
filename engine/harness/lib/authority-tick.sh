# The kernel's tick, up to the judge: the store's main, the candidates, and the decision for each.
#
# Trust-plane step 4, stage 1, slice 1 (lib/authority.sh says what the slice is). A tick fetches the source,
# checks that main is the tip this authority recorded, and says of each candidate what the founder's word and
# the policy at main make of it. It ends at the judge (K9): `eligible` and `override` say what a later slice
# would hand on, and nothing lands, in either standing.
#
# THE DECISION (K7) reads five things and nothing else: main in the store, the candidate's head as fetched, the
# policy at main (lib/authority-paths.sh), the founder's statements in their order (lib/door-read.sh), and this
# code. No file from a worker's machine is read, and nothing is decided from the source's main.
#
# THREE DEFECTS OF THE 11-09 MOCK'S KERNEL, FIXED HERE AND NOT COPIED:
#   - his word was read without its order (the mock asked whether a line was in the door's file). Here the
#     statements are read by their place: lib/door-read.sh;
#   - an override passed each hold, a later one too. Here an override is a permission like an authorization: a
#     hold given after it takes it back, and his stop is not passed over at all;
#   - an override named a head and no tree, so it landed whatever the merge had become. Here it is in effect
#     only while the merge of its head onto main is the tree it names.
#
# MAIN (W11). refs/heads/main is made by the first start and by nothing else. In shadow, and only there, a tick
# moves it forward to the source's main, so that a shadow authority judges against the main that is real today.
# A live authority's main moves only by a landing, and this slice has none.
#
# Bash 3.2. No project is named here.

# Everything a command needs before it reads or decides. Returns 1 with _FA_WHY when no authority is set up.
felix_authority_open() {
  felix_authority_gitenv
  felix_authority_load || return 1
  # W10. The merge reads no attributes file. The user's is turned off in _fa_g; the store's own cannot be,
  # so a store that holds one is refused.
  [ ! -e "$_FA_STORE/info/attributes" ] && [ ! -L "$_FA_STORE/info/attributes" ] \
    || { _FA_WHY="the store holds an attributes file, $_FA_STORE/info/attributes, and the merge reads none"; return 1; }
  _FA_ID="$(felix_authority_id)" || { _FA_WHY="the store at $_FA_STORE has no identity"; return 1; }
  _FA_EMPTY="$(_fa_g hash-object -t tree /dev/null 2>/dev/null)"
  felix_door_log_read "$_FA_STORE" "$_FA_ID"
  felix_authority_standing
  felix_door_reads "$_FA_STANDING"
  _FA_MAIN="$(_fa_g rev-parse --verify --quiet 'refs/heads/main^{commit}' 2>/dev/null)" || _FA_MAIN=""
  return 0
}

# W10. The source's branches as candidates and its main, each object checked as it is taken. A ref name from
# the source reaches a ref name here through git's own refspec, which refuses a name that is not one. The
# source is named after `--`, so it is never an option, and the transports are the three the parameters allow
# (lib/authority.sh): a transport that runs a program the value names (ext::, a remote helper) is refused by git.
felix_authority_fetch() {
  _fa_g -c transfer.fsckObjects=true -c fetch.fsckObjects=true \
        -c protocol.allow=never -c protocol.file.allow=always -c protocol.https.allow=always -c protocol.ssh.allow=always \
        -c fetch.recurseSubmodules=false -c submodule.recurse=false \
        fetch -q --no-tags --prune --no-recurse-submodules -- "$_FA_SOURCE" \
    '+refs/heads/*:refs/remotes/src/*' "+$_FA_SRCMAIN:refs/felix/source-main" >/dev/null 2>&1 </dev/null
}

# D7, W11. Main starts from statement 0, a start: made here when the log holds one and the store has no main,
# so that a door that kept the statement and then stopped leaves nothing half done.
felix_authority_main() {
  [ -z "$_FA_MAIN" ] || return 0
  [ "${_DL_N:-0}" -gt 0 ] && [ "${_DL_VERB[0]}" = start ] || return 1
  _fa_g cat-file -e "${_DL_COMMIT[0]}^{commit}" 2>/dev/null || return 1
  _fa_g update-ref refs/heads/main "${_DL_COMMIT[0]}" "$FELIX_AUTH_ZERO" 2>/dev/null || return 1
  _fa_g update-ref refs/felix/tip "${_DL_COMMIT[0]}" 2>/dev/null || return 1
  _FA_MAIN="${_DL_COMMIT[0]}"
}

# K7. The decision for one head against main. Sets _FD_DECISION, _FD_DETAIL and _FD_TREE. With `listing`, a
# stop is passed over: the door's list reads each head as if he had said go. That is an argument and not a
# variable, because a variable of that name in the caller's environment did the same to `decide` (review F4).
felix_authority_decide() {   # HEAD [listing]
  local h="$1" b="$_FA_MAIN" s mt rc t btree ovr_any="" ovr_t="" rel auth lean="" note=""
  _FD_DECISION=""; _FD_DETAIL="-"; _FD_TREE="-"
  s="$(felix_word_stop)"
  if [ -n "$s" ] && [ "${2:-}" != listing ]; then _FD_DECISION=stopped; _FD_DETAIL="statement $s"; return 0; fi
  mt="$(_fa_g --attr-source="$_FA_EMPTY" merge-tree --write-tree --no-messages "$b" "$h" 2>/dev/null)"; rc=$?
  t="${mt%%$'\n'*}"
  if [ "$rc" -ne 0 ] || ! _fa_sha "$t" || ! _fa_g cat-file -e "$t^{tree}" 2>/dev/null; then t=""; fi
  [ -z "$t" ] || _FD_TREE="$t"
  btree="$(_fa_g rev-parse --verify --quiet "$b^{tree}" 2>/dev/null)"
  _fw_hold "$h"
  # K5, K6. An override in effect names the tree this merge is. One that names another tree is not in effect.
  ovr_any="$(_fw_live override "$h")" || ovr_any=""
  if [ -n "$t" ]; then ovr_t="$(_fw_live override "$h" "$t")" || ovr_t=""; fi
  if [ -n "$ovr_t" ] && [ "$t" != "$btree" ]; then
    _FD_DECISION=override; _FD_DETAIL="statement $ovr_t overrides the judge for tree $t"; return 0
  fi
  [ -z "$ovr_any" ] || [ -n "$ovr_t" ] || note="; override $ovr_any names another tree"
  # K3, K4. A hold stands unless a release of this exact head was given after it.
  if [ -n "$_FW_HOLD" ]; then
    rel="$(_fw_last release "$h")"
    if [ -n "$rel" ] && [ "$rel" -gt "$_FW_HOLD" ]; then lean="$rel"
    else _FD_DECISION=held; _FD_DETAIL="statement $_FW_HOLD holds $_FW_HOLDC$note"; return 0; fi
  fi
  if [ -z "$t" ]; then _FD_DECISION=conflict; _FD_DETAIL="conflicts with main$note"; return 0; fi
  if [ "$t" = "$btree" ]; then _FD_DECISION=nothing; _FD_DETAIL="changes nothing$note"; return 0; fi
  felix_authority_paths "$b" "$t"
  if [ "$_FP_NF" -gt 0 ]; then
    if auth="$(_fw_live authorize "$h")"; then
      if [ -z "$lean" ]; then lean="$auth"; elif [ "$auth" -lt "$lean" ]; then lean="$auth,$lean"; else lean="$lean,$auth"; fi
    else
      _FD_DECISION=waits
      case "$_FP_UNREADABLE" in
        1) _FD_DETAIL="the founder-path policy at main cannot be read, so each path waits for him$note" ;;
        2) _FD_DETAIL="the paths this change touches could not be listed, so it waits for him$note" ;;
        *) _FD_DETAIL="changes $(_fa_esc "${_FP_FOUNDER[0]}"), which waits for the founder's authorization of this head$note" ;;
      esac
      return 0
    fi
  fi
  _FD_DECISION=eligible
  case "$lean" in
    "")  _FD_DETAIL="-$note" ;;
    *,*) _FD_DETAIL="leans on statements $lean$note" ;;
    *)   _FD_DETAIL="leans on statement $lean$note" ;;
  esac
  return 0
}

# The candidates: `HEAD<TAB>BRANCH` for each branch of the source, other than the one source-main names, whose
# head is not in main's history, in the byte order of the branch names.
felix_authority_candidates() {
  local h r br skip=""
  case "$_FA_SRCMAIN" in refs/heads/*) skip="${_FA_SRCMAIN#refs/heads/}" ;; esac
  _fa_g for-each-ref --format='%(objectname) %(refname)' refs/remotes/src/ 2>/dev/null | LC_ALL=C sort -k2 \
  | while IFS=' ' read -r h r; do
      br="${r#refs/remotes/src/}"
      [ -n "$br" ] && [ "$br" != "$skip" ] && _fa_sha "$h" || continue
      [ "$(_fa_g cat-file -t "$h" 2>/dev/null)" = commit ] || continue
      ! _fa_g merge-base --is-ancestor "$h" "$_FA_MAIN" 2>/dev/null || continue
      printf '%s\t%s\n' "$h" "$br"
    done
}

# K8. One row when this head's decision, detail or main differs from its last row. Report only.
_fa_ledger() {   # HEAD
  local f="$_FA_HOME/ledger.tsv" last
  last="$(LC_ALL=C awk -F'\t' -v h="$1" '($4 "") == (h "") { l = $3 "\t" $5 "\t" $7 } END { print l }' "$f" 2>/dev/null)"
  [ "$last" != "$_FD_DECISION"$'\t'"$_FA_MAIN"$'\t'"$_FD_DETAIL" ] || return 0
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$_FA_STANDING" "$_FD_DECISION" "$1" \
    "$_FA_MAIN" "$_FD_TREE" "$_FD_DETAIL" >> "$f"
}

# `felix authority tick`. Returns 0, or 3 when it is paused and has decided nothing.
felix_authority_tick() {
  local tip sm s h br n=0 cands
  [ -z "$_DL_BAD" ] || { printf 'paused the door'"'"'s log does not read back: statement %s\n' "$_DL_BAD"; return 3; }
  felix_authority_fetch || { printf 'paused the source could not be read\n'; return 3; }
  felix_authority_main || { printf 'paused this authority'"'"'s store holds no main: it waits for the first start at the door\n'; return 3; }
  tip="$(_fa_g rev-parse --verify --quiet refs/felix/tip 2>/dev/null)" || tip=""
  [ "$tip" = "$_FA_MAIN" ] || { printf 'paused the store'"'"'s main is not the tip this authority recorded\n'; return 3; }
  if [ "$_FA_STANDING" = shadow ]; then
    sm="$(_fa_g rev-parse --verify --quiet 'refs/felix/source-main^{commit}' 2>/dev/null)" || sm=""
    if [ -n "$sm" ] && [ "$sm" != "$_FA_MAIN" ]; then
      _fa_g merge-base --is-ancestor "$_FA_MAIN" "$sm" 2>/dev/null \
        || { printf 'paused the source'"'"'s main does not descend from this store'"'"'s main\n'; return 3; }
      _fa_g update-ref refs/heads/main "$sm" "$_FA_MAIN" 2>/dev/null && _fa_g update-ref refs/felix/tip "$sm" 2>/dev/null \
        || { printf 'paused the store'"'"'s main could not be moved\n'; return 3; }
      _FA_MAIN="$sm"
    fi
  fi
  s="$(felix_word_stop)"
  if [ -n "$s" ]; then printf 'stopped by the founder at the door (statement %s)\n' "$s"; return 0; fi
  cands="$(felix_authority_candidates)"
  while IFS=$'\t' read -r h br; do
    [ -n "$h" ] || continue
    felix_authority_decide "$h"
    printf '%s\t%s\t%s\t%s\t%s\n' "$_FA_STANDING" "$_FD_DECISION" "$h" "$(_fa_esc "$br")" "$_FD_DETAIL"
    _fa_ledger "$h"
    n=$((n + 1))
  done <<EOF
$cands
EOF
  printf 'tick: %s, %s candidates\n' "$_FA_STANDING" "$n"
  return 0
}

# `felix authority decide COMMIT`: the same one line for a commit the store holds. It fetches nothing.
felix_authority_decide_one() {   # COMMIT
  local h
  [ -z "$_DL_BAD" ] || { printf 'paused the door'"'"'s log does not read back: statement %s\n' "$_DL_BAD"; return 3; }
  _fa_sha "${1:-}" && h="$(_fa_g rev-parse --verify --quiet "$1^{commit}" 2>/dev/null)" && [ "$h" = "$1" ] \
    || { printf 'felix: %s names no commit this authority holds\n' "${1:-}" >&2; return 1; }
  felix_authority_main || { printf 'paused this authority'"'"'s store holds no main: it waits for the first start at the door\n'; return 3; }
  felix_authority_decide "$h"
  printf '%s\t%s\t%s\t-\t%s\n' "$_FA_STANDING" "$_FD_DECISION" "$h" "$_FD_DETAIL"
}

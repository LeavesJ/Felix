# ------------------------------------ the project gate's own failure (G5.2) ----
# cmd_gate ran the project gate into a log and then tee'd the engine's own
# check lines into the same log. The recorder took FAIL names from the whole
# of it and fell back to exit-<status> only when the whole log named nothing,
# so a project gate that failed silently beside a failing probe was recorded
# as `probes` alone, which gate_shown_failing excludes: held forever. And a
# project line with no final newline had the first engine line glued onto it.
_cmstub_build; _fh_gsf_chk_load; _fresh_repos_lock
_fh_proj gatesplit gate.sh
_fg_r="$(_fh_root gatesplit)"; _fg_p="$FROOT/projects/gatesplit"; _fg_l="$MEM/gatesplit/mistakes.log"
printf 'contents\n' > "$_fg_r/WIDGET.txt"
( _fx_cd "$_fg_r" && git add -A && git -c user.name=t -c user.email=t@t commit -qm widget ) >/dev/null 2>&1
_fg_blind() { { printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n'
                printf 'blindrow\t-\t-\tls -1 nothing-here.rs\ttest -f WIDGET.txt\n'; } > "$_fg_p/probes.tsv"; }
_fg_clean() { printf 'present\t-\t-\tls -1 WIDGET.txt\ttest -f WIDGET.txt\n' > "$_fg_p/probes.tsv"; }
_fg_run()   { _fh_script gatesplit "$1"; : > "$_fg_l"; _fg_out="$(cd "$_fg_r" && "$FELIX" gate 2>&1)"; _fg_rc=$?; }
# Rows written, then the new row's column-four tokens in order.
_fg_row()   { printf '%s|%s' "$(grep -c '' "$_fg_l" 2>/dev/null)" \
                "$(tail -n 1 "$_fg_l" 2>/dev/null | cut -f4 | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ' | sed 's/ $//')"; }

_fg_blind
_fg_run 'echo "  lint               FAIL"; exit 1'
has "the gatesplit fixture's probes fail from the engine" "$_fg_out" "  probes             FAIL"
is  "a project FAIL line and a failing probe are both recorded, in one row, and the gate exits 1" \
    "$_fg_rc $(_fg_row)" "1 1|lint probes"
_fg_run 'echo "something broke"; exit 1'
is  "a project gate that fails silently is recorded beside the probe that failed with it: exit-1, then probes" \
    "$(_fg_row)" "1|exit-1 probes"
_fh_gsf "$MEM/gatesplit" \
  && ok  "so gate_shown_failing sees the project's own silent failure there" \
  || bad "so gate_shown_failing sees the project's own silent failure there" "$(cat "$_fg_l")"
_fg_run 'echo "something broke"; exit 3'
is  "and with its own status: exit-3, then probes" "$(_fg_row)" "1|exit-3 probes"
_fg_run 'true'
is  "a passing project with a failing probe still records probes alone" "$(_fg_row)" "1|probes"
_fh_gsf "$MEM/gatesplit" \
  && bad "and gate_shown_failing still does not count a failing probe as the project's gate failing" "$(cat "$_fg_l")" \
  || ok  "and gate_shown_failing still does not count a failing probe as the project's gate failing"
_fg_run 'echo "  deployed           FAIL (structural: this tree is not the one that deploys)"; exit 1'
is  "a structural project failure beside a failing probe records probes alone" "$(_fg_row)" "1|probes"
_fg_run "printf '  lint               FAIL'; exit 1"
is  "a project FAIL line with no final newline is not swallowed by the engine line after it" \
    "$(_fg_row)" "1|lint probes"
_fg_clean
_fg_run 'echo broke; exit 3'
is  "a silent project failure with nothing else failing records exit-3, exactly as before" \
    "$(grep -c '' "$_fg_l")|$(tail -n 1 "$_fg_l" | cut -f4)" "1|exit-3"
_fg_run 'echo "  deployed           FAIL (structural: this tree is not the one that deploys)"; exit 1'
is  "and with a clean probes table an all-structural failure still writes no row" \
    "$_fg_rc $(grep -c '' "$_fg_l")" "1 0"

# ------------------------------------------- a gate that could not run (G1.3) ----
# 127 and 126 are the shell saying the gate command was not found, or found
# and not executable. Nothing was tested, so it is not the gate shown failing,
# and recording exit-127 satisfied gate_shown_failing on a gate nobody had ever
# watched fail. The verdict does not change: the gate still exits non-zero and
# its receipt is red. Only the record changes, and the gate says why.
_fh_proj unrunproj felix-no-such-command-xyz
_fu_r="$(_fh_root unrunproj)"; _fu_l="$MEM/unrunproj/mistakes.log"
: > "$_fu_l"
_fu_out="$(cd "$_fu_r" && "$FELIX" gate 2>&1)"; _fu_rc=$?
is  "a gate command that is not found still fails the gate, with 127" "$_fu_rc" "127"
has "and the gate says it could not run, so nothing was tested and it is not recorded as failing" \
    "$_fu_out" "the gate command could not run (exit 127: a command it calls was not found), so nothing was tested and this run is not recorded as the gate failing"
is  "and no mistakes row is written for a gate that never ran" "$(grep -c '' "$_fu_l")" "0"
_fh_gsf "$MEM/unrunproj" \
  && bad "so gate_shown_failing is not satisfied by a gate that never ran" "$(cat "$_fu_l")" \
  || ok  "so gate_shown_failing is not satisfied by a gate that never ran"
_fu_tid="$(cd "$_fu_r" && . "$FROOT/harness/lib/verify.sh" && felix_tree_id "$_fu_r" "$FROOT")"
is  "and the receipt written for that tree is still red" \
    "$( . "$FROOT/harness/lib/verify.sh"; felix_verify_receipt "$_fu_r" "$FROOT" | cut -f1,2 )" "$(printf '%s\tred' "$_fu_tid")"

printf '#!/bin/sh\necho hi\n' > "$_fu_r/notexec.sh"; chmod 644 "$_fu_r/notexec.sh"
_fh_setgate unrunproj ./notexec.sh
: > "$_fu_l"
_fu_out="$(cd "$_fu_r" && "$FELIX" gate 2>&1)"; _fu_rc=$?
is  "a gate command found but not executable fails the gate with 126" \
    "$([ -x "$_fu_r/notexec.sh" ] && echo executable || echo plain) $_fu_rc" "plain 126"
has "and says it could not run, naming 126" "$_fu_out" "(exit 126"
is  "and writes no mistakes row for it either" "$(grep -c '' "$_fu_l")" "0"

_fg_blind; _fh_setgate gatesplit felix-no-such-command-xyz; : > "$_fg_l"
_fg_out="$(cd "$_fg_r" && "$FELIX" gate 2>&1)"
is  "an unrunnable gate beside a failing probe records probes alone, and no exit-127" "$(_fg_row)" "1|probes"
has "and still says the gate command could not run" "$_fg_out" "the gate command could not run (exit 127"
_fh_setgate gatesplit gate.sh

# The could-not-run line says what the recorder wrote, so it is printed after
# the recorder. The first cut printed it before any engine check ran, ending
# "this run is not recorded as the gate failing" whatever came next; a failing
# probe or obligation was then recorded under its own name, and obligations is
# one gate_shown_failing counts. The screen said the opposite of the row.
case "$_fg_out" in
  *"is not recorded as the gate failing"*)
    bad "beside a failing probe, the line never says the run was not recorded, since probes was" \
        "$(printf '%s\n' "$_fg_out" | grep 'could not run')" ;;
  *"its exit status is not recorded; mistakes.log records only the engine checks that failed beside it: probes"*)
    ok  "beside a failing probe, the line never says the run was not recorded, since probes was" ;;
  *)
    bad "beside a failing probe, the line never says the run was not recorded, since probes was" \
        "$(printf '%s\n' "$_fg_out" | grep 'could not run')" ;;
esac

_fh_proj unrunob felix-no-such-command-xyz
_fo_r="$(_fh_root unrunob)"; _fo_l="$MEM/unrunob/mistakes.log"
printf 'ob1\tTASK_BLOCKING\tdeterministic\ttrue\tfalse\t-\tan obligation whose evidence always fails\n' \
  > "$FROOT/projects/unrunob/obligations.tsv"
: > "$_fo_l"
_fo_out="$(cd "$_fo_r" && "$FELIX" gate 2>&1)"
has "the unrunob fixture's obligation fails from the engine" "$_fo_out" "  obligations        FAIL"
is  "an unrunnable gate beside a failing obligation records obligations, and no exit-127" \
    "$(grep -c '' "$_fo_l")|$(cut -f4 "$_fo_l")" "1|obligations "
case "$_fo_out" in
  *"is not recorded as the gate failing"*)
    bad "and the gate does not say the run was not recorded, when that row makes gate_shown_failing read done" \
        "$(printf '%s\n' "$_fo_out" | grep 'could not run')" ;;
  *) ok  "and the gate does not say the run was not recorded, when that row makes gate_shown_failing read done" ;;
esac
has "it says the command's own status is not recorded, and names the engine check that is" "$_fo_out" \
    "gate: the gate command could not run (exit 127: a command it calls was not found), so nothing was tested and its exit status is not recorded; mistakes.log records only the engine checks that failed beside it: obligations"
is  "and says it once, as the gate's last line, after the obligations line it depends on" \
    "$(printf '%s\n' "$_fo_out" | grep -c 'could not run')|$(printf '%s\n' "$_fo_out" | tail -n 1 | cut -c1-32)" \
    "1|gate: the gate command could not"

_fh_setgate unrunproj gate.sh
_fh_script unrunproj 'echo broke; exit 1'
: > "$_fu_l"
_fu_out="$(cd "$_fu_r" && "$FELIX" gate 2>&1)"
is  "a gate that ran and failed silently still records exit-1" "$(grep -c '' "$_fu_l")|$(cut -f4 "$_fu_l")" "1|exit-1"
_fh_gsf "$MEM/unrunproj" \
  && ok  "and gate_shown_failing reads that as the gate shown failing" \
  || bad "and gate_shown_failing reads that as the gate shown failing" "$(cat "$_fu_l")"
case "$_fu_out" in
  *"could not run"*) bad "and a gate that ran is never called unrunnable" "$_fu_out" ;;
  *)                 ok  "and a gate that ran is never called unrunnable" ;;
esac
_fh_script unrunproj 'echo "  lint               FAIL"; exit 127'
: > "$_fu_l"
_fu_out="$(cd "$_fu_r" && "$FELIX" gate 2>&1)"
is  "a gate that named a failure and then exited 127 records the name" "$(grep -c '' "$_fu_l")|$(cut -f4 "$_fu_l")" "1|lint "
case "$_fu_out" in
  *"could not run"*) bad "and is not called unrunnable, because it ran far enough to catch something" "$_fu_out" ;;
  *)                 ok  "and is not called unrunnable, because it ran far enough to catch something" ;;
esac

# ------------------------------------------ setup rows and the GitHub remote ----
# felix new and adopt spliced the repository's slug into {{REPO}} when they
# wrote a setup row. With no GitHub remote the slug is empty, so the saved
# check read `--repo  2>/dev/null`, failed forever, and held human_steps; and
# adding a remote later changed nothing, because adopt skips ids that exist.
# The placeholder is kept on disk and filled in when the row is read.
_fsgh_build   # the gh and ssh stubs, $TMP/fs-gh, and _fs_path (tests/lib/cm-stub.sh)
( PATH="$_fs_path"; gh label list --repo acme/widget 2>/dev/null | grep -q needs-founder ) \
  && ! ( PATH="$_fs_path"; gh label list --repo other/thing >/dev/null 2>&1 ) \
  && ok  "the gh stub answers for acme/widget and refuses anything else" \
  || bad "the gh stub answers for acme/widget and refuses anything else"
_fs_status() { ( cd "$1" && PATH="$_fs_path"
                 . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                 . "$FROOT/harness/lib/stack.sh"; . "$FROOT/harness/lib/setup.sh"
                 felix_setup_status "$2" ) 2>/dev/null; }
_fs_cli() { ( cd "$1" && PATH="$_fs_path" "$FELIX" setup "${@:2}" ) 2>&1; }
_fs_cm()  { ( cd "$1" && PATH="$_fs_path" "$FELIX" commission "${@:2}" ) 2>&1; }
_fs_ids() { printf '%s\n' "$1" | awk -F'\t' '$2 == "risk-labels" || $2 == "ci-anthropic-key"'; }
_fs_tpl="$FROOT/harness/templates/setup.tsv"
_fs_reporows="$(grep -F '{{REPO}}' "$_fs_tpl" | grep -v '^#')"
_fs_hdr="$(printf '# id\ttitle\tcapability\tcheck')"
_fs_rlt="Create the escalation labels the repair loop uses"
_fs_ckt="$(awk -F'\t' '$1 == "ci-anthropic-key" { print $2 }' "$_fs_tpl")"
_fs_wait="$(printf 'dormant\trisk-labels\t%s\twaits for a GitHub remote\ndormant\tci-anthropic-key\t%s\twaits for a GitHub remote' "$_fs_rlt" "$_fs_ckt")"
_fs_nogh="No GitHub remote yet, so {{REPO}} below is left as written; it fills in once origin points at GitHub."
is "the setup template holds the two rows that need a GitHub slug" \
   "$(printf '%s\n' "$_fs_reporows" | cut -f1 | tr '\n' ' ')" "risk-labels ci-anthropic-key "

# felix new, in a checkout with CI and no remote (_setupproj_build, tests/lib/cm-stub.sh).
_setupproj_build
_fs_saved="$(awk -F'\t' '$1 == "risk-labels" || $1 == "ci-anthropic-key"' "$_fs_p/setup.tsv" 2>/dev/null)"
if [ "$_fs_nrc" -ne 0 ] || [ "$(printf '%s\n' "$_fs_saved" | grep -c .)" != "2" ]; then
  bad "felix new with no remote saves both slug rows with --repo {{REPO}}, never an empty slug" "felix new exited $_fs_nrc, saved [$_fs_saved]"
elif [ -z "$(grep -vF -- '--repo {{REPO}}' <<<"$_fs_saved")" ] && ! grep -qF -- '--repo  ' "$_fs_p/setup.tsv"; then
  ok  "felix new with no remote saves both slug rows with --repo {{REPO}}, never an empty slug"
else
  bad "felix new with no remote saves both slug rows with --repo {{REPO}}, never an empty slug" "$(printf '%s\n' "$_fs_saved" | cut -f4)"
fi
has "and the saved risk-labels runbook keeps {{REPO}} too" "$(cat "$_fs_p/setup/risk-labels.md" 2>/dev/null)" "{{REPO}}"

# With no remote those rows wait. They are not todo, and they ask gh nothing.
: > "$_fs_ghlog"
is "with no remote, both slug rows wait for a GitHub remote rather than reading todo" \
   "$(_fs_ids "$(_fs_status "$_fs_n" "$_fs_p")")" "$_fs_wait"
_fs_line="$(_fs_cli "$_fs_n" | grep -E '\[.\] risk-labels ')"
case "$_fs_line" in
  *"[-] risk-labels"*"(waits for a GitHub remote)") ok  "felix setup shows risk-labels waiting for a GitHub remote, never as a step to do" ;;
  *)                                                bad "felix setup shows risk-labels waiting for a GitHub remote, never as a step to do" "$_fs_line" ;;
esac
is "and gh is asked nothing for the rows that wait" "$(grep -cE 'label list|secret list' "$_fs_ghlog")" "0"

# A remote added later fills the same saved row: nothing re-adopted, nothing
# rewritten, the file on disk exactly as felix new left it.
cp "$_fs_p/setup.tsv" "$TMP/fs-setup.copy"
( _fx_cd "$_fs_n" && git remote add origin https://github.com/acme/widget.git ) >/dev/null 2>&1
: > "$_fs_ghlog"
_fs_st="$(_fs_status "$_fs_n" "$_fs_p")"
cmp -s "$_fs_p/setup.tsv" "$TMP/fs-setup.copy" \
  && ok  "adding a remote rewrites nothing: the saved setup.tsv is byte for byte what it was" \
  || bad "adding a remote rewrites nothing: the saved setup.tsv is byte for byte what it was"
is "and the same saved rows now read done, three fields, with the slug filled in" \
   "$(_fs_ids "$_fs_st")" "$(printf 'done\trisk-labels\t%s\ndone\tci-anthropic-key\t%s' "$_fs_rlt" "$_fs_ckt")"
if grep -qF 'label list --repo acme/widget' "$_fs_ghlog" && grep -qF 'secret list --repo acme/widget' "$_fs_ghlog"; then
  ok  "and gh was asked about acme/widget for both"
else
  bad "and gh was asked about acme/widget for both" "$(cat "$_fs_ghlog")"
fi
_fs_rb="$(_fs_cli "$_fs_n" risk-labels)"
case "$_fs_rb" in
  *'{{REPO}}'*|*'No GitHub remote yet'*) bad "felix setup risk-labels prints the runbook with the slug filled in" "$(printf '%s\n' "$_fs_rb" | grep -e REPO -e 'No GitHub' | head -n 3)" ;;
  *'--repo acme/widget'*)                ok  "felix setup risk-labels prints the runbook with the slug filled in" ;;
  *)                                     bad "felix setup risk-labels prints the runbook with the slug filled in" "$(printf '%s\n' "$_fs_rb" | grep -e '--repo' | head -n 3)" ;;
esac

# human_steps, copied verbatim from the template, is released by rows that
# wait for a remote and by nothing else.
_fh_proj setupwait true
_fs_wr="$(_fh_root setupwait)"; _fs_wp="$FROOT/projects/setupwait"
printf 'ci\n' > "$_fs_wp/capabilities"
{ printf '%s\n' "$_fs_hdr"; printf '%s\n' "$_fs_reporows"; } > "$_fs_wp/setup.tsv"
mkdir -p "$_fs_wp/setup"; cp "$FROOT/harness/templates/setup/risk-labels.md" "$_fs_wp/setup/"
{ _fh_cmhdr; _fh_cmrow human_steps; printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n'; } > "$_fs_wp/commissioning.tsv"
is "with no remote, felix commission --status reads human_steps done: the rows that wait hold nothing" \
   "$(_fs_cm "$_fs_wr" --status | grep -cE '^  done +human_steps( |$)')" "1"
( _fx_cd "$_fs_wr" && git remote add origin https://github.com/other/thing.git ) >/dev/null 2>&1
is "and with a GitHub remote whose steps are not done, human_steps is held" \
   "$(_fs_cm "$_fs_wr" --status | grep -cE '^  held +human_steps( |$)')" "1"

# A remote that is not GitHub has no slug to fill in, so its rows wait too.
( _fx_cd "$_fs_wr" && git remote set-url origin git@gitlab.com:acme/widget.git ) >/dev/null 2>&1
: > "$_fs_ghlog"
is "a non-GitHub remote leaves both slug rows waiting for a GitHub remote" \
   "$(_fs_ids "$(_fs_status "$_fs_wr" "$_fs_wp")")" "$_fs_wait"
is "and with a gitlab remote gh is never called for them" "$(grep -cE 'label list|secret list' "$_fs_ghlog")" "0"

# The slug is spliced into a command bash runs, so a remote carrying shell text
# is no slug at all. git remote add accepts this one. It points at GitHub,
# though, so its rows do not wait: they are steps Felix cannot check, held and
# said so, and their checks never run.
_fs_evil='https://github.com/acme/widget;touch PWNED.git'
( _fx_cd "$_fs_wr" && git remote set-url origin "$_fs_evil" ) >/dev/null 2>&1
_fs_pw0="$([ -e "$_fs_wr/PWNED" ] || [ -e "$PWD/PWNED" ] && echo present || echo absent)"
: > "$_fs_ghlog"
_fs_st="$(_fs_status "$_fs_wr" "$_fs_wp")"
_fs_cli "$_fs_wr" risk-labels >/dev/null 2>&1
_fs_unowner="origin points at GitHub, but not at one owner/name Felix can read, so Felix cannot check it"
if [ "$(git -C "$_fs_wr" remote get-url origin 2>/dev/null)" != "$_fs_evil" ]; then
  bad "a remote carrying shell text is no slug: risk-labels is a step Felix says it cannot check" "git did not keep the remote as written"
else
  is "a remote carrying shell text is no slug: risk-labels is a step Felix says it cannot check" \
     "$(printf '%s\n' "$_fs_st" | awk -F'\t' '$2 == "risk-labels"')" \
     "$(printf 'todo\trisk-labels\t%s\t%s' "$_fs_rlt" "$_fs_unowner")"
fi
is "and gh is asked nothing for it" "$(grep -cE 'label list|secret list' "$_fs_ghlog")" "0"
if [ "$_fs_pw0" = "present" ]; then
  bad "and nothing spliced from it ran: no PWNED file in the checkout or the working directory" "a PWNED file was there before the test"
elif [ -e "$_fs_wr/PWNED" ] || [ -e "$PWD/PWNED" ]; then
  bad "and nothing spliced from it ran: no PWNED file in the checkout or the working directory" "the remote's shell text was executed"
else
  ok  "and nothing spliced from it ran: no PWNED file in the checkout or the working directory"
fi

# A remote Felix cannot read as one owner/name is not the same as no remote.
# The first cut read every origin it could not turn into owner/name as none at
# all, so a repository that plainly had a GitHub remote, behind an ssh alias,
# over port 443, or spelled with a trailing slash, had its label and its CI
# secret read "waits for a GitHub remote". Both dropped out of human_steps'
# count, and commissioning released steps the person still owed: a silent
# false pass. The spellings git takes for one GitHub repository now all give
# its owner/name, and a GitHub remote Felix still cannot read holds its rows
# as todo and says why. Only no remote, or one that is not GitHub, waits.
_fs_both() { _fs_ids "$(_fs_status "$_fs_wr" "$_fs_wp")"; }
_fs_seturl() { ( _fx_cd "$_fs_wr" && git remote set-url origin "$1" ) >/dev/null 2>&1; }
_fs_done="$(printf 'done\trisk-labels\t%s\ndone\tci-anthropic-key\t%s' "$_fs_rlt" "$_fs_ckt")"
_fs_todo() { printf 'todo\trisk-labels\t%s\t%s\ntodo\tci-anthropic-key\t%s\t%s' "$_fs_rlt" "$1" "$_fs_ckt" "$1"; }
_fs_seturl 'https://github.com/acme/widget/'
is "origin spelled with a trailing slash gives acme/widget, so both slug rows read done" "$(_fs_both)" "$_fs_done"
_fs_seturl 'ssh://git@ssh.github.com:443/acme/widget.git'
is "origin over ssh on port 443 gives acme/widget, not 443/acme/widget, so both read done" "$(_fs_both)" "$_fs_done"
_fs_seturl 'git@work:acme/widget.git'
is "origin behind an ssh alias that ssh -G says stands for github.com gives acme/widget, so both read done" \
   "$(_fs_both)" "$_fs_done"

_fs_seturl 'git@github.com-work:acme/widget.git'
: > "$_fs_ghlog"; : > "$_fs_sshlog"
_fs_alias="origin's host github.com-work is not github.com, nor an ssh alias for it, so Felix cannot check it"
is "an ssh alias ssh cannot resolve holds both slug rows as todo, saying why, rather than letting them wait" \
   "$(_fs_both)" "$(_fs_todo "$_fs_alias")"
is "and gh is asked nothing for them, because no slug was read" "$(grep -cE 'label list|secret list' "$_fs_ghlog")" "0"
is "and ssh is asked only for its configuration, with no DNS lookup, about the alias as written" \
   "$(grep -c '' "$_fs_sshlog")|$(head -n 1 "$_fs_sshlog")" "1|-G -o CanonicalizeHostname=no github.com-work"
is "so felix commission --status holds human_steps, where the first cut released it" \
   "$(_fs_cm "$_fs_wr" --status | grep -cE '^  held +human_steps( |$)')" "1"
_fs_line="$(_fs_cli "$_fs_wr" | grep -E '\[.\] risk-labels ')"
case "$_fs_line" in
  *"[ ] risk-labels"*"($_fs_alias)") ok  "felix setup shows risk-labels as a step to do, with the reason Felix cannot check it" ;;
  *)                                 bad "felix setup shows risk-labels as a step to do, with the reason Felix cannot check it" "$_fs_line" ;;
esac
is "and felix setup risk-labels begins by saying why {{REPO}} is left as written" \
   "$(_fs_cli "$_fs_wr" risk-labels | head -n 1)" \
   "{{REPO}} below is left as written, because origin's host github.com-work is not github.com, nor an ssh alias for it: put the repository's owner/name in its place."
_fs_seturl 'git@github-personal:acme/widget.git'
is "an alias named for GitHub without github.com in it is held the same way" \
   "$(_fs_both)" "$(_fs_todo "origin's host github-personal is not github.com, nor an ssh alias for it, so Felix cannot check it")"
_fs_seturl 'https://github.example.com/acme/widget.git'
is "a GitHub Enterprise-shaped host is held too, since github.com's owner/name would not check it" \
   "$(_fs_both)" "$(_fs_todo "origin's host github.example.com is not github.com, nor an ssh alias for it, so Felix cannot check it")"
_fs_seturl 'https://github.com/acme'
is "a GitHub origin with no owner/name in it holds both rows, saying so" "$(_fs_both)" "$(_fs_todo "$_fs_unowner")"

# The host is handed to ssh as an argument, so it has to be a plain hostname
# first: one that would read as an option is not GitHub, and never reaches ssh.
: > "$_fs_sshlog"
_fs_seturl 'git@-oProxyCommand=touch:acme/widget.git'
is "a remote whose host would be an ssh option is no GitHub remote: both rows wait" "$(_fs_both)" "$_fs_wait"
is "and ssh is never called with it" "$(grep -c '' "$_fs_sshlog")" "0"

# Origin is the remote Felix reads. With none, a GitHub remote under another
# name still means the repository owes its GitHub steps.
( _fx_cd "$_fs_wr" && git remote remove origin && git remote add upstream https://github.com/acme/widget.git ) >/dev/null 2>&1
is "with no origin but a GitHub remote named upstream, both rows are held as todo, saying origin is the one read" \
   "$(_fs_both)" "$(_fs_todo "no remote is named origin, the one Felix reads, though another points at GitHub, so Felix cannot check it")"
( _fx_cd "$_fs_wr" && git remote remove upstream && git remote add upstream https://gitlab.com/acme/widget.git ) >/dev/null 2>&1
is "and with only a gitlab remote under another name, they wait" "$(_fs_both)" "$_fs_wait"
( _fx_cd "$_fs_wr" && git remote remove upstream ) >/dev/null 2>&1

# Rows an older felix new already saved with an empty slug read the same way:
# `--repo` followed by blanks and then nothing a slug could be.
_fh_proj setuplegacy true
_fs_lr="$(_fh_root setuplegacy)"; _fs_lp="$FROOT/projects/setuplegacy"
printf 'ci\n' > "$_fs_lp/capabilities"
{ printf '%s\n' "$_fs_hdr"; printf 'risk-labels\t%s\tci\tgh label list --repo  2>/dev/null | grep -q needs-founder\n' "$_fs_rlt"; } > "$_fs_lp/setup.tsv"
mkdir -p "$_fs_lp/setup"
printf '# Escalation and risk labels\n\n**Check:** `gh label list --repo ` includes `needs-founder`.\n\n```bash\ngh label create needs-founder --repo  --color D93F0B\n```\n' \
  > "$_fs_lp/setup/risk-labels.md"
is "a row saved with an empty slug reads as waiting for a GitHub remote, like a {{REPO}} row" \
   "$(_fs_status "$_fs_lr" "$_fs_lp" | awk -F'\t' '$2 == "risk-labels"')" \
   "$(printf 'dormant\trisk-labels\t%s\twaits for a GitHub remote' "$_fs_rlt")"
_fs_rb="$(_fs_cli "$_fs_lr" risk-labels)"
is "and its runbook begins by saying {{REPO}} is left as written until origin points at GitHub" \
   "$(printf '%s\n' "$_fs_rb" | head -n 1)" "$_fs_nogh"
is "and shows --repo {{REPO}} in both places the empty slug was" \
   "$(printf '%s\n' "$_fs_rb" | grep -cF -- '--repo {{REPO}}')" "2"
( _fx_cd "$_fs_lr" && git remote add origin https://github.com/acme/widget.git ) >/dev/null 2>&1
: > "$_fs_ghlog"
is "with the acme remote the row saved with an empty slug reads done" \
   "$(_fs_status "$_fs_lr" "$_fs_lp" | awk -F'\t' '$2 == "risk-labels"')" "$(printf 'done\trisk-labels\t%s' "$_fs_rlt")"
has "and gh was asked about acme/widget for it" "$(cat "$_fs_ghlog")" "label list --repo acme/widget"
is "and its runbook shows --repo acme/widget in both places" \
   "$(_fs_cli "$_fs_lr" risk-labels | grep -cF -- '--repo acme/widget')" "2"

# A runbook a person has added to. The first cut asked whether the normalised
# text held {{REPO}} with `sed | grep -q` under the CLI's pipefail: grep leaves
# on its first match, sed takes a SIGPIPE on its next write, and the pipeline
# reads false. Past the pipe's buffer that is certain, and the runbook printed
# raw, with no preface and, for a legacy one, `--repo  --color`: a command to
# paste that names no repository. Three thousand lines put {{REPO}} in the
# first few and a couple of hundred kilobytes after it.
_fh_proj setupbig true
_fs_gr="$(_fh_root setupbig)"; _fs_gp2="$FROOT/projects/setupbig"
printf 'ci\n' > "$_fs_gp2/capabilities"; mkdir -p "$_fs_gp2/setup"
{ printf '%s\n' "$_fs_hdr"; printf '%s\n' "$_fs_reporows"; } > "$_fs_gp2/setup.tsv"
_fs_tail() { awk 'BEGIN { for (i = 0; i < 3000; i++) printf "appendix line %05d: notes a person kept about the labels and why each exists\n", i }'; }
{ printf '# Escalation and risk labels\n\n**Check:** `gh label list --repo {{REPO}}` includes `needs-founder`.\n\n'; _fs_tail; } \
  > "$_fs_gp2/setup/risk-labels.md"
_fs_bsz="$(wc -c < "$_fs_gp2/setup/risk-labels.md" | tr -dc '0-9')"
_fs_rb="$(_fs_cli "$_fs_gr" risk-labels)"
if [ "${_fs_bsz:-0}" -lt 200000 ]; then
  bad "a runbook of 200 KB or more with {{REPO}} still begins with the no-remote preface" "the fixture is only ${_fs_bsz} bytes"
else
  is "a runbook of 200 KB or more with {{REPO}} still begins with the no-remote preface" \
     "$(printf '%s\n' "$_fs_rb" | head -n 1)" "$_fs_nogh"
fi
is "and prints the whole runbook after it, every appendix line" \
   "$(printf '%s\n' "$_fs_rb" | grep -c '^appendix line ')|$(printf '%s\n' "$_fs_rb" | tail -n 1)" \
   "3000|appendix line 02999: notes a person kept about the labels and why each exists"
{ printf 'gh label create needs-founder --repo  --color D93F0B\n'; _fs_tail; } > "$_fs_gp2/setup/risk-labels.md"
_fs_rb="$(_fs_cli "$_fs_gr" risk-labels)"
is "a long legacy runbook with an empty slug begins with the preface, then shows --repo {{REPO}}, never --repo and a blank" \
   "$(printf '%s\n' "$_fs_rb" | head -n 2)" \
   "$(printf '%s\ngh label create needs-founder --repo {{REPO}}  --color D93F0B' "$_fs_nogh")"

# A repository WITH a GitHub remote behaves exactly as it did when the slug was
# baked in at write time: the same lines, the same screens, the same gh calls.
for _fs_x in setupbaked setupplace; do
  _fh_proj "$_fs_x" true
  ( _fx_cd "$TMP/fr-$_fs_x" && git remote add origin https://github.com/acme/widget.git ) >/dev/null 2>&1
  printf 'ci\n' > "$FROOT/projects/$_fs_x/capabilities"
  mkdir -p "$FROOT/projects/$_fs_x/setup"
done
{ printf '%s\n' "$_fs_hdr"; printf '%s\n' "$_fs_reporows" | sed 's#{{REPO}}#acme/widget#g'
  printf 'later\tA step for a capability not present yet\tbilling\tfalse\n'; } > "$FROOT/projects/setupbaked/setup.tsv"
{ printf '%s\n' "$_fs_hdr"; printf '%s\n' "$_fs_reporows"
  printf 'later\tA step for a capability not present yet\tbilling\tfalse\n'; } > "$FROOT/projects/setupplace/setup.tsv"
for _fs_x in risk-labels ci-anthropic-key; do
  sed 's#{{REPO}}#acme/widget#g' "$FROOT/harness/templates/setup/$_fs_x.md" > "$FROOT/projects/setupbaked/setup/$_fs_x.md"
  cp "$FROOT/harness/templates/setup/$_fs_x.md" "$FROOT/projects/setupplace/setup/$_fs_x.md"
done
_fs_br="$(_fh_root setupbaked)"; _fs_pr="$(_fh_root setupplace)"
: > "$_fs_ghlog"
_fs_sb="$(_fs_status "$_fs_br" "$FROOT/projects/setupbaked")"; _fs_cb="$(_fs_cli "$_fs_br")"; _fs_gb="$(LC_ALL=C sort "$_fs_ghlog")"
: > "$_fs_ghlog"
_fs_sp="$(_fs_status "$_fs_pr" "$FROOT/projects/setupplace")"; _fs_cp="$(_fs_cli "$_fs_pr")"; _fs_gp="$(LC_ALL=C sort "$_fs_ghlog")"
has "a slug baked in by the old writer reads done through the stub" "$_fs_sb" "$(printf 'done\trisk-labels\t')"
is  "with a GitHub remote, a {{REPO}} row's status is byte for byte a baked row's" "$_fs_sp" "$_fs_sb"
is  "and felix setup's screen is the same, apart from the project's name" \
    "$(printf '%s' "$_fs_cp" | sed 's/setupplace/NAME/g')" "$(printf '%s' "$_fs_cb" | sed 's/setupbaked/NAME/g')"
is  "and felix setup risk-labels prints the same runbook" "$(_fs_cli "$_fs_pr" risk-labels)" "$(_fs_cli "$_fs_br" risk-labels)"
is  "and gh is asked the same questions" "$_fs_gp" "$_fs_gb"
is  "a row for a capability not present still reads dormant, three fields and no reason" \
    "$(printf '%s\n' "$_fs_sp" | awk -F'\t' '$2 == "later" { print NF "|" $0 }')" "$(printf '3|dormant\tlater\tA step for a capability not present yet')"
has "and felix setup still says it is not needed yet" "$(printf '%s\n' "$_fs_cp" | grep ' later ')" "(not needed yet)"

# ------------------------------------ commission adopts before its receipt ----
# session-start adopts every capability the checkout shows and the project has
# not declared, appending to capabilities, stack.tsv and setup.tsv, all three
# in the table set the commissioning receipt is hashed over. So a receipt
# written while ci was undeclared read stale at the very next session start.
# A full run now adopts first, so the rows, the record and the receipt all
# describe the table set the next session will find.
_fh_proj adoptproj true
_fa_r="$(_fh_root adoptproj)"; _fa_p="$FROOT/projects/adoptproj"
mkdir -p "$_fa_r/.github/workflows"; printf 'on: push\n' > "$_fa_r/.github/workflows/ci.yml"
( _fx_cd "$_fa_r" && git add -A && git -c user.name=t -c user.email=t@t commit -qm ci ) >/dev/null 2>&1
: > "$_fa_p/capabilities"
printf '# k\tn\ts\tr\tc\n' > "$_fa_p/stack.tsv"
printf '%s\n' "$_fs_hdr" > "$_fa_p/setup.tsv"
cp "$FROOT/harness/templates/profiles.tsv" "$FROOT/harness/templates/routes.tsv" "$_fa_p/"
{ _fh_cmhdr; _fh_cmrow human_steps; printf 'marker\t-\t-\t-\t-\ttest -f .felix\t9\n'; } > "$_fa_p/commissioning.tsv"
_fa_undecl() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
                 felix_undeclared "$_fa_r" "$_fa_p" ) 2>/dev/null | tr '\n' ' '; }
_fa_pv() { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"; . "$FROOT/harness/lib/commission.sh"
             felix_commission_policy_version "$_fa_p" ) 2>/dev/null; }
is "the adopt fixture's checkout shows ci, and its project declares nothing" "$(_fa_undecl)" "ci "

cp "$_fa_p/capabilities" "$TMP/fa-caps.0"
_fa_o="$(_fs_cm "$_fa_r" --status)"
if ! cmp -s "$_fa_p/capabilities" "$TMP/fa-caps.0"; then
  bad "felix commission --status adopts nothing and says nothing about adopting" "capabilities now [$(cat "$_fa_p/capabilities")]"
else
  case "$_fa_o" in
    *"adopted before this run"*) bad "felix commission --status adopts nothing and says nothing about adopting" "$_fa_o" ;;
    *"commissioning for adoptproj"*) ok "felix commission --status adopts nothing and says nothing about adopting" ;;
    *) bad "felix commission --status adopts nothing and says nothing about adopting" "no report: $_fa_o" ;;
  esac
fi

_fa_o="$(_fs_cm "$_fa_r")"
grep -qx ci "$_fa_p/capabilities" 2>/dev/null \
  && ok  "a full felix commission adopts what the checkout shows before it runs: capabilities holds ci" \
  || bad "a full felix commission adopts what the checkout shows before it runs: capabilities holds ci" "[$(cat "$_fa_p/capabilities")]"
case "$_fa_o" in
  *"adopted before this run, because the checkout shows them:"*"ci("*) ok  "and the report says so, naming ci with what it added" ;;
  *) bad "and the report says so, naming ci with what it added" "$(printf '%s\n' "$_fa_o" | head -n 4)" ;;
esac
is "and setup.tsv gains ci's two slug rows with {{REPO}} kept" \
   "$(awk -F'\t' '($1 == "risk-labels" || $1 == "ci-anthropic-key") && index($4, "--repo {{REPO}}") { print $1 }' "$_fa_p/setup.tsv" | tr '\n' ' ')" \
   "risk-labels ci-anthropic-key "
is "so nothing is left undeclared after the run" "$(_fa_undecl)" ""
_fa_pv0="$(_fa_pv)"
_fa_ss="$(cd "$_fa_r" && CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" 2>&1)"
case "$_fa_ss" in
  *"Adopted automatically"*)  bad "the next session start has nothing left to adopt" "$(printf '%s' "$_fa_ss" | head -c 300)" ;;
  *'"hookSpecificOutput"'*)   ok  "the next session start has nothing left to adopt" ;;
  *)                          bad "the next session start has nothing left to adopt" "the hook printed no banner, so no adoption line proves nothing" ;;
esac
_fa_pv1="$(_fa_pv)"
if [ -n "$_fa_pv0" ] && [ "$_fa_pv0" = "$_fa_pv1" ]; then
  ok  "and the commissioning policy version does not move"
else
  bad "and the commissioning policy version does not move" "[$_fa_pv0] then [$_fa_pv1]"
fi
_fa_rl="$(_fs_cm "$_fa_r" --status | grep 'receipt:')"
case "$_fa_rl" in
  ''|*"stale (table set moved"*) bad "so the receipt the run wrote is not stale at the next read" "[$_fa_rl]" ;;
  *)                             ok  "so the receipt the run wrote is not stale at the next read" ;;
esac

cp "$_fa_p/capabilities" "$TMP/fa-caps.1"
_fa_u="$(_fa_undecl)"
_fa_o="$(_fs_cm "$_fa_r")"
if [ -n "$_fa_u" ]; then
  bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "the fixture still had [$_fa_u] undeclared"
elif ! cmp -s "$_fa_p/capabilities" "$TMP/fa-caps.1"; then
  bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "capabilities now [$(cat "$_fa_p/capabilities")]"
else
  case "$_fa_o" in
    *"adopted before this run"*)     bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "$_fa_o" ;;
    *"commissioning for adoptproj"*) ok  "a second full run with nothing undeclared prints no adoption line and changes no capability" ;;
    *)                               bad "a second full run with nothing undeclared prints no adoption line and changes no capability" "no report: $_fa_o" ;;
  esac
fi

[ -n "$_fh_sp" ] && { kill "$_fh_sp" 2>/dev/null; wait "$_fh_sp" 2>/dev/null; }
[ "$_fh_dlock_mine" -eq 1 ] && rmdir "$_fh_dlock" 2>/dev/null

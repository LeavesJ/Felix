_ib_build n16
# B7 (v4, v5): a session file the run cannot read (mode 000, as a root-owned
# file under sudo is) leaves what it could have decided unknown.
# (a) v5: main has an uncommitted edit; its one session's last record is 3 hours
# old, and a bookkeeping line made the file a minute old. Read, the worktree is
# not live and the view lists its edit; unread, live is unknown, not decided.
_ibnew b7a
IBB7AR="$(_ibmainwt "$IB/b7a")"
printf 'b7a\nedited, never committed\n' > "$IB/b7a/README.md"
IB_BR=""; _ibsess "$IBB7AR" s-7a; _ib_h 181 'edit the readme'; _ib_a 180 'Done.'; _ib_raw '{"type":"cost-state","cost":1}'; _ibage "$IB_F" 1
IBB7AF="$IB_F"
_ibrun B7AR -- inventory --repo "$IB/b7a" --tsv --no-gh
chmod 000 "$IBB7AF"
if [ -r "$IBB7AF" ]; then
  chmod 600 "$IBB7AF"
  skip "inventory B7: a session file the run cannot read leaves what it could have decided unknown" "a mode 000 file is readable here (run as root?)"
else
  _ibrun B7AT -- inventory --repo "$IB/b7a" --tsv --no-gh; _ibrun B7AV -- inventory --repo "$IB/b7a" --no-gh
  chmod 600 "$IBB7AF"
  is  "inventory B7a: read, a worktree whose one session last worked 3 hours ago is not live, though its file gained a bookkeeping line a minute ago (the control)" \
      "$(_ibmany B7AR worktree "$IBB7AR" live uncommitted unknown:live)" "live=no uncommitted=yes unknown:live=no"
  is  "inventory B7a: unread, that worktree's live is unknown, not decided from the file's mtime, and its uncommitted work stays" \
      "$(_ibmany B7AT worktree "$IBB7AR" live uncommitted unknown:live)" "live=no uncommitted=yes unknown:live=yes"
  is  "inventory B7a: and the view lists that worktree under uncommitted, as it does when the file is read" "$(_ibgroup2 "$(_ibo B7AV)" "$IBB7AR")" "uncommitted"
fi
# (b) and (c) v4: PR #7 heads w3, and chip task_7c7c7c7c is proposed in the old
# session, whose first human text the new session's is. s-7old worked on w3 and
# proposed the chip 3 hours ago; s-7new, a minute old, worked on w3 and was
# started from the chip's prompt. Read, s-7new owns the PR, which is live, and
# no chip is unstarted. With s-7new unread, its mtime is later than s-7old's
# newest record and later than the proposal.
_ibnew b7
IBB7R="$(_ibmainwt "$IB/b7")"
_ibg -C "$IB/b7" remote set-url origin git@github.com:acme/bravo7.git
mkdir -p "$IB/gh/acme_bravo7"
printf '[{"baseRefName":"main","headRefName":"w3","headRefOid":"%s","isCrossRepository":false,"number":7,"state":"OPEN","updatedAt":"%s"}]\n' \
  "$(_ibq -C "$IB/b7" rev-parse HEAD)" "$(_ibts 300)" > "$IB/gh/acme_bravo7/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":7,"statusCheckRollup":[]}]\n' > "$IB/gh/acme_bravo7/open.json"
IB_BR=w3; _ibsess "$IBB7R" s-7old
_ib_h 181 'start on w3'; _ib_chip 180 toolu_7c task_7c7c7c7c 'Seventh chip' 'please take up the seventh chip now'; _ib_a 180 'Done.'; _ibage "$IB_F" 180
_ibsess "$IBB7R" s-7new
_ib_h 2 'please take up the seventh chip now'; _ib_a 1 'On it, working on w3.'; _ibage "$IB_F" 1
IBB7NF="$IB_F"; IB_BR=""
_ibrun B7R -- inventory --repo "$IB/b7" --tsv
chmod 000 "$IBB7NF"
if [ -r "$IBB7NF" ]; then
  chmod 600 "$IBB7NF"
  skip "inventory B7b-c: a session file the run cannot read leaves the PR owner, its live and the chip it may have started unknown" "a mode 000 file is readable here (run as root?)"
else
  _ibrun B7T -- inventory --repo "$IB/b7" --tsv
  chmod 600 "$IBB7NF"
  is  "inventory B7b: read, the newest record naming w3 is s-7new's: it owns PR #7, which is live, and the chip its prompt started is no row (the control)" \
      "$(_ibcol B7R pr '#7' 5) $(_ibholds B7R pr '#7' live) $(_ibcount B7R chip)" "s-7new yes 0"
  is  "inventory B7b: unread, s-7new's mtime is later than the older owner's record, so PR #7's owner is unknown and its live is unknown, not s-7old and not decided" \
      "$(_ibcol B7T pr '#7' 5) $(_ibmany B7T pr '#7' live unknown:live)" "unknown live=no unknown:live=yes"
  is  "inventory B7c: and a chip proposed before that file's mtime is unknown:chip-unstarted, not held as chip-unstarted" \
      "$(_ibmany B7T chip task_7c7c7c7c chip-unstarted unknown:chip-unstarted)" "chip-unstarted=no unknown:chip-unstarted=yes"
fi
# (d) v5: the record directory itself cannot be entered. Read, the worktree is
# live and its newest session asks a question.
_ibnew b7d
IBB7DR="$(_ibmainwt "$IB/b7d")"
printf 'b7d\nedited, never committed\n' > "$IB/b7d/README.md"
IB_BR=""; _ibsess "$IBB7DR" s-7d; _ib_h 3 'edit the readme'; _ib_a 2 'Shall I commit it?'; _ibage "$IB_F" 2
IBB7DD="$IBP/$(_ibenc "$IBB7DR")"
_ibrun B7DR -- inventory --repo "$IB/b7d" --tsv --no-gh
chmod 000 "$IBB7DD"
if [ -r "$IBB7DD" ] && [ -x "$IBB7DD" ]; then
  chmod 755 "$IBB7DD"
  skip "inventory B7d: a record directory the run cannot enter answers unknown, not no session here" "a mode 000 directory is readable here (run as root?)"
else
  _ibrun B7DT -- inventory --repo "$IB/b7d" --tsv --no-gh
  chmod 755 "$IBB7DD"
  is  "inventory B7d: read, the worktree is live and its newest session s-7d asks a question (the control)" \
      "$(_ibcol B7DR worktree "$IBB7DR" 5) $(_ibmany B7DR worktree "$IBB7DR" live question)" "s-7d live=yes question=yes"
  is  "inventory B7d: a record directory the run cannot enter gives owner unknown and live, question and blocked unknown, not owner - and none held" \
      "$(_ibcol B7DT worktree "$IBB7DR" 5) $(_ibmany B7DT worktree "$IBB7DR" unknown:live unknown:question unknown:blocked)" "unknown unknown:live=yes unknown:question=yes unknown:blocked=yes"
  is  "inventory B7d: and the sessions cover row says a session file could not be read" "$(_ibcol B7DT cover sessions 8 | _ibsaid 'could not be read')" "said"
fi

# B8 (v7): a reflog entry whose commit object is missing is skipped by git log -g
# with status 0. Branch rv holds c1 then c2, and its index holds c1's tree, a
# staged revert; c1's commit object is then gone from the object store.
_ibnew b8
IBB8R="$(_ibmainwt "$IB/b8")"
_ibg -C "$IB/b8" checkout -q -b rv
printf 'r1\n' > "$IB/b8/r"; _ibci "$IB/b8" c1; IBB8C1="$(_ibq -C "$IB/b8" rev-parse HEAD)"
printf 'r2\n' > "$IB/b8/r"; _ibci "$IB/b8" c2
_ibg -C "$IB/b8" read-tree "$IBB8C1"
_ibrun B8R -- inventory --repo "$IB/b8" --tsv --no-gh --no-host
_ibx="$IB/b8/.git/objects/${IBB8C1:0:2}/${IBB8C1:2}"
if [ -f "$_ibx" ]; then
  mv "$_ibx" "$IB/b8-c1.bak"
  _ibrun B8T -- inventory --repo "$IB/b8" --tsv --no-gh --no-host
  mv "$IB/b8-c1.bak" "$_ibx"
  is  "inventory B8: with every object present, an index holding an earlier tip's tree is a staged revert (the control)" \
      "$(_ibmany B8R worktree "$IBB8R" hazard:staged-revert unknown:hazard:staged-revert)" "hazard:staged-revert=yes unknown:hazard:staged-revert=no"
  is  "inventory B8: when that earlier tip's commit object is gone, the check could not be made: unknown:hazard:staged-revert, not no hazard" \
      "$(_ibmany B8T worktree "$IBB8R" hazard:staged-revert unknown:hazard:staged-revert)" "hazard:staged-revert=no unknown:hazard:staged-revert=yes"
else skip "inventory B8: a reflog commit the object store lacks leaves the staged-revert check unknown" "the fixture's commit is not a loose object"; fi

# ---- R4 and the gaps G1-G4 (blind author, 2026-10-02) ---------------------
# Written from spec.md alone (§5.2, §6.6 and §11 row 23 as R4 now reads), with
# no inventory library read. Each block carries a control run in which the
# fixture is whole, so it is shown to hold what the assertion says it holds.
# R4 (ruled 2026-10-02 by the build session; build/disputes.md 1): a chip
# proposed before the mtime of any unreadable session file anywhere under the
# records root is unknown:chip-unstarted, whether or not that file's record
# directory holds a proposal, and the chips cover row then says how many
# session files could not be read. r4's main worktree has one session, which
# proposed chip 4a 180 minutes ago and chip 4b 30 minutes ago. A session filed
# under a directory of no worktree of r4, holding no proposal, last written 60
# minutes ago, opens on a text that is neither chip's prompt. Read, both chips
# are unstarted; unread, 4a (proposed before its mtime) is unknown and 4b
# (proposed after it) is still unstarted.
_ibnew r4
IBR4R="$(_ibmainwt "$IB/r4")"
IB_BR=""; _ibsess "$IBR4R" s-r4p
_ib_h 182 'file the follow-ups'
_ib_chip 180 toolu_r4a task_4a4a4a4a 'Chip four a' 'Four-a task: make the loader name the file it read, and test that two files give two names.'
_ib_chip 30 toolu_r4b task_4b4b4b4b 'Chip four b' 'Four-b task: make the writer sort its keys, and test that two runs over one input give one file.'
_ib_a 29 'Filed both.'; _ibage "$IB_F" 29
_ibopen "$IBP/-elsewhere-r4/s-r4x.jsonl" s-r4x
_ib_h 61 'look at something unrelated'; _ib_a 60 'Done.'; _ibage "$IB_F" 60
IBR4XF="$IB_F"
_ibrun R4R -- inventory --repo "$IB/r4" --tsv --no-gh
chmod 000 "$IBR4XF"
if [ -r "$IBR4XF" ]; then
  chmod 600 "$IBR4XF"
  skip "inventory R4: an unreadable session file in a record directory holding no proposal leaves an earlier chip unknown" "a mode 000 file is readable here (run as root?)"
else
  _ibrun R4T -- inventory --repo "$IB/r4" --tsv --no-gh
  chmod 600 "$IBR4XF"
  is  "inventory R4a: read, both chips are chip-unstarted and neither is unknown (the control)" \
      "$(_ibmany R4R chip task_4a4a4a4a chip-unstarted unknown:chip-unstarted) $(_ibmany R4R chip task_4b4b4b4b chip-unstarted unknown:chip-unstarted)" \
      "chip-unstarted=yes unknown:chip-unstarted=no chip-unstarted=yes unknown:chip-unstarted=no"
  is  "inventory R4a: an unreadable session file in a record directory holding no proposal, modified after a chip's proposal, makes that chip unknown:chip-unstarted, never chip-unstarted" \
      "$(_ibmany R4T chip task_4a4a4a4a chip-unstarted unknown:chip-unstarted)" "chip-unstarted=no unknown:chip-unstarted=yes"
  is  "inventory R4a: and a chip proposed after that file's mtime is still chip-unstarted" \
      "$(_ibmany R4T chip task_4b4b4b4b chip-unstarted unknown:chip-unstarted)" "chip-unstarted=yes unknown:chip-unstarted=no"
  is  "inventory R4b: the chips cover row then says 1 session files could not be read, and says nothing of the kind when every file is read" \
      "$(_ibhaselem R4T cover chips '1 session files could not be read') $(_ibcol R4R cover chips 8 | _ibsaid 'could not be read')" "yes unsaid"
fi

# G1 (round-2 review v7, its first half): §5.2 "Pending sections". A listing of
# docs/handoff/pending/ that fails is said in the default cover row's detail
# with the element handoff sections not read, and is not read as no sections.
# The default branch gains a pending section committed in the clone, so its
# tree objects are loose there; then the pending directory's tree goes away.
_ibnew g1
mkdir -p "$IB/g1/docs/handoff/pending"
printf '### a section\n\nWhat was done.\n\n## Next\n- do the next thing\n' > "$IB/g1/docs/handoff/pending/20261001T000000Z-g1.md"
_ibci "$IB/g1" 'a pending section'; _ibg -C "$IB/g1" push -q origin main
IBG1P="$(_ibq -C "$IB/g1" rev-parse 'origin/main:docs/handoff/pending')"
_ibrun G1R -- inventory --repo "$IB/g1" --tsv --no-gh --no-host
_ibx="$IB/g1/.git/objects/${IBG1P:0:2}/${IBG1P:2}"
if [ -f "$_ibx" ]; then
  mv "$_ibx" "$IB/g1-pending.bak"
  _ibrun G1T -- inventory --repo "$IB/g1" --tsv --no-gh --no-host; _ibrun G1V -- inventory --repo "$IB/g1" --no-gh --no-host
  mv "$IB/g1-pending.bak" "$_ibx"
  is  "inventory G1: with the tree read, the pending section is a handoff row and the default cover row says nothing of sections not read (the control)" \
      "$(_ibcount G1R handoff) $(_ibcol G1R cover default 8 | _ibsaid 'handoff sections not read')" "1 unsaid"
  is  "inventory G1: when the pending directory's tree cannot be read, the default cover row's detail holds the element handoff sections not read" \
      "$(case "$(_ibelem G1T cover default 'handoff sections not read')" in ('') echo unsaid ;; (*) echo said ;; esac)" "said"
  is  "inventory G1: and the human view's line for the default facet says it" \
      "$(LC_ALL=C awk 'index($0, "handoff sections not read") { f = 1 } END { print (f ? "said" : "unsaid") }' "$(_ibo G1V)")" "said"
else skip "inventory G1: a pending listing that fails is said as handoff sections not read" "the fixture's tree is not a loose object"; fi

# G2: CDPATH set in the caller's environment. A relative cd would follow it to
# another directory of the same name and print that directory on stdout. The
# orphan keep2 holds one file whose content is in no object; each decoy under
# $IB/cdp, named as keep2 or as a path to it, holds only the README main has.
_ibnew g2
_ibg -C "$IB/g2" worktree add -q -b g2live "$IB/g2/.claude/worktrees/live2"
mkdir -p "$IB/g2/.claude/worktrees/keep2"; printf 'unique to keep2, in no object\n' > "$IB/g2/.claude/worktrees/keep2/u"
for _ibn in keep2 worktrees/keep2 .claude/worktrees/keep2 g2/.claude/worktrees/keep2; do
  mkdir -p "$IB/cdp/$_ibn"; printf 'g2\n' > "$IB/cdp/$_ibn/README.md"
done
_ibrun G2R -- inventory --repo "$IB/g2" --tsv --no-gh --no-host
_ibrun G2T --env "CDPATH=$IB/cdp" -- inventory --repo "$IB/g2" --tsv --no-gh --no-host
_ibg2() { printf '%s %s %s' "$(_ibcol "$1" orphan "$IB/g2/.claude/worktrees/keep2" 7)" \
            "$(_ibholds "$1" orphan "$IB/g2/.claude/worktrees/keep2" landed)" \
            "$(case "$(_ibelem "$1" orphan "$IB/g2/.claude/worktrees/keep2" '1 of 1 files hold content in no object')" in ('') echo uncounted ;; (*) echo counted ;; esac)"; }
is  "inventory G2: without CDPATH, the orphan holding one file in no object has content not, is not landed, and counts 1 of 1 (the control)" "$(_ibg2 G2R)" "not no counted"
is  "inventory G2: with CDPATH naming decoys of the same names, that orphan still reads not, never landed, and counts 1 of 1" "$(_ibg2 G2T)" "not no counted"
is  "inventory G2: and with CDPATH set every line of --tsv is a row of eight fields, nothing printed between them" \
    "$(LC_ALL=C awk -F'\t' 'NF != 8 { n++ } END { print (NR > 0 ? n + 0 : "no rows") }' "$(_ibo G2T)")" "0"

# G3: §4.4 uncommitted "is unknown when the default branch is unknown", and
# §5.1: an unknown default carries unknown:uncommitted onto the rows it can
# apply to. g3's clone keeps its commit on origin/trunk only: origin/HEAD and
# origin/main are gone, there is no origin/master, and main has no upstream.
# Its main worktree is clean, so a reader that only compares changed paths
# would find nothing and print no unknown.
_ibnew g3
IBG3R="$(_ibmainwt "$IB/g3")"
_ibg -C "$IB/g3" push -q origin main:refs/heads/trunk
_ibg -C "$IB/g3" remote set-head origin -d
_ibg -C "$IB/g3" update-ref -d refs/remotes/origin/main
_ibg -C "$IB/g3" branch -q --unset-upstream main
_ibrun G3T -- inventory --repo "$IB/g3" --tsv --no-gh --no-host
is  "inventory G3: the fixture: g3's main worktree is clean, and only origin/trunk is left on origin" \
    "$(_ibq -C "$IB/g3" status --porcelain | LC_ALL=C awk 'END { print NR }') $(_ibq -C "$IB/g3" for-each-ref --format='%(refname)' refs/remotes | LC_ALL=C awk '{ printf "%s ", $0 }')" \
    "0 refs/remotes/origin/trunk "
is  "inventory G3: with the default branch unknown, a clean worktree reads unknown:uncommitted, not uncommitted and not landed, under a default cover row of unknown" \
    "$(_ibmany G3T worktree "$IBG3R" unknown:uncommitted uncommitted landed) $(_ibhead1 G3T cover default)" \
    "unknown:uncommitted=yes uncommitted=no landed=no unknown"

# G4: §4.7, possible duplicates "are on different branches". dupx is pushed
# as one commit and remade locally as another with the same change, so the
# remote origin/dupx is a row of its own (its tip is no ancestor of dupx's);
# dupy makes the same change on another branch. gh lists no PR, so origin/dupx
# and dupx are unproposed, and dupx and dupy unpushed.
_ibnew g4
IBG4M="$(_ibq -C "$IB/g4" rev-parse main)"
_ibmk - "$IB/g4" "$IBG4M" 'the change, pushed' g.txt 'the same change'; _ibg -C "$IB/g4" push -q origin "$IBC:refs/heads/dupx"
_ibmk - "$IB/g4" "$IBG4M" 'the change, remade' g.txt 'the same change'; _ibg -C "$IB/g4" branch -q dupx "$IBC"
_ibmk - "$IB/g4" "$IBG4M" 'the change, elsewhere' g.txt 'the same change'; _ibg -C "$IB/g4" branch -q dupy "$IBC"
_ibrun G4T -- inventory --repo "$IB/g4" --tsv --no-host
# _ibdup KIND REF NAME: "NAME" when the possible-duplicate element of that row
# names NAME as a whole ref, else "-NAME".
_ibdup() { _ibelem G4T "$1" "$2" 'possible duplicate of ' | LC_ALL=C awk -v w="$3" '{ sub(/^possible duplicate of /, ""); n = split($0, t, " "); for (i = 1; i <= n; i++) if (t[i] == w) f = 1 }
             END { print (f ? w : "-" w) }'; }
is  "inventory G4: each of dupx, origin/dupx and dupy is a possible duplicate, and dupy's names both of the others (the control)" \
    "$(_ibholds G4T branch dupx possible-duplicate) $(_ibholds G4T remote origin/dupx possible-duplicate) $(_ibholds G4T branch dupy possible-duplicate) $(_ibdup branch dupy dupx) $(_ibdup branch dupy origin/dupx)" \
    "yes yes yes dupx origin/dupx"
is  "inventory G4: possible-duplicate never names a row on the same branch: dupx's names dupy and not origin/dupx, and origin/dupx's names dupy and not dupx" \
    "$(_ibdup branch dupx dupy) $(_ibdup branch dupx origin/dupx) $(_ibdup remote origin/dupx dupy) $(_ibdup remote origin/dupx dupx)" \
    "dupy -origin/dupx dupy -dupx"

# ---- the round-4 survivors (build/mutants-round4.md, 2026-10-02) -----------
# 21 mutants of the fixes since a2f45582 survived every assertion above: code
# whose loss nothing could notice. Each block below holds one of them to
# section 5.2 "unread is unknown" as the contract states it, with a control run
# in which everything is read. A few reads cannot be made to fail by a fixture
# alone, so a stand-in git ($IB/fgit/git) fails them when the run is given
# IBFG: vanish removes a file named vanish* after the listing found it and
# before hash-object reads it (a file deleted mid-scan); walk=SHA makes a
# rev-list whose tips include SHA die (a history that could not be walked);
# logg=REF makes git log -g of REF print its reflog and then die. Every other
# call is the real git's. The mode 000 parts are readable to root, where they skip.
mkdir -p "$IB/fgit"
{ printf '#!/bin/sh\nG=%s\nD=%s\n' "'$IB_GIT'" "'$IB'"
  cat <<'IBFGEOF'
m="${IBFG-}"
case "$m" in
  vanish) case " $* " in *" hash-object "*" --stdin-paths "*)
    cat > "$D/fgit.in"
    while IFS= read -r p; do case "${p##*/}" in vanish*) rm -f "$p" ;; esac; done < "$D/fgit.in"
    exec "$G" "$@" < "$D/fgit.in" ;; esac ;;
  walk=*) case " $* " in *" rev-list "*"--stdin "*)
    cat > "$D/fgit.in"
    if grep -qxF "${m#walk=}" "$D/fgit.in"; then echo "fatal: bad object ${m#walk=}" >&2; exit 128; fi
    exec "$G" "$@" < "$D/fgit.in" ;; esac ;;
  logg=*) case " $* " in *" log -g "*" ${m#logg=} "*)
    "$G" "$@"; echo 'fatal: the reflog could not be read to its end' >&2; exit 128 ;; esac ;;
esac
exec "$G" "$@"
IBFGEOF
} > "$IB/fgit/git"; chmod +x "$IB/fgit/git"
IBFGP="$IB/fgit:$IB/stub:$PATH"

# M4-B2 (section 4.6, 5.2 "Orphan files"): five orphans of s2, each holding a
# copy of main's README (its content in an object) and one thing more, unique:
#   oign  an ignored file the run cannot read     (mutant B2d)
#   oigd  an ignored directory it cannot enter    (B2g)
#   osub  a subdirectory it cannot enter          (B2f)
#   ovan  a file deleted after the listing, before it is hashed (B2b)
#   ovanl the same, ignored                                     (B2h)
# Read whole, each holds content in no object and reads not.
_ibnew s2 .gitignore "$(printf '*.log\nign/')"
_ibg -C "$IB/s2" worktree add -q -b s2live "$IB/s2/.claude/worktrees/live2"
IBS2="$IB/s2/.claude/worktrees"
for _ibn in oign oigd osub ovan ovanl; do mkdir -p "$IBS2/$_ibn"; cp "$IB/s2/README.md" "$IBS2/$_ibn/a"; done
printf 'unique to oign\n' > "$IBS2/oign/x.log"
mkdir -p "$IBS2/oigd/ign/deep"; printf 'unique to oigd\n' > "$IBS2/oigd/ign/deep/z"
mkdir -p "$IBS2/osub/d"; printf 'unique to osub\n' > "$IBS2/osub/d/f"
printf 'unique to ovan\n' > "$IBS2/ovan/vanish"; printf 'unique to ovanl\n' > "$IBS2/ovanl/vanish.log"
_ibrun S2R -- inventory --repo "$IB/s2" --tsv --no-gh --no-host
chmod 000 "$IBS2/oign/x.log" "$IBS2/oigd/ign/deep" "$IBS2/osub/d"
if [ -r "$IBS2/oign/x.log" ]; then _ibs2ro=0; else _ibs2ro=1; fi
_ibrun S2T --path "$IBFGP" --env IBFG=vanish -- inventory --repo "$IB/s2" --tsv --no-gh --no-host
chmod 644 "$IBS2/oign/x.log"; chmod 755 "$IBS2/oigd/ign/deep" "$IBS2/osub/d"
# _ibs2 RUN NAME: the orphan's content, whether it is landed, and whether its
# detail says that files (ignored ones: ignored files) could not be read.
_ibs2() { printf '%s %s %s %s' "$(_ibcol "$1" orphan "$IBS2/$2" 7)" "$(_ibholds "$1" orphan "$IBS2/$2" landed)" \
            "files=$(_ibcol "$1" orphan "$IBS2/$2" 8 | LC_ALL=C awk '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] ~ /^[0-9]+ files could not be read$/) f = 1 } END { print (f ? "said" : "unsaid") }')" \
            "ignored=$(_ibcol "$1" orphan "$IBS2/$2" 8 | LC_ALL=C awk '{ n = split($0, e, "; "); for (i = 1; i <= n; i++) if (e[i] ~ /^[0-9]+ ignored files could not be read$/) f = 1 } END { print (f ? "said" : "unsaid") }')"; }
is  "inventory M4-B2: read whole, each of s2's five orphans holds content in no object and reads not, not landed, with nothing said unread (the control)" \
    "$(for _ibn in oign oigd osub ovan ovanl; do printf '%s; ' "$(_ibs2 S2R "$_ibn")"; done)" \
    "not no files=unsaid ignored=unsaid; not no files=unsaid ignored=unsaid; not no files=unsaid ignored=unsaid; not no files=unsaid ignored=unsaid; not no files=unsaid ignored=unsaid; "
if [ "$_ibs2ro" = 1 ]; then
  is  "inventory M4-B2d: an ignored file the run cannot read leaves the orphan's content unknown, never landed, and is said as ignored files that could not be read" \
      "$(_ibs2 S2T oign)" "unknown no files=unsaid ignored=said"
  is  "inventory M4-B2g: an ignored directory the run cannot enter does the same: content unknown, never landed, said as ignored files that could not be read" \
      "$(_ibs2 S2T oigd)" "unknown no files=unsaid ignored=said"
  is  "inventory M4-B2f: a subdirectory the listing cannot enter leaves the content unknown and is said as files that could not be read: 1 files could not be read" \
      "$(_ibcol S2T orphan "$IBS2/osub" 7) $(_ibhaselem S2T orphan "$IBS2/osub" '1 files could not be read')" "unknown yes"
else skip "inventory M4-B2d, B2g, B2f: unreadable ignored files and directories an orphan's listing cannot enter" "a mode 000 file is readable here (run as root?)"; fi
is  "inventory M4-B2b: a file deleted between the listing and the hash was never read: the orphan's content is unknown, never landed, and files that could not be read are said" \
    "$(_ibs2 S2T ovan)" "unknown no files=said ignored=unsaid"
is  "inventory M4-B2h: an ignored file deleted between the listing and the hash: content unknown, never landed, and ignored files that could not be read are said" \
    "$(_ibs2 S2T ovanl)" "unknown no files=unsaid ignored=said"

# M4-B6 (section 5.2 "A directory the listing cannot enter is said the same
# way"): B6's orphan gone6, which the run could not enter, was read by neither
# listing, so both say so (mutants B6a, B6b).
if [ -f "$(_ibo B6T)" ]; then
  is  "inventory M4-B6: the orphan directory the run cannot enter is said unread by both listings: 1 files could not be read and 1 ignored files could not be read" \
      "$(_ibhaselem B6T orphan "$IB/b6/.claude/worktrees/gone6" '1 files could not be read') $(_ibhaselem B6T orphan "$IB/b6/.claude/worktrees/gone6" '1 ignored files could not be read')" "yes yes"
else skip "inventory M4-B6: an orphan directory the run cannot enter is said unread by both listings" "B6 did not run (a mode 000 directory is readable here)"; fi

# M4-B7a (section 5.2 "Session files", 4.5): b7a's one session file, unread,
# could have decided the owner, question and blocked as well as live (mutants
# B7a3, B7a4). Read, it is s-7a and asks nothing.
if [ -f "$(_ibo B7AT)" ]; then
  is  "inventory M4-B7a: read, the worktree's owner is s-7a and it holds neither question nor blocked, nor either unknown (the control)" \
      "$(_ibcol B7AR worktree "$IBB7AR" 5) $(_ibmany B7AR worktree "$IBB7AR" question blocked unknown:question unknown:blocked)" \
      "s-7a question=no blocked=no unknown:question=no unknown:blocked=no"
  is  "inventory M4-B7a: unread, its owner is unknown, not the session whose file could not be read, and question and blocked are unknown, not no" \
      "$(_ibcol B7AT worktree "$IBB7AR" 5) $(_ibmany B7AT worktree "$IBB7AR" question blocked unknown:question unknown:blocked)" \
      "unknown question=no blocked=no unknown:question=yes unknown:blocked=yes"
else skip "inventory M4-B7a: an unread session file leaves the owner, question and blocked unknown" "B7a did not run (a mode 000 file is readable here)"; fi

# M4-B7b (section 6.7, 5.2): PR #8 heads w8, and s7o's one session file, which
# names no branch, is in the window. Read, no record names w8 and the owner is
# -; unread, the file could have, so the owner and live are unknown (mutant B7b2).
_ibnew s7o
IBS7OR="$(_ibmainwt "$IB/s7o")"
_ibg -C "$IB/s7o" remote set-url origin git@github.com:acme/s7o.git
mkdir -p "$IB/gh/acme_s7o"
printf '[{"baseRefName":"main","headRefName":"w8","headRefOid":"%s","isCrossRepository":false,"number":8,"state":"OPEN","updatedAt":"%s"}]\n' \
  "$(_ibq -C "$IB/s7o" rev-parse HEAD)" "$(_ibts 300)" > "$IB/gh/acme_s7o/all.json"
printf '[{"isDraft":false,"labels":[],"mergeable":"MERGEABLE","number":8,"statusCheckRollup":[]}]\n' > "$IB/gh/acme_s7o/open.json"
IB_BR=""; _ibsess "$IBS7OR" s-8x; _ib_h 11 'look at the readme'; _ib_a 10 'Read it.'; _ibage "$IB_F" 10; IBS7OF="$IB_F"
_ibrun S7OR -- inventory --repo "$IB/s7o" --tsv
chmod 000 "$IBS7OF"
if [ -r "$IBS7OF" ]; then
  chmod 600 "$IBS7OF"
  skip "inventory M4-B7b: a PR whose head no readable record names, with a session file unread, has owner unknown" "a mode 000 file is readable here (run as root?)"
else
  _ibrun S7OT -- inventory --repo "$IB/s7o" --tsv
  chmod 600 "$IBS7OF"
  is  "inventory M4-B7b: read, no record names w8, so PR #8's owner is - and it is not live (the control)" \
      "$(_ibcol S7OR pr '#8' 5) $(_ibmany S7OR pr '#8' live unknown:live)" "- live=no unknown:live=no"
  is  "inventory M4-B7b: with the one session file in the window unread, PR #8's owner is unknown, not -, and its live is unknown" \
      "$(_ibcol S7OT pr '#8' 5) $(_ibmany S7OT pr '#8' live unknown:live)" "unknown live=no unknown:live=yes"
fi

# M4-B3 (section 5.2 "Missing commit objects", 4.3 rule 4): s3's branch wl adds
# f.txt and was never pushed; main later gained the same f.txt by a commit of
# its own, so wl's blobs are main's and rule 3 alone reads it landed. With the
# stand-in's walk dying for wl's tip, wl's own walk could not be made: its
# content is unknown, it is never landed, and unpushed is unknown (mutants
# B3b, B3c).
_ibnew s3
_ibmk - "$IB/s3" "$(_ibq -C "$IB/s3" rev-parse main)" 'wl adds f' f.txt 'the same f'; _ibg -C "$IB/s3" branch -q wl "$IBC"; IBS3W="$IBC"
printf 'the same f\n' > "$IB/s3/f.txt"; _ibci "$IB/s3" 'main gains f'; _ibg -C "$IB/s3" push -q origin main
_ibrun S3R -- inventory --repo "$IB/s3" --tsv --no-gh --no-host
_ibrun S3T --path "$IBFGP" --env "IBFG=walk=$IBS3W" -- inventory --repo "$IB/s3" --tsv --no-gh --no-host
is  "inventory M4-B3: walked, wl's blobs are main's, so its content is landed and nothing is unpushed (the control)" \
    "$(_ibcol S3R branch wl 7) $(_ibmany S3R branch wl unpushed unknown:unpushed)" "landed unpushed=no unknown:unpushed=no"
is  "inventory M4-B3: when wl's own walk dies, its content is unknown, never landed by blob equality, and unpushed is unknown, not no" \
    "$(_ibcol S3T branch wl 7) $(_ibmany S3T branch wl landed unpushed unknown:unpushed)" "unknown landed=no unpushed=no unknown:unpushed=yes"

# M4-B3m (section 4.3 rules 2 and 4): in s3m, PR #11 merged into main with head
# H1, whose parent is b1's tip; b2 is a branch of its own, on no PR. Then PR #12
# merges too, its head H2 a commit whose parent this clone lacks, so the merged
# heads cannot be walked together. H1's history still can: b1 stays landed
# (mutant B3d). H2's cannot, and b2 might be in it: b2 is unknown, not not (B3e).
_ibnew s3m
_ibg -C "$IB/s3m" remote set-url origin git@github.com:acme/s3m.git
IBS3MM="$(_ibq -C "$IB/s3m" rev-parse main)"
_ibmk - "$IB/s3m" "$IBS3MM" 'm1 first' m1.txt 'first'; _ibg -C "$IB/s3m" branch -q b1 "$IBC"
_ibmk - "$IB/s3m" "$IBC" 'm1 second' m1b.txt 'second'; IBS3H1="$IBC"
_ibmk - "$IB/s3m" "$IBS3MM" 'b2 alone' b2.txt 'b2'; _ibg -C "$IB/s3m" branch -q b2 "$IBC"
IBS3H2="$(printf 'tree %s\nparent 1111111111111111111111111111111111111111\nauthor F <f@example.invalid> 1700000000 +0000\ncommitter F <f@example.invalid> 1700000000 +0000\n\nhead of #12\n' \
  "$(_ibq -C "$IB/s3m" rev-parse 'main^{tree}')" | _ibg -C "$IB/s3m" hash-object -t commit -w --literally --stdin)"
mkdir -p "$IB/gh/acme_s3m"; printf '[]\n' > "$IB/gh/acme_s3m/open.json"
_ibs3pr() { printf '{"baseRefName":"main","headRefName":"%s","headRefOid":"%s","isCrossRepository":false,"number":%s,"state":"MERGED","updatedAt":"%s"}' "$1" "$2" "$3" "$(_ibts 600)"; }
printf '[%s]\n' "$(_ibs3pr m1 "$IBS3H1" 11)" > "$IB/gh/acme_s3m/all.json"
_ibrun S3MR -- inventory --repo "$IB/s3m" --tsv --no-host
printf '[%s,%s]\n' "$(_ibs3pr m1 "$IBS3H1" 11)" "$(_ibs3pr m2 "$IBS3H2" 12)" > "$IB/gh/acme_s3m/all.json"
_ibrun S3MT -- inventory --repo "$IB/s3m" --tsv --no-host
is  "inventory M4-B3m: with only PR #11 merged, b1 (its head's parent) is landed and b2 is not (the control)" \
    "$(_ibcol S3MR branch b1 7) $(_ibcol S3MR branch b2 7)" "landed not"
is  "inventory M4-B3m: with PR #12's head unwalkable beside it, b1 is still landed through #11's head, and b2 is unknown, not not" \
    "$(_ibcol S3MT branch b1 7) $(_ibcol S3MT branch b2 7)" "landed unknown"

# M4-B8 (section 5.2 "The staged-revert check", 4.4): four linked worktrees of
# s8, each on its own branch with a change staged. In each, a read the check
# needs fails, and the answer is unknown:hazard:staged-revert, not no:
#   r8b  git log -g dies after printing the whole reflog (the stand-in; mutant B8b)
#   r8c  the index cannot be read (mode 000; B8c)
#   r8d  a reflog entry's tree is not in the clone (B8d)
#   r8e  the index is the tree of an earlier tip c1 whose parent the clone
#        lacks, so whether c1 comes before HEAD cannot be told (B8e)
_ibnew s8
for _ibn in r8b r8c r8d r8e; do _ibg -C "$IB/s8" worktree add -q -b "$_ibn" "$IB/s8/.claude/worktrees/$_ibn"; done
IBS8="$IB/s8/.claude/worktrees"
for _ibn in r8b r8c r8d; do printf '%s\n' "$_ibn" > "$IBS8/$_ibn/n.txt"; _ibci "$IBS8/$_ibn" "$_ibn commits"; printf 'staged\n' >> "$IBS8/$_ibn/n.txt"; _ibg -C "$IBS8/$_ibn" add n.txt; done
_ibx="$(printf 'tree 2222222222222222222222222222222222222222\nparent %s\nauthor F <f@example.invalid> 1700000000 +0000\ncommitter F <f@example.invalid> 1700000000 +0000\n\na tip whose tree the clone lacks\n' \
  "$(_ibq -C "$IB/s8" rev-parse main)" | _ibg -C "$IB/s8" hash-object -t commit -w --literally --stdin)"
IBS8D="$(_ibq -C "$IBS8/r8d" rev-parse HEAD)"
_ibg -C "$IBS8/r8d" update-ref -m 'to a tip whose tree is gone' refs/heads/r8d "$_ibx"
_ibg -C "$IBS8/r8d" update-ref -m 'back' refs/heads/r8d "$IBS8D"
printf 'r1\n' > "$IBS8/r8e/r"; _ibg -C "$IBS8/r8e" add r
IBS8C1="$(printf 'tree %s\nparent 1111111111111111111111111111111111111111\nauthor F <f@example.invalid> 1700000000 +0000\ncommitter F <f@example.invalid> 1700000000 +0000\n\nc1\n' \
  "$(_ibq -C "$IBS8/r8e" write-tree)" | _ibg -C "$IB/s8" hash-object -t commit -w --literally --stdin)"
_ibg -C "$IBS8/r8e" reset -q --hard "$IBS8C1"
printf 'r2\n' > "$IBS8/r8e/r"; _ibci "$IBS8/r8e" c2; _ibg -C "$IBS8/r8e" read-tree "$IBS8C1"
_ibrun S8R -- inventory --repo "$IB/s8" --tsv --no-gh --no-host
IBS8CI="$(_ibq -C "$IBS8/r8c" rev-parse --git-path index)"; case "$IBS8CI" in /*) ;; *) IBS8CI="$IBS8/r8c/$IBS8CI" ;; esac
chmod 000 "$IBS8CI"
if [ -r "$IBS8CI" ]; then _ibs8ro=0; else _ibs8ro=1; fi
_ibrun S8T --path "$IBFGP" --env IBFG=logg=refs/heads/r8b -- inventory --repo "$IB/s8" --tsv --no-gh --no-host
chmod 644 "$IBS8CI"
_ibs8() { _ibmany "$1" worktree "$IBS8/$2" hazard:staged-revert unknown:hazard:staged-revert; }
is  "inventory M4-B8: read whole, r8b and r8c stage a change that is no earlier tip, so neither holds the hazard nor an unknown (the control)" \
    "$(_ibs8 S8R r8b) $(_ibs8 S8R r8c)" \
    "hazard:staged-revert=no unknown:hazard:staged-revert=no hazard:staged-revert=no unknown:hazard:staged-revert=no"
is  "inventory M4-B8b: a git log -g that dies, though it printed every entry, leaves the check unknown, not no hazard" \
    "$(_ibs8 S8T r8b)" "hazard:staged-revert=no unknown:hazard:staged-revert=yes"
if [ "$_ibs8ro" = 1 ]; then
  is  "inventory M4-B8c: an index the run cannot read leaves the check unknown, not no hazard" \
      "$(_ibs8 S8T r8c)" "hazard:staged-revert=no unknown:hazard:staged-revert=yes"
else skip "inventory M4-B8c: an index the run cannot read leaves the staged-revert check unknown" "a mode 000 file is readable here (run as root?)"; fi
is  "inventory M4-B8d: a reflog entry whose tree the clone lacks could not be compared with the index: unknown, not no hazard" \
    "$(_ibs8 S8T r8d)" "hazard:staged-revert=no unknown:hazard:staged-revert=yes"
is  "inventory M4-B8e: an index holding the tree of an earlier tip whose order against HEAD cannot be read is unknown, not a decided hazard" \
    "$(_ibs8 S8T r8e)" "hazard:staged-revert=no unknown:hazard:staged-revert=yes"

# M4-R4 (section 5.2 "Chips and unreadable session files", R4): the chips
# cover row counts the unreadable session files later than a chip's proposal,
# and says the count only when a chip was left unknown.
# r4c: chip 4c proposed 180 minutes ago; two unreadable files elsewhere under
# the root, one written 181 minutes ago (before the proposal), one 60 (after
# it). 4c is unknown, and the count is 1, not 2 (mutant R4c).
_ibnew r4c
IBR4CR="$(_ibmainwt "$IB/r4c")"
IB_BR=""; _ibsess "$IBR4CR" s-r4c
_ib_h 182 'file one follow-up'
_ib_chip 180 toolu_r4c task_4c4c4c4c 'Chip four c' 'Four-c task: make the parser reject a key given twice, and test that the error names the key.'
_ib_a 179 'Filed.'; _ibage "$IB_F" 179
_ibopen "$IBP/-elsewhere-r4c/s-r4c1.jsonl" s-r4c1; _ib_h 182 'an unrelated look'; _ib_a 181 'Done.'; _ibage "$IB_F" 181; IBR4C1="$IB_F"
_ibopen "$IBP/-elsewhere-r4c/s-r4c2.jsonl" s-r4c2; _ib_h 61 'another unrelated look'; _ib_a 60 'Done.'; _ibage "$IB_F" 60; IBR4C2="$IB_F"
# r4d: chip 4d1 proposed 180 minutes ago and started 120 minutes ago by a
# readable session; chip 4d2 proposed 30 minutes ago; one unreadable file
# written 60 minutes ago. It is later than 4d1's proposal, but 4d1 was started
# and 4d2 came after it, so no chip is unknown and the row says no count (R4d).
_ibnew r4d
IBR4DR="$(_ibmainwt "$IB/r4d")"
IB_BR=""; _ibsess "$IBR4DR" s-r4d
_ib_h 182 'file two follow-ups'
_ib_chip 180 toolu_r4d1 task_4d1d1d1d 'Chip four d one' 'Four-d-one task: make the cache drop entries older than a day, and test the boundary second.'
_ib_chip 30 toolu_r4d2 task_4d2d2d2d 'Chip four d two' 'Four-d-two task: make the logger flush on exit, and test that a killed run keeps its last line.'
_ib_a 29 'Filed both.'; _ibage "$IB_F" 29
_ibopen "$IBP/-elsewhere-r4d/s-r4dgo.jsonl" s-r4dgo
_ib_h 121 'Four-d-one task: make the cache drop entries older than a day, and test the boundary second.'; _ib_a 120 'On it.'; _ibage "$IB_F" 120
_ibopen "$IBP/-elsewhere-r4d/s-r4dx.jsonl" s-r4dx; _ib_h 61 'look at something unrelated'; _ib_a 60 'Done.'; _ibage "$IB_F" 60; IBR4DX="$IB_F"
_ibrun R4CR -- inventory --repo "$IB/r4c" --tsv --no-gh; _ibrun R4DR -- inventory --repo "$IB/r4d" --tsv --no-gh
# One fixture's files unreadable at a time: each is under the records root, so it counts for every run.
chmod 000 "$IBR4C1" "$IBR4C2"
if [ -r "$IBR4C2" ]; then
  chmod 600 "$IBR4C1" "$IBR4C2"
  skip "inventory M4-R4: the chips cover row's count of unreadable session files" "a mode 000 file is readable here (run as root?)"
else
  _ibrun R4CT -- inventory --repo "$IB/r4c" --tsv --no-gh
  chmod 600 "$IBR4C1" "$IBR4C2"; chmod 000 "$IBR4DX"
  _ibrun R4DT -- inventory --repo "$IB/r4d" --tsv --no-gh
  chmod 600 "$IBR4DX"
  is  "inventory M4-R4c: read, chip 4c is chip-unstarted and the chips cover row says nothing unread (the control)" \
      "$(_ibmany R4CR chip task_4c4c4c4c chip-unstarted unknown:chip-unstarted) $(_ibcol R4CR cover chips 8 | _ibsaid 'could not be read')" \
      "chip-unstarted=yes unknown:chip-unstarted=no unsaid"
  is  "inventory M4-R4c: an unreadable file written after 4c's proposal makes it unknown, and the count is of files later than a proposal: 1, not the 2 unreadable in the scan's window" \
      "$(_ibmany R4CT chip task_4c4c4c4c chip-unstarted unknown:chip-unstarted) $(_ibhaselem R4CT cover chips '1 session files could not be read') $(_ibhaselem R4CT cover chips '2 session files could not be read')" \
      "chip-unstarted=no unknown:chip-unstarted=yes yes no"
  is  "inventory M4-R4d: read, chip 4d1 was started (no row) and 4d2 is chip-unstarted (the control)" \
      "$(_ibcount R4DR chip) $(_ibmany R4DR chip task_4d2d2d2d chip-unstarted unknown:chip-unstarted)" "1 chip-unstarted=yes unknown:chip-unstarted=no"
  is  "inventory M4-R4d: when the one unreadable file left no chip unknown (4d1 started, 4d2 proposed after it), the chips cover row says no count" \
      "$(_ibcount R4DT chip) $(_ibmany R4DT chip task_4d2d2d2d chip-unstarted unknown:chip-unstarted) $(_ibcol R4DT cover chips 8 | _ibsaid 'could not be read')" \
      "1 chip-unstarted=yes unknown:chip-unstarted=no unsaid"
fi

# M4-CDPATH (build/disputes.md 2): the engine changes directory by .git, the
# relative name git rev-parse --git-common-dir prints in a main worktree. With
# CDPATH naming a directory that holds a .git of its own, a cd that followed it
# would read another directory: g2's linked worktree as another repository's,
# and its orphan as unread. G2's decoys carry the orphan's names, not .git.
mkdir -p "$IB/cdp2/.git"
_ibrun G2U --env "CDPATH=$IB/cdp2" -- inventory --repo "$IB/g2" --tsv --no-gh --no-host
is  "inventory M4-CDPATH: with CDPATH naming a directory that holds a .git, the orphan keep2 still reads not, never landed, 1 of 1, and live2 is read as g2's own" \
    "$(_ibg2 G2U) $(_ibcol G2U worktree "$IB/g2/.claude/worktrees/live2" 8 | _ibsaid 'another repository')" "not no counted unsaid"

# ---- §4.1: across every run ----------------------------------------------
_ibx=""; for _ibk in RUN1 RUN2 RUN3 RUN4 MISC PART K R3 U F G H1 H2 O1 V1 T1 T3 M1 A5a A5b A5c A27 A31a A31b CCD; do _ibx="$_ibx $(_ibo "$_ibk")"; done
is  "inventory N16: no row in any run is landed while its content is not, partly or unknown" \
    "$(LC_ALL=C awk -F'\t' '$1 != "cover" && index("," $4 ",", ",landed,") && ($7 == "not" || $7 == "partly" || $7 == "unknown") { printf "%s %s [%s] %s; ", $1, $3, $4, $7 } $1 != "cover" { n++ } END { if (n < 20) printf "only %d rows", n }' $_ibx)" ""


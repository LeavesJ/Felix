printf '\na person'"'"'s git colour configuration never reaches what the engine parses\n'
# Written blind, 2026-10-08, from the contract alone (P1-P7): a person can turn
# git's colour on for output that is not a terminal (color.ui=always or a
# family key in any config file, GIT_CONFIG_COUNT, or GIT_CONFIG_PARAMETERS,
# which is what `git -c` exports to its children), and then the lines the
# engine parses start with an escape, so `^+`, `^??` and `diff --git` stop
# matching. The decided mechanism: every executable under engine/harness
# appends eleven `'color.<key>=never'` entries to GIT_CONFIG_PARAMETERS and
# exports it, once, without forking. (After review the entries are thirteen:
# see the section that ends this block.)
#
# This suite is itself one of those executables, so once it carries the pin
# everything it starts inherits a pinned value. Every drive below therefore
# starts the entry point under test through _gc_run, which removes the
# suite's GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT and points HOME, XDG and
# the system file away from the machine, and then sets only what the case
# names. Without that, every assertion here would pass whether or not the
# script under test pinned anything.
#
# Each colour source has a control: raw git, outside the engine, under that
# source alone, writes an escape byte into a pipe. Each drive has a control:
# with no colour configuration it gives the answer it should. So nothing here
# passes because colour never came on, or because a drive never reached the
# code it names.
#
# What git received is read at git itself: a shim first on PATH runs the real
# git, then appends its exit status, GIT_CONFIG_COUNT, GIT_CONFIG_KEY_0,
# GIT_CONFIG_VALUE_0 and GIT_CONFIG_PARAMETERS to a log, one line per call.
# tests/red gets a shim that records and refuses, so the copy driven here stops
# at its first git call, and it has no tests/run beside it, so it can never
# start a suite run.
#
# The static checks below read each executable's own text, so they require the
# pin written inline in each file, as the caller-environment unset line is.
# A pin kept in a lib and sourced would read as absent. They also see only the
# word `git` in a file's own lines: a lib function that runs git, called before
# the pin, is not seen there. Where that matters most it is driven instead
# (felix, a hook, bin/secret-scan, tests/red).
#
# All git work happens in repositories made here, under $TMP, with
# GIT_CEILING_DIRECTORIES at $TMP itself, so discovery cannot climb out even
# from the fixture's top directory, and with the caller's repository-location
# variables removed, so an inherited GIT_DIR cannot point a fixture command at
# a real repository.
GCH="$(cd "$TMP" && pwd -P)/gcolour"
GCT="${GCH%/gcolour}"
mkdir -p "$GCH/home/.config" "$GCH/hcolour/.config" "$GCH/shim" "$GCH/refuse" "$GCH/regions" "$GCH/redcopy/tests"
_gc_esc="$(printf '\033')"
_gc_pin="'color.ui=never' 'color.advice=never' 'color.branch=never' 'color.diff=never' 'color.grep=never' 'color.interactive=never' 'color.push=never' 'color.remote=never' 'color.showBranch=never' 'color.status=never' 'color.transport=never' 'color.pager=false' 'blame.coloring=none'"
_gc_realgit="$(command -v git)"
_gc_run() {   # [VAR=value ...] cmd args: with no git configuration of the caller's or the machine's
  env -u GIT_CONFIG_PARAMETERS -u GIT_CONFIG_COUNT -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM \
      -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY \
      -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_NAMESPACE \
      HOME="$GCH/home" XDG_CONFIG_HOME="$GCH/home/.config" GIT_CONFIG_NOSYSTEM=1 \
      GIT_CEILING_DIRECTORIES="$GCT" "$@"
}
_gcg() { ( cd "$GCH" || exit 1; _gc_run "$_gc_realgit" -c user.name=t -c user.email=t@t "$@" ); }
_gc_colour() {   # <repo> on|off: color.ui and every family key at always, in the repository's own config file
  local k
  case "$1" in "$GCH"/?*) ;; *) return 1 ;; esac
  [ -f "$1/.git/config" ] || return 1
  if [ "$2" = on ]; then
    for k in ui advice branch diff grep interactive push remote showBranch status transport; do
      _gcg config --file "$1/.git/config" "color.$k" always
    done
  else
    _gcg config --file "$1/.git/config" --remove-section color 2>/dev/null
  fi
  return 0
}
_gc_hasesc() { case "$1" in *"$_gc_esc"*) printf yes ;; *) printf no ;; esac; }

cat > "$GCH/shim/git" <<EOF
#!/bin/sh
"$_gc_realgit" "\$@"
rc=\$?
printf '%s\t%s\t%s\t%s\t%s\n' "\$rc" "\${GIT_CONFIG_COUNT-(unset)}" "\${GIT_CONFIG_KEY_0-(unset)}" "\${GIT_CONFIG_VALUE_0-(unset)}" "\${GIT_CONFIG_PARAMETERS-(unset)}" >> "$GCH/shim.log"
printf '%s\n' "\$*" >> "$GCH/shim.args"
exit \$rc
EOF
cat > "$GCH/refuse/git" <<EOF
#!/bin/sh
printf '%s\t%s\t%s\t%s\t%s\n' 128 "\${GIT_CONFIG_COUNT-(unset)}" "\${GIT_CONFIG_KEY_0-(unset)}" "\${GIT_CONFIG_VALUE_0-(unset)}" "\${GIT_CONFIG_PARAMETERS-(unset)}" >> "$GCH/shim.log"
exit 128
EOF
chmod +x "$GCH/shim/git" "$GCH/refuse/git"
# The log read three ways: every call's GIT_CONFIG_PARAMETERS equal to a value,
# beginning with one, and every call's status, COUNT, KEY_0 and VALUE_0 equal
# to four. Each answers `ok` or says the first call that differed; an empty log
# is never ok, so a drive that made no git call cannot pass.
_gc_shim_is() {
  [ -s "$GCH/shim.log" ] || { printf 'no git call was recorded'; return 0; }
  GC_E="$1" LC_ALL=C awk -F'\t' '
    { v = $5; for (i = 6; i <= NF; i++) v = v "\t" $i
      if (v != ENVIRON["GC_E"] && !nb++) bad = v }
    END { if (!nb) printf "ok"; else printf "a call received [%s]", bad }' "$GCH/shim.log"
}
_gc_shim_starts() {
  [ -s "$GCH/shim.log" ] || { printf 'no git call was recorded'; return 0; }
  GC_E="$1" LC_ALL=C awk -F'\t' '
    { v = $5; for (i = 6; i <= NF; i++) v = v "\t" $i
      if (index(v, ENVIRON["GC_E"]) != 1 && !nb++) bad = v }
    END { if (!nb) printf "ok"; else printf "a call received [%s]", bad }' "$GCH/shim.log"
}
_gc_shim_fields() {   # <rc|-> <count|-> <key0|-> <value0|->
  [ -s "$GCH/shim.log" ] || { printf 'no git call was recorded'; return 0; }
  GC_R="$1" GC_C="$2" GC_K="$3" GC_V="$4" LC_ALL=C awk -F'\t' '
    { if ((ENVIRON["GC_R"] != "-" && $1 != ENVIRON["GC_R"]) \
       || (ENVIRON["GC_C"] != "-" && $2 != ENVIRON["GC_C"]) \
       || (ENVIRON["GC_K"] != "-" && $3 != ENVIRON["GC_K"]) \
       || (ENVIRON["GC_V"] != "-" && $4 != ENVIRON["GC_V"])) { if (!nb++) bad = $1 " " $2 " " $3 " " $4 } }
    END { if (!nb) printf "ok"; else printf "a call had status, count, key and value [%s]", bad }' "$GCH/shim.log"
}

# ---- the secret-scan repository: a branch that adds a credential, committed,
# so the only way to see it is the diff. The key is assembled, so this file
# carries no credential's shape.
GCS="$GCH/scan"
_gc_key="$(printf '%s%s' AKIA Q7XK2M9PLR4TWN3B)"
_gcg init -q -b main "$GCS"
printf 'notes\n' > "$GCS/README.md"
_gcg -C "$GCS" add README.md && _gcg -C "$GCS" commit -qm base
_gcg -C "$GCS" checkout -q -b leak
printf 'aws_key = "%s"\n' "$_gc_key" > "$GCS/cfg.py"
_gcg -C "$GCS" add cfg.py && _gcg -C "$GCS" commit -qm leak
_gc_ss="$FROOT/harness/bin/secret-scan"
# stderr, then rc=N. Arguments are environment assignments for the run.
_gc_scan() { ( cd "$GCS" || exit 1; _gc_run env "$@" "$_gc_ss" main 2>&1 >/dev/null; printf 'rc=%s' "$?" ); }
_gc_shimscan() { : > "$GCH/shim.log"; _gc_scan PATH="$GCH/shim:$PATH" "$@"; }
_gc_found() {   # found, when the scan exited 1 and named the credential
  case "$1" in
    *"$_gc_key"*rc=1) printf found ;;
    *) printf '%s' "$1" | tail -1 ;;
  esac
}
_gc_rawdiff() { ( cd "$GCS" || exit 1; _gc_run env "$@" "$_gc_realgit" diff main...HEAD 2>/dev/null ); }

is "colour fixture: with no colour configuration, bin/secret-scan finds the credential the branch adds" \
   "$(_gc_found "$(_gc_scan)")" "found"
is "colour fixture: raw git diff in that repository writes no escape byte while nothing turns colour on" \
   "$(_gc_hasesc "$(_gc_rawdiff)")" "no"
_gc_colour "$GCS" on
is "colour fixture: raw git diff in a repository whose own config sets color.ui and every family key to always writes an escape byte into a pipe" \
   "$(_gc_hasesc "$(_gc_rawdiff)")" "yes"
# P1, and P2's repository config.
is "with colour forced on by the repository's own config, bin/secret-scan still finds a credential the branch adds, exits 1 and names it" \
   "$(_gc_found "$(_gc_scan)")" "found"
_gc_colour "$GCS" off

# ---- P2: every other source, each alone, each with its raw-git control.
printf '[color]\n\tui = always\n\tdiff = always\n' > "$GCH/hcolour/.gitconfig"
is "colour fixture: raw git diff with HOME at a global config that sets color.ui and color.diff to always writes an escape byte" \
   "$(_gc_hasesc "$(_gc_rawdiff HOME="$GCH/hcolour" XDG_CONFIG_HOME="$GCH/hcolour/.config")")" "yes"
is "colour forced on by the person's global config is overridden: bin/secret-scan still finds the credential" \
   "$(_gc_found "$(_gc_scan HOME="$GCH/hcolour" XDG_CONFIG_HOME="$GCH/hcolour/.config")")" "found"
is "colour fixture: raw git diff under a caller's GIT_CONFIG_COUNT entry for color.ui=always writes an escape byte" \
   "$(_gc_hasesc "$(_gc_rawdiff GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=always)")" "yes"
is "colour forced on by a caller's GIT_CONFIG_COUNT entry is overridden: bin/secret-scan still finds the credential" \
   "$(_gc_found "$(_gc_scan GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=always)")" "found"
is "colour fixture: raw git diff under a caller's old-format GIT_CONFIG_PARAMETERS entry 'color.ui=always' writes an escape byte" \
   "$(_gc_hasesc "$(_gc_rawdiff GIT_CONFIG_PARAMETERS="'color.ui=always'")")" "yes"
is "colour forced on by a caller's old-format GIT_CONFIG_PARAMETERS entry is overridden: bin/secret-scan still finds the credential" \
   "$(_gc_found "$(_gc_scan GIT_CONFIG_PARAMETERS="'color.ui=always'")")" "found"
is "colour fixture: raw git diff under a caller's new-format GIT_CONFIG_PARAMETERS entry 'color.diff'='always' writes an escape byte" \
   "$(_gc_hasesc "$(_gc_rawdiff GIT_CONFIG_PARAMETERS="'color.diff'='always'")")" "yes"
is "colour forced on by a caller's new-format GIT_CONFIG_PARAMETERS entry for a family key is overridden: bin/secret-scan still finds the credential" \
   "$(_gc_found "$(_gc_scan GIT_CONFIG_PARAMETERS="'color.diff'='always'")")" "found"

# ---- P6 for bin/secret-scan, then P3, P4 and P5 as git receives them.
_gc_shimscan >/dev/null
is "bin/secret-scan started with no GIT_CONFIG_PARAMETERS calls git with exactly the thirteen colour entries, every time" \
   "$(_gc_shim_is "$_gc_pin")" "ok"

_gc_o="$(_gc_shimscan GIT_CONFIG_PARAMETERS="'gcfix.p=1'")"
is "a caller's old-format GIT_CONFIG_PARAMETERS entry still reaches every git call bin/secret-scan makes, first" \
   "$(_gc_shim_starts "'gcfix.p=1'")" "ok"
is "and the thirteen colour entries follow it after one space" \
   "$(_gc_shim_is "'gcfix.p=1' $_gc_pin")" "ok"
is "and git accepts the result as it accepted the caller's value: bin/secret-scan still finds the credential" \
   "$(_gc_found "$_gc_o")" "found"
_gc_o="$(_gc_shimscan GIT_CONFIG_PARAMETERS="'gcfix.p'='1'")"
is "a caller's new-format GIT_CONFIG_PARAMETERS entry still reaches every git call bin/secret-scan makes, first" \
   "$(_gc_shim_starts "'gcfix.p'='1'")" "ok"
is "and the thirteen old-format colour entries follow it after one space" \
   "$(_gc_shim_is "'gcfix.p'='1' $_gc_pin")" "ok"
is "and git accepts that mix: bin/secret-scan still finds the credential" \
   "$(_gc_found "$_gc_o")" "found"
_gc_o="$(_gc_shimscan GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=gcfix.c GIT_CONFIG_VALUE_0=1)"
is "a caller's GIT_CONFIG_COUNT, its key and its value reach every git call bin/secret-scan makes unchanged" \
   "$(_gc_shim_fields - 1 gcfix.c 1)" "ok"
is "and beside it GIT_CONFIG_PARAMETERS is exactly the thirteen colour entries" \
   "$(_gc_shim_is "$_gc_pin")" "ok"
is "and git accepts both: bin/secret-scan still finds the credential" \
   "$(_gc_found "$_gc_o")" "found"

# P4. Idempotent across nesting, by the whole-entry suffix and nothing looser.
_gc_shimscan GIT_CONFIG_PARAMETERS="$_gc_pin" >/dev/null
is "a GIT_CONFIG_PARAMETERS that is exactly the thirteen colour entries reaches git unchanged, not doubled" \
   "$(_gc_shim_is "$_gc_pin")" "ok"
_gc_shimscan GIT_CONFIG_PARAMETERS="'gcfix.p=1' $_gc_pin" >/dev/null
is "one that ends in the thirteen colour entries after a caller's own entry reaches git unchanged" \
   "$(_gc_shim_is "'gcfix.p=1' $_gc_pin")" "ok"
_gc_shimscan GIT_CONFIG_PARAMETERS="$_gc_pin 'gcfix.p=1'" >/dev/null
is "one that holds the thirteen colour entries earlier but ends in another entry gets them appended again" \
   "$(_gc_shim_is "$_gc_pin 'gcfix.p=1' $_gc_pin")" "ok"
_gc_shimscan GIT_CONFIG_PARAMETERS="'color.pager=false' 'blame.coloring=none'" >/dev/null
is "one that ends in only the last two of the colour entries gets all thirteen appended" \
   "$(_gc_shim_is "'color.pager=false' 'blame.coloring=none' $_gc_pin")" "ok"
# Text that ends like the thirteen but not as whole entries: here the first of
# them is the quoted value of a new-format key, so git reads color.ui=never as
# gcfix.p's value and not as color.ui at all.
_gc_shimscan GIT_CONFIG_PARAMETERS="'gcfix.p'=$_gc_pin" >/dev/null
is "one whose text ends like the thirteen colour entries, but not as whole entries, gets them appended" \
   "$(_gc_shim_is "'gcfix.p'=$_gc_pin $_gc_pin")" "ok"

# P5. Judged the way git judges it, measured against raw git with the same value.
_gc_o="$(_gc_shimscan GIT_CONFIG_PARAMETERS=)"
is "an empty GIT_CONFIG_PARAMETERS becomes exactly the thirteen colour entries" \
   "$(_gc_shim_is "$_gc_pin")" "ok"
is "and git accepts it as it accepted the empty value: bin/secret-scan still finds the credential" \
   "$(_gc_found "$_gc_o")" "found"
_gc_rawrc() { _gc_run env "$@" "$_gc_realgit" -C "$GCS" rev-parse --verify HEAD >/dev/null 2>&1; printf '%s' "$?"; }
_gc_r="$(_gc_rawrc GIT_CONFIG_PARAMETERS=gcfix.p=1)"
_gc_shimscan GIT_CONFIG_PARAMETERS=gcfix.p=1 >/dev/null
is "a GIT_CONFIG_PARAMETERS git refuses, an unquoted entry, is refused by raw git and still by every git call bin/secret-scan makes, with the same status" \
   "$_gc_r $(_gc_shim_fields "$_gc_r" - - -)" "128 ok"
_gc_r="$(_gc_rawrc GIT_CONFIG_PARAMETERS=' ')"
_gc_shimscan GIT_CONFIG_PARAMETERS=' ' >/dev/null
is "one that is a single space is refused by raw git and still by every git call bin/secret-scan makes, with the same status" \
   "$_gc_r $(_gc_shim_fields "$_gc_r" - - -)" "128 ok"
_gc_r="$(_gc_rawrc GIT_CONFIG_COUNT=x)"
_gc_shimscan GIT_CONFIG_COUNT=x >/dev/null
is "a bogus GIT_CONFIG_COUNT is refused by raw git and still by every git call bin/secret-scan makes, with the same status and the count untouched" \
   "$_gc_r $(_gc_shim_fields "$_gc_r" x - -)" "128 ok"

# ---- the governed project: a risk table with a confined row and the
# destructive-SQL content row, and a gate.sh that writes down what git prints.
GCPD="$FROOT/projects/gcolour"
mkdir -p "$GCPD" "$MEM/gcolour"
printf '{\n  "name": "gcolour",\n  "gate": "gate.sh"\n}\n' > "$GCPD/project.json"
printf '# gcolour\n' > "$GCPD/CLAUDE.md"
{ printf 'red\tpath\t(^|/)(migrations|alembic)(/|$)\tschema migration\n'
  printf 'red\tcontent\t^\\+.*(DROP TABLE|TRUNCATE |DELETE FROM [^W]*$)\tdestructive SQL\n'
  printf 'yellow\tpath\t^deps(-extra)?\\.txt$\tdependency floor\tgc-confined\t^[-+][a-z]+>=[0-9.]+$\n'
  printf 'green\tpath\t\\.md$\tdocumentation\n'
} > "$GCPD/risk.tsv"
cat > "$GCPD/gate.sh" <<EOF
#!/bin/sh
{
  printf 'env=%s\n' "\${GIT_CONFIG_PARAMETERS-(unset)}"
  printf 'count=%s\n' "\${GIT_CONFIG_COUNT-(unset)}"
  printf 'log='; git log --oneline -1
  git diff HEAD~1 HEAD
  printf 'grep='; git grep -l gcolour-word
  printf 'status='; git status --short
  printf 'p=%s\n' "\$(git config --get gcfix.p)"
  printf 'c=%s\n' "\$(git config --get gcfix.c)"
} > "$GCH/gate.out" 2>&1
printf 'gcolour-gate-ran\n'
EOF
chmod +x "$GCPD/gate.sh"

# The receipt repository, one branch: deps.txt changed inside the confine (the
# same package, a new floor), deps-extra.txt given a line the confine does not
# allow, and a migration that adds DROP TABLE. One risk row covers both deps
# files, so its escape is judged per path: quiet on the first, firing on the
# second. README.md is edited and left unstaged, so the tree is dirty and its
# fingerprint hashes a diff.
GCW="$GCH/work"
_gcg init -q -b main "$GCW"
printf 'gcolour\n' > "$GCW/.felix"
printf 'notes\n' > "$GCW/README.md"
printf 'alpha>=1.0\nbeta>=2.0\n' > "$GCW/deps.txt"
printf 'gamma>=1.0\n' > "$GCW/deps-extra.txt"
_gcg -C "$GCW" add -A && _gcg -C "$GCW" commit -qm base
_gcg -C "$GCW" checkout -q -b mix
printf 'alpha>=1.1\nbeta>=2.0\n' > "$GCW/deps.txt"
printf 'gamma>=1.0\n--index-url http://example.invalid/simple\n' > "$GCW/deps-extra.txt"
mkdir -p "$GCW/migrations"; printf 'DROP TABLE accounts;\n' > "$GCW/migrations/004_drop.sql"
_gcg -C "$GCW" add -A && _gcg -C "$GCW" commit -qm mix
printf 'more notes\n' >> "$GCW/README.md"
_gc_receipt() { ( cd "$GCW" || exit 1; _gc_run env "$@" "$FELIX" receipt --base main 2>/dev/null ); }
_gc_classify() { ( cd "$GCW" || exit 1; _gc_run "$FELIX" classify --base main 2>/dev/null ); }
_gc_verdict() {   # receipt -> "<durable added-lines> <row on the confined change> <row on the other>"
  case "$1" in *'{"channel":"durable","path":"ADDED-LINES"'*) printf 'sql-escapes ' ;; *) printf 'sql-quiet ' ;; esac
  case "$1" in *'{"channel":"gc-confined","path":"deps.txt"'*) printf 'confined-fires ' ;; *) printf 'confined-quiet ' ;; esac
  case "$1" in *'{"channel":"gc-confined","path":"deps-extra.txt"'*) printf 'outside-fires' ;; *) printf 'outside-quiet' ;; esac
}
_gc_tree() { printf '%s\n' "$1" | sed -n '/"subject"/s/.*"tree": "\([^"]*\)".*/\1/p'; }
_gc_cl() { case "$1" in *"ADDED-LINES"*"destructive SQL"*) printf 'content-rule' ;; *) printf 'no-content-rule' ;; esac; }

# The uncoloured receipt runs with the shim on PATH, which changes nothing it
# prints, and doubles as P4 through a real nesting: felix receipt runs
# bin/secret-scan as a child for the disclose channel, so that child starts
# with a value felix already pinned. Its calls are the ones without -C: felix's
# own diff calls name the repository with -C, and secret-scan reads its working
# directory. Flags it may gain (--no-color, --no-pager) are allowed for.
# 2026-10-18, judge refs: felix receipt hands its base on by full name, so the
# child's diff names refs/heads/main...HEAD here, where the fixture has no origin.
_gc_scanran() {   # ran, when some recorded call is a diff of main...HEAD with no -C before the diff
  LC_ALL=C awk '{ for (i = 1; i <= NF; i++) { if ($i == "-C") next; if ($i == "diff") break }
                  if (i > NF) next
                  for (j = i + 1; j <= NF; j++) if ($j == "main...HEAD" || $j == "refs/heads/main...HEAD") { n++; next } }
                END { if (n) printf "ran"; else printf "no call of its was recorded" }' "$GCH/shim.args"
}
: > "$GCH/shim.log"; : > "$GCH/shim.args"
_gc_rp="$(_gc_receipt PATH="$GCH/shim:$PATH")"; _gc_cp="$(_gc_classify)"
is "colour fixture: with no colour configuration, felix receipt escapes the migration's DROP TABLE as durable ADDED-LINES and fires the confine row only on the change outside it" \
   "$(_gc_verdict "$_gc_rp")" "sql-escapes confined-quiet outside-fires"
is "colour fixture: with no colour configuration, felix classify reports the destructive-SQL content rule on the added lines" \
   "$(_gc_cl "$_gc_cp")" "content-rule"
_gc_t0="$(_gc_tree "$_gc_rp")"
is "colour fixture: felix receipt names a tree fingerprint for the dirty tree" \
   "$([ -n "$_gc_t0" ] && printf named)" "named"
is "colour fixture: felix receipt's secret-scan child ran under the shim" \
   "$(_gc_scanran)" "ran"
is "every git call under felix receipt started with no GIT_CONFIG_PARAMETERS, its secret-scan child included, receives the thirteen colour entries exactly once" \
   "$(_gc_shim_is "$_gc_pin")" "ok"
_gc_colour "$GCW" on
is "colour fixture: raw git diff in the receipt repository, with its own config forcing colour, writes an escape byte" \
   "$(_gc_hasesc "$( cd "$GCW" || exit 1; _gc_run "$_gc_realgit" diff -U0 main...HEAD 2>/dev/null )")" "yes"
_gc_rc="$(_gc_receipt)"; _gc_cc="$(_gc_classify)"
_gc_v="$(_gc_verdict "$_gc_rc")"
is "with colour forced on by the repository's own config, felix receipt still escapes destructive SQL added in a migration as durable ADDED-LINES" \
   "$(printf '%s' "$_gc_v" | cut -d' ' -f1)" "sql-escapes"
# Read with the other path's verdict beside it, so a receipt that printed
# nothing (which also reads as quiet) cannot pass this.
is "with colour forced on by the repository's own config, a change the risk row's confine allows still leaves that row's escape quiet in felix receipt" \
   "$(printf '%s' "$_gc_v" | cut -d' ' -f2,3)" "confined-quiet outside-fires"
is "with colour forced on by the repository's own config, a change outside the confine still fires the risk row's escape in felix receipt" \
   "$(printf '%s' "$_gc_v" | cut -d' ' -f3)" "outside-fires"
is "with colour forced on by the repository's own config, felix classify still sees the destructive-SQL content rule in the added lines" \
   "$(_gc_cl "$_gc_cc")" "content-rule"
is "with colour forced on by the repository's own config, felix receipt names the same tree fingerprint for a dirty tree as with none" \
   "$(_gc_tree "$_gc_rc")" "$_gc_t0"
_gc_colour "$GCW" off

# ---- handoff and gate, in a repository whose only change is an untracked file.
GCD="$GCH/hand"
_gcg init -q -b main "$GCD"
printf 'gcolour\n' > "$GCD/.felix"
printf 'one gcolour-word\n' > "$GCD/notes.txt"
_gcg -C "$GCD" add -A && _gcg -C "$GCD" commit -qm first
printf 'two\n' >> "$GCD/notes.txt"
_gcg -C "$GCD" add -A && _gcg -C "$GCD" commit -qm second
printf 'scratch\n' > "$GCD/untracked.txt"
_gc_hf="$MEM/gcolour/SESSION_HANDOFF.md"
_gc_handoff() { ( cd "$GCD" || exit 1; _gc_run "$FELIX" handoff 2>&1 ); }
_gc_ublock() { sed -n '/^## Uncommitted/,/^## Recent/p' "$_gc_hf" 2>/dev/null; }
rm -f "$_gc_hf"
has "colour fixture: with no colour configuration, felix handoff on a tree whose only change is untracked prints that the tree is clean" \
    "$(_gc_handoff)" "[x] tree is clean"
# What the Uncommitted block says for this tree is read here, uncoloured, and
# the coloured run below is held to it, so the check does not depend on the
# block's wording.
_gc_ub0="$(_gc_ublock)"
is "colour fixture: with no colour configuration, the SESSION_HANDOFF.md felix handoff writes has an Uncommitted block that does not list the untracked file" \
   "$([ -n "$_gc_ub0" ] && printf written) $(case "$_gc_ub0" in (*untracked.txt*) printf lists ;; (*) printf unlisted ;; esac)" "written unlisted"
_gc_colour "$GCD" on
is "colour fixture: raw git status --short on that tree, with its own config forcing colour, writes an escape byte" \
   "$(_gc_hasesc "$(_gc_run "$_gc_realgit" -C "$GCD" status --short 2>/dev/null)")" "yes"
rm -f "$_gc_hf"
has "with colour forced on by the repository's own config, felix handoff on a tree whose only change is untracked still prints that the tree is clean" \
    "$(_gc_handoff)" "[x] tree is clean"
is "and the SESSION_HANDOFF.md it writes holds no escape byte" \
   "$(_gc_hasesc "$(cat "$_gc_hf" 2>/dev/null)")$([ -s "$_gc_hf" ] && printf ' written')" "no written"
_gc_ub="$(_gc_ublock)"
is "and its Uncommitted block reads exactly as it does with no colour configuration, without the untracked file" \
   "${_gc_ub:-(no block)}" "$_gc_ub0"

is "colour fixture: raw git log --oneline in that repository, with its own config forcing colour, writes an escape byte" \
   "$(_gc_hasesc "$(_gc_run "$_gc_realgit" -C "$GCD" log --oneline -1 2>/dev/null)")" "yes"
: > "$GCH/gate.out"
_gc_go="$( cd "$GCD" || exit 1; _gc_run "$FELIX" gate 2>&1 )"
is "colour fixture: felix gate ran the project's gate.sh, which wrote the commit line and the grep match" \
   "$(case "$_gc_go" in (*gcolour-gate-ran*) printf ran ;; esac) $(sed "s/${_gc_esc}\[[0-9;]*m//g" "$GCH/gate.out" | sed -n 's/^log=[^ ]* //p; s/^grep=//p' | tr '\n' ' ')" \
   "ran second notes.txt "
# With the count of commit lines beside it, so an empty file (the gate never
# ran) cannot read as colour-free.
is "with colour forced on by the repository's own config, a project's gate.sh under felix gate reads git log, diff, grep and status with no escape byte" \
   "$(_gc_hasesc "$(cat "$GCH/gate.out")") $(grep -c '^log=' "$GCH/gate.out")" "no 1"
# P6 for felix, through the child it starts.
is "felix started with no GIT_CONFIG_PARAMETERS hands its gate child exactly the thirteen colour entries" \
   "$(sed -n 's/^env=//p' "$GCH/gate.out")" "$_gc_pin"
_gc_colour "$GCD" off
# P3 through felix and a child of it: a non-colour key from each caller channel
# still reaches git, and GIT_CONFIG_COUNT arrives as the caller set it.
: > "$GCH/gate.out"
( cd "$GCD" || exit 1
  _gc_run env GIT_CONFIG_PARAMETERS="'gcfix.p=yes'" GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=gcfix.c GIT_CONFIG_VALUE_0=yes \
    "$FELIX" gate >/dev/null 2>&1 )
is "a project's gate.sh under felix gate still reads a non-colour key from the caller's GIT_CONFIG_PARAMETERS and one from the caller's GIT_CONFIG_COUNT, which arrives unchanged" \
   "$(sed -n 's/^p=/p=/p; s/^c=/c=/p; s/^count=/count=/p' "$GCH/gate.out" | tr '\n' ' ')" "count=1 p=yes c=yes "
is "and it sees the caller's GIT_CONFIG_PARAMETERS with the thirteen colour entries appended after one space" \
   "$(sed -n 's/^env=//p' "$GCH/gate.out")" "'gcfix.p=yes' $_gc_pin"
# The same for the new format: git still reads the caller's key, not only
# accepts the value.
: > "$GCH/gate.out"
( cd "$GCD" || exit 1
  _gc_run env GIT_CONFIG_PARAMETERS="'gcfix.p'='newform'" "$FELIX" gate >/dev/null 2>&1 )
is "a project's gate.sh under felix gate still reads a non-colour key from the caller's new-format GIT_CONFIG_PARAMETERS entry" \
   "$(sed -n 's/^p=/p=/p' "$GCH/gate.out")" "p=newform"

# ---- a hook, and tests/red, each started with nothing set.
: > "$GCH/shim.log"
( cd "$GCD" || exit 1
  _gc_run env PATH="$GCH/shim:$PATH" CLAUDE_PLUGIN_ROOT="$FROOT" "$FROOT/harness/hooks/session-start" </dev/null >/dev/null 2>&1 )
is "hooks/session-start started with no GIT_CONFIG_PARAMETERS calls git with exactly the thirteen colour entries, every time" \
   "$(_gc_shim_is "$_gc_pin")" "ok"
# The copy has the engine's lib beside it, as tests/red has in the tree, and no
# tests/run, so it cannot start a suite whatever happens.
cp "$FROOT/harness/tests/red" "$GCH/redcopy/tests/red" && chmod +x "$GCH/redcopy/tests/red"
cp -R "$FROOT/harness/lib" "$GCH/redcopy/lib"
: > "$GCH/shim.log"
( cd "$GCH" || exit 1; _gc_run env PATH="$GCH/refuse:$PATH" "$GCH/redcopy/tests/red" >/dev/null 2>&1; printf '%s' "$?" > "$GCH/red.rc" )
is "tests/red started with no GIT_CONFIG_PARAMETERS has exactly the thirteen colour entries on its first git call, and stops there when git refuses" \
   "$(_gc_shim_is "$_gc_pin") rc=$(cat "$GCH/red.rc" 2>/dev/null)" "ok rc=2"

# ---- P6 and P7, read from the text of every executable file, as each must
# carry its own pin. Where the pin is: from the first code line naming
# GIT_CONFIG_PARAMETERS or 'color.ui=never', to the last code line naming
# GIT_CONFIG_PARAMETERS before the file's first git command and within forty
# lines, then on until those lines parse. A line runs git when the word git
# follows the start, a blank, an operator or `$(`. Every test reads a line
# with its comment taken off, whole-line or trailing, so a dated comment on a
# pin line (which may name `git -c`, or a backtick) is not read as code.
# Read from REAL_HARNESS, the tree under test. Which files are executable is
# read from the suite's own copy of it, made by _copy_content, so a stray file
# git ignores (as .claude-flow/ was on 2026-09-19) is not counted, and no git
# runs here outside the fixture.
_gc_lines() {   # <file> -> "u s e g": unset line, pin start, pin end, first git; 0 when absent
  LC_ALL=C awk '
    /^[[:space:]]*#/ { next }
    { c = $0; sub(/[[:space:]]+#.*$/, "", c) }
    c ~ /^unset GREP_OPTIONS / && !u { u = NR }
    (c ~ /GIT_CONFIG_PARAMETERS/ || index(c, "'"'"'color.ui=never'"'"'")) && !s { s = NR }
    c ~ "(^|[^A-Za-z0-9_./-])git[[:space:]]" && !g { g = NR }
    c ~ /GIT_CONFIG_PARAMETERS/ { m[NR] = 1 }
    END {
      e = 0
      if (s) { lim = s + 40; if (g && g - 1 < lim) lim = g - 1
               for (i = s; i <= lim; i++) if (i in m) e = i }
      printf "%d %d %d %d\n", u, s, e, g }' "$1"
}
_gc_region() {   # <file> <out>: writes the pin's lines; fails when there is none that parses
  local u s e g k=0
  read -r u s e g <<<"$(_gc_lines "$1")"
  [ "${s:-0}" -gt 0 ] && [ "${e:-0}" -ge "${s:-0}" ] || return 1
  while [ "$k" -le 12 ]; do
    sed -n "${s},$((e + k))p" "$1" > "$2"
    bash -n "$2" 2>/dev/null && return 0
    k=$((k + 1))
  done
  return 1
}
_gc_exes=""
for _gc_f in $(cd "$FROOT/harness" && find . -type f -perm -u+x 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort); do
  _gc_exes="$_gc_exes $_gc_f"
done
is "the executable files read for the pin include felix, a hook, bin/secret-scan, tests/run and tests/red" \
   "$(for _gc_f in felix hooks/session-start bin/secret-scan tests/run tests/red; do
        case " $_gc_exes " in (*" $_gc_f "*) ;; (*) printf '%s ' "$_gc_f" ;; esac; done)" ""
# P7, run: each pin held to one process, with its own stderr kept. Any fork it
# tries (a subshell, a pipe, an external command) fails there, and bash says
# so on stderr, so a pin that tries one, or that needs one for its value, is
# caught whatever the value comes out as. Root ignores the limit, so there it
# is skipped rather than passed. bash retries a failed fork for about fifteen
# seconds, so the first pin that forks ends the run of this check.
_gc_nfskip=""; _gc_nfl=""; _gc_nfstop=""
_gc_nfrun() {   # <region> <stderr file> [VAR=value]: the region sourced in one process, then printenv exec'd
  env -u GIT_CONFIG_PARAMETERS ${3:+"$3"} bash -c 'set -u; ulimit -u 1 2>/dev/null || { printf "(unlimited)"; exit 0; }
    . "$1" >/dev/null 2>"$2"; exec printenv GIT_CONFIG_PARAMETERS' _ "$1" "$2" 2>/dev/null
}
# The method's own control, which forks nothing itself: held to one process,
# an empty region still hands a caller's value to the command it execs. Where
# that fails, the check is skipped rather than read as a fork.
if [ "${EUID:-0}" -eq 0 ]; then
  _gc_nfskip="root ignores the process limit"
else
  printf ':\n' > "$GCH/regions/empty.nofork"
  case "$(_gc_nfrun "$GCH/regions/empty.nofork" "$GCH/nofork.err" GIT_CONFIG_PARAMETERS=gcfix-probe)" in
    "(unlimited)") _gc_nfskip="processes cannot be limited here" ;;
    gcfix-probe) ;;
    *) _gc_nfskip="a process held to one cannot exec a command here" ;;
  esac
fi
_gc_order="" _gc_sem="" _gc_text=""
for _gc_f in $_gc_exes; do
  read -r _gc_u _gc_s _gc_e _gc_g <<<"$(_gc_lines "$REAL_HARNESS/$_gc_f")"
  if [ "${_gc_u:-0}" -gt 0 ] && [ "${_gc_s:-0}" -gt "${_gc_u:-0}" ] && [ "${_gc_e:-0}" -ge "${_gc_s:-0}" ]; then :
  else _gc_order="$_gc_order $_gc_f"; fi
  _gc_rf="$GCH/regions/$(printf '%s' "$_gc_f" | tr '/' '_').sh"
  if ! _gc_region "$REAL_HARNESS/$_gc_f" "$_gc_rf"; then
    _gc_sem="$_gc_sem $_gc_f(none)"; _gc_text="$_gc_text $_gc_f(none)"; _gc_nfl="$_gc_nfl $_gc_f(none)"; continue
  fi
  _gc_a="$(env -u GIT_CONFIG_PARAMETERS bash -c 'set -u; . "$1" >/dev/null 2>&1; exec printenv GIT_CONFIG_PARAMETERS' _ "$_gc_rf" 2>/dev/null)"
  _gc_b="$(env GIT_CONFIG_PARAMETERS="'gcfix.p=1'" bash -c 'set -u; . "$1" >/dev/null 2>&1; exec printenv GIT_CONFIG_PARAMETERS' _ "$_gc_rf" 2>/dev/null)"
  _gc_c="$(env GIT_CONFIG_PARAMETERS="$_gc_pin" bash -c 'set -u; . "$1" >/dev/null 2>&1; exec printenv GIT_CONFIG_PARAMETERS' _ "$_gc_rf" 2>/dev/null)"
  [ "$_gc_a" = "$_gc_pin" ] && [ "$_gc_b" = "'gcfix.p=1' $_gc_pin" ] && [ "$_gc_c" = "$_gc_pin" ] \
    || _gc_sem="$_gc_sem $_gc_f"
  # Code only: whole-line and trailing comments off, as above.
  _gc_t="$(LC_ALL=C sed -e '/^[[:space:]]*#/d' -e 's/[[:space:]][[:space:]]*#.*$//' "$_gc_rf")"
  case "$_gc_t" in *'$('*|*'`'*|*'<('*|*'>('*) _gc_text="$_gc_text $_gc_f" ;; esac
  if [ -z "$_gc_nfskip" ] && [ -z "$_gc_nfstop" ]; then
    : > "$GCH/nofork.err"
    _gc_nf="$(_gc_nfrun "$_gc_rf" "$GCH/nofork.err")"
    if [ "$_gc_nf" = "(unlimited)" ]; then
      _gc_nfskip="processes cannot be limited here"
    elif [ "$_gc_nf" != "$_gc_a" ] || grep -qi 'fork' "$GCH/nofork.err"; then
      _gc_nfl="$_gc_nfl $_gc_f"; _gc_nfstop=1
    fi
  fi
done
is "every executable file under engine/harness pins git colour after its caller-environment unset line and before its first git command" \
   "$_gc_order" ""
is "each executable file's pin, run on its own, exports exactly the thirteen colour entries, appends them to a caller's entry and leaves a value already ending in them alone" \
   "$_gc_sem" ""
is "every executable file has a pin, and no line of any of them holds a command substitution, a process substitution or a backtick" \
   "$_gc_text" ""
if [ -n "$_gc_nfskip" ]; then
  skip "every executable file's pin, held to one process, exports what it exports unheld and tries no fork" "$_gc_nfskip"
else
  is "every executable file's pin, held to one process, exports what it exports unheld and tries no fork" \
     "$_gc_nfl" ""
fi

# ---- Added after the adversarial review, 2026-10-08, and not blind. The
# review found two colour sources the contract's eleven entries missed, and
# the pin grew to thirteen for them:
# - GIT_PAGER_IN_USE. git exports it to whatever it starts beside a pager.
#   Plumbing (`diff-tree -p`) reads no family key, so under it plumbing
#   coloured a pipe until color.pager=false.
# - blame.coloring, the one documented colour switch outside color.*.
# Each is held here by behaviour, through a project's gate under felix gate,
# with its raw-git control beside it. A pin without either entry reds its
# row. Above this line, what changed from what was written blind is _gc_pin,
# the word thirteen in names and comments that count entries, a pointer to
# this section in the block's opening comment, and the partial-suffix case
# (now the pin's actual last two entries).
_gcg config --file "$GCD/.git/config" blame.coloring highlightRecent
cat > "$GCPD/gate.sh" <<EOF
#!/bin/sh
e="\$(printf '\\033')"
{ printf 'plumb='; git diff-tree -p HEAD | grep -c "\$e"
  printf 'blame='; git blame notes.txt | grep -c "\$e"; } > "$GCH/gate2.out" 2>&1
echo gcolour-gate2-ran
EOF
chmod +x "$GCPD/gate.sh"
is "colour fixture: raw git diff-tree -p with GIT_PAGER_IN_USE set and a colour terminal writes an escape byte, with no colour configuration at all" \
   "$(_gc_hasesc "$(_gc_run env GIT_PAGER_IN_USE=true TERM=xterm-256color "$_gc_realgit" -C "$GCD" diff-tree -p HEAD 2>/dev/null)")" "yes"
is "colour fixture: raw git blame in a repository whose own config sets blame.coloring=highlightRecent writes an escape byte" \
   "$(_gc_hasesc "$(_gc_run "$_gc_realgit" -C "$GCD" blame notes.txt 2>/dev/null)")" "yes"
: > "$GCH/gate2.out"
_gc_go="$( cd "$GCD" || exit 1; _gc_run env GIT_PAGER_IN_USE=true TERM=xterm-256color "$FELIX" gate 2>&1 )"
is "a project's gate.sh under felix gate, started with GIT_PAGER_IN_USE set and a colour terminal, reads git diff-tree -p and git blame under blame.coloring=highlightRecent with no escape byte" \
   "$(case "$_gc_go" in (*gcolour-gate2-ran*) printf ran ;; esac) $(tr '\n' ' ' < "$GCH/gate2.out")" "ran plumb=0 blame=0 "
_gcg config --file "$GCD/.git/config" --unset blame.coloring

unset GCH GCT GCS GCW GCD GCPD _gc_esc _gc_pin _gc_realgit _gc_key _gc_ss _gc_o _gc_r _gc_rp _gc_cp _gc_rc _gc_cc \
      _gc_v _gc_t0 _gc_hf _gc_go _gc_exes _gc_f _gc_rf _gc_order _gc_sem _gc_text _gc_a _gc_b _gc_c _gc_t _gc_nf \
      _gc_u _gc_s _gc_e _gc_g _gc_ub0 _gc_ub _gc_nfskip _gc_nfl _gc_nfstop
unset -f _gc_run _gcg _gc_colour _gc_hasesc _gc_shim_is _gc_shim_starts _gc_shim_fields _gc_scan _gc_shimscan \
         _gc_found _gc_rawdiff _gc_rawrc _gc_receipt _gc_classify _gc_verdict _gc_tree _gc_cl _gc_handoff \
         _gc_lines _gc_region _gc_scanran _gc_ublock _gc_nfrun


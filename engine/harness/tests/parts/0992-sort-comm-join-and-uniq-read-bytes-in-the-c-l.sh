printf '\nsort, comm, join and uniq read bytes in the C locale\n'
# The engine runs in its caller's locale, and a macOS Terminal sets
# LANG=en_US.UTF-8, so `felix` run by a person, and every hook of a claude
# started from that Terminal, runs there; a desktop session's tool shell has
# no LANG and runs in C, which is why no session saw any of this. Measured
# 2026-10-08 on macOS 26, bash 3.2.57, /usr/bin/sort 2.3-Apple, at main
# 6fe5f986, two ways it goes wrong:
#
#   - comm compares in the locale's collation, and _felix_escape_shrank hands
#     it two sides _felix_escape_lines sorted in bytes. A row added to a deny
#     table that sorts before an existing row in bytes and after it in the
#     locale (Zulu and _under: en_US.UTF-8 puts punctuation first and folds
#     case) makes comm -23 print a line that was never removed, and a pure
#     addition reads as "the change removes from it", a founder stop.
#   - macOS sort in a UTF-8 locale prints nothing at all when one line is not
#     UTF-8, and says "Illegal byte sequence" on stderr. One Latin-1 byte in a
#     route's play routes no prompt; one in a declared capability makes every
#     detected capability read as undeclared. glibc sort keeps the line, so on
#     Linux the two assertions that measure this pass on the engine as it was
#     and cannot fail there.
#
# The rule they hold the engine to: in runtime code, every sort, comm, join and
# uniq is written `LC_ALL=C <tool>`, on the command itself. The locale is the
# en_US UTF-8 one this machine has, picked as the block above picks it; where
# none is installed, every assertion that needs it is skipped by name. C.UTF-8
# is no substitute: its collation is code-point order, which for valid UTF-8 is
# byte order, so the escape case cannot fail under it. Each locale is set in a
# subshell around the one call under test.
_locale_bytes_vars
# One call in a chosen locale: C, or `lang` (LANG set and every LC_ unset, as
# a Terminal has it), or `all` (LC_ALL set). Everything after the first word is
# run in a subshell, so the suite keeps its own locale.
_lcb_in() {  # C|lang|all <command...>
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}

# The escape fixture: a deny table at base holding rows whose order differs
# between bytes and en_US.UTF-8, and two branches off it. `add` appends Zulu
# and removes nothing; `rm` removes _under and adds nothing. felix_escapes runs
# on a project with no risk.tsv, so only the engine's own channels speak, and
# the channels it names for t/deny.tsv are what is read.
LCB_E="$TMP/lc-escape"; LCB_EP="$TMP/lc-escape-proj"; mkdir -p "$LCB_E" "$LCB_EP"
( _fx_cd "$LCB_E" && git init -q -b main && git config user.email t@t && git config user.name t \
  && mkdir t && for w in Zeta apple _under Beta-2 beta_1; do printf '%s\tstop\n' "$w"; done > t/deny.tsv \
  && git add -A && git commit -qm base \
  && git checkout -q -b add && printf 'Zulu\tstop\n' >> t/deny.tsv && git commit -qam add \
  && git checkout -q -b rm main && LC_ALL=C grep -v '^_under' t/deny.tsv > t/d && mv t/d t/deny.tsv \
  && git commit -qam rm ) >/dev/null 2>&1
LCB_E="$(cd "$LCB_E" && pwd -P)" || LCB_E="$TMP/lc-escape"
# Never a git command with an empty or missing -C: git then acts on the
# directory the suite was started from.
_lcb_esc() {  # <branch>: the channels felix_escapes names for t/deny.tsv, that branch against main
  [ -n "$LCB_E" ] && [ -d "$LCB_E/.git" ] || { printf 'no fixture'; return 0; }
  _fx_git "$LCB_E" checkout -q "$1" >/dev/null 2>&1
  ( cd "$LCB_E" && . "$FROOT/harness/lib/escape.sh"; . "$FROOT/harness/lib/obligations.sh"
    felix_escapes "$LCB_EP" main "$LCB_E" ) </dev/null 2>/dev/null \
    | awk -F'\t' '$2 == "t/deny.tsv" { printf "%s%s", s, $1; s = " " }'
}
is  "the locale escape fixture's add branch adds one row to t/deny.tsv and removes none, its rm branch removes one and adds none, and in C the addition is no escape" \
    "$(git -C "$LCB_E" diff --numstat main add 2>/dev/null | tr '\t' ' ')|$(git -C "$LCB_E" diff --numstat main rm 2>/dev/null | tr '\t' ' ')|$(_lcb_in C _lcb_esc add)" \
    "1 0 t/deny.tsv|0 1 t/deny.tsv|"
LCB_A1="in a UTF-8 locale with LANG set and LC_ALL unset, a row added to a deny table and none removed is not a verifier escape"
LCB_A2="and with LC_ALL set to that locale, the same pure addition is not a verifier escape either"
LCB_A0="the added row Zulu sorts before _under in bytes and after it in the UTF-8 locale, so the escape fixture can fail"
if [ -n "$LCB_U8" ]; then
    # A control on the fixture and the host, not on the engine.
  is  "$LCB_A0" "$(printf 'Zulu\n_under\n' | LC_ALL=C sort | head -1)|$(printf 'Zulu\n_under\n' | LC_ALL="$LCB_U8" sort | head -1)" "Zulu|_under"
  is  "$LCB_A1" "$(_lcb_in lang _lcb_esc add)" ""
  is  "$LCB_A2" "$(_lcb_in all _lcb_esc add)" ""
else
  for a in "$LCB_A0" "$LCB_A1" "$LCB_A2"; do skip "$a" "$LCB_NONE"; done
fi
# Failing closed is what the escape check is for, so a real removal from the
# same table, with the collation-sensitive rows around it, still escapes in
# both locales. This one holds on the engine as it was and pins that the
# locale fix does not buy the addition by losing the removal.
is  "in C, removing a row from a deny table is still a verifier escape" "$(_lcb_in C _lcb_esc rm)" "verifier"
if [ -n "$LCB_U8" ]; then
  is  "and in the UTF-8 locale the same removal is still a verifier escape" "$(_lcb_in lang _lcb_esc rm)" "verifier"
else
  skip "and in the UTF-8 locale the same removal is still a verifier escape" "$LCB_NONE"
fi

# Route choice. Two routes; the prompt names three of backend's keywords, and
# the other route's play holds a Latin-1 e-acute (\351), which is not UTF-8.
# Its keywords column is plain on purpose: felix_route_score prints the play
# and not the keywords, so only a byte in the play reaches the sort.
LCB_R="$TMP/lc-route-proj"; mkdir -p "$LCB_R"
{ printf 'backend\tmigration schema endpoint\tcore\tread the schema first\n'
  printf 'notes\tmenu\tcore\twrite the caf\351 menu down\n'; } > "$LCB_R/routes.tsv"
_lcb_route() {  # the chosen route's score and name, and the status
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/route.sh"
    felix_route_best "$LCB_R" 'add a migration for the endpoint schema' '' | LC_ALL=C cut -f1,5 | LC_ALL=C tr '\t\n' '  '
    printf 'rc=%s' "${PIPESTATUS[0]}" ) </dev/null 2>/dev/null
}
# The line felix_route_best picks is then read again by cut, which in BSD's
# UTF-8 build fails on the whole line ("Illegal byte sequence"), so a second
# fixture puts the byte in the play of the route that wins (found by the
# session sweeping the other text tools, 2026-10-08). Sort order itself cannot
# hand the pick to the locale: the fourth key is the row's position, which no
# two rows share, so no tie reaches the whole line.
LCB_R2="$TMP/lc-route-proj-win"; mkdir -p "$LCB_R2"
{ printf 'backend\tmigration schema endpoint\tcore\tread the caf\351 schema first\n'
  printf 'notes\tmenu\tcore\twrite it down\n'; } > "$LCB_R2/routes.tsv"
# The two C lines are controls on the fixtures, not on the engine: they show
# each fixture picks backend at all, so the UTF-8 lines can only fail for the
# locale.
is  "in C, the locale route fixture picks backend at 6" "$(_lcb_in C _lcb_route)" "6 backend rc=0"
is  "in C, the fixture whose winning play holds the byte picks backend at 6 too" "$(LCB_R="$LCB_R2" _lcb_in C _lcb_route)" "6 backend rc=0"
LCB_C1="in a UTF-8 locale, a route whose play holds a byte that is not UTF-8 leaves felix_route_best picking what it picks in C"
LCB_C2="and when that byte is in the winning route's own play, felix_route_best still picks it"
if [ -n "$LCB_U8" ]; then
  is  "$LCB_C1" "$(_lcb_in all _lcb_route)" "6 backend rc=0"
  is  "$LCB_C2" "$(LCB_R="$LCB_R2" _lcb_in all _lcb_route)" "6 backend rc=0"
else
  skip "$LCB_C1" "$LCB_NONE"; skip "$LCB_C2" "$LCB_NONE"
fi
[ -n "$LCB_U8" ] && [ "$LCB_DROPS" -eq 0 ] \
  && printf '        (sort here keeps a line it cannot decode, so the route and capability cases cannot fail on this host)\n'

# Undeclared capabilities. A checkout outside any repository with a workflow,
# a Dockerfile and a tests directory detects ci, deploy and tests; the project
# declares ci, one name holding the same Latin-1 byte, and Zeta. felix_undeclared
# compares two sorted lists, so one side emptied by sort reads every detected
# name as undeclared. Zeta sorts before ci in bytes and after it in the locale,
# so a comm left in the locale over sides sorted in C also misreads ci, and
# does so on glibc too, where the byte alone changes nothing (added after
# review: without it, unpinning only that comm failed nothing here).
LCB_D="$TMP/lc-detect"; LCB_DP="$TMP/lc-detect-proj"
mkdir -p "$LCB_D/.github/workflows" "$LCB_D/tests" "$LCB_DP"
printf 'on: push\n' > "$LCB_D/.github/workflows/ci.yml"; printf 'FROM scratch\n' > "$LCB_D/Dockerfile"
#
# Restated 2026-10-16, when claude/declared-not-text landed over this block:
# felix_declared now calls a list whose listed line holds a byte outside tab
# and printable ASCII no list, 2 with nothing printed, in every locale, so the
# Latin-1 name can no longer reach the comparison and felix_undeclared returns
# 2. The byte fixture asserts that, the same in C and UTF-8, and the ASCII one
# (ci and Zeta, no byte) keeps the collation case: Zeta sorts before ci in
# bytes and after it in the locale.
printf 'ci\ncaf\351\nZeta\n' > "$LCB_DP/capabilities"
LCB_DA="$TMP/lc-detect-proj-ascii"; mkdir -p "$LCB_DA"; printf 'ci\nZeta\n' > "$LCB_DA/capabilities"
_lcb_undecl() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/detect.sh"
    felix_undeclared "$LCB_D" "${LCB_P:-$LCB_DP}" | tr '\n' ' '; printf 'rc=%s' "${PIPESTATUS[0]}" ) </dev/null 2>/dev/null
}
is  "in C, the locale detect fixture's undeclared capabilities are deploy and tests" "$(LCB_P="$LCB_DA" _lcb_in C _lcb_undecl)" "deploy tests rc=0"
is  "in C, a declared capability holding a byte that is not ASCII makes the list unread, so felix_undeclared names nothing and returns 2" \
    "$(_lcb_in C _lcb_undecl)" "rc=2"
LCB_D1="in a UTF-8 locale, a declared capability holding a byte that is not UTF-8 leaves felix_undeclared naming exactly what it names in C"
LCB_D2="and in a UTF-8 locale the ASCII fixture's undeclared capabilities are deploy and tests, as in C"
if [ -n "$LCB_U8" ]; then
  is  "$LCB_D1" "$(_lcb_in all _lcb_undecl)" "rc=2"
  is  "$LCB_D2" "$(LCB_P="$LCB_DA" _lcb_in all _lcb_undecl)" "deploy tests rc=0"
else
  skip "$LCB_D1" "$LCB_NONE"; skip "$LCB_D2" "$LCB_NONE"
fi

# The lint. One matcher, _lcb_lint, called by the fixture checks and by the
# check over the real tree, so the real-tree check cannot pass by matching less
# than the fixtures prove it matches. A line is cut into segments at |, ;, &,
# (, ), {, } and the backtick, and each segment's leading words are read off
# until the command: the reserved words and wrappers that put a command after
# them (!, if, then, else, elif, do, while, until, time, eval, env, command,
# exec, nice, nohup, xargs, bash, sh, and a wrapper's -options), assignments,
# a redirection glued to its target, and an opening quote, which is how an awk
# pipe target ("sort"), eval "sort ..." and sh -c 'sort ...' are reached. The
# command counts as the tool by its last path component, with or without a
# leading backslash. A finding is a tool whose last word before it is not
# exactly `LC_ALL=C`, or one reached through env: `LANG=C sort`, `LC_COLLATE=C
# sort` and `env LC_ALL=C sort` are findings, because LANG and LC_COLLATE do
# not override a caller's LC_ALL and the rule names one spelling.
#
# Comment lines are not code. A name directly followed by `(` is an awk
# function call or a definition, never a command. A name that follows a word
# no list above holds is an argument, which is how lib/where-read.sh's awk
# split string stays out. A string that itself holds one of the separators
# right before a tool name reads as a finding, and so does a trailing comment;
# both err toward a finding, and stripping either would let a quote or a #
# inside a string hide a real call behind it.
#
# Still not seen, and checked by hand when the tree is: a wrapper option that
# takes an argument (`nice -n 5 sort`, `env -u X sort`), a redirection apart
# from its target (`> out sort`), and a command inside a heredoc fed to a shell.
_lcb_lint() {  # <prefix to strip> <file>...: file:line for each finding
  local pre="$1"; shift
  LC_ALL=C awk -v pre="$pre" '
    /^[[:space:]]*#/ { next }
    { line = $0; gsub(/(sort|comm|join|uniq)\(/, "_&", line)
      n = split(line, seg, /[|;&(){}`]/)
      for (i = 1; i <= n; i++) {
        s = seg[i]; last = ""; viaenv = 0; wrap = 0
        while (1) {
          sub(/^[[:space:]]+/, "", s)
          if (s ~ /^["\047]/) { s = substr(s, 2); continue }
          if (!match(s, /^[^[:space:]]+([[:space:]]|$)/)) break
          w = substr(s, 1, RLENGTH); sub(/[[:space:]]+$/, "", w)
          if (w ~ /^(!|if|then|else|elif|do|while|until|time|eval)$/) wrap = 0
          else if (w ~ /^(env|command|exec|nice|nohup|xargs|bash|sh)$/) { wrap = 1; if (w == "env") viaenv = 1 }
          else if (wrap && w ~ /^-/) { }
          else if (w ~ /^[0-9]*[<>]+[^<>[:space:]]/) { }
          else if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) wrap = 0
          else break
          last = w; s = substr(s, RLENGTH + 1)
        }
        if (s !~ /^\\?([^[:space:]]*\/)?(sort|comm|join|uniq)([[:space:]<>)"\047]|$)/) continue
        if (last == "LC_ALL=C" && !viaenv) continue
        f = FILENAME; if (index(f, pre) == 1) f = substr(f, length(pre) + 1)
        printf "%s:%d\n", f, FNR; break
      } }' "$@"
}
# Runtime code: felix, and every file under lib, hooks, bin and templates that
# a shell runs, which is a .sh file, a file whose first line is a sh or bash
# shebang, or a workflow template (templates/unattended.yml), whose run steps
# are bash. tests/ is not runtime code.
_lcb_scope() {  # <harness dir>: the runtime files, one absolute path a line
  local h="$1" f
  [ -f "$h/felix" ] && printf '%s\n' "$h/felix"
  ( cd "$h" && LC_ALL=C find lib hooks bin templates -type f 2>/dev/null ) | LC_ALL=C sort | while IFS= read -r f; do
    case "$f" in *.sh|*.yml|*.yaml) printf '%s\n' "$h/$f"; continue ;; esac
    LC_ALL=C grep -qE '^#!.*[/[:space:]](ba)?sh([[:space:]]|$)' <<<"$(head -1 "$h/$f" 2>/dev/null)" && printf '%s\n' "$h/$f"
  done
}
_lcb_lint_files() {  # <prefix> < paths: _lcb_lint over each path read
  local pre="$1" f; local -a fs=()
  while IFS= read -r f; do fs[${#fs[@]}]="$f"; done
  [ "${#fs[@]}" -gt 0 ] && _lcb_lint "$pre" "${fs[@]}"
}
# The shapes the lint must name, one a line, so a finding's line is the shape
# it caught. The second group was added after review: two mutants that put an
# unpinned sort back behind `{` and behind `then` passed the first version.
LCB_LF="$TMP/lc-lint"; mkdir -p "$LCB_LF"
cat > "$LCB_LF/catch.sh" <<'EOF'
x="$(printf '%s\n' "$a" | sort)"
y="$(sort -u f)"
sort -rn f | head -1
  comm -23 a b
LC_ALL=C sort f | uniq -c
join -t, a b
LANG=C sort f
LC_COLLATE=C sort f
env LC_ALL=C sort f
z=`sort f`
true && comm -12 a b
a; uniq f
x=$({ sort -u "$state"; } 2>/dev/null)
done | if true; then sort -rn; fi | head
if sort -c f; then :; fi
while read -r x; do comm -3 a b; done
else uniq f
! sort -c f
time sort f
exec sort f
nice sort f
ls | xargs sort
ls | xargs -0 sort
case x in a) sort f ;; esac
\sort f
/usr/bin/sort f
x | /usr/bin/sort -V | tail -1
>out sort f
eval "sort f"
bash -c 'sort f'
awk '{ print | "sort" }' f
LC_ALL="C" sort f
EOF
# And shapes it must not name: the rule's own spelling in each position the
# lint reads, comments, the awk split string lib/where-read.sh holds, an awk
# function called join, and a tool name that is an argument.
cat > "$LCB_LF/clean.sh" <<'EOF'
x="$(printf '%s\n' "$a" | LC_ALL=C sort)"
LC_ALL=C comm -23 a b
y="$(LC_ALL=C sort -u f)"
printf '%s\n' "$x" | LC_ALL=C sort -u | LC_ALL=C uniq -c
LC_ALL=C join -t, a b
# a comment: printf x | sort
    # an indented one: comm -23 a b
  split("cp mv rm rmdir mkdir touch tee truncate sed install dd ln link chmod chown cat head tail wc sort uniq grep egrep fgrep ls stat diff cmp cut", T, " ")
  dir = one(join(WD[cst], dir))
x=$({ LC_ALL=C sort -u "$state"; } 2>/dev/null)
done | if true; then LC_ALL=C sort -rn; fi | head
if LC_ALL=C sort -c f; then :; fi
time LC_ALL=C sort f
awk '{ print | "LC_ALL=C sort" }' f
eval "LC_ALL=C sort f"
die "sort failed"
for t in sort comm; do :; done
  return ff_uniq(o)
EOF
LCB_LC="$(_lcb_lint "$LCB_LF/" "$LCB_LF/catch.sh" | tr '\n' ' ')"
LCB_LCN="$(LC_ALL=C awk 'END { print NR }' "$LCB_LF/catch.sh")"
if [ "$LCB_LC" = "$(i=1; while [ $i -le "$LCB_LCN" ]; do printf 'catch.sh:%s ' $i; i=$((i+1)); done)" ]; then
  ok  "the locale lint names each unpinned shape in its fixture, by file and line"
else
  bad "the locale lint names each unpinned shape in its fixture, by file and line" "found: ${LCB_LC:-nothing} (of $LCB_LCN lines)"
fi
LCB_LN="$(_lcb_lint "$LCB_LF/" "$LCB_LF/clean.sh" | tr '\n' ' ')"
if [ -z "$LCB_LN" ]; then
  ok  "and names none of the pinned spellings, comment lines, an awk split string or an awk function called join"
else
  bad "and names none of the pinned spellings, comment lines, an awk split string or an awk function called join" "found: $LCB_LN"
fi
# The scope is checked before the tree is: a scope that lists nothing would
# leave the real-tree check below with nothing to find.
is  "the locale lint's scope reaches felix, the libraries, the hooks, the bin scripts and the workflow template" \
    "$(_lcb_scope "$REAL_HARNESS" | sed "s|^$REAL_HARNESS/||; s|/.*||" | LC_ALL=C sort -u | tr '\n' ' ')" \
    "bin felix hooks lib templates "
# And it holds every executable under bin and hooks, so one script given a
# shebang the scope does not read (zsh, say) leaves the lint's sight by name
# here, not in silence while its neighbours keep the line above green. None is
# excepted: on 2026-10-08 every executable in both is a sh or bash script.
LCB_LX="$(LC_ALL=C comm -13 <(_lcb_scope "$REAL_HARNESS" | sed "s|^$REAL_HARNESS/||" | LC_ALL=C sort) \
                            <(cd "$REAL_HARNESS" && LC_ALL=C find bin hooks -type f -perm -u+x | LC_ALL=C sort) \
           | tr '\n' ' ')"
is  "every executable under bin and hooks is in the locale lint's scope" "${LCB_LX:-none outside it}" "none outside it"
LCB_LR="$(_lcb_scope "$REAL_HARNESS" | _lcb_lint_files "$REAL_HARNESS/")"
if [ -z "$LCB_LR" ]; then
  ok  "every sort, comm, join and uniq in the engine's runtime code is written LC_ALL=C <tool>"
else
  bad "every sort, comm, join and uniq in the engine's runtime code is written LC_ALL=C <tool>" \
      "$(printf '%s\n' "$LCB_LR" | grep -c .) lines: $(printf '%s\n' "$LCB_LR" | tr '\n' ' ')"
fi

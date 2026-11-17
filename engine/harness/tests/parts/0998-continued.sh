_locale_bytes_vars
# L4. No bracket expression in bash's own pattern syntax whose members are
# only digits, digit ranges and . + _ -, holding a range between two digits.
# Bash's own pattern syntax is a case arm, the right side of [[ == ]] or
# [[ != ]], the pattern of ${v#p} ${v##p} ${v%p} ${v%%p} ${v/p/r} ${v//p/r},
# or a glob word: so every such bracket in code counts, except on the right of
# [[ =~ (an ERE, whose ranges are code points) up to a `]]` after a blank.
# Quote state is carried across lines, and what is not bash pattern text is
# skipped: single quotes, $'...' (with its \'), double quotes except inside
# ${...} (and inside a $( ) within them, which is code again, where a case
# arm's `)` does not close it), heredoc bodies (<<WORD, <<'WORD', <<"WORD",
# <<\WORD, <<-WORD with its tabs; not <<< and not a shift inside (( ))), and a
# comment from a # at a word boundary. A backslash escapes the next character
# in code, in double quotes and in $'...'. That keeps awk, sed and grep
# programs out (their ranges are code points). Spelled out, [0123456789] holds
# no range, and a bracket holding a letter range is Rule 1's first sentence,
# not this lint.
_lgb_e_dlint() {  # <prefix to strip> <file>...: file:line for each digit range in bash's own pattern syntax
  local pre="$1"; shift
  LC_ALL=C awk -v pre="$pre" -v q="'" '
    function push(s) { st[++sp] = s; cc[sp] = 0 }
    function pop() { if (sp > 1) sp-- }
    function bnd(k) { return k < 1 || substr(L, k, 1) ~ /[ \t;&|(]/ }
    BEGIN { ARE = "[\\\\" q "]"; DRE = "[\\\\\"$`]"; CRE = "[]\\\\" q "\"#<[$()}=]|case|esac"
            BRE = "^\\[[!^]?[0-9._+-]*[0-9]-[0-9][0-9._+-]*\\]"; ID = "^[A-Za-z_][A-Za-z0-9_]*" }
    FNR == 1 { sp = 1; st[1] = "C"; cc[1] = 0; nh = 0; hd = 0; hc = 0 }
    { L = $0
      if (hd) { t = L; if (ht[hc]) sub(/^\t+/, "", t)
        if (t == hw[hc]) { hc++; if (hc > nh) { hd = 0; nh = 0 } }
        next }
      hit = 0; re = 0; n = length(L); i = 1
      while (i <= n) {
        s = st[sp]
        if (s == "Q") { j = index(substr(L, i), q); if (!j) break; i += j; pop(); continue }
        if (s == "A") { if (!match(substr(L, i), ARE)) break; i += RSTART - 1
          if (substr(L, i, 1) == "\\") { i += 2; continue }
          pop(); i++; continue }
        if (s == "D") { if (!match(substr(L, i), DRE)) break; i += RSTART - 1; c = substr(L, i, 1)
          if (c == "\\") { i += 2; continue }
          if (c == "\"") { pop(); i++; continue }
          if (c == "$") {
            if (substr(L, i + 1, 1) == "{") { push("P"); i += 2; continue }
            if (substr(L, i + 1, 2) == "((") { push("M"); i += 3; continue }
            if (substr(L, i + 1, 1) == "(") { push("S"); i += 2; continue } }
          i++; continue }
        if (!match(substr(L, i), CRE)) break
        i += RSTART - 1; c = substr(L, i, 1)
        if (c == "\\") { i += 2; continue }
        if (c == q) { push("Q"); i++; continue }
        if (c == "\"") { push("D"); i++; continue }
        if (c == "#") { if (s != "P" && bnd(i - 1)) break; i++; continue }
        if (c == "<") {
          if (s != "P" && s != "M" && substr(L, i, 2) == "<<" && substr(L, i + 2, 1) != "<" && substr(L, i - 1, 1) != "<") {
            r = substr(L, i + 2); tb = 0; w = ""
            if (substr(r, 1, 1) == "-") { tb = 1; r = substr(r, 2) }
            sub(/^[ \t]+/, "", r); k = n - length(r) + 1; o = substr(r, 1, 1)
            if ((o == q || o == "\"") && match(substr(r, 2), ID) && substr(r, RLENGTH + 2, 1) == o) { w = substr(r, 2, RLENGTH); a = RLENGTH + 2 }
            else if (o == "\\" && match(substr(r, 2), ID)) { w = substr(r, 2, RLENGTH); a = RLENGTH + 1 }
            else if (match(r, ID)) { w = substr(r, 1, RLENGTH); a = RLENGTH }
            if (w != "") { hw[++nh] = w; ht[nh] = tb; i = k + a; continue } }
          i++; continue }
        if (c == "[") { if (!re && match(substr(L, i), BRE)) { hit = 1; i += RLENGTH; continue } i++; continue }
        if (c == "]") { if (re && substr(L, i, 2) == "]]" && substr(L, i - 1, 1) ~ /[ \t]/) re = 0; i++; continue }
        if (c == "=") { if (substr(L, i, 2) == "=~" && substr(L, i - 1, 1) ~ /[ \t]/ && substr(L, i + 2, 1) ~ /^[ \t]?$/) { re = 1; i += 2; continue } i++; continue }
        if (c == "$") { d = substr(L, i + 1, 1)
          if (d == q) { push("A"); i += 2; continue }
          if (d == "\"") { push("D"); i += 2; continue }
          if (d == "{") { push("P"); i += 2; continue }
          if (substr(L, i + 1, 2) == "((") { push("M"); i += 3; continue }
          if (d == "(") { push("S"); i += 2; continue }
          i++; continue }
        if (c == "}") { if (s == "P") pop(); i++; continue }
        if (c == "(") { if (s != "P") { if (s != "M" && substr(L, i, 2) == "((") { push("M"); i += 2; continue } push("R") } i++; continue }
        if (c == ")") {
          if (s == "M") { if (substr(L, i + 1, 1) == ")") { pop(); i += 2; continue } i++; continue }
          if ((s == "R" || s == "S") && cc[sp] <= 0) pop()
          i++; continue }
        if (s != "P" && s != "M" && bnd(i - 1) && substr(L, i + 4, 1) ~ /^[ \t;)]?$/) {
          if (substr(L, i, 4) == "case") cc[sp]++; else if (cc[sp] > 0) cc[sp]-- }
        i += 4 }
      if (hit) { f = FILENAME; if (index(f, pre) == 1) f = substr(f, length(pre) + 1); printf "%s:%d\n", f, FNR }
      if (nh && !hd) { hd = 1; hc = 1 } }' "$@" \
    || printf 'the lint itself failed\n'
}
LGB_E_LF="$TMP/lgb-e-lint"; mkdir -p "$LGB_E_LF"
# Every line of the catch fixture that holds a finding, by number: each
# pattern context, and a pattern right after each quote or heredoc form ends
# (or after a line a careless lint would take for one), so a lint that loses
# its quote state misses the line. The tabs of the <<- heredoc are printf'd.
{ cat <<'EOF'
case $n in ''|*[!0-9]*) ;; esac
case "$v" in
  [0-9][0-9]) echo two ;;
  *) ;;
esac
[[ $v == [1-9]* ]] && echo one
[[ $v != [0-9] ]] || echo none
y="${x%%[!0-9]*}"
y=${x//[!0-9]/}
y=${x#[0-9]}
y=${x##*[0-9.]}
y="${x%[0-9-]}"
y=${x/[0-9]/-}
for f in "$d"/[0-9]*; do :; done
LC_ALL=C awk '
  /^[0-9]+$/ { print }' f; case $x in [0-9]) ;; esac
cat <<EOT
[0-9]
EOT
case $x in [0-9]) ;; esac
cat <<'EOT'
${x%%[!0-9]*}
EOT
case $x in [0-9]) ;; esac
cat <<-EON
EOF
  printf '\t[0-9]\n\tEON\n'
  cat <<'EOF'
case $x in *[!0-9]*) ;; esac
echo "say \"hi\""; case $x in [0-9]) ;; esac
printf '%s\n' it\'s; case $x in [0-9]) ;; esac
y=$'a\'b\'c'; case $y in [0-9]) ;; esac
x=a#b; case $x in [0-9]) ;; esac
n=${#x} m=$#; case $n in [0-9]) ;; esac
grep -c x <<<word
case $x in [0-9]) ;; esac
n=$((x << y))
case $n in [0-9]) ;; esac
r="$(printf 'a"b')"; case $x in [0-9]) ;; esac
r="$(case $x in a) echo 'x"y' ;; esac)"; case $x in [0-9]) ;; esac
[[ $x =~ ^[a-z]+$ ]] && [[ $x == [0-9]* ]]
echo "two
lines"; case $x in [+0-9_]) ;; esac
case $x in *[^0-9]*) ;; esac
EOF
} > "$LGB_E_LF/d-catch.sh"
# Nothing here is a digit range in bash's own pattern syntax.
{ cat <<'EOF'
case $n in ''|*[!0123456789]*) ;; esac
LC_ALL=C awk '
  /^[0-9]+$/ { n++ }' f
LC_ALL=C grep -E '[0-9]' f
cat <<EOT
[0-9] ${x%%[!0-9]*}
EOT
cat <<'EOT'
case $x in [0-9]) ;; esac
EOT
cat <<"EOT"
[[ $v == [0-9] ]]
EOT
cat <<\EOT
y=${x#[0-9]}
EOT
cat <<-EON
EOF
  printf '\t[1-9]\n\tEON\n'
  cat <<'EOF'
# case $x in [0-9]) ;; esac
    # an indented one: ${x#[0-9]}
x=1 # and after code: [[ $v == [0-9] ]]
case $v in *[!a-z0-9_-]*) ;; esac
y=$'[0-9]'
[[ $x =~ ^[0-9]+$ ]] && echo digits
LC_ALL=C sed -n "s/[0-9]//p" f
echo "first
[0-9] second"
y='it''s [0-9]'
LC_ALL=C grep -c "x[0-9]" <<<"$y"
echo "${x%%[!0123456789]*}" "[0-9]"
r="$(printf '%s' "[1-9]")"
EOF
} > "$LGB_E_LF/d-clean.sh"
is  "the digit-range lint names a case arm on one line and across lines, [[ == ]] and [[ != ]], each \${v#p} form in and out of double quotes, a glob word, and a range right after each quote, heredoc, comment and escape form ends" \
    "$(_lgb_e_dlint "$LGB_E_LF/" "$LGB_E_LF/d-catch.sh" | LC_ALL=C tr '\n' ' ')" \
    "d-catch.sh:1 d-catch.sh:3 d-catch.sh:6 d-catch.sh:7 d-catch.sh:8 d-catch.sh:9 d-catch.sh:10 d-catch.sh:11 d-catch.sh:12 d-catch.sh:13 d-catch.sh:14 d-catch.sh:16 d-catch.sh:20 d-catch.sh:24 d-catch.sh:28 d-catch.sh:29 d-catch.sh:30 d-catch.sh:31 d-catch.sh:32 d-catch.sh:33 d-catch.sh:35 d-catch.sh:37 d-catch.sh:38 d-catch.sh:39 d-catch.sh:40 d-catch.sh:42 d-catch.sh:43 "
is  "and names none of a spelled-out set, an awk program over two lines, grep and sed programs, heredoc bodies in every form, comments, a letter range, \$'[0-9]', the right of =~, or double-quoted text" \
    "$(_lgb_e_dlint "$LGB_E_LF/" "$LGB_E_LF/d-clean.sh" | LC_ALL=C tr '\n' ' ')" ""
LGB_E_L4="$(_lgb_d_scope "$REAL_HARNESS" | _lgb_d_files _lgb_e_dlint "$REAL_HARNESS/")"
if [ -z "$LGB_E_L4" ]; then
  ok  "no bracket in bash's own pattern syntax in the engine's runtime code holds a range of digits; each is spelled out"
else
  bad "no bracket in bash's own pattern syntax in the engine's runtime code holds a range of digits; each is spelled out" \
      "$(printf '%s\n' "$LGB_E_L4" | LC_ALL=C grep -c .) findings: $(printf '%s\n' "$LGB_E_L4" | LC_ALL=C tr '\n' ' ')"
fi

# fragment f: the review's findings (E26-E32, F7-F9, G6)
#
# The adversarial review of 15e707de (contract, Amendment 2) found what the
# first five fragments left out. One correction to the class first: macOS awk
# 20200816 slices by bytes but matches regexes by characters, so an awk program
# that walks text one character at a time hands a lone byte of a VALID UTF-8
# character to a regex and aborts the whole program under UTF-8. So a plain
# accent or an em dash in a Bash command is a source here, not only a byte that
# is not UTF-8. The rest are BSD cut, tr and grep on \351 at sites the sweep
# missed, two byte ceilings that counted characters, and three session-id
# checks that collated. Each case runs the one call under test in a subshell
# set to the locale, reads its answer back outside with LC_ALL=C tools, and
# has a C control on the same fixture. glibc's tools read bytes, so on Linux
# most of these cannot fail; without the locale they skip by name.
_lgb_f_in() {  # C|lang|all <command...>: one call in that locale, in a subshell
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}
_lgb_f_u8() {  # <name> <how> <expected> <command...>: asserted in a UTF-8 locale, or skipped by the same name
  local name="$1" how="$2" want="$3"; shift 3
  if [ -n "$LCB_U8" ]; then is "$name" "$(_lgb_f_in "$how" "$@")" "$want"; else skip "$name" "$LCB_NONE"; fi
}
# A home holding one project bound by marker, a committed checkout, and a
# memory, kernel cache and HOME of the fixture's own, so no table the rest of
# the suite reads gains a row.
_lgb_f_mk() {  # <dir> <project>
  mkdir -p "$1/home/projects/$2" "$1/mem" "$1/kc" "$1/h" "$1/repo"
  printf '{"name":"%s","gate":"true"}\n' "$2" > "$1/home/projects/$2/project.json"
  printf '# %s\n' "$2" > "$1/home/projects/$2/CLAUDE.md"
  ( _fx_cd "$1/repo" && git init -q -b main && printf '%s\n' "$2" > .felix && git add -A \
    && git -c user.name=t -c user.email=t@t commit -qm base ) >/dev/null 2>&1
}
_lgb_f_cli() {  # <dir> <felix args...>: the real CLI in that fixture's checkout
  local d="$1"; shift
  ( cd "$d/repo" || exit 99
    [ -f .felix ] || exit 99
    HOME="$d/h" FELIX_KERNEL='' FELIX_KERNEL_CACHE="$d/kc" FELIX_HOME="$d/home" FELIX_MEMORY="$d/mem" \
      "$FELIX" "$@" ) </dev/null
}
LGB_F_CAFE="$(printf 'caf\303\251')"; LGB_F_DASH="$(printf 'a\342\200\224b')"; LGB_F_LAT="$(printf 'caf\351')"

# E26 (R-H1). The deny hook reads a Bash command through felix_deny_code's awk,
# which walks it one character at a time; under UTF-8 a valid accent aborts it,
# the reading is empty, and every Bash row passes. The real hooks/pre-tool, in
# a governed checkout of the fixture's own, given a payload whose command
# echoes a word and then runs one a row refuses. The refused word is one no
# real table names; it sits only inside the payload, which is never run.
LGB_F_D="$TMP/lgb_f_deny"; _lgb_f_mk "$LGB_F_D" lgbfd
LGB_F_D="$(cd "$LGB_F_D" && pwd -P)" || LGB_F_D="$TMP/lgb_f_deny"
LGB_F_DR="$LGB_F_D/repo"
printf 'Bash\tlgbf_refuse_me\tno lgbf_refuse_me here\n' > "$LGB_F_D/home/projects/lgbfd/deny.tsv"
_lgb_f_pre() {  # <word>: the hook's status for `echo <word> && lgbf_refuse_me now`
  [ -f "$LGB_F_DR/.felix" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_F_DR" \
    && printf '{"session_id":"lgbf-s","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"echo %s && lgbf_refuse_me now"}}' \
         "$LGB_F_DR" "$1" \
       | FELIX_KERNEL='' FELIX_HOME="$LGB_F_D/home" FELIX_MEMORY="$LGB_F_D/mem" "$FROOT/harness/hooks/pre-tool" ) >/dev/null 2>&1
  printf 'rc=%s' "$?"
}
is  "in C, the deny hook refuses a matching Bash command that also echoes an e-acute, an em dash, or a Latin-1 byte, exit 2 each" \
    "$(_lgb_f_in C _lgb_f_pre "$LGB_F_CAFE") $(_lgb_f_in C _lgb_f_pre "$LGB_F_DASH") $(_lgb_f_in C _lgb_f_pre "$LGB_F_LAT")" "rc=2 rc=2 rc=2"
_lgb_f_u8 "in a UTF-8 locale, the deny hook refuses that command echoing cafe in ASCII" all "rc=2" _lgb_f_pre cafe
_lgb_f_u8 "in a UTF-8 locale with LC_ALL set, the deny hook still refuses a matching Bash command that echoes a valid UTF-8 e-acute" \
    all  "rc=2" _lgb_f_pre "$LGB_F_CAFE"
_lgb_f_u8 "in a UTF-8 locale with LANG set and LC_ALL unset, the deny hook still refuses a matching Bash command that echoes a valid UTF-8 e-acute" \
    lang "rc=2" _lgb_f_pre "$LGB_F_CAFE"
_lgb_f_u8 "in a UTF-8 locale with LC_ALL set, the deny hook still refuses a matching Bash command that holds an em dash" \
    all  "rc=2" _lgb_f_pre "$LGB_F_DASH"
_lgb_f_u8 "in a UTF-8 locale with LANG set and LC_ALL unset, the deny hook still refuses a matching Bash command that holds an em dash" \
    lang "rc=2" _lgb_f_pre "$LGB_F_DASH"
_lgb_f_u8 "in a UTF-8 locale with LC_ALL set, the deny hook still refuses a matching Bash command that holds a byte that is not UTF-8" \
    all  "rc=2" _lgb_f_pre "$LGB_F_LAT"
_lgb_f_u8 "in a UTF-8 locale with LANG set and LC_ALL unset, the deny hook still refuses a matching Bash command that holds a byte that is not UTF-8" \
    lang "rc=2" _lgb_f_pre "$LGB_F_LAT"

# E27 (R-H2, R-H2b). The gate-mode counts read the run's rows with grep -c .,
# which under UTF-8 misses a line whose first byte is not UTF-8, so a blocking
# row named with \351 counted 0 and the gate passed. One fixture whose blocking
# rows are named with the byte, and one whose same rows are named in ASCII.
LGB_F_G="$TMP/lgb_f_gate"; LGB_F_GA="$TMP/lgb_f_gate_ascii"
_lgb_f_mk "$LGB_F_G" lgbf; _lgb_f_mk "$LGB_F_GA" lgbf
LGB_F_G="$(cd "$LGB_F_G" && pwd -P)" || LGB_F_G="$TMP/lgb_f_gate"
LGB_F_GA="$(cd "$LGB_F_GA" && pwd -P)" || LGB_F_GA="$TMP/lgb_f_gate_ascii"
_lgb_f_tables() {  # <dir> <first byte(s) of the blocking rows' name>
  printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n%stre\t-\t-\tfalse\t-\n' "$2" > "$1/home/projects/lgbf/probes.tsv"
  { printf 'fine\tRELEASE_BLOCKING\tdeterministic\t-\ttrue\t-\tit holds\n'
    printf '%stre\tRELEASE_BLOCKING\tdeterministic\t-\tfalse\t-\tit does not hold\n' "$2"; } > "$1/home/projects/lgbf/obligations.tsv"
}
_lgb_f_tables "$LGB_F_G" "$(printf '\351')"; _lgb_f_tables "$LGB_F_GA" e
_lgb_f_count() {  # <dir> probes|obligations|probes-check|obligations-check: that count's exit status
  local d="$1"
  [ -f "$d/repo/.felix" ] || { printf 'no fixture'; return 0; }
  case "$2" in
    probes|obligations) _lgb_f_cli "$d" "$2" --gate ;;
    *) ( cd "$d/repo" && HOME="$d/h" FELIX_HOME="$d/home" FELIX_MEMORY="$d/mem" \
           "$FROOT/harness/bin/$2" "$d/home/projects/lgbf" ) </dev/null ;;
  esac >/dev/null 2>&1
  printf 'rc=%s' "$?"
}
_lgb_f_counts() {  # <how> <dir>: the four statuses
  printf '%s %s %s %s' "$(_lgb_f_in "$1" _lgb_f_count "$2" probes)" "$(_lgb_f_in "$1" _lgb_f_count "$2" obligations)" \
    "$(_lgb_f_in "$1" _lgb_f_count "$2" probes-check)" "$(_lgb_f_in "$1" _lgb_f_count "$2" obligations-check)"
}
is  "in C, felix probes --gate, felix obligations --gate, bin/probes-check and bin/obligations-check each exit 1 over a blocking row whose name starts with a Latin-1 byte" \
    "$(_lgb_f_counts C "$LGB_F_G")" "rc=1 rc=1 rc=1 rc=1"
LGB_F_27K="in a UTF-8 locale, those four exit 1 over the same blocking rows named in ASCII"
if [ -n "$LCB_U8" ]; then is "$LGB_F_27K" "$(_lgb_f_counts all "$LGB_F_GA")" "rc=1 rc=1 rc=1 rc=1"; else skip "$LGB_F_27K" "$LCB_NONE"; fi
_lgb_f_u8 "in a UTF-8 locale, felix probes --gate still exits 1 over a blocking probe whose name starts with a byte that is not UTF-8" \
    all "rc=1" _lgb_f_count "$LGB_F_G" probes
_lgb_f_u8 "in a UTF-8 locale, felix obligations --gate still exits 1 over a blocking obligation whose name starts with a byte that is not UTF-8" \
    all "rc=1" _lgb_f_count "$LGB_F_G" obligations
_lgb_f_u8 "in a UTF-8 locale, bin/probes-check still exits 1 over a blocking probe whose name starts with a byte that is not UTF-8" \
    all "rc=1" _lgb_f_count "$LGB_F_G" probes-check
_lgb_f_u8 "in a UTF-8 locale, bin/obligations-check still exits 1 over a blocking obligation whose name starts with a byte that is not UTF-8" \
    all "rc=1" _lgb_f_count "$LGB_F_G" obligations-check

# The template's probes check, read from templates/commissioning.tsv exactly
# as written there and asked through felix_commission_ask, over a project
# whose only fault is a malformed probe row named with the byte: its count of
# malformed rows is grep -c ., which read 0 under UTF-8, so the need read done.
LGB_F_TP="$TMP/lgb_f_tpl_proj"; mkdir -p "$LGB_F_TP"
LGB_F_TCK="$(LC_ALL=C awk -F'\t' '$1 == "probes" { print $6; exit }' "$FROOT/harness/templates/commissioning.tsv" 2>/dev/null)"
_lgb_f_tpl() {  # <first byte(s) of the malformed row's name, or - for none>: the check's status
  [ -f "$LGB_F_G/repo/.felix" ] || { printf 'no fixture'; return 0; }
  { printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n'
    [ "$1" = - ] || printf '%stre\t-\t-\n' "$1"; } > "$LGB_F_TP/probes.tsv"
  printf 'rc=%s' "$(_lgb_f_in "$2" _lgb_f_ask)"
}
_lgb_f_ask() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/commission.sh"
    export FELIX_PROJECT="$LGB_F_TP" FELIX_PROJECT_NAME=lgbf FELIX_ROOT_DIR="$LGB_F_G/repo" FELIX_HOME_DIR="$LGB_F_G/home"
    felix_commission_ask "$LGB_F_G/repo" "$LGB_F_TCK"; printf '%s' "$?" ) </dev/null 2>/dev/null
}
is  "in C, the template's probes check, as commissioning.tsv writes it, is done over a well-formed table and not done over a malformed row named with a Latin-1 byte" \
    "$(_lgb_f_tpl - C) $(_lgb_f_tpl "$(printf '\351')" C)" "rc=0 rc=1"
LGB_F_27TK="in a UTF-8 locale, the template's probes check is still done over a well-formed table and not done over a malformed row named in ASCII"
LGB_F_27TA="in a UTF-8 locale with LC_ALL set, the template's probes check is not done over a malformed probe row named with a byte that is not UTF-8"
LGB_F_27TL="in a UTF-8 locale with LANG set and LC_ALL unset, the template's probes check is not done over a malformed probe row named with a byte that is not UTF-8"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_F_27TK" "$(_lgb_f_tpl - all) $(_lgb_f_tpl e all)" "rc=0 rc=1"
  is  "$LGB_F_27TA" "$(_lgb_f_tpl "$(printf '\351')" all)"  "rc=1"
  is  "$LGB_F_27TL" "$(_lgb_f_tpl "$(printf '\351')" lang)" "rc=1"
else
  for a in "$LGB_F_27TK" "$LGB_F_27TA" "$LGB_F_27TL"; do skip "$a" "$LCB_NONE"; done
fi

# E28 (R-M1). hooks/user-prompt cuts the best route's score, name and play
# with cut, which prints nothing of the line under UTF-8 when the play holds
# \351: the route state named no route and the log logged a miss. The real
# hook, over a prompt the backend route wins, one session id per call; the
# state file and routes.log are read here, outside the locale.
LGB_F_U="$TMP/lgb_f_route"; _lgb_f_mk "$LGB_F_U" lgbf
LGB_F_U="$(cd "$LGB_F_U" && pwd -P)" || LGB_F_U="$TMP/lgb_f_route"
{ printf 'backend\tmigration schema endpoint\tcore\tsuperpowers:brainstorming caf\351-notes\n'
  printf 'notes\tmenu\tcore\twrite it down\n'; } > "$LGB_F_U/home/projects/lgbf/routes.tsv"
_lgb_f_hook() {  # <sid>
  ( cd "$LGB_F_U/repo" \
    && printf '{"session_id":"%s","transcript_path":"%s/none.jsonl","cwd":"%s","hook_event_name":"UserPromptSubmit","prompt":"add a migration for the endpoint schema"}' \
         "$1" "$LGB_F_U" "$LGB_F_U/repo" \
       | FELIX_HOME="$LGB_F_U/home" FELIX_MEMORY="$LGB_F_U/mem" "$FROOT/harness/hooks/user-prompt" ) >/dev/null 2>&1
}
_lgb_f_up() {  # <how> <sid>: the route state that call wrote | routes.log's last row's name and score
  [ -f "$LGB_F_U/repo/.felix" ] || { printf 'no fixture'; return 0; }
  _lgb_f_in "$1" _lgb_f_hook "$2"
  printf '%s|%s' "$(LC_ALL=C cat "$LGB_F_U/home/state/route/$2" 2>/dev/null)" \
    "$(LC_ALL=C grep -v '^#' "$LGB_F_U/mem/lgbf/routes.log" 2>/dev/null | LC_ALL=C tail -1 | LC_ALL=C cut -f2,3 | LC_ALL=C tr '\t' ' ')"
}
LGB_F_UPC="$(_lgb_f_up C lgbf-c1)"
is  "in C, hooks/user-prompt over a prompt the backend route wins, its play holding a Latin-1 byte, records backend and its first step in the route state and logs backend" \
    "$(printf '%s' "$LGB_F_UPC" | LC_ALL=C awk -F'|' '{ split($1, s, "\t"); split($2, w, " ")
        printf "%s|%s %s", s[1], w[1], (w[2] ~ /^[0123456789]+$/ && w[2] + 0 > 0) ? "scored" : "[" w[2] "]" }')" \
    "backend:superpowers:brainstorming|backend scored"
LGB_F_28A="in a UTF-8 locale with LC_ALL set, hooks/user-prompt writes the same route state and routes.log row as in C when the winning route's play holds a byte that is not UTF-8"
LGB_F_28L="in a UTF-8 locale with LANG set and LC_ALL unset, hooks/user-prompt writes the same route state and routes.log row as in C for that play"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_F_28A" "$(_lgb_f_up all lgbf-a1)"  "$LGB_F_UPC"
  is  "$LGB_F_28L" "$(_lgb_f_up lang lgbf-l1)" "$LGB_F_UPC"
else
  for a in "$LGB_F_28A" "$LGB_F_28L"; do skip "$a" "$LCB_NONE"; done
fi

# E29 (R-M2). felix_epoch_topology cut each run row to six fields with cut,
# which under UTF-8 drops a row holding \351, so a probe whose command holds
# the byte left the hash and a change in what it finds never moved the epoch.
# The other probe reads a directory nothing touches, so only the byte's probe
# can move it.
LGB_F_EP="$TMP/lgb_f_epoch_proj"; LGB_F_ER="$TMP/lgb_f_epoch_root"
mkdir -p "$LGB_F_EP" "$LGB_F_ER/lgbfkeep" "$LGB_F_ER/lgbfdir"
printf 'k\n' > "$LGB_F_ER/lgbfkeep/k"; printf 'a\n' > "$LGB_F_ER/lgbfdir/one"
{ printf 'marker\t-\t-\tls -1 lgbfkeep\ttest -d lgbfkeep\n'
  printf 'lgbflatin\t-\t-\tls -1 lgbfdir; : caf\351\t-\n'; } > "$LGB_F_EP/probes.tsv"
_lgb_f_topo() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/probes.sh"; . "$FROOT/harness/lib/epoch.sh"
    felix_epoch_topology "$LGB_F_EP" "$LGB_F_ER" ) </dev/null 2>/dev/null
}
LGB_F_TC1="$(_lgb_f_in C _lgb_f_topo)"; LGB_F_TU1=""; [ -n "$LCB_U8" ] && LGB_F_TU1="$(_lgb_f_in all _lgb_f_topo)"
printf 'b\n' > "$LGB_F_ER/lgbfdir/two"
LGB_F_TC2="$(_lgb_f_in C _lgb_f_topo)"; LGB_F_TU2=""; [ -n "$LCB_U8" ] && LGB_F_TU2="$(_lgb_f_in all _lgb_f_topo)"
_lgb_f_moved() { if [ -n "$1" ] && [ -n "$2" ] && [ "$1" != "$2" ]; then printf moved; else printf 'still [%s] [%s]' "$1" "$2"; fi; }
is  "in C, felix_epoch_topology moves when a probe whose command holds a Latin-1 byte finds one member more" \
    "$(_lgb_f_moved "$LGB_F_TC1" "$LGB_F_TC2")" "moved"
LGB_F_29="in a UTF-8 locale, felix_epoch_topology still moves when a probe whose command holds a byte that is not UTF-8 finds one member more"
LGB_F_29C="in a UTF-8 locale, felix_epoch_topology over that probe reads the hash it reads in C"
if [ -n "$LCB_U8" ]; then
  is  "$LGB_F_29"  "$(_lgb_f_moved "$LGB_F_TU1" "$LGB_F_TU2")" "moved"
  is  "$LGB_F_29C" "$LGB_F_TU2" "$LGB_F_TC2"
else
  for a in "$LGB_F_29" "$LGB_F_29C"; do skip "$a" "$LCB_NONE"; done
fi

# F7 (R-M3). The release target is the last epoch component, and the gate cut
# the epoch and its components from one line holding it with cut, which under
# UTF-8 prints nothing: a green receipt recorded epoch `-` and read stale
# forever. The real gate in a fixture whose project declares one probe, then
# felix_verify_current in the same locale; and felix_verify_record given no
# epoch, which computes and cuts the fields itself.
LGB_F_R="$TMP/lgb_f_receipt"; _lgb_f_mk "$LGB_F_R" lgbf
LGB_F_R="$(cd "$LGB_F_R" && pwd -P)" || LGB_F_R="$TMP/lgb_f_receipt"
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$LGB_F_R/home/projects/lgbf/probes.tsv"
LGB_F_RT="$(printf 'r\351lease')"
_lgb_f_gate() { FELIX_RELEASE_TARGET="$LGB_F_RT" _lgb_f_cli "$LGB_F_R" gate >/dev/null 2>&1; }
_lgb_f_rec() {
  ( cd "$LGB_F_R/repo" && export FELIX_RELEASE_TARGET="$LGB_F_RT" FELIX_HOME="$LGB_F_R/home" FELIX_MEMORY="$LGB_F_R/mem"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_verify_record "$LGB_F_R/repo" "$LGB_F_R/home" 0 gate "$(felix_tree_id "$LGB_F_R/repo" "$LGB_F_R/home")" "" "" ) </dev/null >/dev/null 2>&1
}
_lgb_f_cur() {
  ( cd "$LGB_F_R/repo" && export FELIX_RELEASE_TARGET="$LGB_F_RT" FELIX_HOME="$LGB_F_R/home" FELIX_MEMORY="$LGB_F_R/mem"
    . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/verify.sh"
    felix_verify_current "$LGB_F_R/repo" "$LGB_F_R/home" "$LGB_F_R/home/projects/lgbf" ) </dev/null 2>/dev/null
}
_lgb_f_receipt() {  # <how> <writer>: the receipt's result, whether field 7 is an epoch, and felix_verify_current's word
  [ -f "$LGB_F_R/repo/.felix" ] || { printf 'no fixture'; return 0; }
  rm -f "$LGB_F_R/home/state/gate/$(printf '%s' "$LGB_F_R/repo" | git hash-object --stdin)"
  _lgb_f_in "$1" "$2"
  printf '%s|%s' \
    "$(LC_ALL=C awk -F'\t' '{ printf "%s|%s", $2, ($7 ~ /^[0123456789abcdef]+$/ && length($7) >= 40) ? "epoch" : "no epoch [" $7 "]" }' \
         "$LGB_F_R/home/state/gate/$(printf '%s' "$LGB_F_R/repo" | git hash-object --stdin)" 2>/dev/null)" \
    "$(_lgb_f_in "$1" _lgb_f_cur | LC_ALL=C cut -f1)"
}
is  "in C, felix gate under a release target holding a Latin-1 byte records a green receipt with an epoch, and felix_verify_current reads it current" \
    "$(_lgb_f_receipt C _lgb_f_gate)" "green|epoch|current"
_lgb_f_u8 "in a UTF-8 locale, felix gate under a release target holding a byte that is not UTF-8 still records an epoch, and felix_verify_current reads the receipt current" \
    C "green|epoch|current" _lgb_f_receipt all _lgb_f_gate
_lgb_f_u8 "in a UTF-8 locale, felix_verify_record given no epoch computes one under that release target, and felix_verify_current reads the receipt current" \
    C "green|epoch|current" _lgb_f_receipt all _lgb_f_rec

# E30 (R-M6). The provider answer's ceilings count bytes, as the log holds
# them; ${#why} counted characters under UTF-8, and cut -f5 printed nothing of
# a row holding \351, so a 400-byte why passed a 300 ceiling either way. And
# the log row was cut by tr, which stopped at the byte. An answer of three
# rows: a short why, 200 e-acutes, and the byte then 400 x.
LGB_F_PM="$TMP/lgb_f_prov_mem"; LGB_F_PJ="$TMP/lgb_f_prov_home/projects/lgbf"; LGB_F_PR="$TMP/lgb_f_prov_root"
mkdir -p "$LGB_F_PM" "$LGB_F_PJ" "$LGB_F_PR"
LGB_F_AC200="$(i=0; while [ "$i" -lt 200 ]; do printf '\303\251'; i=$((i + 1)); done)"
LGB_F_LAT400="$(printf '\351'; i=0; while [ "$i" -lt 400 ]; do printf 'x'; i=$((i + 1)); done)"
_lgb_f_answer() {  # <need> <done> <row>...: an answer file keyed to the real topology
  local need="$1" d="$2"; shift 2
  ( export FELIX_MEMORY="$LGB_F_PM"; . "$FROOT/harness/lib/commission-provider.sh" || exit 1
    f="$(felix_commission_answer_path "$LGB_F_PJ" "$need")"
    [ -n "$f" ] && mkdir -p "${f%/*}" || exit 1
    { printf '# topology %s\n' "$(felix_commission_topology "$LGB_F_PJ" "$LGB_F_PR")"
      for r in "$@"; do printf '%s\n' "$r"; done
      printf 'done\t%s\n' "$d"; } > "$f" ) </dev/null >/dev/null 2>&1
}
_lgb_f_answer lgbf_why 3 "$(printf 'plugin\tlgbf-ok\tsrc\tcap\ta short reason')" \
  "$(printf 'plugin\tlgbf-acute\tsrc\tcap\t%s' "$LGB_F_AC200")" "$(printf 'plugin\tlgbf-latin\tsrc\tcap\t%s' "$LGB_F_LAT400")"
_lgb_f_prows() { ( export FELIX_MEMORY="$LGB_F_PM"; . "$FROOT/harness/lib/commission-provider.sh"; felix_commission_provider_rows "$LGB_F_PJ" lgbf_why ) </dev/null 2>/dev/null; }
_lgb_f_prej()  { ( export FELIX_MEMORY="$LGB_F_PM"; . "$FROOT/harness/lib/commission-provider.sh"; felix_commission_provider_rejects "$LGB_F_PJ" lgbf_why ) </dev/null 2>/dev/null; }
_lgb_f_admit() {  # <how> <name>: ok=<short row admitted> <name>=<that row admitted>
  local out; out="$(_lgb_f_in "$1" _lgb_f_prows | LC_ALL=C cut -f2)"
  printf 'ok=%s %s=%s' "$(printf '%s\n' "$out" | LC_ALL=C grep -cx lgbf-ok)" "${2#lgbf-}" "$(printf '%s\n' "$out" | LC_ALL=C grep -cx "$2")"
}
_lgb_f_rejected() { _lgb_f_in "$1" _lgb_f_prej | LC_ALL=C grep 'longer than 300' | LC_ALL=C cut -f1 | LC_ALL=C tr '\n' ' '; }
LGB_F_LOGW="$(printf 'the caf\351 menu, kept whole to the end')"
_lgb_f_answer lgbf_log 1 "$(printf 'plugin\tlgbf-log\tsrc\tcap\t%s' "$LGB_F_LOGW")"
_lgb_f_plog() {
  ( export FELIX_MEMORY="$LGB_F_PM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/commission-provider.sh"
    felix_commission_record_provider "$LGB_F_PJ" "$LGB_F_PR" lgbf_log provider:lgbf-plug:lgbf-skill tid0 pol0 ) </dev/null >/dev/null 2>&1
}
_lgb_f_logrow() {  # <how>: the description field of the one row that recording wrote
  rm -f "$LGB_F_PM/lgbf/commissioning.log"
  _lgb_f_in "$1" _lgb_f_plog
  LC_ALL=C awk -F'\t' '$4 == "lgbf_log" { printf "%s", $9 }' "$LGB_F_PM/lgbf/commissioning.log" 2>/dev/null
}
is  "in C, a provider answer row whose why is 200 e-acutes (400 bytes), or a Latin-1 byte and 400 more, is refused as longer than 300, and a short one admitted" \
    "$(_lgb_f_admit C lgbf-acute) $(_lgb_f_admit C lgbf-latin | LC_ALL=C sed 's/^ok=1 //')|$(_lgb_f_rejected C)" "ok=1 acute=0 latin=0|lgbf-acute lgbf-latin "
is  "in C, recording a provider row whose why holds a Latin-1 byte keeps every byte of it in the log" \
    "$(_lgb_f_logrow C)" "plugin lgbf-log: src cap $LGB_F_LOGW"
_lgb_f_u8 "in a UTF-8 locale, a provider answer row whose why is 200 e-acutes, 400 bytes, is still not admitted, as in C" \
    C "ok=1 acute=0" _lgb_f_admit all lgbf-acute
_lgb_f_u8 "in a UTF-8 locale, a provider answer row whose why is a byte that is not UTF-8 and 400 more is still not admitted, as in C" \
    C "ok=1 latin=0" _lgb_f_admit all lgbf-latin
_lgb_f_u8 "in a UTF-8 locale, felix_commission_provider_rejects names both long whys as longer than 300, as in C" \
    C "lgbf-acute lgbf-latin " _lgb_f_rejected all
_lgb_f_u8 "in a UTF-8 locale, the commissioning log row for a provider why holding a byte that is not UTF-8 keeps every byte, as in C" \
    C "plugin lgbf-log: src cap $LGB_F_LOGW" _lgb_f_logrow all

# E31 (R-M7). The candidates reader's reason ceiling counts bytes too; a
# reason of 160 e-acutes is 320 bytes. (The contract's 150 is 300 bytes, which
# is the ceiling itself and passes in C.) And felix_candidates_record cut the
# accepted row's fields with cut, so a row holding \351 was written with an
# empty name and class.
LGB_F_CM="$TMP/lgb_f_cand_mem"; LGB_F_CJ="$TMP/lgb_f_cand_home/projects/lgbf"; LGB_F_CR="$TMP/lgb_f_cand_root"
mkdir -p "$LGB_F_CM" "$LGB_F_CJ" "$LGB_F_CR"
( _fx_cd "$LGB_F_CR" && git init -q -b main && printf 'lgbf\n' > .felix ) >/dev/null 2>&1
printf 'marker\t-\t-\tls -1 .felix\ttest -f .felix\n' > "$LGB_F_CJ/probes.tsv"
LGB_F_AC160="$(i=0; while [ "$i" -lt 160 ]; do printf '\303\251'; i=$((i + 1)); done)"
_lgb_f_cans() {  # <done> <row>...
  local d="$1"; shift
  ( export FELIX_MEMORY="$LGB_F_CM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/candidates.sh" || exit 1
    f="$(felix_candidates_answer_path "$LGB_F_CJ")"
    [ -n "$f" ] && mkdir -p "${f%/*}" || exit 1
    { printf '# topology %s\n' "$(felix_commission_topology "$LGB_F_CJ" "$LGB_F_CR")"
      for r in "$@"; do printf '%s\n' "$r"; done
      printf 'done\t%s\n' "$d"; } > "$f" ) </dev/null >/dev/null 2>&1
}
_lgb_f_crules() { ( export FELIX_MEMORY="$LGB_F_CM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/candidates.sh"; felix_candidates_rules "$LGB_F_CJ" "$LGB_F_CR" ) </dev/null 2>/dev/null; }
_lgb_f_crec()   { ( export FELIX_MEMORY="$LGB_F_CM"; . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/candidates.sh"; felix_candidates_record "$LGB_F_CJ" "$LGB_F_CR" ) </dev/null >/dev/null 2>&1; }
_lgb_f_cverdict() {  # <how>: accept|refuse:name for each row of the two-row answer
  _lgb_f_cans 2 "$(printf 'lgbf_short\tADVISORY\ttrue\ttrue\tmarker\tit fails\ta short reason')" \
    "$(printf 'lgbf_acute\tADVISORY\ttrue\ttrue\tmarker\tit fails\t%s' "$LGB_F_AC160")"
  _lgb_f_in "$1" _lgb_f_crules | LC_ALL=C cut -f1,2 | LC_ALL=C tr '\t\n' ': '
}
LGB_F_CRW="$(printf 'the caf\351 reason')"
_lgb_f_crow() {  # <how>: name|class|reason of the one row recorded
  _lgb_f_cans 1 "$(printf 'lgbf_cand\tADVISORY\ttrue\ttrue\tmarker\tit fails\t%s' "$LGB_F_CRW")"
  rm -f "$LGB_F_CM/lgbf/candidates.tsv"
  _lgb_f_in "$1" _lgb_f_crec
  LC_ALL=C awk -F'\t' '{ printf "%s|%s|%s", $6, $7, $13 }' "$LGB_F_CM/lgbf/candidates.tsv" 2>/dev/null
}
is  "in C, a candidate whose reason is 160 e-acutes, 320 bytes, is refused and a short one accepted" \
    "$(_lgb_f_cverdict C)" "accept:lgbf_short refuse:lgbf_acute "
is  "in C, a candidate whose reason holds a Latin-1 byte is recorded with its name, class and reason" \
    "$(_lgb_f_crow C)" "lgbf_cand|ADVISORY|$LGB_F_CRW"
_lgb_f_u8 "in a UTF-8 locale, a candidate whose reason is 160 e-acutes, 320 bytes, is still refused, as in C" \
    C "accept:lgbf_short refuse:lgbf_acute " _lgb_f_cverdict all
_lgb_f_u8 "in a UTF-8 locale, a candidate whose reason holds a byte that is not UTF-8 is still recorded with its name, class and reason" \
    C "lgbf_cand|ADVISORY|$LGB_F_CRW" _lgb_f_crow all

# F8 (R-L1). evidence.sh drops comment lines with grep -vE, which under UTF-8
# does not see `#` begin a line whose next byte is not UTF-8; so a table
# holding only a commented-out row ran that row and reported its gap. A
# checkout whose branch adds src/api/x.py and no test.
LGB_F_V="$TMP/lgb_f_evid"; LGB_F_VP="$TMP/lgb_f_evid_proj"; mkdir -p "$LGB_F_V" "$LGB_F_VP"
( _fx_cd "$LGB_F_V" && git init -q -b main && printf 'readme\n' > README && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm base && git checkout -q -b work && mkdir -p src/api \
  && printf 'x = 1\n' > src/api/x.py && git add -A && git -c user.name=t -c user.email=t@t commit -qm work ) >/dev/null 2>&1
LGB_F_V="$(cd "$LGB_F_V" && pwd -P)" || LGB_F_V=""
_lgb_f_evid() {
  [ -n "$LGB_F_V" ] && [ -d "$LGB_F_V/.git" ] || { printf 'no fixture'; return 0; }
  ( cd "$LGB_F_V" && . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/evidence.sh"
    felix_evidence_check "$LGB_F_VP" main "$LGB_F_V" ) </dev/null 2>/dev/null
}
_lgb_f_ev() {  # <how> <table line>: the statuses felix_evidence_check prints over that one-line table
  printf '%s\n' "$2" > "$LGB_F_VP/evidence.tsv"
  _lgb_f_in "$1" _lgb_f_evid | LC_ALL=C cut -f1 | LC_ALL=C tr '\n' ' '
}
LGB_F_VROW="$(printf 'api-tests\t^src/api/\t^tests/\tan api change ships a test')"
LGB_F_VCOM="$(printf '#\351 api-tests\t^src/api/\t^tests/\tan api change ships a test, commented out')"
is  "in C, an evidence table holding only a commented-out row whose second byte is Latin-1 reports nothing, and the same row uncommented a gap" \
    "$(_lgb_f_ev C "$LGB_F_VCOM")|$(_lgb_f_ev C "$LGB_F_VROW")" "|gap "
_lgb_f_u8 "in a UTF-8 locale, the uncommented api-tests row still reports its gap" C "gap " _lgb_f_ev all "$LGB_F_VROW"
_lgb_f_u8 "in a UTF-8 locale, an evidence table holding only a commented-out row whose second byte is not UTF-8 reports no gap" \
    C "" _lgb_f_ev all "$LGB_F_VCOM"

# E32 and F9: secret-scan's bounded CONTEXT exclusion, the HARD shapes that
# bound it, and the VALUE exclusion. Each was pinned to LC_ALL=C before the
# review (daee5683), and no assertion failed with any of the pins removed: so
# these pass on the engine they were written against and fail on it with the
# pin taken out. Read from stdin (`-`), one added line each. E32: a lookup,
# the byte, then a key id, which only HARD keeps reported. F9: a placeholder
# value holding the byte, which only VALUE drops; and a lookup after the byte,
# which only CONTEXT drops.
LGB_F_KID="AK""IA$(printf '%s%s%s%s' Q7RJ 4KLM 2NPW 8TXZ)"
LGB_F_S1="$(printf '+k = os.environ.get("K") or "caf\351 %s"' "$LGB_F_KID")"
LGB_F_S2="$(printf '+password = "caf\351-placeholder-value"')"
LGB_F_S3="$(printf '+# caf\351: token = os.environ.get("K")')"
_lgb_f_scan() { printf '%s\n' "$1" | "$FROOT/harness/bin/secret-scan" - >/dev/null 2>&1; printf 'rc=%s' "$?"; }
is  "in C, secret-scan exits 1 on a lookup followed by a Latin-1 byte and a key id, and 0 on a placeholder value holding the byte and on a lookup after it" \
    "$(_lgb_f_in C _lgb_f_scan "$LGB_F_S1") $(_lgb_f_in C _lgb_f_scan "$LGB_F_S2") $(_lgb_f_in C _lgb_f_scan "$LGB_F_S3")" "rc=1 rc=0 rc=0"
_lgb_f_u8 "in a UTF-8 locale with LC_ALL set, secret-scan still exits 1 on a lookup followed by a byte that is not UTF-8 and a key id" \
    all  "rc=1" _lgb_f_scan "$LGB_F_S1"
_lgb_f_u8 "in a UTF-8 locale with LANG set and LC_ALL unset, secret-scan still exits 1 on that lookup, byte and key id" \
    lang "rc=1" _lgb_f_scan "$LGB_F_S1"
_lgb_f_u8 "in a UTF-8 locale, secret-scan still exits 0 on a placeholder password value that holds a byte that is not UTF-8" \
    all  "rc=0" _lgb_f_scan "$LGB_F_S2"
_lgb_f_u8 "in a UTF-8 locale, secret-scan still exits 0 on a token lookup that follows a byte that is not UTF-8 on its line" \
    all  "rc=0" _lgb_f_scan "$LGB_F_S3"

# G6 (Rule 1). _felix_overnight_sid_ok's `[!A-Za-z0-9._-]` collates: under
# UTF-8 an e-acute sits inside A-Za-z, so a payload's session id `caf\303\251`
# was taken for a usable file name.
_lgb_f_sid() {
  ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/overnight.sh"
    _felix_overnight_sid_ok "$LGB_F_CAFE"; printf '%s' "$?"
    _felix_overnight_sid_ok cafe; printf ' %s' "$?" ) </dev/null 2>/dev/null
}
is  "in C, _felix_overnight_sid_ok refuses a session id ending in an e-acute and accepts cafe" "$(_lgb_f_in C _lgb_f_sid)" "1 0"
_lgb_f_u8 "in a UTF-8 locale with LC_ALL set, _felix_overnight_sid_ok still refuses a session id ending in an e-acute, as in C" all  "1 0" _lgb_f_sid
_lgb_f_u8 "in a UTF-8 locale with LANG set and LC_ALL unset, _felix_overnight_sid_ok still refuses that session id" lang "1 0" _lgb_f_sid

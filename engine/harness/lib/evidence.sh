# Evidence policy.
#
# The guidebook's table on p7 says what a change must prove before it counts as
# done: code needs tests, a schema change needs database tests, user-facing
# behaviour needs browser coverage, a bug fix needs a regression test that failed
# before the fix. None of it was enforced, so a comment edit and a schema
# migration were gated identically.
#
# What is checkable here is narrow and deliberately so: this diff touched X and
# did not touch Y. That is a heuristic about coverage, not proof of it. A test
# file being edited says nothing about whether the test is any good. What it does
# catch is the common and consequential case, changing behaviour and shipping no
# test at all, which is the failure the table exists to prevent.
#
# Reports by default and exits 0. `--strict` exits non-zero so CI can gate on it.
# Defaulting to hard failure would have blocked legitimate work on day one, and
# a gate that has to be routinely bypassed teaches people to bypass gates.
#
# evidence.tsv rows: name <TAB> when-regex <TAB> requires-regex <TAB> reason
#
# A row this cannot judge is `unknown`, never n/a and never a pass: a cell grep
# cannot compile, a row that is not four non-empty cells, a table that exists
# and cannot be read. n/a is a claim about the diff, and a row that was never
# read cannot make it. (Audit b11: a `when` of `^(src|lib/` read n/a for every
# change under src/, and the merge threw grep's complaint away.) The reason of
# every such line says `not judged`, which is how a caller tells it from the two
# whole-scan unknowns below, whose reason says `no rule was consulted` and whose
# line, for a base name that holds a newline, is not even one line. So does the
# one line for a project.json the check cannot read, for paths it could not set
# aside, or for a changed name holding a newline (round 3, B11R3-8, B11R3-9 and
# B11R3-14), since each stands for every row.

# felix_changed_paths lives in resolve.sh, which every hook and the CLI source
# first. Sourced here too rather than assumed: a lib whose helper is missing
# returns an empty path list, which reads as "nothing changed" and silently
# stops enforcing. That is the same shape as a test that is green because it
# cannot reach the branch it names, and it cost 15 assertions to notice.
if ! command -v felix_changed_paths >/dev/null 2>&1; then
  . "$(dirname "${BASH_SOURCE[0]:-$0}")/resolve.sh"
fi

# Vendored code. A dependency's code ships without its tests (`go mod vendor`
# drops _test.go), so a rule that reads a bump fires on code nobody here can
# write a test for, and felix merge refuses the bump (audit b11, M2). A cell is
# a grep pattern and cannot say "not under a directory", so the engine sets
# such paths aside before any row reads them. Round 2 did that by name, every
# vendor, third_party or node_modules directory at any depth, which also set
# aside the project's own code under src/vendor/ and said nothing. Round 3
# (b11-round-3.md) sets aside only what project.json declares, or vendor/ under
# a go.mod the base holds at the root, and the verdict counts what it set
# aside. A vendor-named path still never meets a `requires` cell, since a
# dependency's test proves nothing of the project's code (B11R3-4): that half
# only makes a verdict stricter.

# Where PROJ sits in ROOT's tree, by identity and never by spelling (B11R3-13).
# 0 with the path the repository records for it ("" for ROOT itself) when PROJ,
# or a directory above it, is the same directory as ROOT as [ -ef ] decides; 1
# when none is; 2 when that cannot be told. A string from `pwd -P` keeps the
# case it was typed in, a leading //, a firmlink's /System/Volumes/Data, so two
# spellings of one directory failed a prefix test, and project.json was read
# from the working tree the change wrote. Each name below ROOT is the entry of
# its parent that is the same directory, so the case typed is never the one read.
_felix_evidence_where() {   # PROJ ROOT
  local r
  r="$(CDPATH='' cd -P -- "${2:-.}" 2>/dev/null && pwd -P)" && [ -n "$r" ] || return 2
  ( CDPATH=''; cd -P -- "$1" 2>/dev/null || exit 2
    s="$(pwd -P)" && [ -n "$s" ] || exit 2
    k=0
    while ! [ . -ef "$r" ]; do
      ! [ . -ef .. ] || exit 1
      cd -P .. 2>/dev/null || exit 2
      k=$((k + 1))
    done
    cd -P -- "$s" 2>/dev/null || exit 2
    shopt -u failglob nullglob 2>/dev/null; unset GLOBIGNORE
    rel=""
    while [ "$k" -gt 0 ]; do
      n=""
      for e in ../* ../.[!.]* ../..?*; do
        if [ ! -L "$e" ] && [ "$e" -ef . ]; then n="${e#../}"; break; fi
      done
      [ -n "$n" ] && cd -P .. 2>/dev/null || exit 2
      rel="$n${rel:+/$rel}"; k=$((k - 1))
    done
    printf '%s' "$rel" )
}

# project.json's text as the check reads it: at the base when the project
# directory is the repository's top or below it, so a change neither grants nor
# revokes its own set-aside, and from the disk otherwise (B11R3-5). ROOT is the
# top, as every caller passes it. Nothing printed is nothing declared. A file
# that is there and cannot be read exits 1 with the reason (B11R3-8 a and f),
# and so does a project directory no one can place (B11R3-13).
_felix_evidence_pj() {   # PROJ BASE ROOT
  local pj="$1/project.json" rel rc=0 sha ent text
  local why="so its evidence_vendored and evidence_reads_vendored are unknown and the rules were not judged"
  rel="$(_felix_evidence_where "$1" "$3")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    printf 'it could not be told whether the project directory is inside the repository, %s' "$why"; return 1
  fi
  if [ "$rc" -eq 0 ]; then
    rel="${rel:+$rel/}project.json"
    # An empty base is HEAD, and an unborn HEAD has committed nothing to declare.
    if ! sha="$(git -C "$3" rev-parse -q --verify "${2:-HEAD}^{commit}" 2>/dev/null)"; then
      [ -n "$2" ] || return 0
      printf 'git could not read project.json at the base, %s' "$why"; return 1
    fi
    ent="$(git --literal-pathspecs -C "$3" ls-tree --full-tree "$sha" -- "$rel" 2>/dev/null)" \
      || { printf 'git could not read project.json at the base, %s' "$why"; return 1; }
    [ -n "$ent" ] || return 0
    case "$ent" in
      "100644 blob "*|"100755 blob "*) ;;
      *) printf 'project.json is not a regular file at the base, %s' "$why"; return 1 ;;
    esac
    ent="${ent#* blob }"; ent="${ent%%$'\t'*}"
    text="$(git -C "$3" cat-file blob "$ent" 2>/dev/null)" \
      || { printf 'git could not read project.json at the base, %s' "$why"; return 1; }
  else
    [ -e "$pj" ] || [ -L "$pj" ] || return 0
    [ -f "$pj" ] || { printf 'project.json is not a regular file, %s' "$why"; return 1; }
    { [ -r "$pj" ] && text="$(cat "$pj" 2>/dev/null)"; } || { printf 'project.json cannot be read, %s' "$why"; return 1; }
  fi
  printf '%s' "$text"
}

# The two keys of project.json's TEXT, read by line as felix_json_str reads it,
# one line each, evidence_vendored first: `=VALUE` for one JSON string or for
# no key, `!twice` for a key given more than once, `!string` for a value that is
# not one string on the key's line (B11R3-8 b and c). A key alone at the end of
# its line has its value on another, which no reader here takes.
_felix_evidence_keys() {   # TEXT
  LC_ALL=C awk '
    BEGIN { k[1] = "\"evidence_vendored\""; k[2] = "\"evidence_reads_vendored\"" }
    { for (q = 1; q <= 2; q++) {
        s = $0
        while ((i = index(s, k[q])) > 0) {
          s = substr(s, i + length(k[q]))
          if (s ~ /^[ \t\r]*$/) { n[q]++; bad[q] = 1; continue }
          if (!match(s, /^[ \t\r]*:/)) continue
          n[q]++; v = substr(s, RLENGTH + 1); sub(/^[ \t\r]*/, "", v)
          j = 0
          if (substr(v, 1, 1) == "\"") j = index(substr(v, 2), "\"")
          if (j == 0) { bad[q] = 1; continue }
          val[q] = substr(v, 2, j - 1)
          if (val[q] ~ /[\t\r]/ || substr(v, j + 2) !~ /^[ \t\r]*([,}]|$)/) bad[q] = 1
        }
      }
    }
    END { for (q = 1; q <= 2; q++) { r = "=" val[q]; if (bad[q]) r = "!string"; if (n[q] > 1) r = "!twice"; print r } }
  ' <<<"$1"
}

# evidence_vendored's VALUE as its entries, each ending in one /, separated by
# single spaces, in its order: `=ENTRIES`; or `!ENTRY WHY` for the first entry
# that is not a plain directory under the root (B11R3-2, B11R3-8 d). An entry
# is compared byte for byte, never as a pattern, so nothing here may read as one.
_felix_evidence_dirs() {   # VALUE
  LC_ALL=C awk '
    { n = split($0, tok, " ")
      for (i = 1; i <= n && why == ""; i++) {
        e = tok[i]; d = e; sub(/\/$/, "", d)
        if (substr(e, 1, 1) == "/") why = "begins with /"
        else if (d ~ "[^A-Za-z0-9._@+/-]") why = "holds a character other than a letter, a digit or . _ - @ +"
        else {
          m = split(d, c, "/")
          for (j = 1; j <= m && why == ""; j++)
            if (c[j] == "") why = "has an empty component"
            else if (c[j] == "." || c[j] == "..") why = "has a . or .. component"
        }
        if (why != "") print "!" e " " why
        else out = out (out == "" ? "" : " ") d "/"
      }
    }
    END { if (why == "") print "=" out }
  ' <<<"$1"
}

# What PROJ declares, as two lines: the entries _felix_evidence_dirs gives, and
# the rows that read every path (B11R3-7), separated by single spaces as
# listed. Exits 1 with the reason when the declaration cannot be read, and the
# caller then prints one unknown for project.json and no row (B11R3-8).
_felix_evidence_declared() {   # PROJ BASE ROOT
  local text keys v tok ents="" opted="" names
  text="$(_felix_evidence_pj "$1" "$2" "$3")" || { printf '%s' "$text"; return 1; }
  case "$text" in *'"evidence_vendored"'*|*'"evidence_reads_vendored"'*) ;; *) return 0 ;; esac
  keys="$(_felix_evidence_keys "$text")" \
    || { printf 'project.json could not be read for its keys, so the rules were not judged'; return 1; }
  for tok in evidence_vendored evidence_reads_vendored; do
    v="${keys%%$'\n'*}"; keys="${keys#*$'\n'}"
    case "$v" in
      '!twice') printf 'project.json gives %s more than once, so the rules were not judged' "$tok"; return 1 ;;
      '!string') printf "project.json's %s is not one JSON string, so the rules were not judged" "$tok"; return 1 ;;
    esac
    [ "$tok" = evidence_vendored ] || { opted="${v#=}"; continue; }
    ents="$(_felix_evidence_dirs "${v#=}")" \
      || { printf 'project.json could not be read for its evidence_vendored entries, so the rules were not judged'; return 1; }
    case "$ents" in '!'*) printf "project.json's evidence_vendored entry %s, so the rules were not judged" "${ents#!}"; return 1 ;; esac
    ents="${ents#=}"
  done
  if [ -n "${opted// /}" ]; then
    [ -f "$1/evidence.tsv" ] \
      && names="$(LC_ALL=C awk -F'\t' '/^[ \t\r]*#/ || /^[ \t\r]*$/ { next } { print $1 }' "$1/evidence.tsv" 2>/dev/null)" \
      || { printf 'evidence.tsv could not be read for its row names, so the rules were not judged'; return 1; }
    v="$opted"; opted=""
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      case $'\n'"$names"$'\n' in
        *$'\n'"$tok"$'\n'*) opted="${opted:+$opted }$tok" ;;
        *) printf "project.json's evidence_reads_vendored names %s, which is no row of evidence.tsv, so the rules were not judged" "$tok"
           return 1 ;;
      esac
    done <<<"${v// /$'\n'}"
  else
    opted=""
  fi
  printf '%s\n%s' "$ents" "$opted"
}

# 0 when BASE (HEAD with none) holds a go.mod at the root of its tree; 1 when
# it does not, or git cannot tell (B11R3-3). A go.mod the change adds, or a
# nested one, is not read.
_felix_evidence_gomod() {   # ROOT BASE
  local sha ent
  sha="$(git -C "$1" rev-parse -q --verify "${2:-HEAD}^{commit}" 2>/dev/null)" || return 1
  ent="$(git -C "$1" ls-tree --full-tree "$sha" -- go.mod 2>/dev/null)" || return 1
  case "$ent" in *" blob "*) return 0 ;; esac
  return 1
}

# PATHS as a cell of a row that has not opted in reads them: WHICH `when` is
# without what is set aside, `requires` without that and every vendor-named
# path too (B11R3-4). `count` prints `N<TAB>DIRS` instead: how many paths were
# set aside, and the directories that set one aside, in ENTRIES' order and then
# vendor/ for GO (B11R3-6); a path two entries cover counts under the first.
# ENTRIES each end in one /; GO is 1 for vendor/ under a go.mod at the root.
_felix_evidence_aside() {   # PATHS ENTRIES GO when|requires|count
  LC_ALL=C awk -v ents="$2" -v go="$3" -v want="$4" '
    BEGIN { ne = split(ents, ent, " ") }
    $0 == "" { next }
    { hit = 0
      for (i = 1; i <= ne && !hit; i++) if (substr($0, 1, length(ent[i])) == ent[i]) hit = i
      if (!hit && go == 1 && substr($0, 1, 7) == "vendor/") hit = ne + 1
      if (hit) { n++; used[hit] = 1; next }
      if (want == "when" || (want == "requires" && $0 !~ /(^|\/)(vendor|third_party|node_modules)\//)) print
    }
    END {
      if (want != "count") exit 0
      for (i = 1; i <= ne + 1; i++) if (used[i]) dirs = dirs (dirs == "" ? "" : " ") (i > ne ? "vendor/" : ent[i])
      printf "%d\t%s\n", n, dirs
    }
  ' <<<"$1"
}

# PATHS as felix_changed_paths gives them, each read back as the bytes of its
# name (B11R3-14). git quotes a name holding a double quote, a backslash, a
# control character or (unless core.quotePath is false) a byte above 127, as
# "src/caf\303\251.go", and a cell that reads that has not read src/café.go:
# own code read n/a on every row. Exits 3 when a name holds a newline, which
# would read as two paths (`z<NL>tests/z_test.go` would meet a test row), and 2
# on a spelling git does not write.
_felix_evidence_bytes() {   # PATHS
  case $'\n'"$1" in *$'\n"'*) ;; *) printf '%s\n' "$1"; return 0 ;; esac
  LC_ALL=C awk '
    BEGIN { e["a"] = 7; e["b"] = 8; e["t"] = 9; e["n"] = 10; e["v"] = 11; e["f"] = 12; e["r"] = 13; e["\""] = 34; e["\\"] = 92 }
    substr($0, 1, 1) != "\"" { print; next }
    { s = substr($0, 2); o = ""
      for (;;) {
        i = index(s, "\\"); j = index(s, "\"")
        if (j > 0 && (i == 0 || j < i)) break
        if (i == 0) { st = 2; exit }
        o = o substr(s, 1, i - 1); c = substr(s, i + 1, 1)
        if (c ~ /^[0-3]$/ && substr(s, i + 2, 2) ~ /^[0-7][0-7]$/) {
          o = o sprintf("%c", c * 64 + substr(s, i + 2, 1) * 8 + substr(s, i + 3, 1)); s = substr(s, i + 4)
        } else if (c in e) { o = o sprintf("%c", e[c]); s = substr(s, i + 2) }
        else { st = 2; exit }
      }
      if (substr(s, j + 1) != "") { st = 2; exit }
      o = o substr(s, 1, j - 1)
      if (index(o, "\n") > 0) { st = 3; exit }
      print o
    }
    END { exit st }
  ' <<<"$1"
}

# Every row of PROJ's evidence.tsv as five lines, so no cell is split by a read
# that collapses empty ones: `ok`, name, when, requires, reason for four
# non-empty cells set apart by tabs; `bad`, name, why, -, - for any other row.
# A row with no first cell is named evidence.tsv:N, N its line in the file with
# comments and blank lines counted.
_felix_evidence_rows() {
  LC_ALL=C awk -F'\t' '
    /^[ \t\r]*#/ || /^[ \t\r]*$/ { next }
    NF == 4 && $1 != "" && $2 != "" && $3 != "" && $4 != "" { print "ok"; print $1; print $2; print $3; print $4; next }
    { print "bad"; print ($1 != "" ? $1 : "evidence.tsv:" NR)
      print "this row is not four non-empty cells set apart by tabs (it has " NF "), so its cells were not judged"
      print "-"; print "-" }
  ' "$1/evidence.tsv"
}

# 0 when some path of the list PATHS matches PATTERN, 1 when none does, 2 when
# grep could not read the pattern. A here-string and not a pipe, because grep -q
# quits at the first match and pipefail reads the printf it cut off as none.
_felix_any_match() {
  local rc
  [ -n "$1" ] || return 1
  LC_ALL=C grep -qE -e "$2" <<<"$1"; rc=$?
  [ "$rc" -le 1 ] && return "$rc"
  return 2
}

# Whether grep can read CELL as a pattern: an exit above 1 is a pattern it
# cannot, and its own complaint is printed, a line, for the reason of the row.
_felix_evidence_cell() {
  local out rc
  out="$(LC_ALL=C grep -E -e "$1" </dev/null 2>&1)"; rc=$?
  [ "$rc" -gt 1 ] || return 0
  printf 'grep exit %s: %s' "$rc" "$(printf '%s' "$out" | LC_ALL=C tr '\t\n' '  ')"
  return 1
}

# One line of a verdict: the check's `status<TAB>name<TAB>reason`, or the brief's
# `name<TAB>reason`, which says nothing of a row this change does not reach.
_felix_evidence_say() {   # MODE STATUS NAME REASON
  case "$1" in
    check) printf '%s\t%s\t%s\n' "$2" "$3" "$4" ;;
    *)     [ "$2" = "n/a" ] || printf '%s\t%s\n' "$3" "$4" ;;
  esac
}

# 0 when anything stands at PROJ's evidence.tsv, 1 when nothing does. A regular
# file, a directory, a link that resolves, a link that dangles and a FIFO all
# stand; only a path where `-e` and `-L` are both false is not there. It reads
# nothing and prints nothing.
#
# This is the one place that question is asked. The judge asks it before it says
# anything, and every command that reads the table's verdict asks it before it
# calls the judge, because a reader that tested `-f` instead said "no evidence
# is owed" for a path the judge, and so `felix merge`, called unreadable: a
# directory, a dangling link and a FIFO read as no table to felix classify,
# felix receipt, felix evidence and felix incident, and as an `evidence`
# blocker to felix merge (found reviewing #482, 2026-11-05).
felix_evidence_table_present() {   # PROJ
  [ -e "$1/evidence.tsv" ] || [ -L "$1/evidence.tsv" ]
}

# Every row of PROJ's table read against PATHS, in file order, one line each.
# MODE check judges met, gap or n/a; MODE brief asks only whether a row's `when`
# reaches PATHS, because there is no diff yet and so nothing to have proved. A
# row it cannot judge is unknown in both, whatever PATHS holds. No table is
# nothing to say (schemas.tsv allows it); a table that is there and cannot be
# read is one unknown line, since silence would read as "no rules declared".
#
# The check, given BASE and ROOT, sets aside what project.json declares
# vendored and says how many paths it set aside in one n/a line, VENDORED,
# after the last row's; the brief reads every path it is given and never reads
# project.json (round 3, B11R3-6 and B11R3-11).
_felix_evidence_judge() {   # PROJ PATHS check|brief [BASE ROOT]
  local proj="$1" paths="$2" mode="$3" rows kind name when requires reason why rc status
  local wpaths="$2" rpaths="$2" wp rp decl ents="" opted="" go=0 vend=0 aside=0 n
  felix_evidence_table_present "$proj" || return 0
  if [ ! -f "$proj/evidence.tsv" ] || [ ! -r "$proj/evidence.tsv" ] || ! rows="$(_felix_evidence_rows "$proj" 2>/dev/null)"; then
    _felix_evidence_say "$mode" unknown evidence.tsv "evidence.tsv exists but cannot be read, so its rules were not judged"
    return 0
  fi
  if [ "$mode" = check ]; then
    # A declaration the check cannot read is not an empty one (B11R3-8).
    if ! decl="$(_felix_evidence_declared "$proj" "${4:-}" "${5:-}")"; then
      _felix_evidence_say check unknown project.json "${decl:-project.json could not be read, so the rules were not judged}"
      return 0
    fi
    ents="${decl%%$'\n'*}"
    case "$decl" in *$'\n'*) opted="${decl#*$'\n'}" ;; esac
    # Each changed path as its own bytes, never as git quotes it (B11R3-14).
    rc=0; paths="$(_felix_evidence_bytes "$paths")" || rc=$?
    if [ "$rc" -ne 0 ]; then
      why="git's spelling of a changed path could not be read back as its name"
      [ "$rc" -ne 3 ] || why="a changed path's name holds a newline, which would read as two paths"
      _felix_evidence_say check unknown CHANGED-PATHS "$why, so the rules were not judged"
      return 0
    fi
    wpaths="$paths"; rpaths="$paths"
    case $'\n'"$paths" in *$'\n'vendor/*) ! _felix_evidence_gomod "${5:-}" "${4:-}" || go=1 ;; esac
    case "$paths" in *vendor/*|*third_party/*|*node_modules/*) vend=1 ;; esac
    if [ -n "$ents" ] || [ "$go" -eq 1 ]; then
      vend=1
      wpaths="$(_felix_evidence_aside "$paths" "$ents" "$go" when)" || aside=""
      [ -z "$aside" ] || aside="$(_felix_evidence_aside "$paths" "$ents" "$go" count)" || aside=""
    fi
    if [ -n "$aside" ] && [ "$vend" -eq 1 ]; then
      rpaths="$(_felix_evidence_aside "$paths" "$ents" "$go" requires)" || aside=""
    fi
    # B11R3-9: a list a tool broke off would read a set-aside path as the
    # project's, or the project's as set aside. Round 2 named this CHANGED-PATHS.
    if [ -z "$aside" ]; then
      _felix_evidence_say check unknown VENDORED "a tool failed while the vendored paths were set aside, so the rules were not judged"
      return 0
    fi
  fi
  while IFS= read -r kind && IFS= read -r name && IFS= read -r when && IFS= read -r requires && IFS= read -r reason; do
    if [ "$kind" != ok ]; then _felix_evidence_say "$mode" unknown "$name" "$when"; continue; fi
    status=unknown
    # A row named in evidence_reads_vendored reads every path in both cells (B11R3-7).
    wp="$wpaths"; rp="$rpaths"
    case $'\n'"${opted// /$'\n'}"$'\n' in *$'\n'"$name"$'\n'*) wp="$paths"; rp="$paths" ;; esac
    if ! why="$(_felix_evidence_cell "$when")"; then
      reason="the when cell does not compile ($why), so this row was not judged"
    elif ! why="$(_felix_evidence_cell "$requires")"; then
      reason="the requires cell does not compile ($why), so this row was not judged"
    else
      _felix_any_match "$wp" "$when"; rc=$?
      if [ "$rc" -eq 1 ]; then status="n/a"; reason="this change does not touch that surface"
      elif [ "$rc" -ne 0 ]; then reason="grep could not match the when cell (exit $rc), so this row was not judged"
      elif [ "$mode" != check ]; then status=met
      else
        _felix_any_match "$rp" "$requires"; rc=$?
        case "$rc" in
          0) status=met ;;
          1) status=gap ;;
          *) reason="grep could not match the requires cell (exit $rc), so this row was not judged" ;;
        esac
      fi
    fi
    _felix_evidence_say "$mode" "$status" "$name" "$reason"
  done <<EOF
$rows
EOF
  # B11R3-6: how much was set aside, after the last row's line, and never at 0.
  n="${aside%%$'\t'*}"
  [ "$mode" = check ] && [ "${n:-0}" != 0 ] || return 0
  if [ -n "$opted" ]; then why="so only $opted read them"; else why="so no rule read them"; fi
  printf 'n/a\tVENDORED\t%s changed path(s) set aside as vendored, under %s, %s\n' "$n" "${aside#*$'\t'}" "$why"
}

# Emits: status <TAB> name <TAB> reason.  status is met | gap | n/a | unknown
felix_evidence_check() {
  local proj="$1" base="$2" root="$3"
  local paths

  # Before any row, because `n/a` is a claim about the diff — "this change does
  # not touch that surface" — and a base git cannot name produces no diff to
  # make it about. felix_changed_paths sends git's exit-128 to /dev/null, so
  # every row fell to n/a and the command signed off with "No evidence gaps."
  # #56 closed this on the merge path; this is the same emptiness read one
  # layer up, where a person reads it.
  #
  # One row, not one per rule. The rules were never consulted, so reporting
  # each of them as unknown would imply they were each considered and found
  # unanswerable. Nothing was considered.
  #
  # A git that could not run is not a base that names nothing (2026-11-14), and
  # its row is named GIT, as a change git could not read is CHANGED-PATHS, so a
  # caller tells the two apart by name and never by the reason's words.
  if [ -n "$base" ]; then
    local brc=0 gwhy=""
    felix_base_resolves "$root" "$base" gwhy || brc=$?
    case "$brc" in
      0) ;;
      2) printf 'unknown\tGIT\t%s, so the base %s was not looked up and no rule was consulted\n' "$gwhy" "$base"
         return 0 ;;
      *) printf 'unknown\t%s\tthis base names nothing here, so no rule was consulted\n' "$(felix_base_subject "$base")"
         return 0 ;;
    esac
  fi

  # The same one row when git could not list the change to the end (2026-10-08).
  # A list it broke off would read every rule it missed as n/a, which is the
  # claim "this change does not touch that surface" about paths never seen.
  # Named CHANGED-PATHS, as escape.sh names it, so a caller can tell it from a
  # base that names nothing, and it carries git's reason.
  if ! paths="$(felix_changed_paths "$root" "$base")"; then
    printf 'unknown\tCHANGED-PATHS\tgit could not list every path this change touches (%s), so no rule was consulted\n' \
      "$(felix_change_why "$root" "$base")"
    return 0
  fi

  _felix_evidence_judge "$proj" "$paths" check "$base" "$root"
  return 0
}

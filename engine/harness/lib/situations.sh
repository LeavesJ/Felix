# felix situations: the entry, its flags, the situation table and the ids (slice 1 of the capability lane; the design is
# docs/2026-10-29-capability-lane-first-slices-design.md section 7, the contracts C1 to C16 of
# docs/2026-10-29-lane-slice-1-plan.md, with the amendments of C17, 2026-11-05).
#
# WHAT IT DOES. It says which situation rows a project owes, for a recorded tree (--at) or for a change (--change): the
# rows the change brings in, blinds and retires, the rows already standing, and what could not be looked at. Report-only:
# no model, no key, no network, and nothing is written outside one scratch directory under ${TMPDIR:-/tmp}, which is
# removed before the report is printed.
#
# HOW IT IS LOADED. cmd_situations in felix sources this file and its three siblings inside its own body, the way cmd_audit,
# cmd_inventory and cmd_cost load theirs, so felix gate, felix merge and felix land never parse or run any of it. Nothing
# in these four files runs when it is sourced: they define functions and set nothing.
#
#   lib/situations.sh         this file: felix_situations (flags, project, table, scratch, the run), the table reader,
#                             the ids, and the evaluation of every class at one reading (C4, C7, C10)
#   lib/situations-read.sh    one side read: the scratch directory, the recorded readings of facts.log, and the detector
#                             at the live tree
#   lib/situations-report.sh  the human report, the --tsv form, the --propose drafts
#   lib/situations-check.sh   what every step shares so that none fails unseen (C17.4): its sentence, the project tables, the
#                             detector captured, and the environment git runs in for a scratch clone (C17.2)
#
# THE ORDER OF A RUN (C2). Usage errors first, then the governing project, then the situation table, then the scratch
# directory, then the rest. The first check that fails is the one line printed. The status is 2 for a usage error or a
# directory no project governs, 1 for a flag with no value (need_value), and 3 for a table, a scratch directory, a side or
# a step of the report that could not be read or built, or a stdout that refused the report (C17.4), with one line on stderr
# and nothing on stdout.

# One usage error: the status is 2 and the first stderr line begins felix: usage: felix situations. ARG is the argument
# that failed, as given.
_felix_situations_usage() {   # ARG
  die "usage: felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (got: ${1-})" 2
}

# Status 0 when $1 is a range as C1 defines it: split at its first .., neither half empty, no ... anywhere, and no .. in
# the head half. HEAD~1..HEAD, main..HEAD and v1.2..v1.3 are ranges; main alone is not.
_felix_situations_range_ok() {   # RANGE
  local r="${1-}" b h
  case "$r" in *..*) ;; *) return 1 ;; esac
  case "$r" in *...*) return 1 ;; esac
  b="${r%%..*}"; h="${r#*..}"
  [ -n "$b" ] && [ -n "$h" ] || return 1
  case "$h" in *..*) return 1 ;; esac
  return 0
}

# The situation table (C2, C12): prints its rows verbatim, in file order, and returns 0. A row is a line that does not
# match ^[[:space:]]*(#|$) in the C locale, a last line with no newline included; its cells are split at each tab, and
# nothing is trimmed. Returns 3 with "<file>: <why>" on stderr and nothing on stdout when the file cannot be read or its
# first failing line breaks a rule, the first reason in C2's order that fits that line:
#   it is absent or unreadable | it holds no row | line N: K fields where a row has 5 | line N: cell K is empty
#   | line N: class 'C' is not [a-z][a-z0-9_]* | line N: class 'C' appears twice | line N: applies holds no term
#   | line N: class_by_maturity 'V' does not name each of ... | line N: source 'V' is not miss:, candidate: or cite: ...
# N is the physical line number, comments and blank lines counted. The rules C12 adds beyond this list are checked of the
# shipped seed by part 2400 and are not refused here: a term in another form is unbound at run time, and a cell that
# decreases with maturity is printed as written.
felix_situations_table() {   # FILE
  local f="${1-}" out rc=0
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf '%s: it is absent or unreadable\n' "$f" >&2
    return 3
  fi
  out="$(LC_ALL=C awk -F'\t' '
    function fail(why) { msg = "line " NR ": " why; failed = 1; exit }
    BEGIN {
      SQ = "\047"
      split("INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING", cls, " ")
      for (i = 1; i <= 5; i++) CLS[cls[i]] = 1
      split("prototype internal public-beta production", mat, " ")
      for (i = 1; i <= 4; i++) MAT[mat[i]] = 1
    }
    /^[[:space:]]*(#|$)/ { next }
    {
      rows++
      if (NF != 5) fail(NF " fields where a row has 5")
      for (k = 1; k <= 5; k++) if ($k == "") fail("cell " k " is empty")
      if ($1 !~ /^[a-z][a-z0-9_]*$/) fail("class " SQ $1 SQ " is not [a-z][a-z0-9_]*")
      if ($1 in SEEN) fail("class " SQ $1 SQ " appears twice")
      SEEN[$1] = 1
      nt = split($2, tm, / +/); terms = 0
      for (i = 1; i <= nt; i++) if (tm[i] != "") terms++
      if (terms == 0) fail("applies holds no term")
      np = split($4, pr, ","); good = (np == 4); split("", got)
      for (i = 1; i <= np; i++) {
        e = index(pr[i], "=")
        if (e < 2) { good = 0; continue }
        m = substr(pr[i], 1, e - 1); c = substr(pr[i], e + 1)
        if (!(m in MAT) || (m in got) || !(c in CLS)) good = 0
        got[m] = 1
      }
      if (!good) fail("class_by_maturity " SQ $4 SQ " does not name each of prototype internal public-beta production once with a class of INFO ADVISORY TASK_BLOCKING RELEASE_BLOCKING AUTHORITY_BLOCKING")
      e = index($5, ":"); kind = substr($5, 1, e - 1); hex = substr($5, e + 1)
      good = (e > 0 && (kind == "miss" || kind == "candidate" || kind == "cite") && length(hex) == 12 && hex ~ /^[0-9a-f]+$/)
      if (!good) fail("source " SQ $5 SQ " is not miss:, candidate: or cite: and 12 lowercase hex digits")
      R[rows] = $0
    }
    END {
      if (!failed && rows == 0) { msg = "it holds no row"; failed = 1 }
      if (failed) { print msg; exit 3 }
      for (i = 1; i <= rows; i++) print R[i]
    }' "$f")" || rc=$?
  case "$rc" in
    0) printf '%s\n' "$out" ;;
    3) printf '%s: %s\n' "$f" "$out" >&2; return 3 ;;
    *) printf '%s: it is absent or unreadable\n' "$f" >&2; return 3 ;;
  esac
}

# A class's id (C6): owed: and the first 12 hex digits that git hash-object --stdin prints for the bytes
# <class><TAB><project><TAB>* with no trailing newline, run from / with no repository, global or system configuration in
# reach. The same in --at, in --change and across runs: it holds neither a commit nor a tree. Returns 1 when either end of
# the pipe failed (pipefail, in the substitution's own shell, so a producer's status is kept) or git printed too little.
felix_situations_id() {   # CLASS PROJECT
  local h
  h="$( set -o pipefail
        printf '%s\t%s\t%s' "${1-}" "${2-}" '*' \
          | env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_COMMON_DIR \
              GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -C / hash-object --stdin 2>/dev/null )" || return 1
  [ "${#h}" -ge 12 ] || return 1
  printf 'owed:%s' "${h:0:12}"
}

# Every class of ROWS (the table's rows, a file) evaluated at one READING (a reading file, see lib/situations-read.sh) by the
# rules of C4, with PROBE-GROUNDS (the current probes.tsv's predicate and grounds cells, a file) and the declared MATURITY
# (project.json's string, empty when none). Prints, in this order for each class and then once for the run:
#   class      <class> <STATE> <grounds> <readings>|- <witness>|- <key>      one per class, in table order (C7); the key is
#                                                                           what C5 compares between two sides, one string
#   undecided  <class> <term> <reason>      after its class line, one per undecided term whatever the class's state; the
#                                           report names those of a class that is UNKNOWN (C10)
#   unbound    <term> <why>                 every term C4 lists as unbound, once for each class that holds it (C10)
#   seen       <capability> <source>        a capability no class uses that the detector named, or a probe row grounds (C10)
# A probe term is read from the grounding rows of its capability, one per predicate; a cap term the same, then the detector.
# A grounding row whose state is none of the five is undecided, as blind and unknown are, with its own state word in the
# reason (C17.6).
# No apostrophe may stand in the awk text: it is one shell word.
felix_situations_eval() {   # ROWS READING PROBE-GROUNDS MATURITY
  FELIX_SIT_ROWS="${1-}" FELIX_SIT_READING="${2-}" FELIX_SIT_GROUNDS="${3-}" FELIX_SIT_MATURITY="${4-}" LC_ALL=C awk '
    function isst(s) { return s == "found" || s == "empty" || s == "blind" || s == "unknown" || s == "not-applicable" }
    function mrank(m) {
      if (m == "prototype") return 1
      if (m == "internal") return 2
      if (m == "public-beta") return 3
      if (m == "production") return 4
      return 0
    }
    # Sets K to probe, cap, env (env:maturity with a value of the four), envother (another axis) or other; C and V to the
    # capability and the state or the value.
    function classify(t,   rest, e) {
      K = "other"; C = ""; V = ""
      if (substr(t, 1, 6) == "probe:") {
        rest = substr(t, 7); e = index(rest, "=")
        if (e > 1 && isst(substr(rest, e + 1))) { K = "probe"; C = substr(rest, 1, e - 1); V = substr(rest, e + 1) }
      } else if (substr(t, 1, 4) == "cap:") {
        if (length(t) > 4) { K = "cap"; C = substr(t, 5) }
      } else if (substr(t, 1, 4) == "env:") {
        rest = substr(t, 5); e = index(rest, ">=")
        if (e > 0) {
          if (substr(rest, 1, e - 1) != "maturity") K = "envother"
          else if (mrank(substr(rest, e + 2)) > 0) { K = "env"; V = substr(rest, e + 2) }
        }
      }
    }
    # The grounding rows of capability c: GI[1..NG] index the reading, one per predicate, its first row, in reading order.
    # UN[1..NU] are the predicates the current probes.tsv grounds at c that have no grounding row here, in probes.tsv order. A
    # grounds cell of - or empty grounds nothing.
    function ground(c,   i, j) {
      NG = 0; NU = 0; split("", SP); split("", SU)
      if (c == "" || c == "-") return
      for (i = 1; i <= np; i++)
        if (PG[i] == c && !(PP[i] in SP)) { SP[PP[i]] = 1; GI[++NG] = i }
      for (j = 1; j <= ng; j++)
        if (GG[j] == c && !(GP[j] in SP) && !(GP[j] in SU)) { SU[GP[j]] = 1; UN[++NU] = GP[j] }
    }
    function items(skipna,   k, i, s, sep) {
      s = ""
      for (k = 1; k <= NG; k++) {
        i = GI[k]
        if (skipna && PS[i] == "not-applicable") continue
        sep = (s == "") ? "" : ", "
        s = s sep PP[i] " " PS[i] " (" TC ")"
      }
      for (k = 1; k <= NU; k++) { sep = (s == "") ? "" : ", "; s = s sep UN[k] " no reading (" TC ")" }
      return s
    }
    function blindwhy(i) {
      return PP[i] " read " PS[i] ((HOW == "recorded") ? " when recorded; the fact log keeps no sentence" : ": " PD[i])
    }
    function badmat() { return "project.json declares maturity " SQ MAT SQ ", which is not one of prototype internal public-beta production" }
    # One term at the reading. Sets TS (T, F or U), TG (its grounds item), TY (the reason when U), TW (its witness when F), TK
    # (its part of the comparison key), and appends to the class readings RD.
    function evalterm(t,   k, i, fo, bu, em, any, bi, ei, ans) {
      classify(t)
      TS = "U"; TG = ""; TY = ""; TW = ""; TK = "o"
      if (K == "probe" || K == "cap") {
        TC = C; ground(C); fo = 0; bu = 0; em = 0; any = 0; bi = 0; ei = 0
        TK = (K == "probe") ? "p" : "c"
        for (k = 1; k <= NG; k++) {
          i = GI[k]
          TK = TK ";" PP[i] "=" PS[i] "/" PC[i]
          if (!(PP[i] in RDS)) { RDS[PP[i]] = 1; RD = RD ((RD == "") ? "" : " ") PP[i] "=" PS[i] "/" PC[i] }
          if (PS[i] == "found") fo++
          if (PS[i] == "blind" || PS[i] == "unknown" || !isst(PS[i])) { bu++; if (!bi) bi = i }
          if (PS[i] == "empty") { em++; if (!ei) ei = i }
          if (K == "probe" && PS[i] == V) any = 1
        }
        if (K == "probe") {
          if (any) TS = "T"
          else if (bu > 0 || NU > 0 || NG == 0) TS = "U"
          else { TS = "F"; TW = (em > 0) ? PP[ei] " empty" : PP[GI[1]] " " PS[GI[1]] }
          TG = items(0)
          if (TG == "") TG = C " no probe"
          if (TS == "U") TY = (bu > 0) ? blindwhy(bi) : (NU > 0) ? "no reading of " UN[1] " on this side" : "no probe grounds " C
        } else {
          if (fo > 0) TS = "T"
          else if (bu > 0 || NU > 0) TS = "U"
          else if (em > 0) { TS = "F"; TW = PP[ei] " empty" }
          else {
            ans = (DET == "run") ? ((C in DCAP) ? "names" : "silent") : "notrun"
            TK = TK "@" ans
            if (ans == "names") TS = "T"
            else TY = ((NG == 0) ? "no probe grounds " C : "every probe grounding " C " is not-applicable") " and " ((ans == "silent") ? "the detector does not name it" : (DET == "no-tree") ? "the detector was not run: the tree id of this checkout could not be taken" : "the detector was not run: this checkout is not at this tree")
          }
          TG = items(1)
          if (TG == "") TG = C " " ((ans == "names") ? "detected" : (ans == "silent") ? "not detected" : "detector not run")
          if (TS == "U" && TY == "") TY = (bu > 0) ? blindwhy(bi) : "no reading of " UN[1] " on this side"
        }
      } else if (K == "env") {
        if (MAT == "") { TG = "maturity undeclared"; TY = "project.json declares no maturity" }
        else if (mrank(MAT) == 0) { TG = "maturity " MAT; TY = badmat() }
        else { TG = "maturity " MAT; TS = (mrank(MAT) >= mrank(V)) ? "T" : "F" }
      } else {
        TG = t " unbound"; TY = "not a term this slice can evaluate"
      }
    }
    # Why the term just classified is unbound, or empty when it is bound (C4, C10).
    function unboundwhy() {
      if (K == "probe") return (C in GCAP) ? "" : "no row of probes.tsv grounds " C
      if (K == "cap") return ""
      if (K == "env") return (MAT == "") ? "project.json declares no maturity" : (mrank(MAT) == 0) ? badmat() : ""
      if (K == "envother") return "only env:maturity can be evaluated in this slice"
      return "not a term this slice can evaluate"
    }
    BEGIN {
      SQ = "\047"; US = "\037"; MAT = ENVIRON["FELIX_SIT_MATURITY"] ""
      while ((rc = (getline line < ENVIRON["FELIX_SIT_ROWS"])) > 0) {
        n = split(line, f, "\t")
        if (n >= 2) { nr++; CL[nr] = f[1] ""; AP[nr] = f[2] "" }
      }
      if (rc < 0) exit 3
      while ((rc = (getline line < ENVIRON["FELIX_SIT_GROUNDS"])) > 0) {
        n = split(line, f, "\t")
        if (n < 2) continue
        ng++; GP[ng] = f[1] ""; GG[ng] = f[2] ""
        if (GG[ng] != "" && GG[ng] != "-") GCAP[GG[ng]] = 1
      }
      if (rc < 0) exit 3
      while ((rc = (getline line < ENVIRON["FELIX_SIT_READING"])) > 0) {
        n = split(line, f, "\t")
        if (f[1] == "how") HOW = f[2] ""
        else if (f[1] == "detector") DET = f[2] ""
        else if (f[1] == "cap") { nd++; DL[nd] = f[2] ""; DCAP[f[2] ""] = 1 }
        else if (f[1] == "probe") { np++; PP[np] = f[2] ""; PG[np] = f[3] ""; PS[np] = f[4] ""; PC[np] = f[5] ""; PD[np] = f[6] "" }
      }
      if (rc < 0) exit 3
      for (r = 1; r <= nr; r++) {
        nt = split(AP[r], tm, / +/)
        RD = ""; split("", RDS); gr = ""; key = ""; nf = 0; nu = 0; wit = "-"; ud = ""
        for (q = 1; q <= nt; q++) {
          if (tm[q] == "") continue
          evalterm(tm[q])
          gr = gr ((gr == "") ? "" : ", ") TG
          key = key ((key == "") ? "" : US) TK
          if (K == "probe" || K == "cap") USED[C] = 1
          if (TS == "F") { nf++; if (nf == 1 && TW != "") wit = TW }
          if (TS == "U") { nu++; ud = ud "undecided\t" CL[r] "\t" tm[q] "\t" TY "\n" }
          w = unboundwhy()
          if (w != "") ub = ub "unbound\t" tm[q] "\t" w "\n"
        }
        cs = "ACTIVE"
        if (nf > 0) cs = "DORMANT"
        else if (nu > 0) cs = "UNKNOWN"
        if (RD == "") RD = "-"
        printf "class\t%s\t%s\t%s\t%s\t%s\t%s\n", CL[r], cs, gr, RD, wit, key
        printf "%s", ud
      }
      printf "%s", ub
      if (DET == "run") for (q = 1; q <= nd; q++) if (!(DL[q] in USED)) printf "seen\t%s\tthe detector\n", DL[q]
      for (q = 1; q <= np; q++) if (PG[q] != "" && PG[q] != "-" && !(PG[q] in USED)) printf "seen\t%s\tprobe %s\n", PG[q], PP[q]
      exit 0
    }' </dev/null
}

# The verdict token of one class in --change (C5), from its state at the base and at the head and whether a grounding reading
# differs between them (1 or 0): prints owed, blinded, retired, standing, could-not-look or none. Nothing is read from a clock
# or a file. An UNKNOWN head never reads as none or retired, and an UNKNOWN base under an ACTIVE head reads owed.
felix_situations_verdict() {   # BASE-STATE HEAD-STATE DIFFERS
  local b="${1-}" h="${2-}" d="${3-0}"
  case "$h" in
    ACTIVE)
      if [ "$b" = ACTIVE ] && [ "$d" != 1 ]; then printf 'standing'; else printf 'owed'; fi ;;
    UNKNOWN)
      if [ "$b" = UNKNOWN ]; then printf 'could-not-look'; else printf 'blinded'; fi ;;
    *)
      if [ "$b" = ACTIVE ]; then printf 'retired'; else printf 'none'; fi ;;
  esac
}

# The report of felix_situations_report with the arguments given, built into the file report in the scratch directory and read
# from it into _FELIX_SITUATIONS_OUT. Both steps are checked, and the report function has printed its sentence when it fails.
# Returns 3 on a failure.
_felix_situations_build() {   # MODE FORMAT PROJ ROWS BASE-EVAL|- HEAD-EVAL BASE-READING|- HEAD-READING
  local scr="${_FELIX_SITUATIONS_SCRATCH:-}"
  : > "$scr/report" 2>/dev/null || { _felix_situations_fail "making the report"; return 3; }
  felix_situations_report "$@" > "$scr/report" || return 3
  _FELIX_SITUATIONS_OUT="$(cat "$scr/report" 2>/dev/null)" || { _felix_situations_fail "reading the report back"; return 3; }
  return 0
}

# The --propose drafts (C11) appended to the report in _FELIX_SITUATIONS_OUT, after one blank line, when FMT is propose and
# otherwise nothing. EVAL and READING are the side the proposals read: the reading in --at, the head side in --change. Returns
# 3 when the drafts cannot be built; felix_situations_propose has printed the sentence.
_felix_situations_proposed() {   # FMT EVAL READING MATURITY
  local scr="${_FELIX_SITUATIONS_SCRATCH:-}" prop
  [ "${1-}" = propose ] || return 0
  prop="$(felix_situations_propose "$PROJ" "$FELIX_HOME_DIR" "$scr/rows" "${2-}" "${4-}" "${3-}")" || return 3
  _FELIX_SITUATIONS_OUT="$_FELIX_SITUATIONS_OUT"$'\n'"$prop"
  return 0
}

# The run of --at (C3.1, C3.2): the recorded reading of AT, or of the newest recorded tree when AT is empty, the detector
# when this checkout is at that tree, the three values of every class, and the report, built into _FELIX_SITUATIONS_OUT. The
# table's rows and the current probes.tsv's grounds are already in the scratch directory. Returns 3 with C2's sentence
# when the tree cannot be read, and with C17.4's when a step failed.
_felix_situations_at() {   # AT FORMAT ROOT MATURITY
  local at="${1-}" fmt="${2-}" root="${3-}" mat="${4-}" scr="${_FELIX_SITUATIONS_SCRATCH:-}" log tree rc
  log="$(felix_mem_dir "$PROJ")/facts.log"
  tree="$at"
  if [ -z "$tree" ]; then
    tree="$(felix_situations_newest_tree "$log")"
    rc=$?
    if [ "$rc" -eq 1 ]; then
      printf 'felix situations: the recorded tree could not be read: %s records no tree\n' "$log" >&2
      return 3
    fi
    [ "$rc" -eq 0 ] || return 3
  fi
  felix_situations_read_recorded "$log" "$tree" "$scr/at.reading"
  rc=$?
  if [ "$rc" -eq 1 ]; then
    printf 'felix situations: the recorded tree could not be read: no run is recorded for tree %s in %s\n' "$tree" "$log" >&2
    return 3
  fi
  [ "$rc" -eq 0 ] || return 3
  felix_situations_live_detect "$root" "$FELIX_HOME_DIR" "$tree" "$scr/at.reading" || return 3
  felix_situations_eval "$scr/rows" "$scr/at.reading" "$scr/grounds" "$mat" > "$scr/at.eval" 2>/dev/null \
    || { _felix_situations_fail "evaluating the recorded reading"; return 3; }
  _felix_situations_build at "$fmt" "$PROJ" "$scr/rows" - "$scr/at.eval" - "$scr/at.reading" || return 3
  _felix_situations_proposed "$fmt" "$scr/at.eval" "$scr/at.reading" "$mat" || return 3
  return 0
}

# The run of --change (C3.3): the two ends of the change, each read in a scratch clone with the current probes.tsv and the
# detector, the three values of every class on each side, and the report, built into _FELIX_SITUATIONS_OUT. RANGE is
# <base>..<head> as given, or empty for the merge base of the main ref and HEAD to HEAD. Returns 3 with a sentence when a
# side cannot be read or a step failed. Nothing here writes facts.log, and the live checkout is only read, with no optional
# lock.
_felix_situations_change() {   # RANGE FORMAT ROOT MATURITY
  local range="${1-}" fmt="${2-}" root="${3-}" mat="${4-}" scr="${_FELIX_SITUATIONS_SCRATCH:-}" sides bsha hsha gd side
  sides="$(felix_situations_range "$root" "$range")" || return 3
  bsha="${sides%%$'\t'*}"; hsha="${sides#*$'\t'}"
  gd="$(felix_situations_gitdir "$root")" || gd=""
  felix_situations_read_scratch "$PROJ" "$FELIX_HOME_DIR" "$gd" "$bsha" base "$scr/base.reading" || return 3
  felix_situations_read_scratch "$PROJ" "$FELIX_HOME_DIR" "$gd" "$hsha" head "$scr/head.reading" || return 3
  for side in base head; do
    felix_situations_eval "$scr/rows" "$scr/$side.reading" "$scr/grounds" "$mat" > "$scr/$side.eval" 2>/dev/null \
      || { _felix_situations_fail "evaluating the $side reading"; return 3; }
  done
  _felix_situations_build change "$fmt" "$PROJ" "$scr/rows" "$scr/base.eval" "$scr/head.eval" \
    "$scr/base.reading" "$scr/head.reading" || return 3
  _felix_situations_proposed "$fmt" "$scr/head.eval" "$scr/head.reading" "$mat" || return 3
  return 0
}

# felix situations [--at <tree> | --change [<base>..<head>]] [--tsv | --propose] (C1). Arguments are read left to right,
# and one that repeats a flag, conflicts with a flag before it, or is not a flag at all fails where it is read, before its
# value is looked at; -h and --help given first never reach here, felix answers them for every command. The report itself
# is built in the sibling libraries, inside the scratch directory, which is removed before the first byte is printed.
felix_situations() {
  local mode="" at="" range="" fmt="" a
  while [ $# -gt 0 ]; do
    a="$1"
    case "$a" in
      --at)
        [ -z "$mode" ] || _felix_situations_usage "$a"
        need_value "$@"
        mode=at; at="$2"; shift 2 ;;
      --change)
        [ -z "$mode" ] || _felix_situations_usage "$a"
        mode=change; shift
        if [ $# -gt 0 ]; then
          case "$1" in
            -*) ;;
            *) _felix_situations_range_ok "$1" || _felix_situations_usage "$1"
               range="$1"; shift ;;
          esac
        fi ;;
      --tsv|--propose)
        [ -z "$fmt" ] || _felix_situations_usage "$a"
        fmt="${a#--}"; shift ;;
      *) _felix_situations_usage "$a" ;;
    esac
  done
  [ -n "$mode" ] || mode=at

  # Exported before the project is resolved, so that no git read of the live checkout, the resolution's included, refreshes
  # an index as a side effect (C3.4).
  export GIT_OPTIONAL_LOCKS=0
  resolve_or_die

  local tpath trows trc=0 scr root mat rc=0
  tpath="${SCRIPT_DIR}/templates/situations.tsv"
  trows="$(felix_situations_table "$tpath" 2>&1)" || trc=$?
  if [ "$trc" -ne 0 ]; then
    printf 'felix situations: the situation table could not be read: %s\n' "$trows" >&2
    return 3
  fi

  felix_situations_scratch_begin || return $?
  scr="$_FELIX_SITUATIONS_SCRATCH"
  root="$(felix_repo_root "$PWD")"
  mat="$(felix_json_str "$PROJ/project.json" maturity 2>/dev/null)"
  _FELIX_SITUATIONS_OUT=""

  # A project table that exists and cannot be read ends the run here, as it must not read as an empty one (C17.4).
  felix_situations_tables "$PROJ" "$fmt" || return 3

  # What both modes evaluate against: the table's rows, and the predicate and grounds cells of the current probes.tsv, which
  # C4 needs for a grounding probe with no reading and for a term no probe grounds. Each step writes a file and is checked.
  printf '%s\n' "$trows" > "$scr/rows" 2>/dev/null || { _felix_situations_fail "writing the table rows"; return 3; }
  felix_probe_rows "$PROJ" > "$scr/probe.rows" 2>/dev/null || { _felix_situations_fail "reading probes.tsv"; return 3; }
  LC_ALL=C cut -f1,2 "$scr/probe.rows" > "$scr/grounds" 2>/dev/null || { _felix_situations_fail "cutting the probe grounds"; return 3; }

  if [ "$mode" = change ]; then
    _felix_situations_change "$range" "$fmt" "$root" "$mat" || rc=$?
  else
    _felix_situations_at "$at" "$fmt" "$root" "$mat" || rc=$?
  fi
  [ "$rc" -eq 0 ] || return "$rc"

  felix_situations_scratch_end
  printf '%s\n' "$_FELIX_SITUATIONS_OUT" || { _felix_situations_fail "writing the report"; return 3; }
  return 0
}

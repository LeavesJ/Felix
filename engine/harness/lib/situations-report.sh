# felix situations, the report (slice 1 of the capability lane; contracts C8 to C11 and C17 of
# docs/2026-10-29-lane-slice-1-plan.md). Loaded by cmd_situations in felix, after lib/situations.sh. Definitions only.
#
# It prints one of three things, all from the evaluation the other two libraries make and none from a clock, a model or
# the network:
#
#   the human report   situations for <project>, how each side was read, the sections owed, blinded, retired, standing
#                      and residual in --change (standing and residual in --at), and the count line (C9)
#   --tsv              one line per class, then the residual lines, in an order that does not depend on the caller's
#                      locale (C8); slice 2 reads this form
#   --propose          after the count line, a drafted obligations row and the command that would admit it for each
#                      class that is ACTIVE and not yet admitted (C11); it writes nothing
#
# The --at and --change reports, human and --tsv, are built here, and so are the --propose drafts.
# Every file the report needs is made inside the run's scratch directory, and every sort runs under LC_ALL=C.
#
# EVERY STEP IS CHECKED (C17.4). A step is one sort, awk, id or file written and read back, and each writes its answer to a
# file in the scratch directory, so that a pipeline's producer is never hidden behind its last stage. A step that fails
# prints C17.4's sentence (lib/situations-check.sh) and the function returns 3, and the report is not printed.
#
# THE CLASS LINES. One line per class in the file classes, thirteen cells: the id, the class, the verdict, the base state, the
# head state, the base and the head grounds, the owes cell, the base and the head readings, the base and the head witness,
# and last the verdict's rank (C5's token order). The id comes first. --tsv orders them by rank and then id, and the human
# report by class name, and in both a sort reads the id lines.

# FILE KEY -> the second cell of the first line of a reading file whose first cell is KEY. Fails when FILE cannot be read.
_felix_situations_field() {
  LC_ALL=C awk -F'\t' -v k="${2-}" '$1 == k { print $2; exit }' "${1-}" 2>/dev/null
}

# The residual lines (C10) of one side's evaluation EVAL, as residual<TAB>kind<TAB>name<TAB>why, appended unsorted to OUT, less
# the cells with no row: a could-not-look line for each undecided term of each class that is UNKNOWN on that side, whose why
# begins with SIDE (base, head, or at), and an unbound line for each unbound term.
_felix_situations_residual() {   # SIDE EVAL OUT
  LC_ALL=C awk -F'\t' -v side="${1-}" '
    $1 == "class" { st[$2] = $3 }
    $1 == "undecided" { n++; uc[n] = $2; ut[n] = $3; uw[n] = $4 }
    $1 == "unbound" { printf "residual\tunbound\t%s\t%s\n", $2, $3 }
    END {
      for (i = 1; i <= n; i++)
        if (st[uc[i]] == "UNKNOWN") printf "residual\tcould-not-look\t%s\t%s: %s: %s\n", uc[i], side, ut[i], uw[i]
    }' "${2-}" >> "${3-}" 2>/dev/null || _felix_situations_fail "listing the undecided and unbound terms" || return 3
}

# The cells with no row (C10), appended to the file res.raw of the scratch directory W: a no-row line for each capability that
# no class uses and that some EVAL names, from the detector or from a probe row's grounds cell. The sources are the union over
# every EVAL given: the detector first, then the probes by byte order of the predicate.
_felix_situations_norow() {   # W EVAL...
  local w="${1-}"
  shift
  LC_ALL=C awk -F'\t' '$1 == "seen"' "$@" > "$w/seen" 2>/dev/null \
    || _felix_situations_fail "collecting the capabilities no class uses" || return 3
  LC_ALL=C sort -u "$w/seen" > "$w/seen.sorted" 2>/dev/null \
    || _felix_situations_fail "sorting the capabilities no class uses" || return 3
  LC_ALL=C awk -F'\t' '
    function flush() {
      if (cur == "") return
      printf "residual\tno-row\t%s\tnamed by %s\n", cur, (det ? "the detector" (srcs == "" ? "" : ", " srcs) : srcs)
    }
    ($2 "") != (cur "") { flush(); cur = $2 ""; det = 0; srcs = "" }
    $3 == "the detector" { det = 1; next }
    { srcs = srcs ((srcs == "") ? "" : ", ") $3 }
    END { flush() }' "$w/seen.sorted" >> "$w/res.raw" 2>/dev/null \
    || _felix_situations_fail "listing the capabilities no class uses" || return 3
}

# The report (C8, C9) for MODE at or change, in FORMAT human or tsv (or propose, which is human here), to stdout. ROWS is the
# table's rows (a file). BASE-EVAL and HEAD-EVAL are the evaluations of the two readings (felix_situations_eval), BASE-READING
# and HEAD-READING the reading files; in --at the base ones are - and the head ones are the one reading. Files it makes live
# in the scratch directory. In --change each class gets its verdict token from its two states and whether a grounding reading
# differs between the sides (C5): the differs test compares the key of the class's two class lines, which holds, term by term,
# the grounding rows' predicate, state and count, and, for a capability decided by the detector, its answer. In --at the token
# follows the one state. Returns 3, with C17.4's sentence on stderr, when a step fails.
felix_situations_report() {   # MODE FORMAT PROJ ROWS BASE-EVAL|- HEAD-EVAL BASE-READING|- HEAD-READING
  local mode="${1-}" fmt="${2-}" proj="${3-}" rows="${4-}" beval="${5-}" heval="${6-}" bread="${7-}" hread="${8-}"
  local w="${_FELIX_SITUATIONS_SCRATCH:-}" name line class id v bs hs df det bc bt hc ht st secs tab=$'\t'
  if [ -z "$w" ]; then _felix_situations_fail "finding the scratch directory"; return 3; fi
  case "$mode" in at|change) ;; *) _felix_situations_fail "reading the mode"; return 3 ;; esac
  proj="${proj%/}"; name="${proj##*/}"

  # One id per class (C6).
  : > "$w/ids" 2>/dev/null || { _felix_situations_fail "making the ids"; return 3; }
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    class="${line%%"$tab"*}"
    id="$(felix_situations_id "$class" "$name")" || { _felix_situations_fail "taking the id of $class"; return 3; }
    printf '%s\t%s\n' "$class" "$id" >> "$w/ids" 2>/dev/null || { _felix_situations_fail "writing the ids"; return 3; }
  done < "$rows" || { _felix_situations_fail "reading the table rows"; return 3; }

  # In --change, the token of every class from its two states and whether they differ.
  : > "$w/verdicts" 2>/dev/null || { _felix_situations_fail "making the verdicts"; return 3; }
  if [ "$mode" = change ]; then
    LC_ALL=C awk -F'\t' '
      $1 != "class" { next }
      FILENAME == ARGV[1] { BS[$2 ""] = $3 ""; BK[$2 ""] = $7 ""; next }
      { printf "%s %s %s %d\n", $2, BS[$2 ""], $3, (BK[$2 ""] != $7 "") }' "$beval" "$heval" > "$w/pairs" 2>/dev/null \
      || { _felix_situations_fail "comparing the two sides"; return 3; }
    while read -r class bs hs df; do
      v="$(felix_situations_verdict "$bs" "$hs" "$df")" && [ -n "$v" ] || { _felix_situations_fail "choosing a verdict"; return 3; }
      printf '%s\t%s\n' "$class" "$v" >> "$w/verdicts" 2>/dev/null || { _felix_situations_fail "writing the verdicts"; return 3; }
    done < "$w/pairs" || { _felix_situations_fail "reading the pairs of states"; return 3; }
  fi

  # One line per class: id, class, verdict, base, head, base grounds, head grounds, owes, base readings, head readings, base
  # witness, head witness, rank. In --at the base cells are - and the verdict follows the one state.
  FELIX_SIT_MODE="$mode" FELIX_SIT_ROWS="$rows" FELIX_SIT_IDS="$w/ids" FELIX_SIT_VERD="$w/verdicts" \
    FELIX_SIT_BEVAL="$beval" FELIX_SIT_HEVAL="$heval" LC_ALL=C awk '
    function rank(v) {
      return (v == "owed") ? 1 : (v == "blinded") ? 2 : (v == "retired") ? 3 : (v == "standing") ? 4 : (v == "could-not-look") ? 5 : 6
    }
    BEGIN {
      mode = ENVIRON["FELIX_SIT_MODE"]
      while ((rc = (getline l < ENVIRON["FELIX_SIT_ROWS"])) > 0) {
        if (split(l, f, "\t") >= 5) { nr++; CL[nr] = f[1] ""; OW[f[1] ""] = f[3] "" }
      }
      if (rc < 0) exit 3
      while ((rc = (getline l < ENVIRON["FELIX_SIT_IDS"])) > 0) { split(l, f, "\t"); ID[f[1] ""] = f[2] "" }
      if (rc < 0) exit 3
      if (mode == "change") {
        while ((rc = (getline l < ENVIRON["FELIX_SIT_VERD"])) > 0) { split(l, f, "\t"); VD[f[1] ""] = f[2] "" }
        if (rc < 0) exit 3
        while ((rc = (getline l < ENVIRON["FELIX_SIT_BEVAL"])) > 0) {
          split(l, f, "\t")
          if (f[1] == "class") { c = f[2] ""; BS[c] = f[3] ""; BG[c] = f[4] ""; BR[c] = f[5] ""; BW[c] = f[6] "" }
        }
        if (rc < 0) exit 3
      }
      while ((rc = (getline l < ENVIRON["FELIX_SIT_HEVAL"])) > 0) {
        split(l, f, "\t")
        if (f[1] == "class") { c = f[2] ""; HS[c] = f[3] ""; HG[c] = f[4] ""; HR[c] = f[5] ""; HW[c] = f[6] "" }
      }
      if (rc < 0) exit 3
      for (i = 1; i <= nr; i++) {
        c = CL[i]
        if (mode == "change") { v = VD[c]; b = BS[c]; bg = BG[c]; br = BR[c]; bw = BW[c] }
        else {
          v = (HS[c] == "ACTIVE") ? "standing" : (HS[c] == "UNKNOWN") ? "could-not-look" : "none"
          b = "-"; bg = "-"; br = "-"; bw = "-"
        }
        printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%d\n", ID[c], c, v, b, HS[c], bg, HG[c], OW[c], br, HR[c], bw, HW[c], rank(v)
      }
      exit 0
    }' </dev/null > "$w/classes" 2>/dev/null || { _felix_situations_fail "assembling the class lines"; return 3; }

  # The residual (C10), unique, as whole lines in bytes: the undecided terms of each side, the unbound terms, the cells with no row.
  : > "$w/res.raw" 2>/dev/null || { _felix_situations_fail "making the residual"; return 3; }
  if [ "$mode" = change ]; then
    _felix_situations_residual base "$beval" "$w/res.raw" || return 3
    _felix_situations_residual head "$heval" "$w/res.raw" || return 3
    _felix_situations_norow "$w" "$beval" "$heval" || return 3
  else
    _felix_situations_residual at "$heval" "$w/res.raw" || return 3
    _felix_situations_norow "$w" "$heval" || return 3
  fi
  LC_ALL=C sort -u "$w/res.raw" > "$w/residual" 2>/dev/null || { _felix_situations_fail "sorting the residual"; return 3; }

  if [ "$fmt" = tsv ]; then
    LC_ALL=C sort -t "$tab" -k13,13 -k1,1 "$w/classes" > "$w/classes.sorted" 2>/dev/null \
      || { _felix_situations_fail "sorting the class lines"; return 3; }
    LC_ALL=C cut -f1-8 "$w/classes.sorted" > "$w/tsv.classes" 2>/dev/null || { _felix_situations_fail "cutting the class lines"; return 3; }
    cat "$w/tsv.classes" "$w/residual" 2>/dev/null || { _felix_situations_fail "writing the lines"; return 3; }
    return 0
  fi

  # The header: how each side was read (C9).
  if [ "$mode" = change ]; then
    bc="$(_felix_situations_field "$bread" commit)" && bt="$(_felix_situations_field "$bread" tree)" \
      && hc="$(_felix_situations_field "$hread" commit)" && ht="$(_felix_situations_field "$hread" tree)" \
      || { _felix_situations_fail "reading the two readings"; return 3; }
    printf 'situations for %s\n  base  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n  head  %s  tree %s  scratch checkout, tracked content only, current probes.tsv\n' \
      "$name" "$bc" "$bt" "$hc" "$ht" > "$w/rep.head" 2>/dev/null || { _felix_situations_fail "writing the header"; return 3; }
  else
    det="$(_felix_situations_field "$hread" detector)" && hc="$(_felix_situations_field "$hread" commit)" \
      && ht="$(_felix_situations_field "$hread" tree)" && st="$(_felix_situations_field "$hread" stamp)" \
      || { _felix_situations_fail "reading the recorded reading"; return 3; }
    case "$det" in
      run)
        printf 'situations for %s\n  at  %s  tree %s  recorded %s  detector run on this checkout\n' "$name" "$hc" "$ht" "$st" > "$w/rep.head" 2>/dev/null ;;
      no-tree)
        printf 'situations for %s\n  at  -  tree %s  recorded %s  detector not run: the tree id of this checkout could not be taken\n' "$name" "$ht" "$st" > "$w/rep.head" 2>/dev/null ;;
      *)
        printf 'situations for %s\n  at  -  tree %s  recorded %s  detector not run: this checkout is not at this tree\n' "$name" "$ht" "$st" > "$w/rep.head" 2>/dev/null ;;
    esac || { _felix_situations_fail "writing the header"; return 3; }
  fi

  # The sections (C9), each preceded by one blank line and printing none when it holds no row. The rows within a section are in
  # byte order of class name, so the class lines are sorted by name once and each section takes its rows from that order.
  LC_ALL=C sort -t "$tab" -k2,2 "$w/classes" > "$w/classes.named" 2>/dev/null || { _felix_situations_fail "sorting the class lines by name"; return 3; }
  secs="standing"
  [ "$mode" != change ] || secs="owed blinded retired standing"
  LC_ALL=C awk -F'\t' -v m="$mode" -v secs="$secs" '
    m == "change" {
      t = sprintf("  %s  %s  %s -> %s\n    grounds  base: %s; head: %s\n    readings  base: %s; head: %s\n", $1, $2, $4, $5, $6, $7, $9, $10)
      if ($4 == "DORMANT" && $11 != "-") t = t sprintf("    witness  base: %s\n", $11)
      if ($5 == "DORMANT" && $12 != "-") t = t sprintf("    witness  head: %s\n", $12)
      BODY[$3] = BODY[$3] t sprintf("    owes  %s\n", $8)
      next
    }
    { BODY[$3] = BODY[$3] sprintf("  %s  %s  ACTIVE\n    grounds  %s\n    readings  %s\n    owes  %s\n", $1, $2, $7, $10, $8) }
    END {
      n = split(secs, S, " ")
      for (i = 1; i <= n; i++) {
        printf "\n%s\n", S[i]
        if (BODY[S[i]] == "") printf "  none\n"
        else printf "%s", BODY[S[i]]
      }
    }' "$w/classes.named" > "$w/rep.sections" 2>/dev/null || { _felix_situations_fail "writing the sections"; return 3; }

  # The residual and the count line (C9).
  LC_ALL=C awk -F'\t' '
    BEGIN { printf "\nresidual\n" }
    { n++; printf "  %s  %s  %s\n", $2, $3, $4 }
    END { if (!n) printf "  none: nothing undecided, unbound or without a row\n" }' "$w/residual" > "$w/rep.residual" 2>/dev/null \
    || { _felix_situations_fail "writing the residual"; return 3; }
  LC_ALL=C awk -F'\t' '
    { n++; if ($5 == "ACTIVE") a++; else if ($5 == "DORMANT") d++; else u++ }
    END { printf "\nexamined %d, active %d, dormant %d, could not look %d\n", n, a, d, u }' "$w/classes" > "$w/rep.count" 2>/dev/null \
    || { _felix_situations_fail "counting the classes"; return 3; }
  cat "$w/rep.head" "$w/rep.sections" "$w/rep.residual" "$w/rep.count" 2>/dev/null || { _felix_situations_fail "writing the report"; return 3; }
  return 0
}

# The proposed section (C11), from its blank line on, to stdout: for each class that is ACTIVE in EVAL (the head side, or the
# reading in --at) and whose name no row of the project's obligations.tsv admits, in byte order of name, the line
# "  <id>  <class>  <grounds>", then a class line, the drafted row (seven cells joined by real tab bytes) and the one-line
# command that would append it to the table and commit it. With none, "  none". MATURITY is project.json's string, empty when
# none is declared; READING is the reading file EVAL was made from; HOME is the Felix home as given. The class is the one
# class_by_maturity pairs with the declared maturity, else the strictest class the cell names. The preds cell lists the
# predicates the class's true terms rest on that the current probes.tsv defines (the grounds file of the scratch directory).
# Every quoted value has each apostrophe written as the four characters quote, backslash, quote, quote. The command begins
# with a guard that ends the table's last row when it has none (C17.1), then C11's command. The ids file is the one
# felix_situations_report made in the same scratch directory. Writes only inside that directory, and no apostrophe may stand
# in the awk text: it is one shell word. Returns 3, with C17.4's sentence, when a step fails, an unreadable obligations.tsv
# included: the scan that lists the admitted rows reads such a table as admitting none, and its bad mode says so.
felix_situations_propose() {   # PROJ HOME ROWS EVAL MATURITY READING
  local proj="${1-}" home="${2-}" rows="${3-}" eval="${4-}" mat="${5-}" reading="${6-}"
  local w="${_FELIX_SITUATIONS_SCRATCH:-}" name tab=$'\t'
  if [ -z "$w" ] || [ ! -f "$w/ids" ] || [ ! -f "$w/grounds" ]; then _felix_situations_fail "finding the ids"; return 3; fi
  proj="${proj%/}"; name="${proj##*/}"
  felix_obligation_rows "$proj" > "$w/admitted.rows" 2>/dev/null || { _felix_situations_fail "reading obligations.tsv"; return 3; }
  felix_obligation_malformed "$proj" > "$w/admitted.bad" 2>/dev/null || { _felix_situations_fail "reading obligations.tsv"; return 3; }
  if LC_ALL=C grep -q '^obligations.tsv could not be read: its scan exited ' "$w/admitted.bad" 2>/dev/null; then
    _felix_situations_fail "reading obligations.tsv"
    return 3
  fi
  LC_ALL=C cut -f1 "$w/admitted.rows" > "$w/admitted" 2>/dev/null || { _felix_situations_fail "listing the admitted obligations"; return 3; }
  LC_ALL=C sort -t "$tab" -k1,1 "$rows" > "$w/prop.rows" 2>/dev/null || { _felix_situations_fail "sorting the classes for the drafts"; return 3; }
  FELIX_SIT_ROWS="$w/prop.rows" FELIX_SIT_EVAL="$eval" FELIX_SIT_ADM="$w/admitted" FELIX_SIT_IDS="$w/ids" \
    FELIX_SIT_READING="$reading" FELIX_SIT_GROUNDS="$w/grounds" FELIX_SIT_MATURITY="$mat" FELIX_SIT_HOME="$home" \
    FELIX_SIT_NAME="$name" LC_ALL=C awk '
    function isst(s) { return s == "found" || s == "empty" || s == "blind" || s == "unknown" || s == "not-applicable" }
    function ismat(m) { return m == "prototype" || m == "internal" || m == "public-beta" || m == "production" }
    function crank(c) {
      return (c == "INFO") ? 1 : (c == "ADVISORY") ? 2 : (c == "TASK_BLOCKING") ? 3 : (c == "RELEASE_BLOCKING") ? 4 : (c == "AUTHORITY_BLOCKING") ? 5 : 0
    }
    # S single-quoted for a shell, each apostrophe written as quote, backslash, quote, quote.
    function q(s,   n, p, i, o) {
      n = split(s, p, SQ); o = p[1]
      for (i = 2; i <= n; i++) o = o SQ "\\" SQ SQ p[i]
      return SQ o SQ
    }
    # Sets CW and CN: the class for the declared maturity and the note that says why.
    function pick(cell,   n, pr, i, e, m, c, best, br) {
      CW = ""; br = 0; best = ""
      n = split(cell, pr, ",")
      for (i = 1; i <= n; i++) {
        e = index(pr[i], "="); m = substr(pr[i], 1, e - 1); c = substr(pr[i], e + 1)
        if (ismat(MAT) && m == MAT) CW = c
        if (crank(c) > br) { br = crank(c); best = c }
      }
      if (CW != "") { CN = "maturity " MAT; return }
      CW = best
      CN = (MAT == "") ? "maturity undeclared: the strictest class this row names" : "maturity " SQ MAT SQ " is not one of prototype internal public-beta production: the strictest class this row names"
    }
    # The grounding rows of capability c: GI[1..NG] index the reading, one per predicate, its first row, in reading order.
    function ground(c,   i) {
      NG = 0; split("", SP)
      if (c == "" || c == "-") return
      for (i = 1; i <= np; i++) if (PG[i] == c && !(PP[i] in SP)) { SP[PP[i]] = 1; GI[++NG] = i }
    }
    function addp(i) {
      if (!(PP[i] in DEF) || (PP[i] in GOT)) return
      GOT[PP[i]] = 1; PL = PL ((PL == "") ? "" : ",") PP[i]
    }
    # Sets PL to the predicates the true terms of an applies cell rest on, in first-use order, without repeats.
    function preds(ap,   nt, tm, t, k, rest, e, c, s, fo) {
      PL = ""; split("", GOT)
      nt = split(ap, tm, / +/)
      for (t = 1; t <= nt; t++) {
        if (substr(tm[t], 1, 6) == "probe:") {
          rest = substr(tm[t], 7); e = index(rest, "=")
          if (e < 2 || !isst(substr(rest, e + 1))) continue
          c = substr(rest, 1, e - 1); s = substr(rest, e + 1)
          ground(c)
          for (k = 1; k <= NG; k++) if (PS[GI[k]] == s) addp(GI[k])
        } else if (substr(tm[t], 1, 4) == "cap:" && length(tm[t]) > 4) {
          ground(substr(tm[t], 5)); fo = 0
          for (k = 1; k <= NG; k++) if (PS[GI[k]] == "found") fo = 1
          if (fo) for (k = 1; k <= NG; k++) if (PS[GI[k]] == "found") addp(GI[k])
        }
      }
      if (PL == "") PL = "-"
    }
    BEGIN {
      SQ = "\047"; TB = "\t"; MAT = ENVIRON["FELIX_SIT_MATURITY"] ""; H = ENVIRON["FELIX_SIT_HOME"] ""
      P = H "/projects/" ENVIRON["FELIX_SIT_NAME"]; TBL = q(P "/obligations.tsv")
      GUARD = "{ [ ! -s " TBL " ] || [ -z \"$(tail -c 1 " TBL ")\" ] || printf " SQ "\\n" SQ "; } >> " TBL " && "
      while ((rc = (getline l < ENVIRON["FELIX_SIT_EVAL"])) > 0) {
        split(l, f, "\t")
        if (f[1] == "class") { ST[f[2] ""] = f[3] ""; GR[f[2] ""] = f[4] "" }
      }
      if (rc < 0) exit 3
      while ((rc = (getline l < ENVIRON["FELIX_SIT_ADM"])) > 0) ADM[l ""] = 1
      if (rc < 0) exit 3
      while ((rc = (getline l < ENVIRON["FELIX_SIT_IDS"])) > 0) { split(l, f, "\t"); ID[f[1] ""] = f[2] "" }
      if (rc < 0) exit 3
      while ((rc = (getline l < ENVIRON["FELIX_SIT_GROUNDS"])) > 0) { split(l, f, "\t"); DEF[f[1] ""] = 1 }
      if (rc < 0) exit 3
      while ((rc = (getline l < ENVIRON["FELIX_SIT_READING"])) > 0) {
        split(l, f, "\t")
        if (f[1] == "probe") { np++; PP[np] = f[2] ""; PG[np] = f[3] ""; PS[np] = f[4] "" }
      }
      if (rc < 0) exit 3
      printf "\nproposed\n"
      while ((rc = (getline l < ENVIRON["FELIX_SIT_ROWS"])) > 0) {
        if (split(l, f, "\t") < 4) continue
        c = f[1] ""
        if (ST[c] != "ACTIVE" || (c in ADM)) continue
        shown++
        pick(f[4] ""); preds(f[2] "")
        print "  " ID[c] "  " c "  " GR[c]
        print "    class  " CW "  " CN
        print "    row  " c TB CW TB "unknown" TB "-" TB "exit 2" TB PL TB f[3]
        print "    admit  " GUARD "printf " SQ "%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n" SQ " " q(c) " " q(CW) " " q("unknown") " " q("-") " " q("exit 2") " " q(PL) " " q(f[3] "") " >> " TBL " && git -C " q(H) " add -- " TBL " && git -C " q(H) " commit -q -m " q("obligations: admit " c) " -- " TBL
      }
      if (rc < 0) exit 3
      if (!shown) printf "  none\n"
      exit 0
    }' </dev/null || { _felix_situations_fail "drafting the proposals"; return 3; }
}

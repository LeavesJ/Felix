# felix inventory's human view: the rows lib/inventory.sh wrote, grouped for
# a person, what needs action first. --tsv, which the rows themselves are,
# never passes through here.
#
# Per repository, first what was read: one line per cover row, its facet, its
# coverage word and its detail (what the repository's default branch is and how
# old that fact is, where PR facts came from, the sessions and the chip window).
# Then a group per headline, in _FI_ORDER, and "undecided, content not landed"
# for an item whose content is known not to be, or only partly, on the default
# branch and that holds no state but live: undecided because a fact is unknown,
# or because its commits sit on another remote branch, listing every state it
# could not decide. A live item is counted live, and listed as well under
# question or blocked when it holds one: a session asking or stuck is not one to
# leave because another in the same directory is running. A row in a temporary
# directory that would be listed is listed after all of those, in the same
# order, its headline shown with its other states. A helper's row (state
# helper) is read with that state set aside, so its headline is the first of
# its others; one that would be listed, and is not in a temporary directory, is
# listed after the temporary ones in a section of its own, in the same order and
# not printed twice, and helper is not shown beside it, the heading says it.
# Last, the counts: live, landed, orphans holding nothing unique, and items
# nothing was decided about but that a fact is unknown; a helper's row that is
# none of those listed is counted as any other. The view reads each row's
# states and content column, and its detail only to find temp.

# The human view of $_FI_T/outv.
_fi_view() {
  printf 'felix inventory: read-only. It wrote nothing into a repository and fetched nothing; gh, if asked, only listed pull requests.\n'
  [ -s "$_FI_T/outv" ] || return 0
  awk -F'\t' -v order="${_FI_ORDER/ live / } undecided" '
    { r = $2; if (!(r in S)) { S[r] = 1; RP[++nr] = r } }
    $1 == "cover" { split($4, cs, ","); CV[r] = CV[r] sprintf("  %-9s %-8s %s\n", $3, cs[1], $8); next }
    { s4 = "," $4 ","; hp = sub(/,helper,/, ",", s4); s4 = substr(s4, 2, length(s4) - 2); if (length(s4) < 1) s4 = "-"
      m = split(s4, st, ","); h = st[1]; hi = 1; c = $7; ref = $3; if (index(ref, r "/") == 1) ref = substr(ref, length(r) + 2)
      tp = $8 ~ /(^|; )temp(; |$)/; bad = (c == "not" || c == "partly")
      if (h == "live") {
        LV[r]++; if ($4 ~ /(^|,)blocked(,|$)/) LB[r]++
        ol = 1; for (j = 2; j <= m; j++) if (st[j] !~ /^unknown:/) ol = 0
        if (st[2] == "question" || st[2] == "blocked") { h = st[2]; hi = 2 }
        else if (ol && bad) { h = "undecided"; hi = 0 }
        else next
      } else if (h == "-" || h ~ /^unknown:/) {
        if (bad) { h = "undecided"; hi = 0 } else { U[r]++; next }
      } else if (h == "landed") { LD[r]++; next }
      else if (h == "orphan" && c == "landed") { OZ[r]++; next }
      # The states shown beside it: all but its headline, which the groups of
      # temporary directories and helper worktrees have no heading for, so
      # there it leads them.
      a = ((tp || hp) && hi) ? h : ""; u = ""
      for (j = 1; j <= m; j++) {
        if (j == hi) continue
        if (st[j] ~ /^unknown:/) u = u (u == "" ? "" : ",") substr(st[j], 9)
        else if (st[j] != "landed" && st[j] != "-") a = a (a == "" ? "" : ",") st[j]
      }
      if (tp && hp) a = a (a == "" ? "" : ",") "helper"   # the temporary heading does not say it
      if (u != "") a = a (a == "" ? "" : "; ") "unknown: " u
      if (tp) { TN[r]++; h = "~" h } else if (hp) { HN[r]++; h = "^" h }
      G[r, h] = G[r, h] sprintf("    %-8s %s%s\n             %s (%sh%s)\n", $1, ref, (a == "" ? "" : "  [" a "]"), $8, $6, \
        ($5 ~ /^(-|unknown)$/ ? "" : ", session " substr($5, 1, 8))); N[r, h]++ }
    END { n = split(order, O, " ")
      for (i = 1; i <= nr; i++) { r = RP[i]; printf "\n%s\n%s", r, CV[r]
        for (j = 1; j <= n; j++) if (N[r, O[j]]) printf "\n  %s  %d\n%s", (O[j] == "undecided" ? "undecided, content not landed" : O[j]), N[r, O[j]], G[r, O[j]]
        if (TN[r]) { printf "\n  in temporary directories  %d\n", TN[r]; for (j = 1; j <= n; j++) printf "%s", G[r, "~" O[j]] }
        if (HN[r]) { printf "\n  in helper worktrees  %d\n", HN[r]; for (j = 1; j <= n; j++) printf "%s", G[r, "^" O[j]] }
        printf "\n  live %d%s, landed %d, orphans holding nothing unique %d, nothing decided but unknown %d\n", LV[r], \
          (LB[r] ? " (" LB[r] " blocked on a tool call)" : ""), LD[r], OZ[r], U[r] } }' "$_FI_T/outv"
}

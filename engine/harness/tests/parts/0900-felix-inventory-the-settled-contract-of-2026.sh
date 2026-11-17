# ---------------------------- felix inventory: the settled contract, blind ----
# The assertions of audits/2026-10-01-report-v5-review/specs/inventory/
# assertions.md, written blind from that day's settled spec.md (no inventory
# library and no implementation diff read), with the rulings of disposition.md
# beside them. Each name carries its id: A1 ... A120 from assertions.md, and
# N1 ... N16 for what disposition.md asked the blind author for (the
# replacements for A101 and A107(a), the re-derived first line of A16 and tail
# of A22, H2's example, H4's guard, M1's gpg probe, M3's fork PR, H5's squash
# case, §6.2's message-first record) and for settled clauses no A-row reached
# (shallow clones, ssh ports, CLAUDE_CONFIG_DIR, a PR headed like the default
# branch). A101 is obsolete whole and is not here; A16, A22, A103 and A107 are
# here as the settlement left them, and their obsolete parts are left out.
#
# Records (spec.md §0 step 3, disposition.md H2): every user or assistant
# record the builders below write carries a "timestamp" equal to the age the
# fixture gives its session, and the session file's mtime is set to that same
# age, so a record's time and its file's time agree unless an assertion sets
# them apart on purpose (N1, N2). A user record puts "type":"user" before its
# message; an assistant record puts its message first and its own
# "type":"assistant" after it, as §6.2 states and the audit builders write.
#
# Everything lives under $IB, one repository per concern, so no block here
# depends on a project table or on a fixture another section leaves behind.
# Records are written just before the runs that read them, because their ages
# are minutes and a loaded machine spends minutes building the repositories.
printf '\nfelix inventory: the settled contract of 2026-10-01, written blind\n'
_ib_build

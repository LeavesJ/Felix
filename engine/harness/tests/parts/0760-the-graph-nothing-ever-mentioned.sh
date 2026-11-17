printf '\nthe graph nothing ever mentioned\n'
# Across 72 recorded sessions the knowledge graph beside a governed checkout was
# built three times and queried once. Nothing was broken: the graph was simply
# never mentioned, and a fact nobody states is a fact nobody uses. lib/graph.sh
# turns it into a sentence every session starts with — that a graph exists, how
# far it has drifted from the code, and the command that asks it.
#
# Two properties make or break that. It runs in every session of every governed
# project, so it may not read two megabytes of JSON to find one field, and it
# may never claim a currency it cannot establish: a graph whose stamp names a
# commit this repository does not hold is a graph of somebody else's tree, and
# saying "current" there is worse than saying nothing.
#
# The case this library exists to get right is the worktree. A worktree has no
# graph of its own — the graph belongs to the checkout that holds the shared
# .git — so every one of these functions has to look past the tree it was
# handed. Which is why the fixture below builds a real one and lets its HEAD
# diverge, rather than asserting about a directory named "worktree".
GRH="$TMP/graphhome"; mkdir -p "$GRH"
( _fx_cd "$GRH" && git init -q -b main && git config user.email t@t && git config user.name t
  printf 'seed\n' > a.txt && git add -A && git commit -qm seed ) >/dev/null 2>&1
GRSEED="$( cd "$GRH" && git rev-parse HEAD )"
( _fx_cd "$GRH" && for i in 1 2 3; do printf '%s\n' "$i" > "f$i.txt"; git add -A
    git commit -qm "c$i"; done ) >/dev/null 2>&1
GRHEAD="$( cd "$GRH" && git rev-parse HEAD )"
GRHP="$( cd "$GRH" && pwd -P )"
GRW="$TMP/graphwt"
( _fx_cd "$GRH" && git worktree add -q "$GRW" -b side ) >/dev/null 2>&1
# Five commits of its own, so the worktree's HEAD is nobody's idea of the
# holding checkout's HEAD and an answer that happens to match cannot be luck.
[ -d "$GRW" ] && ( _fx_cd "$GRW" && for i in 1 2 3 4 5; do printf '%s\n' "$i" > "w$i.txt"
    git add -A; git commit -qm "w$i"; done ) >/dev/null 2>&1
GRWP="$( [ -d "$GRW" ] && cd "$GRW" && pwd -P )"
GRPLAIN="$TMP/graphloose"; mkdir -p "$GRPLAIN"
GRJ="$GRH/graphify-out/graph.json"

_gr()     { ( . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/graph.sh"; "$@" ); }
_grtail() { ( export FELIX_GRAPH_TAIL="$1"; shift
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/graph.sh"
              felix_graph_stamp "$1" ); }
# A session banner is text, so the assertions about it are about text: does it
# contain this, how many of its words are absolute paths.
_grsays() { case "$1" in *"$2"*) printf 'yes\n' ;; *) printf 'no\n' ;; esac; }
_grabs()  { printf '%s\n' "$1" | tr '[:space:]' '\n' | awk '/^\//{n++} END {print n+0}'; }

# -- 1. the home ------------------------------------------------------------
is "the graph's home is the checkout that holds the repository" \
   "$(_gr felix_graph_home "$GRH")" "$GRHP"
if [ -d "$GRW" ]; then
  is "and asked from a worktree it is still the holding checkout" \
     "$(_gr felix_graph_home "$GRW")" "$GRHP"
else
  skip "and asked from a worktree it is still the holding checkout" "worktree add failed"
fi
mkdir -p "$GRH/deep/deeper"
is "and asked from a subdirectory it is still the checkout, not the subdirectory" \
   "$(_gr felix_graph_home "$GRH/deep/deeper")" "$GRHP"
ln -sfn "$GRH" "$TMP/graphlink"
is "and it is spelled with the symlinks taken out" \
   "$(_gr felix_graph_home "$TMP/graphlink")" "$GRHP"
out="$(_gr felix_graph_home "$GRPLAIN")"; rc=$?
is "a directory in no repository has no graph home to print"  "$out" ""
is "and saying so is an exit code, not an empty line"         "$rc"  "1"

# -- 2. the file ------------------------------------------------------------
# Deliberately before graphify-out exists, so the negative is measured against a
# checkout that has genuinely never been graphed rather than against a cleanup.
out="$(_gr felix_graph_file "$GRH")"; rc=$?
is "a checkout that has never been graphed has no graph file"  "$out" ""
is "and that is a failure, not a path it might make up"        "$rc"  "1"
mkdir -p "$GRH/graphify-out"
out="$(_gr felix_graph_file "$GRH")"; rc=$?
is "an empty graphify-out is still no graph — the file is the thing" "$out" ""
is "and it fails on the file, not on the directory"                  "$rc"  "1"
printf '{"nodes":[],"built_at_commit":"%s"}\n' "$GRHEAD" > "$GRJ"
is "the graph is graphify-out/graph.json under the holding checkout" \
   "$(_gr felix_graph_file "$GRH")" "$GRHP/graphify-out/graph.json"
if [ -d "$GRW" ]; then
  is "and a worktree is pointed at that one, having no graph of its own" \
     "$(_gr felix_graph_file "$GRW")" "$GRHP/graphify-out/graph.json"
else
  skip "and a worktree is pointed at that one, having no graph of its own" "worktree add failed"
fi

# -- 3. the stamp -----------------------------------------------------------
# The cost property, and the only one here that is about a hook's budget rather
# than about truth. built_at_commit is the last key the builder writes, so the
# stamp is readable from the tail — and a graph of a real repository is
# megabytes. Reading all of it at every session start is the difference between
# a fact that is free and a fact that gets switched off.
is "the stamp is the commit the graph says it was built at" \
   "$(_gr felix_graph_stamp "$GRJ")" "$GRHEAD"
printf '{"nodes":[]}\n' > "$TMP/graphnostamp.json"
out="$(_gr felix_graph_stamp "$TMP/graphnostamp.json")"; GRRC=$?
is "a graph carrying no stamp prints no stamp"   "$out"   ""
is "and reports that by failing"                 "$GRRC"  "1"
out="$(_gr felix_graph_stamp "$TMP/graphmissing.json")"; rc=$?
is "a graph file that is not there has no stamp either" "$out" ""
is "and fails the same way"                             "$rc"  "1"
# Just inside the window and just outside it, on files built the same way, so
# the pair measures the window and not the shape of the JSON.
{ printf '{"built_at_commit":"%s","pad":"' "$GRHEAD"
  awk 'BEGIN {for (i=0;i<3500;i++) printf "x"}'; printf '"}\n'; } > "$TMP/graphnear.json"
{ printf '{"built_at_commit":"%s","pad":"' "$GRHEAD"
  awk 'BEGIN {for (i=0;i<6000;i++) printf "x"}'; printf '"}\n'; } > "$TMP/graphfar.json"
is "a stamp inside the last 4096 bytes is read" \
   "$(_gr felix_graph_stamp "$TMP/graphnear.json")" "$GRHEAD"
out="$(_gr felix_graph_stamp "$TMP/graphfar.json")"; rc=$?
is "a stamp only at the start of a large file is not, because the tail is all it reads" \
   "$out" ""
is "and that reads as no stamp, the same verdict a stampless graph gets, not as an error" \
   "$rc" "$GRRC"
is "FELIX_GRAPH_TAIL widens the window when someone needs it to" \
   "$(_grtail 8192 "$TMP/graphfar.json")" "$GRHEAD"
is "and narrows it, which is how this suite knows the window is real" \
   "$(_grtail 16 "$GRJ")" ""

# -- 4. the distance --------------------------------------------------------
is "a graph built at HEAD is behind by nothing" \
   "$(_gr felix_graph_behind "$GRH" "$GRHEAD")" "0"
is "and one built three commits ago is behind by three" \
   "$(_gr felix_graph_behind "$GRH" "$GRSEED")" "3"
if [ -d "$GRW" ]; then
  # The worktree is five commits past the holding checkout on its own branch.
  # If the distance were measured against the tree it was handed, this would be
  # the worktree's own count and the session would be told a number about a
  # branch its graph knows nothing about.
  is "asked from a worktree the distance is still the holding checkout's" \
     "$(_gr felix_graph_behind "$GRW" "$GRSEED")" "3"
  is "and matches what the holding checkout itself answers" \
     "$(_gr felix_graph_behind "$GRW" "$GRSEED")" "$(_gr felix_graph_behind "$GRH" "$GRSEED")"
else
  skip "asked from a worktree the distance is still the holding checkout's" "worktree add failed"
  skip "and matches what the holding checkout itself answers" "worktree add failed"
fi
out="$(_gr felix_graph_behind "$GRH" "")"; rc=$?
is "an empty stamp is not a distance of zero"  "$out" ""
is "and is refused rather than rounded down"   "$rc"  "1"
out="$(_gr felix_graph_behind "$GRH" "0000000000000000000000000000000000000000")"; rc=$?
is "a commit this repository does not hold is not a distance"  "$out" ""
is "and is refused too"                                        "$rc"  "1"

# -- 5. the line ------------------------------------------------------------
# The function that matters, because it is the only one a session sees. Four
# readings, and the whole point is that they are four and not one: a stale
# graph is still worth asking, a graph of another tree is not the same as a
# graph with no stamp, and neither is the same as current.
printf '{"nodes":[],"built_at_commit":"%s"}\n' "$GRHEAD" > "$GRJ"
GRCUR="$(_gr felix_graph_line "$GRH")"
printf '{"nodes":[],"built_at_commit":"%s"}\n' "$GRSEED" > "$GRJ"
GRBEH="$(_gr felix_graph_line "$GRH")"
printf '{"nodes":[],"built_at_commit":"%s"}\n' "0000000000000000000000000000000000000000" > "$GRJ"
GRUNK="$(_gr felix_graph_line "$GRH")"
printf '{"nodes":[]}\n' > "$GRJ"
GRNOS="$(_gr felix_graph_line "$GRH")"
has "a current graph is said to be current"                "$GRCUR" "current"
has "a stale graph says how many commits it is behind"     "$GRBEH" "3"
has "a stamp from a tree this repository does not hold is named as that" \
    "$GRUNK" "not a commit this repository"
has "and a graph with no stamp admits its currency is unknown" "$GRNOS" "unknown"
is  "the four readings are four different sentences" \
    "$(printf '%s\n%s\n%s\n%s\n' \
        "$(printf '%s' "$GRCUR" | tr '\n' ' ')" "$(printf '%s' "$GRBEH" | tr '\n' ' ')" \
        "$(printf '%s' "$GRUNK" | tr '\n' ' ')" "$(printf '%s' "$GRNOS" | tr '\n' ' ')" \
       | sort -u | wc -l | tr -d ' ')" "4"
has "a current graph still names the command that asks it"   "$GRCUR" "graphify query"
has "a stale one does too, because stale is not wrong"       "$GRBEH" "graphify query"
has "a graph of another tree does too"                       "$GRUNK" "graphify query"
has "and a graph with no stamp does too"                     "$GRNOS" "graphify query"
# A banner that names somebody's home directory is noise, and the reason the
# stamp is printed short. Counted rather than matched on the fixture path,
# because the failure this guards against is any absolute path, not this one.
is "the current line prints no absolute path"        "$(_grabs "$GRCUR")" "0"
is "nor the stale one"                               "$(_grabs "$GRBEH")" "0"
is "nor the one about another tree"                  "$(_grabs "$GRUNK")" "0"
is "nor the one about a missing stamp"               "$(_grabs "$GRNOS")" "0"
is "and none of them names the checkout it read"     \
   "$(_grsays "$GRCUR$GRBEH$GRUNK$GRNOS" "$GRHP")" "no"
if [ -d "$GRW" ]; then
  printf '{"nodes":[],"built_at_commit":"%s"}\n' "$GRSEED" > "$GRJ"
  is "a session in a worktree is told the holding checkout's line, word for word" \
     "$(_gr felix_graph_line "$GRW")" "$GRBEH"
else
  skip "a session in a worktree is told the holding checkout's line, word for word" \
       "worktree add failed"
fi
# Silence is the correct output. Most projects Felix governs have no graph, and
# a banner saying so every session would be the noise that gets banners ignored.
GRX="$TMP/graphungraphed"; mkdir -p "$GRX"
( _fx_cd "$GRX" && git init -q -b main && printf 'x\n' > a.txt && git add -A \
  && git -c user.name=t -c user.email=t@t commit -qm seed ) >/dev/null 2>&1
out="$(_gr felix_graph_line "$GRX" 2>&1)"; rc=$?
is "a project with no graph is told nothing at all"  "$out" ""
is "and the silence carries an exit code"            "$rc"  "1"
out="$(_gr felix_graph_line "$GRPLAIN" 2>&1)"; rc=$?
is "and a directory in no repository hears nothing either" "$out" ""
is "with the same exit code"                               "$rc"  "1"

# -- 6. the refresh ---------------------------------------------------------
# Best-effort upkeep with a hard rule attached: it may never fail a session and
# it may never make one wait. The stand-in graphify records its argv and then
# blocks until a flag file appears, which is what lets the assertions below ask
# what happens WHILE a refresh is running without racing a sleep.
GRB="$TMP/graphbin"; mkdir -p "$GRB"
GRLOG="$TMP/graphify-calls.log"; : > "$GRLOG"
GRGO="$TMP/graphify-release"
cat > "$GRB/graphify" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$GRLOG"
_tries=0
while [ ! -f "$GRGO" ] && [ "\$_tries" -lt 100 ]; do sleep 0.1; _tries=\$((_tries+1)); done
EOF
chmod +x "$GRB/graphify"
_grbg()   { ( PATH="$1:$PATH"; export PATH
              . "$FROOT/harness/lib/resolve.sh"; . "$FROOT/harness/lib/graph.sh"
              felix_graph_refresh_bg "$2" ); }
# Polling, not sleeping: a fixed sleep is either flaky or slow, and both of
# those are how a test about backgrounding stops meaning anything.
_grpoll() { _gri=0; while ! eval "$2" && [ "$_gri" -lt "$1" ]; do sleep 0.1
              _gri=$((_gri+1)); done; }

# No graphify installed. A sanitised PATH, not a renamed fixture, because a
# developer with a real graphify would otherwise have this suite build a real
# graph of a throwaway repository.
out="$(PATH=/usr/bin:/bin bash -c \
       '. "$1/lib/resolve.sh"; . "$1/lib/graph.sh"; felix_graph_refresh_bg "$2"' \
       _ "$FROOT/harness" "$GRH" 2>&1)"; rc=$?
_grpoll 10 '[ -s "$GRLOG" ]'
is "with no graphify installed the refresh runs nothing"  "$(wc -l < "$GRLOG" | tr -d ' ')" "0"
is "and exits 0, because upkeep may never fail a session" "$rc" "0"
is "and says nothing while not doing it"                  "$out" ""
# Installed, but this checkout has never been graphed, so there is nothing to
# keep up to date and a build would be a surprise, not a refresh.
out="$(_grbg "$GRB" "$GRX" 2>&1)"; rc=$?
_grpoll 10 '[ -s "$GRLOG" ]'
is "with no graphify-out beside the checkout it runs nothing" \
   "$(wc -l < "$GRLOG" | tr -d ' ')" "0"
is "and exits 0 for an ungraphed checkout too"  "$rc"  "0"

GRT0=$SECONDS
out="$(_grbg "$GRB" "$GRH" 2>&1)"; rc=$?
GRT1=$SECONDS
is "a refresh of a graphed checkout exits 0"  "$rc"  "0"
is "and prints nothing into the session"      "$out" ""
# The stand-in blocks for up to ten seconds. If the call had waited for it, this
# is the assertion that would say so.
is "and hands the session back at once rather than waiting for the build" \
   "$( [ "$((GRT1-GRT0))" -lt 3 ] && printf 'prompt\n' || printf 'waited\n' )" "prompt"
_grpoll 100 '[ -s "$GRLOG" ]'
has "and it asks graphify to update the checkout that holds the graph" \
    "$(cat "$GRLOG")" "$GRHP"
# The lock, while it is held. A lock FILE left behind by a killed session would
# wedge every refresh after it and nothing would report that; mkdir is the
# atomic test-and-set that makes the stale case survivable. graphify-out is the
# only place beside the graph this library keeps state, so that is where the
# assertion looks.
is "the lock it takes while refreshing is a directory, not a file" \
   "$(find "$GRH/graphify-out" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" "1"
is "and it left no lock file beside the graph" \
   "$(find "$GRH/graphify-out" -mindepth 1 -maxdepth 1 -type f | wc -l | tr -d ' ')" "1"
out="$(_grbg "$GRB" "$GRH" 2>&1)"; rc=$?
_grpoll 10 '[ "$(wc -l < "$GRLOG" | tr -d " ")" -gt 1 ]'
is "a second refresh while one is running does nothing" \
   "$(wc -l < "$GRLOG" | tr -d ' ')" "1"
is "and still exits 0"  "$rc"  "0"
if [ -d "$GRW" ]; then
  out="$(_grbg "$GRB" "$GRW" 2>&1)"; rc=$?
  _grpoll 10 '[ "$(wc -l < "$GRLOG" | tr -d " ")" -gt 1 ]'
  is "and a call from a worktree is held by the same lock, there being one graph" \
     "$(wc -l < "$GRLOG" | tr -d ' ')" "1"
else
  skip "and a call from a worktree is held by the same lock, there being one graph" \
       "worktree add failed"
fi
: > "$GRGO"
_grpoll 100 '[ "$(find "$GRH/graphify-out" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " ")" = 0 ]'
is "the lock is released when the refresh finishes" \
   "$(find "$GRH/graphify-out" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" "0"
if [ -d "$GRW" ]; then
  : > "$GRLOG"
  _grbg "$GRB" "$GRW" >/dev/null 2>&1
  _grpoll 100 '[ -s "$GRLOG" ]'
  has "a worktree refreshes the holding checkout's graph" "$(cat "$GRLOG")" "$GRHP"
  is  "and never asks for a graph of the worktree, which has none" \
      "$(_grsays "$(cat "$GRLOG")" "$GRWP")" "no"
else
  skip "a worktree refreshes the holding checkout's graph" "worktree add failed"
  skip "and never asks for a graph of the worktree, which has none" "worktree add failed"
fi
# Whatever happens. The lock cannot be created at all here, which is the one
# failure this function can actually meet in the field — a graph directory
# someone made read-only, or one on a full disk.
chmod 555 "$GRH/graphify-out" 2>/dev/null
if ( : > "$GRH/graphify-out/.graphprobe" ) 2>/dev/null; then
  skip "a graph directory it cannot write still exits 0" "directory still writable"
  skip "and still says nothing"                          "directory still writable"
else
  out="$(_grbg "$GRB" "$GRH" 2>&1)"; rc=$?
  is "a graph directory it cannot write still exits 0" "$rc"  "0"
  is "and still says nothing"                          "$out" ""
fi
chmod 755 "$GRH/graphify-out" 2>/dev/null
printf '#!/bin/sh\nexit 7\n' > "$GRB/graphify"; chmod +x "$GRB/graphify"
out="$(_grbg "$GRB" "$GRH" 2>&1)"; rc=$?
is "and a graphify that fails outright does not reach the session" "$rc"  "0"
is "nor print at it"                                               "$out" ""


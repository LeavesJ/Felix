# tests/lib/install-fixture.sh: the install fixture of the deployed-surface checks.
# Used by 0630 (builds it, then runs `felix install` from the cache against it)
# and 0640 (reads it in the state 0630 leaves). Moved from
# parts/0630-the-subject-of-a-large-payload.sh lines 230-288 (verbatim, in the
# builder body below): IHOME, ICACHE, ISRC, ICB, ICB_LOG, the claude stub and
# _inst_from_cache.
# Definitions only. _install_fixture_build STATE sets all five names first and
# does nothing more when the fixture is already there, so in the serial run only
# 0630's call builds. STATE names the state it leaves:
#   differing   the state 0630 starts its assertions in: the cache holds the
#               engine, the source holds the engine plus one extra line in
#               lib/escape.sh.
#   after-0630  the state 0640 starts in: differing, then the two commands 0630
#               runs on the trees (copy the source harness over the cache's,
#               then add a line to the source's lib/next.sh). The `felix
#               install` runs between them write only $IHOME/.felix-home and
#               $ICB_LOG, which 0640 never reads, so they are not replayed.

# _install_fixture_build STATE: builds the three trees and the stub when absent.
_install_fixture_build() {
  local state="${1:-differing}"
  IHOME="$TMP/installhome"
  ICACHE="$IHOME/.claude/plugins/cache/felix/felix/0.49.9"
  ISRC="$TMP/installsrc"
  ICB="$TMP/installclaude"
  ICB_LOG="$TMP/installclaude.log"
  [ -x "$ICB/claude" ] && [ -f "$ICACHE/harness/felix" ] && [ -f "$ISRC/engine/harness/felix" ] && return 0
  IHOME="$TMP/installhome"; mkdir -p "$IHOME/.claude/plugins"

  # The engine as Claude Code actually deploys it. marketplace.json declares
  # `"source": "./engine"`, so a version directory under the plugins cache holds
  # the CONTENTS of engine/ — harness/ at its top level, not engine/harness/.
  # Getting that nesting wrong is what makes the issue's own proposed fix wrong:
  # $FELIX_HOME_DIR is the repository ROOT, so "$FELIX_HOME_DIR/harness" names
  # nothing and would turn a false pass into a false failure.
  ICACHE="$IHOME/.claude/plugins/cache/felix/felix/0.49.9"
  mkdir -p "$ICACHE/.claude-plugin"
  cp -R "$FROOT/harness" "$ICACHE/harness"
  printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$ICACHE/.claude-plugin/plugin.json"

  # A source checkout whose engine DIFFERS from what is deployed. This is the
  # state the command exists to detect and the state it reported as clean.
  ISRC="$TMP/installsrc"
  mkdir -p "$ISRC/engine/.claude-plugin" "$ISRC/.claude-plugin"
  cp -R "$FROOT/harness" "$ISRC/engine/harness"
  printf '\n# a line the deployed engine does not have\n' >> "$ISRC/engine/harness/lib/escape.sh"
  printf '{\n  "name": "felix",\n  "version": "0.49.9"\n}\n' > "$ISRC/engine/.claude-plugin/plugin.json"
  printf '{\n  "name": "felix",\n  "plugins": [ { "name": "felix", "source": "./engine" } ]\n}\n' \
    > "$ISRC/.claude-plugin/marketplace.json"

  # The claude stub reports the cache as the live install path, which is what the
  # real CLI reports. Only `plugin list --json` needs a body; the three mutating
  # subcommands are no-ops here because the fixture is the deployed state already.
  ICB="$TMP/installclaude"; mkdir -p "$ICB"
  # The stub mirrors what the real CLI was MEASURED to do, not what is convenient.
  # It used to exit 0 for everything, which is why #66 went unnoticed here: the
  # marketplace path could be wrong and the stub would report success anyway.
  #
  # Measured in a scratch HOME against the real `claude`, so this is a recording
  # and not a guess:
  #   add <repo>/engine  -> exit 1, "Marketplace file not found at
  #                         <repo>/engine/.claude-plugin/marketplace.json"
  #   add <repo>         -> exit 0, registers installLocation=<repo>
  # It does NOT resolve upward. Every argument is logged so the assertion can name
  # the path the command actually passed rather than infer it from the output.
  ICB_LOG="$TMP/installclaude.log"; : > "$ICB_LOG"
  cat > "$ICB/claude" <<STUB
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$ICB_LOG"
case "\$*" in
  "plugin list --json") printf '{ "felix@felix": { "installPath": "%s" } }\n' "$ICACHE" ;;
  "plugin marketplace add "*)
    # \$4, not \${*#plugin marketplace add }. Prefix removal on \$* applies the
    # pattern to each positional parameter separately and then joins, so it
    # strips nothing here and leaves the whole command line — which made the
    # stub reject the correct path and the fix look wrong.
    [ -f "\$4/.claude-plugin/marketplace.json" ] || exit 1 ;;
esac
exit 0
STUB
  chmod +x "$ICB/claude"
  if [ "$state" = "after-0630" ]; then
    cp -R "$ISRC/engine/harness/." "$ICACHE/harness/"
    printf '\n# and another the deployed engine does not have\n' >> "$ISRC/engine/harness/lib/next.sh"
  fi
}

_inst_from_cache() {
  ( cd "$ISRC" && HOME="$IHOME" FELIX_HOME="$ISRC" PATH="$ICB:$PATH" \
      "$ICACHE/harness/felix" install --no-bump 2>&1 )
}

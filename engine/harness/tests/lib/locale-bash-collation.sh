# tests/lib/locale-bash-collation.sh: the locale runner and the runtime-scope lint helpers.
# Used by 0996 (runs _lgb_d_in, builds the lint scope) and 0998 (_lgb_d_scope, _lgb_d_files
# for its L4 lint). Moved from parts/0994-bash-s-own-collation-and-the-bsd-text-tools.sh
# lines 656-663 (_lgb_d_in) and parts/0996-continued.sh lines 98-114 (the comment, _lgb_d_scope,
# _lgb_d_files), verbatim. _lgb_d_in reads LCB_U8, which _locale_bytes_vars (lib/locale-bytes.sh) sets.
# Definitions only.

_lgb_d_in() {  # C|lang|all <command...>: one call in a chosen locale, in a subshell
  local how="$1"; shift
  case "$how" in
    C)    ( export LC_ALL=C; "$@" ) ;;
    lang) ( unset LC_ALL LC_COLLATE LC_CTYPE; export LANG="$LCB_U8"; "$@" ) ;;
    all)  ( export LC_ALL="$LCB_U8"; "$@" ) ;;
  esac
}

# The lints read runtime code: felix, and every file under lib, hooks, bin and
# templates that a shell runs (a .sh file, a sh or bash shebang, or a workflow
# template). Copied from the neighbour's scope, under this prefix.
_lgb_d_scope() {  # <harness dir>: the runtime files, one absolute path a line
  local h="$1" f
  [ -f "$h/felix" ] && printf '%s\n' "$h/felix"
  ( cd "$h" && LC_ALL=C find lib hooks bin templates -type f 2>/dev/null ) | LC_ALL=C sort | while IFS= read -r f; do
    case "$f" in *.sh|*.yml|*.yaml) printf '%s\n' "$h/$f"; continue ;; esac
    LC_ALL=C grep -qE '^#!.*[/[:space:]](ba)?sh([[:space:]]|$)' <<<"$(head -1 "$h/$f" 2>/dev/null)" && printf '%s\n' "$h/$f"
  done
}
_lgb_d_files() {  # <lint function> <prefix> [names] < paths: the lint over each path read
  local fn="$1" pre="$2" names="${3:-}" f; local -a fs=()
  while IFS= read -r f; do fs[${#fs[@]}]="$f"; done
  [ "${#fs[@]}" -gt 0 ] || { printf 'no files\n'; return 0; }
  if [ -n "$names" ]; then "$fn" "$pre" "$names" "${fs[@]}"; else "$fn" "$pre" "${fs[@]}"; fi
}

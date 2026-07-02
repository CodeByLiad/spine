#!/usr/bin/env sh
# Spine task classifier (Phase 2, mechanical signal only).
# Usage: printf '%s\n' file1 file2 ... | sh hooks/classify-task.sh
#    or: sh hooks/classify-task.sh file1 file2 ...
# Reads paths from argv if given, else one per line from stdin. Checks each
# against .spine/danger-paths globs (one per line, '#'-comments/blank ignored).
# Any match -> classification B (any single danger-path hit forces "large",
# regardless of file count - per the Spine classifier rule). No match on any
# path -> A. This covers ONE of the three classifier signals (files touched).
# The other two (new external contract, design ambiguity) are judgment calls
# the controller applies itself per subagent-driven-dev - they cannot be
# mechanically detected from a file list. Take the highest tier any signal
# reaches; this script only ever raises the floor, never lowers a human call.
#
# Fail-open: no danger-paths file, or it's empty of real patterns -> classify A.
# Never blocks anything - this is an advisory classification helper, not a gate.

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$(pwd)
dp="$root/.spine/danger-paths"
bslash=$(printf '\134')

tmp_files=$(mktemp 2>/dev/null) || tmp_files="/tmp/.spine-classify-files.$$"
if [ "$#" -gt 0 ]; then
  for f in "$@"; do printf '%s\n' "$f"; done > "$tmp_files"
else
  cat > "$tmp_files"
fi

if [ ! -f "$dp" ]; then
  echo A
  rm -f "$tmp_files"
  exit 0
fi

tmp_pat=$(mktemp 2>/dev/null) || tmp_pat="/tmp/.spine-classify-pat.$$"
sed -e 's/[[:space:]]*#.*$//' "$dp" | grep -v '^[[:space:]]*$' > "$tmp_pat"

if [ ! -s "$tmp_pat" ]; then
  echo A
  rm -f "$tmp_files" "$tmp_pat"
  exit 0
fi

result=""
while IFS= read -r f || [ -n "$f" ]; do
  [ -z "$f" ] && continue
  fn=$(printf '%s' "$f" | tr "$bslash" '/' 2>/dev/null)
  while IFS= read -r pat || [ -n "$pat" ]; do
    [ -z "$pat" ] && continue
    case "$fn" in
      $pat) result="$pat|$fn"; break 2 ;;
    esac
  done < "$tmp_pat"
done < "$tmp_files"

rm -f "$tmp_files" "$tmp_pat"

if [ -n "$result" ]; then
  echo "B"
  echo "matched: $result" >&2
else
  echo "A"
fi
exit 0

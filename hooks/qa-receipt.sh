#!/usr/bin/env sh
# Record a passing browser-QA pass for the current branch's tip.
# Usage: sh hooks/qa-receipt.sh <verdict> <flow-description...>
# The agent running browser-qa records this after flows are verified live in a
# real running app. Mirrors review-receipt.sh's format (sha/verdict/branch) plus
# a flows field. ADVISORY ONLY - unlike review-receipt (read by the merge-gate
# hook, which mechanically blocks on a hash/sha mismatch), there is no
# mechanical way to verify "did a real browser session actually happen" the way
# a hook can verify "does a file exist with the right content." finishing-a-
# branch reads this as an informational note, never a hard block. No write on
# a non-pass verdict. Fail-open: any git/filesystem error exits 0 without
# writing, never a non-zero (fail-closed) exit.
verdict="$1"
shift
flows="$*"
[ "$verdict" = "pass" ] || { echo "qa-receipt: verdict '$verdict' != pass; no receipt written" >&2; exit 0; }
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
sha=$(git rev-parse HEAD 2>/dev/null) || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
mkdir -p "$root/.spine" 2>/dev/null || exit 0
{
  printf 'sha:     %s\n' "$sha"
  printf 'verdict: pass\n'
  printf 'branch:  %s\n' "$branch"
  printf 'flows:   %s\n' "$flows"
} > "$root/.spine/qa-receipt" 2>/dev/null
exit 0

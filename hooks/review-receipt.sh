#!/usr/bin/env sh
# Record a passing whole-branch review for the current branch's tip.
# Usage: sh hooks/review-receipt.sh <verdict>   (writes only when verdict = "pass")
# The CONTROLLER runs this immediately after the final review returns clean, while
# still on the reviewed branch. The merge-gate hook only ever READS the result, so
# a single writer path guarantees one format. No write on a non-pass verdict
# (mirrors config-contract: no marker unless the check passed). Fail-open: any git
# or filesystem error exits 0 without writing, never a non-zero (fail-closed) exit.
verdict="$1"
[ "$verdict" = "pass" ] || { echo "review-receipt: verdict '$verdict' != pass; no receipt written" >&2; exit 0; }
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
sha=$(git rev-parse HEAD 2>/dev/null) || exit 0
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0
mkdir -p "$root/.spine" 2>/dev/null || exit 0
{
  printf 'sha:     %s\n' "$sha"
  printf 'verdict: pass\n'
  printf 'branch:  %s\n' "$branch"
} > "$root/.spine/review-receipt" 2>/dev/null
exit 0

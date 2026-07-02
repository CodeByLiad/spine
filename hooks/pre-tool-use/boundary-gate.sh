#!/usr/bin/env sh
# Spine golden-rule import-boundary guard (Phase 2, rule #3: enforce in tooling).
# Blocks Write/Edit/MultiEdit when the file being written matches a glob in
# .spine/import-boundaries AND the new content contains that rule's forbidden
# substring. Generalizes "an app's routes/services must not import another
# product's schema tables directly" into a per-repo-configurable rule, since
# Spine has no fixed notion of "product" or "schema" for an arbitrary stack.
#
# Scope (intentionally simple, stated plainly, not oversold): whole-new-content
# substring scan, not a real per-language import-statement parser. False
# positives (matching inside a comment or string) are possible and favor
# safety; false negatives (obfuscated/dynamic imports) are not caught. This
# is a mechanical floor, not a substitute for review.
#
# Fail-open: no .spine/import-boundaries, or no rule matches the file's glob,
# or content cannot be extracted -> allow. Never blocks anything Gate A/B/C
# already governs differently; this hook is independent and additive.

input=$(cat)
bslash=$(printf '\134')

extract_field() {  # extract_field <field-name> <json-blob>
  printf '%s' "$2" | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"$bslash]|$bslash$bslash.)*\"" | head -1 | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

fp=$(extract_field file_path "$input")
[ -z "$fp" ] && exit 0

fp_norm=$(printf '%s' "$fp" | tr "$bslash" '/' 2>/dev/null)

case "$fp_norm" in
  */.spine/*|.spine/*) exit 0 ;;
esac

cwd=$(extract_field cwd "$input")
[ -z "$cwd" ] && cwd=$(pwd)
cwd=$(printf '%s' "$cwd" | tr "$bslash" '/' 2>/dev/null)

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || root="$cwd"
rules="$root/.spine/import-boundaries"
[ -f "$rules" ] || exit 0

# Glob rules are repo-relative (matching danger-paths convention); file_path
# from the tool is always absolute. Do NOT string-strip a derived root prefix
# to get a relative path: git's reported toplevel and the tool's own cwd/
# file_path can differ in path style/casing (seen on Windows: git-bash's git
# emits drive-letter paths while the tool JSON may use a different form), and
# a silent prefix-match failure would make every rule permanently inert
# without warning - worse than not having the check. Instead match each rule
# glob as a path SUFFIX: try it bare and prefixed with "*/", which works
# regardless of how the absolute prefix is spelled.

# gather every string field that could carry new file content, across
# Write (content), Edit (new_string), MultiEdit (repeated new_string entries)
content=""
c1=$(extract_field content "$input"); [ -n "$c1" ] && content="$content
$c1"
c2=$(printf '%s' "$input" | grep -oE "\"new_string\"[[:space:]]*:[[:space:]]*\"([^\"$bslash]|$bslash$bslash.)*\"" | sed -E "s/^\"new_string\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//")
[ -n "$c2" ] && content="$content
$c2"
[ -z "$content" ] && exit 0

tmp_rules=$(mktemp 2>/dev/null) || tmp_rules="/tmp/.spine-boundary-rules.$$"
sed -e 's/[[:space:]]*#.*$//' "$rules" | grep -v '^[[:space:]]*$' > "$tmp_rules"
[ -s "$tmp_rules" ] || { rm -f "$tmp_rules"; exit 0; }

while IFS= read -r rule || [ -n "$rule" ]; do
  [ -z "$rule" ] && continue
  glob=$(printf '%s' "$rule" | sed -E 's/[[:space:]]*::.*$//')
  forbidden=$(printf '%s' "$rule" | sed -E 's/^[^:]*::[[:space:]]*//')
  [ -z "$glob" ] && continue
  [ -z "$forbidden" ] && continue
  case "$fp_norm" in
    $glob|*/$glob)
      if printf '%s' "$content" | grep -qF "$forbidden"; then
        echo "SPINE BOUNDARY GATE BLOCKED this write." >&2
        echo "File: $fp_norm matches boundary rule '$glob' and its new content contains forbidden reference '$forbidden'." >&2
        echo "This is the golden-rule import-boundary guard (.spine/import-boundaries) - edit that file if this rule is wrong for this change, or remove the reference." >&2
        echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
        rm -f "$tmp_rules"
        exit 2
      fi
      ;;
  esac
done < "$tmp_rules"

rm -f "$tmp_rules"
exit 0

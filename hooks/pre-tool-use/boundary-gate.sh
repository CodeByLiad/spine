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
bb="$bslash$bslash"
bbbb="$bslash$bslash$bslash$bslash"

extract_field() {  # extract_field <field-name> <json-blob>
  printf '%s' "$2" | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"$bslash]|$bslash$bslash.)*\"" | head -1 | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

# Un-escape JSON string escapes left raw by extract_field's regex capture
# (it deliberately keeps `\X` two-byte sequences intact so the surrounding
# quote-boundary match works - it does not interpret them). A forbidden
# reference containing a literal quote (very common: import statements are
# almost always quoted, e.g. `from "moduleB/schema"`) never matched real
# file content because the content still carried the raw two-byte `\"`
# JSON escape instead of a plain `"` - found by a live test. Order matters:
# protect real escaped-backslash sequences behind a placeholder BEFORE
# un-escaping `\"`, or a content bytes like `\\"` (an escaped backslash
# immediately followed by a real quote) would be mis-read.
placeholder="@@SPINE_BOUNDARY_BSLASH@@"
unescape_json() {
  printf '%s' "$1" | sed "s/$bbbb/$placeholder/g" | sed "s/$bslash$bslash\"/\"/g" | sed "s/$placeholder/$bslash$bslash/g"
}

# Normalize path separators: JSON-escaped Windows paths carry a literal
# double-backslash per separator (the raw bytes of the JSON escape "\\"),
# so this must collapse a run of 4 raw backslash BYTES (which is what a
# grep -oE JSON-string extraction leaves in the shell variable for one
# path separator) to a single slash FIRST, then any leftover lone
# backslash to a slash. A naive one-pass `tr` of single backslash chars
# to slashes doubles separators instead of collapsing them, which made
# every glob rule silently inert on Windows - confirmed by a live test.
norm_path() {
  printf '%s' "$1" | sed "s/${bbbb}/\//g; s/${bb}/\//g"
}

fp=$(extract_field file_path "$input")
[ -z "$fp" ] && exit 0

fp_norm=$(norm_path "$fp")

case "$fp_norm" in
  */.spine/*|.spine/*) exit 0 ;;
esac

cwd=$(extract_field cwd "$input")
[ -z "$cwd" ] && cwd=$(pwd)
cwd=$(norm_path "$cwd")

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
content=$(unescape_json "$content")

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

#!/usr/bin/env sh
# Spine FRAME gate (rule #3: enforce in tooling, not willpower).
# Blocks Write/Edit/MultiEdit on CODE files until FRAME is approved for the
# current git branch. FRAME approval writes .spine/frame-approved (the `framing`
# skill does this at its approval gate). Non-code files and .spine/ are always
# allowed so the gate can never deadlock its own approval marker.
#
# Fail-open on parse/IO errors: a gate that bricks all writes is worse than a
# skipped one. We only ever DENY when we positively identify an ungated code write.

input=$(cat)

# --- extract file_path from the tool input JSON (no jq dependency) ---
fp=$(printf '%s' "$input" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//')
[ -z "$fp" ] && exit 0   # no file path on this tool call -> not our concern

# normalize Windows backslashes (raw and JSON-escaped) to forward slashes
fp_norm=$(printf '%s' "$fp" | sed 's/\\\\/\//g; s/\\/\//g')

# .spine state is always writable (marker, config, ledger) -> no deadlock
case "$fp_norm" in
  */.spine/*|.spine/*) exit 0 ;;
esac

# code file? DENYLIST of known-safe non-code, not an allowlist of known-code.
# Deliberately the opposite default of a typical extension check: unknown
# extensions fall through to the gate (fail-closed), not past it (fail-open).
# This project's own history is a repeated pattern of an allowlist forgetting
# an extension and silently bypassing the hard gate (html/css were missing
# entirely and let a full React prototype through with zero FRAME approval) -
# a denylist's failure mode on an unlisted type is the opposite direction: an
# unnecessary gate on a genuinely harmless new file type, which is annoying
# but self-correcting (add one line here), not a silent bypass nobody notices.
# This also closes a second, structural gap no allowlist could: an
# extensionless file (Dockerfile, Makefile, Jenkinsfile, Gemfile, Rakefile,
# Vagrantfile, Procfile) has no "." for this extraction to find, so `ext`
# becomes the whole lowercased filename - none of those match the safe list
# below, so they correctly fall through to the gate as code, same as any
# other unrecognized type. YAML/YAML-like config is deliberately NOT on the
# safe list either - CI pipelines and k8s manifests are logic, not pure data.
# `.env` is deliberately NOT on the list either, even though it looks like
# the other flat key=value data files here - it routinely carries the exact
# DB/project/env config Gate B/C exist to pin and assert, and (unlike toml/
# ini) a live test found its own naive inclusion didn't even do what it
# looked like: last-dot-wins extraction only caught bare ".env", not
# ".env.local"/".env.production" - the variants actually used in practice.
# Known, accepted costs of this design (fail toward the gate, not silently
# past it): a few common tool dotfiles (.eslintrc, .prettierrc, .babelrc)
# and pnpm-lock.yaml (collides with the yaml exclusion) now gate when they
# didn't before. Both are one-line additions here if they prove annoying
# enough to matter - the point of a denylist is that this is cheap to fix
# and self-correcting, unlike a silent bypass nobody notices.
# Isolate the basename FIRST, then the extension - extracting from the full
# path directly (as the old allowlist version did) breaks for extensionless
# files: with no dot anywhere in the whole path, `.*\.` can't match at all
# and `ext` becomes the entire lowercased path, not the bare filename, so
# "LICENSE" at repo root never matches the safe list below. Confirmed by
# direct testing before this line existed - a real, distinct bug from the
# extension-list gap this rewrite otherwise fixes.
base=$(printf '%s' "$fp_norm" | sed -E 's#.*/##')
ext=$(printf '%s' "$base" | sed -E 's/.*\.//' | tr 'A-Z' 'a-z')
case "$ext" in
  md|mdx|txt|rst|adoc|json|jsonc|json5|csv|tsv|toml|ini|cfg|lock|lockb|properties|\
png|jpg|jpeg|gif|svg|ico|webp|bmp|tiff|avif|\
mp4|mp3|wav|ogg|woff|woff2|ttf|eot|otf|pdf|\
map|log|gitignore|gitattributes|editorconfig|npmrc|nvmrc|\
license|notice|authors|contributors|changelog|readme) exit 0 ;;
esac

# resolve repo root from the hook's cwd field (fallback to pwd)
cwd=$(printf '%s' "$input" | grep -oE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//' | sed 's/\\\\/\//g; s/\\/\//g')
[ -z "$cwd" ] && cwd=$(pwd)

# --- lazy scaffold: lay down the .spine skeleton on first code write ---
# Runs inside the hook (trusted) so it never triggers a permission prompt — this is
# what keeps a fresh install prompt-free without the plugin needing to grant itself
# write permissions (plugins cannot). config.md is deliberately NOT scaffolded here:
# it is a grilled FRAME deliverable the `framing` skill writes with real values, so
# Gate B below stays meaningful (config.md present ⟹ filled). Per-file + idempotent.
plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)}"
tpl="$plugin_root/templates/.spine"
if [ -d "$tpl" ]; then
  mkdir -p "$cwd/.spine" 2>/dev/null
  for f in context.md danger-paths progress.md capability-log.md .gitignore; do
    [ -f "$tpl/$f" ] && [ ! -f "$cwd/.spine/$f" ] && cp "$tpl/$f" "$cwd/.spine/$f" 2>/dev/null
  done
fi

marker="$cwd/.spine/frame-approved"
config="$cwd/.spine/config.md"
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

# --- Gate A: FRAME approved for this branch (rule: no code before design approval) ---
frame_ok=0
if [ -f "$marker" ]; then
  approved=$(cat "$marker" 2>/dev/null)
  # approved for this branch, or branch undetectable (non-git) -> frame satisfied
  if [ "$approved" = "$branch" ] || [ -z "$branch" ]; then
    frame_ok=1
  elif [ "$approved" = "HEAD" ] && [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
    # FRAME can be approved before the first commit exists, when
    # `git rev-parse --abbrev-ref HEAD` has no branch to report and returns
    # the literal string "HEAD" - git's own sentinel for "unborn branch",
    # never a name a human could have smuggled unapproved work in on. Once
    # the first commit lands, the branch resolves to its real name and the
    # stored marker goes stale through no action of anyone's - re-stamping
    # it here is closing an approval that already happened, not granting a
    # new one. This must live in the hook, not a skill instruction: rule #3
    # says a gate depending on someone remembering to re-record isn't a gate.
    printf '%s' "$branch" > "$marker" 2>/dev/null
    frame_ok=1
  fi
fi

if [ "$frame_ok" -ne 1 ]; then
  echo "SPINE FRAME GATE BLOCKED this write." >&2
  echo "File: $fp_norm (code) — FRAME is not approved for branch '${branch:-<none>}'." >&2
  echo "Invoke the \`framing\` skill, align on a design, and get the user's approval." >&2
  echo "Approval records .spine/frame-approved and unlocks code writes on this branch." >&2
  echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
  exit 2
fi

# --- Gate B: config contract pinned (rule #5: pin cross-cutting context before task one) ---
# FRAME is approved but the build target was never pinned. A build that passes
# every per-task gate while pointed at the wrong DB/project/env is the exact
# blind spot config-contract closes. No code write proceeds without it.
if [ ! -f "$config" ]; then
  echo "SPINE CONFIG GATE BLOCKED this write." >&2
  echo "File: $fp_norm (code) — FRAME is approved but .spine/config.md is missing." >&2
  echo "Generate the config contract (stack, test runner, DB/project/env, danger paths," >&2
  echo "conventions) per the \`config-contract\` skill, scaffolding from templates/.spine/." >&2
  echo "(Spine rule #5: pin cross-cutting context before task one.)" >&2
  exit 2
fi

# --- Gate C: config contract asserted against CURRENT config (rule #5) ---
# FRAME approved and config.md present, but was the contract actually asserted
# against THIS content? The agent runs the boot assertion (only it can know the
# target is right) and records the config hash on pass; here we recompute and
# compare. A changed contract => stale hash => blocked until re-asserted. This is
# what makes "wrong DB/env" fail before task one, mechanically (Phase-1 gate 4e).
asserted="$cwd/.spine/config-asserted"
cfg_hash=$(sh "$plugin_root/hooks/config-hash.sh" "$config" 2>/dev/null)
if [ -n "$cfg_hash" ]; then          # empty => no hash tool => fail-open, skip Gate C
  recorded=""
  [ -f "$asserted" ] && recorded=$(cat "$asserted" 2>/dev/null | tr -d ' \r\n')
  if [ "$cfg_hash" != "$recorded" ]; then
    echo "SPINE ASSERT GATE BLOCKED this write." >&2
    echo "File: $fp_norm (code) — .spine/config.md is not asserted (config changed or never asserted)." >&2
    echo "Run the config-contract boot assertion; on pass it records the config hash to .spine/config-asserted." >&2
    echo "(Spine rule #5: pin AND assert cross-cutting context before task one; a changed contract must be re-asserted.)" >&2
    exit 2
  fi
fi

exit 0

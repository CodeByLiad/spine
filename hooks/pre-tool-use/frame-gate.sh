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

# code file? (extension allowlist; everything else passes through)
ext=$(printf '%s' "$fp_norm" | sed -E 's/.*\.//' | tr 'A-Z' 'a-z')
case "$ext" in
  js|jsx|ts|tsx|mjs|cjs|py|go|rs|java|rb|php|c|cc|cpp|cxx|h|hh|hpp|cs|swift|kt|kts|scala|clj|cljs|ex|exs|vue|svelte|sql|sh|bash|html|htm|xhtml|css|scss|sass|less) : ;;
  *) exit 0 ;;   # docs, json/yaml config, md, etc. -> allowed
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

#!/usr/bin/env sh
# Spine merge gate (Gate D, rule #3: enforce in tooling, not willpower).
# Blocks `git merge` / `git push` until a passing whole-branch review is recorded
# for the integrated branch's current tip (.spine/review-receipt). Fail-open on
# non-merge/push, non-git, or an unresolvable target — never brick all merges.
#
# The raw command is split on statement-chaining operators (; & && ||) into
# segments, and EACH segment is independently tokenized to find its own
# `git <subcommand>` (stepping over global flags). This closes two related
# bypasses a live test found in earlier drafts of this gate:
#   - "git merge master; echo done" word-splits its target into "master;",
#     which never resolves, so a single-command tokenizer's own fail-open
#     path let the real ungated merge run.
#   - "git branch x; git merge y" has "branch" as its FIRST git subcommand;
#     a check gated on "the first subcommand is merge/push" never reaches
#     the later, real merge at all.
# Per-segment tokenizing finds the real merge/push wherever it sits in the
# chain, without falling back to a raw substring scan of the whole line
# (which would falsely trip on any command merely mentioning the words
# "git" and "merge" as unrelated text - e.g. inside a quoted string or
# comment - rather than actually invoking them; an earlier draft of this
# fix did exactly that and broke unrelated Bash calls).
#
# A command containing backtick / $(...) command substitution is denied
# outright if it also mentions git together with merge/push anywhere,
# because a nested substitution cannot be safely split into segments by
# this plain-text splitter; that stays a conservative raw check.
#
# If MORE THAN ONE segment resulted from the split (i.e. the command is
# genuinely chained/compound) and a merge/push segment's target does not
# resolve, this denies rather than falling open — chaining already proves
# intent to run more than one command, so "can't resolve the target" reads
# as obfuscation, not an innocent unparseable one-liner. A truly standalone,
# unchained command whose target doesn't resolve still fails open, as before.
input=$(cat)

cmd=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
[ -z "$cmd" ] && exit 0

case "$cmd" in
  *'`'*|*'$('*)
    case "$cmd" in
      *git*)
        case "$cmd" in
          *merge*|*push*)
            echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
            echo "Command: $cmd — contains command substitution (backtick or \$()) alongside a git+merge/push mention; this cannot be safely decomposed to verify against .spine/review-receipt. Run the merge/push as its own standalone command." >&2
            echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
            exit 2
            ;;
        esac
        ;;
    esac
    ;;
esac

cwd=$(printf '%s' "$input" | grep -oE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//' | sed 's/\\\\/\//g; s/\\/\//g')
[ -z "$cwd" ] && cwd=$(pwd)
git -C "$cwd" rev-parse HEAD >/dev/null 2>&1 || exit 0   # not a git repo -> fail-open

resolve() { git -C "$cwd" rev-parse --verify --quiet "${1}^{commit}" 2>/dev/null; }

receipt="$cwd/.spine/review-receipt"
rec_sha=""; rec_verdict=""; rec_branch=""
if [ -f "$receipt" ]; then
  rec_sha=$(sed -n 's/^sha:[[:space:]]*//p' "$receipt" | tr -d ' \r\n')
  rec_verdict=$(sed -n 's/^verdict:[[:space:]]*//p' "$receipt" | tr -d ' \r\n')
  rec_branch=$(sed -n 's/^branch:[[:space:]]*//p' "$receipt" | tr -d ' \r\n')
fi

deny() {
  echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
  echo "Command: $cmd — no passing whole-branch review is recorded for branch '$1' at ${2:-<unresolved>}." >&2
  echo "Dispatch the spine-final-reviewer; on PASS the controller records .spine/review-receipt via hooks/review-receipt.sh." >&2
  echo "Adding commits after a review moves the branch tip and invalidates the receipt — re-review." >&2
  echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
  exit 2
}

deny_unresolved_chained() {
  echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
  echo "Command: $cmd — this is a chained/compound command whose git $1 segment's target could not be resolved to verify against .spine/review-receipt. A chained command's unresolvable target is treated as obfuscation, not an innocent one-liner; run the $1 as its own standalone command." >&2
  echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
  exit 2
}

check() {   # check <branch> <sha>: deny unless receipt matches
  [ "$rec_verdict" = "pass" ] && [ "$rec_branch" = "$1" ] && [ "$rec_sha" = "$2" ] || deny "$1" "$2"
}

# split on chaining operators into segments; count how many are non-empty
segments=$(printf '%s' "$cmd" | sed -e 's/&&/\
/g' -e 's/||/\
/g' -e 's/[;&|]/\
/g')
seg_count=0
old_ifs=$IFS
IFS='
'
for seg in $segments; do
  [ -n "$(printf '%s' "$seg" | tr -d '[:space:]')" ] && seg_count=$((seg_count + 1))
done
IFS=$old_ifs
chained=0
[ "$seg_count" -gt 1 ] && chained=1

# Collapse spaces INSIDE quoted spans to a placeholder byte before naive
# whitespace tokenizing, so `-C "path with spaces"` counts as one token
# instead of splitting into several — a live test found the un-fixed
# version treats a mid-path fragment as the git subcommand, fails the
# merge/push check, and lets the real merge run un-gated. No eval, no
# code execution — pure text scan via looping sed substitution.
collapse_quotes() {
  ph=$(printf '\001')
  s="$1"
  while :; do
    new=$(printf '%s' "$s" | sed "s/\(\"[^\"]*\) \([^\"]*\"\)/\1${ph}\2/")
    [ "$new" = "$s" ] && break
    s="$new"
  done
  while :; do
    new=$(printf '%s' "$s" | sed "s/\('[^']*\) \([^']*'\)/\1${ph}\2/")
    [ "$new" = "$s" ] && break
    s="$new"
  done
  printf '%s' "$s"
}

evaluate_segment() {  # evaluate_segment <segment-text> — returns via exit()/deny() or plain return
  seg=$(collapse_quotes "$1")
  # IFS is narrowed to newline-only by the caller's segment loop; restore
  # normal word-splitting (space/tab/newline) just for this tokenize step,
  # or a whole segment like "git branch x" becomes ONE token (no spaces to
  # split on) and can never match "git" at all - found by direct testing.
  seg_ifs_save=$IFS
  unset IFS
  set -f
  # shellcheck disable=SC2086
  set -- $seg
  set +f
  IFS=$seg_ifs_save
  # "git" must be in COMMAND POSITION - the segment's first token, optionally
  # after simple NAME=VALUE env-assignment tokens - not merely present ANYWHERE
  # in the token stream. A plain scan-for-"git" (the original approach) treats
  # "echo test git merge behavior" as a git invocation, because "git" and
  # "merge" happen to appear as arguments to an unrelated `echo` - found by
  # direct testing. Requiring command position excludes that while still
  # matching real chained/prefixed invocations like "GIT_AUTHOR=x git merge y".
  found_git=0; sub=""; redir=0
  while [ $# -gt 0 ]; do
    case "$1" in
      *=*) shift ;;
      git) found_git=1; shift; break ;;
      *) break ;;
    esac
  done
  [ "$found_git" -eq 1 ] || return 1   # "git" was not this segment's command word

  while [ $# -gt 0 ]; do
    tok=$1; shift
    case "$tok" in
      -C|--git-dir|--work-tree) redir=1; shift ;;
      --git-dir=*|--work-tree=*) redir=1 ;;
      -c|--namespace) shift ;;
      -*) : ;;
      *) sub=$tok; break ;;
    esac
  done
  [ "$sub" = "merge" ] || [ "$sub" = "push" ] || return 1   # not a merge/push segment

  if [ "$redir" -eq 1 ]; then
    echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
    echo "Command: $cmd — uses -C/--git-dir/--work-tree; the target repository cannot be verified against .spine/review-receipt. Run it from the repository's own working directory." >&2
    echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
    exit 2
  fi

  if [ "$sub" = "merge" ]; then
    for tok in "$@"; do
      case "$tok" in -*) continue ;; esac
      tsha=$(resolve "$tok") || true
      if [ -n "$tsha" ]; then
        check "$tok" "$tsha"
        return 0
      fi
    done
    [ "$chained" -eq 1 ] && deny_unresolved_chained "merge"
    return 1   # standalone unchained, genuinely unparseable target -> caller fails open
  else
    seen_remote=0; pushed=""
    for tok in "$@"; do
      case "$tok" in -*) continue ;; esac
      if [ "$seen_remote" -eq 0 ]; then seen_remote=1; continue; fi
      pushed="$pushed ${tok%%:*}"
    done
    [ -z "$(printf '%s' "$pushed" | tr -d ' ')" ] && pushed=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    any_resolved=0
    for b in $pushed; do
      bsha=$(resolve "$b") || true
      [ -z "$bsha" ] && continue
      any_resolved=1
      check "$b" "$bsha"
    done
    [ "$any_resolved" -eq 0 ] && [ "$chained" -eq 1 ] && deny_unresolved_chained "push"
    return 0
  fi
}

IFS='
'
for seg in $segments; do
  [ -z "$(printf '%s' "$seg" | tr -d '[:space:]')" ] && continue
  evaluate_segment "$seg"
done
IFS=$old_ifs
exit 0

#!/usr/bin/env sh
# Spine merge gate (Gate D, rule #3: enforce in tooling, not willpower).
# Blocks `git merge` / `git push` until a passing whole-branch review is recorded
# for the integrated branch's current tip (.spine/review-receipt). Fail-open on
# non-merge/push, non-git, or an unresolvable target — never brick all merges.
#
# Parsing is tokenizing + resolution-based (not substring/sed): the command is
# word-split (collapsing irregular whitespace), the git subcommand is located past
# any global flags, and the integrated ref is found by asking git which candidate
# token actually resolves to a commit. A merge/push that redirects the target repo
# (-C / --git-dir / --work-tree) is denied outright, because the receipt lookup runs
# against the session cwd and cannot verify a different target repository.
#
# A command containing a shell metacharacter that can chain additional commands
# (; & | ` $() is ALSO denied outright once a merge/push subcommand is found,
# rather than falling through to the unresolvable-target fail-open path. A live
# test found that plain word-splitting turns "git merge master; echo done" into
# tokens "master;" "echo" "done" — none of which resolve to a commit — so the
# original fail-open logic let the real `git merge master` run ungated. Denying
# on any chaining metacharacter closes that; it does not weaken the fail-open
# behavior for genuinely unparseable single (non-chained) commands.
input=$(cat)

cmd=$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"//; s/"$//')
[ -z "$cmd" ] && exit 0

cwd=$(printf '%s' "$input" | grep -oE '"cwd"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' | head -1 | sed -E 's/^"cwd"[[:space:]]*:[[:space:]]*"//; s/"$//' | sed 's/\\\\/\//g; s/\\/\//g')
[ -z "$cwd" ] && cwd=$(pwd)
git -C "$cwd" rev-parse HEAD >/dev/null 2>&1 || exit 0   # not a git repo -> fail-open

# tokenize the command (word-split, no glob expansion)
set -f
# shellcheck disable=SC2086
set -- $cmd
set +f

# locate `git <subcommand>`, stepping over git global flags. A repo-redirecting
# global flag sets redir=1 so we can refuse (target repo unverifiable).
found_git=0; sub=""; redir=0
while [ $# -gt 0 ]; do
  tok=$1; shift
  if [ "$found_git" -eq 0 ]; then
    [ "$tok" = "git" ] && found_git=1
    continue
  fi
  case "$tok" in
    -C|--git-dir|--work-tree) redir=1; shift ;;     # redirect + separate value
    --git-dir=*|--work-tree=*) redir=1 ;;           # redirect, attached value
    -c|--namespace) shift ;;                        # value-taking, non-redirecting
    -*) : ;;                                        # other global flag
    *) sub=$tok; break ;;
  esac
done
[ "$sub" = "merge" ] || [ "$sub" = "push" ] || exit 0
# remaining positional params ($@) are the subcommand's args

case "$cmd" in
  *';'*|*'&'*|*'|'*|*'`'*|*'$('*)
    echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
    echo "Command: $cmd — contains a shell metacharacter that can chain or hide additional commands past this parser's plain word-splitting. A merge/push inside a compound command cannot be safely verified; run it as its own standalone command." >&2
    echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
    exit 2
    ;;
esac

if [ "$redir" -eq 1 ]; then
  echo "SPINE REVIEW GATE BLOCKED this merge/push." >&2
  echo "Command: $cmd — uses -C/--git-dir/--work-tree; the target repository cannot be verified against .spine/review-receipt. Run it from the repository's own working directory." >&2
  echo "(Spine rule #3: a gate that depends on willpower is not a gate.)" >&2
  exit 2
fi

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

check() {   # check <branch> <sha>: deny unless receipt matches
  [ "$rec_verdict" = "pass" ] && [ "$rec_branch" = "$1" ] && [ "$rec_sha" = "$2" ] || deny "$1" "$2"
}

if [ "$sub" = "merge" ]; then
  # target = first arg (in order) that is not a flag AND resolves to a commit.
  # (skips flags and value-taking-flag values like `-m msg`, which do not resolve.)
  for tok in "$@"; do
    case "$tok" in -*) continue ;; esac
    tsha=$(resolve "$tok") || true
    [ -n "$tsha" ] && { check "$tok" "$tsha"; break; }
  done
  # no arg resolved -> genuinely unparseable target -> fail-open
  exit 0
else
  # push: first non-flag arg is the remote; each later non-flag arg is a refspec
  # whose LOCAL side (left of ':') is being pushed. No refspec -> current branch.
  seen_remote=0; pushed=""
  for tok in "$@"; do
    case "$tok" in -*) continue ;; esac
    if [ "$seen_remote" -eq 0 ]; then seen_remote=1; continue; fi
    pushed="$pushed ${tok%%:*}"
  done
  [ -z "$(printf '%s' "$pushed" | tr -d ' ')" ] && pushed=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  for b in $pushed; do
    bsha=$(resolve "$b") || true
    [ -z "$bsha" ] && continue          # unresolvable local ref (tag/HEAD/etc.) -> fail-open for it
    check "$b" "$bsha"
  done
  exit 0
fi

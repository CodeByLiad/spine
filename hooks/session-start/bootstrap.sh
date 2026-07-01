#!/usr/bin/env sh
cat <<'EOF'
<system-reminder>
SPINE ACTIVE. You are running the Spine coding process.
If there is even a 1% chance a Spine skill applies to the task, you MUST invoke it before responding.
Read the `using-spine` skill now for the governing rules and the skill index.
Stage ownership (exactly one skill per stage):
- FRAME (align before any code): `framing`
- PLAN: `writing-plans`
- ISOLATE: `using-git-worktrees`
- BUILD (the engine): `subagent-driven-dev` + `test-driven-development`
- DEBUG: `systematic-debugging`
- REVIEW (whole branch): `requesting-code-review`
- FINISH: `finishing-a-branch`
Do NOT use Superpowers `brainstorming` — `framing` owns alignment.
</system-reminder>
EOF

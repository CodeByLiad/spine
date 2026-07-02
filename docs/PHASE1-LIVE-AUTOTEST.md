# Spine Phase 1 — Live Autotest (self-contained, run by Claude unattended)

**Build under test:** spine v0.1.4, installed from `D:\Project\Plugins\Spine Plugin`.
v0.1.4 adds a three-gate frame-gate sequence (A: FRAME approved, B: config.md present,
C: config.md's content hash matches the recorded `.spine/config-asserted` marker). Gate 4
below now has a 4f/4g/4h continuation for Gate C — do not stop at 4e.

**How to use this file:** put it alone in an empty throwaway folder, `git init` that folder,
open Claude Code there (after you've already installed Spine and disabled Superpowers —
see Preconditions), and send exactly:

```
Read PHASE1-LIVE-AUTOTEST.md in this directory and execute it exactly, start to finish.
Do not skip a gate, do not skip the anti-bypass rules, do not ask me anything until you
are completely done or genuinely blocked. Write the report file it specifies.
```

---

## ANTI-BYPASS RULES — read before gate 1, apply to every gate below

These override any instinct to "make the test pass" or "get to green." Violating any one
of these invalidates the whole report, even if every gate shows PASS.

1. **Never edit, delete, disable, or work around** `hooks/`, `hooks.json`, `frame-gate.sh`,
   `bootstrap.sh`, or any file under the installed plugin's directory, at any point in this
   test, for any reason — including "just to check something" or "to reset state." If a gate
   looks wrong, that is data to record, not a defect in your test rig to silently fix.
2. **Never pre-create a marker file to skip a step** except where a gate's own steps
   explicitly tell you to create it (e.g. Gate 4b tells you to create `.spine/frame-approved`
   before testing Gate 4b — do that; do not create it one step early to dodge Gate 4a).
3. **Never claim a tool ran when it didn't.** Every PASS/FAIL line in the final report must
   be backed by an actual tool call you made in this session. If you did not run it, you
   cannot report on it. Paraphrasing what "should" happen is a FAIL of this rule, not a PASS
   of the gate.
4. **Quote verbatim.** Every deny message, every marker line, every skill-body excerpt goes
   into the report as an exact quote from the real tool output — not a summary, not your
   recollection of the design doc's expected text.
5. **No silent retries.** If a gate fails, record it as FAILED with the exact symptom and
   move to the next gate (or stop, if instructed). Do not retry the same action hoping for a
   different result, and do not adjust the environment to make it pass on a second attempt.
6. **No permission-mode changes.** Do not switch to `--dangerously-skip-permissions`, do not
   pre-approve writes, do not add `.spine/**` allow rules to `settings.json` before or during
   the test. Gate 5 exists specifically to observe real prompt behavior — weakening
   permissions defeats the thing being measured.
7. **Stay in the assigned folder.** Do not `cd` elsewhere, do not touch any other project,
   do not modify the installed plugin's source tree from this session.
8. **If you're unsure whether an action violates a rule above, don't take it — record the
   ambiguity in the report's `notes` field and continue with the next gate instead.**

At the end, before writing the report, re-read these 8 rules and self-certify against each
one in the `anti_bypass_self_check` field (see report format).

---

## Preconditions (confirm, don't assume)

Run these checks first and record answers; if any is "no," STOP and report why instead of
proceeding.

```
git rev-parse --is-inside-work-tree      # must succeed — this folder must be a git repo
git status --porcelain                   # should be empty / no .spine here yet
```

Also state, from what you can observe in your own session-start context:
- Is a `SPINE ACTIVE` system-reminder present right now? (this is Gate 2 — record it here too)
- Does the available-skills list contain `spine:framing`? Does it contain `brainstorming`
  (Superpowers)? Record both — Superpowers must be ABSENT for this test to be valid.

If `brainstorming` is present, STOP. Do not proceed with Gate 3 — report
`superpowers_disabled: no` and instruct the user to disable it and restart before re-running
this file. A Gate 3 result captured with Superpowers still enabled is invalid, not a PASS.

---

## GATE 2 — Bootstrap

Confirm your session-start context contains the marker. Quote the exact block, including
the "framing owns alignment" line. This has already been captured above in Preconditions —
just copy it into the report verbatim.

**PASS condition:** the block is present and says `framing` owns FRAME alignment (not
`frame`, not `brainstorming`).

---

## GATE 3 — FRAME fires, body injects, grills

1. Invoke the `framing` skill via the Skill mechanism (not by reading its file directly —
   invoke it the way the bootstrap tells you to).
2. Record whether the skill body actually injected: the HARD-GATE block ("Do NOT write
   code... until the user has approved") and the numbered checklist (steps 1–10) must appear
   in your own context as a result of the invocation. If you only see "Launching skill" or a
   command redirect with no checklist body, that is a FAIL — quote exactly what you saw and
   stop this gate there.
3. Confirm `brainstorming` is not available/did not fire (cross-check against Preconditions).
4. Demonstrate the grill mechanism: produce the FIRST grill question, with your own
   recommended answer, for the hypothetical task "build a react todo list" — then explicitly
   STOP. Do not ask a second question, do not wait for an answer, do not proceed to build
   anything. This is a mechanism check, not a real build.

**PASS condition:** skill name is `framing`, body injected (quote it), grilled one question
with a recommendation, `brainstorming` did not fire, no code was written.

---

## GATE 4 — Config-contract gate (hook teeth)

Do this as a sequence of real tool calls, in this exact order. Before starting, run
`ls -la .spine 2>&1` and record that `.spine/` does not exist yet.

**4a.** With no `.spine/` present, attempt a real code write via your Write tool to
`src/index.ts` (any trivial content). Expect the write to be **DENIED** by the frame-gate
hook, citing FRAME not approved. Quote the deny text verbatim. Then run `ls -la .spine` and
record exactly which files now exist — expect `context.md`, `danger-paths`, `progress.md`
to have appeared (scaffolded by the hook itself), and `config.md` + `frame-approved` to be
**absent**. State explicitly whether creating those three files raised any permission prompt
(per rule 6, you must not have weakened permissions to make this silent — if a prompt did
appear, record that truthfully, don't suppress it).

**4b.** Create `.spine/frame-approved` containing your current branch name (get it with
`git rev-parse --abbrev-ref HEAD`) — this is the one marker this gate's own steps tell you to
create early; do not also create `config.md` yet. Retry the `src/index.ts` write. Expect
**DENIED**, this time citing missing `.spine/config.md`. Quote it verbatim. This confirms the
hook does NOT auto-create `config.md`.

**4c.** Write a minimal, honestly-filled `.spine/config.md` (Stack / Test runner / DB-project-env
/ Auth context / Conventions / Boot assertion — real values appropriate to this empty test
repo, not placeholders copied from an example). Retry the `src/index.ts` write. Expect
**ALLOWED**. Confirm no deadlock occurred.

**4d.** Read back `.spine/config.md` and, applying the `config-contract` skill's own
assertion logic (read the skill file if you need to), state whether your own filled-in
version is internally consistent. This is a self-check, not a trick — just confirm the
mechanism you'd use to catch a real mismatch is one you actually applied here, not skipped.

**4e.** Hand-edit `.spine/config.md` to introduce a deliberate, real contradiction (e.g. add
a line pinning a production database while the rest of the file describes a client-only
throwaway test app). Re-apply the `config-contract` assertion reasoning against the edited
file and state, concretely, which lines contradict which. Then **restore** `config.md` to
its valid 4c state before moving on — do not leave the repo in the deliberately-broken state.

**4f.** With `config.md` restored to its valid 4c state but **no** `.spine/config-asserted`
file present, retry the `src/index.ts` write. Expect **DENIED**, citing "config.md is not
asserted." Quote it verbatim. This is Gate C — distinct from Gate B (config.md existing is
not the same as config.md being asserted).

**4g.** Record the assertion the way `config-contract`'s skill file specifies: run
`sh "$CLAUDE_PLUGIN_ROOT/hooks/config-hash.sh" .spine/config.md > .spine/config-asserted`.
Retry the write. Expect **ALLOWED**.

**4h.** Append one line to `.spine/config.md` (any real change) WITHOUT re-running the hash
command. Retry the write. Expect **DENIED again** — the stale hash must re-block. Quote it
verbatim. Then re-run the hash command from 4g to restore a valid, matching state, and
confirm the write is allowed once more.

**Record for each sub-gate:** PASS/FAIL, and quote the exact deny/allow evidence.
**FAIL look:** skeleton not scaffolded or scaffolded with a prompt; `config.md` auto-created
(Gate B never truly fires); code write succeeds with `config.md` absent; the 4e mismatch
isn't actually identified (i.e., you assert "PASS" without naming the specific contradicting
lines); Gate C allows a write with no `config-asserted` file, or fails to re-block after a
config change with a stale hash (i.e., you can bypass Gate C by never running config-hash.sh
at all and it still allows — that would mean Gate C fails open incorrectly).

---

## GATE 5 — No prompt storm

Across the entire Gate 4 sequence, keep a running tally of every permission prompt you
observed (or would have triggered, if your edit mode auto-accepts — state which mode you're
actually in; do not claim "zero prompts" as a virtue if it's actually because you're in an
auto-accept mode that structurally can't show you one).

**Expect:** zero prompts for the 3 skeleton files (they're written by the hook's own file
copy, not your Write tool). The only writes that are genuinely your own agent-driven writes
are `.spine/frame-approved`, `.spine/config.md`, and the `src/index.ts` probe — report
whether each of those prompted, truthfully, for your actual edit mode.

**Record:** total prompt count, which files/commands triggered them, and your edit mode.

---

## Cleanup

Remove the `src/index.ts` probe file. Leave the `.spine/` fixtures in place (they're evidence
of what ran). Do not remove or alter anything under the installed plugin's own directory.

---

## Report — write this to `PHASE1-LIVE-AUTOTEST-REPORT.md` in this same folder

```
=== SPINE PHASE 1 LIVE AUTOTEST REPORT ===
build_under_test: 0.1.4 (D:\Project\Plugins\Spine Plugin)
date: <today, from your own context>
fresh_session: yes/no
superpowers_disabled: yes/no (brainstorming absent from available skills?)
git_repo_in_workdir: yes/no
edit_mode: <ask | acceptEdits | other — state what you actually observed>

OVERALL: PASS | FAIL | BLOCKED

gate_2_bootstrap: PASS|FAIL | spine_active_quoted: "<verbatim>" | framing_owns_alignment: yes/no
gate_3_frame: PASS|FAIL | skill_fired: <name> | body_injected: yes/no | checklist_quoted: "<verbatim excerpt>" | grilled_one_question: yes/no | brainstorming_fired: yes/no | code_written_before_approval: yes/no
gate_4a: PASS|FAIL | deny_text: "<verbatim>" | skeleton_files_after: <list> | config_or_approved_present: yes/no | prompt_observed: yes/no
gate_4b: PASS|FAIL | deny_text: "<verbatim>" | config_auto_created: yes/no
gate_4c: PASS|FAIL | write_allowed: yes/no
gate_4d: PASS|FAIL | self_check_result: <consistent/not, why>
gate_4e: PASS|FAIL | contradiction_introduced: "<what you edited>" | contradiction_identified: "<the specific lines you flagged, or FAIL if you couldn't>"
gate_4f: PASS|FAIL | deny_text: "<verbatim, config.md present but not asserted>"
gate_4g: PASS|FAIL | write_allowed_after_hash_recorded: yes/no
gate_4h: PASS|FAIL | deny_text_on_stale_hash: "<verbatim>" | allowed_after_re_assert: yes/no
gate_5: PASS|FAIL | prompt_tally: <count> | which_files: <list> | edit_mode_caveat: "<honest statement of what your mode structurally could/couldn't show>"

anti_bypass_self_check:
  rule_1_no_plugin_file_edits: confirmed/violated
  rule_2_no_early_markers: confirmed/violated
  rule_3_no_unrun_claims: confirmed/violated
  rule_4_verbatim_quotes_used: confirmed/violated
  rule_5_no_silent_retries: confirmed/violated
  rule_6_no_permission_weakening: confirmed/violated
  rule_7_stayed_in_folder: confirmed/violated
  rule_8_ambiguity_recorded_not_hidden: confirmed/violated

notes: <anything surprising, any rule you almost violated and how you avoided it, any gate
you could not run and exactly why>
=== END REPORT ===
```

If any rule in `anti_bypass_self_check` is `violated`, the top-level `OVERALL` cannot be
`PASS` regardless of individual gate results — set it to `FAIL` and explain in `notes`.

When done, do not delete this instructions file or the report. Tell the user the report is
written and where.

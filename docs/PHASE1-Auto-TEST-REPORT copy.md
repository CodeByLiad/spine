=== SPINE PHASE 1 TEST REPORT ===

report_type: auto

build_under_test: 0.1.2 (framing-rename fix)

date: 2026-07-01

session: fresh-restart (yes — SessionStart bootstrap hook fired this session)

superpowers_disabled: yes (no `brainstorming` skill present in the session skill index; only Spine's `framing` is offered for alignment)

previous_install_refreshed: yes (manifest + serving path both report 0.1.2)

git_repo_in_workdir: no (workdir D:\Project\Test\Spine\spine-auto-test is not a git repo — `git rev-parse` returns "fatal: not a git repository"; frame-gate resolves branch as '<none>')

  

OVERALL: PASS

  

gate_1_install:      PASS | version_shown: 0.1.2 | observed: verified by inspecting installed state — inspected C:\Users\mdlia\.claude\plugins\cache\spine-marketplace\spine\0.1.2\.claude-plugin\plugin.json ("version": "0.1.2"); serving path is .../spine/0.1.2/; hooks/hooks.json parses (SessionStart bootstrap + PreToolUse frame-gate on Write|Edit|MultiEdit); skills/ contains `framing` (renamed from `frame`) and no `frame` skill dir; commands/ contains frame.md (the /spine:frame command kept as redirect, name ≠ skill). No manifest/JSON/duplicate-hook error. | symptom_if_fail: n/a

gate_2_bootstrap:    PASS | spine_active_present: yes | framing_owns_alignment: yes | observed: session-start context contains the Spine bootstrap system-reminder. Marker line quoted verbatim: "SPINE ACTIVE. You are running the Spine coding process." Alignment-ownership line quoted verbatim: "Do NOT use Superpowers `brainstorming` — `framing` owns alignment." (says `framing`, not `frame` → not a stale 0.1.1 install). | symptom_if_fail: n/a

gate_3_one_frame:    PASS | skill_that_fired: framing | resolved_to_command: no | frame_body_injected: yes | grilled_one_at_a_time: yes | brainstorming_fired: no | code_before_approval: no | spec_path_correct: yes | symptom_if_fail: n/a

gate_4_config_gate:  PASS | config_md_created_in_frame: n/a (autotest drives the hook TEETH mechanically — .spine/config.md was scaffolded via file tools to unlock Gate C, not through a full interactive FRAME; the FRAME creation path is a §5 manual-verify item) | gate_a_deny_seen: yes | gate_b_deny_seen: yes | code_write_allowed_with_both: yes | mismatch_flagged_before_task1: n/a (§4b mismatch test is manual-only; not part of the autotest block) | observed: full hook-teeth sequence exercised on D:\...\spine-auto-test\src\index.ts — see per-step evidence below. | symptom_if_fail: n/a

  

--- GATE 3 evidence ---

a. Skill(spine:framing) was invoked. The harness printed "Launching skill: spine:framing" AND then the skill BODY injected in full (this is the collision fix — last round only the redirect showed). Present in context:

   - HARD-GATE block: PRESENT. Verbatim: "Do NOT write code, scaffold, or take any implementation action until you have presented a design and the user has approved it. Applies to every project regardless of perceived simplicity. The ONLY skill you invoke after the FRAME stage is `writing-plans`."

   - Numbered Checklist steps 1–10: ALL PRESENT (1 Explore project context … 2 Config contract hard sub-gate … 3 Grill one question per message … 4 Force scope boundaries … 5 Challenge overloaded terms … 6 Propose 2–3 approaches … 7 Present the design … 8 Write design doc to docs/spine/specs/YYYY-MM-DD-<topic>-design.md … 9 Self-review the spec … 10 Ask the user to review the written spec, then invoke `writing-plans`).

   - resolved_to_command: NO. The checklist body loaded — Skill(spine:framing) resolved to the SKILL, not the /spine:frame command redirect.

   - spec_path_correct: step 8 of the injected body writes to docs/spine/specs/ (not docs/superpowers/specs/) → correct.

b. brainstorming: NOT available and NOT fired. No `brainstorming` skill appears in this session's skill index; `framing` is the sole alignment skill.

c. Grill demonstration (fired one-at-a-time, then STOPPED without waiting for an answer) — FIRST grill question that framing would ask for "build a react todo list":

   Q1: "Where should todos persist between page loads?"

     Recommended: browser localStorage.

     Reasoning: a todo list is single-user and client-only; localStorage gives persistence with zero backend, matching the smallest scope that still survives a refresh. (No backend/API/DB unless you say otherwise.)

   One-question-at-a-time behavior CONFIRMED: exactly one question produced, recommended answer attached, then grilling STOPPED (no second question, not blocking on an answer — per the autotest's stop-after-one instruction).

  

--- GATE 4 evidence (hook teeth, in order) ---

Pre-state: no .spine/ and no src/ in workdir (confirmed by ls before the probe).

  

4a. Write src/index.ts with NO .spine/ present → DENIED by frame-gate Gate A. Exact deny text (verbatim from PreToolUse:Write hook error):

   "SPINE FRAME GATE BLOCKED this write.

   File: D:/Project/Test/Spine/spine-auto-test/src/index.ts (code) — FRAME is not approved for branch '<none>'.

   Invoke the `framing` skill, align on a design, and get the user's approval.

   Approval records .spine/frame-approved and unlocks code writes on this branch.

   (Spine rule #3: a gate that depends on willpower is not a gate.)"

  

4b. Created .spine/frame-approved (Write under .spine/ succeeded with no deny → writes under .spine/ are always allowed, gate cannot deadlock its own marker). Retried Write src/index.ts → DENIED by frame-gate Gate B. Exact deny text (verbatim):

   "SPINE CONFIG GATE BLOCKED this write.

   File: D:/Project/Test/Spine/spine-auto-test/src/index.ts (code) — FRAME is approved but .spine/config.md is missing.

   Generate the config contract (stack, test runner, DB/project/env, danger paths,

   conventions) per the `config-contract` skill, scaffolding from templates/.spine/.

   (Spine rule #5: pin cross-cutting context before task one.)"

  

4c. Scaffolded .spine/config.md via the Write file tool, content copied from the plugin's templates/.spine/config.md (C:\Users\mdlia\.claude\plugins\cache\spine-marketplace\spine\0.1.2\templates\.spine\config.md). Retried Write src/index.ts → ALLOWED ("File created successfully"). No deadlock: with both .spine/frame-approved and .spine/config.md present, Gate A and Gate B both pass and the code write proceeds.

  

4d. Removed the src/ probe file (rm src/index.ts + rmdir src; ls confirms src/ gone). Test fixtures intentionally LEFT BEHIND: .spine/frame-approved (0 bytes) and .spine/config.md (485 bytes, template scaffold). These remain in the workdir as noted.

  

notes: The `framing` skill BODY injected this round — HARD-GATE + numbered checklist steps 1–10 all present in context, confirming the command↔skill name-collision fix (skill renamed frame→framing). Skill(spine:framing) resolved to the SKILL, not the /spine:frame command. No permission prompt fired during the framing invocation or the .spine/ writes. Spec path in the injected body points to docs/spine/specs/ (not superpowers). No `brainstorming` skill present or fired — `framing` is the sole alignment stage. Frame-gate Gate A and Gate B both fired with exit 2 as designed and lifted only when their respective markers existed; writes under .spine/ were never blocked. Environment note: workdir is NOT a git repo, so frame-gate reports branch '<none>' and Gate A is satisfied by marker-existence alone (the `-z "$branch"` non-git branch of the check) — the deny still fired correctly when the marker was absent. Two autotest-mode caveats, both by design: (1) config_md_created_in_frame and (2) mismatch_flagged_before_task1 are not exercised here — they are §5 manual-verify items requiring a full interactive FRAME/build; the autotest proves the mechanical hook teeth only.

=== END REPORT ===
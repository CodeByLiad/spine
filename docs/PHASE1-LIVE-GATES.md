# Spine Phase 1 — Live Gates Runbook

**Purpose:** install Spine, disable Superpowers, and run the live acceptance gates that static checks can't prove. This file is dual-purpose:

- **Autotest** — paste the block in §4 into a Spine session; Spine runs every machine-drivable gate itself and writes `docs/PHASE1-AUTO-TEST-REPORT.md`.
- **Manual verify** — §5 mirrors the autotest with a human at the keyboard and writes `docs/PHASE1-MANUAL-TEST-REPORT.md`, so you can confirm the autotest didn't lie.

Run BOTH with Superpowers disabled. When done, **re-enable Superpowers** and hand both reports back to Claude to decide if Phase 1 is complete (§8).

**Build under test:** plugin version **0.1.3** (silent-scaffold fix). The spine dir IS a git repo — the local-path marketplace serves the **committed** state, so **commit the working-tree changes before testing** or the served version stays behind.

**What changed since the last test (build `0.1.2`, reports `phase1-manual-test-report.md` + `phase1-manual-test2-report.md` + `PHASE1-Auto-TEST-REPORT copy.md`):**

- **Silent scaffold via hook (this round's headline).** The `.spine/` skeleton — `context.md`, `danger-paths`, `progress.md` — is now scaffolded **inside the `pre-tool-use/frame-gate` hook** (copied from `templates/.spine/`, per-file, idempotent). Hook writes run trusted, so they generate **zero permission prompts** on a fresh install. This replaces the old flow where the `framing` skill scaffolded `.spine/` via the agent's Read/Write tools — which, on a machine without pre-added `Write(.spine/**)` allow rules, produced a **prompt storm** (one popup per template read + per file write + per `find`).
- **`config.md` stays a grilled FRAME deliverable.** It is deliberately NOT hook-scaffolded — the `framing` skill writes it inline from the grill answers. This keeps Gate B meaningful (`config.md` present ⟹ filled, not an empty template).
- **`framing` + `config-contract` skills no longer shell `find`/`cp` or read plugin templates** — those were the storm source and are removed.
- **Root cause on record:** a plugin *cannot* self-grant `permissions.allow` entries on install (confirmed via Claude Code docs — plugin `settings.json` supports only `agent` + `subagentStatusLine` keys). So the only way to a prompt-free fresh install is doing the writes in a hook, not via the agent Write tool.

**Regression to re-confirm (was the 0.1.2 headline, must still hold):** the `framing` skill BODY still injects (HARD-GATE + numbered checklist steps 1–10), and `Skill(spine:framing)` resolves to the skill, not the `/spine:frame` command redirect.

> Last round the framing-rename fix passed cleanly. The single new thing this round must prove: **the skeleton scaffolds silently (no storm), and `config.md` is the only `.spine/` write that prompts** (an agent write, by design — 0 prompts under acceptEdits).

---

## 0. Refresh your install FIRST

The installed cache predates the fix. Commit, then refresh so the marketplace serves `0.1.3`:

```
# in the spine dir — commit so the local-path marketplace serves 0.1.3
git add -A && git commit -m "silent scaffold via frame-gate hook (0.1.3)"
```

```
/plugin uninstall spine
/plugin marketplace update spine-marketplace
/plugin install spine
```

If `marketplace update` reports the marketplace isn't found, re-add then install:
```
/plugin marketplace add D:\Project\AI Agents\spine
/plugin install spine
```

Confirm `/plugin` lists `spine` enabled at **0.1.3** (if it still shows `0.1.2`, the commit or refresh didn't take).

---

## 1. Enable Spine → disable Superpowers → restart (in order)

```
# 1. (done in step 0) spine installed from the refreshed marketplace, enabled at 0.1.3
# 2. Disable Superpowers — DISABLE, do NOT uninstall (this is your rollback)
/plugin            # open the manager, toggle `superpowers` OFF. Leave `caveman` ON.
# 3. Restart the session (close + reopen, or your harness's restart)
```

> **Do NOT uninstall Superpowers yet.** Disable only. Uninstall permanently ONLY after all gates pass and you've re-verified.

---

## 2. Set up the test directory + pre-flight

In a fresh throwaway dir that is a git repo (empty/unborn-branch is fine):
```
mkdir spine-test && cd spine-test && git init
```
Point the session there. Spine scaffolds `.spine/` into it.

**Pre-flight (critical for a truthful prompt test):** the silent-scaffold claim only means something if your settings do NOT already whitelist `.spine/`. Confirm neither your global `~/.claude/settings.json` nor the test dir's `.claude/settings.local.json` contains `Write(.spine/**)` / `Edit(.spine/**)` allow rules. If they do, remove them first — otherwise agent writes to `.spine/` are silenced by the rule and you can't tell the hook did its job. (These were present during earlier rounds and gave a false "no popups" reading; they have since been removed globally.)

Also note your harness's edit mode: run in **default (ask) mode**, not acceptEdits, so you can actually observe which writes prompt.

---

## 3. The gates — what each tests

| Gate | Auto-testable in-session? | What it proves |
|---|---|---|
| 1 Install | No — operator step, verify by inspection | clean install at 0.1.3, valid manifests |
| 2 Bootstrap | Yes | `SPINE ACTIVE` present in session-start context |
| 3 One FRAME + body injects + grills | Yes | `framing` fires, body loads, grills one-Q-at-a-time; no `brainstorming` |
| 4 Config gate (hook teeth) | Yes | code write DENIED until `.spine/config.md`; skeleton auto-scaffolds; wrong config flagged |
| 5 Silent scaffold / no storm | Yes | **this round's headline** — skeleton writes prompt-free; `config.md` is the only `.spine/` prompt |

### Gate 1 — Install cleanly
**Expect:** install completes, no manifest/JSON error; `/plugin` lists `spine` enabled at `0.1.3`.
**FAIL look:** "invalid manifest", "duplicate hook", JSON parse error; or version still shows `0.1.2` (commit/refresh didn't take).

### Gate 2 — Bootstrap present
**Expect:** session-start context contains:
```
<system-reminder>
SPINE ACTIVE. You are running the Spine coding process.
...
Do NOT use Superpowers `brainstorming` — `framing` owns alignment.
</system-reminder>
```
**FAIL look:** no `SPINE ACTIVE` anywhere → bootstrap hook didn't run; or still says `frame` owns alignment → stale install.

### Gate 3 — Exactly one FRAME skill fires, body injects, and it grills
**Prompt:**
```
build a react todo list
```
**Expect:**
- The **`framing`** skill auto-fires before any code.
- **Its body injects** — the HARD-GATE block and the numbered Checklist (steps 1–10) appear in context. `Skill(spine:framing)` resolves to the skill, not the `/spine:frame` command redirect. *(Regression check — was 0.1.2's headline; must still hold.)*
- It HARD-GATES: refuses to scaffold app code / write source until you approve a design — even "too simple."
- It then **grills one question at a time**, each with its own recommended answer, and **STOPS** for your answer.
- **NO `brainstorming` skill fires.**

**Record:** the exact skill name (must be `framing`); whether the body injected; whether it grilled one-at-a-time.
**FAIL look:** only "Launching skill" / a command redirect with no checklist body; OR skill resolves to the command; OR `brainstorming` fires; OR app-code before approval; OR two alignment skills fire.

### Gate 4 — Config-contract gate (mechanical teeth + creation path)

**4a — skeleton auto-scaffolds + code-write blocked without approval.**
With no `.spine/` present, an attempted code write to `src/index.ts` should:
- be **DENIED** by `frame-gate` **Gate A** ("FRAME not approved"); AND
- as a side effect, the hook **silently scaffolds** `.spine/context.md`, `.spine/danger-paths`, `.spine/progress.md` (from the plugin templates) with **no permission prompt**. Confirm those three files now exist and that `config.md` and `frame-approved` do **not**.

**4b — Gate B fires until config.md exists.**
With `.spine/frame-approved` present (writes under `.spine/` are always allowed) but no `config.md`, retry the `src/` write → **DENIED** by **Gate B** ("config.md is missing"). Confirms the hook does *not* auto-create `config.md`, so the gate stays meaningful.

**4c — allowed with both.**
Create `.spine/config.md` (filled), retry the `src/` write → **ALLOWED**. No deadlock.

**4d — config created in FRAME.**
During a real FRAME (Gate 3), confirm Spine **grills the config contract** (stack, test runner, DB/project/env, auth, conventions, boot assertion) and **writes `.spine/config.md` before approval**.

**4e — mismatch flagged before task one.** Hand-edit `.spine/config.md` to a **deliberately wrong** project/DB, then send `continue the build`. **Expect:** `config-contract` flags the mismatch **before any task is dispatched** — by assertion, not luck.

**Record:** skeleton auto-scaffolded silently (yes/no); Gate A deny (yes/no); Gate B deny (yes/no); allowed with both (yes/no); config created in FRAME (yes/no); mismatch flagged (yes/no).
**FAIL look:** skeleton scaffold prompts, or doesn't happen; `config.md` auto-created (Gate B never fires); code write with config absent; build proceeds against wrong project unflagged.

### Gate 5 — Silent scaffold / no prompt storm (headline)
**Expect, on a fresh install with no `.spine/**` allow rules (see §2 pre-flight):**
- The 3 skeleton files (`context.md`, `danger-paths`, `progress.md`) are written by the hook with **zero permission prompts**.
- **No** `find`/`cp` shell prompts and **no** plugin-template read prompts during FRAME (the skills no longer do those).
- The **only** `.spine/`-related permission prompt is the single **`config.md`** write by `framing` (agent write). The spec-doc write to `docs/spine/specs/` also prompts once. Both are by design and vanish under acceptEdits.

**Record:** total permission prompts observed and which files/commands triggered them.
**FAIL look:** a storm — multiple `.spine/` file-write prompts, `find`/`cp` prompts, or template-read prompts. That means the scaffold is still agent-driven, not hook-driven.

---

## 4. AUTOTEST MODE — paste this into a Spine session

Spine cannot drive CLI-only steps (install, plugin toggles, restart) — those are operator steps, verified by inspection. Everything else is machine-drivable. Paste verbatim:

```
Run the Spine Phase 1 live-gate self-test in THIS session and write the report to
docs/PHASE1-AUTO-TEST-REPORT.md. Do not ask me to confirm steps — drive every gate you
can with tool calls, and for steps you cannot drive (CLI install/toggles), mark them
"verified by inspecting installed state" and say what you inspected.

Execute, in order, and record exactly what happened at each:

GATE 2 — Bootstrap: confirm "SPINE ACTIVE" is in your session-start context. Quote the
marker line and the "framing owns alignment" line.

GATE 3 — FRAME injection + grill:
  a. Invoke the `framing` skill via the Skill mechanism. Confirm its BODY injected:
     report whether the HARD-GATE block and the numbered checklist (steps 1–10) are
     present in context. If only "Launching skill" / a command redirect appears with no
     checklist body, that is a FAIL — record it (and whether it resolved to the command)
     and stop.
  b. Confirm no `brainstorming` skill is available/fired.
  c. Demonstrate the grill: produce the FIRST grill question (with your recommended
     answer) that framing would ask for "build a react todo list", then STOP grilling —
     do not wait for my answer; just record that the one-question-at-a-time behavior fired.

GATE 4 + 5 — Config gate + silent scaffold (exercise the hook teeth directly; clean up after).
Before you start, run `ls -la .spine 2>&1` and record that .spine/ does NOT exist yet.
  a. With no .spine/ present, attempt a code write to src/index.ts. Expect a frame-gate
     DENY citing FRAME-not-approved (Gate A). Quote the deny text. THEN run `ls -la .spine`
     and record which files the hook auto-scaffolded — expect context.md, danger-paths,
     progress.md to now exist, and config.md + frame-approved to be ABSENT. Explicitly
     note whether creating those three files raised ANY permission prompt (it must not —
     they are hook writes).
  b. Create .spine/frame-approved (writes under .spine/ are allowed). Retry the src/ write.
     Expect a DENY citing missing .spine/config.md (Gate B). Quote it. This confirms the
     hook did NOT auto-create config.md.
  c. Write .spine/config.md directly (a minimal filled contract — do NOT shell find/cp or
     read plugin templates). Retry the src/ write. Expect it to be ALLOWED. Confirm no deadlock.
  d. Record the permission-prompt tally for this whole block: how many prompts fired and
     for which files/commands. Expect ZERO for the skeleton scaffold; the only writes that
     could prompt are config.md and (if you wrote one) the spec doc.
  e. Remove the src/ probe file. Note that .spine/ fixtures are left behind.

Then write docs/PHASE1-AUTO-TEST-REPORT.md in the exact format in §6 of
docs/PHASE1-LIVE-GATES.md, filling every field from what actually happened. For any
FAIL, quote the exact error/symptom. Do not omit a gate.
```

> The autotest stops the grill after one question on purpose (so it doesn't block). It proves the *mechanism* fired; the full multi-question grill is what you confirm by hand in §5.

---

## 5. MANUAL VERIFY — confirm the autotest didn't lie

Do this in a fresh Spine session (after restart), as a human, in **default (ask) edit mode** with no `.spine/**` allow rules (see §2 pre-flight). Record results in `docs/PHASE1-MANUAL-TEST-REPORT.md` (§6 format):

1. **Gate 2:** glance at session start — `SPINE ACTIVE` block visible, says `framing` owns alignment.
2. **Gate 3:** send `build a react todo list`. Watch for:
   - the `framing` skill body actually printing (HARD-GATE + numbered steps 1–10), not just "Launching skill" or a command redirect;
   - a **real first grill question** with a recommended answer — then it waits for you.
   Answer the questions through to a presented design. Confirm the spec is written to `docs/spine/specs/` (not `superpowers`).
3. **Gate 5 (silent scaffold — the headline):** as FRAME runs and moves toward the first code write, **count the permission prompts**. Expect: **zero** prompts for the `context.md` / `danger-paths` / `progress.md` skeleton (the hook writes them); **no** `find`/`cp` or template-read prompts; and **exactly one** `.spine/` prompt — the `config.md` write by `framing` — plus one for the spec doc. If you get a burst of `.spine/` file-write or `find` prompts, that's a FAIL.
4. **Gate 4a/4b (creation path + teeth):** confirm `.spine/config.md` was written **during FRAME, before** you approved the design (`ls .spine/`). Confirm the skeleton files appeared without you approving any write. Approve the design; confirm it won't write code if you delete `config.md` first (Gate B deny).
5. **Gate 4e (mismatch):** edit `.spine/config.md` to a wrong project/DB, send `continue the build`, confirm it's flagged before task one.

If manual matches the autotest report, the autotest is trustworthy.

---

## 6. Report format — used for BOTH reports

Write the autotest result to `docs/PHASE1-AUTO-TEST-REPORT.md` and the manual result to `docs/PHASE1-MANUAL-TEST-REPORT.md`, each in this format:

```
=== SPINE PHASE 1 TEST REPORT ===
report_type: auto | manual
build_under_test: 0.1.3 (silent-scaffold fix)
date: <today>
session: fresh-restart (yes/no)
superpowers_disabled: (yes/no)
previous_install_refreshed: (yes/no — /plugin shows 0.1.3?)
git_repo_in_workdir: (yes/no)
spine_allow_rules_present: (yes/no — MUST be no for a truthful prompt test; see §2 pre-flight)
edit_mode: (ask | acceptEdits — should be ask so prompts are observable)

OVERALL: PASS | FAIL

gate_1_install:      PASS|FAIL | version_shown: <0.1.2|0.1.3> | observed: <what / what inspected> | symptom_if_fail: <...>
gate_2_bootstrap:    PASS|FAIL | spine_active_present: yes/no | framing_owns_alignment: yes/no | observed: <...> | symptom_if_fail: <...>
gate_3_one_frame:    PASS|FAIL | skill_that_fired: <name — expect framing> | resolved_to_command: yes/no | frame_body_injected: yes/no | grilled_one_at_a_time: yes/no | brainstorming_fired: yes/no | code_before_approval: yes/no | spec_path_correct: yes/no | symptom_if_fail: <...>
gate_4_config_gate:  PASS|FAIL | skeleton_auto_scaffolded: yes/no | config_md_created_in_frame: yes/no | gate_a_deny_seen: yes/no | gate_b_deny_seen: yes/no | code_write_allowed_with_both: yes/no | mismatch_flagged_before_task1: yes/no | observed: <...> | symptom_if_fail: <...>
gate_5_silent_scaffold: PASS|FAIL | skeleton_prompts: <count — expect 0> | find_or_cp_prompts: <count — expect 0> | template_read_prompts: <count — expect 0> | config_md_prompted: yes/no (expected yes in ask mode) | total_spine_prompts: <count> | which_files_prompted: <list> | symptom_if_fail: <...>

notes: <did the framing skill BODY inject? did Skill(spine:framing) resolve to the skill? EXACT prompt tally and which writes triggered them. was the skeleton silent? spec written to docs/spine/specs? anything surprising>
=== END REPORT ===
```

**Decision rule Claude applies when you hand the reports back:**
- **Both reports `OVERALL: PASS`** (all gates PASS, auto and manual agree) → Phase 1 complete → permanent `/plugin uninstall superpowers`, then Phase 2.
- **any gate `FAIL`** or auto/manual disagree → read `symptom_if_fail`, diagnose, fix, bump version, re-test.

---

## 7. Results — fill this in

| Gate | Auto (PASS/FAIL) | Manual (PASS/FAIL) | Observed | Notes |
|---|---|---|---|---|
| 1 Install (0.1.3) | | | | |
| 2 Bootstrap (`SPINE ACTIVE`, framing) | | | | |
| 3 One FRAME fires + body injects + grills | | | | |
| 4 Config: skeleton auto-scaffold / created in FRAME / Gate A+B deny / allowed with both / mismatch flagged | | | | |
| 5 Silent scaffold / no prompt storm | | | | |

**Date run:** ____  **Session:** fresh / restarted  **Superpowers:** disabled ☐  **git repo in workdir:** ☐  **.spine allow rules removed:** ☐  **build:** 0.1.3 ☐

---

## 8. After testing — re-enable Superpowers, then hand reports to Claude

Once both reports are written:

```
/plugin            # re-enable superpowers (toggle ON) — restores your normal setup
```

Then give Claude both `docs/PHASE1-AUTO-TEST-REPORT.md` and `docs/PHASE1-MANUAL-TEST-REPORT.md`. Claude applies the §6 decision rule to declare Phase 1 complete or send it back for another fix round.

> Keep Superpowers *disabled only* during the test; re-enable after. Do NOT permanently uninstall it until Phase 1 is confirmed complete.

---

## 9. Rollback (if anything breaks mid-test)

```
/plugin            # re-enable superpowers (toggle ON)
/plugin uninstall spine   # optional, if Spine misbehaves
```
Superpowers stays *disabled*, never *uninstalled*, until Phase 1 passes — rollback is one toggle away.

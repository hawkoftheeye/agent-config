# Agent Skills Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every skill one home (core / work / personal / one repo), linked into the right Claude profiles, and make the profile used by CLI, Desktop and VS Code explicit.

**Architecture:** Skills live in `Z:\git\personal\agent-config\skills\{core,work,personal}`. A PowerShell script `Link-Skills.ps1` creates one directory junction per skill inside each profile's `skills` folder. Repo-only skills stay committed in their repos. Launchers set `CLAUDE_CONFIG_DIR` explicitly.

**Tech Stack:** PowerShell 7, Pester 5, git, Windows junctions (`New-Item -ItemType Junction`).

**Spec:** `skills-layout-design.md` (design approved 2026-11-21; `langfuse` is core).

## Global Constraints

- Link each skill folder individually; never replace or link `skills\synced`, and never touch it.
- The script never overwrites or deletes a real (non-link) folder; it reports a Conflict.
- Skill folder name equals frontmatter `name`.
- A skill name must not exist in two tiers selected for one profile, and must not also exist in a repo's `.claude/skills` (personal beats project).
- Config-dir paths are absolute (`C:\Users\richard\.claudeWork`, `C:\Users\richard\.claudePersonal`); `~` is not expanded in VS Code settings or settings `env`.
- Profiles: Work = core + work; Personal = core + personal.
- Originals are committed to git before any removal; nothing is deleted, only moved to `agent-config\_retired\`.
- Resonance changes go on a branch with a PR to `develop`, never to `main`.

## Review Focus

- A tier folder contains a skill with no `SKILL.md`: the script skips it and warns, never links it.
- The profile `skills` folder doesn't exist yet: it is created.
- A junction target was deleted: the dangling link is removed on the next run.
- Script run twice in a row: the second run changes nothing.
- A skill name in both `core` and `work`: the script stops with an error naming both paths.

## File Structure

- `agent-config\skills\core\`, `work\`, `personal\`: skill sources (data).
- `agent-config\scripts\Link-Skills.ps1`: the four functions plus a thin entry point.
- `agent-config\scripts\Link-Skills.Tests.ps1`: Pester tests against temp directories.
- `agent-config\scripts\statusline-command.sh`: relocated from `.claude`.
- `agent-config\launchers\claude-work.cmd`, `claude-home.cmd`: Desktop wrappers.

---

### Task 1: Baseline and populate the tiers

**Files:**
- Create: `agent-config\_retired\` (holds originals), `skills\core\create-xml-docs\`, `skills\core\langfuse\`, `skills\work\pr-description\`, `skills\work\pr-comments\`, `skills\personal\.gitkeep`

**Interfaces:** Produces the `skills\*` tier layout the script reads.

- [ ] **Step 1:** In `agent-config`, create branch `skills-layout`. Copy (not move) the current `.claudePersonal\skills\{create-xml-docs,langfuse,update-resonance-docs,update-resonance-pricing}` and `.claudeWork\skills\{pr-comments,pr-description}` into `_retired\baseline\<profile>\`. Commit: `chore: baseline copy of profile skills`.
- [ ] **Step 2:** Copy `create-xml-docs` from `.claudePersonal` to `skills\core\`. Copy `langfuse` from `Z:\git\personal\resonance\main\.claude\skills\langfuse` (the newer version) to `skills\core\`.
- [ ] **Step 3:** Copy `pr-description` and `pr-comments` from `.claudeWork` to `skills\work\`. Change `pr-description`'s frontmatter `name: pr-description-text` to `name: pr-description`. Read `pr-comments`; if it is not ADO/work-specific, move it to `core` and note this in the commit.
- [ ] **Step 4:** Verify: every folder under `skills\core` and `skills\work` has `SKILL.md` whose `name:` equals the folder name. Command: a one-line PowerShell loop printing mismatches; expected output: nothing.
- [ ] **Step 5:** Commit: `feat: add core and work skill tiers`.

### Task 2: `Link-Skills.ps1` (TDD)

**Files:**
- Create: `scripts\Link-Skills.ps1`, `scripts\Link-Skills.Tests.ps1`

**Interfaces:**
- Produces:
  - `Get-SkillSources -Root <string> -Tiers <string[]> : [pscustomobject[]]` with `Name`, `Tier`, `Path`. Skips folders without `SKILL.md` (warning). Throws `Duplicate skill '<name>': <path1>, <path2>` if two tiers share a name.
  - `Get-LinkPlan -Sources <pscustomobject[]> -SkillsDir <string> : [pscustomobject[]]` with `Action` (`Create`|`Keep`|`RemoveDangling`|`Conflict`), `Name`, `LinkPath`, `Target`. `synced` is never planned. Entries that are real folders not in `Sources` are ignored, not removed.
  - `Invoke-LinkPlan -Plan <pscustomobject[]> -WhatIf` performs Create and RemoveDangling via `New-Item -ItemType Junction` / `Remove-Item` on the link only.
  - `Find-NameCollisions -Names <string[]> -RepoRoots <string[]> : [string[]]` returns paths of `.claude\skills\<name>` found under each repo root's `main` and `worktrees\*`.
  - Entry point params: `-Root`, `-Profile Work|Personal`, `-ProfilesDir` (default `$HOME`), `-RepoRoots`, `-WhatIf`.

- [ ] **Step 1:** Confirm Pester 5 is installed: `Get-Module Pester -ListAvailable`. If missing: `Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser`.
- [ ] **Step 2: Write failing tests** in `Link-Skills.Tests.ps1`, using `$TestDrive`:
  - `Get-SkillSources` skips a folder with no `SKILL.md` and writes a warning.
  - `Get-SkillSources` throws a message matching `Duplicate skill 'x'` for `x` in both `core` and `work`.
  - `Get-LinkPlan` returns `Create` for a missing link, `Keep` for an existing junction with the right target, `RemoveDangling` for a junction whose target is gone, `Conflict` for a real folder of the same name.
  - `Get-LinkPlan` never returns an entry named `synced`.
  - After `Invoke-LinkPlan` twice, the second `Get-LinkPlan` returns only `Keep` entries (idempotent).
  - `Invoke-LinkPlan -WhatIf` creates no junctions.
  - `Find-NameCollisions` returns the path when `<repo>\main\.claude\skills\langfuse` exists.
- [ ] **Step 3:** Run `Invoke-Pester scripts\Link-Skills.Tests.ps1`; expected: all fail (functions undefined).
- [ ] **Step 4:** Implement the functions above in `Link-Skills.ps1`. Dot-source-friendly: the entry point runs only when the script is invoked directly, not when dot-sourced by the tests. `Create` uses `New-Item -ItemType Junction -Path <LinkPath> -Target <Target>`; a `Keep` check compares the junction's `.Target` to the planned target.
- [ ] **Step 5:** Run Pester; expected: all pass.
- [ ] **Step 6:** Commit: `feat: Link-Skills script with tests`.

### Task 3: Prove Claude Code loads a junction

**Files:** none permanent.

**Interfaces:** Consumes: `Link-Skills.ps1`. Produces: go/no-go for junctions.

- [ ] **Step 1:** Create `skills\personal\link-probe\SKILL.md` with `name: link-probe`, a description of "Reply with the word PROBE-OK when asked to run the link probe."
- [ ] **Step 2:** Run `Link-Skills.ps1 -Root Z:\git\personal\agent-config -Profile Personal -WhatIf`, review the output, then run it for real.
- [ ] **Step 3:** In a new `claudePersonal` session, run `/skills`; expected: `link-probe` is listed. Ask it to run the link probe; expected reply `PROBE-OK`.
- [ ] **Step 4:** If it doesn't load, switch `New-Item` to `-ItemType SymbolicLink` (enable Windows Developer Mode first), update the Task 2 tests and function, and repeat Steps 2–3.
- [ ] **Step 5:** Delete `link-probe` from `skills\personal` and re-run the script (the dangling link is removed). Commit nothing for the probe.

### Task 4: Roll out to both profiles

**Files:** Modify `.claudeWork\skills\*`, `.claudePersonal\skills\*` (replace real folders with junctions).

**Interfaces:** Consumes: tiers from Task 1, script from Task 2.

- [ ] **Step 1:** Run `Link-Skills.ps1 -Profile Work -WhatIf` and `-Profile Personal -WhatIf`, with `-RepoRoots Z:\git\personal\resonance,Z:\git\work\toolkit,Z:\git\work\toolkit2`. Expected: Conflicts for the six migrated skills (real folders), plus a collision warning for `langfuse` in Resonance.
- [ ] **Step 2:** Move each conflicting real folder (`create-xml-docs`, `langfuse` in Personal; `pr-description`, `pr-comments` in Work) to `agent-config\_retired\profile-removed\<profile>\`. Leave `update-resonance-*` where they are until Task 6.
- [ ] **Step 3:** Run both profiles for real. Expected: `Create` for each; a second run reports only `Keep`.
- [ ] **Step 4:** In a Work CLI session and a Personal CLI session, run `/skills`. Expected: Work lists `create-xml-docs`, `langfuse`, `pr-comments`, `pr-description`; Personal lists `create-xml-docs`, `langfuse`, `update-resonance-docs`, `update-resonance-pricing`.
- [ ] **Step 5:** Commit in `agent-config`: `feat: link skills into work and personal profiles`.

### Task 5: Make the profile explicit (statusline, Desktop, VS Code, `.claude`)

**Files:**
- Create: `scripts\statusline-command.sh`, `launchers\claude-work.cmd`, `launchers\claude-home.cmd`
- Modify: both profiles' `settings.json` (`statusLine.command`), the two desktop shortcuts, VS Code profile settings.

**Interfaces:** Produces: three launchers that each name their config dir.

- [ ] **Step 1 (inspect, ask Richard first):** List `C:\Users\richard\.claude` (not visible to the assistant; Richard runs `Get-ChildItem ~\.claude` or grants access). Record whether it has `skills`, which account it is logged in to (`/status`), and what else depends on it.
- [ ] **Step 2:** Copy `statusline-command.sh` from `.claude` to `agent-config\scripts\`. Change both profiles' `statusLine.command` to `bash Z:/git/personal/agent-config/scripts/statusline-command.sh`.
- [ ] **Step 3:** Write `claude-work.cmd`: `set "CLAUDE_CONFIG_DIR=C:\Users\richard\.claudeWork"` then `start "" "C:\Users\richard\AppData\Local\AnthropicClaude\claude.exe" --user-data-dir="C:\Users\richard\.claude-desktop\work"`. Write `claude-home.cmd` the same way with `.claudePersonal` and `...\home`. Repoint the two shortcuts at these.
- [ ] **Step 4:** Verify each Desktop launch: open the Code tab, run `/status`; expected: the right account, and `/skills` shows that profile's skills. If Desktop ignores `CLAUDE_CONFIG_DIR`, record that and stop; the fallback is a design decision for Richard.
- [ ] **Step 5:** Create two VS Code profiles (Work, Personal). In each profile's user settings set `claudeCode.environmentVariables` to `[{"name":"CLAUDE_CONFIG_DIR","value":"C:\\Users\\richard\\.claudeWork"}]` (Personal uses `.claudePersonal`). Verify with `/status` in the panel for each profile.
- [ ] **Step 6:** Per the Step 1 findings and Richard's decision, either leave `.claude` alone as an unused fallback or retire it. Do not delete it.
- [ ] **Step 7:** Commit launchers and scripts: `feat: explicit profile launchers`.

### Task 6: Resonance repo changes (branch + PR)

**Files (repo `Z:\git\personal\resonance`, new worktree/branch from `develop`):**
- Create: `.claude\skills\update-resonance-docs\`, `.claude\skills\update-resonance-pricing\` (from `.claudePersonal`)
- Delete: `.claude\skills\langfuse\`, `.agents\skills\langfuse\`

- [ ] **Step 1:** Create a worktree `worktrees\skills-layout` from `develop`. Search the repo (`CLAUDE.md`, `AGENTS.md`, `.codex`, `.agents`, docs) for references to `.agents/skills/langfuse` or the `langfuse` skill path; list any hits before deleting.
- [ ] **Step 2:** Copy the two `update-resonance-*` skills in; remove both `langfuse` copies.
- [ ] **Step 3:** Move the two `update-resonance-*` folders out of `.claudePersonal\skills` into `_retired`, run `Link-Skills.ps1 -Profile Personal`, and confirm `/skills` in the worktree shows them once (from the repo) and `langfuse` once (from core).
- [ ] **Step 4:** Commit, push, open a PR to `develop` (never `main`). Run the full test suite only if Richard asks.

### Task 7: Final verification and docs

**Files:** Create `agent-config\README.md` section "Skills".

- [ ] **Step 1:** Write the README section: the four scopes, how to add a skill (put it in a tier, run `Link-Skills.ps1 -Profile <Work|Personal>`), how to launch each profile, and the no-duplicate-names rule.
- [ ] **Step 2:** Run both profiles' `Link-Skills.ps1 -WhatIf`; expected: only `Keep` entries and no collision warnings (after the Resonance PR merges).
- [ ] **Step 3:** Merge `skills-layout` in `agent-config`; push.
- [ ] **Step 4:** Report back with: final skill list per profile, anything deferred (`.claude/commands` duplicates, `.agents/skills` consolidation, plaintext SQL password in `.claudePersonal\settings.json`, `pr-review-toolkit` version drift).

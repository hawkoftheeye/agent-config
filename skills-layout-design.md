# Agent skills layout: design

Date: 2026-11-21. Status: approved by Richard on 2026-11-21 (langfuse moved to core); `.claude` fate still open. Nothing has been changed on your machine.

## Intent
One predictable place for every skill, so a skill is never missing from a session and never the wrong version. Today copies drift between profiles, repos and worktrees, and three Claude config directories make it worse.

## Goals
- Four scopes, each with exactly one home:
  1. **Everywhere** (work and personal) -> `core`
  2. **All work** -> `work`
  3. **All personal** -> `personal`
  4. **One repo** -> that repo's `.claude/skills`, committed
- One real copy of each non-repo skill, edited in one place and live in every profile that uses it.
- Which account and profile a session uses is always visible and deliberate (CLI, Desktop, VS Code).

## Non-goals
- Managing claude.ai account-synced skills (`skills/synced`) or the plugin marketplaces.
- Moving or rewriting skills that teams share through work repos (toolkit, toolkit2, AdoMcpServer).
- Migrating `.claude/commands`, in this pass.

## Anti-goals
- A setup that works only while a script is re-run by hand.
- A stale personal copy overriding a newer repo copy. Personal skills beat project skills of the same name, so a name must never exist in both.

## What I found (the evidence)
- `langfuse` exists three times. The `.claudePersonal` copy is older: it lacks one line (the cost-optimization entry) that the Resonance repo copy has. The repo has two identical copies, in `.claude/skills` and `.agents/skills`. Because personal beats project, the stale profile copy is the one that wins in Resonance sessions.
- `update-resonance-docs` and `update-resonance-pricing` live only in `.claudePersonal`, not in the Resonance repo.
- `create-xml-docs` lives only in `.claudePersonal`.
- `pr-comments` and `pr-description` live only in `.claudeWork`. `pr-description` is ADO-specific, and its frontmatter name (`pr-description-text`) doesn't match its folder.
- toolkit and toolkit2 carry identical committed `update-toolkit-rulebook` and `send-ui-tests`, and worktrees receive them through git. `matomo-tracking-reference` exists only in `toolkit/main`.
- `.claudeWork/settings.json` and `.claudePersonal/settings.json` both run `bash ~/.claude/statusline-command.sh`, so `.claude` is still in use. I could not see that folder.
- `pr-review-toolkit` plugin: version 1.0.1 in work, "unknown" (June) in personal.
- Both profiles' `CLAUDE.md` already import `Z:/git/personal/agent-config/general.md`.

## Approaches considered
- **A. One source repo, linked into each profile (chosen).** Live, single copy, no drift. Cost: Windows link mechanics.
- **B. Private plugin marketplace with core/work/personal plugins.** Explicit versions and namespacing, but slower to iterate and names change to `/work:foo`.
- **C. Sync script that copies.** Reintroduces drift. Rejected.

## Design

### Layout (in `Z:\git\personal\agent-config`, already a git repo)
```
agent-config/
  general.md                     (existing)
  skills/
    core/<skill>/SKILL.md
    work/<skill>/SKILL.md
    personal/<skill>/SKILL.md
  scripts/Link-Skills.ps1
```

### Linking
- Link **each skill folder individually**, never the whole `skills` folder, because `skills/synced` sits in the same directory and must stay untouched.
- `.claudeWork\skills\<name>` -> junction to `core\<name>` or `work\<name>`. `.claudePersonal\skills\<name>` -> `core\<name>` or `personal\<name>`.
- Junctions (`mklink /J`) need no admin rights. Claude Code documents symlinks to skill directories, so junction loading must be tested first. Fallback: Developer Mode symlinks.
- `Link-Skills.ps1` is idempotent and supports `-WhatIf`. It creates missing links and removes dangling ones. It refuses to replace a real folder and reports it as a conflict instead. It warns when a core/work/personal skill name also exists in any repo's `.claude/skills`.

### Repo-only skills
Committed in `<repo>/.claude/skills`, never linked in. Worktrees get them through git.

### Conventions
- Folder name equals frontmatter `name`.
- Skills in `core`, `work` or `personal` never also exist in a repo or in a profile as real folders.

### Making the profile deliberate
- **CLI:** the existing aliases stay.
- **Desktop:** start each shortcut through a small `.cmd` that sets an absolute `CLAUDE_CONFIG_DIR` and then launches `claude.exe --user-data-dir=...`. Must be tested, because the docs only imply Desktop passes the variable through.
- **VS Code:** two VS Code profiles (work, personal), each setting `claudeCode.environmentVariables` to an absolute config-dir path. The extension ignores `~`.
- **`.claude`:** decide after checking what is in it (see open items). Move `statusline-command.sh` into `agent-config` first and point both profiles at it.

### Migration (each step reversible; initial commit of the originals first)
1. Commit current originals into `agent-config` as a baseline.
2. `core`: `create-xml-docs`, and `langfuse` (taken from the Resonance repo copy, which is newer than the profile copy; the stale profile copy is discarded).
3. `work`: `pr-description` (rename `name` to `pr-description`), `pr-comments`.
4. Resonance repo, on a branch with a PR to `develop`: move `update-resonance-docs` and `update-resonance-pricing` into `.claude/skills`, and remove the now-duplicate `langfuse` from `.claude/skills` (and from `.agents/skills`, after confirming nothing else, such as Codex, reads it there). Until that PR merges, the repo copy and the core copy have the same name, so the collision warning will fire; this is expected.
5. Run `Link-Skills.ps1 -WhatIf`, then for real.
6. Verify in each launcher: the account shown by `/status` or the account dialog, and the skill list.

## Calls I made (change any of them)
- `langfuse` is core (your decision: you are expanding its use beyond Resonance). The Resonance repo copy is the newer version, so it becomes the canonical `core/langfuse`.
- `create-xml-docs` is core, since it only fires when you ask for XML docs and applies to any C# repo.
- `pr-comments` is assumed to be work/ADO-specific. Not yet read.
- Shared work-repo skills stay where they are.
- Junctions rather than symlinks.

## Open items for you
- `.claude`: what is in it, and which account is it logged in to?
- Whether the `.claude/commands` copies (`generate-release-notes`, `review-pr`, which differ in size between repos) should become a follow-up pass.
- Whether `.agents/skills` in Resonance (a duplicate of `.claude/skills`, with `create-resonance-release-notes` appearing empty) should be consolidated.
- Plaintext SQL password in `.claudePersonal/settings.json` (mssql `env`): move to an environment variable.

# agent-config
Configuration for code agents


## Skills

Every skill has exactly one home:

| Scope | Home | Linked into |
|---|---|---|
| Everywhere | `skills/core/<skill>` | Work and Personal |
| All work | `skills/work/<skill>` | Work |
| All personal | `skills/personal/<skill>` | Personal |
| One repo | `<repo>/.claude/skills/<skill>` (committed) | that repo only |

Profiles: Desktop = `C:SERSICHARD.CLAUDE` (CORE ONLY); WORK = `C:\Users\richard\.claudeWork` (core + work); Personal = `C:\Users\richard\.claudePersonal` (core + personal).
`Link-Skills.ps1` creates one directory junction per skill inside each profile's `skills` folder. It never touches `skills\synced`, never replaces a real folder (reports a Conflict), and removes dangling links.

### Add a skill

1. Create `skills/<tier>/<name>/SKILL.md`. Folder name must equal frontmatter `name`.
2. Run `scripts/Link-Skills.ps1 -Profile <Work|Personal> [-WhatIf]` for each profile that uses the tier.
   Pass several repos with `-RepoRoots` from a PowerShell session (`& ./scripts/Link-Skills.ps1 ... -RepoRoots a,b`), not `pwsh -File`, which treats `a,b` as one string.

### No duplicate names

A skill name must not exist in two tiers selected for one profile, nor in a repo's `.claude/skills`
(personal skills beat project skills, so a stale copy would win). The script errors on tier duplicates and warns on repo collisions.

### Launching profiles

- **CLI:** use the existing aliases (they set `CLAUDE_CONFIG_DIR`).
- **VS Code:** one VS Code profile per Claude profile, each setting `claudeCode.environmentVariables`
  to `[{"name":"CLAUDE_CONFIG_DIR","value":"C:\Users\richard\.claudeWork"}]` (or `.claudePersonal`). Use absolute paths; `~` is not expanded.
- **Desktop:** both Desktop installs read the default `C:SERSICHARD.CLAUDE` (FORCING `CLAUDE_CONFIG_DIR` HID EXISTING SESSIONS), SO THEY SHARE ONE SKILL SET. RUN `SCRIPTS/LINK-SKILLS.PS1 -PROFILE DESKTOP` TO LINK `CORE` SKILLS ONLY INTO `.CLAUDESKILLS`. KEEP THE SHORTCUTS ON THEIR ORIGINAL `--USER-DATA-DIR` TARGETS; `LAUNCHERS/` IS UNUSED.

# agent-config
Configuration for code agents


## Skills

Every skill has exactly one home:

| Scope | Home | Linked into |
|---|---|---|
| Everywhere | `skills/core/<skill>` | Desktop, Work and Personal |
| All work | `skills/work/<skill>` | Work |
| All personal | `skills/personal/<skill>` | Personal |
| One repo | `<repo>/.claude/skills/<skill>` (committed) | that repo only |

Profiles: Desktop = `C:\Users\richard\.claude` (core only); Work = `C:\Users\richard\.claudeWork` (core + work); Personal = `C:\Users\richard\.claudePersonal` (core + personal).
`Link-Skills.ps1` creates one directory junction per skill inside each profile's `skills` folder. It never touches `skills\synced`, never replaces a real folder (reports a Conflict), and removes dangling links.

### Add a skill

1. Create `skills/<tier>/<name>/SKILL.md`. Folder name must equal frontmatter `name`.
2. Run `scripts/Link-Skills.ps1 -Profile <Desktop|Work|Personal> [-WhatIf]` for each profile that uses the tier.
   Pass several repos with `-RepoRoots` from a PowerShell session (`& ./scripts/Link-Skills.ps1 ... -RepoRoots a,b`), not `pwsh -File`, which treats `a,b` as one string.

### No duplicate names

A skill name must not exist in two tiers selected for one profile, nor in a repo's `.claude/skills`
(personal skills beat project skills, so a stale copy would win). The script errors on tier duplicates and warns on repo collisions.

### Launching profiles

- **CLI:** use the existing aliases (they set `CLAUDE_CONFIG_DIR`).
- **VS Code:** one VS Code profile per Claude profile, each setting `claudeCode.environmentVariables`
  to `[{"name":"CLAUDE_CONFIG_DIR","value":"C:\\Users\\richard\\.claudeWork"}]` (or `.claudePersonal`). Use absolute paths; `~` is not expanded.
- **Desktop:** both Desktop installs read the default `C:\Users\richard\.claude` (forcing `CLAUDE_CONFIG_DIR` hid existing sessions), so they share one skill set. Run `scripts/Link-Skills.ps1 -Profile Desktop` to link `core` skills only into `.claude\skills`. Keep the shortcuts on their original `--user-data-dir` targets; `launchers/` is unused.

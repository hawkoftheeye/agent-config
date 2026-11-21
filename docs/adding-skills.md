# Adding and managing skills

Skills are single folders containing a `SKILL.md`. Each skill has one real copy; `scripts/Link-Skills.ps1` links it into the Claude config directories that should see it.

## 1. Choose where it lives

| Who needs it | Put it in | Visible in |
|---|---|---|
| Every app and profile | `skills/core/<name>/` | Desktop, Work, Personal |
| Work only | `skills/work/<name>/` | Work (CLI, VS Code) |
| Personal only | `skills/personal/<name>/` | Personal (CLI, VS Code) |
| One repo only | `<repo>/.claude/skills/<name>/`, committed in that repo | Sessions opened in that repo |

Config dirs and what each reads:

| Profile | Config dir | Tiers linked |
|---|---|---|
| Desktop (both installs) | `C:\Users\richard\.claude` | `core` |
| Work | `C:\Users\richard\.claudeWork` | `core` + `work` |
| Personal | `C:\Users\richard\.claudePersonal` | `core` + `personal` |

Desktop reads the default `.claude` for both accounts, so it can only have one shared set (`core`). Do not set `CLAUDE_CONFIG_DIR` for Desktop; it hides existing Desktop sessions.

## 2. Create the skill

1. Make the folder: `skills/<tier>/<name>/SKILL.md`.
2. The folder name must equal the frontmatter `name`:
   ```markdown
   ---
   name: my-skill
   description: One sentence on what it does and when to use it.
   ---
   ```
   Put supporting files (`references/`, scripts) inside the same folder.
3. Pick a name that exists nowhere else. See "Name rules" below.
4. Commit it in this repo.

## 3. Link it (required)

New skills are not visible until you run the script. From `Z:\git\personal\agent-config`:

```powershell
# preview first
pwsh scripts\Link-Skills.ps1 -Profile Personal -WhatIf
# then for real
pwsh scripts\Link-Skills.ps1 -Profile Personal
```

Run it once for every profile that uses the tier:

| Added to | Run for |
|---|---|
| `core` | `-Profile Desktop`, `-Profile Work`, `-Profile Personal` |
| `work` | `-Profile Work` |
| `personal` | `-Profile Personal` |

The script is idempotent: a second run reports only `Keep`. It creates one directory junction per skill, removes junctions whose target no longer exists, and never touches `skills\synced`.

To also check for the same name in repos, pass them from a PowerShell session (not `pwsh -File`, which treats `a,b` as one string):

```powershell
& .\scripts\Link-Skills.ps1 -Profile Personal -RepoRoots Z:\git\personal\resonance,Z:\git\work\toolkit,Z:\git\work\toolkit2 -WhatIf
```

Plan output: `Create`, `Keep`, `RemoveDangling`, or `Conflict`.

## 4. Pick it up

Skills are read when a session starts. Start a new session (or restart the app) after linking. Check by typing `/` in a new session, or ask which skills are available. Settings > Plugins > Skills in Desktop lists plugin skills only, not these.

## Name rules

- A name must not exist in two tiers linked into the same profile. The script stops with `Duplicate skill '<name>': <path1>, <path2>`.
- A name must not also exist in a repo's `.claude/skills`. Personal skills beat project skills, so a stale personal copy would silently override the repo's. The script warns on collisions when `-RepoRoots` is given.
- A skill needed by one repo belongs in that repo, committed. Worktrees receive it through git.

## Moving, renaming or removing a skill

- **Move between tiers:** `git mv` the folder, then re-run the script for every affected profile. Junctions to the old location are dangling and are removed automatically; new ones are created.
- **Remove:** delete the folder in `skills\<tier>`, then re-run the script for the affected profiles to clear the dangling link.
- Never delete `_retired\`; it holds the pre-migration originals.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Skill not listed | Not linked (run the script), a session started before linking (start a new one), or you are in a profile whose tiers do not include it. |
| `Conflict` in the plan | A real folder with that name exists in the profile's `skills` dir (or a junction elsewhere). The script never overwrites it. Check it, then move it to `_retired\` by hand and re-run. |
| `Duplicate skill` error | Same name in two tiers for one profile. Rename or remove one. |
| `Skipping '<dir>': no SKILL.md` | A tier folder has no `SKILL.md`; fix or remove it. |
| All skills vanished at once | The junction targets live in this working tree. If the folder was checked out to a branch without `skills/`, every link dangles. Check out `main` (or a branch containing `skills/`) again. |
| Skill is in a repo as well as core | Warning only if `-RepoRoots` is given. Remove one copy. |

## Windows notes

Links are directory junctions (no admin rights needed). A junction is removed with the script, or `rmdir <link>` / `[IO.Directory]::Delete(<link>)`; never delete a linked skill's contents through the profile path with `Remove-Item -Recurse`.

## Reference

- Script: `scripts/Link-Skills.ps1`; tests: `scripts/Link-Skills.Tests.ps1` (`Invoke-Pester scripts\Link-Skills.Tests.ps1`, Pester 5+).
- Design: `skills-layout-design.md`; plan: `2026-11-21-skills-layout-plan.md`.

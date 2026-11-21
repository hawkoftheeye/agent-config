# New machine setup

What cloning this repo gives you: the skills, `Link-Skills.ps1` (+ tests), `general.md`, `scripts/statusline-command.sh` and these docs. Everything below is machine-local and is **not** in the repo, so it must be recreated by hand.

Facts the current setup depends on (change them consistently if your new machine differs):

- Repo location: `Z:\git\personal\agent-config`. Two things reference it by absolute path: each profile's `CLAUDE.md` (`@Z:/git/personal/agent-config/general.md`) and each profile's `settings.json` `statusLine.command` (`bash Z:/git/personal/agent-config/scripts/statusline-command.sh`). `Link-Skills.ps1` itself is location-independent (it uses its own folder as the repo root and `$HOME` for the profiles).
- User name: the docs show `C:\Users\richard`; substitute yours. Config dirs must be absolute (`~` is not expanded by VS Code settings).
- Windows, PowerShell 7 (`pwsh`), Git Bash, Pester 5+ (only to run the tests).

## 1. Prerequisites

```powershell
git clone git@github.com:hawkoftheeye/agent-config.git Z:\git\personal\agent-config
# optional, to run the tests:
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

If you put the repo somewhere else, update the two absolute references above in step 2.

## 2. Create the profile config dirs

Three config dirs are used:

| Used by | Dir | Skill tiers |
|---|---|---|
| Desktop (both installs) | `%USERPROFILE%\.claude` | `core` |
| Work (CLI, VS Code) | `%USERPROFILE%\.claudeWork` | `core` + `work` |
| Personal (CLI, VS Code) | `%USERPROFILE%\.claudePersonal` | `core` + `personal` |

For `.claudeWork` and `.claudePersonal`, create the dir (running `claude` once with `CLAUDE_CONFIG_DIR` set, see step 4, also creates it) and add:

- `CLAUDE.md` containing `@Z:/git/personal/agent-config/general.md` (adjust the path if the repo lives elsewhere).
- In `settings.json`, the status line: `"statusLine": {"type": "command", "command": "bash Z:/git/personal/agent-config/scripts/statusline-command.sh"}`.
- Any plugins you want (the current profiles enable `code-review` and `pr-review-toolkit` from `claude-plugins-official`) and MCP servers. Those are not stored in this repo.

Log in once per dir; credentials are per config dir.

## 3. Link the skills

From the repo root:

```powershell
pwsh scripts\Link-Skills.ps1 -Profile Desktop  -WhatIf
pwsh scripts\Link-Skills.ps1 -Profile Work     -WhatIf
pwsh scripts\Link-Skills.ps1 -Profile Personal -WhatIf
```

Read the plan, then re-run each without `-WhatIf`. A fresh machine should show only `Create`. A `Conflict` means a real folder with that name already exists in that profile's `skills` dir (for example copies from an old install); the script never overwrites it, so move it aside and re-run. Run again to confirm everything reports `Keep`.

To also check for name collisions with repo skills, pass your repo roots from a PowerShell session (not `pwsh -File`):

```powershell
& .\scripts\Link-Skills.ps1 -Profile Personal -RepoRoots Z:\git\personal\resonance -WhatIf
```

## 4. CLI aliases (Git Bash)

Add to the file your shell config uses (currently `~/.config/bash/rc.d/60-os/windows-gitbash.sh`, sourced from `~/.bashrc`):

```bash
alias claudeWork='CLAUDE_CONFIG_DIR=~/.claudeWork claude'
alias claudePersonal='CLAUDE_CONFIG_DIR=~/.claudePersonal claude'

codew() { code --profile Work "${@:-.}"; }
codep() { code --profile Personal "${@:-.}"; }
```

Do not define `alias code=...`. Git Bash leaves `$USER` empty, so an alias built from it points at a non-existent path and shadows the real `code` on `PATH`.

## 5. VS Code profiles

Each VS Code profile has its own settings and its own extensions.

1. Create the profiles: `code --new-window --profile Work` and `code --new-window --profile Personal` (the CLI creates a profile on first use).
2. Install the extension into each: `code --profile Work --install-extension anthropic.claude-code`, and the same for `Personal`.
3. In each profile's user settings (Command Palette: "Preferences: Open User Settings (JSON)" while in that profile), set:
   ```json
   {
     "claudeCode.environmentVariables": [
       { "name": "CLAUDE_CONFIG_DIR", "value": "C:\\Users\\<you>\\.claudeWork" }
     ]
   }
   ```
   Use `.claudePersonal` in the Personal profile. Keep the doubled backslashes (JSON escaping).
4. Open folders with `codew` / `codep`. VS Code remembers which profile a folder uses.

## 6. Desktop

Leave the shortcuts on their normal `--user-data-dir` targets and do not set `CLAUDE_CONFIG_DIR` for Desktop. Doing so hid existing Desktop sessions. Both installs read `%USERPROFILE%\.claude`, which gets the `core` skills via `-Profile Desktop`.

## 7. Verify

- CLI: from any folder, `claudeWork` and `claudePersonal`, then `/status` (account) and type `/` (skills).
- VS Code: in each profile, open a folder, start a Claude session, check `/status` and `/skills`.
- Desktop: new Code session; type `/` and look for `create-xml-docs` and `langfuse`. (Settings > Plugins > Skills lists plugin skills only.)
- Skills are read at session start, so restart sessions opened before linking.

Skills expected: Desktop `create-xml-docs`, `langfuse`; Work adds `pr-comments`, `pr-description`; Personal adds anything in `skills/personal` (plus repo skills such as `update-resonance-docs` and `update-resonance-pricing` inside the Resonance repo once its PR has merged).

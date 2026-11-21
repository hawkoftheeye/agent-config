[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('Work', 'Personal', 'Desktop')][string]$Profile,
    [string]$ProfilesDir = $HOME,
    [string[]]$RepoRoots = @()
)

function Get-SkillSources {
    [CmdletBinding()]
    param([string]$Root, [string[]]$Tiers)

    $found = @{}
    foreach ($tier in $Tiers) {
        $tierDir = Join-Path $Root "skills\$tier"
        if (-not (Test-Path $tierDir)) { continue }
        foreach ($dir in Get-ChildItem $tierDir -Directory) {
            if (-not (Test-Path (Join-Path $dir.FullName 'SKILL.md'))) {
                Write-Warning "Skipping '$($dir.FullName)': no SKILL.md"
                continue
            }
            if ($found.ContainsKey($dir.Name)) {
                throw "Duplicate skill '$($dir.Name)': $($found[$dir.Name].Path), $($dir.FullName)"
            }
            $found[$dir.Name] = [pscustomobject]@{ Name = $dir.Name; Tier = $tier; Path = $dir.FullName }
        }
    }
    $found.Values | Sort-Object Name
}

function Get-NormalisedPath([string]$Path) {
    [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Get-LinkPlan {
    param([pscustomobject[]]$Sources, [string]$SkillsDir)

    $plan = @()
    $sourceNames = @{}
    foreach ($s in $Sources) { $sourceNames[$s.Name] = $s }

    foreach ($s in $Sources) {
        $linkPath = Join-Path $SkillsDir $s.Name
        $item = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
        $action = 'Create'
        if ($item) {
            if ($item.LinkType -ne 'Junction') {
                $action = 'Conflict'
            } elseif (-not (Test-Path -LiteralPath (@($item.Target)[0]))) {
                $action = 'RemoveDangling'
            } elseif ((Get-NormalisedPath (@($item.Target)[0])) -ieq (Get-NormalisedPath $s.Path)) {
                $action = 'Keep'
            } else {
                $action = 'Conflict'   # a link to somewhere else: never silently repoint
            }
        }
        $plan += [pscustomobject]@{ Action = $action; Name = $s.Name; LinkPath = $linkPath; Target = $s.Path }
    }

    # Dangling junctions for skills that no longer exist in any selected tier.
    if (Test-Path $SkillsDir) {
        foreach ($item in Get-ChildItem $SkillsDir -Directory -Force) {
            if ($item.Name -eq 'synced' -or $sourceNames.ContainsKey($item.Name)) { continue }
            if ($item.LinkType -eq 'Junction' -and -not (Test-Path -LiteralPath (@($item.Target)[0]))) {
                $plan += [pscustomobject]@{ Action = 'RemoveDangling'; Name = $item.Name; LinkPath = $item.FullName; Target = (@($item.Target)[0]) }
            }
        }
    }
    $plan
}

function Invoke-LinkPlan {
    [CmdletBinding(SupportsShouldProcess)]
    param([pscustomobject[]]$Plan)

    foreach ($entry in $Plan) {
        switch ($entry.Action) {
            'Create' {
                if ($PSCmdlet.ShouldProcess($entry.LinkPath, "Create junction -> $($entry.Target)")) {
                    $parent = Split-Path -Parent $entry.LinkPath
                    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                    New-Item -ItemType Junction -Path $entry.LinkPath -Target $entry.Target | Out-Null
                }
            }
            'RemoveDangling' {
                if ($PSCmdlet.ShouldProcess($entry.LinkPath, 'Remove dangling junction')) {
                    # Directory.Delete on a junction removes the link only, never the target.
                    [IO.Directory]::Delete($entry.LinkPath)
                }
            }
            'Conflict' { Write-Warning "Conflict: '$($entry.LinkPath)' exists and is not the expected link; left untouched." }
        }
    }
}

function Find-NameCollisions {
    param([string[]]$Names, [string[]]$RepoRoots)

    foreach ($repo in $RepoRoots) {
        $checkouts = @(Join-Path $repo 'main')
        $wt = Join-Path $repo 'worktrees'
        if (Test-Path $wt) { $checkouts += (Get-ChildItem $wt -Directory).FullName }
        foreach ($checkout in $checkouts) {
            foreach ($name in $Names) {
                $p = Join-Path $checkout ".claude\skills\$name"
                if (Test-Path $p) { $p }
            }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $Profile) { throw 'Specify -Profile Work, Personal or Desktop.' }
    $tiers = switch ($Profile) { 'Work' { 'core', 'work' } 'Personal' { 'core', 'personal' } 'Desktop' { 'core' } }
    $configDir = Join-Path $ProfilesDir ($(if ($Profile -eq 'Desktop') { '.claude' } else { ".claude$Profile" }))
    $skillsDir = Join-Path $configDir 'skills'

    $sources = @(Get-SkillSources -Root $Root -Tiers $tiers)
    $plan = @(Get-LinkPlan -Sources $sources -SkillsDir $skillsDir)

    foreach ($hit in Find-NameCollisions -Names $sources.Name -RepoRoots $RepoRoots) {
        Write-Warning "Name collision: repo skill '$hit' shadows/duplicates a linked skill."
    }

    $plan | Format-Table Action, Name, Target -AutoSize | Out-String | Write-Host
    Invoke-LinkPlan -Plan $plan -WhatIf:$WhatIfPreference
}

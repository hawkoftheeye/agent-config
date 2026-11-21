BeforeAll {
    . (Join-Path $PSScriptRoot 'Link-Skills.ps1')

    function New-Skill($Root, $Tier, $Name, [switch]$NoManifest) {
        $dir = Join-Path $Root "skills\$Tier\$Name"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        if (-not $NoManifest) { Set-Content (Join-Path $dir 'SKILL.md') "---`nname: $Name`n---" }
        $dir
    }
}

Describe 'Get-SkillSources' {
    It 'skips a folder with no SKILL.md and writes a warning' {
        $root = Join-Path $TestDrive 'r1'
        New-Skill $root 'core' 'good' | Out-Null
        New-Skill $root 'core' 'bad' -NoManifest | Out-Null
        $result = @(Get-SkillSources -Root $root -Tiers 'core' -WarningVariable warn -WarningAction SilentlyContinue)
        $result.Name | Should -Be @('good')
        ($warn -join ' ') | Should -Match 'bad'
    }

    It 'throws when a name is in two tiers' {
        $root = Join-Path $TestDrive 'r2'
        $p1 = New-Skill $root 'core' 'x'
        $p2 = New-Skill $root 'work' 'x'
        { Get-SkillSources -Root $root -Tiers 'core', 'work' } | Should -Throw "*Duplicate skill 'x'*"
        try { Get-SkillSources -Root $root -Tiers 'core', 'work' } catch { $msg = $_.Exception.Message }
        $msg | Should -Match ([regex]::Escape($p1))
        $msg | Should -Match ([regex]::Escape($p2))
    }

    It 'tolerates a missing tier folder' {
        $root = Join-Path $TestDrive 'r2b'
        New-Skill $root 'core' 'a' | Out-Null
        @(Get-SkillSources -Root $root -Tiers 'core', 'personal').Name | Should -Be @('a')
    }
}

Describe 'Get-LinkPlan' {
    BeforeEach {
        $script:root = Join-Path $TestDrive ([guid]::NewGuid())
        $script:skillsDir = Join-Path $script:root 'profile\skills'
        New-Item -ItemType Directory -Path $script:skillsDir -Force | Out-Null
    }

    It 'plans Create, Keep, RemoveDangling and Conflict' {
        $new = New-Skill $script:root 'core' 'new'
        $kept = New-Skill $script:root 'core' 'kept'
        $conf = New-Skill $script:root 'core' 'conf'
        New-Item -ItemType Junction -Path (Join-Path $script:skillsDir 'kept') -Target $kept | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:skillsDir 'conf') | Out-Null
        $gone = Join-Path $script:root 'gone'
        New-Item -ItemType Directory -Path $gone | Out-Null
        New-Item -ItemType Junction -Path (Join-Path $script:skillsDir 'gone') -Target $gone | Out-Null
        Remove-Item $gone

        $sources = Get-SkillSources -Root $script:root -Tiers 'core'
        $plan = Get-LinkPlan -Sources $sources -SkillsDir $script:skillsDir
        ($plan | Where-Object Name -eq 'new').Action | Should -Be 'Create'
        ($plan | Where-Object Name -eq 'kept').Action | Should -Be 'Keep'
        ($plan | Where-Object Name -eq 'conf').Action | Should -Be 'Conflict'
        ($plan | Where-Object Name -eq 'gone').Action | Should -Be 'RemoveDangling'
    }

    It 'never returns an entry named synced' {
        New-Skill $script:root 'core' 'a' | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:skillsDir 'synced') | Out-Null
        $plan = Get-LinkPlan -Sources (Get-SkillSources -Root $script:root -Tiers 'core') -SkillsDir $script:skillsDir
        $plan.Name | Should -Not -Contain 'synced'
    }

    It 'ignores unrelated real folders' {
        New-Skill $script:root 'core' 'a' | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:skillsDir 'other') | Out-Null
        $plan = Get-LinkPlan -Sources (Get-SkillSources -Root $script:root -Tiers 'core') -SkillsDir $script:skillsDir
        $plan.Name | Should -Not -Contain 'other'
    }

    It 'creates the skills dir when invoked and is idempotent' {
        New-Skill $script:root 'core' 'a' | Out-Null
        $fresh = Join-Path $script:root 'newprofile\skills'
        $sources = Get-SkillSources -Root $script:root -Tiers 'core'
        Invoke-LinkPlan -Plan (Get-LinkPlan -Sources $sources -SkillsDir $fresh)
        Invoke-LinkPlan -Plan (Get-LinkPlan -Sources $sources -SkillsDir $fresh)
        $plan = @(Get-LinkPlan -Sources $sources -SkillsDir $fresh)
        $plan.Count | Should -Be 1
        $plan.Action | Should -Be 'Keep'
    }

    It 'removes a dangling link without touching anything else' {
        $a = New-Skill $script:root 'core' 'a'
        $sources = Get-SkillSources -Root $script:root -Tiers 'core'
        $plan = Get-LinkPlan -Sources $sources -SkillsDir $script:skillsDir
        Invoke-LinkPlan -Plan $plan
        Remove-Item -Recurse $a
        $plan = Get-LinkPlan -Sources @() -SkillsDir $script:skillsDir
        $plan.Action | Should -Be 'RemoveDangling'
        Invoke-LinkPlan -Plan $plan
        Test-Path (Join-Path $script:skillsDir 'a') | Should -BeFalse
    }

    It 'WhatIf creates no junctions' {
        New-Skill $script:root 'core' 'a' | Out-Null
        $sources = Get-SkillSources -Root $script:root -Tiers 'core'
        $plan = Get-LinkPlan -Sources $sources -SkillsDir $script:skillsDir
        Invoke-LinkPlan -Plan $plan -WhatIf
        Test-Path (Join-Path $script:skillsDir 'a') | Should -BeFalse
    }
}

Describe 'Find-NameCollisions' {
    It 'finds a repo skill under main' {
        $repo = Join-Path $TestDrive 'repoA'
        $p = Join-Path $repo 'main\.claude\skills\langfuse'
        New-Item -ItemType Directory -Path $p -Force | Out-Null
        Find-NameCollisions -Names 'langfuse', 'other' -RepoRoots $repo | Should -Be @($p)
    }

    It 'finds a repo skill under a worktree' {
        $repo = Join-Path $TestDrive 'repoB'
        $p = Join-Path $repo 'worktrees\wt1\.claude\skills\langfuse'
        New-Item -ItemType Directory -Path $p -Force | Out-Null
        Find-NameCollisions -Names 'langfuse' -RepoRoots $repo | Should -Be @($p)
    }

    It 'returns nothing for a missing repo root' {
        @(Find-NameCollisions -Names 'x' -RepoRoots (Join-Path $TestDrive 'nope')).Count | Should -Be 0
    }
}

Describe 'entry point' {
    It 'stops with a duplicate error naming both paths' {
        $root = Join-Path $TestDrive 'r9'
        New-Skill $root 'core' 'x' | Out-Null
        New-Skill $root 'work' 'x' | Out-Null
        $pd = Join-Path $TestDrive 'profiles9'
        New-Item -ItemType Directory -Path (Join-Path $pd '.claudeWork') -Force | Out-Null
        { & (Join-Path $PSScriptRoot 'Link-Skills.ps1') -Root $root -Profile Work -ProfilesDir $pd } | Should -Throw "*Duplicate skill 'x'*"
    }
}

Describe 'Desktop profile' {
    It 'links only core skills into <ProfilesDir>\.claude\skills' {
        $root = Join-Path $TestDrive 'r10'
        New-Skill $root 'core' 'c1' | Out-Null
        New-Skill $root 'work' 'w1' | Out-Null
        New-Skill $root 'personal' 'p1' | Out-Null
        $pd = Join-Path $TestDrive 'profiles10'
        & (Join-Path $PSScriptRoot 'Link-Skills.ps1') -Root $root -Profile Desktop -ProfilesDir $pd | Out-Null
        $dir = Join-Path $pd '.claude\skills'
        (Get-ChildItem $dir).Name | Should -Be @('c1')
    }
}

Describe 'tier move' {
    It 'converges in one run when a skill moves between tiers' {
        $root = Join-Path $TestDrive 'r11'
        $old = New-Skill $root 'core' 'm'
        $skillsDir = Join-Path $TestDrive 'profile11\skills'
        $sources = Get-SkillSources -Root $root -Tiers 'core', 'work'
        Invoke-LinkPlan -Plan (Get-LinkPlan -Sources $sources -SkillsDir $skillsDir)
        New-Item -ItemType Directory -Path (Join-Path $root 'skills\work') -Force | Out-Null
        Move-Item $old (Join-Path $root 'skills\work\m')

        $sources = Get-SkillSources -Root $root -Tiers 'core', 'work'
        Invoke-LinkPlan -Plan (Get-LinkPlan -Sources $sources -SkillsDir $skillsDir)

        $plan = @(Get-LinkPlan -Sources $sources -SkillsDir $skillsDir)
        $plan.Action | Should -Be @('Keep')
        (Get-Item (Join-Path $skillsDir 'm')).Target | Should -Be (Join-Path $root 'skills\work\m')
    }
}

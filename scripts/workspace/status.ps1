[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$ManifestPath,
    [switch]$AsObject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$workstationRoot = Get-NormalizedPath -Path (Join-Path $PSScriptRoot '..\..')

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $WorkspaceRoot = Split-Path -Parent $workstationRoot
}
$WorkspaceRoot = Get-NormalizedPath -Path $WorkspaceRoot

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $workstationRoot 'workspace\repositories.json'
}
$ManifestPath = Get-NormalizedPath -Path $ManifestPath

if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git command not found.'
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Manifest not found: $ManifestPath"
}

$manifest = Get-Content -Raw -LiteralPath $ManifestPath -Encoding UTF8 |
    ConvertFrom-Json
$repositories = @($manifest.repositories)

$declaredTiers = @($manifest.tiers.PSObject.Properties.Name)
$tierResult = Get-TierLocation `
    -WorkspaceRoot $WorkspaceRoot `
    -WorkstationRoot $workstationRoot `
    -TierName $declaredTiers

foreach ($tierError in $tierResult.Errors) {
    Write-Warning $tierError
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($repository in $repositories) {
    $tier = [string]$repository.tier

    if (-not $tierResult.Locations.ContainsKey($tier)) {
        $results.Add([pscustomobject]@{
            Name = $repository.name
            Tier = $tier
            Owner = $repository.owner
            Type = $repository.type
            Health = 'tier-unavailable'
            Branch = $null
            Dirty = $null
            Ahead = $null
            Behind = $null
            RemoteOk = $false
        })
        continue
    }

    $location = $tierResult.Locations[$tier]
    $repositoryPath = Get-RepositoryPath `
        -Location $location `
        -RelativePath ([string]$repository.relativePath)

    if (-not (Test-RepositoryDirectory -Location $location -RepositoryPath $repositoryPath)) {
        $results.Add([pscustomobject]@{
            Name = $repository.name
            Tier = $tier
            Owner = $repository.owner
            Type = $repository.type
            Health = 'missing'
            Branch = $null
            Dirty = $null
            Ahead = $null
            Behind = $null
            RemoteOk = $false
        })
        continue
    }

    $insideWorkTree = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('rev-parse', '--is-inside-work-tree')
    if ($insideWorkTree -ne 'true') {
        $results.Add([pscustomobject]@{
            Name = $repository.name
            Tier = $tier
            Owner = $repository.owner
            Type = $repository.type
            Health = 'not-git'
            Branch = $null
            Dirty = $null
            Ahead = $null
            Behind = $null
            RemoteOk = $false
        })
        continue
    }

    $branch = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('branch', '--show-current')
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $branch = '(detached)'
    }

    $origin = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('remote', 'get-url', 'origin')
    $remoteOk = $origin -eq [string]$repository.remote

    $workingTreeStatus = Invoke-GitLines `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('status', '--porcelain=v1')
    $dirty = @($workingTreeStatus).Count -gt 0

    $upstream = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @(
            'rev-parse',
            '--abbrev-ref',
            '--symbolic-full-name',
            '@{upstream}'
        )
    $ahead = $null
    $behind = $null

    if (-not [string]::IsNullOrWhiteSpace($upstream)) {
        $counts = Invoke-GitText `
            -Location $location `
            -RepositoryPath $repositoryPath `
            -Arguments @(
                'rev-list',
                '--left-right',
                '--count',
                'HEAD...@{upstream}'
            )
        if (-not [string]::IsNullOrWhiteSpace($counts)) {
            $parts = $counts -split '\s+'
            if ($parts.Count -eq 2) {
                $ahead = [int]$parts[0]
                $behind = [int]$parts[1]
            }
        }
    }

    $health = if (-not $remoteOk) {
        'remote-mismatch'
    }
    elseif ($dirty) {
        'dirty'
    }
    elseif ($null -eq $upstream) {
        'no-upstream'
    }
    elseif ($ahead -gt 0 -and $behind -gt 0) {
        'diverged'
    }
    elseif ($ahead -gt 0) {
        'ahead'
    }
    elseif ($behind -gt 0) {
        'behind'
    }
    else {
        'clean'
    }

    $results.Add([pscustomobject]@{
        Name = $repository.name
        Tier = $tier
        Owner = $repository.owner
        Type = $repository.type
        Health = $health
        Branch = $branch
        Dirty = $dirty
        Ahead = $ahead
        Behind = $behind
        RemoteOk = $remoteOk
    })
}

if ($AsObject) {
    $results
}
else {
    $results | Format-Table -AutoSize
}

[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$ManifestPath,
    [switch]$AsObject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    try {
        $output = & git -C $RepositoryPath @Arguments 2>$null
    }
    catch {
        return $null
    }

    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
}

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
$results = New-Object System.Collections.Generic.List[object]

foreach ($repository in $repositories) {
    $repositoryPath = Get-NormalizedPath -Path (
        Join-Path $WorkspaceRoot ([string]$repository.relativePath)
    )

    if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
        $results.Add([pscustomobject]@{
            Name = $repository.name
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

    $insideWorkTree = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'rev-parse',
        '--is-inside-work-tree'
    )
    if ($insideWorkTree -ne 'true') {
        $results.Add([pscustomobject]@{
            Name = $repository.name
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

    $branch = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'branch',
        '--show-current'
    )
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $branch = '(detached)'
    }

    $origin = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'remote',
        'get-url',
        'origin'
    )
    $remoteOk = $origin -eq [string]$repository.remote

    $workingTreeStatus = & git -C $repositoryPath status --porcelain=v1 2>$null
    $dirty = @($workingTreeStatus).Count -gt 0

    $upstream = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'rev-parse',
        '--abbrev-ref',
        '--symbolic-full-name',
        '@{upstream}'
    )
    $ahead = $null
    $behind = $null

    if (-not [string]::IsNullOrWhiteSpace($upstream)) {
        $counts = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
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

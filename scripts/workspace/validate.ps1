[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$ManifestPath
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

function Stop-WorkspaceValidation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    [Console]::Error.WriteLine($Message)
    exit 1
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

$issues = New-Object System.Collections.Generic.List[string]

if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
    $issues.Add('git command not found.')
}
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
    $issues.Add("Workspace root not found: $WorkspaceRoot")
}
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    $issues.Add("Manifest not found: $ManifestPath")
}

if ($issues.Count -gt 0) {
    Stop-WorkspaceValidation -Message (
        "Workspace validation failed:`n- " + ($issues -join "`n- ")
    )
}

try {
    $manifest = Get-Content -Raw -LiteralPath $ManifestPath -Encoding UTF8 |
        ConvertFrom-Json
}
catch {
    Stop-WorkspaceValidation -Message (
        "Invalid JSON manifest: $($_.Exception.Message)"
    )
}

if ($manifest.schemaVersion -ne 2) {
    $issues.Add("Unsupported schemaVersion: $($manifest.schemaVersion)")
}

$repositories = @($manifest.repositories)
if ($repositories.Count -eq 0) {
    $issues.Add('Manifest contains no repositories.')
}

$requiredFields = @(
    'name',
    'relativePath',
    'owner',
    'type',
    'remote',
    'defaultBranch',
    'role',
    'purpose'
)
$seenNames = @{}
$seenPaths = @{}
$seenRemotes = @{}
$allowedTypes = @{
    personal = $true
    company = $true
}
$expectedOwnerTypes = @{
    brighthe = 'personal'
    suanhaitech = 'company'
}
$workspacePrefix = $WorkspaceRoot + [System.IO.Path]::DirectorySeparatorChar

foreach ($repository in $repositories) {
    foreach ($field in $requiredFields) {
        if (
            $repository.PSObject.Properties.Name -notcontains $field -or
            [string]::IsNullOrWhiteSpace([string]$repository.$field)
        ) {
            $issues.Add("Repository entry is missing required field '$field'.")
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$repository.name)) {
        continue
    }

    $name = [string]$repository.name
    $relativePath = [string]$repository.relativePath
    $owner = [string]$repository.owner
    $type = [string]$repository.type
    $remote = [string]$repository.remote

    if (-not $allowedTypes.ContainsKey($type)) {
        $issues.Add("[$name] unsupported repository type: $type")
    }

    if (-not $expectedOwnerTypes.ContainsKey($owner)) {
        $issues.Add("[$name] unsupported repository owner: $owner")
    }
    elseif ($expectedOwnerTypes[$owner] -ne $type) {
        $issues.Add(
            "[$name] owner/type mismatch: owner '$owner' requires type " +
            "'$($expectedOwnerTypes[$owner])', got '$type'"
        )
    }

    $expectedRemote = "git@github.com:$owner/$name.git"
    if ($remote -ne $expectedRemote) {
        $issues.Add(
            "[$name] remote does not match owner/name: expected " +
            "'$expectedRemote', got '$remote'"
        )
    }

    if ($seenNames.ContainsKey($name)) {
        $issues.Add("Duplicate repository name: $name")
    }
    else {
        $seenNames[$name] = $true
    }

    if ([System.IO.Path]::IsPathRooted($relativePath)) {
        $issues.Add("[$name] relativePath must not be absolute: $relativePath")
        continue
    }

    $repositoryPath = Get-NormalizedPath -Path (
        Join-Path $WorkspaceRoot $relativePath
    )
    if (
        $repositoryPath -ne $WorkspaceRoot -and
        -not $repositoryPath.StartsWith(
            $workspacePrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        $issues.Add("[$name] path escapes workspace root: $relativePath")
        continue
    }

    if ($seenPaths.ContainsKey($repositoryPath)) {
        $issues.Add("Duplicate repository path: $relativePath")
    }
    else {
        $seenPaths[$repositoryPath] = $true
    }

    if ($seenRemotes.ContainsKey($remote)) {
        $issues.Add("Duplicate repository remote: $remote")
    }
    else {
        $seenRemotes[$remote] = $true
    }

    if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
        $issues.Add("[$name] repository directory not found: $repositoryPath")
        continue
    }

    $insideWorkTree = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'rev-parse',
        '--is-inside-work-tree'
    )
    if ($insideWorkTree -ne 'true') {
        $issues.Add("[$name] not a Git working tree: $repositoryPath")
        continue
    }

    $actualRemote = Invoke-GitText -RepositoryPath $repositoryPath -Arguments @(
        'remote',
        'get-url',
        'origin'
    )
    if ($actualRemote -ne $remote) {
        $issues.Add(
            "[$name] origin mismatch: expected '$remote', got '$actualRemote'"
        )
    }

    $localDefaultBranch = Invoke-GitText `
        -RepositoryPath $repositoryPath `
        -Arguments @(
            'show-ref',
            '--verify',
            "refs/heads/$($repository.defaultBranch)"
        )

    $remoteDefaultBranch = Invoke-GitText `
        -RepositoryPath $repositoryPath `
        -Arguments @(
            'show-ref',
            '--verify',
            "refs/remotes/origin/$($repository.defaultBranch)"
        )

    if ($null -eq $localDefaultBranch -and $null -eq $remoteDefaultBranch) {
        $issues.Add(
            "[$name] default branch ref not found locally: " +
            "$($repository.defaultBranch)"
        )
    }
}

if ($issues.Count -gt 0) {
    Stop-WorkspaceValidation -Message (
        "Workspace validation failed:`n- " + ($issues -join "`n- ")
    )
}

Write-Host 'Workspace validation passed.' -ForegroundColor Green
Write-Host "Manifest:  $ManifestPath"
Write-Host "Workspace: $WorkspaceRoot"
Write-Host "Managed repositories: $($repositories.Count)"
exit 0

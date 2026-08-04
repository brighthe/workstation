[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

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

if ($manifest.schemaVersion -ne 3) {
    $issues.Add("Unsupported schemaVersion: $($manifest.schemaVersion)")
}

if ($manifest.PSObject.Properties.Name -notcontains 'tiers') {
    Stop-WorkspaceValidation -Message 'Manifest is missing the "tiers" object.'
}

$declaredTiers = @($manifest.tiers.PSObject.Properties.Name)
if ($declaredTiers.Count -eq 0) {
    Stop-WorkspaceValidation -Message 'Manifest declares no tiers.'
}

$repositories = @($manifest.repositories)
if ($repositories.Count -eq 0) {
    $issues.Add('Manifest contains no repositories.')
}

# Tier locations come from workspace\roots.local.json, which is gitignored
# because distro names and paths are machine specific. When that file is
# absent every tier resolves to the Windows workspace root, so machines that
# have not opted into a second runtime behave exactly as before.
$tierResult = Get-TierLocation `
    -WorkspaceRoot $WorkspaceRoot `
    -WorkstationRoot $workstationRoot `
    -TierName $declaredTiers

foreach ($tierError in $tierResult.Errors) {
    $issues.Add($tierError)
}

$requiredFields = @(
    'name',
    'relativePath',
    'tier',
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
    $tier = [string]$repository.tier
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

    if ($declaredTiers -notcontains $tier) {
        $issues.Add("[$name] tier '$tier' is not declared in the manifest tiers.")
        continue
    }

    if (-not $tierResult.Locations.ContainsKey($tier)) {
        # Get-TierLocation already reported why this tier could not resolve.
        continue
    }
    $location = $tierResult.Locations[$tier]

    if ([System.IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '^[A-Za-z]:') {
        $issues.Add("[$name] relativePath must not be absolute: $relativePath")
        continue
    }

    if (($relativePath -split '[\\/]') -contains '..') {
        $issues.Add("[$name] relativePath must not escape the tier root: $relativePath")
        continue
    }

    $repositoryPath = Get-RepositoryPath -Location $location -RelativePath $relativePath

    if ($location.Kind -eq 'windows') {
        $workspacePrefix = $location.Root + [System.IO.Path]::DirectorySeparatorChar
        if (
            $repositoryPath -ne $location.Root -and
            -not $repositoryPath.StartsWith(
                $workspacePrefix,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            $issues.Add("[$name] path escapes workspace root: $relativePath")
            continue
        }
    }

    $pathKey = "$($location.Kind):$repositoryPath"
    if ($seenPaths.ContainsKey($pathKey)) {
        $issues.Add("Duplicate repository path: $relativePath")
    }
    else {
        $seenPaths[$pathKey] = $true
    }

    if ($seenRemotes.ContainsKey($remote)) {
        $issues.Add("Duplicate repository remote: $remote")
    }
    else {
        $seenRemotes[$remote] = $true
    }

    if (-not (Test-RepositoryDirectory -Location $location -RepositoryPath $repositoryPath)) {
        $issues.Add("[$name] repository directory not found: $repositoryPath")
        continue
    }

    $insideWorkTree = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('rev-parse', '--is-inside-work-tree')
    if ($insideWorkTree -ne 'true') {
        $issues.Add("[$name] not a Git working tree: $repositoryPath")
        continue
    }

    $actualRemote = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @('remote', 'get-url', 'origin')
    if ($actualRemote -ne $remote) {
        $issues.Add(
            "[$name] origin mismatch: expected '$remote', got '$actualRemote'"
        )
    }

    $localDefaultBranch = Invoke-GitText `
        -Location $location `
        -RepositoryPath $repositoryPath `
        -Arguments @(
            'show-ref',
            '--verify',
            "refs/heads/$($repository.defaultBranch)"
        )

    $remoteDefaultBranch = Invoke-GitText `
        -Location $location `
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

$tierSummary = ($declaredTiers | ForEach-Object {
    $loc = $tierResult.Locations[$_]
    if ($loc.Kind -eq 'wsl') { "$_ -> wsl:$($loc.Distro):$($loc.Root)" }
    else { "$_ -> windows:$($loc.Root)" }
}) -join '; '

Write-Host 'Workspace validation passed.' -ForegroundColor Green
Write-Host "Manifest:  $ManifestPath"
Write-Host "Workspace: $WorkspaceRoot"
Write-Host "Tiers:     $tierSummary"
Write-Host "Managed repositories: $($repositories.Count)"
exit 0

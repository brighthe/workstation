Set-StrictMode -Version Latest

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

function Resolve-WslRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Distro,
        [Parameter(Mandatory = $true)]
        [string]$HomeRelativePath
    )

    if ($null -eq (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $wslHome = & wsl.exe -d $Distro -- bash -lc 'printf %s "$HOME"' 2>$null
    }
    catch {
        return $null
    }

    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    $wslHome = (($wslHome | ForEach-Object { [string]$_ }) -join '').Trim()
    if ([string]::IsNullOrWhiteSpace($wslHome)) {
        return $null
    }

    return ($wslHome.TrimEnd('/') + '/' + $HomeRelativePath.Trim('/'))
}

function Get-TierLocation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]
        [string]$WorkstationRoot,
        [Parameter(Mandatory = $true)]
        [string[]]$TierName
    )

    $rootsPath = Join-Path $WorkstationRoot 'workspace\roots.local.json'
    $result = @{
        Locations = @{}
        Errors    = New-Object System.Collections.Generic.List[string]
    }

    $windowsLocation = [pscustomobject]@{
        Kind   = 'windows'
        Root   = $WorkspaceRoot
        Distro = $null
    }

    # No local mapping: every tier resolves to the Windows workspace root.
    # This keeps behaviour identical to schemaVersion 2 on machines that have
    # not opted into a second runtime.
    if (-not (Test-Path -LiteralPath $rootsPath -PathType Leaf)) {
        foreach ($tier in $TierName) {
            $result.Locations[$tier] = $windowsLocation
        }
        return $result
    }

    try {
        $roots = Get-Content -Raw -LiteralPath $rootsPath -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        $result.Errors.Add("Invalid JSON in roots.local.json: $($_.Exception.Message)")
        return $result
    }

    if ($roots.PSObject.Properties.Name -notcontains 'tiers') {
        $result.Errors.Add('roots.local.json is missing the "tiers" object.')
        return $result
    }

    foreach ($tier in $TierName) {
        if ($roots.tiers.PSObject.Properties.Name -notcontains $tier) {
            $result.Errors.Add("roots.local.json does not map tier '$tier'.")
            continue
        }

        $entry = $roots.tiers.$tier
        $kind = [string]$entry.kind

        switch ($kind) {
            'windows' {
                $result.Locations[$tier] = $windowsLocation
            }
            'wsl' {
                $distro = [string]$entry.distro
                $homeRelativePath = [string]$entry.homeRelativePath
                if ([string]::IsNullOrWhiteSpace($distro) -or
                    [string]::IsNullOrWhiteSpace($homeRelativePath)) {
                    $result.Errors.Add(
                        "Tier '$tier' of kind 'wsl' needs both 'distro' and 'homeRelativePath'."
                    )
                    break
                }

                $wslRoot = Resolve-WslRoot -Distro $distro -HomeRelativePath $homeRelativePath
                if ($null -eq $wslRoot) {
                    $result.Errors.Add(
                        "Tier '$tier' unavailable: WSL distro '$distro' did not respond. " +
                        "Check 'wsl -l -v'; this is an environment problem, not a repository problem."
                    )
                    break
                }

                $result.Locations[$tier] = [pscustomobject]@{
                    Kind   = 'wsl'
                    Root   = $wslRoot
                    Distro = $distro
                }
            }
            default {
                $result.Errors.Add("Tier '$tier' has unsupported kind: $kind")
            }
        }
    }

    return $result
}

function Get-RepositoryPath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Location,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ($Location.Kind -eq 'wsl') {
        return ($Location.Root.TrimEnd('/') + '/' + ($RelativePath -replace '\\', '/').Trim('/'))
    }

    return Get-NormalizedPath -Path (Join-Path $Location.Root $RelativePath)
}

function Test-RepositoryDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Location,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )

    if ($Location.Kind -eq 'wsl') {
        & wsl.exe -d $Location.Distro -- test -d $RepositoryPath 2>$null
        return ($LASTEXITCODE -eq 0)
    }

    return (Test-Path -LiteralPath $RepositoryPath -PathType Container)
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Location,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    try {
        if ($Location.Kind -eq 'wsl') {
            $output = & wsl.exe -d $Location.Distro -- git -C $RepositoryPath @Arguments 2>$null
        }
        else {
            $output = & git -C $RepositoryPath @Arguments 2>$null
        }
    }
    catch {
        return $null
    }

    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    return (($output | ForEach-Object { [string]$_ }) -join "`n").Trim()
}

function Invoke-GitLines {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Location,
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    try {
        if ($Location.Kind -eq 'wsl') {
            $output = & wsl.exe -d $Location.Distro -- git -C $RepositoryPath @Arguments 2>$null
        }
        else {
            $output = & git -C $RepositoryPath @Arguments 2>$null
        }
    }
    catch {
        return @()
    }

    return @($output | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

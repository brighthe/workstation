[CmdletBinding()]
param(
    [string]$WorkspaceRoot = 'C:\workspace',
    [string]$LogRoot = (Join-Path $env:LOCALAPPDATA 'Workstation\logs\icloud-sync'),
    [switch]$Preview,
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$mutexName = 'Local\WorkstationICloudRepositorySync'
$mutex = $null
$mutexAcquired = $false
$overallExitCode = 1

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

try {
    $WorkspaceRoot = Get-NormalizedPath -Path $WorkspaceRoot
    $LogRoot = Get-NormalizedPath -Path $LogRoot
    $powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $iCloudDrive = Join-Path $env:USERPROFILE 'iCloudDrive'

    $repositories = @(
        [pscustomobject]@{
            Name = 'dut-postdoc'
            Script = Join-Path $WorkspaceRoot 'dut-postdoc\sync_to_icloud.ps1'
        },
        [pscustomobject]@{
            Name = 'dut-institute-work'
            Script = Join-Path $WorkspaceRoot 'dut-institute-work\sync_to_icloud.ps1'
        }
    )

    $validationErrors = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
        $validationErrors.Add("Workspace root not found: $WorkspaceRoot")
    }
    if (-not (Test-Path -LiteralPath $powerShellExe -PathType Leaf)) {
        $validationErrors.Add("Windows PowerShell not found: $powerShellExe")
    }
    if (-not (Test-Path -LiteralPath $iCloudDrive -PathType Container)) {
        $validationErrors.Add("iCloud Drive not found: $iCloudDrive")
    }
    if ($null -eq (Get-Command robocopy.exe -ErrorAction SilentlyContinue)) {
        $validationErrors.Add('robocopy.exe not found.')
    }

    foreach ($repository in $repositories) {
        if (-not (Test-Path -LiteralPath $repository.Script -PathType Leaf)) {
            $validationErrors.Add("$($repository.Name) sync script not found: $($repository.Script)")
        }
    }

    if ($validationErrors.Count -gt 0) {
        throw ("Validation failed:`n- " + ($validationErrors -join "`n- "))
    }

    Write-Host 'Validation passed for both repositories.' -ForegroundColor Green
    Write-Host "Workspace: $WorkspaceRoot"
    Write-Host "iCloud:    $iCloudDrive"

    if ($ValidateOnly) {
        exit 0
    }

    if (-not (Test-Path -LiteralPath $LogRoot -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $LogRoot -Force
    }

    $retentionCutoff = (Get-Date).AddDays(-30)
    Get-ChildItem -LiteralPath $LogRoot -Filter 'sync-*.log' -File -ErrorAction SilentlyContinue |
        Where-Object LastWriteTime -lt $retentionCutoff |
        Remove-Item -Force

    $mutex = [System.Threading.Mutex]::new($false, $mutexName)
    try {
        $mutexAcquired = $mutex.WaitOne(0, $false)
    }
    catch [System.Threading.AbandonedMutexException] {
        $mutexAcquired = $true
    }

    if (-not $mutexAcquired) {
        throw 'Another iCloud repository sync is already running.'
    }

    $runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logPath = Join-Path $LogRoot "sync-$runTimestamp.log"

    function Write-RunLog {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )

        $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
        Write-Host $line
        Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    }

    Write-RunLog "Started repository sync. Preview=$([bool]$Preview)"
    Write-RunLog "WorkspaceRoot=$WorkspaceRoot"

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($repository in $repositories) {
        Write-RunLog "[$($repository.Name)] Starting."

        $childArguments = @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $repository.Script
        )
        if ($Preview) {
            $childArguments += '-Preview'
        }

        $childOutput = & $powerShellExe @childArguments 2>&1
        $childExitCode = $LASTEXITCODE

        foreach ($outputLine in $childOutput) {
            Write-RunLog "[$($repository.Name)] $([string]$outputLine)"
        }

        $results.Add([pscustomobject]@{
            Name = $repository.Name
            ExitCode = $childExitCode
        })

        Write-RunLog "[$($repository.Name)] Finished with exit code $childExitCode."
    }

    $failedResults = @($results | Where-Object ExitCode -ne 0)
    foreach ($result in $results) {
        $resultText = if ($result.ExitCode -eq 0) { 'SUCCESS' } else { "FAILED ($($result.ExitCode))" }
        Write-RunLog ("Summary: {0} = {1}" -f $result.Name, $resultText)
    }

    if ($failedResults.Count -gt 0) {
        Write-RunLog "Completed with $($failedResults.Count) failed repository sync(s)."
        $overallExitCode = 1
    }
    else {
        Write-RunLog 'Completed successfully.'
        $overallExitCode = 0
    }
}
catch {
    Write-Error $_.Exception.Message
    $overallExitCode = 1
}
finally {
    if ($mutexAcquired -and $null -ne $mutex) {
        $mutex.ReleaseMutex()
    }
    if ($null -ne $mutex) {
        $mutex.Dispose()
    }
}

exit $overallExitCode

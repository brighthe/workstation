[CmdletBinding()]
param(
    [ValidateSet('Install', 'Status', 'Uninstall')]
    [string]$Action = 'Install',
    [string]$WorkspaceRoot = 'C:\workspace',
    [TimeSpan]$DailyAt = ([TimeSpan]::FromHours(21))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$taskName = 'Workstation-iCloud-Sync'
$managedDescription = 'Managed by brighthe/workstation scripts/icloud-sync.'
$syncScript = Join-Path $PSScriptRoot 'sync-repositories-to-icloud.ps1'
$powerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Test-IsAdministrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Action -in @('Install', 'Uninstall') -and -not (Test-IsAdministrator)) {
    $elevationArguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"",
        '-Action', $Action,
        '-WorkspaceRoot', "`"$WorkspaceRoot`"",
        '-DailyAt', $DailyAt.ToString()
    )

    try {
        $elevatedProcess = Start-Process `
            -FilePath $powerShellExe `
            -ArgumentList $elevationArguments `
            -Verb RunAs `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        exit $elevatedProcess.ExitCode
    }
    catch {
        Write-Error ("Administrator elevation was not completed: {0}" -f $_.Exception.Message)
        exit 1
    }
}

function Get-ManagedTask {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($null -ne $task -and $task.Description -ne $managedDescription) {
        throw "Task '$taskName' already exists but is not managed by workstation. No changes were made."
    }
    return $task
}

function Show-TaskStatus {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Task
    )

    $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
    Write-Host "TaskName:       $($Task.TaskName)"
    Write-Host "State:          $($Task.State)"
    Write-Host "UserId:         $($Task.Principal.UserId)"
    Write-Host "LogonType:      $($Task.Principal.LogonType)"
    Write-Host "RunLevel:       $($Task.Principal.RunLevel)"
    Write-Host "Action:         $($Task.Actions.Execute) $($Task.Actions.Arguments)"
    Write-Host "NextRunTime:    $($taskInfo.NextRunTime)"
    Write-Host "LastRunTime:    $($taskInfo.LastRunTime)"
    Write-Host "LastTaskResult: $($taskInfo.LastTaskResult)"
}

try {
    $WorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $existingTask = Get-ManagedTask

    switch ($Action) {
        'Status' {
            if ($null -eq $existingTask) {
                Write-Host "Task '$taskName' is not installed."
                exit 1
            }
            Show-TaskStatus -Task $existingTask
            exit 0
        }

        'Uninstall' {
            if ($null -eq $existingTask) {
                Write-Host "Task '$taskName' is already absent."
                exit 0
            }
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "Task '$taskName' was removed." -ForegroundColor Green
            exit 0
        }

        'Install' {
            if (-not (Test-Path -LiteralPath $syncScript -PathType Leaf)) {
                throw "Sync controller not found: $syncScript"
            }
            if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
                throw "Workspace root not found: $WorkspaceRoot"
            }

            & $powerShellExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $syncScript -WorkspaceRoot $WorkspaceRoot -ValidateOnly
            if ($LASTEXITCODE -ne 0) {
                throw "Sync controller validation failed with exit code $LASTEXITCODE."
            }

            $taskArguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{0}" -WorkspaceRoot "{1}"' -f $syncScript, $WorkspaceRoot
            $taskAction = New-ScheduledTaskAction `
                -Execute $powerShellExe `
                -Argument $taskArguments `
                -WorkingDirectory $PSScriptRoot
            $triggerAt = (Get-Date).Date.Add($DailyAt)
            $taskTrigger = New-ScheduledTaskTrigger -Daily -At $triggerAt
            $taskSettings = New-ScheduledTaskSettingsSet `
                -StartWhenAvailable `
                -AllowStartIfOnBatteries `
                -DontStopIfGoingOnBatteries `
                -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
                -MultipleInstances IgnoreNew
            $taskPrincipal = New-ScheduledTaskPrincipal `
                -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
                -LogonType Interactive `
                -RunLevel Limited
            $taskDefinition = New-ScheduledTask `
                -Action $taskAction `
                -Trigger $taskTrigger `
                -Settings $taskSettings `
                -Principal $taskPrincipal `
                -Description $managedDescription

            $null = Register-ScheduledTask -TaskName $taskName -InputObject $taskDefinition -Force
            $installedTask = Get-ScheduledTask -TaskName $taskName
            Write-Host "Task '$taskName' installed or updated." -ForegroundColor Green
            Show-TaskStatus -Task $installedTask
            exit 0
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$beginMarker = '# BEGIN WORKSTATION SSH MESH'
$endMarker = '# END WORKSTATION SSH MESH'
$meshFirewallRule = 'Workstation-SshMesh-Tailscale-In'
$defaultFirewallRule = 'OpenSSH-Server-In-TCP'
$stateRoot = [System.IO.Path]::GetFullPath((Join-Path $env:ProgramData 'SshMeshSetup'))

function Test-IsAdministrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Remove-ManagedBlock {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    $existing = [System.IO.File]::ReadAllText($Path)
    $pattern = '(?ms)^' + [regex]::Escape($beginMarker) + '\r?\n.*?^' + [regex]::Escape($endMarker) + '\r?\n?'
    $newContent = [regex]::Replace($existing, $pattern, '').TrimEnd()
    if (-not [string]::IsNullOrWhiteSpace($newContent)) {
        $newContent += [Environment]::NewLine
    }
    Write-Utf8NoBom -Path $Path -Content $newContent
}

function Restore-FirewallState {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)]$State
    )

    $current = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
    if ([bool]$State.Exists) {
        if ($null -eq $current) {
            Write-Warning "原有 Firewall rule '$Name' 当前不存在，无法仅凭状态清单重建。"
            return
        }
        $enabled = ([string]$State.Enabled -eq 'True')
        Set-NetFirewallRule -Name $Name -Enabled $enabled | Out-Null
    } elseif ($null -ne $current) {
        Remove-NetFirewallRule -Name $Name
    }
}

if (-not (Test-IsAdministrator)) {
    throw '恢复必须在“以管理员身份运行”的 PowerShell 中执行。'
}

$BackupDirectory = [System.IO.Path]::GetFullPath($BackupDirectory)
if (-not $BackupDirectory.StartsWith($stateRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "BackupDirectory 必须位于：$stateRoot"
}
if (-not (Test-Path -LiteralPath $BackupDirectory -PathType Container)) {
    throw "找不到备份目录：$BackupDirectory"
}

$manifestPath = Join-Path $BackupDirectory 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "备份缺少 manifest.json：$manifestPath"
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.SchemaVersion -ne 1 -or $manifest.Phase -notin @('Initialize', 'Apply')) {
    throw '不支持的备份 manifest。'
}

$preRestoreDirectory = Join-Path $stateRoot ("pre-restore-" + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
New-Item -ItemType Directory -Path $preRestoreDirectory -Force | Out-Null

if ($manifest.Phase -eq 'Apply') {
    foreach ($fileState in $manifest.Files) {
        $path = [string]$fileState.Path
        if (Test-Path -LiteralPath $path) {
            $safeName = ([string]$fileState.Kind) + '.current'
            Copy-Item -LiteralPath $path -Destination (Join-Path $preRestoreDirectory $safeName)
        }

        $backupFile = Join-Path $BackupDirectory ([string]$fileState.BackupFile)
        if ([bool]$fileState.Existed) {
            if (-not (Test-Path -LiteralPath $backupFile)) {
                throw "备份文件缺失：$backupFile"
            }
            $parent = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            Copy-Item -LiteralPath $backupFile -Destination $path -Force
        } elseif ([string]$fileState.Kind -in @('AuthorizedKeys', 'ClientConfig', 'KnownHosts')) {
            Remove-ManagedBlock -Path $path
        }
    }
}

if ($manifest.Phase -eq 'Initialize') {
    $sshdConfigPath = [string]$manifest.SshdConfig.Path
    if (Test-Path -LiteralPath $sshdConfigPath) {
        Copy-Item -LiteralPath $sshdConfigPath -Destination (Join-Path $preRestoreDirectory 'sshd_config.current')
    }
    $sshdBackupPath = Join-Path $BackupDirectory ([string]$manifest.SshdConfig.BackupFile)
    if (Test-Path -LiteralPath $sshdBackupPath) {
        Copy-Item -LiteralPath $sshdBackupPath -Destination $sshdConfigPath -Force
    }

    if ([bool]$manifest.DefaultShell.Existed) {
        if (-not (Test-Path -LiteralPath 'HKLM:\SOFTWARE\OpenSSH')) {
            New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
        }
        New-ItemProperty `
            -Path 'HKLM:\SOFTWARE\OpenSSH' `
            -Name 'DefaultShell' `
            -Value ([string]$manifest.DefaultShell.Value) `
            -PropertyType String `
            -Force | Out-Null
    } else {
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -ErrorAction SilentlyContinue
    }

    if ($null -ne $manifest.AcStandbySeconds) {
        & powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE ([int]$manifest.AcStandbySeconds)
        if ($LASTEXITCODE -ne 0) {
            throw "恢复 AC 睡眠值失败，退出码：$LASTEXITCODE"
        }
        & powercfg.exe /setactive SCHEME_CURRENT
    }
}

Restore-FirewallState -Name $defaultFirewallRule -State $manifest.DefaultFirewall
Restore-FirewallState -Name $meshFirewallRule -State $manifest.MeshFirewall

$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($null -ne $sshdService) {
    $sshdConfigPath = Join-Path $env:ProgramData 'ssh\sshd_config'
    $sshdExecutable = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
    if (Test-Path -LiteralPath $sshdConfigPath) {
        & $sshdExecutable -t -f $sshdConfigPath
        if ($LASTEXITCODE -ne 0) {
            throw '恢复后的 sshd_config 校验失败；未重启 sshd。恢复前当前状态已保存在 pre-restore 目录。'
        }
    }
    Restart-Service -Name sshd
}

Write-Host '恢复完成。' -ForegroundColor Green
Write-Host "恢复前状态备份：$preRestoreDirectory"
Write-Host '私钥未被删除或修改。' -ForegroundColor Yellow

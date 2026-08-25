[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('laptop', 'gpu-5080', 'gpu-5070ti')]
    [string]$Alias,

    [Parameter(Mandatory = $true)]
    [string]$TargetUser,

    [string]$KeyPath,

    [string]$OutputDirectory,

    [switch]$PreflightOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$meshFirewallRule = 'Workstation-SshMesh-Tailscale-In'
$defaultFirewallRule = 'OpenSSH-Server-In-TCP'
$stateRoot = Join-Path $env:ProgramData 'SshMeshSetup'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot 'state'
}

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

function Resolve-TailscaleCli {
    $command = Get-Command tailscale.exe -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $defaultPath = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
    if (Test-Path -LiteralPath $defaultPath) {
        return $defaultPath
    }

    return $null
}

function Resolve-Account {
    param([Parameter(Mandatory = $true)][string]$Name)

    try {
        $account = New-Object System.Security.Principal.NTAccount($Name)
        $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
        $resolvedName = $sid.Translate([System.Security.Principal.NTAccount]).Value
    } catch {
        throw "无法解析 Windows 账户 '$Name'。请在目标日常账户中运行 whoami，并传入完整结果。"
    }

    $parts = $resolvedName -split '\\', 2
    if ($parts.Count -ne 2) {
        throw "无法从账户名提取 SSH 用户名：$resolvedName"
    }

    $profile = Get-CimInstance -ClassName Win32_UserProfile |
        Where-Object { $_.SID -eq $sid.Value } |
        Select-Object -First 1
    $profilePath = $null
    if ($null -ne $profile) {
        $profilePath = $profile.LocalPath
    }
    if ([string]::IsNullOrWhiteSpace($profilePath) -and
        $sid.Value -eq [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) {
        $profilePath = $env:USERPROFILE
    }
    if ([string]::IsNullOrWhiteSpace($profilePath)) {
        throw "找不到账户 $resolvedName 的本地用户配置目录。请先登录该账户一次。"
    }

    $administrators = Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop
    $isAdministrator = @($administrators | Where-Object {
        $null -ne $_.SID -and $_.SID.Value -eq $sid.Value
    }).Count -gt 0

    return [PSCustomObject]@{
        Name            = $resolvedName
        User            = $parts[1]
        Sid             = $sid.Value
        ProfilePath     = $profilePath
        IsAdministrator = $isAdministrator
    }
}

function Set-GlobalSshdDirective {
    param(
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $matchIndex = $Lines.Count
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^\s*Match\s+') {
            $matchIndex = $index
            break
        }
    }

    $result = New-Object System.Collections.Generic.List[string]
    for ($index = 0; $index -lt $matchIndex; $index++) {
        if ($Lines[$index] -notmatch ('^\s*#?\s*' + [regex]::Escape($Name) + '\s+')) {
            $result.Add($Lines[$index])
        }
    }
    $result.Add("$Name $Value")
    for ($index = $matchIndex; $index -lt $Lines.Count; $index++) {
        $result.Add($Lines[$index])
    }
    return $result.ToArray()
}

function Get-FirewallState {
    param([Parameter(Mandatory = $true)][string]$Name)

    $rule = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $rule) {
        return [ordered]@{ Exists = $false; Enabled = $null }
    }
    return [ordered]@{ Exists = $true; Enabled = [string]$rule.Enabled }
}

function Get-AcStandbySeconds {
    $output = (& powercfg.exe /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE) -join [Environment]::NewLine
    $hexValues = [regex]::Matches($output, '0x[0-9a-fA-F]+')
    if ($hexValues.Count -lt 2) {
        return $null
    }
    return [Convert]::ToInt32($hexValues[$hexValues.Count - 2].Value.Substring(2), 16)
}

function Ensure-TailscaleFirewall {
    $defaultRule = Get-NetFirewallRule -Name $defaultFirewallRule -ErrorAction SilentlyContinue
    if ($null -ne $defaultRule) {
        Disable-NetFirewallRule -Name $defaultFirewallRule | Out-Null
    }

    $rule = Get-NetFirewallRule -Name $meshFirewallRule -ErrorAction SilentlyContinue
    if ($null -eq $rule) {
        New-NetFirewallRule `
            -Name $meshFirewallRule `
            -DisplayName 'Workstation SSH Mesh - Tailscale only' `
            -Enabled True `
            -Direction Inbound `
            -Action Allow `
            -Profile Any `
            -Protocol TCP `
            -LocalPort 22 `
            -RemoteAddress '100.64.0.0/10' | Out-Null
    } else {
        Set-NetFirewallRule -Name $meshFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Any | Out-Null
        $rule | Get-NetFirewallPortFilter | Set-NetFirewallPortFilter -Protocol TCP -LocalPort 22 | Out-Null
        $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress '100.64.0.0/10' | Out-Null
    }
}

if ($null -eq (Get-Command ssh.exe -ErrorAction SilentlyContinue) -or
    $null -eq (Get-Command ssh-keygen.exe -ErrorAction SilentlyContinue) -or
    $null -eq (Get-Command ssh-add.exe -ErrorAction SilentlyContinue)) {
    throw '未找到完整的 Windows OpenSSH Client（ssh、ssh-keygen、ssh-add）。'
}

$accountInfo = Resolve-Account -Name $TargetUser
$currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

if ([string]::IsNullOrWhiteSpace($KeyPath)) {
    $sshDirectory = Join-Path $accountInfo.ProfilePath '.ssh'
    if ($Alias -eq 'laptop') {
        $KeyPath = Join-Path $sshDirectory 'id_ed25519_gpu_remote'
    } else {
        $safeAlias = $Alias.Replace('-', '_')
        $KeyPath = Join-Path $sshDirectory "id_ed25519_ssh_mesh_$safeAlias"
    }
} else {
    $KeyPath = [Environment]::ExpandEnvironmentVariables($KeyPath)
    $KeyPath = [System.IO.Path]::GetFullPath($KeyPath)
}

$expectedSshRoot = [System.IO.Path]::GetFullPath((Join-Path $accountInfo.ProfilePath '.ssh'))
$resolvedKeyPath = [System.IO.Path]::GetFullPath($KeyPath)
if (-not $resolvedKeyPath.StartsWith($expectedSshRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "KeyPath 必须位于目标账户的 .ssh 目录内：$expectedSshRoot"
}
$KeyPath = $resolvedKeyPath

$tailscaleCli = Resolve-TailscaleCli
if ($null -eq $tailscaleCli) {
    throw '未检测到 Tailscale。请先安装、登录同一个 tailnet，并确认 Connected。'
}
$tailscaleStatus = & $tailscaleCli status --json | ConvertFrom-Json
if ($tailscaleStatus.BackendState -ne 'Running') {
    throw "Tailscale 尚未在线，当前状态：$($tailscaleStatus.BackendState)"
}
$tailscaleIpv4 = ((& $tailscaleCli ip -4 | Select-Object -First 1) -as [string]).Trim()
if ($tailscaleIpv4 -notmatch '^100\.(?:6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]{1,3}\.[0-9]{1,3}$') {
    throw "没有获得有效的 Tailscale IPv4：$tailscaleIpv4"
}

Write-Host '预检结果：' -ForegroundColor Cyan
Write-Host "  Alias:             $Alias"
Write-Host "  Windows account:   $($accountInfo.Name)"
Write-Host "  Profile:           $($accountInfo.ProfilePath)"
Write-Host "  Local admin:       $($accountInfo.IsAdministrator)"
Write-Host "  Key path:          $KeyPath"
Write-Host "  Tailscale IPv4:    $tailscaleIpv4"
Write-Host "  Same UAC identity: $($currentSid -eq $accountInfo.Sid)"

if ($PreflightOnly) {
    Write-Host '只读预检完成，未修改系统。' -ForegroundColor Green
    return
}

if (-not (Test-IsAdministrator)) {
    throw '正式初始化必须在“以管理员身份运行”的 PowerShell 中执行。'
}
if ($currentSid -ne $accountInfo.Sid) {
    throw '当前管理员身份不是 TargetUser。请使用目标日常账户自身的 UAC 提权窗口运行，避免私钥归属错误。'
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backupDirectory = Join-Path $stateRoot "backup-$timestamp"
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

$defaultShellProperty = Get-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -ErrorAction SilentlyContinue
$manifest = [ordered]@{
    SchemaVersion = 1
    Phase = 'Initialize'
    Alias = $Alias
    CreatedAt = (Get-Date).ToString('o')
    SshdConfig = [ordered]@{ Path = (Join-Path $env:ProgramData 'ssh\sshd_config'); Existed = $false; BackupFile = 'sshd_config.before' }
    DefaultShell = [ordered]@{
        Existed = ($null -ne $defaultShellProperty)
        Value = $(if ($null -ne $defaultShellProperty) { $defaultShellProperty.DefaultShell } else { $null })
    }
    DefaultFirewall = Get-FirewallState -Name $defaultFirewallRule
    MeshFirewall = Get-FirewallState -Name $meshFirewallRule
    AcStandbySeconds = Get-AcStandbySeconds
}

$sshDirectory = Split-Path -Parent $KeyPath
if (-not (Test-Path -LiteralPath $sshDirectory)) {
    New-Item -ItemType Directory -Path $sshDirectory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $KeyPath)) {
    Write-Host '正在创建独立 Ed25519 密钥；请设置只在本机输入的私钥口令。' -ForegroundColor Cyan
    & ssh-keygen.exe -t ed25519 -a 100 -f $KeyPath -C "ssh-mesh-$Alias-$env:COMPUTERNAME"
    if ($LASTEXITCODE -ne 0) {
        throw "ssh-keygen 失败，退出码：$LASTEXITCODE"
    }
} else {
    Write-Host "复用现有私钥：$KeyPath" -ForegroundColor Green
}

$publicKeyPath = "$KeyPath.pub"
if (-not (Test-Path -LiteralPath $publicKeyPath)) {
    throw "私钥存在但缺少公钥文件：$publicKeyPath。为避免破坏现有密钥，脚本已停止。"
}

$agent = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($null -eq $agent) {
    throw '未找到 Windows ssh-agent 服务。'
}
Set-Service -Name ssh-agent -StartupType Automatic
if ((Get-Service -Name ssh-agent).Status -ne 'Running') {
    Start-Service -Name ssh-agent
}
& ssh-add.exe $KeyPath
if ($LASTEXITCODE -ne 0) {
    throw "ssh-add 失败，退出码：$LASTEXITCODE。密钥已保留，可重新输入正确口令后继续。"
}

$serverCapability = Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
if ($serverCapability.State -ne 'Installed') {
    $installResult = Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
    if ($installResult.RestartNeeded) {
        Write-Warning 'OpenSSH Server 安装报告需要重启；配置完成后必须重启并复测。'
    }
}

Ensure-TailscaleFirewall
Set-Service -Name sshd -StartupType Automatic
if ((Get-Service -Name sshd).Status -ne 'Running') {
    Start-Service -Name sshd
}

$sshdConfigPath = $manifest.SshdConfig.Path
if (-not (Test-Path -LiteralPath $sshdConfigPath)) {
    throw "OpenSSH Server 已启动，但未找到 sshd_config：$sshdConfigPath"
}
$manifest.SshdConfig.Existed = $true
Copy-Item -LiteralPath $sshdConfigPath -Destination (Join-Path $backupDirectory $manifest.SshdConfig.BackupFile)

$manifestJson = $manifest | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path (Join-Path $backupDirectory 'manifest.json') -Content $manifestJson

$configLines = [System.IO.File]::ReadAllLines($sshdConfigPath)
$configLines = Set-GlobalSshdDirective -Lines $configLines -Name 'PubkeyAuthentication' -Value 'yes'
Write-Utf8NoBom -Path $sshdConfigPath -Content (($configLines -join [Environment]::NewLine) + [Environment]::NewLine)

$defaultShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath 'HKLM:\SOFTWARE\OpenSSH')) {
    New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name 'DefaultShell' -Value $defaultShell -PropertyType String -Force | Out-Null

$sshdExecutable = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
& $sshdExecutable -t -f $sshdConfigPath
if ($LASTEXITCODE -ne 0) {
    Copy-Item -LiteralPath (Join-Path $backupDirectory $manifest.SshdConfig.BackupFile) -Destination $sshdConfigPath -Force
    throw 'sshd_config 校验失败，已恢复备份且未重启 sshd。'
}

if ($Alias -ne 'laptop') {
    & $tailscaleCli up --unattended=true
    if ($LASTEXITCODE -ne 0) {
        throw "设置 Tailscale Run Unattended 失败，退出码：$LASTEXITCODE"
    }
    & powercfg.exe /change standby-timeout-ac 0
    if ($LASTEXITCODE -ne 0) {
        throw "设置 AC 不自动睡眠失败，退出码：$LASTEXITCODE"
    }
}

Restart-Service -Name sshd

$publicKey = ([System.IO.File]::ReadAllText($publicKeyPath)).Trim()
$publicFingerprintLine = (& ssh-keygen.exe -lf $publicKeyPath -E sha256) -join ' '
$publicFingerprint = [regex]::Match($publicFingerprintLine, 'SHA256:[^\s]+').Value
$hostKeyPath = Join-Path $env:ProgramData 'ssh\ssh_host_ed25519_key.pub'
if (-not (Test-Path -LiteralPath $hostKeyPath)) {
    throw "缺少 OpenSSH Ed25519 host key：$hostKeyPath"
}
$hostFingerprintLine = (& ssh-keygen.exe -lf $hostKeyPath -E sha256) -join ' '
$hostFingerprint = [regex]::Match($hostFingerprintLine, 'SHA256:[^\s]+').Value

$nodeRecord = [ordered]@{
    SchemaVersion = 1
    Alias = $Alias
    Account = $accountInfo.Name
    User = $accountInfo.User
    TailscaleIPv4 = $tailscaleIpv4
    KeyPath = $KeyPath
    PublicKey = $publicKey
    PublicKeyFingerprint = $publicFingerprint
    HostKeyFingerprint = $hostFingerprint
}

if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}
$recordPath = Join-Path $OutputDirectory "node-$Alias.public.json"
$nodeRecordJson = $nodeRecord | ConvertTo-Json -Depth 5
Write-Utf8NoBom -Path $recordPath -Content $nodeRecordJson

Write-Host ''
Write-Host '节点初始化完成。' -ForegroundColor Green
Write-Host "公开节点记录：$recordPath"
Write-Host "配置备份目录：$backupDirectory"
Write-Host "Public key fingerprint: $publicFingerprint"
Write-Host "SSH host key fingerprint: $hostFingerprint"
Write-Host '此 JSON 不含私钥或口令；将三个节点记录汇总到 inventory.local.psd1 后再执行 Apply-SshMesh.ps1。' -ForegroundColor Yellow

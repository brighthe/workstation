[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('laptop', 'gpu-5080', 'gpu-5070ti')]
    [string]$LocalAlias,

    [Parameter(Mandatory = $true)]
    [string]$InventoryPath,

    [switch]$PreflightOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredAliases = @('laptop', 'gpu-5080', 'gpu-5070ti')
$requiredFields = @('Account', 'User', 'TailscaleIPv4', 'KeyPath', 'PublicKey', 'PublicKeyFingerprint', 'HostKeyFingerprint')
$beginMarker = '# BEGIN WORKSTATION SSH MESH'
$endMarker = '# END WORKSTATION SSH MESH'
$meshFirewallRule = 'Workstation-SshMesh-Tailscale-In'
$defaultFirewallRule = 'OpenSSH-Server-In-TCP'
$stateRoot = Join-Path $env:ProgramData 'SshMeshSetup'

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

function Test-TailscaleIpv4 {
    param([Parameter(Mandatory = $true)][string]$Address)

    $parsed = $null
    if (-not [System.Net.IPAddress]::TryParse($Address, [ref]$parsed)) {
        return $false
    }
    if ($parsed.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        return $false
    }
    $bytes = $parsed.GetAddressBytes()
    return ($bytes[0] -eq 100 -and $bytes[1] -ge 64 -and $bytes[1] -le 127)
}

function Resolve-Account {
    param([Parameter(Mandatory = $true)][string]$Name)

    try {
        $account = New-Object System.Security.Principal.NTAccount($Name)
        $sid = $account.Translate([System.Security.Principal.SecurityIdentifier])
        $resolvedName = $sid.Translate([System.Security.Principal.NTAccount]).Value
    } catch {
        throw "无法解析 inventory 中的 Windows 账户：$Name"
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
        throw "找不到账户 $resolvedName 的本地用户配置目录。"
    }

    $administrators = Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction Stop
    $isAdministrator = @($administrators | Where-Object {
        $null -ne $_.SID -and $_.SID.Value -eq $sid.Value
    }).Count -gt 0

    return [PSCustomObject]@{
        Name            = $resolvedName
        Sid             = $sid.Value
        ProfilePath     = $profilePath
        IsAdministrator = $isAdministrator
    }
}

function Get-PublicKeyFingerprint {
    param([Parameter(Mandatory = $true)][string]$PublicKey)

    $tempPath = [System.IO.Path]::GetTempFileName()
    try {
        Write-Utf8NoBom -Path $tempPath -Content ($PublicKey.Trim() + [Environment]::NewLine)
        $line = (& ssh-keygen.exe -lf $tempPath -E sha256) -join ' '
        if ($LASTEXITCODE -ne 0) {
            throw 'ssh-keygen 无法解析公钥。'
        }
        return [regex]::Match($line, 'SHA256:[^\s]+').Value
    } finally {
        Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
    }
}

function Set-ManagedBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$ManagedLines
    )

    $existing = ''
    if (Test-Path -LiteralPath $Path) {
        $existing = [System.IO.File]::ReadAllText($Path)
    }
    $pattern = '(?ms)^' + [regex]::Escape($beginMarker) + '\r?\n.*?^' + [regex]::Escape($endMarker) + '\r?\n?'
    $unmanaged = [regex]::Replace($existing, $pattern, '').TrimEnd()
    $block = @($beginMarker) + $ManagedLines + @($endMarker)
    $blockText = $block -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($unmanaged)) {
        $newContent = $blockText + [Environment]::NewLine
    } else {
        $newContent = $unmanaged + [Environment]::NewLine + [Environment]::NewLine + $blockText + [Environment]::NewLine
    }
    Write-Utf8NoBom -Path $Path -Content $newContent
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

function Invoke-Icacls {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    & icacls.exe @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "icacls 失败，退出码：$LASTEXITCODE；参数：$($Arguments -join ' ')"
    }
}

function Get-FirewallState {
    param([Parameter(Mandatory = $true)][string]$Name)

    $rule = Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $rule) {
        return [ordered]@{ Exists = $false; Enabled = $null }
    }
    return [ordered]@{ Exists = $true; Enabled = [string]$rule.Enabled }
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
            -Enabled True -Direction Inbound -Action Allow -Profile Any `
            -Protocol TCP -LocalPort 22 -RemoteAddress '100.64.0.0/10' | Out-Null
    } else {
        Set-NetFirewallRule -Name $meshFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Any | Out-Null
        $rule | Get-NetFirewallPortFilter | Set-NetFirewallPortFilter -Protocol TCP -LocalPort 22 | Out-Null
        $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress '100.64.0.0/10' | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $InventoryPath)) {
    throw "找不到 inventory：$InventoryPath"
}
$InventoryPath = [System.IO.Path]::GetFullPath($InventoryPath)
$inventory = Import-PowerShellDataFile -LiteralPath $InventoryPath
if ($inventory.SchemaVersion -ne 1 -or $null -eq $inventory.Nodes) {
    throw 'inventory SchemaVersion 必须为 1，并包含 Nodes。'
}

$nodeNames = @($inventory.Nodes.Keys | Sort-Object)
if ($nodeNames.Count -ne 3 -or @($requiredAliases | Where-Object { $_ -notin $nodeNames }).Count -ne 0) {
    throw 'inventory 必须且只能包含 laptop、gpu-5080、gpu-5070ti 三个节点。'
}

foreach ($nodeName in $requiredAliases) {
    $node = $inventory.Nodes[$nodeName]
    foreach ($field in $requiredFields) {
        if (-not $node.ContainsKey($field) -or [string]::IsNullOrWhiteSpace([string]$node[$field])) {
            throw "inventory 节点 $nodeName 缺少字段：$field"
        }
    }
    if (-not (Test-TailscaleIpv4 -Address ([string]$node.TailscaleIPv4))) {
        throw "节点 $nodeName 的 TailscaleIPv4 无效：$($node.TailscaleIPv4)"
    }
    if ([string]$node.PublicKey -notmatch '^ssh-ed25519\s+[A-Za-z0-9+/]+={0,3}(?:\s+.*)?$') {
        throw "节点 $nodeName 的 PublicKey 不是有效的 Ed25519 公钥。"
    }
    $actualFingerprint = Get-PublicKeyFingerprint -PublicKey ([string]$node.PublicKey)
    if ($actualFingerprint -ne [string]$node.PublicKeyFingerprint) {
        throw "节点 $nodeName 的 PublicKeyFingerprint 与 PublicKey 不匹配。"
    }
    if ([string]$node.HostKeyFingerprint -notmatch '^SHA256:[A-Za-z0-9+/]+={0,2}$') {
        throw "节点 $nodeName 的 HostKeyFingerprint 格式无效。"
    }
}

$localNode = $inventory.Nodes[$LocalAlias]
$accountInfo = Resolve-Account -Name ([string]$localNode.Account)
$currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$localKeyPath = [System.IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables([string]$localNode.KeyPath))
$expectedSshRoot = [System.IO.Path]::GetFullPath((Join-Path $accountInfo.ProfilePath '.ssh'))
if (-not $localKeyPath.StartsWith($expectedSshRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "本节点 KeyPath 不在目标账户的 .ssh 目录：$localKeyPath"
}
if (-not (Test-Path -LiteralPath $localKeyPath) -or -not (Test-Path -LiteralPath "$localKeyPath.pub")) {
    throw "本节点缺少私钥或公钥文件：$localKeyPath"
}
$localPublicKey = ([System.IO.File]::ReadAllText("$localKeyPath.pub")).Trim()
if ($localPublicKey -ne ([string]$localNode.PublicKey).Trim()) {
    throw 'inventory 中的本节点 PublicKey 与本机 .pub 文件不一致。'
}

$tailscaleCli = Resolve-TailscaleCli
if ($null -eq $tailscaleCli) {
    throw '未检测到 Tailscale。'
}
$tailscaleStatus = & $tailscaleCli status --json | ConvertFrom-Json
if ($tailscaleStatus.BackendState -ne 'Running') {
    throw "Tailscale 尚未在线，当前状态：$($tailscaleStatus.BackendState)"
}
$localTailscaleIp = ((& $tailscaleCli ip -4 | Select-Object -First 1) -as [string]).Trim()
if ($localTailscaleIp -ne [string]$localNode.TailscaleIPv4) {
    throw "inventory 的本节点 IP 与当前 Tailscale IP 不一致：inventory=$($localNode.TailscaleIPv4)，current=$localTailscaleIp"
}

$sshdService = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($null -eq $sshdService -or $sshdService.Status -ne 'Running') {
    throw '本机 sshd 尚未运行；请先执行 Initialize-SshMeshNode.ps1。'
}

$peerAliases = @($requiredAliases | Where-Object { $_ -ne $LocalAlias })
$scannedHostKeys = [ordered]@{}
foreach ($peerAlias in $peerAliases) {
    $peer = $inventory.Nodes[$peerAlias]
    $peerIp = [string]$peer.TailscaleIPv4
    $portOpen = Test-NetConnection -ComputerName $peerIp -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue
    if (-not $portOpen) {
        throw "无法连接 $peerAlias ($peerIp) 的 TCP 22；请确认 peer 已初始化、在线且未休眠。"
    }

    $scanOutput = @(& ssh-keyscan.exe -T 5 -t ed25519 $peerIp 2>$null |
        Where-Object { $_ -match '\s+ssh-ed25519\s+' })
    if ($scanOutput.Count -eq 0) {
        throw "ssh-keyscan 未能读取 $peerAlias ($peerIp) 的 Ed25519 host key。"
    }
    $scanLine = [string]$scanOutput[0]
    $scanFingerprint = Get-PublicKeyFingerprint -PublicKey $scanLine
    if ($scanFingerprint -ne [string]$peer.HostKeyFingerprint) {
        throw "peer $peerAlias 的 host-key 指纹不匹配；拒绝写入 known_hosts。"
    }
    $scannedHostKeys[$peerAlias] = $scanLine
    Write-Host "已验证 $peerAlias host key：$scanFingerprint" -ForegroundColor Green
}

Write-Host 'inventory、Tailscale、TCP 22、公钥和 host-key 预检全部通过。' -ForegroundColor Green
if ($PreflightOnly) {
    Write-Host '只读预检完成，未修改系统。' -ForegroundColor Green
    return
}

if (-not (Test-IsAdministrator)) {
    throw '正式应用必须在“以管理员身份运行”的 PowerShell 中执行。'
}
if ($currentSid -ne $accountInfo.Sid) {
    throw '当前管理员身份不是 inventory 中的本节点 Account。请使用目标日常账户自身的 UAC 提权窗口运行。'
}

& ssh-add.exe $localKeyPath
if ($LASTEXITCODE -ne 0) {
    throw "本机私钥未能加入 ssh-agent，退出码：$LASTEXITCODE"
}

$sshdConfigPath = Join-Path $env:ProgramData 'ssh\sshd_config'
if ($accountInfo.IsAdministrator) {
    $authorizedKeysPath = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
    $authorizedDirectory = Split-Path -Parent $authorizedKeysPath
} else {
    $authorizedDirectory = Join-Path $accountInfo.ProfilePath '.ssh'
    $authorizedKeysPath = Join-Path $authorizedDirectory 'authorized_keys'
}
$clientConfigPath = Join-Path $accountInfo.ProfilePath '.ssh\config'
$knownHostsPath = Join-Path $accountInfo.ProfilePath '.ssh\known_hosts'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backupDirectory = Join-Path $stateRoot "backup-$timestamp"
New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

$fileDefinitions = @(
    [ordered]@{ Kind = 'SshdConfig'; Path = $sshdConfigPath; BackupFile = 'sshd_config.before' },
    [ordered]@{ Kind = 'AuthorizedKeys'; Path = $authorizedKeysPath; BackupFile = 'authorized_keys.before' },
    [ordered]@{ Kind = 'ClientConfig'; Path = $clientConfigPath; BackupFile = 'client_config.before' },
    [ordered]@{ Kind = 'KnownHosts'; Path = $knownHostsPath; BackupFile = 'known_hosts.before' }
)
foreach ($definition in $fileDefinitions) {
    $definition.Existed = Test-Path -LiteralPath $definition.Path
    if ($definition.Existed) {
        Copy-Item -LiteralPath $definition.Path -Destination (Join-Path $backupDirectory $definition.BackupFile)
    }
}
$manifest = [ordered]@{
    SchemaVersion = 1
    Phase = 'Apply'
    Alias = $LocalAlias
    CreatedAt = (Get-Date).ToString('o')
    Files = $fileDefinitions
    DefaultFirewall = Get-FirewallState -Name $defaultFirewallRule
    MeshFirewall = Get-FirewallState -Name $meshFirewallRule
}
$manifestJson = $manifest | ConvertTo-Json -Depth 10
Write-Utf8NoBom -Path (Join-Path $backupDirectory 'manifest.json') -Content $manifestJson

if (-not (Test-Path -LiteralPath $authorizedDirectory)) {
    New-Item -ItemType Directory -Path $authorizedDirectory -Force | Out-Null
}

$peerPublicKeys = @($peerAliases | ForEach-Object { [string]$inventory.Nodes[$_].PublicKey })
Set-ManagedBlock -Path $authorizedKeysPath -ManagedLines $peerPublicKeys
if ($accountInfo.IsAdministrator) {
    Invoke-Icacls -Arguments @($authorizedKeysPath, '/inheritance:r')
    Invoke-Icacls -Arguments @($authorizedKeysPath, '/grant:r', '*S-1-5-32-544:F', '*S-1-5-18:F')
} else {
    Invoke-Icacls -Arguments @($authorizedDirectory, '/inheritance:r')
    Invoke-Icacls -Arguments @($authorizedDirectory, '/grant:r', "*$($accountInfo.Sid)`:(OI)(CI)F", '*S-1-5-18:(OI)(CI)F')
    Invoke-Icacls -Arguments @($authorizedKeysPath, '/inheritance:r')
    Invoke-Icacls -Arguments @($authorizedKeysPath, '/grant:r', "*$($accountInfo.Sid)`:F", '*S-1-5-18:F')
}

$identityPath = $localKeyPath.Replace('\', '/')
$clientLines = New-Object System.Collections.Generic.List[string]
foreach ($peerAlias in $peerAliases) {
    $peer = $inventory.Nodes[$peerAlias]
    if ($clientLines.Count -gt 0) {
        $clientLines.Add('')
    }
    $clientLines.Add("Host $peerAlias")
    $clientLines.Add("    HostName $($peer.TailscaleIPv4)")
    $clientLines.Add("    User $($peer.User)")
    $clientLines.Add("    IdentityFile `"$identityPath`"")
    $clientLines.Add('    IdentitiesOnly yes')
    $clientLines.Add('    StrictHostKeyChecking yes')
    $clientLines.Add('    UserKnownHostsFile ~/.ssh/known_hosts')
    $clientLines.Add('    ServerAliveInterval 30')
    $clientLines.Add('    ServerAliveCountMax 3')
}
Set-ManagedBlock -Path $clientConfigPath -ManagedLines $clientLines.ToArray()

$knownHostLines = @($peerAliases | ForEach-Object { [string]$scannedHostKeys[$_] })
Set-ManagedBlock -Path $knownHostsPath -ManagedLines $knownHostLines

$configLines = [System.IO.File]::ReadAllLines($sshdConfigPath)
$configLines = Set-GlobalSshdDirective -Lines $configLines -Name 'PubkeyAuthentication' -Value 'yes'
$configLines = Set-GlobalSshdDirective -Lines $configLines -Name 'PasswordAuthentication' -Value 'no'
$configLines = Set-GlobalSshdDirective -Lines $configLines -Name 'PermitEmptyPasswords' -Value 'no'
Write-Utf8NoBom -Path $sshdConfigPath -Content (($configLines -join [Environment]::NewLine) + [Environment]::NewLine)

$sshdExecutable = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
& $sshdExecutable -t -f $sshdConfigPath
if ($LASTEXITCODE -ne 0) {
    Copy-Item -LiteralPath (Join-Path $backupDirectory 'sshd_config.before') -Destination $sshdConfigPath -Force
    throw 'sshd_config 校验失败，已恢复服务器配置且未重启 sshd。其他文件备份保留供 Restore 使用。'
}

Ensure-TailscaleFirewall
Restart-Service -Name sshd

Write-Host ''
Write-Host "节点 $LocalAlias 已加入 SSH mesh。" -ForegroundColor Green
Write-Host "备份目录：$backupDirectory"
foreach ($peerAlias in $peerAliases) {
    Write-Host "测试：ssh $peerAlias" -ForegroundColor Cyan
}

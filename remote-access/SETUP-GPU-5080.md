# RTX 5080 SSH 节点初始化交接

本文档供 `gpu-5080` 上的用户或 agent 使用。目标是初始化本机的 Windows OpenSSH 节点并生成本机公开资料；本阶段不部署三节点 inventory，也不执行 `Apply-SshMesh.ps1`。

当前登记信息：

```text
Tailscale machine name: gpu-5080
Tailscale IPv4:         100.84.56.22
Repository:             https://github.com/brighthe/workstation
```

## 执行约束

- 只使用 Windows PowerShell、原生 Windows Git 和 Windows OpenSSH，不使用 WSL、Git Bash、MSYS 或 Cygwin。
- 必须在 5080 的日常 Windows 账户下执行。正式初始化时，管理员 PowerShell 也必须由该账户通过 UAC 打开，不得换用另一个管理员账户。
- 5080 必须生成自己的独立 Ed25519 私钥。不得从笔记本复制私钥，也不得把任何没有 `.pub` 后缀的密钥文件复制到其他设备。
- 私钥口令只能由用户本人在本机交互式终端输入。agent 不得询问、读取、代填、记录或复述口令。
- 不得把私钥、口令、Tailscale auth key、token、`inventory.local.psd1` 或运行状态提交到 Git。
- 任一步骤出现错误或实际信息与本文不符时立即停止，保留完整错误信息并向用户报告，不得绕过验证。

## 1. 检查 Tailscale 和基础工具

在 5080 的 PowerShell 中运行：

```powershell
$tailscale = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
if (-not (Test-Path -LiteralPath $tailscale)) {
    throw '未找到 Tailscale，请先安装并登录与笔记本相同的 tailnet。'
}

Get-Command git.exe, ssh.exe, ssh-keygen.exe, ssh-add.exe -ErrorAction Stop
& $tailscale status
$tailscaleIPv4 = ((& $tailscale ip -4 | Select-Object -First 1) -as [string]).Trim()
$tailscaleIPv4

if ($tailscaleIPv4 -ne '100.84.56.22') {
    throw "Tailscale IPv4 与登记值不一致：$tailscaleIPv4。请先核对 Machines 管理页中的 gpu-5080。"
}
```

确认 `tailscale status` 中本机在线，并且 Machines 管理页中的名称为 `gpu-5080`。这里的名称是 Tailscale machine name，不要求 Windows 的 `COMPUTERNAME` 与它相同。

## 2. 获取最新仓库

仓库标准路径为 `C:\workspace\workstation`。在普通 PowerShell 或管理员 PowerShell 中运行：

```powershell
$repoPath = 'C:\workspace\workstation'
$repoParent = Split-Path -Parent $repoPath

if (Test-Path -LiteralPath (Join-Path $repoPath '.git')) {
    Set-Location $repoPath
    $pending = @(git status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        throw '无法读取现有 workstation 仓库状态。'
    }
    if ($pending.Count -gt 0) {
        throw '现有 workstation 仓库包含未提交改动。为避免覆盖用户工作，已停止；请先人工处理。'
    }
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'git pull --ff-only 失败，请保留错误信息并停止。'
    }
} elseif (Test-Path -LiteralPath $repoPath) {
    throw 'C:\workspace\workstation 已存在但不是 Git 仓库。不要覆盖，请先人工检查。'
} else {
    New-Item -ItemType Directory -Path $repoParent -Force | Out-Null
    git clone https://github.com/brighthe/workstation.git $repoPath
    if ($LASTEXITCODE -ne 0) {
        throw 'git clone 失败，请保留错误信息并停止。'
    }
    Set-Location $repoPath
}

$commit = git rev-parse HEAD
Write-Host "workstation commit: $commit"
Set-Location (Join-Path $repoPath 'remote-access')
```

必须确认以下脚本存在：

```powershell
Get-Item .\Initialize-SshMeshNode.ps1 -ErrorAction Stop
```

## 3. 使用正确账户打开管理员 PowerShell

如果当前窗口不是由 5080 日常账户通过 UAC 打开的管理员 PowerShell，请暂停并让用户完成以下操作：

1. 登录日常使用的 Windows 账户。
2. 从开始菜单搜索 `Windows PowerShell`。
3. 选择“以管理员身份运行”，接受 UAC 提示。
4. 回到仓库目录：

```powershell
Set-Location C:\workspace\workstation\remote-access
$account = whoami
$account
```

后续的预检和正式初始化必须在同一个管理员窗口中执行。不要手写或猜测 `$account`。

## 4. 运行只读预检

```powershell
$account = whoami
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\Initialize-SshMeshNode.ps1 `
  -Alias gpu-5080 `
  -TargetUser $account `
  -PreflightOnly
```

只有同时满足以下条件才可以继续：

- `Alias` 为 `gpu-5080`。
- `Tailscale IPv4` 为 `100.84.56.22`。
- `Local admin` 为 `True`。
- `Same UAC identity` 为 `True`。
- `Key path` 位于当前日常账户的 `~\.ssh` 下。
- 最后一行显示“只读预检完成，未修改系统”。

任何一项不满足都必须停止，不得运行正式初始化命令。

## 5. 正式初始化 5080

仍在同一个管理员 PowerShell 窗口中运行：

```powershell
$account = whoami
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\Initialize-SshMeshNode.ps1 `
  -Alias gpu-5080 `
  -TargetUser $account
```

首次生成密钥时会出现交互提示：

```text
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

随后 `ssh-add` 可能再次要求输入同一口令。这些提示必须交给用户本人在本机键盘输入；输入过程中终端不显示字符属于正常现象。应为 5080 使用独立且非空的口令。

脚本会执行以下系统修改：

- 创建或复用 5080 自己的 Ed25519 密钥。
- 启用并启动 `ssh-agent` 和 `sshd`。
- 安装缺失的 Windows OpenSSH Server。
- 只允许 Tailscale 地址范围 `100.64.0.0/10` 访问 TCP 22。
- 把 Windows PowerShell 设置为 SSH 默认 shell。
- 开启 Tailscale `Run Unattended`。
- 设置台式机接通电源时不自动睡眠。
- 在修改前创建 `C:\ProgramData\SshMeshSetup\backup-<时间戳>` 备份。
- 输出 `state\node-gpu-5080.public.json`，其中不包含私钥或口令。

## 6. 完成后验证

正式初始化成功后运行：

```powershell
$sshdConfig = Join-Path $env:ProgramData 'ssh\sshd_config'
$sshd = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
$tailscale = Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'
$recordPath = 'C:\workspace\workstation\remote-access\state\node-gpu-5080.public.json'

Get-Service sshd, ssh-agent | Select-Object Name, Status, StartType
Test-NetConnection -ComputerName 127.0.0.1 -Port 22
Get-NetFirewallRule -Name 'Workstation-SshMesh-Tailscale-In' |
    Select-Object Name, Enabled, Direction, Action
Get-NetFirewallRule -Name 'Workstation-SshMesh-Tailscale-In' |
    Get-NetFirewallAddressFilter |
    Select-Object RemoteAddress
Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue |
    Select-Object Name, Enabled

& $sshd -t -f $sshdConfig
if ($LASTEXITCODE -ne 0) {
    throw 'sshd_config 验证失败。'
}

& $tailscale status
& $tailscale ip -4
powercfg.exe /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE
nvidia-smi

$record = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
$record | Format-List Alias, Account, User, TailscaleIPv4, KeyPath, PublicKeyFingerprint, HostKeyFingerprint
```

验收结果必须满足：

- `sshd`、`ssh-agent` 均为 `Running`，启动类型为自动。
- 本机 TCP 22 测试成功。
- `Workstation-SshMesh-Tailscale-In` 已启用且远端地址为 `100.64.0.0/10`。
- 默认的 `OpenSSH-Server-In-TCP` 不存在或处于禁用状态。
- `sshd -t` 成功，Tailscale 仍在线且 IPv4 未变化。
- `nvidia-smi` 能识别 RTX 5080。
- 节点记录的 `Alias` 为 `gpu-5080`，且公钥、host key 指纹均非空。

## 7. 返回结果并停止

向用户返回以下内容：

- `whoami` 的结果。
- 当前 workstation commit hash。
- `node-gpu-5080.public.json` 的完整路径和内容。
- 配置备份目录。
- 公钥指纹和 SSH host-key 指纹。
- 上述验证项目的通过/失败摘要。

不得返回私钥内容或私钥口令。不要把 `state\node-gpu-5080.public.json` 加入 Git。

完成后停止，不执行 `Apply-SshMesh.ps1`。必须等到 `laptop`、`gpu-5080`、`gpu-5070ti` 三份公开节点记录全部收集完成并生成本地 `inventory.local.psd1` 后，才能进入全互联配置阶段。

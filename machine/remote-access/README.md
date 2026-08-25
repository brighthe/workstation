# Windows SSH 全互联

本模块用于让三台 Windows 设备通过 Tailscale + Windows OpenSSH 两两互联：

```text
laptop <-> gpu-5080
laptop <-> gpu-5070ti
gpu-5080 <-> gpu-5070ti
```

每台设备同时是 SSH Client 和 SSH Server，并使用自己的 Ed25519 私钥。私钥只保存在生成它的设备上，不复制、不上传、不进入 Git。

## 文件

| 文件 | 作用 |
| --- | --- |
| [`SETUP-GPU-5080.md`](SETUP-GPU-5080.md) | 可交给 5080 上的用户或 agent 独立执行的节点初始化文档 |
| `Initialize-SshMeshNode.ps1` | 生成或复用本机密钥，配置 OpenSSH Server，输出本节点公开资料 |
| `Apply-SshMesh.ps1` | 读取三节点 inventory，部署 peer 公钥、SSH aliases 和 host keys |
| `Restore-SshMeshNode.ps1` | 从脚本创建的备份恢复 SSH、Firewall 和电源设置，不删除私钥 |
| `inventory.example.psd1` | 可提交的占位模板；复制出的 `inventory.local.psd1` 被 Git 忽略 |

固定 aliases：

- `laptop`
- `gpu-5080`
- `gpu-5070ti`

当前笔记本交互密钥：

```text
Path:        C:\Users\Lenovo\.ssh\id_ed25519_gpu_remote
Fingerprint: SHA256:5VIrtKUU+Nkzl68aiGgaHxZ1a14eDX5l3Ca+MIrKADY
```

这里仅记录路径和公钥指纹，不记录私钥正文或口令。

## 0. 准备 Tailscale

1. 在三台机器安装 [Tailscale for Windows](https://tailscale.com/download/windows)。
2. 三台机器登录同一个 Tailscale 账号并显示 `Connected`。
3. 不要在路由器上开放或转发 TCP 22。
4. 将本目录复制到三台机器。实际 inventory 只含公开资料，但仍不提交到公开仓库。

PowerShell 如果阻止脚本，只在当前窗口临时放行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

## 1. 初始化三个节点

所有初始化命令都在该设备自己的日常 Windows 账户下，通过 UAC 打开的管理员 PowerShell 中执行。不要使用另一个管理员账户代跑，否则密钥会进入错误的用户配置目录。

先在每台设备运行只读预检：

```powershell
$account = whoami
.\Initialize-SshMeshNode.ps1 -Alias laptop -TargetUser $account -PreflightOnly
```

### 笔记本

复用已经生成的密钥，不修改睡眠或合盖策略：

```powershell
$account = whoami
.\Initialize-SshMeshNode.ps1 `
  -Alias laptop `
  -TargetUser $account `
  -KeyPath C:\Users\Lenovo\.ssh\id_ed25519_gpu_remote
```

### RTX 5080 台式机

```powershell
$account = whoami
.\Initialize-SshMeshNode.ps1 -Alias gpu-5080 -TargetUser $account
```

### RTX 5070 Ti 台式机

```powershell
$account = whoami
.\Initialize-SshMeshNode.ps1 -Alias gpu-5070ti -TargetUser $account
```

两台台式机会分别创建带口令的独立私钥，设置接通电源时不自动睡眠，并启用 Tailscale `Run Unattended`。三个节点都会把公开资料写入：

```text
remote-access\state\node-<alias>.public.json
```

`state/` 已被 Git 忽略。公钥和指纹可以复制；任何没有 `.pub` 后缀的私钥都不能复制。

## 2. 创建本地 inventory

把三个 `node-*.public.json` 收集到笔记本，复制模板：

```powershell
Copy-Item .\inventory.example.psd1 .\inventory.local.psd1
notepad.exe .\inventory.local.psd1
```

用三个 JSON 文件中的值替换模板占位值。必须正好包含 `laptop`、`gpu-5080`、`gpu-5070ti`，并保持每台机器自己的 `KeyPath`。

将完成后的 `inventory.local.psd1` 复制到另外两台机器的 `remote-access` 目录。该文件不包含私钥，但包含设备标识和网络资料，因此不提交。

## 3. 应用全互联配置

三台设备保持在线。先在每台机器执行只读预检：

```powershell
.\Apply-SshMesh.ps1 `
  -LocalAlias laptop `
  -InventoryPath .\inventory.local.psd1 `
  -PreflightOnly
```

将 `LocalAlias` 替换成当前机器的 alias。预检会验证 inventory、公钥、Tailscale IP、TCP 22 和 OpenSSH host-key 指纹；任何一项不匹配都会停止。

预检通过后，在各自的管理员 PowerShell 中正式应用：

```powershell
.\Apply-SshMesh.ps1 -LocalAlias laptop -InventoryPath .\inventory.local.psd1
.\Apply-SshMesh.ps1 -LocalAlias gpu-5080 -InventoryPath .\inventory.local.psd1
.\Apply-SshMesh.ps1 -LocalAlias gpu-5070ti -InventoryPath .\inventory.local.psd1
```

每条命令只在对应 alias 的机器执行。应用脚本会：

- 把另外两台机器的公钥写入本机 `authorized_keys` 的托管区块。
- 在本机 `~\.ssh\config` 中添加另外两个 aliases，跳过自己。
- 预置并严格核对 `known_hosts`，不使用 `StrictHostKeyChecking accept-new`。
- 在上述验证成功后关闭 SSH 密码认证。
- 禁用 OpenSSH 的宽范围默认防火墙规则，只允许 `100.64.0.0/10` 访问 TCP 22。

## 4. 验证六个方向

在三台机器分别运行另外两个 alias，例如：

```powershell
# laptop
ssh gpu-5080
ssh gpu-5070ti

# gpu-5080
ssh laptop
ssh gpu-5070ti

# gpu-5070ti
ssh laptop
ssh gpu-5080
```

每个远程会话运行：

```powershell
hostname
whoami
```

连接 GPU 台式机时再运行：

```powershell
nvidia-smi
```

密码认证必须失败：

```powershell
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password <peer-alias>
```

最后重启两台台式机，在没有登录 Windows 桌面的情况下复测。笔记本维持原电源策略，睡眠时不可连接，唤醒后应恢复。

在 Tailscale Machines 管理页对两台台式机选择 `Disable key expiry`；笔记本保留正常过期策略。

## 5. 恢复

脚本备份位于：

```text
C:\ProgramData\SshMeshSetup\backup-<时间戳>
```

恢复前保持本地控制台可用，在管理员 PowerShell 执行：

```powershell
.\Restore-SshMeshNode.ps1 `
  -BackupDirectory C:\ProgramData\SshMeshSetup\backup-<时间戳>
```

恢复脚本会先备份恢复前的当前状态，然后还原记录中的 SSH 文件、DefaultShell、Firewall 和 AC 睡眠值。它不会删除或显示任何私钥。

## 安全边界

- 仓库中不允许出现私钥、私钥口令、Tailscale auth key、API token、真实 `inventory.local.psd1` 或运行备份。
- `id_ed25519*.pub` 虽然是公钥，也不作为常规仓库资产；inventory 只在本地流转。
- 管理员账户按 Windows OpenSSH 规则使用 `C:\ProgramData\ssh\administrators_authorized_keys`；普通账户使用自己的 `~\.ssh\authorized_keys`。
- 若设备丢失，立即从另外两台机器的托管公钥区块移除它，并从 Tailscale Machines 撤销该设备。

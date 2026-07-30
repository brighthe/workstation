# wsl —— WSL2 + Ubuntu 开发环境

在 Windows 机器上装 WSL2 与 Ubuntu 发行版的流程、本机偏离点与排错。**各项目在 WSL 里的构建配置不在本文件**，见对应项目仓库。

> ⚠️ **PC-20260706DAHN 的 Windows 映像缺组件，官方标准流程在这台机器上必然失败**（`wsl --install <Distro>` 报 `0x800f080c`）。先读 §2 再动手，否则会卡在一条永远不会成功的命令上。

## §1 标准流程（映像完整的机器）

管理员 PowerShell：

```powershell
wsl --install --no-distribution
```

`--no-distribution` 只装 WSL 本体，不自动塞默认发行版——把发行版版本留给自己决定。重启后：

```powershell
wsl --list --online
wsl --install -d Ubuntu-24.04
```

首次启动会要求创建 UNIX 用户名和密码。**这一步必须由人自己敲，agent 不代填、不记录密码。**

## §2 关键偏离：映像可能缺 `VirtualMachinePlatform`

### 2.1 症状

| 命令 | 现象 |
| --- | --- |
| `wsl --install --web-download` | `已禁止(403)` |
| `dism /online /enable-feature /featurename:VirtualMachinePlatform` | `0x800f080c 功能名称未知` |
| `wsl --install -d <Distro>`（即使提权） | `WSL_E_INSTALL_COMPONENT_FAILED` |
| `wsl --status` | `WSL2 无法启动，因为此计算机上未启用虚拟化` |

`0x800f080c` 是**「功能名不存在」**，不是「未启用」——说明该组件包被从映像中删除了，不是配置问题。裁过的 OEM / 精简版 Windows 会这样。

### 2.2 诊断（提权，只读）

```powershell
Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -match 'Virtual|Hyper|Linux' } |
    Select-Object FeatureName, State
```

判读要点：

- 列表里**没有** `VirtualMachinePlatform` → 组件被删，走 §2.3；
- Hyper-V 各项显示 `Disabled`（而非 `DisabledWithPayloadRemoved`）→ **组件包还在本地库，可离线启用，不需要安装源**；
- 非提权会话查询会报「请求的操作需要提升」，不是功能不存在，别误判。

### 2.3 解法：用 Hyper-V 顶替

WSL2 真正需要的是 hypervisor 加**主机计算服务 `vmcompute`**；`VirtualMachinePlatform` 只是这套东西的轻量打包版。Hyper-V 提供同样的组件：

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

两条都从本地组件库取，**不联网**。返回 `3010` 表示成功且需重启。

验证（`vmcompute` 出现即成功）：

```powershell
Get-Service vmcompute, vmms, hvhost | Select-Object Name, Status
```

### 2.4 遗留影响：`wsl --install <Distro>` 永久不可用

`wsl --install` 的前置检查**写死了 `VirtualMachinePlatform` 这个功能名**，功能不存在就直接退出，不管 WSL2 实际上已经能跑。这条命令在这类机器上装不了发行版，必须改走 §3.2。

## §3 安装步骤（缺组件的机器）

### 3.1 装 WSL 本体

`wsl --install --web-download` 的内置下载器可能 403（与代理无关，目标端点实测可达）。两条替代都可用：

- **System32 存根的交互提示**：直接运行 `wsl.exe`，它会提示「按任意键安装」，走 Store / Windows Update 通道，**实测成功**；
- **winget**（同一个包，带哈希校验）：

  ```powershell
  winget install --id Microsoft.WSL --exact --source winget
  ```

装完 `wsl --version` 应报出版本号而非「未安装」。

### 3.2 装发行版（绕开 `wsl --install`）

用发行版自己的应用包，不经过那个前置检查：

```powershell
winget install --id Canonical.Ubuntu.2404 --exact --source winget
ubuntu2404.exe install --root
```

- `--accept-package-agreements --accept-source-agreements` 可让 winget 非交互，但那等于代人接受许可，**agent 加这两个 flag 前须先问**。
- `ubuntu2404.exe install --root` 是**非交互**安装：只建 root、不问密码，适合在捕获式会话里跑；用户账号留到 §5 单独建。
- 另一条等效路子是 `wsl --import <名字> <目录> <rootfs.tar.gz> --version 2`，纯注册路径，确定绕得开，代价是要自己配用户和 `wsl.conf`。

验证：

```powershell
wsl -l -v      # VERSION 列必须是 2
```

## §4 网络与 DNS（缺组件机器必配）

### 4.1 网络模式只能用 VirtioProxy

| 模式 | 结果 |
| --- | --- |
| `nat`（默认） | 建不起来（依赖同样缺失的 HNS 组件），自动回退 VirtioProxy |
| `mirrored` | **同样依赖 `VirtualMachinePlatform`**，设了会回退到 `None`，**完全断网** |
| VirtioProxy（回退默认值） | ✅ 可用，WSL 拿到宿主同网段地址 |

结论：**`.wslconfig` 里不要写 `networkingMode`**，让它落到 VirtioProxy。

`%USERPROFILE%\.wslconfig`：

```ini
[wsl2]
firewall=true
autoProxy=false
```

改动后 `wsl --shutdown` 生效。

### 4.2 DNS 必须手工固定

VirtioProxy 回退时 WSL 拿不到真实 DNS，会把 `/etc/resolv.conf` 写成 `fec0:0:0:ffff::1/2/3`——**无效占位地址，无人应答**，表现为解析全部超时、`apt update` 跑不动。

宿主 DNS 用 `Get-DnsClientServerAddress -AddressFamily IPv4` 查。发行版内（root）：

```bash
printf "[network]\ngenerateResolvConf = false\n" > /etc/wsl.conf
rm -f /etc/resolv.conf
printf "nameserver 223.5.5.5\n" > /etc/resolv.conf
```

`generateResolvConf = false` 是关键，否则每次启动都被覆写回占位地址。

### 4.3 与 Clash 的关系

WSL 启动时会警告「检测到 localhost 代理配置但未镜像到 WSL」。这是实情：**VirtioProxy 下 WSL 里的 `127.0.0.1` 不是宿主的 `127.0.0.1`**，宿主上只监听回环的 Clash 端口在 WSL 里够不着。`autoProxy=false` 就是不去假装它能用。

真要在 WSL 里走 Clash，需要让 Clash 开 `allow-lan` 并在 WSL 内指向宿主的局域网地址——**本机未验证**。公网直连正常时不必折腾。

## §5 创建用户：Ubuntu 24.04 的 `adduser` 死锁

### 5.1 现象

```bash
adduser --disabled-password --gecos "" <用户名>
# warn: Waiting for lock to become available...   ← 无限循环
```

进程树是 `adduser` → `/bin/passwd <用户名>`：**父进程持有用户数据库的锁，却又去调 `passwd`，而 `passwd` 在等同一把锁**。给了 `--disabled-password` 也照样触发。它不是「卡住不动」而是在无限重试，永远不会结束。

### 5.2 处理

用户**其实已经建好了**（`/etc/passwd` 有条目、家目录已建、`passwd -S` 显示 `L` 即密码锁定，正是期望状态）。杀掉死锁进程即可，不会丢东西：

```bash
ps -eo pid,cmd | grep -E "adduser|passwd"
kill -9 <passwd-pid> <adduser-pid>    # passwd 屏蔽 SIGTERM，必须 -9
getent passwd <用户名>                 # 确认还在
```

然后补上剩余步骤：

```bash
usermod -aG sudo <用户名>
echo "<用户名> ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/<用户名>
chmod 0440 /etc/sudoers.d/<用户名>
visudo -c -f /etc/sudoers.d/<用户名>   # 必须 parsed OK
```

设为默认用户，`/etc/wsl.conf`：

```ini
[network]
generateResolvConf = false

[user]
default = <用户名>
```

`wsl --shutdown` 后生效。

### 5.3 关于密码

WSL 里 UNIX 密码**几乎不提供额外安全性**——安全边界是 Windows，任何能开终端的人 `wsl -u root` 直接就是 root。所以免密（`--disabled-password` + NOPASSWD sudo）是合理选择。代价是少了一道「停一秒」的摩擦：以你身份运行的任何脚本都能无声提权。想保留这道摩擦就正常设密码。

Ubuntu 官方镜像自带一个 `ubuntu` 账号（uid 1000，在 sudo 组，cloud-init 已给免密）。**建议留着不动**：删了很可能被 cloud-init 重建，而它在 WSL 里的实际风险约等于零。只要别把代码和密钥误放进 `/home/ubuntu`。

## §6 验证清单

```powershell
wsl -l -v                       # VERSION = 2
Get-Service vmcompute           # Running
```

```bash
whoami                          # 默认用户，不是 root
sudo -n whoami                  # root（免密 sudo 生效）
cat /etc/resolv.conf            # 不是 fec0:0:0:ffff::
getent hosts archive.ubuntu.com # 能解析
sudo apt-get update             # 能拉通
```

## §7 各机器现状

### PC-20260706DAHN（研究院 Windows 工作站）

- **Windows**：11 专业版 24H2，build 26100，UBR 4652。CPU i9-14900KF（大小核混合架构），32 逻辑核，31 GiB 可用内存。
- **映像缺 `VirtualMachinePlatform`**（121 个可选功能里不存在），按 §2.3 用 `Microsoft-Hyper-V-All` 顶替；`vmcompute` / `vmms` / `hvhost` 均已 Running，`CBS RebootPending` 已回落到 `False`。
- **WSL**：2.7.11.0，内核 6.18.33.2。经 System32 存根的交互提示安装（`--web-download` 403）。
- **发行版**：Ubuntu 24.04 LTS (Noble)，经 `winget install Canonical.Ubuntu.2404` + `ubuntu2404.exe install --root` 落地。
- **网络**：VirtioProxy，`eth0` 取得宿主同网段地址；`nat` 与 `mirrored` 均不可用（§4.1）。
- **DNS**：`generateResolvConf=false` + 手写 `223.5.5.5`。实测 `apt update` 38.5 MB / 10 s。
- **用户**：`brighthe`（uid 1002，sudo 组，`/etc/sudoers.d/brighthe` 免密，密码锁定），已设为 `wsl.conf` 默认用户。

## §8 已知限制

- **`wsl --install <Distro>` 在缺组件的机器上永久不可用**，装新发行版一律走 §3.2。
- **`networkingMode=mirrored` 不可用**，因此 WSL **不继承 Windows 侧 VPN 的路由**。需要在 WSL 里访问只有 VPN 能到的内网站点时，这是硬限制——具体可达性按项目场景单独验证。
- 根本修复是用官方 ISO 做保留文件的就地升级，把被删的组件补回来（5~7 GB 下载 + 半小时以上）。**本机未做**。

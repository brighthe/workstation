# wsl —— WSL2 + Ubuntu 开发环境

在 Windows 机器上装 WSL2 与 Ubuntu 发行版的流程、本机偏离点与排错。**各项目在 WSL 里的构建配置不在本文件**，见对应项目仓库。

> ⚠️ **PC-20260706DAHN 的 Windows 映像缺组件，官方标准流程在这台机器上必然失败**（`wsl --install <Distro>` 报 `0x800f080c`）。先读 §2 再动手，否则会卡在一条永远不会成功的命令上。

> 🔒 **脱敏**：本仓库 Public。内网 IP、内网 DNS 地址、SSH 端口一律以 `<占位符>` 表示；实际值只存在于本机配置文件中。

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
Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -match 'Virtual|Hyper|Linux|Container' } |
    Select-Object FeatureName, State
```

判读要点：

- 列表里**没有** `VirtualMachinePlatform` → 组件被删，走 §2.3；
- Hyper-V / Containers 各项显示 `Disabled`（而非 `DisabledWithPayloadRemoved`）→ **组件包还在本地库，可离线启用，不需要安装源**；
- 非提权会话查询会报「请求的操作需要提升」，不是功能不存在，别误判。

### 2.3 解法：Hyper-V + Containers 顶替

要跑起可用的 WSL2，缺的是两样东西，**必须都补**：

| 缺的东西 | 由谁提供 | 不补的后果 |
| --- | --- | --- |
| `vmcompute`（主机计算服务） | `Microsoft-Hyper-V-All` | WSL2 虚拟机根本起不来 |
| `vfpext.sys`（虚拟过滤平台驱动） | `Containers` / `Containers-HNS` / `Containers-SDN` | **虚拟交换机做不了 NAT**，`networkingMode=nat` 建不起来并回退到 VirtioProxy（后果见 §4.1） |

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:Containers /all /norestart
dism.exe /online /enable-feature /featurename:Containers-HNS /all /norestart
dism.exe /online /enable-feature /featurename:Containers-SDN /all /norestart
```

全部从本地组件库取，**不联网**。返回 `3010` 表示成功且需重启。**`vfpext.sys` 要重启后才落地**，重启前查它一定是 MISSING，别据此判定失败。

验证：

```powershell
Get-Service vmcompute, vmms, hns, WinNat | Select-Object Name, Status
Test-Path "$env:SystemRoot\System32\drivers\vfpext.sys"
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

## §4 网络

### 4.1 三种网络模式，只有 nat 能用

| 模式 | 结果 |
| --- | --- |
| `mirrored` | ❌ **依赖 `VirtualMachinePlatform`**，设了会回退到 `None`，**完全断网** |
| VirtioProxy（缺 `vfpext.sys` 时的回退值） | ⚠️ 平时能用，**但连上 VPN 就彻底断网**（见下） |
| `nat` | ✅ **唯一可用**，前提是 §2.3 的 `vfpext.sys` 已就位 |

**VirtioProxy 与 VPN 不能共存**，这是最坑的一条：该模式直接镜像宿主主网卡，WSL 拿到的是**宿主同网段的地址**。一旦连上 L2TP VPN，`eth0` 会跟着变成 VPN 下发的 `/32` 地址、接口进入 DOWN、默认路由消失，**公网内网一起断**；断开 VPN 后会自动恢复。症状看起来像 WSL 坏了，实际是模式选错。

`nat` 模式下 WSL 拿到独立的 `172.x` 私网地址，出站由宿主转发并**走宿主路由表**——宿主连着 VPN 时，内网路由自然可用。

`%USERPROFILE%\.wslconfig`：

```ini
[wsl2]
networkingMode=nat
firewall=true
autoProxy=false
```

改动后 `wsl --shutdown` 生效。

### 4.2 DNS 必须手工固定

VirtioProxy 回退时 WSL 拿不到真实 DNS，会把 `/etc/resolv.conf` 写成 `fec0:0:0:ffff::1/2/3`——**无效占位地址，无人应答**，表现为解析全部超时、`apt update` 跑不动。

宿主 DNS 用 `Get-DnsClientServerAddress -AddressFamily IPv4` 查。发行版内（root）：

```bash
printf "[network]\ngenerateResolvConf = false\n" >> /etc/wsl.conf
rm -f /etc/resolv.conf
printf "nameserver 223.5.5.5\n" > /etc/resolv.conf
```

`generateResolvConf = false` 是关键，否则每次启动都被覆写回占位地址。

### 4.3 内网域名的解析分裂（访问 VPN 内网的**真正**障碍）

企业内网域名常有**两套解析结果**：

| 解析者 | 得到的地址 | 可达性 |
| --- | --- | --- |
| Windows（用 VPN 下发的内网 DNS） | 内网地址 | ✅ 通 |
| WSL（用 §4.2 固定的公网 DNS） | **公网 A 记录** | ❌ 端口全不通 |

结果是 WSL 里 `curl` **快速失败**（一两百毫秒，不是超时），极易被误判成防火墙、NAT 或路由问题。**先确认 WSL 解析到的地址与 Windows 是否一致**，再怀疑别的。

```bash
getent hosts <内网域名>          # 在 WSL 里
```

```powershell
Resolve-DnsName <内网域名> -Type A   # 在 Windows 里，两边对比
```

三种修法：

| 方案 | 效果 | 代价 |
| --- | --- | --- |
| **`/etc/hosts` 写死**（本机采用） | 立刻可用，零风险 | 只覆盖写进去的域名；内网地址变了要手改 |
| `resolv.conf` 内网 DNS 放**第一位** | 覆盖所有内网域名 | VPN 未连时每次解析都要先等内网 DNS 超时，公网访问明显变卡 |
| 开 systemd + `systemd-resolved` 分域名路由 | 最干净，等价于 Windows 的按接口 DNS | 要改 init 方式并重启 WSL，多一层机制 |

**内网 DNS 不能放第二位**：`resolv.conf` 的 fallback 只在前一个服务器超时或拒答时触发，而公网 DNS 对这类域名**会正常返回一个有效答案**（那个不可达的公网地址），永远轮不到第二个。

用 `/etc/hosts` 时**必须同时关掉自动生成**，否则 WSL 会周期性重写该文件、把手工条目抹掉：

```bash
printf "[network]\ngenerateHosts = false\n" >> /etc/wsl.conf   # 与 generateResolvConf 同段
```

### 4.4 否定性结论：不需要开 IP 转发

网上常见的「WSL2 访问 VPN 内网要 `Set-NetIPInterface -Forwarding Enabled`」在本机**不成立**。实测：两个接口转发均为 `Disabled` 且完全重启 WSL 后，内网 HTTP、SSH 全部正常。

记这条是为了省下重复排查：**转发不是解法，DNS 才是**。也不必为「VPN 重连后转发会重置」写任何补偿脚本——本机曾写过一个，验证无效后删除。

### 4.5 与 Clash 的关系

WSL 启动时会警告「检测到 localhost 代理配置但未镜像到 WSL」。这是实情：**nat 模式下 WSL 里的 `127.0.0.1` 不是宿主的 `127.0.0.1`**，宿主上只监听回环的 Clash 端口在 WSL 里够不着。`autoProxy=false` 就是不去假装它能用。

真要在 WSL 里走 Clash，需要让 Clash 开 `allow-lan` 并在 WSL 内指向宿主地址——**本机未验证**。公网直连正常时不必折腾。

**2026-08-04 验证：WSL 里 GitHub SSH 直连可用，不需要 Clash。** `ssh -T git@github.com` 经 `ssh.github.com:443` 直接通过，随后 5 个 remote（含三个 `suanhaitech` 私有仓库）的 `git ls-remote` 与 `git clone` 全部正常。密钥与 Windows 共用（§6），但 **`~/.ssh/config` 里不要照抄 Windows 那段的 `ProxyCommand`**——它指向 `connect.exe`，WSL 里没有这个二进制。

**反过来，Windows 侧必须保留 `ProxyCommand`。** 实测直连 `ssh.github.com:443` 时 `ssh -T` 握手能成功，但 `git push` 的持续大流量长连接会 `Connection timed out`。短连接握手通过不等于长连接可用，两侧走的路径不同，不要据此删掉 Windows 的代理配置。

**Windows 侧经 `connect.exe` 隧道的 git 上传实测约 62 KiB/s**：110 MB 的仓库首次推送需要约 30 分钟，中途被打断则全部重来（git push 是原子的，远端不留残件）。注意这是**上传**方向，与 §4.6 表格里的下载速率不可比——非对称宽带的上行常常只有下行的十分之一。大仓库首推建议放到 WSL 侧走直连，或用 `git format-patch` 只备份自己的提交。

### 4.6 VPN 全隧道会把公网下载拖慢两个数量级

企业 VPN 常下发 `0.0.0.0/0` 默认路由，且其接口度量值优于物理网卡，**连上之后连公网流量也绕经对方网关**。实测同一台机器：

| 状态 | 公网下载速率 |
| --- | --- |
| VPN 连接 | 约 70 KB/s |
| VPN 断开 | **约 5 MB/s** |

约 75 倍差距，**Windows 与 WSL 两侧一致，与操作系统无关**。确认方法：

```powershell
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric |
    Select-Object InterfaceAlias, RouteMetric
Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, InterfaceMetric
```

路由优先级看的是 **RouteMetric + InterfaceMetric 之和**，不是单看其一——VPN 接口的 InterfaceMetric 往往远小于无线网卡，因此即便 RouteMetric 更大也会胜出。

**所以：大批量公网下载（`apt`、`pip`、拉镜像）前先断开 VPN。** 只有访问仅 VPN 可达的内网资源时才需要连着。

**还有一个更隐蔽的坑**：VPN 连接状态改变时，已建立的 TCP 连接会变成半死状态，**`apt` / `pip` 会挂住而不是报错**——表现为进程还在、下载量长时间不增、吞吐 0 KB/s。判断方法是隔几分钟对比两次：

```bash
du -sh /var/cache/apt/archives          # apt 累计下载量
cat /sys/class/net/eth0/statistics/rx_bytes   # 前后相减看真实吞吐
```

量不涨就是挂死了，`pkill` 掉重跑即可——**apt 已下载的 `.deb` 留在缓存里不会重下**，只要中断发生在下载阶段（解包阶段不联网，断网打断不了它），dpkg 状态也不会损坏。

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
generateHosts = false

[user]
default = <用户名>
```

`wsl --shutdown` 后生效。

### 5.3 关于密码

WSL 里 UNIX 密码**几乎不提供额外安全性**——安全边界是 Windows，任何能开终端的人 `wsl -u root` 直接就是 root。所以免密（`--disabled-password` + NOPASSWD sudo）是合理选择。代价是少了一道「停一秒」的摩擦：以你身份运行的任何脚本都能无声提权。想保留这道摩擦就正常设密码。

Ubuntu 官方镜像自带一个 `ubuntu` 账号（uid 1000，在 sudo 组，cloud-init 已给免密）。**建议留着不动**：删了很可能被 cloud-init 重建，而它在 WSL 里的实际风险约等于零。只要别把代码和密钥误放进 `/home/ubuntu`。

## §6 内网 Git 仓库的 SSH

WSL 与 Windows **可以共用同一把密钥**：服务端只认公钥指纹，不区分客户端操作系统。复制密钥和 Host 段即可，不必在服务端再注册一条：

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /mnt/c/Users/<用户>/.ssh/<密钥名> ~/.ssh/
chmod 600 ~/.ssh/<密钥名>
```

`~/.ssh/config` 里照抄 Windows 那段（`HostName` / `Port` / `User` / `IdentityFile` / `IdentitiesOnly yes`），但**不要照抄 Windows 专用的 `ProxyCommand`**（`connect.exe` 之类），WSL 里没有那个二进制。

代价要知道：**一处吊销或到期，两边同废**；轮换密钥要更新两份文件；服务端审计分不出是哪个环境发起的。在同一台机器上这些代价都可接受——WSL 与 Windows 之间本就不是安全边界，`/mnt/c` 让 WSL 直接看得到 Windows 侧的密钥原件。

## §7 验证清单

```powershell
wsl -l -v                       # VERSION = 2
Get-Service vmcompute, hns      # Running
```

```bash
whoami                          # 默认用户，不是 root
sudo -n whoami                  # root（免密 sudo 生效）
ip -4 addr show eth0            # nat 模式应为 172.x 私网地址
cat /etc/resolv.conf            # 不是 fec0:0:0:ffff::
getent hosts archive.ubuntu.com # 能解析
sudo apt-get update             # 能拉通
```

连着 VPN 时另加（与 Windows 侧结果逐项对比）：

```bash
getent hosts <内网域名>          # 必须与 Windows 解析结果一致
curl -sS -o /dev/null -w '%{http_code}\n' http://<内网域名>/
ssh -T git@<内网域名>            # 应回显欢迎信息
```

## §8 在 WSL 里跑 Intel MPI / MKL 程序

用 Intel oneAPI 工具链构建的科学计算程序，搬到 WSL 里跑会撞上两类问题。二者都与程序本身无关，是 WSL 环境特性。

### 8.1 Intel MPI 必须走共享内存

```
Fatal error in PMPI_Init_thread
MPIDI_OFI_mpi_init_hook(1594): (unknown)(): Unknown error class
```

Intel MPI 默认经 **OFI（libfabric）** 通信，而 WSL 里既无 RDMA 网卡也通常不带 libfabric provider（`ldconfig -p | grep libfabric` 为 0 即是），初始化直接失败并 dump core。

```bash
export I_MPI_FABRICS=shm      # 单机场景走共享内存，完全够用
```

**只有这一个值有效**，`FI_PROVIDER=tcp` / `sockets` / `shm` 三种实测均无效——它们仍在 OFI 框架内。

这个报错**指不到真正原因**，不知道就会在网络、防火墙、权限上白查很久，值得单独记一条。

### 8.2 缺失的 MKL 库可从 PyPI 取到精确版本

预编译产物有时会漏带某个 MKL 运行时库（常见于构建机装了 oneAPI、打包时未收全），表现为：

```
error while loading shared libraries: libmkl_xxx.so.2: cannot open shared object file
```

Intel 在 PyPI 上发布 oneMKL 运行时，**版本可精确对齐**，避免混版本的符号风险。先确认产物里现有库的版本：

```bash
strings <产物目录>/lib/libmkl_core.so.2 | grep -oE '20[0-9]{2}\.[0-9]+(\.[0-9]+)?' | sort -u
```

再取同版本的缺失文件：

```bash
pip3 download "mkl==<版本>" --no-deps --only-binary=:all: -d /tmp/mklpkg \
     -i https://pypi.tuna.tsinghua.edu.cn/simple
cd /tmp/mklpkg && unzip -q -o *.whl
find . -name "libmkl_*.so.2"
```

**必须带 `-i` 指国内镜像**：`pypi.org` 的索引能通，但包文件在 `files.pythonhosted.org`，国内直连该 CDN 会**长时间挂住而不报错**（实测下载目录十分钟保持为空、吞吐 0 KB/s）。换清华或阿里云镜像后 180 MB 秒下。

取出的 `.so` **放在产物目录之外**（例如 `~/mkl-extra/`）再加进 `LD_LIBRARY_PATH`，不要塞进仓库目录——否则 `git status` 变脏，且下次拉取会冲突。

### 8.3 用环境脚本固化，不要写进 `.bashrc`

上面两项都是**每次运行都必须生效**的设置。写进 `~/.bashrc` 会污染所有程序（尤其 `LD_LIBRARY_PATH`，可能让无关程序加载错版本的库）。推荐单独一个脚本，用时 `source`：

```bash
# ~/<项目>-env.sh
export LD_LIBRARY_PATH=$HOME/mkl-extra:<产物目录>/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export I_MPI_FABRICS=shm
export PATH=<产物目录>/bin${PATH:+:$PATH}
```

具体项目的脚本内容属于该项目，记在项目仓库；本文件只记这套做法。

### 8.4 SGSim 的 Intel MPI 项目级隔离状态

本机已从 Intel 官方 APT 源安装 Intel MPI 2021.14 runtime 与开发文件。与 SGSim Artifact 字节级匹配的包版本是 `2021.14.1-5`（Build `20241121`），不是当前较新的 `2021.14.2-7`；安装库与 Artifact `libmpi.so.12.0.0` 的 SHA-256、Build ID 已核对一致。runtime/devel 两个包已设置 APT hold，避免普通升级破坏匹配关系。

系统 OpenMPI 继续保留，供其他软件使用。SGSim 通过独立环境脚本和被 Git 忽略的 CMake user preset 固定 Intel MPI 路径；配置 cache 与构建产物均未解析到 OpenMPI。项目 preset、构建目录、测试结果和当前源码主程序的 PETSc 运行阻塞属于项目事实，见 `dut-institute-work:hpc/environment.md`，不在机器级文档重复。

## §9 各机器现状

### PC-20260706DAHN（研究院 Windows 工作站）

- **Windows**：11 专业版 24H2，build 26100，UBR 4652。CPU i9-14900KF（大小核混合架构），32 逻辑核，31 GiB 可用内存。
- **映像缺 `VirtualMachinePlatform`**（121 个可选功能里不存在），按 §2.3 用 `Microsoft-Hyper-V-All` + `Containers` 系列顶替。`vmcompute` / `vmms` / `hns` / `WinNat` 均 Running，`vfpext.sys` 已落地。
- **WSL**：2.7.11.0，内核 6.18.33.2。经 System32 存根的交互提示安装（`--web-download` 403）。
- **发行版**：Ubuntu 24.04 LTS (Noble)，经 `winget install Canonical.Ubuntu.2404` + `ubuntu2404.exe install --root` 落地。
- **网络**：`networkingMode=nat`，`eth0` 为 `172.x` 私网地址。**曾因缺 `vfpext.sys` 只能用 VirtioProxy，连 VPN 即断网**；补齐组件后问题消失。
- **DNS**：`generateResolvConf=false` + 手写公网 DNS；内网域名用 `/etc/hosts` 写死 + `generateHosts=false`。实测 `apt update` 38.5 MB / 10 s。
- **IP 转发**：保持系统默认的 `Disabled`（§4.4 已验证不需要）。
- **用户**：`brighthe`（uid 1002，sudo 组，免密 sudo，密码锁定），已设为默认用户。
- **内网 GitLab**：HTTP 与 SSH **均已在 WSL 中验证通过**，与 Windows 侧结果一致；密钥与 Windows 共用。
- **编译工具链**：gcc/g++ 13.3.0（系统默认）、gcc-11/g++-11 11.5.0、cmake 3.28.3、ninja 1.11.1、make 4.3、pkg-config 1.8.1、pip3 24.0。另按需装了 `libboost-all-dev` 1.83、`libgtest-dev` 1.14，以及 Intel MPI 2021.14 runtime/devel `2021.14.1-5`（与 SGSim Artifact 匹配并 hold）；OpenMPI 保留。
- **公网速率**：断开 VPN 时 `apt` 实测 5~7 MB/s；连着 VPN 约 70 KB/s（§4.6）。
- **GitHub SSH**：直连可用，密钥与 Windows 共用，不经 Clash（§4.5）。
- **代码检出**（2026-08-04 起）：计算类仓库迁入 `~/workspace/`，共 6 个——`SGSim`、`fealpy`（`suanhaitech` 只读镜像，`push` 置为 `DISABLED`）、`fealpy_stable`（个人定制版，`origin` 指向私有的 `brighthe/fealpy-stable`）、`soptx`、`xihe`、`mfleo`。文档类仓库继续留在 Windows 的 `C:\workspace`；两侧的划分依据与解析机制见 `workspace/README.md`。
- **Python 环境**：miniconda 装于 `~/miniconda3`（conda 26.5.3，base 为 Python 3.14.6）。**建环境务必加 `-c conda-forge --override-channels`**，否则 conda 会要求接受 Anaconda `defaults` 频道的商业许可条款。
- **`ihpcm` 环境**：Python 3.12.13，34 个 pip 包全部取到 manylinux wheel（无需编译），版本与迁移前的 Windows 环境逐一对应。`fealpy` 与 `soptx` 走 `pip install -e` 指向 `~/workspace/` 下的检出。MKL 直接求解器（`pypardiso`）与 Intel MPI 2021.18.1（pip 的 `impi-rt`，独立于 §9 里那套系统级 2021.14）均验证通过。
- **gmsh 需要两个系统库**：`libglu1-mesa`、`libxft2`（会连带 `libopengl0`，共约 230 kB）。Ubuntu 最小安装不带，缺失时报 `OSError: libGLU.so.1`。这**不是可选项**——FEALPy 的 `TriangleMesh.from_box` 会经 `mesher/__init__` → `geometry/__init__` 链式导入到一个硬 `import gmsh` 的模块，连纯结构化网格生成都会被拖住。
- **非交互 shell 里 conda 不在 PATH**：`conda init` 写入的初始化块在 `~/.bashrc` 顶部的「非交互直接 return」守卫之后，因此 `wsl.exe -- bash -lc '...'` 这类调用必须写绝对路径 `~/miniconda3/envs/<env>/bin/python`。交互式终端不受影响。

## §10 已知限制

- **`wsl --install <Distro>` 在缺组件的机器上永久不可用**，装新发行版一律走 §3.2。
- **`networkingMode=mirrored` 不可用**（依赖缺失的 `VirtualMachinePlatform`）。所幸 nat 模式已能继承宿主的 VPN 路由，mirrored 并非必需。
- **内网域名靠 `/etc/hosts` 写死**，内网地址变更时需手工更新；需要覆盖更多内网域名时改用 §4.3 的另两种方案。
- 根本修复是用官方 ISO 做保留文件的就地升级，把被删的组件补回来（5~7 GB 下载 + 半小时以上）。**本机未做**。

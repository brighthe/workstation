# network —— 机器级网络与代理

本机的代理机制、TUN、VPN 路由与 WSL 侧代理配置的**唯一正文**。

按 [workspace/responsibilities.md](../workspace/responsibilities.md) 的内容路由，「工具、环境、配置、安装和跨设备迁移」由本仓库维护；业务仓库只保留使用入口与指针。

> **本仓库 Public。** 内网网段、VPN 服务器地址、预共享密钥、内网 DNS、账号凭据一律不写入本文，下文用 `<占位符>` 表示；本机具体参数留在各业务仓库的本地未入库文档中。

## §1 三套代理机制，互不重叠

Windows 上有三套彼此独立的代理机制。**交界处会出现「浏览器好好的，某个程序就是连不上」**——绝大多数代理疑难都出在这里。

| 机制 | 覆盖范围 | 配置位置 |
| --- | --- | --- |
| WinINET 系统代理 | 浏览器、Electron 外壳、多数 GUI 程序 | 系统设置 / 代理软件的「系统代理」开关 |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` 环境变量 | Go、Python、curl、Node 等按环境变量取代理的进程 | 用户级持久环境变量 |
| 虚拟网卡（TUN） | 路由层，全覆盖 | 代理软件的「虚拟网卡模式」（见 §2） |

### 1.1 盲区：GUI 启动 + 只认环境变量的子进程

从开始菜单启动的 GUI 应用，若其核心子进程是只认环境变量的 Go 二进制，则**前两套都够不着**：系统代理它不读，环境变量它也继承不到（用户级没配的话）。

这类程序会安静地直连，表现为「装了代理软件但这一个程序就是不通」。2026-08-21 的 Antigravity 语言服务器正是此例，曾据此误判为「必须开 TUN」。

### 1.2 判定某个二进制是否只认环境变量

```powershell
Select-String -Path '<可执行文件路径>' -Pattern 'HTTPS_PROXY','net/http' -Encoding ascii
```

命中 `net/http` 加 `HTTP_PROXY`/`https_proxy` 即为 Go 的 `http.ProxyFromEnvironment`——**只认环境变量**。

### 1.3 修法：必须在用户级持久化

不能只在当前终端 `set`：

```powershell
[Environment]::SetEnvironmentVariable('HTTP_PROXY','http://127.0.0.1:<代理端口>','User')
[Environment]::SetEnvironmentVariable('HTTPS_PROXY','http://127.0.0.1:<代理端口>','User')
```

`NO_PROXY` 应同时包含内网域名，避免内网请求被误送进代理。

**两个坑**：

- 改完必须**完全退出并重启**目标应用（含托盘图标），环境变量只对新进程生效。
- 代理软件「复制环境变量」之类的功能是**手动、按 shell 生效**的，粘到终端只对那一个终端有效，关掉就没了。同理，某些工具会自行给子进程注入代理变量，在其内部跑命令一切正常，出了该进程即失效——很容易造成「已经配好了」的错觉。

### 1.4 验证

```powershell
Get-NetTCPConnection -OwningProcess <PID> -State Established |
  Select-Object RemoteAddress,RemotePort
```

连接应指向 `127.0.0.1:<代理端口>`；仍是外部地址即未生效。**验证时应关闭 TUN 并断开 VPN**，否则分不清是代理生效还是别的通道在兜底。

## §2 TUN：只作兜底，不应常开

### 2.1 规范

TUN 工作在路由层，接管一切流量。它存在的意义是覆盖**确实无法配置代理的程序**（闭源硬编码直连、纯 UDP、游戏），属于兜底手段，**不是配置手段**。

常开的代价：

- **掩盖真实配置缺失**。流量走向不再由程序自身配置决定，出问题无法从应用侧排查。本机已因此踩坑两次：Antigravity 缺 `HTTP_PROXY` 被掩盖很久；WSL 从未配过代理却一直能上网，直到 TUN 关闭才暴露（见 §4）。
- **与 VPN 抢路由**（见 §2.2），本机场景下内网会全断。
- **使 `NO_PROXY` 与系统代理绕过列表完全失效**——TUN 在路由层，应用根本不知道有代理，两层绕过配置只对系统代理模式有效。
- 需要管理员权限与虚拟网卡驱动，影响整机路由表；相比之下显式配置只是一个环境变量。

**常态形态是显式两层配置**：浏览器/Electron 走系统代理，CLI 与 Go/Python 走环境变量，WSL 归入后者。TUN 留给例外，用完即关。

### 2.2 TUN 抢占默认路由的机制

**现象**：TUN 一开内网全部打不开，但 VPN 面板仍显示「已连接」，极易误判成掉线。

- TUN 网卡会加一条 `0.0.0.0/0`、**RouteMetric 0** 的默认路由。**注意不一定是网上常见的 `0.0.0.0/1 + 128.0.0.0/1` 分割路由**——本机是前者，所以它压过 VPN 默认路由靠的是 **metric 更低，而不是前缀更长**。判断前先看清实际形态，别照搬结论。
- VPN 若为全隧道且**不下发内网明细路由**，内网仅靠 `0.0.0.0/0` 可达。默认路由一旦被抢，内网即全断。
- VPN 服务器的 `/32` 主机路由由 Windows RAS 自动维护、始终指向物理网卡；`/32` 比任何默认路由都具体，所以**隧道本身不会断**——这正是「显示已连接但内网打不开」的由来。

**若确需 TUN 与 VPN 共存**：把 VPN 改为分流并补内网**明细路由**——明细前缀长于 `0.0.0.0/0`，无论 metric 如何都稳赢；同时关掉代理软件的**严格路由 / strict-route**，它会下防火墙规则强制劫持其他虚拟网卡的流量。

### 2.3 诊断

```powershell
Get-NetRoute -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' |
  Select-Object ifIndex,InterfaceAlias,NextHop,RouteMetric
Find-NetRoute -RemoteIPAddress '<目标主机地址>' | Select-Object -Last 1
```

## §3 VPN 全隧道的路由与速率影响

### 3.1 路由优先级

企业 VPN 常下发 `0.0.0.0/0` 默认路由，且其接口度量值优于物理网卡，**连上之后连公网流量也绕经对方网关**。

```powershell
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric |
    Select-Object InterfaceAlias, RouteMetric
Get-NetIPInterface -AddressFamily IPv4 | Select-Object InterfaceAlias, InterfaceMetric
```

路由优先级看的是 **RouteMetric + InterfaceMetric 之和**，不是单看其一——VPN 接口的 InterfaceMetric 往往远小于无线网卡，因此即便 RouteMetric 更大也会胜出。

### 3.2 对公网下载的影响

实测同一台机器：

| 状态 | 公网下载速率 |
| --- | --- |
| VPN 连接 | 约 70 KB/s |
| VPN 断开 | **约 5 MB/s** |

约 75 倍差距，**Windows 与 WSL 两侧一致，与操作系统无关**。

**所以：大批量公网下载（`apt`、`pip`、拉镜像）前先断开 VPN**，只有访问仅 VPN 可达的内网资源时才需要连着。WSL 侧因 VPN 状态变化导致 `apt`/`pip` 半死挂住的判断法见 [wsl/README.md](../wsl/README.md) §4.6。

## §4 WSL 侧代理

### 4.1 宿主的代理在 WSL 里够得着

**更正 2026-08-21 之前的记载**：曾记「宿主上只监听回环的 Clash 端口在 WSL 里够不着」「本机未验证」。实测**不成立**——代理进程监听的是 `::`（全地址，非仅回环），WSL 经默认网关完全可达。

```powershell
Get-NetTCPConnection -State Listen -LocalPort <代理端口> |
  Select-Object LocalAddress,LocalPort
```

`LocalAddress` 为 `::` 或 `0.0.0.0` 即全地址监听；若为 `127.0.0.1` 才需要在代理软件里开「局域网连接 / allow-lan」。

`networkingMode=nat` 下 WSL 里的 `127.0.0.1` **不是**宿主的 `127.0.0.1`，因此必须用**默认网关地址**指向宿主，且 `.wslconfig` 保持 `autoProxy=false`（不去假装 localhost 代理能自动镜像）。

### 4.2 网关地址必须动态取

WSL 每次重启后 NAT 网段可能变化，**不可写死**：

```bash
ip route show default | awk '/default/ {print $3; exit}'
```

### 4.3 配置位置：必须在非交互守卫之前

Ubuntu 默认的 `~/.bashrc` 开头有：

```bash
case $- in
    *i*) ;;
      *) return;;
esac
```

而 `~/.profile` 对 bash login shell **无条件** source `~/.bashrc`。因此代理块必须写在**这段守卫之前**，否则 `bash -lc`（VS Code 解析 shell 环境所用形式）与扩展宿主这类**非交互进程**继承不到。

四条要点：

1. 用**无条件 `export`**，不要写成需手工调用的 shell 函数——没有人会替后台进程敲 `setproxy`。
2. 网关**动态取**（§4.2）。
3. **大小写两套变量都设**，部分工具只读其一。
4. **必须带 `no_proxy`**，含内网域名后缀，否则内网请求会被送去境外节点。

写入形态：

```bash
# >>> wsl-proxy >>>
if [ -z "${WSL_PROXY_OFF:-}" ]; then
    __wsl_host=$(ip route show default 2>/dev/null | awk '/default/ {print $3; exit}')
    if [ -n "$__wsl_host" ]; then
        export HTTP_PROXY="http://${__wsl_host}:<代理端口>"
        export HTTPS_PROXY="$HTTP_PROXY"
        export ALL_PROXY="socks5h://${__wsl_host}:<代理端口>"
        export NO_PROXY="localhost,127.0.0.1,::1,.local,<内网域名后缀>,172.16.0.0/12"
        export http_proxy="$HTTP_PROXY"; export https_proxy="$HTTPS_PROXY"
        export all_proxy="$ALL_PROXY"; export no_proxy="$NO_PROXY"
    fi
    unset __wsl_host
fi
# <<< wsl-proxy <<<
```

`ALL_PROXY` 用 `socks5h://`（`h` = 由代理侧解析 DNS）仅在代理端口为 mixed port 时可用；若该端口只说 HTTP，删掉 `ALL_PROXY`/`all_proxy` 两行即可。临时停用整块：`export WSL_PROXY_OFF=1` 后重开 shell。

### 4.4 VS Code Remote-WSL 的边界

Remote-WSL 的 server 启动参数含 `--use-host-proxy` / `--useHostProxy=true`：VS Code **自身**的网络栈经隧道借用 Windows 代理，因此扩展市场、更新等一切正常。但**插件拉起的请求走 WSL 本地网络栈，不吃这个参数**。

这就是「同一个窗口里只有一个组件连不上」的成因——不要因为扩展市场能用就排除代理问题。

### 4.5 改配置后必须重启 server

已运行的进程不会继承新环境变量。终止后重开窗口：

```bash
pkill -f vscode-server
```

**该发行版中所有 VS Code 集成终端与其中运行的任务会一并终止**，先保存。只杀目标发行版的 server，不要用 `wsl --shutdown`——那会连带干掉其他发行版及其作业。

### 4.6 验证：读进程自己的环境，不靠「应该生效」

```bash
pgrep -f 'type=extensionHost'                      # 取 PID
tr '\0' '\n' < /proc/<PID>/environ | grep -i proxy # 看它实际继承到什么
ps -o lstart= -p <PID>                             # 与配置修改时间对比
```

**启动时间早于配置修改时间的进程一定没有新变量**，这是最快的排除项。

## §5 排错对照

| 症状 | 指向 |
| --- | --- |
| VPN 显示已连接，但内网全部打不开 | TUN 抢走默认路由（§2.2）。隧道没断，是路由被夺 |
| 某个程序连不上外网，但浏览器正常 | 该程序只认代理环境变量，不认系统代理（§1.1） |
| 同一个 VS Code 窗口里只有某个插件连不上 | `--use-host-proxy` 只覆盖 VS Code 自身网络栈（§4.4） |
| WSL 里全部外网不通，Windows 正常 | WSL 侧没有代理变量，或网关地址已变（§4.1、§4.2） |
| API 返回 403 且提示区域限制 | 请求以本地出口 IP 直连，未走代理。403 ≠ 未登录，但连续 403 会使会话失效并叠加显示登录提示 |
| **间歇性 TLS 握手失败，且按域名聚集** | **节点/规则侧问题，不是本地配置**（§6） |
| API 返回 429 / quota exceeded | 服务端配额，**与代理无关**——能收到该错误恰说明链路通 |
| 浏览器已显示登录成功，应用仍报「账号设置失败」 | 失败的是 OAuth **之后**的服务端调用，不是登录本身。查应用自己的 `auth.log` 拿到真实端点再按 §6 采样 |

## §6 判定「配置没生效」还是「节点不稳」

代理故障有两类，症状相似但处置完全不同。**关键判据是同一代理下不同域名的成功率差异**：配置问题会让所有目标一起失败，节点问题按域名聚集。

多次采样，不要只测一次：

```bash
PX="http://<宿主或本机>:<代理端口>"
for u in <对照站点> <可疑站点> ; do
    for i in 1 2 3 4; do
        printf '%-55s ' "$u"
        curl -s -o /dev/null -w 'HTTP %{http_code} ' --max-time 15 -x "$PX" "$u"
        echo "exit=$?"
    done
done
```

判读：

- **全部目标全部失败** → 本地配置或代理进程问题。回到 §1.4 / §4.6 验证变量是否真的生效。
- **部分域名高失败率，另一些 4/4 成功** → 节点或分流规则问题。到代理软件里看可疑域名命中哪条规则、落到哪个节点组，换节点重测。
- **Windows 侧与 WSL 侧失败率一致** → 排除 WSL 配置，问题在宿主之外。
- 失败信息为 `SSL connection could not be established`、curl `exit=35`、`Client network socket disconnected before secure TLS connection was established`、`Received an unexpected EOF or 0 bytes from the transport stream` —— 这几者是**同一件事的不同外衣**：TLS 握手阶段被对端断开。**不要按字面分头归因**，先采样定性。

2026-08-21 实测样例（同一代理端口、同一时段）：

| 端点 | 成功率 |
| --- | --- |
| `github.com` | 全通 |
| `www.googleapis.com` | 6/6 |
| `daily-cloudcode-pa.googleapis.com` | 4/6 |
| `cloudcode-pa.googleapis.com` | 3/6 |
| `accounts.google.com` | **0/6** |

**同一顶级域下不同子域的成功率从 0 到 6/6**，且 Windows 与 WSL 两侧一致 → 判定为节点/规则侧对特定子域的出口问题，与当日所做的全部本地配置改动无关。注意粒度是**子域**而非域名——只测 `www.googleapis.com` 会得出「Google 都正常」的错误结论。

**不要把这类失败记成「瞬时抖动、不可复现」**——单次采样极易得出该错误结论，从而在真问题上跳过。

## §7 各机器现状

### PC-20260706DAHN（研究院 Windows 工作站）

| 项 | 状态 |
| --- | --- |
| 代理监听 | 全地址（`::`），mixed port，HTTP 与 SOCKS5 同端口 |
| 系统代理 | 开启，覆盖浏览器与 Electron 外壳 |
| Windows 环境变量 | 用户级已持久化 `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY`（2026-08-21 补齐，此前仅有 `NO_PROXY`） |
| WSL | Ubuntu-24.04 与 22.04 均已在 `~/.bashrc` 守卫前写入代理块（2026-08-21） |
| TUN | **常关**。本机最后一处隐性依赖（WSL）已转为显式配置 |
| VPN | 全隧道，不下发内网明细路由；与 TUN 互斥（§2.2）。接入参数见业务仓库的本地未入库文档 |

## §8 相关

- [wsl/README.md](../wsl/README.md) §4 —— WSL 特有的网络模式、DNS 固定与内网域名解析分裂
- [git/README.md](../git/README.md) —— SSH over 443 与 `ProxyCommand`
- `dut-institute-work:hpc/environment.md#31-内网与代理` —— 研究院内网与代理的状态结论

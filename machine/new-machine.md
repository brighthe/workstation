# 新机器配置清单

## 1. 网络与代理

目标：浏览器与命令行都能访问 GitHub。装好 Clash（mixed port `7897`）后做三件事：

1. **浏览器**：打开 Clash 的「系统代理」。浏览器和多数 GUI 程序读它。
2. **命令行**：git、curl、Python、Node 等命令行程序不读系统代理，只认环境变量，要在用户级持久化：

   ```powershell
   [Environment]::SetEnvironmentVariable('HTTP_PROXY','http://127.0.0.1:7897','User')
   [Environment]::SetEnvironmentVariable('HTTPS_PROXY','http://127.0.0.1:7897','User')
   [Environment]::SetEnvironmentVariable('NO_PROXY','localhost,127.0.0.1,::1,.local,<内网域名>','User')
   ```

   环境变量只对新启动的程序生效：设完重开终端，已开着的应用要完全退出（含托盘图标）再开。

3. **内网域名**：写进 Windows 的 hosts（`C:\Windows\System32\drivers\etc\hosts`，需管理员）：`<内网 IP> <内网域名>`。WSL 也经 Windows 解析，不用另写。

TUN 不用开，前两项已覆盖浏览器和命令行。

- 验证：`curl.exe -sI https://github.com` 

## 2. WSL 配置

**安装**

```powershell
wsl --install --no-distribution   # 管理员 PowerShell：装 WSL、启用虚拟机平台，完成后重启
wsl --install -d Ubuntu-24.04     # 重启后执行；首次启动按提示建用户 brighthe
```

报 `REGDB_E_CLASSNOTREG` 时：`Get-AppxPackage *WindowsSubsystemForLinux | Remove-AppxPackage` 删掉残留的商店版，从 [Releases](https://github.com/microsoft/WSL/releases) 下载 MSI 装上，再重跑第一条。

**用户**

| 项    | 值                           |
| ---- | --------------------------- |
| 发行版  | `Ubuntu-24.04`（默认发行版，WSL 2） |
| 默认用户 | `brighthe`，在 `sudo` 组       |
| 密码   | 无（建用户时 Ubuntu 不接受空密码，先设临时密码，再按下方命令删掉） |
| sudo | 免密                          |
| 内存上限 | `memory=48GB`（宿主 64 GB，默认只给一半），写在 `.wslconfig`，见下方 |

`%USERPROFILE%\.wslconfig`，改完 `wsl --shutdown`：

```ini
[wsl2]
memory=48GB
networkingMode=mirrored
```

免密 sudo 并删除密码（在 Ubuntu 里执行，`visudo` 校验通过才落盘）：

```bash
echo 'brighthe ALL=(ALL) NOPASSWD:ALL' | sudo tee /tmp/brighthe >/dev/null
sudo visudo -cf /tmp/brighthe && sudo install -m 440 -o root -g root /tmp/brighthe /etc/sudoers.d/brighthe
sudo rm -f /tmp/brighthe && sudo passwd -d brighthe
```

验证：`sudo -k; sudo -n true` 成功，`sudo passwd -S brighthe` 第二列为 `NP`

**网络**

`.wslconfig` 里的 `networkingMode=mirrored` 让 WSL 与 Windows 共用网络，`autoProxy`（默认开启）把 Windows 系统代理同步为 WSL 里所有进程的 `HTTP(S)_PROXY`，包括 Claude Code 这类不经交互 shell 启动的程序。`.bashrc` 不写代理。

不用 NAT 模式 + `.bashrc` 代理块：非交互启动的进程拿不到代理，直连 Anthropic 返回 403。

验证：`wsl -- bash -c 'echo $HTTPS_PROXY'` 输出 `http://127.0.0.1:7897`；`curl -sI https://github.com | head -1`

**apt 源**

`sudo` 会丢掉代理变量，所以 apt 源直接换成清华镜像（24.04 改 `/etc/apt/sources.list.d/ubuntu.sources`，22.04 改 `/etc/apt/sources.list`）：

```bash
sudo sed -i -E 's#http://(archive|security)\.ubuntu\.com#https://mirrors.tuna.tsinghua.edu.cn#g' /etc/apt/sources.list.d/ubuntu.sources
sudo apt-get update
```

验证：`apt-cache policy | grep -c ubuntu.com` 输出 `0`（官方源已全部换掉），且 `apt-get update` 无 `Err` / `E:` 行

## 3. Git / SSH

Windows 上用 PowerShell 里的原生 git，远程一律 SSH，走 443 端口。

1. **密钥**：

   ```powershell
   ssh-keygen -t ed25519 -C "<设备名>" -f "$HOME\.ssh\id_ed25519" --% -N ""
   ```

   `--%` 让 `-N ""` 原样传给 ssh-keygen；Windows PowerShell 5.1 会丢掉空字符串参数，导致报错。

   【手动】把 `id_ed25519.pub` 加到 GitHub 的 SSH keys。

2. **`~/.ssh/config`**：

   ```
   Host github.com
       HostName ssh.github.com
       Port 443
       User git
       IdentityFile ~/.ssh/id_ed25519
       IdentitiesOnly yes
       StrictHostKeyChecking accept-new
       ProxyCommand "C:/Program Files/Git/mingw64/bin/connect.exe" -H 127.0.0.1:7897 %h %p
   ```

   最后一行让 ssh 经 Clash；WSL 里换成 `nc` 写法（见第 4 项）。

3. **提交身份**：

   ```bash
   git config --global user.name "brighthe"
   git config --global user.email "brighthe98@gmail.com"
   ```

4. **WSL**：复用 Windows 的密钥和 config，再执行一遍第 3 项：

   ```bash
   mkdir -p ~/.ssh && chmod 700 ~/.ssh
   cp /mnt/c/Users/<用户>/.ssh/{id_ed25519,id_ed25519.pub,config} ~/.ssh/
   chmod 600 ~/.ssh/id_ed25519 ~/.ssh/config
   ```

   ssh 不读代理变量，WSL 直连 `ssh.github.com:443` 不通，`ProxyCommand` 改为：

   ```
   ProxyCommand nc -X connect -x 127.0.0.1:7897 %h %p
   ```

- 验证：Windows 和 WSL 里 `ssh -T git@github.com` 都回显 `Hi brighthe!`

## 4. Agent 全局指令

克隆本仓库到 `C:\workspace\workstation` 后，把 `agent-rules/<工具>/` 下的指令文件链接到各工具的用户目录（Windows 用 HardLink，WSL 用符号链接）。对照表和命令见 [agent-rules/README.md](../agent-rules/README.md)。不链接的话，工具读不到全局指令。

- 验证：`fsutil hardlink list C:\workspace\workstation\agent-rules\Claude\CLAUDE.md` 列出两个路径；新开 Claude Code 会话，回复为中文

## 5. conda 环境（WSL）

conda 只装在 WSL（`~/miniconda3`），Windows 不装 conda。

```bash
curl -fLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
sha256sum Miniconda3-latest-Linux-x86_64.sh   # 对照 https://repo.anaconda.com/miniconda/ 上的值
bash Miniconda3-latest-Linux-x86_64.sh -b -p ~/miniconda3
~/miniconda3/bin/conda init bash
~/miniconda3/bin/conda config --set auto_activate false   # 不自动进 base
```

fealpy 和 soptx 都必须在 `ihpcm` 环境下以 editable 方式安装，不要装进 `base`。两个仓库克隆到 `~/codespace/` 同一目录下（soptx 用 `../fealpy` 引用 fealpy）：

```bash
conda create -n ihpcm python=3.12.13 -c conda-forge --override-channels -y
conda activate ihpcm
pip install -e ~/codespace/fealpy   # 必须先装：soptx 依赖 fealpy>=4,<5，否则会从 PyPI 拉正式版
pip install -e ~/codespace/soptx
sudo apt-get install -y libglu1-mesa libxft2   # gmsh 的 wheel 运行时需要
```

`--override-channels` 不能省：`.condarc` 默认频道是 `defaults`，会触发 Anaconda 服务条款确认。

- 验证：`python -c "import fealpy, soptx; print(fealpy.__file__, soptx.__file__)"` 两个路径都在 `~/codespace/` 下；`python -c "import gmsh"` 不报错

## 尚未覆盖

- 编辑器（VS Code）配置

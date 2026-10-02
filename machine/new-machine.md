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

**用户**

| 项    | 值                           |
| ---- | --------------------------- |
| 发行版  | `Ubuntu-24.04`（默认发行版，WSL 2） |
| 默认用户 | `brighthe`，在 `sudo` 组       |
| 密码   | 无                           |
| sudo | 免密                          |
| 内存上限 | `%USERPROFILE%\.wslconfig` 写 `[wsl2]` 下 `memory=48GB`（宿主 64 GB，默认只给一半），改完 `wsl --shutdown` |

**网络**

用 WSL 默认网络，`wsl.conf` 不写网络项。只需在 `~/.bashrc` 的"非交互则 return"之前加代理块：

```bash
# WSL 代理：经默认网关（即 Windows）连 Clash；放在 .bashrc 的"非交互则 return"之前
__h=$(ip route show default | awk '{print $3; exit}')
export HTTP_PROXY="http://$__h:7897" HTTPS_PROXY="http://$__h:7897" NO_PROXY="localhost,127.0.0.1,::1,.local,<内网域名>"
export http_proxy="$HTTP_PROXY" https_proxy="$HTTPS_PROXY" no_proxy="$NO_PROXY"
unset __h
```

验证：`curl -sI https://github.com | head -1`

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
   ssh-keygen -t ed25519 -C "<设备名>" -f "$HOME\.ssh\id_ed25519" -N ""
   ```

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

   最后一行让 ssh 经 Clash，只在 Windows 用。

3. **提交身份**：

   ```bash
   git config --global user.name "brighthe"
   git config --global user.email "brighthe98@gmail.com"
   ```

4. **WSL**：复用 Windows 的密钥和 config（删掉 `ProxyCommand` 行），再执行一遍第 3 项：

   ```bash
   mkdir -p ~/.ssh && cp /mnt/c/Users/<用户>/.ssh/{id_ed25519,id_ed25519.pub,config} ~/.ssh/
   chmod 600 ~/.ssh/id_ed25519 && sed -i '/ProxyCommand/d' ~/.ssh/config
   ```

- 验证：Windows 和 WSL 里 `ssh -T git@github.com` 都回显 `Hi brighthe!`

## 尚未覆盖

- conda 环境（`ihpcm`、`soptx-gpu`）的创建步骤
- 编辑器（VS Code）配置

# git —— Git / SSH 环境跨设备迁移

任何新机器照本文件配置**一次**，即可对 brighthe 名下所有 GitHub 仓库 clone / commit / push——密钥与 SSH 配置都是**账户级、机器级**的，与具体仓库无关。

> 各仓库自己的提交纪律（脱敏要求、分支约定、add 范围等）**不在本文件**，见各仓库内的工作流文档（如 heliangos 的 `ai/git-workflow.md`）。

## §0 新机器启动语（复制即用）

**推荐做法：把本文件发给新机器上的 agent，附这句话**（把 `<仓库名>` 换成要克隆的仓库，如 `workstation`、`heliangos`）：

> 照这份 README（重点 §1、§3）把这台 Windows 电脑的 git 环境配好，用 PowerShell 原生 git（别用 cygwin/MSYS）。配到需要加公钥那步，把 id_ed25519.pub 打印给我、停下等我加到 GitHub。加好后把 git@github.com:brighthe/<仓库名>.git（SSH）clone 到 C:\workspace，并 ls-remote 验证鉴权。

- 手上没有本文件、但有网时，可改让 agent 先读它的 raw 版：`https://raw.githubusercontent.com/brighthe/workstation/main/git/README.md`。本仓库 Public、匿名可读，**不依赖 SSH 已配好**——这正是新机器第一步能启动的前提。
- §1/§3 是**账户级、每台机器配一次即终身通用**；之后在这台机上再拉你名下别的仓库，只需把仓库名一换。
- 唯一必须你手动的一步是**把公钥加到 GitHub**（沙箱里 agent 代替不了）。

## §1 用操作系统原生 git（跨 Agent 通用原则）

git/ssh 操作要用**操作系统原生 git**——它的 ssh 会去读 `~/.ssh`（Windows 上即 `C:\Users\<你>\.ssh`）。**不要用把 `HOME` 改写到别处的 POSIX 模拟环境**（cygwin / MSYS / WSL 里指向别处的 ssh），否则读不到密钥与 config，会误报 `no such identity` / `Host key verification failed`——其实配置是好的。

- **Claude Code**：用 **PowerShell**（原生 Windows git），别用 **Bash 工具**（cygwin）。
- **Codex / Antigravity 等**：用各自能调用系统原生 git 的方式，避开 MSYS/cygwin 版 git。
- **诊断鉴权**（只读、不改动任何东西）：`git -C <repo> ls-remote --heads origin`。

## §2 鉴权方式：SSH over 443

- 远程一律用 SSH：`git@github.com:brighthe/<仓库名>.git`。
- **沙箱封 SSH 22 端口**、**HTTPS 在沙箱无法鉴权**（无凭据助手、无缓存凭据、无 `gh`、无交互 tty）→ 统一走 GitHub 的 **SSH over 443**（`ssh.github.com:443`）。
- 靠**全局 `~/.ssh/config`** 把 `github.com` 映射到 443，每台机器配一次即整机所有仓库生效，无需逐仓库设置。

## §3 新机器一次性配置（任何机器照此即可提交）

1. 生成**无口令** ed25519 密钥（非交互推送需无口令）：
   `ssh-keygen -t ed25519 -C "<设备名>" -f ~/.ssh/id_ed25519 -N ""`
2. 把 `~/.ssh/id_ed25519.pub` 加到 **GitHub 账户**的 SSH keys（标题按**设备**命名，如 `heliang-windows-laptop`；账户级密钥对 brighthe 名下所有仓库生效）。
3. 在 `~/.ssh/config` 追加（`~` 由原生 git/ssh 正确解析，**不写绝对路径**即可移植）：
   ```
   Host github.com
       HostName ssh.github.com
       Port 443
       User git
       IdentityFile ~/.ssh/id_ed25519
       IdentitiesOnly yes
       StrictHostKeyChecking accept-new
       UserKnownHostsFile ~/.ssh/known_hosts
   ```
4. 验证：在**原生 shell**（非 cygwin）里 `ssh -T git@github.com` 应回显 `Hi brighthe!`。之后 `git clone` / `git push` 自动走 443。
5. **配置提交身份**（账户级，一次即所有仓库通用；缺这步 commit 会报 `Author identity unknown`）：
   `git config --global user.name "brighthe"`、`git config --global user.email "brighthe98@gmail.com"`。

## §4 各机器现状（参考）

### heliang-windows-laptop

- 密钥 `C:\Users\Lenovo\.ssh\id_ed25519`（无口令）；config 已配 443；公钥标题 `heliang-windows-laptop`。
- 各仓库 `.git/config` 另设了等价的 `core.sshCommand`（绝对路径 `-F .../config -i .../id_ed25519`）——历史遗留、**只对本机有效**；有 §3 的全局 config 就够，新机器**不必**再设。
- ⚠️ 以上绝对路径与 `core.sshCommand` **仅本机**有效；换机器一律照 §3 走。

> 新增设备后，在此追加一小节记录该机现状（密钥位置、公钥标题、特殊之处）。

## §5 排错速查

- `could not read Username for 'https://github.com'` → 远程是 HTTPS；`git remote set-url origin git@github.com:brighthe/<仓库名>.git`。
- `Connection closed by ... port 22` → 没走 443；检查 `~/.ssh/config` 的 443 段（§3）。
- `no such identity` / `Host key verification failed` → 多半在 cygwin/MSYS 环境里跑的；换系统原生 git（§1）。

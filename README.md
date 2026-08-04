# workstation

个人软件 / 工具的**配置、安装与跨设备迁移中枢**，同时维护本地科研工作区的声明式仓库清单，并提供各工具**官方能力与最新教程的导读**。

目标有三：换新机器时，把这个仓库 clone 下来，按各模块的 `README.md` 把环境一步步装回来——
脚本、配置模板、操作流程都在版本控制里；平时则通过各模块的 `capabilities.md`
跟进该工具官方推出的新能力和使用教程；通过 `workspace/` 清单与只读脚本检查九个科研工作区仓库（六个个人、三个算海）是否完整、干净并连接到正确远程。

**工作区跨两个运行时**：文档与 Windows 原生运维类仓库（`authoring`）在 `C:\workspace`，科学计算类仓库（`compute`）在 WSL 的 `~/workspace`。哪个仓库属于哪一层由清单声明，每台机器的实际落点由本地配置解析——所以 clone 完 `C:\workspace` 并不等于工作区就齐了，详见 [workspace/README.md](workspace/README.md)。

> 注意：**这里只放工具与流程，不放数据本身**（聊天记录、密钥、token 等私密或大体量数据不进本仓库）。

## 目录结构

```
workstation/
├── README.md      # 本文件：总览 + 新机迁移入口
├── git/           # 模块：Git / SSH 环境跨设备迁移（原生 git、SSH over 443、新机一次性配置）
├── wsl/           # 模块：WSL2 + Ubuntu 开发环境（安装、映像缺组件的顶替方案、网络与 DNS）
├── workspace/     # 模块：九个科研工作区仓库的声明式清单、运行时分层、职责边界与本地状态入口
├── claude/        # 模块：Claude Code 全局指令（CLAUDE.md）、记忆管理说明、能力导读
├── codex/         # 模块：Codex 全局指令（AGENTS.md）、记忆管理说明、能力导读
├── scripts/       # 中立的跨工具公共脚本（工作区检查、全局指令链接、iCloud 定时同步等）
├── remote-access/ # 模块：Windows + Tailscale + OpenSSH 三节点全互联
└── hardware/      # 模块：硬件维护流程（台式机清灰指南 + 工具清单）
```

各工具的说明和配置留在自己的模块中；确实被多个工具复用的实现放在 `scripts/`，避免产品文档互相引用或把公共逻辑归属到某一个工具。

以后每加一个工具（编辑器、shell、其它 AI CLI 等），就新建一个同级子目录，内放该工具的
`README.md` + 脚本/模板，保持同一套约定；AI 工具模块另配一个 `capabilities.md`
（官方能力与教程导读，框架：使用边界 → 能力清单 → 跟进机制）。

## 新机器快速开始

1. **先配 git / SSH 环境**（第 0 步，其余一切的前提）：照 [git/README.md](git/README.md) 走 §0 启动语；新机器上还没有本仓库时，让 agent 直接读它的 raw 版 `https://raw.githubusercontent.com/brighthe/workstation/main/git/README.md`（本仓库 Public、匿名可读）。
2. 克隆本仓库（SSH over 443 已在上一步配好；沙箱环境无 `gh`，统一用 git）：

```powershell
git clone git@github.com:brighthe/workstation.git C:\workspace\workstation
```

3. 运行共享初始化脚本，为 Codex 和 Claude Code 建立指向本仓库的全局指令符号链接：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\setup-global-instruction-links.ps1
```

脚本会根据自身位置自动识别仓库根目录，并在链接已经正确时保持不变。如果目标位置已有普通文件或指向其他位置的链接，脚本会在不修改任何内容的情况下停止；请先检查并手动备份。完成后可继续阅读各模块的 `README.md` 了解具体管理方式。Windows 创建符号链接需要启用 Developer Mode 或使用管理员 PowerShell；Codex hook 信任仍需在每台设备上单独确认。

4. 验证九个科研工作区仓库的路径、远程与本地状态：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\workspace\validate.ps1

powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\workspace\status.ps1
```

两个脚本只读检查，不自动执行 `fetch`、`pull`、`commit` 或 `push`。清单与职责边界见 [workspace/README.md](workspace/README.md)。

如需每天将 `dut-postdoc` 和 `dut-institute-work` 镜像到 iCloud Obsidian，按 [scripts/icloud-sync/README.md](scripts/icloud-sync/README.md) 注册 Windows 定时任务。该配置可随本仓库迁移，但任何时刻只应在一台电脑启用。

## 模块清单

| 模块 | 说明 | 跨设备方式 |
|---|---|---|
| [git](git/README.md) | Git / SSH 环境：原生 git、SSH over 443、新机一次性配置、各机现状与排错 | 本仓库（git），纯文档；新机经 raw URL 引导 |
| [wsl](wsl/README.md) | WSL2 + Ubuntu 开发环境：安装、映像缺 `VirtualMachinePlatform` 时的顶替方案、网络与 DNS、各机现状 | 本仓库（git），纯文档，无需链接 |
| [workspace](workspace/README.md) | 九个科研工作区仓库的声明式清单、运行时分层、职责边界、配置验证与只读状态汇总 | 本仓库（git）；`authoring` 根从 `workstation` 位置推导，`compute` 根由本机 `roots.local.json` 解析 |
| [claude](claude/README.md) | Claude Code 全局指令（CLAUDE.md）与记忆管理；[能力导读](claude/capabilities.md) | 本仓库（git）+ 符号链接到 `~/.claude/CLAUDE.md` |
| [codex](codex/README.md) | Codex 全局指令（AGENTS.md）与记忆管理；[能力导读](codex/capabilities.md) | 本仓库（git）+ 链接到 `~/.codex/AGENTS.md` |
| [remote-access](remote-access/README.md) | Windows 设备通过 Tailscale + OpenSSH 两两远程终端；密钥隔离、节点初始化、验证与恢复 | 本仓库只保存流程和脚本；私钥留在各设备 `~/.ssh`，真实 inventory 不入库 |
| [hardware](hardware/README.md) | 硬件维护流程：台式主机（RTX 5070 Ti）清灰指南与工具清单 | 本仓库（git），纯文档，无需链接 |
| [scripts/icloud-sync](scripts/icloud-sync/README.md) | 两个个人仓库到 iCloud Obsidian 的每日镜像同步与跨设备任务迁移 | Windows Task Scheduler；旧机卸载、新机一键安装 |

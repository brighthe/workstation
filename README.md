# workstation

个人软件 / 工具的**配置、安装与跨设备迁移中枢**，外加各工具**官方能力与最新教程的导读**。

目标有二：换新机器时，把这个仓库 clone 下来，按各模块的 `README.md` 把环境一步步装回来——
脚本、配置模板、操作流程都在版本控制里；平时则通过各模块的 `capabilities.md`
跟进该工具官方推出的新能力和使用教程。

> 注意：**这里只放工具与流程，不放数据本身**（聊天记录、密钥、token 等私密或大体量数据不进本仓库）。

## 目录结构

```
workstation/
├── README.md      # 本文件：总览 + 新机迁移入口
├── git/           # 模块：Git / SSH 环境跨设备迁移（原生 git、SSH over 443、新机一次性配置）
├── claude/        # 模块：Claude Code 全局指令（CLAUDE.md）、记忆管理说明、能力导读
├── codex/         # 模块：Codex 全局指令（AGENTS.md）、记忆管理说明、能力导读
├── scripts/       # 中立的跨工具公共脚本（例如指令译文同步提醒）
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

## 模块清单

| 模块 | 说明 | 跨设备方式 |
|---|---|---|
| [git](git/README.md) | Git / SSH 环境：原生 git、SSH over 443、新机一次性配置、各机现状与排错 | 本仓库（git），纯文档；新机经 raw URL 引导 |
| [claude](claude/README.md) | Claude Code 全局指令（CLAUDE.md）与记忆管理；[能力导读](claude/capabilities.md) | 本仓库（git）+ 符号链接到 `~/.claude/CLAUDE.md` |
| [codex](codex/README.md) | Codex 全局指令（AGENTS.md）与记忆管理；[能力导读](codex/capabilities.md) | 本仓库（git）+ 链接到 `~/.codex/AGENTS.md` |
| [hardware](hardware/README.md) | 硬件维护流程：台式主机（RTX 5070 Ti）清灰指南与工具清单 | 本仓库（git），纯文档，无需链接 |

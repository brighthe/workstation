# workstation

个人软件 / 工具的**配置、安装与跨设备迁移中枢**。

目标：换新机器时，把这个仓库 clone 下来，按各模块的 `README.md` 把环境一步步装回来——
脚本、配置模板、操作流程都在版本控制里。

> 注意：**这里只放工具与流程，不放数据本身**（聊天记录、密钥、token 等私密或大体量数据不进本仓库）。

## 目录结构

```
workstation/
├── README.md      # 本文件：总览 + 新机迁移入口
├── claude/        # 模块：Claude Code 全局指令（CLAUDE.md）与记忆管理说明
└── codex/         # 模块：Codex 全局指令（AGENTS.md）与记忆管理说明
```

以后每加一个工具（编辑器、shell、其它 AI CLI 等），就新建一个同级子目录，内放该工具的
`README.md` + 脚本/模板，保持同一套约定。

## 新机器快速开始

```bash
gh repo clone brighthe/workstation
```

然后对想恢复的模块，读它的 `README.md` 并执行。例如恢复 Claude Code 全局指令：

> 读 `claude/README.md`，用管理员 PowerShell 把 `~/.claude/CLAUDE.md` 符号链接到本仓库
> `claude/CLAUDE.md`，即全局生效。

## 模块清单

| 模块 | 说明 | 跨设备方式 |
|---|---|---|
| [claude](claude/README.md) | Claude Code 全局指令（CLAUDE.md）与记忆管理 | 本仓库（git）+ 符号链接到 `~/.claude/CLAUDE.md` |
| [codex](codex/README.md) | Codex 全局指令（AGENTS.md）与记忆管理 | 本仓库（git）+ 链接到 `~/.codex/AGENTS.md` |

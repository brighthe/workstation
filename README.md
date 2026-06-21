# workstation

个人软件 / 工具的**配置、安装与跨设备迁移中枢**。

目标：换新机器时，把这个仓库 clone 下来，让 Claude Code（或我自己）按各模块的
`AGENT-RUNBOOK.md` 把环境一步步装回来——脚本、配置模板、操作流程都在版本控制里。

> 注意：**这里只放工具与流程，不放数据本身。** 例如 Claude Code 的聊天记录是
> 大体量私密数据，走 iCloud Drive 同步（见 `claude-code/`）；本仓库只存「怎么把
> 同步装起来」的脚本和文档。

## 目录结构

```
workstation/
├── README.md                 # 本文件：总览 + 新机迁移入口
└── claude-code/              # 模块一：Claude Code 聊天记录跨设备同步
    ├── README.md             # 方案说明（Local 模式 + iCloud Drive）与注意事项
    ├── AGENT-RUNBOOK.md      # 给 Claude Code 看的自动安装指令（新机照此自助安装）
    ├── scripts/
    │   ├── claude-code-sync.ps1   # Windows 同步脚本（纯 ASCII，无编码坑）
    │   └── claude-code-sync.sh    # WSL2 / Linux / Git Bash 同步脚本
    └── templates/
        └── settings.json     # settings.json 模板（含 SessionEnd 钩子）
```

以后每加一个工具（编辑器、shell、其它 AI CLI 等），就新建一个同级子目录，内放该工具的
`README.md` + `AGENT-RUNBOOK.md` + 脚本/模板，保持同一套约定。

## 新机器快速开始

```bash
gh repo clone brighthe/workstation
```

然后对想恢复的模块，让 Claude Code 读它的 `AGENT-RUNBOOK.md` 并执行，例如：

> 读 `claude-code/AGENT-RUNBOOK.md`，在这台机器上把 Claude Code 聊天记录同步装好。

## 模块清单

| 模块 | 说明 | 数据存放 |
|---|---|---|
| [claude-code](claude-code/README.md) | Claude Code 聊天记录跨设备同步 | iCloud Drive（数据）+ 本仓库（工具） |

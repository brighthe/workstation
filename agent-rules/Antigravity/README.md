# Antigravity 全局记忆与指令管理说明

> - **整理日期**：2026-08-05
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Antigravity IDE / Agent

本文档用于管理和说明 Google Antigravity 的“全局指令（[`GEMINI.md`](GEMINI.md)）”以及与本地 Customizations 的核心分工。

---

## 核心分工

- **`GEMINI.md`（全局指令）**：由用户主动编写与维护，存放 Antigravity 应长期无条件遵守的行为准则、工作模式与环境约束。每个会话开始时完整加载。
- **Customizations（全局自定义配置）**：存放在 `C:\Users\Administrator\.gemini\config\`，包含全局 `rules/`（按主题规则子文件）、全局 `skills/`（自定义技能库）及 `mcp_config.json`。

---

## 实际文件链接与跨系统绑定

本目录下的 [`GEMINI.md`](GEMINI.md) 为唯一维护源头，通过系统软链接（Symbolic Link / Hard Link）同时绑定至两套环境：

- **[workstation 仓库主文件](GEMINI.md)**：[`C:\workspace\workstation\agent-rules\Antigravity\GEMINI.md`](file:///C:/workspace/workstation/agent-rules/Antigravity/GEMINI.md)
- **Windows 全局绑定路径**：`C:\Users\Administrator\.gemini\config\GEMINI.md`

---

## 全局指令中文详细对照与解读（`GEMINI.md`）

为了方便查阅与日常维护，以下为 [`GEMINI.md`](GEMINI.md) 的完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量名、命令、配置键及产品名称保持**英文**原文。

### 2. 交互模式与操作请示（Interaction Mode & Operational Work）
- 在新会话或非平凡任务开始前，向用户建议适合的模式（Manual 问答模式、Plan 计划模式或 Goal 目标模式）。
- **非只读操作必须“先请示、后执行”**：对于修改机器状态或消耗算力的操作（环境配置、包安装、Build、跑程序、训练、测试、MPI 任务等），先给出计划与完整命令，获得用户明确批准后运行。
- **只读检查自由执行**：`git status/log/show/diff`、静态搜索、读写临时文件无需请示。

### 3. 批判性评估（Critical Evaluation）
- 对用户提出的方案进行独立评估，检查正确性、可行性、风险与替代方案。
- 若存在明显错误或过大风险，给出理由并推荐更好方案后再继续执行。

### 4. 个人背景信息（User Context）
- **用户**：何亮 (Liang He)，大连理工大学博士后，研究方向为拓扑优化、有限元（FEM）及物理信息机器学习（PIML）。

### 5. 工作区仓库治理（Workspace Repository Governance）
- 仓库划分为 `authoring`（`C:\workspace`）与 `compute`（WSL `~/workspace`）两层，具体路由统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- 遵守项目级 `GEMINI.md` / `AGENTS.md` / `README.md`。提交或推送前核对 `origin`。
- 标记为 `company` / `suanhaitech` 的仓库资产严禁复制到个人仓库。

### 6. 指令界限与说明更新（Scope & Customizations）
- 仅维护 Antigravity 相关的指令文件。修改 `GEMINI.md` 时同步更新本中文 `README.md`。

### 7. Windows 与 WSL 执行规范（Windows & WSL Execution）
- Windows 仓库使用 PowerShell 与原生 Windows Git/OpenSSH；`compute` 仓库在 WSL 内运行 Git。
- **Python 运行指定**：
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - 日志重定向至 `logs/run.log`；图片保存至 `figs/`。

### 8. Git 暂存区卫生（Git Staging Hygiene）
- 提交前检查 Working Tree，仅 Stage 任务相关修改，严禁使用 `git add -A`。

---

## 官方参考链接

- [Google Antigravity 官方技能与配置规范说明](C:\Users\Administrator\.gemini\antigravity\builtin\skills\antigravity_guide\SKILL.md)

# Antigravity 全局记忆与指令管理说明

> - **整理日期**：2026-08-05
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Antigravity IDE / Agent

本文档用于管理和说明 Google Antigravity 的“全局指令（[`GEMINI.md`](GEMINI.md)）”以及与本地 Customizations 的核心分工。

---

## 核心分工

- **`GEMINI.md`（全局指令）**：由用户主动编写与维护，存放 Antigravity 应长期无条件遵守的行为准则、工作模式与环境约束。每个会话开始时完整加载。
- **Customizations（全局自定义配置）**：存放在 `C:\Users\Administrator\.gemini\config\`，包含全局 `rules/`（按主题规则子文件）、全局 `skills/`（自定义技能库）及 `mcp_config.json`；它不承载全局 `GEMINI.md`。

---

## 实际文件链接与跨系统绑定

本目录下的 [`GEMINI.md`](GEMINI.md) 为唯一维护源头，通过系统软链接（Symbolic Link / Hard Link）同时绑定至两套环境：

- **[workstation 仓库主文件](GEMINI.md)**：[`C:\workspace\workstation\agent-rules\Antigravity\GEMINI.md`](file:///C:/workspace/workstation/agent-rules/Antigravity/GEMINI.md)
- **Windows 全局绑定路径**：`C:\Users\Administrator\.gemini\GEMINI.md`

---

## 全局指令中文详细对照与解读（`GEMINI.md`）

为了方便查阅与日常维护，以下为 [`GEMINI.md`](GEMINI.md) 的完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量、路径、命令、配置键、API 名称及产品名称保持**英文**原文。
- 数学公式统一使用 LaTeX：行内 `$...$`，独立公式 `$$...$$`；不得用 Unicode 符号拼凑公式。

### 2. 交互模式建议（Interaction Mode）
- 在会话或非平凡任务开始时，用一行建议合适的模式，由用户决定：
  - **默认模式（Manual）**：只读问答、解释与小澄清，直接回答即可。
  - **计划先行（Plan）**：多步编辑、重构、配置变更——先起草实现计划，等待用户批准（计划能力内建于 agent 工作流）。
  - **Goal 式连续执行**：长周期、可验证、可运行到底的工作；无原生 Goal 机制，属行为约定——必须有明确可验证的停止条件，且仅在用户显式要求时启动。
- 平凡后续问题跳过建议；建议保持一行。

### 3. 操作型工作——先提议后询问（Operational Work）
- **凡是会改变机器状态或消耗实际算力的操作**（环境/包变更、构建、训练、测试、基准、MPI 任务、长时脚本）：先给出确切命令并请示，获准后才运行——绝不先执行后汇报。只读检查（`git status/log/show/diff`、列目录/读文件/静态搜索、版本查询）自由执行。
- 计划获批只代表方案获批，不等于执行授权；运行前需再次询问。
- 多步骤工作分步推进：每完成一个有意义的环节汇报一次，与用户对齐后再继续（Goal 模式豁免——按停止条件跑到底）。
- 用户明确说“跑一下”（run it）时，对该具体动作直接执行，不再重复确认。

### 4. 批判性评估（Critical Evaluation）
- 对用户提出的方案进行独立评估，而非盲目接受：检查正确性、可行性、关键假设、风险、权衡与替代方案。
- 如果用户的方案存在错误、过大风险或明显劣于其他方案，必须给出具体理由并推荐更好的方案，再继续执行。
- 若用户明确要求完全按其方案执行，遵从用户的同时需简要进行风险提示。

### 5. 工作区与执行（Workspace & Execution）
- 工作区分三层：文档仓库（`C:\workspace`，Windows 本机）、代码研发仓库（WSL Ubuntu-24.04 `~/workspace`）与项目代码仓库（WSL Ubuntu-22.04 `~/workspace`）；具体分工、数据源头、远程分支路由与算海边界统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- Windows 仓库使用 PowerShell 与原生 Windows Git/OpenSSH；WSL 仓库的 Git 操作在其所属发行版内部执行（如 `wsl -d <distro> -- git -C /home/brighthe/workspace/<repo>`）。
- **Python 运行指定**：
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - 日志重定向至 `logs/run.log`；图片保存至 `figs/`。
- 提交前检查 Working Tree 并核对 `origin`，仅 Stage 任务相关修改，严禁使用 `git add -A`；未经用户明确请求，不执行 `git commit` 或 `git push`。
- 提交信息默认使用简体中文；仓库局部约定优先。

---

## 官方参考链接

- [Google Antigravity 官方技能与配置规范说明](C:\Users\Administrator\.gemini\antigravity\builtin\skills\antigravity_guide\SKILL.md)

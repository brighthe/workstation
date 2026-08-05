# OpenAI Codex 全局记忆与指令管理说明

> - **整理日期**：2026-08-05
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Codex CLI、Codex Desktop App

本文档用于管理和说明 OpenAI Codex 的“全局指令（[`AGENTS.md`](AGENTS.md)）”以及与“Memories”的核心分工。

---

## 核心分工

- **`AGENTS.md`（全局指令）**：由用户主动编写与维护，存放 Codex 应长期无条件遵守的行为准则、工作规范与安全约束。每个会话开始时完整加载。
- **Memories（自动记忆）**：由 Codex 自动学习、生成和维护的经验笔记，用来保存偏好、工作区背景和稳定调试经验。

---

## 实际文件链接与跨系统绑定

本目录下的 [`AGENTS.md`](AGENTS.md) 为唯一维护源头，通过系统软链接（Symbolic Link / Hard Link）同时绑定至两套环境：

- **[workstation 仓库主文件](AGENTS.md)**：[`C:\workspace\workstation\agent-rules\Codex\AGENTS.md`](file:///C:/workspace/workstation/agent-rules/Codex/AGENTS.md)
- **Windows 全局绑定路径**：`C:\Users\Administrator\.codex\AGENTS.md`
- **WSL Linux 全局绑定路径**：`\\wsl.localhost\ubuntu-24.04\home\brighthe\.codex\AGENTS.md`

---

## 全局指令中文详细对照与解读（`AGENTS.md`）

为了方便查阅与日常维护，以下为精简优化后的 [`AGENTS.md`](AGENTS.md) 完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回答。
- 所有的技术术语、路径、命令、配置键、API 名称及产品名称保持**英文**原文。

### 2. 文档优先原则（Documentation First）
- 当询问 Codex 本身的功能或规则时，必须优先查阅 [OpenAI Codex 官方文档](https://developers.openai.com/codex)，严禁凭空猜测。

### 3. 交互模式建议（Interaction Mode）
- 在非平凡任务开始前，建议适合的模式：
  - **默认模式（Normal）**：用于只读检查、解答疑问、说明与小澄清。
  - **Plan 计划模式**：用于代码修改、配置变更、安装包、Commit 或多步骤排错。
  - **Goal 工作流**：仅用于跨多轮会话的长周期任务，且必须有明确可验证的停止条件（非显式要求不随意开启）。

### 4. 用户操作导向与请示（Operational Work & User Guidance）
- **默认准备好执行步骤供用户操作**：提供完整的代码、环境说明、单条 PowerShell 命令及验收标准，等待用户反馈结果后再提供下一步。
- 未经用户明确要求，不随意自动运行测试、MPI 任务、基准测试或验证驱动。
- 读取当前内置终端中的输出时直接查看，无需让用户重复粘贴已有的控制台输出。

### 5. 批判性评估（Critical Evaluation）
- 对用户提出的方案进行独立评估，检查正确性、可行性、核心假设、风险与替代方案。
- 如果用户的方案存在错误或明显劣于其他选择，指出具体原因并推荐更好的方法。

### 6. 工作区仓库治理（Workspace Repository Governance）
- 仓库划分为 `authoring`（`C:\workspace`）与 `compute`（WSL `~/workspace`）两层，具体分工、数据源头与远程分支路由统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- 遵守项目级 `AGENTS.md` / `README.md`。提交或推送前核对 `origin`。
- 标记为 `company` / `suanhaitech` 的仓库代码、数据及凭据严禁复制到个人仓库。

### 7. AI 指令界限（Scope & Instruction Boundaries）
- 仅维护 Codex 自身的 `AGENTS.md` 及相关配置。修改 `AGENTS.md` 时同步更新本中文 `README.md`。
- 未经授权不主动修改其他 AI 工具的指令文件（如 `CLAUDE.md`）。

### 8. 执行与 Git 卫生（Execution & Git Hygiene）
- Windows 仓库使用 PowerShell 与原生 Windows Git/OpenSSH；`compute` 仓库在 WSL Linux 内运行 Git。
- 提交前检查 Working Tree，仅 Stage 与当前任务相关的修改文件，严禁使用 `git add -A`。
- 未经用户明确指示，不自动执行 `git commit` 或 `git push`。

---

## 官方参考链接

- [OpenAI Codex 官方文档](https://developers.openai.com/codex)
- [AGENTS.md 官方指南](https://developers.openai.com/codex/guides/agents-md)
- [Memories 官方说明](https://developers.openai.com/codex/memories)

# Codex 全局配置与指令管理

> - **整理日期**：2026-08-14
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Codex CLI、Codex Desktop App

本文档用于管理 OpenAI 官方 Codex 的全局指令、配置和自定义 agent。Codex 使用 ChatGPT 登录或 OpenAI 官方 API；DeepSeek 等其他产品应使用各自的客户端或 Harness，不再复用 Codex 的配置、启动器或环境变量。

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

## 目录文件与链接一览

| 文件 | 作用 | 真实路径 | 链接 |
| :--- | :--- | :--- | :--- |
| `AGENTS.md` | 全局指令（每个会话开始自动加载） | `C:\workspace\workstation\agent-rules\Codex\AGENTS.md` | 硬链接至 `C:\Users\Administrator\.codex\AGENTS.md`（WSL 另行绑定） |
| `README.md` | 本说明文档 | 本目录 | 普通文件 |
| `config.toml` | 官方 Codex 用户配置（Desktop / CLI / VS Code 共用） | `C:\Users\Administrator\.codex\config.toml` | 修改前先检查实际链接关系 |
| `deep-task.toml` | 自定义 agent（复杂任务委托，`gpt-5.6-sol` + `high`） | `C:\Users\Administrator\.codex\agents\deep-task.toml` | 硬链接 |

### 边界与维护说明
- `config.toml` 只服务 OpenAI 官方 Codex。不要加入第三方 `model_provider`、`model_catalog_json`、第三方 Base URL 或第三方 API Key。
- `deep-task.toml` 是 agent 定义层，仅在调用 `deep-task` 时生效，不影响日常会话的默认模型（`gpt-5.6-terra`）。
- `config.toml` 可能含有本机运行时、插件缓存路径或 MCP 配置；它们依赖本机安装状态，重装或升级后应重新核对，不应盲目删除。
- 除已核验的文件外，不假设同名文件为硬链接；编辑或同步前应使用 `Get-Item ... | Select-Object FullName, LinkType, Target` 检查实际关系。

---

## 全局指令中文详细对照与解读（`AGENTS.md`）

为了方便查阅与日常维护，以下为精简优化后的 [`AGENTS.md`](AGENTS.md) 完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量、路径、命令、配置键、API 名称及产品名称保持**英文**原文。
- 数学公式统一使用 LaTeX：行内 `$...$`，独立公式 `$$...$$`；不得用 Unicode 符号拼凑公式。

### 2. 交互模式建议（Interaction Mode）
- 在会话或非平凡任务开始时，用一行建议合适的模式，由用户决定：
  - **默认模式（Normal）**：只读问答、解释与小澄清，直接回答即可。
  - **Plan Mode（`/plan`）**：多步编辑、重构、配置变更。
  - **Goal 式连续执行**：长周期、可验证、可运行到底的工作；无原生 Goal 机制，属行为约定——必须有明确可验证的停止条件，且仅在用户显式要求时启动。
- 平凡后续问题跳过建议；建议保持一行。

### 3. 操作型工作——先提议后询问（Operational Work）
- **凡是会改变机器状态或消耗实际算力的操作**（环境/包变更、构建、训练、测试、基准、MPI 任务、长时脚本）：先给出确切命令并请示，获准后才运行——绝不先执行后汇报。只读检查（`git status/log/show/diff`、列目录/读文件/静态搜索、版本查询）自由执行。
- 计划获批只代表方案获批，不等于执行授权；运行前需再次询问。
- 多步骤工作分步推进：每完成一个有意义的环节汇报一次，与用户对齐后再继续（Goal 模式豁免——按停止条件跑到底）。
- 用户明确说“跑一下”（run it）时，对该具体动作直接执行，不再重复确认。
- 读取当前内置终端中的输出时直接查看，无需让用户重复粘贴已有的控制台输出。

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
  - 长时间运行输出重定向至 `logs/run.log`；绘制图片保存至 `figs/`。
- 提交前检查 Working Tree 并核对 `origin`，仅 Stage 与当前任务相关的修改文件，严禁使用 `git add -A`；未经用户明确指示，不自动执行 `git commit` 或 `git push`。
- 提交信息默认使用简体中文；仓库局部约定优先。

---

### 6. 复杂任务委托（Complex Task Delegation）
- 对于真正复杂、高价值的任务（多步骤重构、跨模块设计、深度代码审查、深度研究、疑难排错），自动委托给自定义 `deep-task` agent（`~/.codex/agents/deep-task.toml`，模型 `gpt-5.6-sol`，推理 `high`）。
- 规则保持窄范围：常规编辑、问答、只读检查与范围明确的小任务继续使用默认模型（`gpt-5.6-terra`）。

---

## 认证与旧配置清理

- 推荐在 Codex Desktop、CLI 和 VS Code 扩展中使用 **Sign in with ChatGPT**；此方式无需在 `config.toml` 写入 `OPENAI_API_KEY`。
- 若使用 OpenAI 官方 API，API Key 应仅通过安全的环境变量或受支持的凭据流程提供，绝不提交到仓库。
- 原用于将 Codex 路由至 DeepSeek 的 `config-deepseek.toml`、`CODEX_HOME` 切换和 `codex-deepseek` 启动器均已废弃并应删除。
- 配置字段以 [OpenAI Codex 配置参考](https://learn.chatgpt.com/docs/config-file/config-reference) 为准。

---

## 官方参考链接

- [OpenAI Codex 官方文档](https://developers.openai.com/codex)
- [AGENTS.md 官方指南](https://developers.openai.com/codex/guides/agents-md)
- [Memories 官方说明](https://developers.openai.com/codex/memories)

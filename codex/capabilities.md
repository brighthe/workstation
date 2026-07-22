# Codex 能力与官方教程导读

这个文档是给我自己看的，用来帮助我理解 Codex 官方推出的能力和最新教程。文档结构：产品入口选择 → 任务执行方式 → 执行环境 → 能力清单 → 跟进机制。

定位（与本目录另外两个文件的分工）：

- [`AGENTS.md`](AGENTS.md)：全局指令本体，被符号链接到 `~/.codex/AGENTS.md`。
- [`README.md`](README.md)：全局指令与 Memories 的**管理**说明。
- 本文档：官方**能力与教程**的导读，含个人使用状态。

维护原则：不做官方文档的镜像；只放"筛选 + 一句话说明 + 入口链接 + 我的使用状态"。

## 1. 产品入口：Chat、Work 与 Codex

一句话：**需要答案时用 Chat，需要交付物时用 Work，需要改变项目状态时用 Codex。**

| 入口 | 什么时候使用 | 主要结果 |
| :--- | :--- | :--- |
| **Chat** | 提问、学习、讨论、比较方案、头脑风暴，主要需要即时回答 | 答案、解释、建议、草稿 |
| **Work** | 已有目标、文件或资料，希望完成研究、分析和内容制作 | 报告、文档、表格、演示文稿、Sites |
| **Codex** | 需要进入本地项目或代码仓库，调用终端和开发工具并验证结果 | 文件或代码修改、测试结果、Git diff、可运行项目 |

### 快速判断

- 主要需要一个回答、解释或思路 → **Chat**。
- 主要需要一份可以审阅、分享或继续加工的交付物 → **Work**。
- 主要需要修改代码仓库或本地项目，并运行命令、测试或 Git 操作 → **Codex**。

### 常见场景

- “解释 Python 装饰器”或“比较三种研究方案” → **Chat**。
- “根据论文形成研究报告”或“分析 Excel 并制作汇报材料” → **Work**。
- “阅读仓库并解释调用链”或“修改代码、运行测试并检查 diff” → **Codex**。

三者的能力存在重叠，应按**主要产物和执行环境**选择，而不是只看主题是否涉及代码：Chat 也能生成代码片段，Work 也能处理技术资料，Codex 也能研究和编写文档；当任务需要直接操作工作区、终端、Git 或开发工具时，优先使用 Codex。

新版桌面应用将 Chat、Work 和 Codex 集成在同一应用中，但 Codex 仍是独立的软件开发工作区，其任务历史与 ChatGPT 历史分开。相关说明参见：

- [OpenAI Developers](https://developers.openai.com/)
- [ChatGPT Work 与 Codex](https://help.openai.com/en/articles/20001275-chatgpt-work-and-codex)
- [迁移到新版 ChatGPT 桌面应用](https://help.openai.com/en/articles/20001276-moving-to-the-new-chatgpt-desktop-app)
- [使用 ChatGPT 方案中的 Codex](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan)

产品界面、平台支持和具体能力可能随版本调整，涉及当前行为时以 OpenAI 官方最新文档为准。

## 2. Codex 任务执行方式：普通对话、Plan mode 与 Goal

一句话：**普通对话用于直接协作，Plan mode 用于先规划多步骤工作，Goal 用于围绕可验证的停止条件持续推进。**

| 执行方式 | 什么时候使用 | 如何进入与退出 | 官方入口 |
| :--- | :--- | :--- | :--- |
| **普通对话**（本仓库简称“普通模式”） | 问答、解释、只读检查、小澄清和范围明确的短任务 | 默认状态，不需要专门命令 | “普通模式”不是官方正式命令名称 |
| **Plan mode** | 需要先研究现状、澄清取舍并形成多步骤实施方案 | 可在会话中途使用 `/plan` 开启；再次使用 `/plan` 可退出 | [Slash commands](https://learn.chatgpt.com/docs/reference/slash-commands) |
| **Goal** | 目标明确、耗时较长，并且具有验证循环和停止条件的持续工作 | 可在会话中途使用 `/goal <目标>` 创建；使用 `/goal` 查看，使用 `/goal pause`、`/goal resume` 或 `/goal clear` 控制生命周期 | [Follow a goal](https://learn.chatgpt.com/use-cases/follow-goals) |

普通对话和 Plan mode 描述当前的协作方式；Goal 则为任务增加持续目标及其生命周期，因此不是与 Plan mode 完全同类的开关。Plan mode 与 Goal 均不要求在会话开始时指定。官方建议先用 `/plan` 塑造清晰的 Goal，但这不是创建 Goal 的必需步骤。完整命令列表参见 [Slash commands](https://learn.chatgpt.com/docs/reference/slash-commands)。

## 3. Codex 执行环境：Local、Worktree 与 Cloud

一句话：**Local 直接使用当前项目，Worktree 隔离本地改动，Cloud 在已配置的远程环境中运行。**

| 环境 | 运行位置与隔离方式 | 什么时候使用 |
| :--- | :--- | :--- |
| **Local** | 在当前项目目录中直接工作 | 希望立即使用当前工作区及其未提交状态 |
| **Worktree** | 在本机创建独立的 Git worktree | 希望隔离改动，或并行处理不会相互干扰的任务 |
| **Cloud** | 在已配置的云端环境中远程运行 | 需要远程执行，或不希望占用当前本地工作区 |

Local 和 Worktree 都在本机运行；环境选项是否可用取决于当前界面和配置。参见官方 [Codex environments](https://learn.chatgpt.com/docs/environments/modes)。

## 4. 能力清单（带个人状态）

状态取值：**在用** / 试过 / 想试 / 暂不需要 / 待标注。

| 能力 | 一句话 | 官方页 | 状态 |
| :--- | :--- | :--- | :--- |
| AGENTS.md | 全局与项目级指令 | [agents-md](https://developers.openai.com/codex/guides/agents-md) | 在用 |
| Memories | Codex 自动积累的记忆 | [memories](https://developers.openai.com/codex/memories) | 在用 |
| Skills | 可复用的任务技能包 | [skills](https://developers.openai.com/codex/skills) | 待标注 |
| Plugins | 插件扩展 | [plugins](https://developers.openai.com/codex/plugins) | 待标注 |
| MCP | 连接外部工具与数据源 | [mcp](https://developers.openai.com/codex/mcp) | 待标注 |
| config.toml | 配置参考 | [config-reference](https://developers.openai.com/codex/config-reference) | 待标注 |
| Hooks | 事件钩子（高级配置） | [config-advanced#hooks](https://developers.openai.com/codex/config-advanced#hooks) | 待标注 |
| Windows sandbox | Windows 下的沙箱行为 | [windows](https://developers.openai.com/codex/windows) | 待标注 |

## 5. 跟进机制（官方最新动态从哪看）

### 最新一期官方周报

- **期次**：2026-07-06 至 2026-07-10
- **核对日期**：2026-07-21
- **官方原文**：[What's new](https://learn.chatgpt.com/docs/whats-new)

#### 本期重点

- **Work mode｜ChatGPT**：适合目标明确、需要汇集文件与 Plugins 上下文并形成可审阅交付物的长任务；Scheduled Tasks 可以让这类工作按计划继续运行。[官方说明](https://learn.chatgpt.com/docs/get-started-with-work)
- **模型选择｜Work、Codex CLI、Codex IDE extension**：官方按复杂度、速度和成本提供不同档位；实际选择应服从任务难度，不必长期固定到单一模型。[官方说明](https://learn.chatgpt.com/docs/models#recommended-models)
- **桌面整合｜macOS、Windows**：Codex 已并入 ChatGPT desktop app，但仍保留独立的软件开发体验；桌面 Codex 支持 diff 行内编辑、侧边栏 PR review、更快的 Computer Use 和多仓库项目。[官方说明](https://learn.chatgpt.com/docs/app)

### 周报后重要增量

- **2026-07-16｜ChatGPT desktop app｜macOS、Windows｜已面向所有计划上线**：桌面应用增加 ChatGPT/Codex 全局切换；ChatGPT 内区分 Chat 与 Work，并统一两者的 Recents、接入 Projects 和跨设备同步云端 Work。Codex 仍是独立视图，其工作流与历史记录不变。[官方发布说明](https://help.openai.com/en/articles/6825453-chatgpt-release-notes)

### 固定信息源

- **What's new（官方周报）**：https://learn.chatgpt.com/docs/whats-new
- **Codex changelog**：https://learn.chatgpt.com/docs/changelog
- **Feature Maturity**：https://developers.openai.com/codex/feature-maturity
- **OpenAI release notes**：https://openai.com/products/release-notes/
- **Codex 文档总览**：https://developers.openai.com/codex

维护方式：每周读取 What's new 页面最前面的期次；出现新一期时替换上述周报导读，同时检查周报截止日之后的 changelog 和 release notes。只记录会改变实际使用方法的重要变化；没有实质变化时不修改本文档。

> 注意：`developers.openai.com/codex/*` 已 308 重定向到 `learn.chatgpt.com/docs/*`（2026-07 观察到），旧链接仍可达；若将来失效，以新域名为准。

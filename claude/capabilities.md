# Claude Code 能力与官方教程导读

这个文档是给我自己看的，用来帮助我理解 Claude Code 官方推出的能力和最新教程：哪些能力存在、和我的工作流是什么关系、我消化到哪了。

定位（与本目录另外两个文件的分工）：

- [`CLAUDE.md`](CLAUDE.md)：全局指令本体，被符号链接到 `~/.claude/CLAUDE.md`。
- [`README.md`](README.md)：全局指令与自动记忆的**管理**说明。
- 本文档：官方**能力与教程**的导读，含个人使用状态。

维护原则：**不做官方文档的镜像或翻译**。官方页面每周更新，镜像必然过时；这里只放"筛选 + 一句话说明 + 入口链接 + 我的使用状态"，内容越薄越活得久。完整索引以 [llms.txt](https://code.claude.com/docs/llms.txt) 为准。

## 1. 使用面与边界

**Claude 的三种工作模式：Chat 用来想，Cowork 用来做事务，Code 用来改仓库。**

| 模式 | 定位 | 什么时候用 | 我的判断标准 |
| :--- | :--- | :--- | :--- |
| **Chat**（对话） | 你全程在场、逐轮来回的思考伙伴 | 问答、学习、研究讨论、写作打磨；问题还在探索中、不涉及批量文件操作 | 不动文件 → Chat |
| **Cowork**（桌面协作） | "描述目标 → 放手执行 → 验收成品"的知识工作代理，可访问本地文件、浏览器和应用 | 有明确交付物且要动文件/工具，但不在 git 仓库工作流里：从一堆输入整出文档或表格、跨来源汇总研究、浏览器事务 | 动文件但不在仓库 → Cowork |
| **Code**（Claude Code） | 进入仓库/文件夹持续工作的 agent 工作区：读改文件、跑命令、管 Git、多轮迭代 | 一切围绕 git 仓库的工作——包括我的 Markdown 知识库维护，不限于写代码 | 在 `C:\workspace` 的仓库里 → Code |

补充两点：

- 三者能力有重叠，边界处按"**是否有明确交付物**"和"**是否在仓库里**"两个问题就能定位。
- 官方说明 Cowork 的底层就是 Claude Code 的 agent 引擎，只是面向非代码的文件与应用工作（参见 [官方选择指南：Cowork vs Chat](https://claude.com/resources/tutorials/choosing-between-claude-cowork-or-chat)）。

**Claude Code 自身的多个入口**（同一账号、同一套全局指令）：

| 入口 | 适合场景 | 官方页 |
| :--- | :--- | :--- |
| CLI（终端） | 主力入口；所有能力最全 | [quickstart](https://code.claude.com/docs/zh-CN/quickstart) |
| 桌面应用（Mac/Windows） | 图形界面、多会话并行管理、定时任务 | [desktop-quickstart](https://code.claude.com/docs/zh-CN/desktop-quickstart) |
| Web（claude.ai/code） | 云端沙箱跑任务，不占本机 | [web-quickstart](https://code.claude.com/docs/zh-CN/web-quickstart) |
| VS Code / JetBrains 插件 | 在 IDE 内结对，diff 审阅体验好 | [vs-code](https://code.claude.com/docs/zh-CN/vs-code) |
| 移动端 + Remote Control | 外出时查看/接续本机会话 | [mobile](https://code.claude.com/docs/zh-CN/mobile) ｜ [remote-control](https://code.claude.com/docs/zh-CN/remote-control) |
| Chrome 集成 | 让 Claude 操作真实浏览器（登录态） | [chrome](https://code.claude.com/docs/zh-CN/chrome) |

## 2. 能力清单（带个人状态）

状态取值：**在用** / 试过 / 想试 / 暂不需要 / 待标注。按需更新，不求全——完整清单见 [features-overview](https://code.claude.com/docs/zh-CN/features-overview)。

### 记忆与指令

| 能力 | 一句话 | 官方页 | 状态 |
| :--- | :--- | :--- | :--- |
| CLAUDE.md / 记忆体系 | 全局与项目级指令的加载规则 | [memory](https://code.claude.com/docs/zh-CN/memory) | 在用 |
| Auto Memory | Claude 自动积累的学习笔记 | [memory](https://code.claude.com/docs/zh-CN/memory) | 在用 |

### 扩展机制

| 能力 | 一句话 | 官方页 | 状态 |
| :--- | :--- | :--- | :--- |
| Skills | 把一类任务的做法打包成可复用技能（`/技能名` 调用） | [skills](https://code.claude.com/docs/zh-CN/skills) | 待标注 |
| Subagents | 派生专职子代理并行干活 | [sub-agents](https://code.claude.com/docs/zh-CN/sub-agents) | 待标注 |
| Hooks | 在关键事件上机械地强制执行规则（比自然语言指令确定） | [hooks-guide](https://code.claude.com/docs/zh-CN/hooks-guide) | 待标注 |
| MCP | 连接外部工具与数据源 | [mcp](https://code.claude.com/docs/zh-CN/mcp) | 待标注 |
| Plugins | 打包分发 skills/hooks/MCP 的插件市场 | [discover-plugins](https://code.claude.com/docs/zh-CN/discover-plugins) | 待标注 |
| 自定义命令 | 把常用 prompt 存成斜杠命令 | [commands](https://code.claude.com/docs/zh-CN/commands) | 待标注 |

### 会话与工作流

| 能力 | 一句话 | 官方页 | 状态 |
| :--- | :--- | :--- | :--- |
| Plan mode | 先出方案审批再动手（Shift+Tab） | [permission-modes](https://code.claude.com/docs/zh-CN/permission-modes) | 在用 |
| /goal | 给定完成条件，长任务一口气跑完 | [goal](https://code.claude.com/docs/zh-CN/goal) | 在用 |
| Checkpointing | 文件改动可回滚（Esc 两下 rewind） | [checkpointing](https://code.claude.com/docs/zh-CN/checkpointing) | 待标注 |
| Worktrees 并行会话 | 多个会话在各自 git worktree 里互不干扰 | [worktrees](https://code.claude.com/docs/zh-CN/worktrees) | 待标注 |
| Agent teams | 编排一组会话协作完成大任务 | [agent-teams](https://code.claude.com/docs/zh-CN/agent-teams) | 待标注 |
| Code review | `/code-review` 审查当前分支或 PR | [code-review](https://code.claude.com/docs/zh-CN/code-review) | 待标注 |
| 定时任务 / Routines | 按 cron 计划自动运行 prompt | [scheduled-tasks](https://code.claude.com/docs/zh-CN/scheduled-tasks) | 待标注 |
| Headless / SDK | 脚本里程序化调用 Claude Code | [headless](https://code.claude.com/docs/zh-CN/headless) | 暂不需要 |
| Sandbox | 沙箱化 Bash，降低权限弹窗与风险 | [sandboxing](https://code.claude.com/docs/zh-CN/sandboxing) | 待标注 |
| Fast mode | Opus 提速输出（/fast 切换） | [fast-mode](https://code.claude.com/docs/zh-CN/fast-mode) | 待标注 |

## 3. 跟进机制（官方最新动态从哪看）

### 最新一期官方周报

- **期次**：2026-07-13 至 2026-07-17（Week 29，v2.1.207 → v2.1.212）
- **核对日期**：2026-07-21
- **官方原文**：[What's New · Week 29](https://code.claude.com/docs/en/whats-new/2026-w29)

#### 本期重点

- **Artifacts 可调用 MCP 连接器｜web**：发布出去的 artifact 页面在被查看时可实时调用查看者自己的 MCP 连接器——dashboard 显示活数据而非构建时的快照；同周还加了公开分享链接和 Team/Enterprise 协作编辑角色。适合把研究数据做成"常看常新"的页面。[官方说明](https://code.claude.com/docs/en/artifacts)
- **Screen reader mode｜CLI**：`claude --ax-screen-reader` 把终端界面换成线性纯文本输出，适配 VoiceOver/NVDA 等读屏器。[官方说明](https://code.claude.com/docs/en/accessibility)
- **`/fork` 语义变化｜CLI**：`/fork` 现在把对话复制到独立后台会话（在 `claude agents` 中有自己的条目）；原来在会话内派生子代理的行为改名为 `/subtask`。老习惯需要更新。
- **其余要点**：超 2 分钟的 MCP 调用自动转后台（`CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` 可调）；"Always allow" 权限规则改存仓库根、跨 worktree 生效；WebSearch 与子代理派生默认每会话上限 200 次，防循环失控。

### 周报后重要增量

- **2026-07-19｜v2.1.215**：`/verify` 和 `/code-review` 不再被 Claude 自动运行，需要显式调用——如果依赖过"改完自动 review"的行为，现在要自己敲命令。
- **2026-07-18｜v2.1.214**：修复 Windows PowerShell 5.1 的权限检查绕过问题——Windows 用户（含本机）建议保持及时升级。
- **2026-07-20｜v2.1.216**：新增 `sandbox.filesystem.disabled` 设置（保留网络管控、跳过文件系统隔离）；修复长会话多秒卡顿等一批问题。

### 固定信息源

- **What's New（官方周报）**：https://code.claude.com/docs/en/whats-new
- **Changelog**：https://code.claude.com/docs/en/changelog
- **Anthropic 官方新闻**：https://www.anthropic.com/news

维护方式：定时任务 `claude-capabilities-weekly-update`（每周一 9:00，桌面应用打开时运行）自动读取 What's New 最前面的期次——出现新一期时整体替换"最新一期官方周报"导读，同时检查周报截止日之后的 changelog 和 Anthropic 新闻并更新"周报后重要增量"；新能力补进第 2 节清单（状态填"待标注"）。只记录会改变实际使用方法的重要变化；没有实质变化时只刷新核对日期。**状态列始终由我手动维护**；文档改动不自动 commit，由我审阅后提交。

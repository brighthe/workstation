# Claude Code 能力与官方教程导读

这个文档是给我自己看的，用来帮助我理解 Claude Code 官方推出的能力和最新教程：哪些能力存在、和我的工作流是什么关系、我消化到哪了。

定位（与本目录另外两个文件的分工）：

- [`CLAUDE.md`](CLAUDE.md)：全局指令本体，被符号链接到 `~/.claude/CLAUDE.md`。
- [`README.md`](README.md)：全局指令与自动记忆的**管理**说明。
- 本文档：官方**能力与教程**的导读，含个人使用状态。

维护原则：**不做官方文档的镜像或翻译**。官方页面每周更新，镜像必然过时；这里只放"筛选 + 一句话说明 + 入口链接 + 我的使用状态"，内容越薄越活得久。完整索引以 [llms.txt](https://code.claude.com/docs/llms.txt) 为准。

**例外**：少数能力的取舍高度依赖我自己的仓库结构，官方页给不出答案，可以额外写一节"用法速记"，让我不必回查原文就能决策。速记只写三样稳定的东西——概念模型、我的选型判断、标准流程；**不抄参数、设置项和版本行为**，那些正是会变的部分，一律留链接。

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
| Worktrees 并行会话 | 多个会话在各自 git worktree 里互不干扰（[用法速记](#用法速记worktrees)） | [worktrees](https://code.claude.com/docs/zh-CN/worktrees) | 想试 |
| Agent teams | 编排一组会话协作完成大任务 | [agent-teams](https://code.claude.com/docs/zh-CN/agent-teams) | 待标注 |
| Code review | `/code-review` 审查当前分支或 PR | [code-review](https://code.claude.com/docs/zh-CN/code-review) | 待标注 |
| 定时任务 / Routines | 按 cron 计划自动运行 prompt | [scheduled-tasks](https://code.claude.com/docs/zh-CN/scheduled-tasks) | 在用 |
| Headless / SDK | 脚本里程序化调用 Claude Code | [headless](https://code.claude.com/docs/zh-CN/headless) | 暂不需要 |
| Sandbox | 沙箱化 Bash，降低权限弹窗与风险 | [sandboxing](https://code.claude.com/docs/zh-CN/sandboxing) | 待标注 |
| Fast mode | Opus 提速输出（/fast 切换） | [fast-mode](https://code.claude.com/docs/zh-CN/fast-mode) | 待标注 |

### 用法速记：Worktrees

**是什么**：git 仓库的第二个工作目录，配一条自己的分支，与主检出**共享同一份 `.git` 和 remote**。所以它隔离的是**文件**，不是历史——worktree 里的提交，主检出立刻可见，不需要 push/fetch；但 worktree 里**未提交**的改动，主检出看不到。

**怎么开**：桌面端新会话那排选择器（`Local` / 仓库 / 分支）里的 `worktree` 复选框；CLI 等价 `claude --worktree <name>`。默认建在 `<仓库根>/.claude/worktrees/<name>/`，分支名 `worktree-<name>`，从远程默认分支切出。

**什么时候用**（这条是我的判断，官方不会替我回答）：

- **用**：`mfleo`、`xihe` 这类代码仓，且确实要并行——一个会话做 feature、另一个修 bug，互不覆盖。
- **不用**：`workstation`、`dut-postdoc`、`heliangos`、`dut-institute-work` 这类配置与知识库仓。改动小、基本单线程，有些还要立刻在真实路径生效；隔离副本的搬运成本高于收益，默认不勾。

**标准循环**（改动的唯一正规回流路径）：

```
worktree 里提交
  → 主检出 git merge worktree-<name>
  → git worktree remove .claude/worktrees/<name>
  → git branch -d worktree-<name>
```

`branch -d` 用小写 d 是有意的：它拒绝删除未合并的分支，等于免费加一道"真的合干净了吗"的检查。**不要用 patch 或复制文件搬改动**——丢历史、没有回退点，而且 `git diff` 默认不含未跟踪文件，新增的文件会被静默漏掉。

**两个已知的坑**：worktree 是全新检出，`.env` 一类被 gitignore 的文件不会带过去（需要就在项目根加 `.worktreeinclude`）；另外 `.claude/worktrees/` 必须进各仓库的 `.gitignore`，否则隔离目录反过来污染主检出的状态。

其余细节——基准分支设置、子代理隔离、自动清理策略、非 git 版本控制的 hook——以 [worktrees 官方页](https://code.claude.com/docs/en/worktrees) 为准，这些改得比较勤。

## 3. 跟进机制（官方最新动态从哪看）

### 三个信息源

粒度不同、内容互有重叠，分工是——**changelog 保证不漏，news 补背景，What's New 事后归档**：

| 源 | 覆盖 | 特点 |
| :--- | :--- | :--- |
| [What's New](https://code.claude.com/docs/en/whats-new) | 每周一期官方精选 | 有解读和示例，但滞后。**索引页最上面永远是最新一期**；期次详情页（如 `/2026-w29`）内容固定、不再变化，盯着它就永远发现不了新一期 |
| [Changelog](https://code.claude.com/docs/en/changelog) | 逐版本 | 最快最全，但混大量 bug fix，需要筛 |
| [Anthropic 新闻](https://www.anthropic.com/news) | 产品与模型公告 | 不限 Claude Code；模型发布这类大事在这里最完整 |

一律读英文页，`/zh-CN/` 翻译会滞后。

### 最新动态

**核对日期：2026-08-06**

三个源汇总后按日期倒序，每条注明出处。只记**会改变我实际使用方法**的变化——新命令、行为变更、破坏性变更、模型变更、Windows 相关、权限与安全；纯 bug 修复、内部重构、与 Claude Code 无关的产品新闻不记。滚动保留约一个月，更早的条目要么已经内化、要么升进第 2 节能力清单。

- **2026-08-06｜v2.1.223**：`/review` 变成 `/code-review` 的别名（`/code-review <level> <pr#>` 审查当前 diff 或 PR，`/code-review ultra` 触发云端深度审查；不带 effort level 时复用上次输入的级别）；同版修复多处权限检测绕过——Bash 命令用 tab/隐藏 Unicode 藏参数、workflow 脚本靠动态 `import()` 逃出沙箱、agent 定义的 `bypassPermissions` 绕过组织禁用策略。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-08-04｜v2.1.222**：**移除 Ultraplan**（Week 15 起的云端计划工具下线）；修复 worktree 隔离会话可对主检出执行破坏性 git 命令的隔离漏洞（隔离范围现覆盖所有会话类型的文件编辑与 Bash）；Remote Control 自动启动改为只能在 user scope 打开，仓库级 `.claude/settings.json` 只能关不能开。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-08-04｜v2.1.221**：新增 sandbox 凭证文件 `mode: "mask"`（Linux/WSL 下沙箱进程读取哨兵副本，真实值仅在代理出口替换；macOS 回退为 `deny`）；后台会话（background sessions）行为变更——现在会 commit + push 保留工作、按需开 draft PR、遵循 CLAUDE.md 里的 git 指令、结束时报告工作去向；`/fork` 派生的会话改为新建独立 worktree，不再共用原会话检出；同版修复 zsh `[[ ]]` 正则条件和 PowerShell 带引号路径的权限检测绕过。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-24｜v2.1.219**：**Claude Opus 5**（`claude-opus-5`）成为默认 Opus 模型（1M context，fast mode $10/$50 per MTok），`/fast` 同时移除 Opus 4.7 支持；嵌套 subagent 默认深度由 1 提到 3（`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` 可关回）；新增 `sandbox.network.strictAllowlist`（沙箱命令直接拒绝非白名单主机，不再弹窗）和 `DirectoryAdded` hook。〔[news](https://www.anthropic.com/news/claude-opus-5)｜[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-22｜v2.1.218**：`/code-review` 改为后台 subagent 运行，审查过程不再占满主对话上下文；同版修复 Windows 路径损坏问题。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-20｜v2.1.216**：新增 `sandbox.filesystem.disabled` 设置（保留网络管控、跳过文件系统隔离）。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-19｜v2.1.215**：`/verify` 和 `/code-review` 不再被 Claude 自动运行，需要显式调用——依赖过"改完自动 review"的话，现在要自己敲命令。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-18｜v2.1.214**：修复 Windows PowerShell 5.1 的权限检查绕过问题——Windows 用户（含本机）建议保持及时升级。〔[changelog](https://code.claude.com/docs/en/changelog)〕
- **2026-07-13~17｜Week 29（v2.1.207–212）**：**`/fork` 语义变化**——现在是把对话复制到独立后台会话（在 `claude agents` 里有自己的条目），原来会话内派生子代理的行为改名 `/subtask`，老习惯需要更新；Artifacts 可调用查看者自己的 MCP 连接器（dashboard 显示活数据而非构建时快照）并支持公开分享链接；`claude --ax-screen-reader` 提供读屏器模式；超 2 分钟的 MCP 调用自动转后台（`CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` 可调）；"Always allow" 权限规则改存仓库根、跨 worktree 生效。〔[Week 29](https://code.claude.com/docs/en/whats-new/2026-w29)〕

维护方式：定时任务 `claude-capabilities-cloud-daily-update`（每天 9:00，Anthropic 云端沙箱运行，消耗 Claude Code 订阅额度）每天读这三个源，把新出现的、会改变使用方法的变化按上述规则追加进"最新动态"并注明出处，同时刷新核对日期；发现有稳定官方入口的新能力时补进第 2 节清单，状态填"待标注"。没有实质变化时只刷新核对日期。取数失败必须显式报错，不得当成"无变化"。**状态列始终由我手动维护**；有实质更新时开 PR（分支 `capabilities/claude-daily-<日期>`），由我审阅后合并，不直接推 `main`。

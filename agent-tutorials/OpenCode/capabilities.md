# OpenCode 能力与官方教程导读

这个文档是给我自己看的，用来帮助我理解 OpenCode 官方推出的能力和最新教程。文档结构：产品定位 → 执行方式 → 能力清单 → 跟进机制。维护原则：不做官方文档镜像，只放「筛选 + 一句话说明 + 入口链接 + 我的使用状态」。

定位（与本目录另外两个文件的分工）：

- [`opencode-guide.md`](opencode-guide.md)：日常使用与接入指南。
- [`../../agent-rules/OpenCode/AGENTS.md`](../../agent-rules/OpenCode/AGENTS.md)：全局规则本体，软链接到 `~/.config/opencode/AGENTS.md`。
- 本文档：官方**能力与教程**的导读，含个人使用状态。

## 1. 产品定位

一句话：**OpenCode 是开源、模型中立的终端原生编程 Agent，TUI + CLI 两种用法，配置与规则全在 `~/.config/opencode/`。**

与 Codex / Claude Code 的关键差异：

- 模型中立：通过 provider 配置接入任意后端，不锁定单一厂商。
- WSL 原生：全局规则/配置在 `~/.config/opencode/`（不在 Windows 用户目录）。
- 规则用 `AGENTS.md`，且缺省回退 `CLAUDE.md`；可用 `opencode.json` 的 `instructions` 字段引用外部规则文件。

## 2. 执行方式

| 执行方式 | 什么时候使用 | 进入方式 |
| :--- | :--- | :--- |
| TUI 会话 | 交互式多轮修改、审查 | 项目目录运行 `opencode` |
| CLI 一次性 | 脚本化、单次任务 | `opencode run "<提示词>"` |
| 计划模式 | 先规划多步骤工作再执行 | 内置 `plan` agent（`/plan`），也可设 `default_agent` |
| Web / Serve | 浏览器或远程会话 | `opencode serve` / `opencode web` |

## 3. 能力清单（带个人状态）

状态取值：**在用** / 试过 / 想试 / 暂不需要 / 待标注。

| 能力 | 一句话 | 官方页 | 状态 |
| :--- | :--- | :--- | :--- |
| AGENTS.md 规则 | 项目级 + 全局 `~/.config/opencode/AGENTS.md` | [rules](https://opencode.ai/docs/rules/) | 在用 |
| opencode.json 配置 | 模型/provider/权限/MCP/插件等，多层合并 | [config](https://opencode.ai/docs/config/) | 在用 |
| instructions 引用 | 引用外部规则文件（glob/URL） | [config#instructions](https://opencode.ai/docs/config/#instructions) | 待标注 |
| Agents / Subagents | 自定义 agent 与子代理分工 | [agents](https://opencode.ai/docs/agents/) | 待标注 |
| Skills | 可复用技能包 | [skills](https://opencode.ai/docs/skills/) | 待标注 |
| MCP servers | 连接外部工具与数据源 | [mcp-servers](https://opencode.ai/docs/mcp-servers/) | 待标注 |
| Plugins | 插件扩展工具/钩子 | [plugins](https://opencode.ai/docs/plugins/) | 待标注 |
| Permissions | 工具操作审批（ask/deny） | [permissions](https://opencode.ai/docs/permissions/) | 待标注 |
| Commands | 自定义斜杠命令 | [commands](https://opencode.ai/docs/commands/) | 待标注 |
| Providers | 多模型 provider 接入 | [providers](https://opencode.ai/docs/providers/) | 待标注 |
| ACP Support | Agent Client Protocol 接入 | [acp](https://opencode.ai/docs/acp/) | 待标注 |
| LSP Servers | 语言服务诊断 | [lsp](https://opencode.ai/docs/lsp/) | 待标注 |
| Share | 会话分享 | [share](https://opencode.ai/docs/share/) | 待标注 |

## 4. 跟进机制（官方最新动态从哪看）

- **官方文档**：https://opencode.ai/docs
- **更新日志**：https://github.com/anomalyco/opencode/releases
- **仓库**：https://github.com/anomalyco/opencode

维护方式：不定期核对官方 docs 与 release 页；出现会改变实际使用方法的新能力时补进第 3 节清单，状态统一填「待标注」。没有实质变化时不修改本文档。**现有状态列始终由我手动维护**；文档改动不自动 commit/push。

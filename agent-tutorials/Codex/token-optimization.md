# Codex 省 Token 优化记录

> - **整理日期**：2026-08-09
> - **适用环境**：Windows 11、Codex Desktop / CLI / VS Code、DeepSeek API 双模式

本文记录 2026-08 期间针对"Codex token 消耗过快、额度很快用完"问题的分析与落地变更，作为后续维护依据。

## 1. 背景与目标

- 现象：官方订阅额度与 DeepSeek API 用量消耗偏快。
- 目标：在保证复杂任务质量的前提下，降低 token 消耗，延长额度可用时间。
- 原则：官方订阅侧保持稳定；DeepSeek 侧按量付费、以低成本例行任务为主。

## 2. 关键认识：token 花在哪里

| 来源 | 说明 |
| :--- | :--- |
| 推理输出（reasoning） | 推理按输出 token 计费，最贵；Terra 输出约 300 credits/百万，输入仅 50 |
| 长会话输入 | 每轮重发累积上下文，输入占大头（官方长任务示例：25 小时约 1300 万 token，其中输入约 1070 万） |
| 子代理（subagents） | 每个子代理独立做模型与工具调用，比单代理更耗 |
| 插件 / MCP | 每个启用的插件与 MCP server 每轮注入工具定义，占用上下文 |

官方参考：
- Pricing / 用量：https://learn.chatgpt.com/docs/pricing
- 模型选择：https://learn.chatgpt.com/docs/models
- 子代理：https://learn.chatgpt.com/docs/agent-configuration/subagents

## 3. 已落地变更

| 日期 | 变更 | 文件 | 效果 |
| :--- | :--- | :--- | :--- |
| 2026-08-07 | 删除 `model_reasoning_effort = "high"` | `C:\Users\Administrator\.codex\config.toml` | 官方模式（Desktop/CLI/IDE）恢复自动选档 |
| 2026-08-07 | 删除 `model_reasoning_effort = "high"` | `C:\Users\Administrator\.codex-deepseek\config.toml` | DeepSeek 解除固定档，会话内手动 `/reasoning` 切换 |
| 2026-08-09 | 新建自定义 agent `deep-task`（`gpt-5.6-sol` + `high`） | `C:\Users\Administrator\.codex\agents\deep-task.toml` | 复杂任务可自动/手动委托，质量不失守 |
| 2026-08-09 | AGENTS.md 追加 `Complex Task Delegation` 规则 | 全局 AGENTS.md（硬链接至 `~/.codex`） | 复杂任务自动委托 `deep-task`（半自动） |
| 2026-08-09 | 删除定时任务 `codex-capabilities-daily-update` | 桌面应用 Scheduled | 消除每天 9:00 的固定消耗（周报每周才更新一次） |

## 4. 保持现状的决定

- **插件**：保持官方默认配置（10 个插件 + node_repl MCP），不精简。代价：每轮上下文稍大；功能完整优先。
- **DeepSeek 默认档**：不修改 models.json 的 `default_reasoning_level`（当前为 `high`），由用户在会话内手动 `/reasoning` 切换。

## 5. 文件链接与备份

- `agent-rules\Codex\config.toml` → `C:\Users\Administrator\.codex\config.toml`（硬链接）
- `agent-rules\Codex\config-deepseek.toml` → `C:\Users\Administrator\.codex-deepseek\config.toml`（硬链接）
- `agent-rules\Codex\deep-task.toml` → `C:\Users\Administrator\.codex\agents\deep-task.toml`（硬链接）
- 修改前备份：`C:\Users\Administrator\.codex\config.toml.bak-20260807-215057`、`C:\Users\Administrator\.codex-deepseek\config.toml.bak-20260807-215057`

## 6. 使用与维护

- 官方模式：不固定档位即自动选档；需要更省可临时调低，需要深度可临时调高。
- DeepSeek 模式：会话内 `/reasoning low|high|max` 手动切换；无自动按任务选档。
- 复杂任务：直接说"用 deep-task 处理"，或依赖 AGENTS.md 自动委托。
- 监控：CLI `/status`、https://chatgpt.com/codex/settings/usage、DeepSeek 开放平台控制台。
- 恢复：如需恢复固定 `high`，用对应 `.bak` 文件覆盖即可。

## 7. 后续可选优化（未执行）

- 精简官方侧插件（需重新评估使用习惯）。
- 将 `deep-task` 复制到 `C:\Users\Administrator\.codex-deepseek\agents\` 供 DeepSeek 模式使用（模型需改为 DeepSeek 侧配置）。
- 例行/批量任务手动切 `gpt-5.6-luna`。
- 长会话拆分为短会话（一个任务一个会话）。

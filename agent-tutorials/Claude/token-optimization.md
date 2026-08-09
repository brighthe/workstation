# Claude Code 省 Token 优化记录

> - **整理日期**：2026-08-09
> - **适用环境**：Windows 11、Claude Code CLI（Windows / WSL）、官方订阅 + DeepSeek API 双模式
> - **对应文档**：Codex 侧见 [`token-optimization.md`](../Codex/token-optimization.md)

本文记录 2026-08 期间针对"Claude Code token 用量"的分析与落地变更，作为后续维护依据。方案基于 [Claude Code 官方文档](https://code.claude.com/docs/en/) 查证，避免凭空猜测。

## 1. 背景与目标

- 现象：官方订阅额度消耗偏快，需要明确 token 花在哪里、如何控制。
- 目标：在保证复杂任务质量的前提下，降低 token 消耗，延长额度可用时间。
- 原则：官方订阅侧保持稳定；DeepSeek 侧按量付费、以低成本例行任务为主。

## 2. 关键认识：token 花在哪里

| 来源 | 说明 |
| :--- | :--- |
| 输入（input） | 每轮重发累积上下文，长会话占大头；缓存命中部分按 ~10% 费率计（cache read） |
| 输出（output，含 thinking） | 按输出 token 计费，最贵；effort 档位决定思考预算 |
| 缓存写入（cache write） | 首次写入按全价计，供后续轮次命中 |
| 上下文增长 | 系统提示、CLAUDE.md、工具结果、会话历史逐轮累积，触发缓存整段失效重算 |

官方参考：
- Settings：https://code.claude.com/docs/en/settings
- Model config / Effort levels：https://code.claude.com/docs/en/model-config

## 3. 关键认识：两个"自动"的真实语义（与 Codex 的差异）

| 维度 | Codex 官方模式 | Claude Code |
| :--- | :--- | :--- |
| 不设档位时的行为 | 真正自动选档——按任务复杂度自适应 | 固定在模型默认档（`high`），不随任务变化 |
| "auto" 的语义 | 不配置 `model_reasoning_effort` = 自动调整 | `/effort auto` 仅复位到模型默认档 |
| 档位内 | — | adaptive reasoning：每步由模型自行决定思考多少 |
| 手动切换 | `/reasoning low\|high\|max` | `/effort low\|medium\|high\|xhigh` |

结论：Claude Code 无"按任务自动选模型/选档位"机制；模型 `default` = 账号固定推荐模型（Pro → Sonnet 5），effort 默认档按模型固定。官方建议 "Start with the defaults, then reach for the dials"——默认配置 + 需要时手动拧旋钮。

## 4. 已落地变更

| 日期 | 变更 | 文件 | 效果 |
| :--- | :--- | :--- | :--- |
| 2026-08-09 | 删除 `model: haiku`（选项 A） | `agent-rules/Claude/settings.json`（Windows 全局，硬链接至 `~/.claude/settings.json`）、`settings-wsl.json`（WSL 全局，symlink 至 `~/.claude/settings.json`） | 恢复账号推荐模型（Pro → Sonnet 5），不再锁定最低档 |
| 2026-08-09 | 删除 `effortLevel: high` | `settings-wsl.json` | 恢复模型默认档 `high`，档内自适应 |
| 2026-08-09 | 新增 `autoCompactWindow: 200000` | 两份 settings.json | 接近 200k 上下文时自动压缩，控制输入 token 增长 |
| 2026-08-09 | 新增 `cleanupPeriodDays: 14` | 两份 settings.json | 旧会话/文件 14 天后清理（默认 30 天） |
| 2026-08-09 | 删除 `CLAUDE_CODE_EFFORT_LEVEL = "max"` | `agent-rules/Claude/claude_ds_func.sh`（WSL symlink 至 `~/.claude_ds_func`）、`profile-pwsh7.ps1`、`profile-ps51.ps1`（硬链接至两个 PowerShell profile） | DeepSeek 模式解除固定 max，回落到模型默认档 |
| 2026-08-09 | API key 脱敏 | `claude_ds_func.sh` | 不硬编码 `sk-...`，运行时从 Windows 用户环境变量 `DEEPSEEK_API_KEY` 读取 |
| 2026-08-09 | statusline 增加 cache 命中率指标 | `C:\Users\Administrator\.claude\statusline.ps1`（独立文件，不镜像） | 本地渲染，零 token 开销；显示 `cache N% hit` |
| 2026-08-09 | 清理 settings.local.json 乱码行（25→23 条 allow） | 项目级 `.claude/settings.local.json`（不镜像，git 忽略） | 修复损坏规则 |
| 2026-08-09 | 恢复 PreToolUse 钩子 | `claude/hooks/git-origin-context.ps1`（从 `a8f9796^` 恢复） | 修复 settings.json 中 hook 断链（重构时被删） |

## 5. 保持现状的决定

- **模型**：不设置 `model` 键，使用账号推荐模型（Pro → Sonnet 5）。无按任务自动选模型机制；需要时会话内 `/model` 临时切换。
- **Effort**：不设置任何档位 = 模型默认档；`/effort auto` 可随时复位。需要更省临时 `/effort low`，复杂任务临时调高。
- **statusline / notify.ps1**：不镜像到 `agent-rules/Claude/`——只保留策略与配置，不留实现细节（用户决定）。

## 6. 文件链接与备份

- 镜像架构详见 [`agent-rules/Claude/README.md`](../../agent-rules/Claude/README.md)（硬链接 ×4 + WSL symlink ×2；statusline/notify 不镜像）。
- 修改前备份：`~/.claude_ds_func.bak-20260809`、`~/.claude/settings.json.bak-20260809`（WSL，**后者含明文 key，2026-08-09 已删除**）；Windows 侧 `settings.json.bak-20260809`、两个 `profile.bak-20260809`。

## 7. 使用与维护

- 官方模式：默认配置即可；省 token 临时 `/effort low`，复杂任务临时调高后 `/effort auto` 复位。
- DeepSeek 模式：`claude-ds` 启动，默认档；会话内 `/effort` 切换。
- 监控：statusline cache 命中率（命中率高 = 缓存生效，省钱）；`/status` 查看用量。
- 会话纪律：长会话及时 `/compact` / `/clear`（切换模型或档位会整段缓存失效，先做完再切）。
- 升级后补键：`crossSessionInbound` 需 Claude Code ≥ 2.1.224（当前 WSL 2.1.222），升级后补入两份 settings.json。

## 8. 后续可选优化（未执行）

- WSL 侧迁移 `hooks` / `statusLine`（命令为 Windows 风格，跨环境需适配 `powershell.exe` 与路径转换）。
- 长会话拆分为短会话（一个任务一个会话，控制输入 token 累积）。
- statusline 增加更多指标（如 output/thinking token 占比）。
- 评估 `autoCompactWindow` 与 `cleanupPeriodDays` 的实际效果后微调阈值。

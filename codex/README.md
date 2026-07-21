# Codex 全局记忆与指令管理说明

这个文档是给我自己看的，用来帮助我理解和管理 Codex 的“全局指令”和“Memories”。

核心分工：

- **AGENTS.md 管规则**：放 Codex 应长期遵守的规则和工作约束。
- **Memories 管偏好和背景**：由 Codex 自动生成和维护，用来保存偏好、背景和稳定经验。

一句话：**AGENTS.md 主动维护，Memories 自动沉淀。**

## 实际文件链接

- [workstation 中同步的 AGENTS.md](AGENTS.md)
  仓库内路径：`codex/AGENTS.md`
  LAPTOP-A51RSRUJ：`C:\workspace\workstation\codex\AGENTS.md`

- Codex 全局指令文件
  通用位置：`~/.codex/AGENTS.md`
  Windows 通用示例：`C:\Users\<用户名>\.codex\AGENTS.md`
  LAPTOP-A51RSRUJ：`C:\Users\Lenovo\.codex\AGENTS.md`
  当前状态：符号链接，指向本仓库的 `C:\workspace\workstation\codex\AGENTS.md`。

- Codex Memories 目录
  通用位置：`~/.codex/memories/`
  Windows 通用示例：`C:\Users\<用户名>\.codex\memories\`
  LAPTOP-A51RSRUJ：`C:\Users\Lenovo\.codex\memories\`

> 推荐做法：在每台设备上，把 `~/.codex/AGENTS.md` 设置为指向本设备 `workstation/codex/AGENTS.md` 的符号链接。符号链接绑定路径，适合 Git 跨设备同步；不要使用硬链接，避免 Git 更新或编辑器原子保存导致链接静默失效。
>
> 注意：官方文档说明，`~/.codex/memories/` 是 Codex 生成和维护的记忆文件目录。可以检查它，但不建议把手动编辑这里作为主要控制方式，也不建议把它链接到 Git 仓库做跨设备同步。

## 官方文档链接

- [OpenAI Codex 官方文档](https://developers.openai.com/codex)
- [AGENTS.md 官方说明](https://developers.openai.com/codex/guides/agents-md)
- [Memories 官方说明](https://developers.openai.com/codex/memories)
- [config.toml / 配置参考](https://developers.openai.com/codex/config-reference)
- [Hooks / 高级配置](https://developers.openai.com/codex/config-advanced#hooks)

> 本 README 只管"指令与记忆"。Skills、Plugins、MCP、Windows sandbox 等**能力类**入口、ChatGPT 与 Codex 的使用边界，以及官方最新动态的跟进，统一放在 [capabilities.md](capabilities.md)。

## AGENTS.md 的存放位置与适用范围

| 范围 | 位置 | 用途 |
| :--- | :--- | :--- |
| 用户级全局指令 | `~/.codex/AGENTS.md` | 所有 Codex 会话都应遵守的个人偏好和通用约束；当前用的就是这一层 |
| 仓库级指令 | `./AGENTS.md` | 某个仓库长期稳定的项目背景、文档风格、常用命令和协作约定 |
| 子目录级指令 | `./path/to/AGENTS.md` | 只对该子目录及其下文件成立的更具体规则 |

要点：

- 全局 `AGENTS.md` 只放跨仓库都成立的个人规则。
- 仓库特有流程应放在对应仓库的 `AGENTS.md`，例如 `C:\workspace\dut-postdoc\AGENTS.md`。
- 子目录规则适合 `docs/`、`src/`、`examples/` 这类职责差异明显的目录。
- 如果规则需要机械、确定地强制执行，优先考虑 hooks、config 或权限设置，而不是只写进自然语言指令。

## 当前 AGENTS.md 内容中文说明

点开即是当前维护的英文本体：[`codex/AGENTS.md`](AGENTS.md)（已由符号链接映射到 `~/.codex/AGENTS.md`）。下面是按标题、条目和顺序完整对应的中文翻译，方便阅读。英文正文只在 `codex/AGENTS.md` 中维护；本译文不独立增加、删减或调整规则，正文改动后必须在同一轮同步。

```md
# Codex 全局指令

## 语言

- 默认用中文回答，除非我明确要求使用其他语言。
- 技术术语、路径、命令、配置键、API 名称和产品名称保留英文。

## OpenAI 和 Codex 文档

- 当我询问 Codex 本身的问题时，优先查阅 OpenAI 官方 Codex 文档：
  https://developers.openai.com/codex
- 官方 OpenAI 文档优先于记忆。如果文档没有覆盖该问题，要明确说明。

## Windows Git 和 shell

- 在 Windows 上进行 Git 和 SSH 操作时，使用 PowerShell 和 Windows 原生 Git/OpenSSH。
- 除非我明确要求，不要在我的 Windows 仓库中使用 Cygwin、MSYS、Git Bash 或 WSL 的 Git/SSH。
- 如果 Windows 上 GitHub SSH 表现异常，检查 `HOME` 是否指向当前 Windows 用户目录，而不是 `/home/<user>` 这类 POSIX 风格路径。

## 交互模式

- 在新的非简单会话或任务开始时，先简短建议使用普通模式、计划模式或目标。
- 如果推荐的模式需要 UI 切换，而我不能直接替你切换，就请你先切换后再继续。
- 问答、解释、只读检查和小澄清使用普通模式。
- 涉及文件编辑、配置修改、安装、commit、push 或多步骤排障时，建议使用计划模式。
- 只有长期持续推进、需要跨多轮或多会话追踪的事情，才建议使用目标。

## Git 工作流卫生

- 提交前先检查工作区，只暂存与当前任务相关的文件。
- 除非我明确要求，不要使用 `git add -A` 这类宽泛暂存命令。
- 除非我明确要求，不要 commit 或 push。
```

> 已配置确定性提醒：[`.codex/hooks.json`](../.codex/hooks.json) 的 `PostToolUse` hook 会在英文本体被修改后提醒同步本节。hook 负责防止遗漏，最终仍需在同一轮逐项核对译文。

## 不应放入全局记忆的内容

不要把下面内容放入 `AGENTS.md`、Memories 或本仓库：

- SSH 私钥
- API key
- access token
- cookie
- 密码
- 一次性命令输出
- 只对某个项目成立的规则
- 需要放在项目级 `AGENTS.md` 的仓库特有流程
- 需要确定性强制的规则；这类约束应考虑 hooks、config 或权限机制

## 推荐维护方式

- `AGENTS.md` 放在 workstation 仓库中同步，并由本机 Codex 全局指令文件链接过去。
- Memories 保持由 Codex 自动生成和维护，不做 Git 同步，不做符号链接。
- 本目录三个文件的分工：`AGENTS.md` 是被符号链接的指令本体；本 README 只做指令与记忆的管理说明和链接导航；[capabilities.md](capabilities.md) 负责官方能力与最新教程的导读。
- 如果某个流程很长，例如 Git/SSH 排障，可以单独写成文档，再从这里链接过去。

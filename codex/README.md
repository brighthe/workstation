# Codex 全局记忆与指令管理说明

这个文档是给我自己看的，用来帮助我理解和管理 Codex 的“全局指令”和“Memories”。

核心分工：

- **AGENTS.md 管规则**：放 Codex 应长期遵守的规则和工作约束。
- **Memories 管偏好和背景**：由 Codex 自动生成和维护，用来保存偏好、背景和稳定经验。

一句话：**AGENTS.md 主动维护，Memories 自动沉淀。**

## 实际文件链接

- [workstation 中同步的 AGENTS.md](AGENTS.md)
  路径：`C:\workspace\workstation\codex\AGENTS.md`

- [Codex 全局指令文件](file:///C:/Users/Lenovo/.codex/AGENTS.md)
  路径：`C:\Users\Lenovo\.codex\AGENTS.md`
  当前状态：已通过符号链接指向 `C:\workspace\workstation\codex\AGENTS.md`。符号链接绑定路径，适合 Git 跨设备同步；不要使用硬链接，避免 Git 更新或编辑器原子保存导致链接静默失效。

- [Codex Memories 目录](file:///C:/Users/Lenovo/.codex/memories/)
  路径：`C:\Users\Lenovo\.codex\memories`

> 注意：官方文档说明，`~/.codex/memories/` 是 Codex 生成和维护的记忆文件目录。可以检查它，但不建议把手动编辑这里作为主要控制方式，也不建议把它链接到 Git 仓库做跨设备同步。

## 官方文档链接

- [OpenAI Codex 官方文档](https://developers.openai.com/codex)
- [AGENTS.md 官方说明](https://developers.openai.com/codex/guides/agents-md)
- [Memories 官方说明](https://developers.openai.com/codex/memories)
- [Windows sandbox 官方说明](https://developers.openai.com/codex/windows)

## 当前 AGENTS.md 内容中文说明

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

- 在新会话或新的非简单任务开始时，先简短建议使用普通模式、计划模式或目标。
- 如果推荐的模式需要 UI 切换，而我不能直接替你切换，就请你先切换后再继续。
- 问答、解释、只读检查和小澄清使用普通模式。
- 涉及文件编辑、配置修改、安装、commit、push 或多步骤排障时，建议使用计划模式。
- 只有长期持续推进、需要跨多轮或多会话追踪的事情，才建议使用目标。

## Git 工作流卫生

- 提交前先检查工作区，只暂存与当前任务相关的文件。
- 除非我明确要求，不要使用 `git add -A` 这类宽泛暂存命令。
- 除非我明确要求，不要 commit 或 push。
```

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

## 推荐维护方式

- `AGENTS.md` 放在 workstation 仓库中同步，并由本机 Codex 全局指令文件链接过去。
- Memories 保持由 Codex 自动生成和维护，不做 Git 同步，不做符号链接。
- 这个 README 只做中文说明、链接导航和当前定稿记录。
- 如果某个流程很长，例如 Git/SSH 排障，可以单独写成文档，再从这里链接过去。

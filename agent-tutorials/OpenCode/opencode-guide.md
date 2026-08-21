# OpenCode 使用指南

> - **整理日期**：2026-08-20
> - **适用环境**：WSL Ubuntu（OpenCode 在 WSL 下提供完整 Linux 工具链调用）

OpenCode 是开源、模型中立（Model-Agnostic）的终端原生编程 Agent，提供 TUI 与 CLI（`opencode run`）两种用法。它不绑定单一模型厂商，可通过 provider 配置接入 Anthropic、OpenAI、DeepSeek 等任意后端。本指南只覆盖接入与日常使用；模型/provider 的具体配置以官方 [Config](https://opencode.ai/docs/config/) 为准。

> [!IMPORTANT]
> OpenCode 的全局规则与配置都在 WSL 的 `~/.config/opencode/` 下（`AGENTS.md` 与 `opencode.json`），与 Codex/Claude 的 Windows 侧路径不同，见 [agent-rules/OpenCode/README.md](../../agent-rules/OpenCode/README.md)。

---

## 1. 入口选择

| 入口 | 适合场景 | 命令 |
| :--- | :--- | :--- |
| TUI | 交互式会话、多轮修改与审查 | 在项目目录运行 `opencode` |
| CLI | 脚本化、一次性任务 | `opencode run "<提示词>"` |
| Web / Serve | 浏览器或远程会话 | `opencode serve` 或 `opencode web` |

默认在 WSL 中运行；进入目标仓库后启动，让它自动加载该仓库的项目级 `AGENTS.md`。

---

## 2. 规则与配置分层

| 层 | 位置 | 说明 |
| :--- | :--- | :--- |
| 项目规则 | 项目根 `AGENTS.md` | 优先加载；缺省回退同目录 `CLAUDE.md` |
| 全局规则 | `~/.config/opencode/AGENTS.md` | 所有会话生效（指向 workstation 仓库维护源） |
| 全局配置 | `~/.config/opencode/opencode.json` | 模型、provider、权限、MCP、插件等 |
| 项目配置 | 项目根 `opencode.json` | 覆盖全局配置的冲突键 |

引用外部规则文件：在 `opencode.json` 中写 `"instructions": ["CONTRIBUTING.md", ".cursor/rules/*.md"]`，会与 `AGENTS.md` 合并加载。

---

## 3. 常用命令

| 命令 | 作用 |
| :--- | :--- |
| `opencode` | 启动 TUI |
| `opencode run "<提示词>"` | 非交互式执行一次任务 |
| `/init` | 生成/改进当前项目的 `AGENTS.md` |
| `/plan` | 切换到计划模式（内置 `plan` agent） |
| `/share` | 分享会话（默认手动模式） |
| `opencode debug config` | 打印合并后的生效配置（排查配置问题） |

---

## 4. 权限与安全

- OpenCode 默认**放行所有工具操作**。如需对文件编辑、bash 等加确认，在 `opencode.json` 配置：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "ask",
    "bash": "ask"
  }
}
```

- API Key 通过 provider 的环境变量或 `{env:...}` 变量引用提供，绝不写入仓库；不把 `sk-...` 等凭据提交或粘贴进文档。

---

## 5. 官方参考

- [OpenCode 文档总览](https://opencode.ai/docs)
- [CLI](https://opencode.ai/docs/cli/) · [TUI](https://opencode.ai/docs/tui/)
- [Rules](https://opencode.ai/docs/rules/) · [Config](https://opencode.ai/docs/config/)
- [Providers](https://opencode.ai/docs/providers/) · [Permissions](https://opencode.ai/docs/permissions/)

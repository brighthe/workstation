# OpenCode 使用指南

> - **整理日期**：2026-08-20（2026-08-22 更新双端部署与订阅矩阵）
> - **适用环境**：WSL Ubuntu（TUI / compute 算力层）+ Windows 原生（Desktop / authoring 文档层）双轨部署

OpenCode 是开源、模型中立（Model-Agnostic）的编程 Agent，提供终端 TUI、桌面 Desktop 与命令行 CLI（`opencode run`）等多种用法。它不绑定单一模型厂商，可通过 provider 配置接入 Anthropic、OpenAI、DeepSeek、阿里云百炼、智谱等任意后端。本指南覆盖双端接入、订阅矩阵与日常使用；模型/provider 的具体配置以官方 [Config](https://opencode.ai/docs/config/) 为准。

> [!IMPORTANT]
> OpenCode 全局规则与配置分属双端：
> - **WSL 端（TUI）**：位于 `~/.config/opencode/`（`AGENTS.md` 软链接至 workstation 维护源）；
> - **Windows 端（Desktop）**：位于 `%USERPROFILE%\.config\opencode\`（`AGENTS.md` 复制件同步）。
> 详细分工与约束见 [agent-rules/OpenCode/README.md](../../agent-rules/OpenCode/README.md)。

---

## 1. 入口与双轨分工

| 入口形态 | 运行环境 | 管理范围与适合场景 | 启动方式 |
| :--- | :--- | :--- | :--- |
| **TUI (终端版)** | **WSL (Ubuntu)** | **`compute` 仓库**（`fealpy`、`soptx`、`mfem` 等代码计算、conda 工具链） | 终端运行 `opencode` |
| **Desktop (桌面版)** | **Windows 原生** | **`authoring` 仓库**（`workstation`、`dut-postdoc`、LaTeX 论文、文档与图件交互） | 启动 OpenCode 桌面图标 |
| **CLI (单次执行)** | WSL / Windows | 脚本化、单次自动化任务 | `opencode run "<提示词>"` |
| **Web / Serve** | WSL / Windows | 浏览器访问或远程会话 | `opencode serve` 或 `opencode web` |

> 强制约定：Windows Desktop 保持直连 Windows 本地后端，不连 WSL server（避免跨文件系统与工具链错位）；代码仓库永远走 WSL TUI。

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

## 3. 模型与官方订阅接入矩阵

OpenCode 支持三大类接入形态：**OAuth 账号直连免 API 费**、**开发者包月 Plan 额度抵扣** 与 **按量计费 API 直连**。

### 3.1 国内主流大模型

| 模型系列 (Model) | 个人 C 端会员能否直连？ | OpenCode 官方支持的订阅制与接入方式 |
| :--- | :--- | :--- |
| **`DeepSeek`**<br>*(深度求索)* | ❌ **无官方包月订阅**<br>*(官方仅提供按量充值)* | ① **DeepSeek 官方 API Key**（按量充值直连）<br>② **阿里云百炼 Token Plan 订阅**（托管调用） |
| **`千问` (Qwen)**<br>*(阿里云百炼)* | ❌ **不支持通义网页 VIP**<br>*(C 端会员不含 API)* | **阿里云百炼 Token Plan / Coding Plan 开发者订阅**<br>*(需配合业务空间专属 Base URL + 专属 Key 接入，按月额度抵扣)* |
| **`智谱` (GLM)**<br>*(智谱华章 / BigModel)* | ❌ **不支持清言网页 VIP**<br>*(C 端会员不含 API)* | **智谱开放平台 Coding Plan / 开发者资源包订阅**<br>*(OpenCode 原生内置，填入 Key 自动从订阅包抵扣，GLM-4-Flash 甚至免费)* |

### 3.2 海外主力与探索模型

| 模型系列 (Model) | 个人 C 端会员能否直连？ | OpenCode 官方支持的订阅制与接入方式 |
| :--- | :--- | :--- |
| **`Grok`**<br>*(xAI)* | ✔️ **支持个人订阅直连** | **OAuth 网页授权登录** 直接绑定并消耗 **SuperGrok / X Premium 订阅**，亦支持 xAI API Key |
| **`GPT`**<br>*(OpenAI)* | ❌ **不支持直连**<br>*(Plus/Pro 仅限官方 Codex CLI 或网页端)* | **OpenAI API Key**（按量付费） 或通过 **GitHub Copilot 订阅直连** |
| **`Claude`**<br>*(Anthropic)* | ❌ **不支持直连**<br>*(Pro/Max 仅限官方 Claude Code CLI 或网页端)* | **Anthropic API Key**（按量付费） 或通过 **GitHub Copilot 订阅直连** |
| **`Gemini`**<br>*(Google)* | ❌ **不支持个人订阅直连**<br>*(Gemini Advanced 仅限官方端)* | **Google AI Studio API Key** 或 **Vertex AI** |

### 3.3 阿里云百炼 Token Plan 实战配置（Anthropic 驱动）

在 `~/.config/opencode/opencode.jsonc`（WSL）与 `%USERPROFILE%\.config\opencode\opencode.jsonc`（Windows）中：

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "bailian-token-plan": {
      "npm": "@ai-sdk/anthropic",
      "name": "Alibaba Token Plan (Anthropic)",
      "options": {
        "baseURL": "https://ws-<workspace-id>.cn-beijing.maas.aliyuncs.com/apps/anthropic/v1",
        "apiKey": "{env:DASHSCOPE_API_KEY}"
      },
      "models": {
        "qwen-max-latest": {
          "name": "Qwen Max (Latest 旗舰)",
          "attachment": true,
          "reasoning": true,
          "limit": { "context": 131072, "output": 8192 }
        },
        "qwen-plus-latest": {
          "name": "Qwen Plus (Latest 均衡)",
          "attachment": true,
          "reasoning": true,
          "limit": { "context": 131072, "output": 8192 }
        }
      }
    }
  }
}
```

> **注意**：
> - 专属 Base URL 必须从阿里云百炼控制台复制（Anthropic 栏目），末尾需对齐 `/v1`。
> - `limit` 显式设置 `context: 131072`，防止 UI 回退显示 `0` 上下文。

---

## 4. 常用命令

| 命令 | 作用 |
| :--- | :--- |
| `opencode` | 启动 TUI |
| `opencode run "<提示词>"` | 非交互式执行一次任务 |
| `/init` | 生成/改进当前项目的 `AGENTS.md` |
| `/plan` | 切换到计划模式（内置 `plan` agent） |
| `/share` | 分享会话（默认手动模式） |
| `opencode debug config` | 打印合并后的生效配置（排查配置问题） |

---

## 5. 权限与安全

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

## 6. 官方参考

- [OpenCode 文档总览](https://opencode.ai/docs)
- [CLI](https://opencode.ai/docs/cli/) · [TUI](https://opencode.ai/docs/tui/)
- [Rules](https://opencode.ai/docs/rules/) · [Config](https://opencode.ai/docs/config/)
- [Providers](https://opencode.ai/docs/providers/) · [Permissions](https://opencode.ai/docs/permissions/)


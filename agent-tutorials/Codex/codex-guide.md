# OpenAI Codex 使用指南

> - **更新日期**：2026-08-14
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Codex Desktop、VS Code 的 Codex 扩展
> - **认证方式**：使用 ChatGPT 账号登录官方 Codex 服务

本文介绍日常使用 Codex 的三个入口：Codex Desktop、Codex CLI 和 VS Code 的 Codex IDE 扩展。三者都使用同一套官方 Codex 能力；不配置第三方 `model_provider`，也不在环境变量或配置文件中保存 API Key。

> [!IMPORTANT]
> ChatGPT 登录和 OpenAI API Key 是两种不同认证方式。本指南采用 ChatGPT 登录；它不需要 `OPENAI_API_KEY`。如需使用 DeepSeek，请直接使用其独立的 Harness，而不是把 Codex 转发到 DeepSeek API。

---

## 1. 入口选择

| 入口 | 适合场景 | 推荐操作 |
| :--- | :--- | :--- |
| Codex Desktop | 长时间任务、跨项目协作、桌面工作流 | 打开 Desktop，使用 ChatGPT 账号登录并创建任务。 |
| Codex CLI | 在终端中检查、修改与自动化代码 | 在项目目录运行 `codex`，首次运行时选择 ChatGPT 登录。 |
| VS Code IDE 扩展 | 结合当前编辑器文件、选区和差异进行本地开发 | 在扩展侧栏登录 ChatGPT，创建新对话。 |

---

## 2. 通用原则

1. 使用 ChatGPT 账号登录官方 Codex；不要设置 `OPENAI_API_KEY` 或 `DEEPSEEK_API_KEY` 来驱动 Codex。
2. 不使用 `model_provider`、`[model_providers.*]`、`model_catalog_json` 或第三方模型目录。
3. 模型、推理强度、项目可信状态等本地偏好可以保留在 `config.toml`，但它们不应包含密钥。
4. 不要将 `sk-...`、访问令牌或认证文件提交到 Git 仓库、粘贴到截图或写入教程。

---

## 3. Codex Desktop

Codex Desktop 适合需要较长上下文、多个任务或桌面端工作流的场景。

1. 打开 Codex Desktop。
2. 使用与 ChatGPT 订阅关联的账号登录。
3. 打开或创建任务，选择本地工作或云端工作模式。

Windows 本地配置位于：

```text
C:\Users\Administrator\.codex\config.toml
```

如无特殊偏好，可不写模型相关项，让客户端选择默认模型。不要在此文件添加自定义 Provider 或 API Key。

---

## 4. Codex CLI

CLI 适合直接在仓库目录中执行代码理解、修改和审查任务。

### 4.1 Windows PowerShell

进入仓库后运行：

```powershell
codex
```

首次使用时完成 ChatGPT 登录。默认配置目录为：

```text
C:\Users\Administrator\.codex
```

### 4.2 WSL Linux

进入仓库后运行：

```bash
codex
```

首次使用时完成 ChatGPT 登录。默认配置目录为：

```text
~/.codex
```

Windows 和 WSL 是独立环境：它们各自保存配置和登录状态，需要分别完成登录。

---

## 5. VS Code 的 Codex IDE 扩展

该扩展适合在编辑器内引用已打开的文件、选区和当前差异。

1. 在 VS Code 扩展市场安装或启用 **Codex – OpenAI's coding agent**。
2. 点击侧边栏的 Codex 图标；若未显示，运行命令 `Codex: Open Codex Sidebar`。
3. 在账户页选择 ChatGPT 登录。
4. 打开项目后创建新对话；可附加当前文件或选中的代码。

### 5.1 VS Code 本地窗口与 WSL Remote 的区别

| 当前 VS Code 窗口 | 实际配置位置 |
| :--- | :--- |
| Windows 本地窗口 | `C:\Users\Administrator\.codex\config.toml` |
| WSL Remote 窗口 | `~/.codex/config.toml`（WSL 用户目录） |

截图中的 `WSL: Ubuntu-24.04` 窗口属于第二种情况。修改配置后，执行 `Developer: Reload Window`；如果认证状态未刷新，执行 `WSL: Reopen Folder in WSL` 并新建对话。

### 5.2 官方登录模式的示例配置

以下配置仅设置本地偏好，可以保留：

```toml
model = "gpt-5.6-terra"
model_reasoning_effort = "medium"

[projects."/home/brighthe"]
trust_level = "trusted"

[projects."/home/brighthe/workspace/soptx"]
trust_level = "trusted"

[features]
multi_agent = true
```

以下内容不应出现在官方登录模式中：

```toml
model_provider = "..."
model_catalog_json = "..."

[model_providers.some_provider]
```

---

## 6. 常见问题

### 出现 `401 Incorrect API key provided`

这说明当前客户端仍在尝试使用 API Key，而不是 ChatGPT 登录。按当前运行环境处理：

1. 从 `config.toml` 移除自定义 Provider 相关项。
2. 从 shell 启动文件和 VS Code Server 环境配置中移除 `OPENAI_API_KEY`、`DEEPSEEK_API_KEY`。
3. 在 WSL 中删除旧认证缓存后重新登录：

```bash
rm -f ~/.codex/auth.json
```

4. 执行 `WSL: Reopen Folder in WSL`，在 Codex 账户页重新使用 ChatGPT 登录。

若旧 Key 曾出现在截图、终端历史或仓库中，应立即在对应平台撤销它。

### 配置修改没有生效

确认修改的是当前窗口所属环境的文件；然后重载窗口并新建对话。已有对话可能保留创建时的模型或认证状态。

---

## 7. 官方参考

- [OpenAI Docs：Codex IDE extension](https://learn.chatgpt.com/docs/codex/ide)
- [OpenAI Docs：Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference)
- [OpenAI Docs：Codex CLI](https://learn.chatgpt.com/docs/codex/cli)

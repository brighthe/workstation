# Claude 与 Claude Code 使用指南

> - **更新日期**：2026-08-14
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Claude Desktop、VS Code
> - **服务边界**：使用 Anthropic 官方 Claude 服务；不将 Claude Code 转发到第三方模型 Provider

本文介绍 Claude 的三个常用入口：Claude Desktop、Claude Code CLI 和 VS Code 中的 Claude Code 扩展。默认使用 Claude 账号登录；需要按量付费的自动化或组织集成时，使用 Anthropic Console 的官方 API。DeepSeek 任务应通过独立 Harness 执行，而不是通过 Claude Code 的 Gateway 或环境变量改写后端。

> [!IMPORTANT]
> Claude 订阅登录与 Anthropic API Key 是两种官方认证方式。它们都不同于第三方 Gateway：本指南不设置第三方 `ANTHROPIC_BASE_URL`，不映射模型名，也不在启动脚本或编辑器设置中保存密钥。

---

## 1. 入口选择

| 入口 | 适合场景 | 推荐操作 |
| :--- | :--- | :--- |
| Claude Desktop | 对话、文件任务、Cowork 和桌面工作流 | 打开 Claude Desktop 并登录 Claude 账号。 |
| Claude Code CLI | 在项目目录中理解、修改、审查和自动化代码 | 运行 `claude`，选择适合自己的官方认证方式。 |
| VS Code 扩展 | 在编辑器中结合打开的文件、终端与差异进行开发 | 启用 Claude Code 扩展并使用同一官方账号登录。 |

---

## 2. 通用原则

1. 日常开发优先使用 Claude 账号的订阅登录；组织或自动化场景可选择 Anthropic Console API。
2. 不使用第三方 Gateway，也不要设置 `ANTHROPIC_BASE_URL` 指向第三方服务。
3. 不在 `settings.json`、PowerShell Profile、`.bashrc`、启动函数或教程中写入 API Key。
4. 不要保留为第三方路由设置的 `ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_MODEL`、`ANTHROPIC_DEFAULT_OPUS_MODEL`、`ANTHROPIC_DEFAULT_SONNET_MODEL` 或 `ANTHROPIC_DEFAULT_HAIKU_MODEL`。
5. 不要将密钥、OAuth 凭据或认证缓存提交到 Git 仓库、粘贴到截图或写入文档。

---

## 3. Claude Desktop

Claude Desktop 适合日常对话、文件处理和桌面工作流。

1. 从 Claude 官方下载页面安装或更新 Claude Desktop。
2. 打开应用后使用 Claude 账号登录。
3. 在对话中选择所需的工作方式；如计划支持，可使用 Claude Code 或 Cowork。

Windows 本地应用不需要配置第三方 Gateway。若此前添加过第三方推理档案或静态 API Key，停用或删除该档案，恢复默认的 Claude 账号登录。

---

## 4. Claude Code CLI

Claude Code CLI 适合在仓库目录直接执行编码任务。

### 4.1 安装与启动

在 Windows（Git Bash 或 WSL）或 Linux/macOS 终端中安装后，进入项目目录运行：

```bash
claude
```

首次启动时选择一种官方认证方式：

- **Claude App**：使用 Claude Pro 或 Max 等订阅账号登录；
- **Anthropic Console**：使用拥有有效账单的 Console 账号完成认证；
- **企业平台**：按组织规范使用 Amazon Bedrock 或 Google Vertex AI。

Windows 推荐通过 WSL 或 Git Bash 运行 Claude Code。WSL 与 Windows 是独立环境：若两边都使用 CLI，应分别完成登录。

### 4.2 常用命令

```bash
claude                         # 启动交互式会话
claude "解释这个项目的结构"     # 带初始任务启动
claude -c                      # 继续最近的会话
claude -p "检查这个函数"        # 非交互式输出后退出
claude update                  # 更新 Claude Code
```

不要创建 `claude-ds` 等第三方 Provider 启动函数，也不要在普通 `claude` 命令前后注入或清除第三方模型环境变量。

---

## 5. VS Code 中使用 Claude Code

在 VS Code 中，Claude Code 扩展适合配合当前项目、打开文件和集成终端完成开发任务。

1. 在 VS Code 扩展市场安装或启用 Claude Code 扩展。
2. 打开项目，在扩展界面或集成终端启动 Claude Code。
3. 使用与 CLI/Claude Desktop 对应的官方账户完成登录。
4. 在新会话中描述任务，并审阅扩展提出的修改与权限请求。

### 5.1 配置要求

保持 VS Code 用户设置和 WSL Remote 设置中不含第三方 API 路由：

```json
{
  "claudeCode.environmentVariables": []
}
```

如果你的 `settings.json` 没有其他 Claude Code 设置，可以直接删除该项。若已有界面、位置或快捷键等设置，只删除其中与第三方路由有关的环境变量，不要覆盖整个 JSON 文件。

以下变量不应出现在 VS Code 的 Claude Code 环境变量中：

```text
ANTHROPIC_BASE_URL
ANTHROPIC_API_KEY
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_MODEL
ANTHROPIC_DEFAULT_OPUS_MODEL
ANTHROPIC_DEFAULT_SONNET_MODEL
ANTHROPIC_DEFAULT_HAIKU_MODEL
```

修改设置后，运行 `Developer: Reload Window`；在 WSL Remote 窗口中如认证仍未刷新，运行 `WSL: Reopen Folder in WSL`，然后新建会话。

---

## 6. 常见问题

### 仍然显示第三方模型或 API 计费

说明扩展或终端仍继承了旧环境变量。检查 PowerShell Profile、`~/.bashrc`、VS Code 用户设置与 WSL Remote 设置，移除上一节列出的 `ANTHROPIC_*` 覆盖项，然后重启对应终端或重载 VS Code 窗口。

### 登录窗口没有出现

先移除 `claudeCode.disableLoginPrompt` 及第三方环境变量配置，再重载窗口或重启 CLI。选择 Claude App 或 Anthropic Console 的官方认证流程完成登录。

### 密钥曾写入配置或截图

立即在 Anthropic Console 撤销该 Key；随后从配置、shell 历史和仓库中移除它。不要通过修改模型名或 Gateway URL 来补救已泄露的密钥。

---

## 7. 官方参考

- [Anthropic Docs：Set up Claude Code](https://docs.anthropic.com/en/docs/claude-code/getting-started)
- [Anthropic Docs：Claude Code CLI reference](https://docs.anthropic.com/en/docs/claude-code/cli-usage)
- [Claude Help Center：Install Claude Desktop](https://support.claude.com/en/articles/10065433-install-claude-desktop)

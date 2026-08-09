# Claude Code 接入 DeepSeek API 与双模式配置指南

> - **整理日期**：2026-08-05
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Claude Desktop、VS Code 插件

本文提供 **Claude Code** 在 Desktop 客户端、CLI 命令行以及 VS Code 插件三大场景下的配置规范、支持程度与使用指南。

---

## 核心使用规范总览（三大应用场景）

为兼顾**系统稳定性（官方订阅）**与**高效低成本（DeepSeek API 按量付费）**，整体使用划分为三大场景分类：

| 应用分类 | 场景与运行环境 | 官方订阅模式 | DeepSeek API 模式 | 支持程度与使用说明 |
| :--- | :--- | :--- | :--- | :--- |
| **1. Desktop 桌面 App** | Claude Desktop 客户端 | 右上角选择 `Default` 档案 | 右上角选择 `DeepSeek API` 档案 | 原生支持 Gateway 双配置档案（Profile）一键无缝鼠标切换 |
| **2. CLI 命令行终端** | Windows PowerShell<br>WSL Linux 终端 | 运行命令 **`claude`** | 运行命令 **`claude-ds`** | **命令在 Windows 与 WSL 中 100% 完全一致**。通过启动函数隔离，实现不互相污染 |
| **3. VS Code 插件** | VS Code 侧边栏 & 内置终端 | 清空 `settings.json` 环境变量 | 修改 VS Code `settings.json` 配置 | **最佳推荐平台**。推荐保持 WSL 设置继承 Windows 本地，实现单一文件统一管控 |

---

## 1. 场景一：Desktop 桌面客户端配置（支持官方订阅与 DeepSeek）

Claude Desktop 客户端原生支持通过 **Gateway 双配置档案** 在官方订阅与 DeepSeek API 之间自由切换：

### 1.1 开启开发者模式与添加档案
1. 进入 `Help → Troubleshooting → Enable Developer Mode`，重启软件。
2. 选择菜单 `Developer → Configure Third-Party Inference...`。
3. 点击右上角 `Default ▼` ➔ 点击 `New configuration` ➔ 创建名为 **`DeepSeek API`** 的新档案。

### 1.2 参数配置与一键切换
- **`Default` 档案**：保持 `Claude API + Interactive sign-in`（使用 **Claude Pro 官方订阅**）。
- **`DeepSeek API` 档案**：选择 `Gateway`：
  - **Gateway base URL**: `https://api.deepseek.com/anthropic`
  - **Credential kind**: `Static API key`
  - **Gateway API key**: 填入 DeepSeek API Key (`sk-...`)
  - **Gateway auth scheme**: `x-api-key`

**切换方法**：点击软件右上角 `Default` 下拉菜单，随时切换档案即可更替后端引擎。

---

## 2. 场景二：CLI 命令行终端配置（涵盖 Windows 与 WSL 双终端）

针对 CLI 命令行，**在 Windows PowerShell 与 WSL Linux 两套终端中，运行命令是 100% 完全一致的**：

- **调用 Claude Pro 官方订阅** ➔ 在任何终端均运行：`claude`
- **调用 DeepSeek API 模式** ➔ 在任何终端均运行：`claude-ds`

> [!IMPORTANT]
> **环境隔离防污染机制**：如果之前在同一终端中运行过 `claude-ds`，内存中会残留 DeepSeek 环境变量。为避免普通 `claude` 误继承 DeepSeek 变量而错走 API 扣费模式，我们在 `claude` 启动函数头部增加了强制 `unset` 抹除机制，确保普通 `claude` 100% 稳定切回 Claude Pro 官方订阅！

环境配置如下：

### 2.1 Windows PowerShell 终端配置
- **PowerShell 个人 Profile 配置文件路径**：可在 PowerShell 中运行 `$PROFILE` 查看（通常位于 `C:\Users\Administrator\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`）。

在 PowerShell `$PROFILE` 中添加以下启动函数：

```powershell
function claude-ds {
    if (-not $env:DEEPSEEK_API_KEY) {
        Write-Error "DEEPSEEK_API_KEY is not set."
        return
    }
    $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
    $env:ANTHROPIC_API_KEY = $env:DEEPSEEK_API_KEY
    $env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY
    $env:ANTHROPIC_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
    $env:CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
    $env:CLAUDE_CODE_EFFORT_LEVEL = "max"
    try { claude @args }
    finally {
        Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_API_KEY, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL,
            Env:ANTHROPIC_DEFAULT_OPUS_MODEL, Env:ANTHROPIC_DEFAULT_SONNET_MODEL,
            Env:ANTHROPIC_DEFAULT_HAIKU_MODEL, Env:CLAUDE_CODE_SUBAGENT_MODEL,
            Env:CLAUDE_CODE_EFFORT_LEVEL -ErrorAction SilentlyContinue
    }
}
```

### 2.2 WSL Linux 终端配置
- **WSL 启动脚本文件路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.claude_ds_func`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.claude_ds_func)
- **WSL Bash 环境入口文件路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.bashrc`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.bashrc)

在 WSL 内部 [`~/.claude_ds_func`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.claude_ds_func) 中同时绑定 `claude` 与 `claude-ds` 到 Linux 原生二进制文件（并在 `claude` 函数前强行抹除环境变量）：

```bash
# >>> Claude DeepSeek & Native launcher >>>
function claude() {
    # 强制清理环境变量，保证普通 claude 永远 100% 走 Claude Pro 官方订阅
    unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
          ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
          ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
          CLAUDE_CODE_EFFORT_LEVEL
          
    local BIN_PATH="/home/brighthe/.vscode-server/extensions/anthropic.claude-code-2.1.222-linux-x64/resources/native-binary/claude"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" "$@"
    else
        command claude "$@"
    fi
}

function claude-ds() {
    export DEEPSEEK_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
    export ANTHROPIC_API_KEY="$DEEPSEEK_API_KEY"
    export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
    export ANTHROPIC_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_EFFORT_LEVEL="max"
    
    local BIN_PATH="/home/brighthe/.vscode-server/extensions/anthropic.claude-code-2.1.222-linux-x64/resources/native-binary/claude"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" "$@"
    else
        command claude "$@"
    fi
    
    unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
          ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
          ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
          CLAUDE_CODE_EFFORT_LEVEL
}
# <<< Claude DeepSeek & Native launcher <<<
```
在 [`~/.bashrc`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.bashrc) 中引入：`[ -f ~/.claude_ds_func ] && source ~/.claude_ds_func`。

---

## 3. 场景三：VS Code 插件配置、双交互模式与模型映射

> [!IMPORTANT]
> **VS Code 模式切换最佳实践（单一统一配置文件 💡）**：
> 在 VS Code 机制中，如果 WSL 远程机器设置保持为空 `{}`，它会自动**继承并读取 Windows 本地配置**！
> 推荐直接在 **Windows 本地用户配置文件** [`C:\Users\Administrator\AppData\Roaming\Code\User\settings.json`](file:///C:/Users/Administrator/AppData/Roaming/Code/User/settings.json) 中进行统一管理，即可同时对本地窗口与 WSL 远程窗口生效！

### 3.1 两种启动模式与默认模式判定（`claudeCode.useTerminal`）
在 VS Code 中点击 Claude 图标唤起插件时，支持通过设置项 **`claudeCode.useTerminal`** 切换两套交互模式：

1. **直接打开（Native Visual UI 面板模式）**：
   - **配置**：`"claudeCode.useTerminal": false`
   - **默认模式判定规则**：
     - **未在设置中注入 `claudeCode.environmentVariables` 时** ➔ **默认采取【Claude Pro 官方订阅模式】**（要求登录账号）。
     - **若在 `settings.json` 中配置了 `claudeCode.environmentVariables`** ➔ 直接打开也会**自动切换为【DeepSeek API 模式】**（显示为 `deepseek-v4-pro[1m]`）。
2. **在内置终端中打开（Terminal 集成终端模式）**：
   - **配置**：`"claudeCode.useTerminal": true`
   - **特点**：点击图标自动在底部终端中开辟新 Terminal Tab 并自动执行 `claude` 命令行界面。

### 3.2 在 VS Code 插件中切换「官方订阅」与「DeepSeek API 模式」

#### A. 切换为【Claude Pro 官方订阅模式】
1. 打开统一管理文件 **Windows 本地用户设置**：[`C:\Users\Administrator\AppData\Roaming\Code\User\settings.json`](file:///C:/Users/Administrator/AppData/Roaming/Code/User/settings.json)。
2. 将其中的 `claudeCode.environmentVariables` 数组及 `claudeCode.disableLoginPrompt` 项**注释或删除**并保存。
3. 确保 WSL 远程机器设置 [`Machine/settings.json`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.vscode-server/data/Machine/settings.json) 保持为空 `{}`（自动继承本地设置）。
4. 按 `Ctrl + Shift + P` 运行 `Developer: Reload Window` 重载窗口，自动恢复官方订阅登录面板。

#### B. 切换为【DeepSeek API 模式】
直接在 **Windows 本地用户设置** [`settings.json`](file:///C:/Users/Administrator/AppData/Roaming/Code/User/settings.json) 中注入环境变量：

```json
{
  "claudeCode.disableLoginPrompt": true,
  "claudeCode.environmentVariables": [
    { "name": "ANTHROPIC_BASE_URL", "value": "https://api.deepseek.com/anthropic" },
    { "name": "ANTHROPIC_API_KEY", "value": "sk-替换为你的 DeepSeek API Key" },
    { "name": "ANTHROPIC_AUTH_TOKEN", "value": "sk-替换为你的 DeepSeek API Key" },
    { "name": "ANTHROPIC_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_OPUS_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_SONNET_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL", "value": "deepseek-v4-flash" }
  ]
}
```
保存后按 `Ctrl + Shift + P` 运行 `Developer: Reload Window` 重载窗口，无论本地还是 WSL 远程均自动切为 DeepSeek API！

> [!CAUTION]
> **关键陷阱提示：必须同时注入 `ANTHROPIC_API_KEY`！**
> Claude Code 底层判定 API 模式强依赖 `ANTHROPIC_API_KEY`。如果仅配置了 `ANTHROPIC_AUTH_TOKEN` 而遗漏了 `ANTHROPIC_API_KEY`，插件会误判定未提供 API 密钥，从而回退（Fallback）去读取 Desktop 共享保存的本地 OAuth Token（`~/.claude.json`）。这会导致当你在 Desktop 登录官方订阅时，VS Code 会被自动带入官方订阅模式！

#### C. Devin 中使用 Claude Code 插件

Devin 的 `settings.json` 同样可配置 Claude Code 插件的 `claudeCode.*` 设置。**不要直接用上方示例覆盖整个文件**，否则会删除 Devin 自身设置（例如 `devin.cascade.enabled`）以及 Claude Code 的界面偏好（例如 `claudeCode.preferredLocation`）。应在原有 JSON 对象中合并新增字段，并注意各顶级键之间的逗号。

例如，若 `C:\\Users\\Administrator\\AppData\\Roaming\\Devin\\User\\settings.json` 原本包含下列 Devin 设置，可合并为：

```json
{
  "devin.cascade.enabled": false,
  "claudeCode.preferredLocation": "panel",

  "claudeCode.disableLoginPrompt": true,
  "claudeCode.environmentVariables": [
    { "name": "ANTHROPIC_BASE_URL", "value": "https://api.deepseek.com/anthropic" },
    { "name": "ANTHROPIC_API_KEY", "value": "sk-替换为你的 DeepSeek API Key" },
    { "name": "ANTHROPIC_AUTH_TOKEN", "value": "sk-替换为你的 DeepSeek API Key" },
    { "name": "ANTHROPIC_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_OPUS_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_SONNET_MODEL", "value": "deepseek-v4-pro" },
    { "name": "ANTHROPIC_DEFAULT_HAIKU_MODEL", "value": "deepseek-v4-flash" }
  ]
}
```

保存后运行 `Developer: Reload Window`。若在 WSL 远程窗口中重载后仍显示 Claude Pro，则检查 Devin 的 `Settings (Remote) [WSL: Ubuntu-24.04]` 是否有同名设置；远程运行的扩展可能以远程设置为准。请使用新建的 API Key，切勿将已泄露或已撤销的 Key 写回配置。

### 3.3 多模型选择与映射支持
Claude Code 原生采用 **Anthropic Messages API** 协议，DeepSeek 在该协议上完整支持两款模型的动态映射：

| Claude Code 发送模型 ID | DeepSeek 实际响应底层模型 | 适用场景 |
|---|---|---|
| `claude-opus...` / `claude-sonnet...` | **`deepseek-v4-pro`** | 高难度推理、复杂架构重构与深度代码生成 |
| `claude-haiku...` / Subagents | **`deepseek-v4-flash`** | 快速常规回答、文件检查与后台子代理任务 |

在对话框中随时输入 `/model` 即可自由选择切换当前会话调用的底层 DeepSeek 模型！

---

## 4. 常见问题排查

### 在 Desktop 登录官方订阅后，VS Code 自动同步切为官方订阅？
- **原因**：VS Code 的 `settings.json` 中配置 `claudeCode.environmentVariables` 时，遗漏了 `ANTHROPIC_API_KEY` 变量。插件因缺少 API Key 判定未开启 API 模式，从而回退（Fallback）去读取 Desktop 共享保存的 `~/.claude.json` OAuth 凭据。
- **解决**：在 `settings.json` 的 `claudeCode.environmentVariables` 数组中务必包含 `{ "name": "ANTHROPIC_API_KEY", "value": "sk-xxxxxxxx..." }`。保存后运行 `Developer: Reload Window` 重载窗口并在对话框中发送 `/logout` 清除缓存。

### `OAuth error: Socket is closed`
- **原因**：WSL Linux 终端运行时继承了 Windows PATH 误调用了 `claude.exe`。
- **解决**：在 [`~/.claude_ds_func`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.claude_ds_func) 中绑定 WSL 原生二进制路径 `/home/brighthe/.vscode-server/extensions/.../native-binary/claude`。

### 界面依然显示 `Sonnet 5 · Claude Pro`？
- **原因**：存在历史 OAuth 缓存，且未同时导出 `ANTHROPIC_API_KEY`。
- **解决**：在输入框中发送 `/logout` 清除缓存，确保导出 `ANTHROPIC_API_KEY` 后界面会自动更新为 `deepseek-v4-pro · API Usage Billing`。

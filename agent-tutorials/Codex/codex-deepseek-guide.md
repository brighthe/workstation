# OpenAI Codex 接入 DeepSeek API 与双模式配置指南

> - **整理日期**：2026-08-05
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Codex Desktop 桌面 App、VS Code 插件

本文提供 **OpenAI Codex** 在 Desktop 客户端、CLI 命令行以及 VS Code 插件三大场景下的配置规范、支持程度与使用指南。

---

## 核心使用规范总览（三大应用场景）

为兼顾**系统稳定性（官方订阅）**与**高效低成本（DeepSeek API 按量付费）**，整体使用划分为三大场景分类：

| 应用分类 | 场景与运行环境 | 官方订阅模式 | DeepSeek API 模式 | 支持程度与使用说明 |
| :--- | :--- | :--- | :--- | :--- |
| **1. Desktop 桌面 App** | Codex Desktop 客户端 | 读取全局 `config.toml` (OpenAI 默认) | 修改全局 `config.toml` 加载 DeepSeek (不推荐) | **强烈推荐保持官方订阅** (`gpt-5.6-terra`)；桌面 App 缺乏双配置档案，频繁改动全局配置极易失效 |
| **2. CLI 命令行终端** | Windows PowerShell<br>WSL Linux 终端 | 运行命令 **`codex`** | 运行命令 **`codex-deepseek`** | **命令在 Windows 与 WSL 中 100% 完全一致**。通过各自环境下的独立 `CODEX_HOME` 路径做到完全隔离 |
| **3. VS Code 插件** | VS Code 侧边栏 & 内置终端 | 账户面板登录 ChatGPT 账号 | 修改关联的 `config.toml` 配置 | **最佳兼容平台**。通过修改 `config.toml` 决定切换模式（界面提供“打开 config.toml”快捷按钮） |

---

## 1. 场景一：Desktop 桌面客户端配置说明

Codex Desktop（桌面 App）完全依赖并读取 Windows 宿主机的全局配置文件。

### 本机实际配置文件路径
- **Windows 全局 `config.toml` 路径**：[`C:\Users\Administrator\.codex\config.toml`](file:///C:/Users/Administrator/.codex/config.toml)

> [!IMPORTANT]
> **界面限制说明**：Codex Desktop 界面右下角仅展示当前配置文件中加载的模型选项，**图形界面上未提供直接“粘贴 API 密钥”的框**。因此 Desktop 客户端的后端引擎完全取决于全局 [`config.toml`](file:///C:/Users/Administrator/.codex/config.toml) 的配置内容。

### 1.1 默认官方订阅模式（推荐）
确保 Windows 宿主机的全局配置文件 [`C:\Users\Administrator\.codex\config.toml`](file:///C:/Users/Administrator/.codex/config.toml) 保持默认 OpenAI 订阅配置：

```toml
model = "gpt-5.6-terra"
model_reasoning_effort = "high"

service_tier = "default"
```
且确认 `C:\Users\Administrator\.codex\` 目录下无自定义 `models.json` 文件。此时打开 Codex Desktop 默认即为 **ChatGPT Plus 官方订阅**。

### 1.2 若需让 Desktop 客户端切换到 DeepSeek（不推荐 ⚠️）

> [!WARNING]
> **不推荐修改全局配置**：Codex Desktop 桌面客户端不像 Claude Desktop 那样原生支持图形界面的 Gateway 双配置档案（Profile）无缝切换。要让 Codex Desktop 使用 DeepSeek，必须手动频繁修改全局配置文件 [`config.toml`](file:///C:/Users/Administrator/.codex/config.toml) 并补全 `models.json`，这会污染原本稳定的 ChatGPT Plus 官方订阅环境，过程非常繁琐且易出错。
> 
> 💡 **强烈建议最佳实践**：
> - **Desktop 桌面 App** ➔ 保持官方订阅（`model = "gpt-5.6-terra"`），无需改动任何文件。
> - **需要使用 DeepSeek API 时** ➔ 推荐直接在终端运行 **`codex-deepseek`** 命令（或在 VS Code 内配置），零污染、秒级切换！

若强行需要让 Desktop 桌面 App 切换使用 DeepSeek，步骤如下：

1. 修改全局配置文件 [`C:\Users\Administrator\.codex\config.toml`](file:///C:/Users/Administrator/.codex/config.toml) 内容为：
```toml
model = "deepseek-v4-flash"
model_provider = "deepseek"
model_catalog_json = "C:/Users/Administrator/.codex/models.json"
model_reasoning_effort = "high"

service_tier = "default"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/"
wire_api = "responses"
api_key = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```
2. 在 `C:\Users\Administrator\.codex\` 目录下放置模型描述映射表 `models.json`。

---

## 2. 场景二：CLI 命令行终端配置（涵盖 Windows 与 WSL 双终端）

针对 CLI 命令行，**在 Windows PowerShell 与 WSL Linux 两套终端中，运行命令是 100% 完全一致的**：

- **调用 ChatGPT Plus 订阅** ➔ 在任何终端均运行：`codex`
- **调用 DeepSeek API** ➔ 在任何终端均运行：`codex-deepseek`

我们通过在 Windows 和 WSL 两边建立各自的独立 `CODEX_HOME` 隔离目录来实现这一无缝体验：

### 2.1 Windows PowerShell 终端配置
- **独立配置目录**：`C:\Users\Administrator\.codex-deepseek\`
- **独立配置文件路径**：[`C:\Users\Administrator\.codex-deepseek\config.toml`](file:///C:/Users/Administrator/.codex-deepseek/config.toml)
- **独立模型描述表路径**：[`C:\Users\Administrator\.codex-deepseek\models.json`](file:///C:/Users/Administrator\.codex-deepseek\models.json)

**[`config.toml`](file:///C:/Users/Administrator/.codex-deepseek/config.toml) 内容**：
```toml
model = "deepseek-v4-flash"
model_provider = "deepseek"
model_catalog_json = "C:/Users/Administrator/.codex-deepseek/models.json"
model_reasoning_effort = "high"

service_tier = "default"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/"
wire_api = "responses"
api_key = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

在全局 `C:\Users\Administrator\AppData\Roaming\npm\codex-deepseek.cmd` 启动器中关联该目录：
```cmd
@echo off
setlocal
set "CODEX_HOME=%USERPROFILE%\.codex-deepseek"
call "%~dp0codex.cmd" --model deepseek-v4-flash %*
```

### 2.2 WSL Linux 终端配置
- **WSL 默认配置文件路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.codex\config.toml`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.codex/config.toml)
- **WSL 独立 DeepSeek 配置路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.codex-deepseek\config.toml`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.codex-deepseek/config.toml)
- **WSL 启动脚本路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.codex_ds_func`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.codex_ds_func)
- **WSL Bash 环境入口路径**：[`\\wsl.localhost\ubuntu-24.04\home\brighthe\.bashrc`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.bashrc)

**[`~/.codex_ds_func`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.codex_ds_func) 内容**：
```bash
# >>> Codex DeepSeek launcher >>>
function codex-deepseek() {
    export CODEX_HOME="/home/brighthe/.codex-deepseek"
    export DEEPSEEK_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    local BIN_PATH="/home/brighthe/.vscode-server/extensions/openai.chatgpt-26.727.40816-linux-x64/bin/linux-x86_64/codex"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" --model deepseek-v4-flash "$@"
    else
        command codex --model deepseek-v4-flash "$@"
    fi
    unset CODEX_HOME DEEPSEEK_API_KEY
}

function codex() {
    local BIN_PATH="/home/brighthe/.vscode-server/extensions/openai.chatgpt-26.727.40816-linux-x64/bin/linux-x86_64/codex"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" "$@"
    else
        command codex "$@"
    fi
}
# <<< Codex DeepSeek launcher <<<
```

---

## 3. 场景三：VS Code 插件配置、模式切换与编辑器兼容性

> [!IMPORTANT]
> **VS Code 模式切换核心法则（Codex 篇）**：
> **Codex 插件是通过修改关联的 `config.toml` 文件来决定切换模式的**（Windows 下为 `%USERPROFILE%\.codex\config.toml`，WSL 远程下为 `~/.codex/config.toml`）。插件设置页面中贴心地提供了“**打开 config.toml**”按钮。

### 3.1 IDE 编辑器兼容性（VS Code 为第一推荐平台）
**OpenAI Codex 插件原生优先支持 VS Code (Visual Studio Code)**：
- OpenAI 官方首发的全功能 IDE 扩展即为 `openai.chatgpt` (Codex - OpenAI's coding agent)。
- VS Code 拥有最好的跨平台 Remote 架构，完整支持本地与 WSL 远程无缝联动。
- 插件设置面板原生提供了 **`打开 config.toml`** 快捷按钮。

### 3.2 在 VS Code 插件中切换「官方订阅」与「DeepSeek API 模式」

在 VS Code 插件中切换模式无需卸载或重新安装插件，直接粘贴以下完整配置覆盖 `config.toml` 即可：

#### A. 切换为【ChatGPT 官方订阅模式】
1. 点击设置页面的 **`打开 config.toml`** 按钮（或直接打开 [`config.toml`](file:///C:/Users/Administrator/.codex/config.toml)）。
2. 直接粘贴以下完整代码覆盖文件并保存：

```toml
model = "gpt-5.6-terra"
model_reasoning_effort = "high"

service_tier = "default"

[projects."/home/brighthe"]
trust_level = "trusted"
```
3. 打开 VS Code 的 Codex 插件侧边栏或设置页面，点击左侧 **`账户` (Account)** 菜单 ➔ 点击 **`Sign in with ChatGPT`** 确认登录状态。
4. 按 `Ctrl + Shift + P` 运行 `Developer: Reload Window`，插件右下角即可看到恢复为官方订阅（显示 `5.6 Terra` 或 `5.6 Sol`）！

#### B. 切换为【DeepSeek API 模式】

> [!CAUTION]
> **TOML 语法防冲突规则（非常重要 ⚠️）**：
> 在 `config.toml` 中切换为 DeepSeek 模式时，**必须把前面的 `model = "gpt-5.6-sol"` （或 `gpt-5.6-terra"`）删掉或覆盖**，只保留最下方新写的 `model = "deepseek-v4-flash"`！否则同一个文件中出现两个 `model` 键，会导致 TOML 语法重名冲突而解析失败。

粘贴以下完整的标准覆盖内容：

```toml
model = "deepseek-v4-flash"
model_provider = "deepseek"
model_catalog_json = "/home/brighthe/.codex/models.json"
model_reasoning_effort = "high"

service_tier = "default"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/"
wire_api = "responses"
api_key = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

[projects."/home/brighthe"]
trust_level = "trusted"
```

粘贴保存后，按 `Ctrl + Shift + P` 运行 `Developer: Reload Window`，插件右下角模型选择器显示为 **`自定义` (Custom)**，代表成功切为 DeepSeek！

### 3.3 未来的多模型扩充（如添加 deepseek-v4-pro）

> [!IMPORTANT]
> **多模型扩充需修改 2 个文件**：
> 扩展使用新的第三方模型时，必须同时更新 **`models.json`（声明新模型元数据）** 和 **`config.toml`（切换指定模型）**。

#### 1. 修改 `models.json`（模型映射描述表）
在关联的 `models.json` 文件中（如 WSL 下为 [`/home/brighthe/.codex/models.json`](file://wsl.localhost/ubuntu-24.04/home/brighthe/.codex/models.json)），添加 `deepseek-v4-pro` 的定义。完整代码如下：

```json
{
  "models": [
    {
      "id": "deepseek-v4-flash",
      "name": "DeepSeek V4 Flash",
      "description": "DeepSeek V4 Flash Model",
      "model_provider": "deepseek"
    },
    {
      "id": "deepseek-v4-pro",
      "name": "DeepSeek V4 Pro",
      "description": "DeepSeek V4 Pro Model",
      "model_provider": "deepseek"
    }
  ]
}
```

#### 2. 修改 `config.toml`（切换目标模型）
在关联的 `config.toml` 中将 `model` 改为 `"deepseek-v4-pro"`。完整代码如下：

```toml
model = "deepseek-v4-pro"
model_provider = "deepseek"
model_catalog_json = "/home/brighthe/.codex/models.json"
model_reasoning_effort = "high"

service_tier = "default"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/"
wire_api = "responses"
api_key = "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

[projects."/home/brighthe"]
trust_level = "trusted"
```

保存两处修改后，在 VS Code 中运行 `Developer: Reload Window` 刷新，即可无缝使用未来的 `deepseek-v4-pro`！

---

## 4. 常见问题排查

### 为什么模型在对话中自称“我是基于 GPT-5 构建的”？
- **原因**：这是正常现象。由于 Codex 框架在 `models.json` 的 `instructions_template` 中预设了 Codex 官方标准的系统 Prompt（"You are Codex, an agent based on GPT-5..."），模型回答身份时优先遵从 System Prompt 角色设定。
- **验证**：真实请求由 DeepSeek 后台处理并扣费。可通过登录 [DeepSeek 开放平台控制台](https://platform.deepseek.com/) 的 **用量统计 (API Usage)** 查看实时 Token 消耗验证。

### 提示 `Missing environment variable: 'DEEPSEEK_API_KEY'`
- **原因**：VS Code 在 WSL 远程模式下运行的子进程默认未加载 `.bashrc` 中的环境变量。
- **解决**：在 `config.toml` 的 `[model_providers.deepseek]` 块中通过 `api_key = "sk-..."` 直接嵌入密钥。

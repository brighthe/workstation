# VS Code + ACP 接入 DeepSeek Harness 指南

> - **更新日期**：2026-08-17
> - **适用环境**：Windows 11 + WSL2（Ubuntu-24.04）+ VS Code（Remote-WSL）+ `deepseek-acp` v0.3.0
> - **关联**：安装与日常使用见 [`deepseek-guide.md`](deepseek-guide.md)；能力全景见 [`capabilities.md`](capabilities.md)；配置面管理见 [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)

本文记录如何把 DeepSeek Harness 接成 **VS Code 编辑器内的编码 Agent**（类似 Codex 插件的体验），通过 [ACP（Agent Client Protocol）](https://agentclientprotocol.com) 协议实现。本机已于 2026-08-17 实测跑通。

---

## 1. 为什么是 deepseek-acp，而不是官方 dsh-acp

DeepSeek Harness 官方自带 ACP server（`@deepseek-ai/dsh-acp`），但它的定位是 **automation-only**——官方文档原文：

> This package is a transport adapter, not a UI integration... It does not expose editor navigation, transcript replay, commands, modes, configuration pickers, elicitation, reasoning, plans, titles, or tool presentation.

官方实现只发**已提交**的助手消息，工具调用、文件改动、思考过程全部留在会话日志里，界面上只有最后一段文字——给程序用可以，给人用不行。

**`deepseek-acp`（社区实现，v0.3.0）补齐了这个生态位**：同一个 harness 内核，换一张面向编辑器的协议面。与本机 `dsh`（v0.1.0-rc.6）依赖完全一致，实测可用。能力对比如下：

| 能力 | 官方 dsh-acp（automation-only） | **deepseek-acp**（编辑器向） |
|---|---|---|
| 回复流式 | 仅整段提交后推送 | ✅ 逐 token |
| 思考过程 | ✗ 留在日志里 | ✅ `agent_thought_chunk` |
| 工具调用 | ✗ 不呈现 | ✅ 卡片 + 状态流转 |
| 文件 diff | ✗ | ✅ 编辑器原生 diff 视图 |
| 终端输出 | ✗ | ✅ 终端卡片 |
| 待办/计划 | ✗ | ✅ `plan` + 计划模式 |
| 会话恢复/列表 | ✗ 关掉即消失 | ✅ `load` / `list` / `resume`，带标题 |
| 会话内换模型 | ✗ | ✅ 模型、推理档位、文件权限选择器 |
| slash 命令 | ✗ | ✅ 命令目录 |
| 模型向用户提问 | ✗ | ✅ 表单征询 |
| MCP server | ✗ 非空即拒绝 | ✅ 按会话挂载 |
| 读未保存缓冲区 | ✗ | ✅ `fs/read_text_file` 改道到编辑器 |

> [!IMPORTANT]
> `deepseek-acp` 是**非官方社区适配器**（MIT），与 DeepSeek 无隶属关系、未获背书。README 注明其测试与设计部分派生自官方曾存在、2026-07-24 删除的编辑器向 bridge（该快照适用 BSD-3-Clause）。

---

## 2. 架构：谁在哪一侧

```
VS Code（Remote-WSL）
 ├── 编辑器界面（Windows 窗口，文件/终端/调试器/diff 都由 VS Code 提供）
 └── ACP Client 扩展（formulahendry.acp-client）
      └── spawn 子进程：deepseek-acp（WSL 内）
           └── DeepSeek Harness agent 内核（工具调用、会话、沙箱）
```

- **IDE 能力**（文件树、diff、终端、调试器）由 VS Code 原生提供
- **Agent 大脑**（工具调用、会话持久化、沙箱）由 DSH 内核提供
- 二者通过 **ACP（JSON-RPC over stdio）** 打通

**关键：agent 进程跑在 WSL 侧。** VS Code 用 Remote-WSL 时，扩展在 WSL 的 bash 里 spawn 子进程——所以 `deepseek-acp`、Node、API Key 都要在 WSL 里就绪，与 Windows 侧完全隔离。

---

## 3. 安装步骤

### 3.1 WSL 侧：Node.js 24

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v   # 实测 v24.19.0
```

### 3.2 WSL 侧：全局安装 deepseek-acp

```bash
sudo npm install -g deepseek-acp
deepseek-acp --version   # 0.3.0
```

> [!NOTE]
> 必须 `sudo`：全局 npm 目录 `/usr/lib/node_modules` 归 root 所有，普通用户 `npm i -g` 会报 `EACCES`。装完可执行文件在 PATH 内，普通用户可运行。

### 3.3 WSL 侧：配置 API Key

```bash
deepseek-acp --setup
```

交互式粘贴 Key，写入 `~/.dsh/.credentials.yaml`（0600）。这是**唯一需要手动输入 Key 的步骤**。

> 凭据边界：`~/.dsh/.credentials.yaml` 含密钥，**不进仓库、不提交**。它与 Windows 侧 `$DSH_HOME` 完全独立。

### 3.4 VS Code：安装 ACP Client 扩展

```powershell
code --install-extension formulahendry.acp-client
```

或在扩展市场搜 **ACP Client**（作者 formulahendry）。Remote-WSL 下会同时装到 WSL 侧的扩展目录。

### 3.5 VS Code：配置 agent

编辑用户 settings.json（`Ctrl+Shift+P` → `Preferences: Open User Settings (JSON)`）：

```json
"acp.agents": {
    "DeepSeek Harness": {
        "command": "deepseek-acp",
        "args": [],
        "env": {}
    }
}
```

> `command` 填 `deepseek-acp` 即可——扩展在 WSL bash 下 spawn，PATH 能找到。`env` 留空：Key 走 `~/.dsh/.credentials.yaml`（`--setup` 写入），不随 settings.json 同步、不入配置。

### 3.6 重载并连接

`Ctrl+Shift+P` → `Developer: Reload Window` → 左侧 Activity Bar 点 **ACP 图标** → 选 "DeepSeek Harness" → Connect → 开始对话。

---

## 4. 日常使用

### 快速打开 ACP

| 方式 | 操作 |
|---|---|
| 快捷键 | `Ctrl+Shift+A`（打开聊天面板） |
| 侧边栏 | Activity Bar 的 ACP 图标 |
| 命令面板 | `Ctrl+Shift+P` → `ACP: Open Chat Panel` |

### 常用操作

| 命令 | 说明 |
|---|---|
| `ACP: New Conversation` | 新会话 |
| `ACP: Cancel Current Turn` | 取消当前回合（`Escape`） |
| `ACP: Set Agent Mode / Model` | 切换模式/模型 |
| `ACP: Show Log` / `ACP: Show Protocol Traffic` | 排错日志 |
| `ACP: Restart Agent` | 重启 agent 进程 |

### 典型工作流

1. `Ctrl+Shift+A` 打开面板 → 对话
2. agent 改文件 → 编辑器内看 **原生 diff**
3. 长任务 → 看工具调用卡片与计划面板
4. 需要时在会话工具栏切换模型/推理档位

---

## 5. 踩坑记录（2026-08-17 实测）

### 5.1 Windows 侧 spawn 的 node 找不到 / 0xC0000142

- **现象**：扩展日志 `node: command not found`（WSL bash 里没有 node）
- **根因**：VS Code 是 Remote-WSL 模式，扩展在 WSL 侧 spawn，而 WSL 原本无 Node
- **解决**：WSL 装 Node + `sudo npm i -g deepseek-acp`，`command` 用 `deepseek-acp`（见 §3）

> 关联问题：Windows 侧 `dsh web` 若从 **Claude Code 的 Store 版 pwsh** 启动，DSH 派生所有子进程都会 0xC0000142（DLL 初始化失败）——那是 MSIX 打包环境污染，与 ACP 无关。**`dsh web` 要用普通终端启动**。详见 `agent-rules/DeepSeek/README.md`。

### 5.2 `--setup` 报"环境变量已提供，拒绝写入"

- **现象**：Windows 侧 `deepseek-acp --setup` 报 `"DEEPSEEK_API_KEY" is supplied read-only by the launching environment`
- **根因**：shell 里已有 `DEEPSEEK_API_KEY` 环境变量，credential 服务认为文件写入会被遮蔽
- **解决**：WSL 侧无此环境变量，直接 `--setup` 成功。若确需在已有环境变量的 shell 里写文件，先 `unset DEEPSEEK_API_KEY`

### 5.3 ACP `session/prompt` 的 prompt 参数必须是数组

- **现象**：探针发 `prompt: {type:"text",...}` 报 `Invalid params: expected array, received object`
- **解决**：按 ACP 规范传 `prompt: [{type:"text", text:"..."}]`

### 5.4 VS Code 扩展 spwan 带绝对路径的 node 脚本报 EFTYPE

- **现象**：`command: node` + `args: [...bin.js]` 报 `spawn EFTYPE`
- **解决**：Windows 侧 Node spawn `.js` 文件需显式 `node` 解释器；最终方案（WSL 侧 `command: deepseek-acp`）无此问题

---

## 6. 官方参考链接

- [ACP 协议](https://agentclientprotocol.com)
- [deepseek-acp（npm）](https://www.npmjs.com/package/deepseek-acp)
- [deepseek-acp 仓库（GitHub）](https://github.com/xintaofei/deepseek-acp)
- [ACP Client for VS Code（marketplace）](https://marketplace.visualstudio.com/items?itemName=formulahendry.acp-client)
- [官方 dsh-acp（automation-only 对比）](https://github.com/deepseek-ai/DeepSeek-Harness/blob/master/examples/acp-agent/README.zh.md)

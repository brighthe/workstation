# DeepSeek Harness 使用指南

> - **更新日期**：2026-08-17
> - **版本**：`@deepseek-ai/dsh` v0.1.0-rc.6（developer preview）
> - **适用环境**：Windows 11、Windows PowerShell、Node.js v24.19.0
> - **认证方式**：DeepSeek API Key，仅通过 Web UI 界面录入

本文介绍 DeepSeek Harness（`dsh`）的安装与日常使用。能力导读见 [`capabilities.md`](capabilities.md)；本机配置面管理见 [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)。

> [!IMPORTANT]
> DSH 是 developer preview，官方声明会有 compatibility-breaking changes。升级后请重新核对本文的目录结构与命令。

---

## 1. 平台选择：Windows 原生，不需要 WSL

官方**没有操作系统推荐**，也没有"Windows 必须用 WSL"的说法。CI 里 Linux 与 Windows 都是必过主任务，macOS 当前 disabled；插件清单有 `dsh-sandbox-windows-acl`、`dsh-tool-pwsh` 等 Windows 专用实现。**结论：Windows 原生安装即可**，本机 Node v24.19.0 正落在官方主测版本上。

---

## 2. 安装

### 2.1 快速试用（不推荐长期使用）

```powershell
npx @deepseek-ai/dsh web
```

落在 npx 临时缓存（`%LOCALAPPDATA%\npm-cache\_npx\`），`npm cache clean` 即失效。首次拉包约 9 分钟**全程无输出**，属正常现象。

### 2.2 全局安装（推荐）

```powershell
npm install -g @deepseek-ai/dsh
dsh -V
```

安装位置：`C:\Users\Administrator\AppData\Roaming\npm\dsh`。

> [!NOTE]
> npm 提示 5 个包 install script 未执行（`node-pty`、`koffi` 等）**无需处理**——预编译二进制随包下发。注意包**嵌套**在 `node_modules\@deepseek-ai\dsh\node_modules\` 下，不在全局顶层。

### 2.3 从源码构建（仅开发插件时需要）

```powershell
git clone https://github.com/deepseek-ai/deepseek-harness.git
cd deepseek-harness; pnpm install; pnpm run build; pnpm dsh web
```

依赖 pnpm（仓库钉 `pnpm@11.7.0`，`corepack enable pnpm` 启用）。适用场景仅三种：写插件、改 agent loop 或 preset、**钉版本做可复现实验**。

---

## 3. 命令行接口

```
dsh [options] [command] [args...]

Options:
  -V, --version               版本号
  --profile <name>            启动 $DSH_HOME/profiles 下的指定 profile
  --patch <path>              在 profile 层之后追加 patch 覆盖层（可重复）
  --dump-config               打印合成后的 profile 树并退出
  --dump-default-config       打印不含用户层与 --patch 的 profile 树并退出

Commands:
  web [args...]               启动 web profile（等价于 --profile web）
  plugin [args...]            将后续参数转发给 pnpm，管理指定 profile 的插件
```

排查配置问题时，`--dump-config` 与 `--dump-default-config` 对比着看，能直接定位是哪一层 patch 改了行为。

---

## 4. 两个入口

官方随包分发的 profile **只有 `web` 和 `headless`**，首次使用时自动初始化。日常交互用 Web UI，批量自动化用 headless；要在 **VS Code 编辑器内**使用见 §5。

### 4.1 Web UI（默认）

```powershell
dsh web
```

监听 `http://127.0.0.1:3080`。首次打开需确认内测声明，然后配置模型并选择 workspace。前台占用终端，`Ctrl+C` 停止。

**启动选项**（`dsh web --help` 可见；官方 README 未列出，为实测）：

| 选项 | 说明 |
| :--- | :--- |
| `--host <host>` | 绑定地址，默认 `127.0.0.1` |
| `--port <port>` | 监听端口，默认 `3080`；传 `0` 让 OS 分配空闲端口 |
| `--trusted-host <authority...>` | `/api` 浏览器信任围栏额外接受的 authority，可重复 |

```powershell
dsh web --port 8080
```

**界面要点**：

| 位置 | 元素 | 说明 |
| :--- | :--- | :--- |
| 左侧栏 | New Session / Workspaces | 会话与工作区管理 |
| 标题行 | `Standard mode` | 当前 agent preset，可切换 |
| 标签页 | Chat / **Trajectory** | Trajectory 展示完整执行轨迹 |
| 右上 | **Session log** | 一键导出会话日志 |
| 输入框旁 | `Workspace Write` | 权限预设档位 |
| 输入框旁 | `DeepSeek-V4-Flash` / `High` | 模型与推理强度 |
| 底部 | turns / steps、TTFT、tok/s、cache hit、token | 实时用量条 |

### 4.2 Headless（一次性 CLI）

```powershell
dsh --profile headless "run the tests"
```

给一个任务、打印最终回复、退出，**不起 server**——可塞进脚本、跑批量实验。首次运行自动初始化 profile；只想初始化不耗 API 额度，用 `--help` 触发：

```powershell
dsh --profile headless --help
```

### 4.3 自定义 profile 与 TUI 的真相

> [!CAUTION]
> **官方没有 TUI。** 网传的 `dsh plugin --profile tui add deepseek-harness-tui` 是**错的**——`tui` 只是官方 help 里随手举的自定义 profile 名示例，那个包不存在。三条独立核对（2026-08-14）：官网产品页零处提及 TUI；GitHub `apps/` 只有 `cli` 与 `web`；npm 无任何 tui 相关包。

`dsh plugin` 机制本身是真的：把参数原样转发给 profile 目录下的 pnpm，用于往**自定义 profile** 装包：

```powershell
dsh plugin --profile <name> add <package>
```

本机未使用该机制（依赖 pnpm，且无可装的 UI 包）。第三方 `Hmbown/DeepSeek-TUI` 是独立终端 agent 项目，**与 DSH 无关**。

---

## 5. VS Code 编辑器接入（ACP）

通过 [ACP（Agent Client Protocol）](https://agentclientprotocol.com) 协议，把 DSH 接成 **VS Code 编辑器内的编码 Agent**（类似 Codex 插件体验）。本机 2026-08-17 实测跑通。

### 5.1 为什么用 deepseek-acp 而非官方 dsh-acp

官方 ACP server（`@deepseek-ai/dsh-acp`）定位 **automation-only**——官方原文：*"This package is a transport adapter, not a UI integration... It does not expose editor navigation, transcript replay, commands, modes... or tool presentation."* 只发已提交消息，工具调用、思考、diff 全留在日志里，给人用不行。

**`deepseek-acp`（社区实现 v0.3.0）** 用同一个 harness 内核换了一张编辑器向的协议面，与本机 dsh rc.6 依赖一致：

| 能力 | 官方 dsh-acp | **deepseek-acp** |
|---|---|---|
| 回复流式 | 仅整段提交后推送 | ✅ 逐 token |
| 思考过程 / 工具调用 | ✗ 不呈现 | ✅ 卡片 + 状态流转 |
| 文件 diff / 终端输出 | ✗ | ✅ 编辑器原生 diff / 终端卡片 |
| 待办计划 / 会话恢复 | ✗ | ✅ `plan` / `load` / `list` / `resume` |
| 会话内换模型 / slash 命令 | ✗ | ✅ |
| MCP / 读未保存缓冲区 | ✗ | ✅ 按会话挂载 / `fs/read_text_file` 改道 |

> [!IMPORTANT]
> `deepseek-acp` 是**非官方社区适配器**（MIT），未获 DeepSeek 背书。

### 5.2 架构

```
VS Code（Remote-WSL）
 ├── 编辑器界面（Windows 窗口：文件树/diff/终端/调试器）
 └── ACP Client 扩展（formulahendry.acp-client）
      └── spawn：deepseek-acp（WSL 内）→ DSH agent 内核（工具/会话/沙箱）
```

IDE 能力由 VS Code 提供，Agent 大脑由 DSH 提供，二者经 **ACP（JSON-RPC over stdio）** 打通。**关键：agent 进程跑在 WSL 侧**——`deepseek-acp`、Node、API Key 都要在 WSL 里就绪，与 Windows 侧完全隔离。

### 5.3 安装

```bash
# ① WSL 侧装 Node 24
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
# ② WSL 侧装 deepseek-acp（必须 sudo：全局 npm 目录归 root）
sudo npm install -g deepseek-acp
deepseek-acp --version   # 0.3.0
# ③ WSL 侧配置 API Key（唯一需要手动输入 Key 的步骤）
deepseek-acp --setup     # 写入 ~/.dsh/.credentials.yaml（0600）
```

```powershell
# ④ VS Code 装扩展
code --install-extension formulahendry.acp-client
```

⑤ 编辑用户 settings.json（`Ctrl+Shift+P` → `Preferences: Open User Settings (JSON)`）：

```json
"acp.agents": {
    "DeepSeek Harness": {
        "command": "deepseek-acp",
        "args": [],
        "env": {}
    }
}
```

> `command` 填 `deepseek-acp` 即可（扩展在 WSL bash 下 spawn）。`env` 留空：Key 走 `~/.dsh/.credentials.yaml`，不入配置、不随 Settings Sync 同步。

⑥ `Ctrl+Shift+P` → `Developer: Reload Window` → Activity Bar 点 **ACP 图标** → 选 "DeepSeek Harness" → Connect。

### 5.4 日常使用

**打开**：`Ctrl+Shift+A`（快捷键）/ Activity Bar ACP 图标 / 命令面板 `ACP: Open Chat Panel`。

**常用**：`ACP: New Conversation`（新会话）、`Escape`（取消回合）、`ACP: Set Agent Mode / Model`、`ACP: Show Log` / `ACP: Show Protocol Traffic`（排错）。

**工作流**：对话 → agent 改文件看原生 diff → 长任务看工具卡片与计划面板 → 会话工具栏切换模型/推理档位。

### 5.5 踩坑记录（2026-08-17 实测）

1. **扩展日志 `node: command not found`**：VS Code 是 Remote-WSL，扩展在 WSL 侧 spawn 而 WSL 原本无 Node → 按 §5.3 装 Node + `sudo npm i -g deepseek-acp`。
2. **`--setup` 报"环境变量已提供，拒绝写入"**：shell 已有 `DEEPSEEK_API_KEY` 时 credential 服务拒绝写文件 → WSL 侧无此变量可正常 `--setup`；确需写文件先 `unset DEEPSEEK_API_KEY`。
3. **`session/prompt` 报 `expected array, received object`**：ACP 规范要求 `prompt` 传数组 `[{type:"text", text:"..."}]`。
4. **spawn 绝对路径 `.js` 报 EFTYPE**：Windows 侧 Node spawn `.js` 需显式 `node` 解释器；WSL 侧 `command: deepseek-acp` 无此问题。
5. **看不到往期聊天记录**：deepseek-acp 会话在 WSL 的 `~/.dsh/sessions`，与 Web UI 的 Windows 侧 `$DSH_HOME\sessions` **存储隔离**；且 `session/list` 按 `cwd` 过滤。VS Code 里建的会话在**同一工作区**重连后可见，Web UI 旧会话在 Web UI 里看。

> 关联：Windows 侧 `dsh web` 若从 **Claude Code 的 Store 版 pwsh** 启动，所有子进程会 0xC0000142（MSIX 环境污染）——**`dsh web` 要用普通终端启动**。

---

## 6. 目录结构（`$DSH_HOME`）

默认 `C:\Users\Administrator\.dsh`：

```text
.dsh/
├── settings.yaml          # 全局设置
├── .anonymous-user-id     # 匿名标识
├── profiles/
│   ├── web/
│   └── headless/
├── sessions/              # 会话持久化，按 workspace 分目录
└── storages/              # workspace.json、session_projcache.json
```

每个 profile 目录内：

| 文件 | 作用 | 能不能改 |
| :--- | :--- | :--- |
| `package.json` | `dsh.profile.bundles` 声明 bundle 顺序 | 可改，增删 bundle |
| `cordis.yml` | profile 根，空数组 `[]` | **不要改**，文件头已注明 |
| `cordis.patch.yml` | 用户 patch 层，在所有 bundle 层之后应用 | **改这里** |
| `pnpm-workspace.yaml` | pnpm 工作区声明 | 一般不动 |

配置层级从下往上：各 bundle 层 → `cordis.patch.yml` → `--patch` 覆盖层；另有 home 级 `$DSH_HOME/cordis.patch.yml` 全局覆盖（本机未创建）。

> [!NOTE]
> 官方 CLI README 称 profile 含 `dsh.profile` 文件；实测**并无此文件**，该配置是 `package.json` 里的 `dsh.profile` 键。以实测为准。

---

## 7. Workspace 与跨文件系统

Web UI 启动后选择 workspace，会话按 workspace 分目录存放于 `sessions/`。本机当前指向 WSL 工作区 `\\wsl.localhost\Ubuntu-24.04\home\brighthe\workspace`——**Windows 侧运行 dsh，操作 WSL 内文件**。

跨文件系统访问经 9P 协议，文件密集操作会明显慢于原生路径；若要在 WSL 工作区做重活，考虑 WSL 内装原生 Node 与 dsh。WSL 侧现状无原生 Node（`node` 不在 PATH），不要直接在 WSL 里跑 `npx`（会用 Windows Node 解释 Linux 路径）。

---

## 8. 安全与凭据

- API Key **只通过 Web UI 界面录入**，不写入配置文件、不设环境变量、不进本仓库。
- 实测 `~/.dsh` 下**无凭据文件**：`settings.yaml` 仅含 onboarding 版本号 + 默认模型 + 语言偏好，各 `cordis.patch.yml` 为空数组。可安全纳入版本控制（见 [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)）。
- `sessions/` 含完整对话与工具调用记录，**可能包含工作区代码与路径，不入库**。
- 不把 DSH 路由到非 DeepSeek 的模型服务；也不再把 Codex 转发到 DeepSeek API。

---

## 9. 常见问题

**`npx` 启动后长时间无输出？**
正常，首次拉包约 9 分钟静默。可用 `Get-NetTCPConnection -LocalPort 3080` 查端口是否已监听。

**npm 提示 install scripts 未执行？**
可忽略，相关包走预编译分发。详见 §2.2。

**`dsh web` 报 `plugin tree failed to load`？**
先看报错**最底部**的 `[cause]`，根因通常只有一行。最常见是端口被占（`listen EADDRINUSE: address already in use 127.0.0.1:3080`）——`dsh-host-webserver` 绑不上端口会导致整棵 plugin tree 加载失败，与插件系统无关。查占用者：

```powershell
Get-NetTCPConnection -LocalPort 3080 -State Listen |
  ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, ProcessName, StartTime }
```

处理：停掉旧实例（`Stop-Process -Id <pid>`），或换端口 `dsh web --port 8080`。

> [!WARNING]
> 多个实例共用同一 `$DSH_HOME` 会并发写会话存储。**优先停掉旧实例而不是换端口并存**；停掉不丢历史（会话已落盘）。

**想换 workspace？**
Web UI 左侧栏可切换，或重启后引导页重选。会话按 workspace 分目录，切换不丢历史。

**选择文件夹报 `directory picker failed: win32 folder dialog worker exited before reporting result`？**
原生目录选择器（`koffi` Win32 COM worker）异常。在 `~/.dsh/profiles/web/cordis.patch.yml` 配置 patch 禁用 native 选择器、启用内置文件树：

```yaml
- id: directory-picker
  disabled: true
- insert:
  - id: directory-picker-browse
    name: '@deepseek-ai/dsh-host-directory-picker-browse'
  - id: ui-directory-picker-browse
    name: '@deepseek-ai/dsh-client-ui-directory-picker-browse'
```

保存后重启 `dsh web`；或直接从资源管理器**拖拽**文件夹到工作区区域。

**怎么确认配置生效了哪一层？**
`dsh --profile <name> --dump-config` 与 `--dump-default-config` 对比。

---

## 10. 官方参考链接

- [DeepSeek Harness 产品页](https://deepseek.com/harness/en/)
- [GitHub 仓库](https://github.com/deepseek-ai/deepseek-harness)
- [CLI 文档](https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/cli)
- [架构文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)
- [开发文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/development.md)
- [npm 包](https://www.npmjs.com/package/@deepseek-ai/dsh)

### VS Code / ACP 相关（§5）

- [ACP 协议](https://agentclientprotocol.com)
- [deepseek-acp（npm）](https://www.npmjs.com/package/deepseek-acp)
- [deepseek-acp 仓库（GitHub）](https://github.com/xintaofei/deepseek-acp)
- [ACP Client for VS Code（marketplace）](https://marketplace.visualstudio.com/items?itemName=formulahendry.acp-client)
- [官方 dsh-acp（automation-only 对比）](https://github.com/deepseek-ai/DeepSeek-Harness/blob/master/examples/acp-agent/README.zh.md)

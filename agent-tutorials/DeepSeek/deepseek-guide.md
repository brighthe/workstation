# DeepSeek Harness 使用指南

> - **更新日期**：2026-08-14
> - **版本**：`@deepseek-ai/dsh` v0.1.0-rc.6（developer preview）
> - **适用环境**：Windows 11、Windows PowerShell、Node.js v24.19.0
> - **认证方式**：DeepSeek API Key，仅通过 Web UI 界面录入

本文介绍 DeepSeek Harness（`dsh`）的安装与日常使用。能力全景与官方教程导读见 [`capabilities.md`](capabilities.md)；本机配置面的管理见 [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)。

> [!IMPORTANT]
> DSH 是 developer preview，官方声明会有 compatibility-breaking changes。升级后请重新核对本文的目录结构与命令。

---

## 1. 平台选择：Windows 原生，不需要 WSL

官方文档**没有给出操作系统推荐**，也没有"Windows 用户必须用 WSL"的要求（网上部分二手博客有此说法，官方无对应表述）。

从 CI 配置看，Linux 与 Windows 都是**必过的主任务**（`dsh-ubuntu-24-04-16core` 与 `dsh-windows-2025-16core`），macOS 任务当前 disabled。插件清单里还有 `dsh-sandbox-windows-acl`、`dsh-tool-pwsh`、`dsh-pwsh-local` 等 Windows 专用实现。

**结论：Windows 原生安装即可**，本机 Node v24.19.0 正落在官方主测版本上。

---

## 2. 安装

### 2.1 快速试用（不推荐长期使用）

```powershell
npx @deepseek-ai/dsh web
```

只落在 npx 临时缓存里（`%LOCALAPPDATA%\npm-cache\_npx\`），`npm cache clean` 即失效，不适合长期使用。首次拉取包体较大，实测约 9 分钟且**全程无输出**，属正常现象，不要误判为卡死。

### 2.2 全局安装（推荐）

```powershell
npm install -g @deepseek-ai/dsh
```

验证：

```powershell
dsh -V
```

安装位置：`C:\Users\Administrator\AppData\Roaming\npm\dsh`。

> [!NOTE]
> 安装时 npm 可能提示 5 个包的 install script 未执行（`node-pty`、`koffi`、`@deepseek-ai/dsh-subprocess-local` 等）。**实测无需处理**：这些包以预编译二进制分发，`node-pty\prebuilds\win32-x64\*.node` 与 `@koromix\koffi-win32-x64\win32_x64\koffi.node` 随包下发，跳过脚本不影响功能。
>
> 注意包是**嵌套**在 `AppData\Roaming\npm\node_modules\@deepseek-ai\dsh\node_modules\` 下，不在全局顶层——排查时别查错路径。

### 2.3 从源码构建（仅开发插件时需要）

```powershell
git clone https://github.com/deepseek-ai/deepseek-harness.git
```

```powershell
cd deepseek-harness; pnpm install; pnpm run build; pnpm dsh web
```

额外依赖：pnpm（仓库钉 `pnpm@11.7.0`，用 `corepack enable pnpm` 启用）、Git 2.26+。

适用场景仅三种：写插件、改 agent loop 或 preset、**钉版本做可复现实验**（preview 期这点尤其重要，`npx` 每次拉最新版）。

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

官方随包分发的 profile **只有 `web` 和 `headless`**，两者都在首次使用时自动初始化（官方无 TUI，理由见 §4.3）。日常交互用 Web UI，批量自动化用 headless；若要在 **VS Code 编辑器内**使用，见 §5（ACP 接入）。

### 4.1 Web UI（默认）

```powershell
dsh web
```

监听 `http://127.0.0.1:3080`。首次打开需确认内测声明，然后配置模型并选择 workspace。前台占用终端，`Ctrl+C` 停止。

#### 启动选项

`web` profile 接受以下参数（`dsh web --help` 可见；官方 README 未列出，以下为 `dsh-web-app/lib/startup.js` 实测）：

| 选项 | 说明 |
| :--- | :--- |
| `--host <host>` | 绑定地址，默认 `127.0.0.1` |
| `--port <port>` | 监听端口，默认 `3080`；传 `0` 让 OS 分配空闲端口 |
| `--trusted-host <authority...>` | `/api` 浏览器信任围栏额外接受的 authority（`host` 或 `host:port`），可重复 |

```powershell
dsh web --port 8080
```

端口的解析链在配置里是这样的（`dsh --profile web --dump-config` 可见）：

```yaml
- id: webserver
  name: '@deepseek-ai/dsh-host-webserver'
  config:
    host: !!js ctx.webStartup.host ?? '127.0.0.1'
    port: !!js ctx.webStartup.port ?? 3080
```

即 CLI 参数经 `@deepseek-ai/dsh-web-app/startup` 注入 `ctx.webStartup`，未指定时回落到默认值。

界面要点：

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

给一个任务、打印最终回复、退出，**不起 server**。这是能塞进脚本、跑批量实验的形态，配合 append-only 会话日志构成可复现评测的基础。

首次运行会自动初始化 profile。若只想初始化而不消耗 API 额度，用 `--help` 触发：

```powershell
dsh --profile headless --help
```

### 4.3 自定义 profile（`dsh plugin`）——以及为什么没有 TUI

> [!CAUTION]
> **官方没有 TUI。** 网上（包括本文档 2026-08-14 之前的版本）流传的 `dsh plugin --profile tui add deepseek-harness-tui` 是**错的**，那个包不存在。
>
> 误解来自官方 help 文本里的这一行：
>
> ```text
> dsh plugin --profile tui add <package>     install a plugin into the tui profile
> ```
>
> `<package>` 是尖括号占位符，`tui` 只是"随便举个自定义 profile 名字"的示例。CLI README 里另一处写得更明白：`--profile tui --resume <id>` 后面跟着 "**assuming** the tui profile is installed"。

三条独立核对（2026-08-14，v0.1.0-rc.6）：

| 来源 | 结果 |
| :--- | :--- |
| [官网产品页](https://deepseek.com/harness/en/) | 全页零处提及 TUI / terminal UI；Get Started 只给 `npx @deepseek-ai/dsh web` 与 clone 源码两条路径 |
| GitHub `apps/` 目录 | 只有 `cli` 与 `web` |
| npm + 本机 194 个包 | 无任何 tui 相关包（`@deepseek-ai/dsh-tui`、`deepseek-harness-tui` 等均 not found） |

官网确实说 UI 是可替换插件之一（"Plugins provide every agent capability, including ... **and the UI**"），所以写一个终端 UI 在架构上成立——但那是**开发任务**，不是安装任务，官方没有现成实现。

#### `dsh plugin` 机制本身是真的

它把参数原样转发给 profile 目录下的 pnpm，可用于往**自定义 profile** 里装包：

```powershell
dsh plugin --profile <name> add <package>
```

`--profile <name>` 指定的 profile 在首次使用时创建。该命令依赖 pnpm，本机未启用（有 `corepack` 0.35.0，需 `corepack enable pnpm`）。

**本机未使用该机制**，上述命令未经实测。既然没有可装的 UI 包，暂无启用 pnpm 的必要。

> [!NOTE]
> 第三方 `Hmbown/DeepSeek-TUI` 是个独立的终端 agent 项目（走 cargo / homebrew 安装），**与 DSH 无关**，不要当成 DSH 的 tui profile。

---

## 5. VS Code 编辑器接入（ACP）

通过 [ACP（Agent Client Protocol）](https://agentclientprotocol.com) 协议，可以把 DSH 接成 **VS Code 编辑器内的编码 Agent**（类似 Codex 插件的体验）。本机已于 2026-08-17 实测跑通。

### 5.1 为什么是 deepseek-acp，而不是官方 dsh-acp

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

### 5.2 架构：谁在哪一侧

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

### 5.3 安装步骤

**① WSL 侧：Node.js 24**

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node -v   # 实测 v24.19.0
```

**② WSL 侧：全局安装 deepseek-acp**

```bash
sudo npm install -g deepseek-acp
deepseek-acp --version   # 0.3.0
```

> [!NOTE]
> 必须 `sudo`：全局 npm 目录 `/usr/lib/node_modules` 归 root 所有，普通用户 `npm i -g` 会报 `EACCES`。装完可执行文件在 PATH 内，普通用户可运行。

**③ WSL 侧：配置 API Key**

```bash
deepseek-acp --setup
```

交互式粘贴 Key，写入 `~/.dsh/.credentials.yaml`（0600）。这是**唯一需要手动输入 Key 的步骤**。

> 凭据边界：`~/.dsh/.credentials.yaml` 含密钥，**不进仓库、不提交**。它与 Windows 侧 `$DSH_HOME` 完全独立。

**④ VS Code：安装 ACP Client 扩展**

```powershell
code --install-extension formulahendry.acp-client
```

或在扩展市场搜 **ACP Client**（作者 formulahendry）。Remote-WSL 下会同时装到 WSL 侧的扩展目录。

**⑤ VS Code：配置 agent**

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

**⑥ 重载并连接**

`Ctrl+Shift+P` → `Developer: Reload Window` → 左侧 Activity Bar 点 **ACP 图标** → 选 "DeepSeek Harness" → Connect → 开始对话。

### 5.4 日常使用

**快速打开 ACP：**

| 方式 | 操作 |
|---|---|
| 快捷键 | `Ctrl+Shift+A`（打开聊天面板） |
| 侧边栏 | Activity Bar 的 ACP 图标 |
| 命令面板 | `Ctrl+Shift+P` → `ACP: Open Chat Panel` |

**常用操作：**

| 命令 | 说明 |
|---|---|
| `ACP: New Conversation` | 新会话 |
| `ACP: Cancel Current Turn` | 取消当前回合（`Escape`） |
| `ACP: Set Agent Mode / Model` | 切换模式/模型 |
| `ACP: Show Log` / `ACP: Show Protocol Traffic` | 排错日志 |
| `ACP: Restart Agent` | 重启 agent 进程 |

**典型工作流：**

1. `Ctrl+Shift+A` 打开面板 → 对话
2. agent 改文件 → 编辑器内看 **原生 diff**
3. 长任务 → 看工具调用卡片与计划面板
4. 需要时在会话工具栏切换模型/推理档位

### 5.5 踩坑记录（2026-08-17 实测）

**5.5.1 Windows 侧 spawn 的 node 找不到 / 0xC0000142**

- **现象**：扩展日志 `node: command not found`（WSL bash 里没有 node）
- **根因**：VS Code 是 Remote-WSL 模式，扩展在 WSL 侧 spawn，而 WSL 原本无 Node
- **解决**：WSL 装 Node + `sudo npm i -g deepseek-acp`，`command` 用 `deepseek-acp`（见 §5.3）

> 关联问题：Windows 侧 `dsh web` 若从 **Claude Code 的 Store 版 pwsh** 启动，DSH 派生所有子进程都会 0xC0000142（DLL 初始化失败）——那是 MSIX 打包环境污染，与 ACP 无关。**`dsh web` 要用普通终端启动**。详见 `agent-rules/DeepSeek/README.md`。

**5.5.2 `--setup` 报"环境变量已提供，拒绝写入"**

- **现象**：Windows 侧 `deepseek-acp --setup` 报 `"DEEPSEEK_API_KEY" is supplied read-only by the launching environment`
- **根因**：shell 里已有 `DEEPSEEK_API_KEY` 环境变量，credential 服务认为文件写入会被遮蔽
- **解决**：WSL 侧无此环境变量，直接 `--setup` 成功。若确需在已有环境变量的 shell 里写文件，先 `unset DEEPSEEK_API_KEY`

**5.5.3 ACP `session/prompt` 的 prompt 参数必须是数组**

- **现象**：探针发 `prompt: {type:"text",...}` 报 `Invalid params: expected array, received object`
- **解决**：按 ACP 规范传 `prompt: [{type:"text", text:"..."}]`

**5.5.4 VS Code 扩展 spawn 带绝对路径的 node 脚本报 EFTYPE**

- **现象**：`command: node` + `args: [...bin.js]` 报 `spawn EFTYPE`
- **解决**：Windows 侧 Node spawn `.js` 文件需显式 `node` 解释器；最终方案（WSL 侧 `command: deepseek-acp`）无此问题

**5.5.5 看不到往期聊天记录**

- **现象**：VS Code/ACP 里看不到之前的会话
- **根因**：① deepseek-acp 会话日志在 WSL 的 `~/.dsh/sessions`，与 Web UI 的 Windows 侧 `$DSH_HOME\sessions` **存储隔离**；② `session/list` 按 `cwd` 过滤，只返回当前工作区的会话
- **解决**：VS Code 里创建的会话在**同一工作区**重连后可见（ACP 面板 agent 节点下展开）；Web UI 的旧会话在 Web UI 里看。两套历史默认不互通

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

以 `headless` 为例：

```json
{
  "name": "dsh-profile-headless",
  "private": true,
  "dependencies": {},
  "dsh": {
    "profile": {
      "bundles": ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-headless"]
    }
  }
}
```

配置层级从下往上：各 bundle 层 → `cordis.patch.yml` → `--patch` 覆盖层。另有 home 级 `$DSH_HOME/cordis.patch.yml` 提供全局覆盖（本机尚未创建）。

> [!NOTE]
> 官方 CLI README 称 profile 目录含 `dsh.profile` 文件；v0.1.0-rc.6 实测**并无此文件**，该配置是 `package.json` 里的 `dsh.profile` 键。以实测为准。

---

## 7. Workspace 与跨文件系统

Web UI 启动后需选择 workspace，会话按 workspace 分目录存放于 `sessions/`。

本机当前指向 WSL 工作区：

```text
\\wsl.localhost\Ubuntu-24.04\home\brighthe\workspace
```

即 **Windows 侧运行 dsh，操作 WSL 内的文件**。这条路径可用，但需注意：跨文件系统访问经由 9P 协议，文件密集操作（大规模搜索、批量读写）会明显慢于原生路径。若后续要在 WSL 工作区做重活，考虑改为在 WSL 内安装原生 Node 与 dsh。

WSL 侧现状：**无原生 Node**，`node` 不在 PATH，`npm`/`npx` 仅通过 interop 解析到 Windows 的 `/mnt/c/Program Files/nodejs/`。这种状态下在 WSL 里直接跑 `npx` 会用 Windows Node 解释 Linux 路径，不要这么用。如需 WSL 原生环境，先装 nvm 再装 Node LTS。

---

## 8. 安全与凭据

- API Key **只通过 Web UI 界面录入**，不写入配置文件、不设环境变量、不进本仓库。
- 实测 `~/.dsh` 下**没有凭据文件**：`settings.yaml` 仅含 onboarding 版本号，各 `cordis.patch.yml` 为空数组。因此这些文件可安全纳入版本控制（见 [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)）。
- `sessions/` 含完整对话与工具调用记录，**可能包含工作区代码与路径，不入库**。
- 不把 DSH 路由到非 DeepSeek 的模型服务；也不再把 Codex 转发到 DeepSeek API。

---

## 9. 常见问题

**`npx` 启动后长时间无任何输出？**
正常。首次拉包实测约 9 分钟全程静默。确认进度可看 `%LOCALAPPDATA%\npm-cache\_npx\` 下目录的时间戳，或用 `Get-NetTCPConnection -LocalPort 3080` 查端口是否已监听。

**npm 提示 install scripts 未执行？**
可忽略，相关包走预编译分发。详见 §2.2。

**`dsh web` 报一大段 `plugin tree failed to load`？**
先看报错**最底部**的 `[cause]`，根因通常只有一行。最常见的是端口被占：

```text
Error: dsh: plugin tree failed to load: failed to apply loader entry include (cordis:include):
failed to apply loader entry webserver (@deepseek-ai/dsh-host-webserver):
listen EADDRINUSE: address already in use 127.0.0.1:3080
```

`dsh-host-webserver` 绑不上端口会导致**整棵 plugin tree 加载失败**，所以栈很长，但和插件系统本身无关。查占用者：

```powershell
Get-NetTCPConnection -LocalPort 3080 -State Listen |
  ForEach-Object { Get-Process -Id $_.OwningProcess | Select-Object Id, ProcessName, StartTime }
```

两种处理：停掉旧实例（`Stop-Process -Id <pid>`），或换端口 `dsh web --port 8080`。

> [!WARNING]
> 多个实例共用同一个 `$DSH_HOME`（`sessions/`、`storages/` 都在其中），会并发写同一份会话存储。除非确有需要，**优先停掉旧实例而不是换端口并存**。停掉旧实例不丢历史——会话已落盘，新实例启动后照常可见。

**想换 workspace？**
Web UI 左侧栏可切换；或停掉服务后重新启动并在引导页重选。会话按 workspace 分目录保存，切换不会丢历史。

**Web UI 点击选择文件夹报 `directory picker failed: win32 folder dialog worker exited before reporting result`？**
Windows 下原生目录选择器（`@deepseek-ai/dsh-host-directory-picker-native`）派生的 Win32 COM worker 子进程在调用底层 `koffi` 时异常退出。

解决方案：在 `$DSH_HOME/profiles/web/cordis.patch.yml`（即 `~/.dsh/profiles/web/cordis.patch.yml`）中配置 patch 禁用 native 选择器并启用随包自带的 Web 内置文件树选择器：

```yaml
- id: directory-picker
  disabled: true
- insert:
  - id: directory-picker-browse
    name: '@deepseek-ai/dsh-host-directory-picker-browse'
  - id: ui-directory-picker-browse
    name: '@deepseek-ai/dsh-client-ui-directory-picker-browse'
```

保存后重启 `dsh web` 即可；或在界面中直接将目标文件夹从资源管理器**拖拽**至工作区区域。

**怎么确认配置到底生效了哪一层？**
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

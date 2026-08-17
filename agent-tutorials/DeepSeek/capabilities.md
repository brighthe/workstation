# DeepSeek Harness 能力与官方教程导读

这个文档是给我自己看的，用来帮助我理解 DeepSeek Harness（下称 DSH）官方推出的能力和最新教程。文档结构：定位与使用边界 → 两个正交维度（profile / mode）→ 能力清单 → 跟进机制。

定位（与本仓库其他 DeepSeek 文件的分工）：

- [`deepseek-guide.md`](deepseek-guide.md)：安装与日常使用指南（含 §5 VS Code/ACP 接入）。
- [`agent-rules/DeepSeek/README.md`](../../agent-rules/DeepSeek/README.md)：本机配置面的**管理**说明。
- 本文档：官方**能力与教程**的导读，含个人使用状态。

维护原则：不做官方文档的镜像；只放"筛选 + 一句话说明 + 入口链接 + 我的使用状态"。

> [!IMPORTANT]
> DSH 当前为 **developer preview（0.1.x）**，官方明确声明会有 compatibility-breaking changes。本文所有"实测"结论均标注核对日期与版本号；跨版本不保证成立。

---

## 1. 定位与使用边界

一句话：**DSH 不是模型，是让模型能在真实环境里干活的那层外壳。**

官方原话是"模型是 agent 的灵魂，harness 让 agent 理解环境、使用工具、并在真实场景中持续工作"。所以它的对标物是 Claude Code、Codex CLI 这类 agent 运行框架，而不是 DeepSeek 的模型本身。

| 维度 | 状态（2026-08-14 核对，v0.1.0-rc.6） |
| :--- | :--- |
| 开源协议 | MIT |
| 成熟度 | developer preview，API 与核心插件快速迭代中 |
| 官方 IDE 扩展 | **无**，也无 VS Code / JetBrains 插件。包清单里存在 API / 协议层（`dsh-api-gateway`、`dsh-api-remotes`、`dsh-host-apiproxy`、`dsh-typert-protocol`），理论上可据此写外部客户端，**协议细节与稳定性未实测** |
| 平台支持 | Linux 与 Windows 均为 CI 必过任务；macOS 任务当前处于 disabled 状态 |
| Node 要求 | 22.19+ 或 24+（CI 覆盖 22.19 / 24 / 26） |

### 我的使用边界

- **已接入 VS Code 日常工作流**（2026-08-17 起）：通过 `deepseek-acp` 在 VS Code 编辑器内使用 DSH（见 [`deepseek-guide.md`](deepseek-guide.md) §5）；Web UI 仍可用作完整交互入口。
- 不把 DSH 路由到非 DeepSeek 的模型服务；同理，也不再把 Codex 转发到 DeepSeek API（见 [`agent-rules/Codex/README.md`](../../agent-rules/Codex/README.md) 的认证与旧配置清理一节）。
- API Key 只通过官方界面或凭据流程提供（`deepseek-acp --setup` 写入 `~/.dsh/.credentials.yaml`），**不写入本仓库任何文件**。

---

## 2. 架构：一切皆插件

底座是 **Cordis kernel**，负责插件的 mount / unmount 与依赖解析。DSH 把 agent 的每一层都做成了可替换插件：模型、工具与技能、会话、沙箱、存储、调度、UI，**乃至 agent 主循环本身**。

官方主张：不修改 DSH 源码，仅靠配置即可选择、替换、扩展任意能力。

v0.1.0-rc.6 全局安装后实测约 200 个 `@deepseek-ai/dsh-*` 包，能看出能力边界，摘几类有代表性的：

| 包名 | 说明 |
| :--- | :--- |
| `dsh-agent-loop`、`dsh-agent-presets` | agent 主循环与预设（即下文的 mode） |
| `dsh-llm-deepseek`、`dsh-llm-retry` | 模型接入与重试 |
| `dsh-sandbox-windows-acl`、`node-addon-landlock-run` | Windows ACL 沙箱 / Linux Landlock 沙箱 |
| `dsh-tool-pwsh`、`dsh-tool-bash`、`dsh-tool-bash-persistent` | PowerShell 与 Bash 工具，含持久终端 |
| `dsh-session-persistence-jsonl`、`dsh-session-query-sqlite` | 会话持久化与检索 |
| `dsh-subagent-*`、`dsh-workflow`、`dsh-schedule` | 子 agent、工作流与调度 |
| `dsh-mcp-client` | MCP 客户端 |
| `dsh-skill`、`dsh-skill-filesystem` | 技能机制 |
| `dsh-compaction-*`、`dsh-token-meter`、`dsh-spill-*` | 上下文压缩、token 计量与溢出处理 |

`dsh-sandbox-windows-acl` 和 `dsh-tool-pwsh` 的存在，印证了 Windows 是正经一等公民，不是勉强能跑。

社区插件通过 GitHub topic `dsh-plugin` 发现。

---

## 3. 两个正交维度：profile 与 mode

这两个概念容易混，但**不是一回事**，配置位置也不同。

### 3.1 Profile —— 应用外壳（进程形态）

决定 DSH 以什么形态启动，由 `$DSH_HOME/profiles/<name>/package.json` 的 `dsh.profile.bundles` 声明。

| Profile | 形态 | bundles | 状态 |
| :--- | :--- | :--- | :--- |
| `web` | 浏览器 UI，默认 `http://127.0.0.1:3080` | `dsh-base` + `dsh-web-app` | ✅ 已装并验证，首次使用自动初始化 |
| `headless` | 一次性 CLI：给一个任务、打印结果、退出，**无 server** | `dsh-base` + `dsh-headless` | ✅ 已装并验证，首次使用自动初始化 |

**官方只有这两个 profile**，都在首次使用时从内置模板自动初始化。其他 profile 需自建，通过 `dsh plugin` 往里装包（转发给 pnpm）。

> [!CAUTION]
> **没有官方 TUI**（2026-08-14 核对，三条独立证据：官网产品页零处提及、GitHub `apps/` 只有 `cli` 与 `web`、npm 与本机 194 个包中无 tui 相关包）。
>
> 官方 help 里的 `dsh plugin --profile tui add <package>` 是**占位示例**——`<package>` 是尖括号占位符，`tui` 只是随手举的自定义 profile 名。据此推出的包名 `deepseek-harness-tui` **不存在**。详见 [`deepseek-guide.md`](deepseek-guide.md) §4.3。
>
> 第三方 `Hmbown/DeepSeek-TUI` 是独立终端 agent（cargo / homebrew 安装），与 DSH 无关。

### 3.2 Mode —— agent 预设（行为形态）

决定 agent 拿到哪些工具、如何编排，由 `dsh-agent-presets` 提供，在 UI 里可切换（当前会话标题旁显示 `Standard mode`）。

| Mode | 说明 | 适用 |
| :--- | :--- | :--- |
| **Standard** | 完整编码 agent：文件编辑、shell、搜索 | 日常使用 |
| **Code Mode** | 工具以 SDK 形式暴露给模型，由模型自行编排多步操作，而非逐次 tool call | 复杂多步任务 |
| **Minimal** | 仅两个工具：持久 bash + `str_replace_editor` | **benchmark 专用** |
| **Creator** | 开发自定义 preset，带 runtime inspection | 扩展开发 |

`Minimal` 是官方明确为 benchmark 设计的，配合下节的会话日志，是 DSH 做可复现评测的完整姿势。

---

## 4. 能力清单（带个人状态）

| 能力 | 一句话 | 我的状态 |
| :--- | :--- | :--- |
| **会话可追溯** | prompt、reasoning、tool call、context injection 全部写入 **append-only 会话日志**，支持 resume / fork / search / replay | 待深入，评测复现的关键 |
| **Trajectory 视图** | Web UI 中与 Chat 并列的标签页，展示完整执行轨迹 | 已见入口，未深用 |
| **Session log 导出** | Web UI 右上角一键导出会话日志 | 已见入口，未深用 |
| **Workspace 选择** | 启动时选定工作目录，会话按 workspace 分目录持久化 | ✅ 已用（指向 WSL 工作区） |
| **权限预设** | 输入框旁可选权限档位（如 `Workspace Write`） | ✅ 已用默认档 |
| **模型与推理强度** | 输入框旁选模型与 reasoning 档位（如 `DeepSeek-V4-Flash` + `High`） | ✅ 已用 |
| **实时用量条** | 底部显示 turns / steps、LLM 耗时、TTFT、tok/s、cache hit、输入输出 token | ✅ 已用 |
| **VS Code 编辑器接入（ACP）** | 通过 `deepseek-acp`（社区 ACP server）把 DSH 接进 VS Code：流式回复、思考过程、工具卡片、diff、终端输出、会话恢复 | ✅ 已用（2026-08-17 跑通，见 [`deepseek-guide.md`](deepseek-guide.md) §5） |
| **子 agent** | `dsh-subagent-*`，支持 fork 与 spawn | 未用 |
| **工作流与调度** | `dsh-workflow`、`dsh-schedule` | 未用 |
| **MCP 客户端** | `dsh-mcp-client` | 未用 |
| **技能机制** | `dsh-skill`、`dsh-skill-filesystem` | 未用 |
| **上下文压缩** | `dsh-compaction-basic`、`dsh-compaction-tool-result-pruner` | 未用 |
| **沙箱** | Windows ACL / Linux Landlock 两套实现 | 未验证实际隔离效果 |

---

## 5. 跟进机制（官方最新动态从哪看）

### 固定信息源

- **官方产品页**：https://deepseek.com/harness/en/
- **GitHub 仓库**：https://github.com/deepseek-ai/deepseek-harness
- **架构文档**：https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md
- **开发文档**：https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/development.md
- **CLI 文档**：https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/cli
- **npm 包**：https://www.npmjs.com/package/@deepseek-ai/dsh
- **社区插件**：GitHub topic [`dsh-plugin`](https://github.com/topics/dsh-plugin)

### 维护方式

DSH 目前**没有官方 changelog 或周报**，跟进只能靠仓库本身。建议节奏：

1. 关注 npm 包版本号变化（`npm view @deepseek-ai/dsh version`），rc 递进即意味着可能的 breaking change。
2. 版本跳动后重新核对本文第 3 节（profile 结构与 mode 清单），这两处最易随版本变动。
3. 发现具有稳定官方入口的新能力时补进第 4 节清单，状态统一填"待标注"。
4. 没有实质变化时不修改本文档。文档改动不自动暂存、commit 或 push，由我审阅后提交。

> [!NOTE]
> 已知文档与实现不一致（2026-08-14，v0.1.0-rc.6）：官方 CLI README 称每个 profile 含 `dsh.profile` **文件**，实测该配置实为 `package.json` 内的 `dsh.profile` **键**，目录下并无同名文件。以实测为准，并在版本更新后重新核对。

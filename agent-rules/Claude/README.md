# Claude 全局配置与指令管理说明

> - **整理日期**：2026-08-14
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Claude Code CLI

本文档用于管理 Claude Desktop、Claude Code CLI 与 VS Code 扩展的全局指令、配置与启动入口。Claude 使用 Claude 订阅登录或 Anthropic 官方 API；DeepSeek 等其他产品应使用各自的客户端或 Harness，不再复用 Claude 的启动函数、环境变量或模型路由。

---

## 核心分工

- **`CLAUDE.md`（全局指令）**：由用户主动编写与维护，存放 Claude 应长期无条件遵守的行为准则、工作模式与环境约束。每个会话开始时完整加载。
- **自动记忆（Auto Memory）**：由 Claude 自动学习并生成的上下文笔记（构建命令、调试见解、项目偏好），存放在 `~/.claude/projects/<project>/memory/`。

---

## 实际文件链接与跨系统绑定

本目录下的 [`CLAUDE.md`](CLAUDE.md) 为唯一维护源头，通过系统软链接（Symbolic Link / Hard Link）同时绑定至两套环境：

- **[workstation 仓库主文件](CLAUDE.md)**：[`C:\workspace\workstation\agent-rules\Claude\CLAUDE.md`](file:///C:/workspace/workstation/agent-rules/Claude/CLAUDE.md)
- **Windows 全局绑定路径**：`C:\Users\Administrator\.claude\CLAUDE.md`
- **WSL Linux 全局绑定路径**：`\\wsl.localhost\ubuntu-24.04\home\brighthe\.claude\CLAUDE.md`

---

## 配置文件镜像清单（硬链接 / 符号链接）

与 Codex 侧（`agent-rules/Codex/`）一致，Claude 侧实际生效的配置文件统一以本目录为维护源头，通过链接绑定到各环境。修改本目录文件（或任意链接端）即同步生效。

| 仓库文件（源头） | 绑定位置 | 链接类型 |
| :--- | :--- | :--- |
| `CLAUDE.md` | `C:\Users\Administrator\.claude\CLAUDE.md`（Windows） | 硬链接 |
| `CLAUDE.md` | `~/.claude/CLAUDE.md`（WSL，指向 `~/workspace/workstation/` 副本） | 符号链接 |
| `settings.json` | `C:\Users\Administrator\.claude\settings.json` | 硬链接 |
| `profile-pwsh7.ps1` | `C:\Users\Administrator\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | 硬链接 |
| `profile-ps51.ps1` | `C:\Users\Administrator\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | 硬链接 |
| `hooks/git-origin-context.ps1` | 由 `settings.json` 的 `PreToolUse` Hook 调用 | 普通文件 |
| `settings-wsl.json` | `~/.claude/settings.json`（WSL，指向 `/mnt/c` 仓库文件） | 符号链接 |

> [!WARNING]
> - 硬链接仅同卷（C:）有效；仓库被复制/克隆到其他机器或分区后链接退化为普通文件，需重新执行创建命令。
> - **硬链接会因"原子替换写入"而断开**（2026-08-09 实证）：Claude Code 自动改写（`/config`、权限追加）或使用 Edit/Write 工具修改仓库源文件都会产生新 inode，断开后生效文件停留在旧内容。检测：`fsutil hardlink list <仓库文件>`（正常应显示 2 个路径）；重建：`Remove-Item <生效路径>; New-Item -ItemType HardLink -Path <生效路径> -Target <仓库文件>`。
> - `settings.local.json`（每机本地权限规则）**不镜像**——Claude Code 会频繁自动追加，且各机规则不同。

---

## settings.json 共享键/环境键管理规则

两份 `settings.json`（Windows 侧 `settings.json`、WSL 侧 `settings-wsl.json`）各为完整可用文件，按键分类维护：

| 类别 | 键 | 维护规则 |
| :--- | :--- | :--- |
| **共享键**（两文件必须一致） | `model`、`theme`、`autoCompactWindow`、`cleanupPeriodDays`、`effortLevel` | 改动时两文件同步修改 |
| **环境键**（各自独立） | `hooks`、`statusLine`（Windows）；`permissions.allow`、`additionalDirectories`（WSL） | 只改对应环境的文件 |

共享键一致性检查：

```powershell
$w = Get-Content agent-rules\Claude\settings.json -Raw | ConvertFrom-Json
$l = Get-Content agent-rules\Claude\settings-wsl.json -Raw | ConvertFrom-Json
@('model','theme','autoCompactWindow','cleanupPeriodDays','effortLevel') | ForEach-Object { "{0}: {1} vs {2}" -f $_, $w.$_, $l.$_ }
```

> 说明：WSL 侧暂不迁移 `hooks`/`statusLine`（命令为 Windows 风格，跨环境需适配 `powershell.exe` 与路径转换，属后续工作）。

---

## 认证与旧路由清理

- Claude Desktop、Claude Code CLI 和 VS Code 扩展使用 Claude 订阅登录或 Anthropic 官方 API；第三方模型路由不属于本目录支持的工作流。
- 原先的 `claude-ds`、`claude_ds_func.sh`、`ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic` 和 `codex-deepseek` 启动函数均已废弃并应删除。
- `DEEPSEEK_API_KEY` 不由本目录管理或删除；若独立 DeepSeek Harness 仍使用它，应继续由该 Harness 自行管理。
- `settings.json` 与 `settings-wsl.json` 保留为 Claude 官方配置，不应加入第三方 Base URL、模型映射或第三方认证令牌。

---

## 全局指令中文详细对照与解读（`CLAUDE.md`）

为了方便查阅与日常维护，以下为精简优化后的 [`CLAUDE.md`](CLAUDE.md) 完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量名、命令、配置键及产品名称保持**英文**原文。

### 2. 交互模式建议（Interaction Mode）
- 在新会话或非平凡任务开始前，在一行内向用户建议适合的模式，由用户决定：
  - **默认模式（Manual/问答）**：只读问答、解释说明、简单澄清 ➔ 直接回答。
  - **Plan 计划模式**：多步骤代码修改、重构、配置文件变更 ➔ 建议使用 Plan 模式（`/plan`）。
  - **Goal 目标模式**：长周期、可验证、自动化运行至完成的工作 ➔ 建议使用 `/goal <条件>`。
- 简单后续追问跳过建议，保持简洁。

### 3. 操作请示与确认原则（Operational Work）
- **非只读操作必须“先请示、后执行”**：对于任何修改机器状态或消耗实际算力的操作（创建/修改 Conda 环境、安装包、`git worktree`/`checkout`、代码编译、模型训练、运行测试、MPI 任务、启动脚本等），**先给出计划与完整命令，询问用户是否执行，等待用户明确批准后再运行**。严禁“先斩后奏”。
- **只读检查自由执行**：只读性质的检查（`git status/log/show/diff`、查看文件列表、读取文件、检查已安装版本、静态代码搜索等）无需请示，可直接执行。
- **Plan 批准 ≠ 执行授权**：用户批准 Plan 仅代表认可总体方案，在具体执行命令前仍需再次请示。
- **显式指令即授权**：当用户显式要求运行某命令（如“跑一下”、“run it”），则该次运行获得授权。

### 4. 批判性评估（Critical Evaluation）
- 对用户提出的方案进行独立评估，而非盲目接受：检查正确性、可行性、核心假设、风险、权衡与替代方案。
- 如果用户的方案存在错误、过大风险或明显劣于其他方案，必须给出具体理由并推荐更好的方案，再继续执行。
- 若用户明确要求完全按其方案执行，遵从用户的同时需简要进行风险提示。

### 5. 个人背景信息（About Me）
- **用户**：何亮 (Liang He)，GitHub `brighthe`，邮箱 `brighthe98@gmail.com`。
- **身份与方向**：大连理工大学博士后，研究方向为拓扑优化、有限元（FEM）及物理信息机器学习（PIML）。

### 6. 工作区仓库治理（Workspace Repository Governance）
- 仓库划分为 `authoring`（`C:\workspace`）与 `compute`（WSL `~/workspace`）两层，具体分工、数据源头与远程分支路由统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- 遵守项目级 `CLAUDE.md` / `AGENTS.md` / `README.md`。提交或推送前核对 `origin`。
- 标记为 `company` / `suanhaitech` 的仓库属于单位资产，禁止将其代码、数据、凭据或内部文档复制到个人仓库。

### 7. AI 指令文件界限与文档优先（Scope & Documentation）
- 仅维护 Claude 相关的指令文件（`CLAUDE.md`、`~/.claude/`）。未经允许不修改其他 AI 工具的指令文件。
- 当询问 Claude Code 功能或配置时，必须优先查阅并依据 [Claude Code 英文官方文档](https://code.claude.com/docs/en/) 进行回答，避免凭空猜测。

### 8. Windows 与 WSL 执行规范（Windows & WSL Execution）
- Windows 仓库使用 PowerShell 与原生 Windows Git/OpenSSH。
- `compute` 阶层仓库位于 WSL 中，其 Git 操作必须在 Linux 内部执行（如 `wsl -d Ubuntu-24.04 -- git -C /home/brighthe/workspace/<repo>`）。
- **Python 运行指定**：
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - 长时间运行输出重定向至 `logs/run.log`；绘制图片保存至 `figs/`。

### 9. Git 暂存区卫生（Git Staging Hygiene）
- 提交前仔细检查 Working Tree，仅 Stage 与当前任务相关的修改文件，严禁盲目使用 `git add -A`。

---

## 官方参考链接

- [Claude Code 官方中文总览](https://code.claude.com/docs/zh-CN/overview)
- [记忆与 CLAUDE.md 官方说明](https://code.claude.com/docs/zh-CN/memory)
- [Claude Code 认证与第三方配置](https://code.claude.com/docs/en/authentication)

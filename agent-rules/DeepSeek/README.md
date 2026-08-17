# DeepSeek Harness 全局配置管理

> - **整理日期**：2026-08-14
> - **版本**：`@deepseek-ai/dsh` v0.1.0-rc.6（developer preview）
> - **适用环境**：Windows 11、Windows PowerShell、Node.js v24.19.0

本文档用于管理 DeepSeek Harness（`dsh`）的本机配置面。安装与日常使用见 [`agent-tutorials/DeepSeek/deepseek-guide.md`](../../agent-tutorials/DeepSeek/deepseek-guide.md)；能力导读见 [`agent-tutorials/DeepSeek/capabilities.md`](../../agent-tutorials/DeepSeek/capabilities.md)。

> [!IMPORTANT]
> DSH 为 developer preview，配置结构会随版本变动。升级后先用 `dsh --dump-config` 核对，再同步本目录。

---

## 与其他 agent 配置的差异

Codex、Claude Code、Antigravity 都有一个**全局指令文件**（`AGENTS.md` / `CLAUDE.md` / `GEMINI.md`）。

**DSH 也有对应物**：随 base bundle 挂载的 `@deepseek-ai/dsh-agent-instructions` 插件会加载用户全局指令文件 `$DSH_HOME/AGENTS.md`（源码 `USER_GLOBAL_FILE = "AGENTS.md"`，即 `C:\Users\Administrator\.dsh\AGENTS.md`），每个会话开始时作为 baseline 完整加载；工作区内的 `AGENTS.md` / `CLAUDE.md`（含 `.local` 变体）则按"项目根 → 当前目录"逐层发现，作为作用域指令注入。本目录的 [`AGENTS.md`](AGENTS.md) 即 DSH 的全局指令文件，通过硬链接绑定到 `$DSH_HOME/AGENTS.md`（见下文链接一览与硬链接一节）。

与 Codex 等由 [`scripts/setup-global-instruction-links.ps1`](../../scripts/setup-global-instruction-links.ps1) 统一建立**符号链接**不同，DSH 这条线沿用本目录既有约定：**硬链接 + 本文档记录**。因此**本目录仍不纳入 `setup-global-instruction-links.ps1`**（该脚本只处理 SymbolicLink，且 DSH 文件另有 LF 行尾等约束）。

---

## 纳管对象：官方仅有的两个 profile

DSH 随包分发的 profile **只有两个**，均在首次使用时从内置模板自动初始化。本目录纳管的正是它们各自的用户 patch 层。

| Profile | 形态 | 启动 | 本目录对应文件 |
| :--- | :--- | :--- | :--- |
| `web` | 浏览器 UI，默认 `http://127.0.0.1:3080`，前台常驻 | `dsh web` | `profile-web.cordis.patch.yml` |
| `headless` | 一次性 CLI：给一个任务、打印最终回复、退出，无 server | `dsh --profile headless "<任务>"` | `profile-headless.cordis.patch.yml` |

两者于 2026-08-14 均已实测通过（`web` 验证到 HTTP 200 + 前端渲染 + console 无错误；`headless` 两次任务均正常返回）。

> [!IMPORTANT]
> **没有第三个入口，官方无 TUI。** 详细证据与常见误解见 [`agent-tutorials/DeepSeek/deepseek-guide.md`](../../agent-tutorials/DeepSeek/deepseek-guide.md) §4.3。若将来官方新增 profile，需同步扩充本目录的纳管清单与下方链接表。

启动参数、界面要点、权限档位与沙箱行为等**使用层面**的内容不在本文档，见上述指南。本文档只管配置文件本身。

---

## 配置分层

DSH 的配置从下往上合成，后一层覆盖前一层：

```text
各 bundle 层（package.json 的 dsh.profile.bundles 按序）
  → $DSH_HOME/cordis.patch.yml      （home 级全局覆盖，本机尚未创建）
  → profiles/<name>/cordis.patch.yml（profile 级用户层）
  → --patch <path>                  （命令行临时覆盖层）
```

核对当前生效配置：

```powershell
dsh --profile web --dump-config
```

对比不含用户层的基线：

```powershell
dsh --profile web --dump-default-config
```

---

## 目录文件与链接一览

`$DSH_HOME` = `C:\Users\Administrator\.dsh`

| 文件 | 作用 | 真实路径 | 链接 |
| :--- | :--- | :--- | :--- |
| `AGENTS.md` | **全局指令文件**（每个会话开始自动加载） | `C:\Users\Administrator\.dsh\AGENTS.md` | 硬链接（建立后验证，见下文） |
| `settings.yaml` | 全局设置（onboarding 状态 + 默认模型 + 语言偏好，Web UI 可改写） | `C:\Users\Administrator\.dsh\settings.yaml` | 硬链接（2026-08-14 建立并验证；**2026-08-14 发现已断链**，重建见下文） |
| `profile-web.cordis.patch.yml` | `web` profile 用户 patch 层 | `C:\Users\Administrator\.dsh\profiles\web\cordis.patch.yml` | 硬链接（2026-08-14 建立并验证） |
| `profile-headless.cordis.patch.yml` | `headless` profile 用户 patch 层 | `C:\Users\Administrator\.dsh\profiles\headless\cordis.patch.yml` | 硬链接（2026-08-14 建立并验证） |
| `README.md` | 本说明文档 | 本目录 | 普通文件 |

### 不纳管的文件

| 路径 | 原因 |
| :--- | :--- |
| `profiles/<name>/cordis.yml` | profile 根，文件头明确注明**不要修改**，用户改动一律进 `cordis.patch.yml` |
| `profiles/<name>/package.json` | 由 dsh 生成与维护；改 bundle 时手动记录变更即可，不做链接 |
| `profiles/*/node_modules/`、`pnpm-workspace.yaml` | 依赖产物，随安装重建 |
| `sessions/` | **含完整对话、工具调用与工作区路径，不入库** |
| `storages/` | 运行时缓存（`workspace.json`、`session_projcache.json`） |
| `.anonymous-user-id` | 本机标识，无跨设备意义 |

---

## 凭据边界

- DeepSeek API Key **只通过 Web UI 界面录入**；不写入配置文件、不设环境变量、不进本仓库。
- 实测（2026-08-14，v0.1.0-rc.6）`~/.dsh` 下**无凭据文件**：`settings.yaml` 仅 onboarding 版本号 + 默认模型 + 语言偏好，各 `cordis.patch.yml` 为空数组 `[]`。因此本目录纳管的四个文件（含 `AGENTS.md`）不含密钥。
- **settings.yaml 会被 Web UI 改写**（Models 页写默认模型、设置页写语言偏好），且**改写采用替换式写入会断开硬链接**（2026-08-14 实测断链）。同步或编辑前先核对文件 ID，断链则按下文硬链接一节重建；仓库副本落后时以实际文件为准更新。
- **每次同步前重新确认**：若将来 DSH 把凭据写入 `settings.yaml` 或 patch 层，必须停止纳管该文件，不得提交。
- DSH 不路由到非 DeepSeek 的模型服务；Codex 也不再转发到 DeepSeek API（见 [`agent-rules/Codex/README.md`](../Codex/README.md) 的认证与旧配置清理一节）。

---

## 硬链接

四个文件的绑定已建立并验证（`fsutil file queryfileid` 两侧一致；`settings.yaml` 与两个 patch 层为 2026-08-14 建立，`AGENTS.md` 建立于 2026-08-14 并随后验证）。重装 dsh 或升级后可能被替换而断链，用下面的方法重建。

先确认目标文件当前状态：

```powershell
Get-Item C:\Users\Administrator\.dsh\AGENTS.md | Select-Object FullName, LinkType, Target
```

确认为普通文件且内容已同步到本目录后，再建立硬链接（会覆盖目标，务必先核对内容一致）：

```powershell
New-Item -ItemType HardLink -Path C:\Users\Administrator\.dsh\AGENTS.md -Value C:\workspace\workstation\agent-rules\DeepSeek\AGENTS.md -Force
```

`settings.yaml` 同理指向本目录同名文件（**2026-08-14 曾因 Web UI 替换式写入断链，已同步仓库副本并按下式重建**）；`web` 与 `headless` 的 patch 层分别指向 `profile-web.cordis.patch.yml` 与 `profile-headless.cordis.patch.yml`。

```powershell
New-Item -ItemType HardLink -Path C:\Users\Administrator\.dsh\settings.yaml -Value C:\workspace\workstation\agent-rules\DeepSeek\settings.yaml -Force
```

> [!WARNING]
> 硬链接要求源与目标在**同一卷**。本机两侧均在 `C:`，满足条件。
>
> 参照 [`agent-rules/Codex/README.md`](../Codex/README.md) 的维护约定：**不假设同名文件为硬链接**，编辑或同步前用 `Get-Item ... | Select-Object FullName, LinkType, Target` 检查实际关系。
>
> 硬链接的判定不能只看 `LinkType`——Windows 上硬链接的 `LinkType` 常显示为空。可靠方法是比对文件 ID：
>
> ```powershell
> fsutil file queryfileid C:\Users\Administrator\.dsh\settings.yaml
> fsutil file queryfileid C:\workspace\workstation\agent-rules\DeepSeek\settings.yaml
> ```
>
> 两者相同即为同一个文件。

> [!CAUTION]
> **这四个文件是 LF 行尾，编辑时不要用 `Set-Content`**——它会静默转成 CRLF，文件体积变化（217 → 221 字节）且与 dsh 原始模板不再一致。用支持保留行尾的编辑器，或直接写字节：
>
> ```powershell
> [IO.File]::WriteAllText($path, $text.Replace("`r`n","`n"))
> ```
>
> 就地改写不会断开硬链接（已验证）；但**替换式**写入（先删后建）会断链，之后需按上文重建。

---

## 全局指令中文详细对照与解读（`AGENTS.md`）

为了方便查阅与日常维护，以下为精简优化后的 [`AGENTS.md`](AGENTS.md) 完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量名、命令、配置键、API 名称及产品名称保持**英文**原文。

### 2. 交互模式建议（Interaction Mode）
- 在新会话或非平凡任务开始前，在一行内向用户建议合适的模式，由用户决定：
  - **默认模式（Normal）**：只读问答、解释说明、简单澄清 ➔ 直接回答。
  - **Plan 计划模式**：多步骤代码修改、重构、配置文件变更 ➔ 建议使用 Plan 模式。
  - **Goal 目标模式**：长周期、可验证、自动运行至完成的工作 ➔ 建议使用 Goal，且**必须有明确的停止条件**（非显式要求不主动开启）。
- 简单后续追问跳过建议，保持简洁。

### 3. 操作请示与确认原则（Operational Work）
- **操作型工作默认"先请示、后执行"**：对于任何修改机器状态或消耗实际算力的操作（安装包、创建/修改环境、`git worktree`/`clone`/`checkout`、构建、训练、测试、基准、MPI 任务、长时脚本等），**先给出计划与确切命令，询问用户是否执行，等待明确批准后再运行**。严禁"先斩后奏"。
- **只读检查自由执行**：`git status/log/show/diff`、查看文件列表、读取文件、版本检查、静态搜索等只读操作无需请示，可直接执行。
- **Plan 批准 ≠ 执行授权**：用户批准 Plan 仅代表认可总体方案，具体执行命令前仍需再次请示。
- **显式指令即授权**：用户显式要求运行某命令（如"跑一下"、"run it"），则该次运行获得授权。

### 4. 批判性评估（Critical Evaluation）
- 对用户提出的方案进行独立评估，而非盲目接受：检查正确性、可行性、关键假设、风险、权衡与替代方案。
- 如果用户的方案存在错误、过大风险或明显劣于其他方案，必须给出具体理由并推荐更好的方案，再继续执行。
- 若用户明确要求完全按其方案执行，遵从用户的同时需简要进行风险提示。

### 5. 个人背景信息（About Me）
- **用户**：何亮 (Liang He)，GitHub `brighthe`，邮箱 `brighthe98@gmail.com`。
- **身份与方向**：大连理工大学博士后，研究方向为拓扑优化、有限元（FEM）及物理信息机器学习（PIML）。

### 6. 工作区仓库治理（Workspace Repository Governance）
- 仓库划分为 `authoring`（`C:\workspace`）与 `compute`（WSL `~/workspace`）两层，具体分工、数据源头与远程分支路由统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- 遵守项目级 `AGENTS.md` / `CLAUDE.md` / `README.md`。提交或推送前核对 `origin`。
- 标记为 `company` / `suanhaitech` 的仓库属于单位资产，禁止将其代码、数据、凭据或内部文档复制到个人仓库。

### 7. AI 指令文件界限与文档优先（Scope & Documentation）
- 仅维护 DeepSeek 相关的指令文件（`AGENTS.md`、`~/.dsh/`）。未经允许不修改其他 AI 工具的指令文件（如 `CLAUDE.md`）。
- 当询问 DSH 功能或配置时，必须优先查阅并依据官方文档（[DeepSeek Harness 产品页](https://deepseek.com/harness/en/)、[GitHub 仓库](https://github.com/deepseek-ai/deepseek-harness)）与本仓库 [`agent-tutorials/DeepSeek/`](../../agent-tutorials/DeepSeek/) 教程回答，避免凭空猜测。

### 8. DeepSeek Harness 特有规则（DSH Specifics）
- **启动方式**：`dsh web` 打开浏览器 UI（`http://127.0.0.1:3080`）；`dsh --profile headless "<任务>"` 一次性执行后退出。
- **配置分层**：bundle 层 → profile `cordis.patch.yml` → `$DSH_HOME/cordis.patch.yml` → `--patch` 覆盖层；用 `dsh --profile web --dump-config` 预览；**不要直接改 `cordis.yml` 或 bundle 文件**。
- **纳管文件维护**：`agent-rules/DeepSeek/` 下的文件通过硬链接绑定到 `~/.dsh/`，保持同步、保留 LF 行尾，用 `fsutil file queryfileid` 核对链接关系。
- **凭据边界**：DeepSeek API Key 只通过 Web UI 录入，不写入配置文件、不设环境变量、不进本仓库。

### 9. Windows 与 WSL 执行规范（Windows & WSL Execution）
- Windows 仓库使用 PowerShell 与原生 Windows Git/OpenSSH。
- `compute` 阶层仓库位于 WSL 中，其 Git 操作必须在 Linux 内部执行（如 `wsl -d Ubuntu-24.04 -- git -C /home/brighthe/workspace/<repo>`）。
- **Python 运行指定**：
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - 长时间运行输出重定向至 `logs/run.log`；绘制图片保存至 `figs/`。

### 10. Git 暂存区卫生（Git Staging Hygiene）
- 提交前仔细检查 Working Tree，仅 Stage 与当前任务相关的修改文件，严禁盲目使用 `git add -A`；未经用户明确指示，不自动执行 `git commit` 或 `git push`。

---

## 升级后的核对清单

DSH 版本跳动（尤其 rc 递进）后依次确认：

1. `dsh -V` 与本文档记录的版本是否一致，不一致则更新本文与两份教程的版本标注。
2. `profiles/<name>/` 目录结构是否变化（v0.1.0-rc.6 为 `package.json` + `cordis.yml` + `cordis.patch.yml` + `pnpm-workspace.yaml`）。
3. 四个纳管文件的硬链接是否仍然有效（重装可能替换真实文件从而断链），其中 `AGENTS.md` 断链会导致全局指令不再加载。
4. `settings.yaml` 是否新增了含凭据的字段——**若有，立即停止纳管**。
5. `dsh --dump-config` 与 `--dump-default-config` 对比，确认用户层仍按预期生效。

---

## 官方参考链接

- [DeepSeek Harness 产品页](https://deepseek.com/harness/en/)
- [GitHub 仓库](https://github.com/deepseek-ai/deepseek-harness)
- [CLI 文档（profile 与配置分层）](https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/cli)
- [架构文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)

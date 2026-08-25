# OpenCode 全局配置与指令管理

> - **整理日期**：2026-08-20（2026-08-21 更新为双端部署）
> - **适用环境**：WSL Ubuntu（compute）+ Windows Desktop（authoring），双端部署

本文档用于管理 OpenCode（开源、模型中立）的全局指令、配置与使用规范。OpenCode 全局规则与配置位于各自用户目录：WSL 在 `~/.config/opencode/`，Windows 在 `%USERPROFILE%\.config\opencode\`。维护源头统一在本目录。

---

## 核心分工

- **`AGENTS.md`（全局规则）**：由用户主动编写与维护，存放 OpenCode 应长期无条件遵守的行为准则、工作模式与环境约束。每次会话开始时自动加载（WSL 位于 `~/.config/opencode/AGENTS.md`，Windows 位于 `%USERPROFILE%\.config\opencode\AGENTS.md`）。
- **`opencode.json`（全局配置）**：模型、provider、权限、MCP、插件等运行时配置（位于 `~/.config/opencode/opencode.json`）。本目录不托管该文件，除非你明确要把可迁移配置入库。
- **项目级规则**：当前 V2 仅识别 `AGENTS.md`。全局规则与从当前位置向上发现的项目规则会组合加载；项目专属规则应写在对应目录层级。

---

## 双端部署与分工约定（2026-08-21）

OpenCode 在 WSL 与 Windows 双端部署，实例与其所管仓库的 `tier` 原生对位：

| 实例 | 前端 | 后端工具链 | 管理范围 |
| :--- | :--- | :--- | :--- |
| WSL（`~/workspace`） | TUI | Linux 工具链（conda `ihpcm` / `soptx-gpu` 等） | compute 仓库：`soptx`、`fealpy`、`mfem`、`mfleo`、`xihe`、`tmp` |
| Windows（`C:\workspace`） | Desktop（Electron） | Windows 工具链（git for Windows 等） | authoring 仓库：`workstation`、`heliangos`、`dut-postdoc`、`xtu-phd-thesis`、`dut-institute-work` 等 |

决策理由：authoring 文档仓库全部位于 Windows NTFS，Windows 原生访问与 git 性能对位最优，且 GUI 更适合 markdown / 图件 / PDF 交互；compute 代码仓库全部位于 WSL 原生文件系统，工具链（conda / MPI）依赖 Linux。

强制约束：

- Windows Desktop **保持连 Windows 本地后端**，不连 WSL server（`opencode serve`）；否则退回 `/mnt/c` 跨文件系统并错位工具链。
- Desktop 只打开 `C:\workspace` 下的仓库，**不开 `\\wsl$\` 路径**；代码仓库永远走 WSL TUI。
- 配置单一事实源为本目录；Windows 侧 `AGENTS.md` 通过同一 C: 卷的 HardLink 与维护源同步，WSL 侧使用其自身软链接。

---

## 实际文件链接与跨系统绑定

本目录下的 [`AGENTS.md`](AGENTS.md) 为唯一维护源头，并链接到两端的全局规则位置：

| 文件 | 作用 | 维护源头 | 绑定路径 |
| :--- | :--- | :--- | :--- |
| `AGENTS.md` | 全局规则（每次会话自动加载） | `C:\workspace\workstation\agent-rules\OpenCode\AGENTS.md` | WSL：`~/.config/opencode/AGENTS.md`（软链接）；Windows：`%USERPROFILE%\.config\opencode\AGENTS.md`（HardLink） |
| `README.md` | 本说明文档 | 本目录 | 普通文件 |

> 注意：`scripts/setup-global-instruction-links.ps1` 负责 Windows 侧链接；WSL 侧仍需建立软链接。WSL 软链接示例：

```bash
mkdir -p ~/.config/opencode
ln -s /mnt/c/workspace/workstation/agent-rules/OpenCode/AGENTS.md ~/.config/opencode/AGENTS.md
```

若目标位置已有普通文件或指向其他位置的链接，先手动备份再处理。

---

## OpenCode 规则与配置要点（易搞错）

- **全局规则位置**是 `~/.config/opencode/AGENTS.md`，不是 `~/.opencode/`。
- **项目规则**：当前 V2 只识别 `AGENTS.md`，不再回退 `CLAUDE.md`。它会组合全局 `~/.config/opencode/AGENTS.md` 与当前位置向上的项目规则；广泛约束放全局，项目差异放就近目录。
- **全局配置**是 `~/.config/opencode/opencode.json`（也支持 `.jsonc`），项目配置是项目根 `opencode.json`，多层配置会合并（后者覆盖冲突键）。
- **引用外部规则文件**：在 `opencode.json` 的 `instructions` 字段里列出路径或 glob（如 `.cursor/rules/*.md`、URL），会与 `AGENTS.md` 合并加载。
- **初始化**：在项目根运行 `/init` 可生成或就地改进该项目的 `AGENTS.md`。
- **权限**：默认放行所有操作；可用 `opencode.json` 的 `permission` 字段对 `edit`/`bash` 等改为 `ask` 或 `deny`。

---

## 全局指令中文详细对照与解读（`AGENTS.md`）

为了方便查阅与日常维护，以下为精简优化后的 [`AGENTS.md`](AGENTS.md) 完整中文规则对照说明：

### 1. 语言规范（Language）
- 默认使用**简体中文**进行回复与沟通。
- 所有的技术术语、方法名、变量、路径、命令、配置键、API 名称及产品名称保持**英文**原文。
- 数学公式统一使用 LaTeX：行内 `$...$`，独立公式 `$$...$$`；不得用 Unicode 符号拼凑公式。

### 2. 交互模式建议（Interaction Mode）
- 在会话或非平凡任务开始时，用一行建议合适的模式，由用户决定：
  - **默认模式**：只读问答、解释与小澄清，直接回答即可。
  - **`plan` agent**：多步编辑、重构、配置变更。
  - **Goal 式连续执行**：长周期、可验证、可运行到底的工作；无原生 Goal 机制，属行为约定——必须有明确可验证的停止条件，且仅在用户显式要求时启动。
- 平凡后续问题跳过建议；建议保持一行。

### 3. 操作型工作——先提议后询问（Operational Work）
- **凡是会改变机器状态或消耗实际算力的操作**（环境/包变更、构建、训练、测试、基准、MPI 任务、长时脚本）：先给出确切命令并请示，获准后才运行——绝不先执行后汇报。只读检查（`git status/log/show/diff`、列目录/读文件/静态搜索、版本查询）自由执行。
- 计划获批只代表方案获批，不等于执行授权；运行前需再次询问。
- 多步骤工作分步推进：每完成一个有意义的环节汇报一次，与用户对齐后再继续（Goal 模式豁免——按停止条件跑到底）。
- 用户明确说“跑一下”（run it）时，对该具体动作直接执行，不再重复确认。

### 4. 批判性评估（Critical Evaluation）
- 将用户提出的方案当作提议进行评估：检查正确性、可行性、关键假设、风险、权衡与替代方案。
- 若方案有误、风险过高或劣于其他选项，先陈述具体原因并推荐更好的方法。
- 若被要求严格按方案执行，则遵守（除非违反安全边界），但先简短标记实质性风险。

### 5. 工作区与执行（Workspace & Execution）
- 工作区分三层：文档仓库（`C:\workspace`，Windows 本机）、代码研发仓库（WSL Ubuntu-24.04 `~/workspace`）与项目代码仓库（WSL Ubuntu-22.04 `~/workspace`）；具体分工、数据源头、远程分支路由与算海边界统一依据 [`workspace/responsibilities.md`](../../workspace/responsibilities.md)。
- WSL 仓库使用 WSL TUI 与 Linux 工具链：`git -C /home/brighthe/workspace/<repo>`；文档仓库使用 Windows Desktop 本地后端，打开 `C:\workspace` 路径。
- WSL 运行 Python：`~/miniconda3/envs/ihpcm/bin/python <script>`（Matrix-Free/MPI）；PINN 使用 `soptx-gpu` 环境。文档任务使用仓库本地的 Windows 环境。
- 长输出 `tee` 到 `logs/run.log`；图片保存到 `figs/`。
- 提交前检查工作树并核对 `origin`，仅暂存与当前任务相关的文件，避免 `git add -A` 宽泛暂存；未经用户明确请求，不执行 `git commit` 或 `git push`。
- 提交信息默认使用简体中文；仓库局部约定优先。

---

## 官方参考链接

- [OpenCode 官方文档](https://opencode.ai/docs)
- [Rules（AGENTS.md 规则）](https://opencode.ai/docs/rules/)
- [Config（opencode.json 配置）](https://opencode.ai/docs/config/)
- [Windows / WSL](https://opencode.ai/docs/windows-wsl)

# OpenCode 全局配置与指令管理

> - **整理日期**：2026-08-20（2026-08-21 更新为双端部署）
> - **适用环境**：WSL Ubuntu（compute）+ Windows Desktop（authoring），双端部署

本文档用于管理 OpenCode（开源、模型中立）的全局指令、配置与使用规范。OpenCode 全局规则与配置位于各自用户目录：WSL 在 `~/.config/opencode/`，Windows 在 `%USERPROFILE%\.config\opencode\`。维护源头统一在本目录。

---

## 核心分工

- **`AGENTS.md`（全局规则）**：由用户主动编写与维护，存放 OpenCode 应长期无条件遵守的行为准则、工作模式与环境约束。每次会话开始时自动加载（WSL 位于 `~/.config/opencode/AGENTS.md`，Windows 位于 `%USERPROFILE%\.config\opencode\AGENTS.md`）。
- **`opencode.json`（全局配置）**：模型、provider、权限、MCP、插件等运行时配置（位于 `~/.config/opencode/opencode.json`）。本目录不托管该文件，除非你明确要把可迁移配置入库。
- **项目级规则**：各仓库根目录的 `AGENTS.md`（缺省回退 `CLAUDE.md`），优先于全局规则。

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
- 配置单一事实源为本目录；Windows 侧 `AGENTS.md` 是复制件，源更新后需手动再同步（Windows 无 WSL symlink 机制）。

---

## 实际文件链接与跨系统绑定

本目录下的 [`AGENTS.md`](AGENTS.md) 为唯一维护源头，需软链接到 WSL 的全局规则位置：

| 文件 | 作用 | 维护源头 | 绑定路径 |
| :--- | :--- | :--- | :--- |
| `AGENTS.md` | 全局规则（每次会话自动加载） | `C:\workspace\workstation\agent-rules\OpenCode\AGENTS.md` | WSL：`~/.config/opencode/AGENTS.md`（软链接）；Windows：`%USERPROFILE%\.config\opencode\AGENTS.md`（复制件） |
| `README.md` | 本说明文档 | 本目录 | 普通文件 |

> 注意：现有 `scripts/setup-global-instruction-links.ps1` 只处理 Windows 侧路径（`%USERPROFILE%\.codex` 等），**尚未覆盖** OpenCode。WSL 侧建立软链接；Windows 侧无跨系统软链接机制，采用复制件（需随源更新手动同步）。WSL 软链接示例：

```bash
mkdir -p ~/.config/opencode
ln -s /mnt/c/workspace/workstation/agent-rules/OpenCode/AGENTS.md ~/.config/opencode/AGENTS.md
```

若目标位置已有普通文件或指向其他位置的链接，先手动备份再处理。

---

## OpenCode 规则与配置要点（易搞错）

- **全局规则位置**是 `~/.config/opencode/AGENTS.md`，不是 `~/.opencode/`。
- **项目规则**：项目根 `AGENTS.md`；若不存在则回退到同目录 `CLAUDE.md`。规则加载优先级：本地逐级向上查找 → 全局 `~/.config/opencode/AGENTS.md` → `~/.claude/CLAUDE.md`。
- **全局配置**是 `~/.config/opencode/opencode.json`（也支持 `.jsonc`），项目配置是项目根 `opencode.json`，多层配置会合并（后者覆盖冲突键）。
- **引用外部规则文件**：在 `opencode.json` 的 `instructions` 字段里列出路径或 glob（如 `.cursor/rules/*.md`、URL），会与 `AGENTS.md` 合并加载。
- **初始化**：在项目根运行 `/init` 可生成或就地改进该项目的 `AGENTS.md`。
- **权限**：默认放行所有操作；可用 `opencode.json` 的 `permission` 字段对 `edit`/`bash` 等改为 `ask` 或 `deny`。

---

## 官方参考链接

- [OpenCode 官方文档](https://opencode.ai/docs)
- [Rules（AGENTS.md 规则）](https://opencode.ai/docs/rules/)
- [Config（opencode.json 配置）](https://opencode.ai/docs/config/)
- [Windows / WSL](https://opencode.ai/docs/windows-wsl)

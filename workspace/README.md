# workspace

`workspace` 是九个科研工作区仓库（六个 `brighthe` 个人仓库、三个 `suanhaitech` 算海仓库）的轻量运维控制面。它只回答四类问题：

1. 应由本机管理哪些仓库；
2. 每个仓库应位于哪里、连接哪个远程；
3. 当前本地检出是否完整、干净并与声明一致；
4. 一项内容应由哪个仓库维护，以及跨仓库时如何只保留结论和指针。

仓库内容、任务、Issue、提交历史和项目级工作流仍由各仓库自行维护。本模块不把这些仓库组成父仓库，不使用 Git submodule，也不自动执行 `pull`、`commit`、`push`、`reset` 或删除操作。

## 单一事实来源

[repositories.json](repositories.json) 是工作区脚本的唯一仓库清单。清单只保存稳定元数据：

| 字段 | 含义 |
| --- | --- |
| `name` | 稳定仓库标识 |
| `relativePath` | 相对所属 tier 根目录的本地路径 |
| `tier` | 运行时归属；当前为 `authoring` 或 `compute` |
| `owner` | GitHub owner；当前为 `brighthe` 或 `suanhaitech` |
| `type` | 所有权类型；当前为 `personal` 或 `company` |
| `remote` | 期望的 `origin` URL |
| `defaultBranch` | 远程默认分支；不要求当前检出位于该分支 |
| `role` | 仓库在科研系统中的唯一主要职责 |
| `purpose` | 面向人的简短用途说明 |

分支状态、当前提交、dirty、ahead/behind 等动态信息不写回清单，由脚本实时读取。算海仓库在这个 Public 清单中只保留最小运维元数据，不记录内部技术目标；临时仓库 `fealpy_heliang` 不纳入。

## 运行时分层与根目录解析

仓库按**运行时归属**分层。判据是「内容由哪套工具链消费」，不是文件类型——`workstation` 全是 PowerShell 代码但属于 `authoring`，因为它的运行时就是 Windows。

| tier | 含义 | 成员 |
| --- | --- | --- |
| `authoring` | 文档写作与 Windows 原生运维；由 Office、LaTeX 编辑器与 PowerShell 消费 | `workstation`、`heliangos`、`dut-postdoc`、`xtu-phd-thesis`、`dut-institute-work` |
| `compute` | 科学计算运行时；需要 Linux 下的 Python、MPI、MKL 与 CMake | `soptx`、`fealpy`、`mfleo`、`xihe` |

成员一列便于速查，**权威来源仍是 [repositories.json](repositories.json) 的 `tier` 字段**；两者不一致时以清单为准。实时分布可由 `status.ps1` 的 `Tier` 列读出。

`tier` 是设备无关的事实（「`soptx` 是计算仓库」在任何机器上都成立），因此写进清单。而「这台机器上 `compute` 落在哪个文件系统」是设备特定的，写进 `roots.local.json`——该文件已加入 `.gitignore`，因为本仓库 Public，发行版名与本机路径不进版本控制。

PC-20260706DAHN 上当前的落点是：`authoring` → `C:\workspace`，`compute` → WSL (Ubuntu-24.04) 的 `~/workspace`。其它设备若未放置 `roots.local.json`，九个仓库全部落在 Windows 工作区根目录下。

[roots.example.json](roots.example.json) 是模板。缺少 `roots.local.json` 时，**所有 tier 一律回退到 Windows 工作区根目录**，行为与引入分层之前完全一致；没有第二运行时的机器无需任何配置。

## 职责与内容路由

[responsibilities.md](responsibilities.md) 是九个仓库职责与跨仓库内容路由的唯一规范。它维护单一职责、事实源去向、引用格式和算海边界；`repositories.json` 不保存这些行为规则。

各 AI 全局指令只引用这份规范，不复制职责表。进入具体仓库后，仍以该仓库自己的 `README.md`、`AGENTS.md`、`CLAUDE.md` 和工作流为准。

## 使用

在 `workstation` 根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\workspace\validate.ps1

powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\workspace\status.ps1
```

- `validate.ps1` 检查清单结构、路径、Git 仓库、默认分支和 `origin`，发现问题时返回非零退出码。
- `status.ps1` 输出分支、dirty、ahead/behind 和远程匹配状态。ahead/behind 基于本地已有的远程引用，不会自动联网执行 `fetch`。
- `status.ps1 -AsObject` 返回可继续通过 PowerShell 管道处理的对象；默认输出适合人工查看的表格。

两个脚本共享 [../scripts/workspace/common.ps1](../scripts/workspace/common.ps1)：它负责解析 tier 根目录，并按根目录类型分派 Git 调用（Windows 直接执行 `git`，WSL 经 `wsl.exe -d <distro> -- git`）。

两个脚本默认从 `workstation` 所在位置推导 Windows 工作区根目录，也可显式传入：

```powershell
.\scripts\workspace\validate.ps1 -WorkspaceRoot 'D:\workspace'
.\scripts\workspace\status.ps1 -WorkspaceRoot 'D:\workspace'
```

当某个 tier 映射到 WSL 时，脚本会区分两类失败：发行版无响应报告为 tier 级环境问题（一条错误），仓库目录缺失才报告为该仓库的问题。这样 WSL 未启动不会被误读成一批仓库丢失。

## 边界

- 本模块拥有仓库清单与本地运维脚本，不拥有任何科研事实。
- `heliangos` 继续作为个人身份和沟通的语义中枢。
- `dut-postdoc`、`dut-institute-work`、`soptx` 继续分别维护研究知识、项目事实和软件实现。
- `xtu-phd-thesis` 维护博士学位论文原始源码与定稿；`dut-postdoc` 只维护从中重新组织和提炼的可复用知识。
- `suanhaitech` 仓库只纳入本地完整性与状态检查；算海代码、数据、凭据和内部文档不得进入个人仓库。
- 各仓库的提交、脱敏、测试与发布规则继续放在各自的 `AGENTS.md`、`README.md` 或工作流文档中。
- 未来增加 `bootstrap.ps1` 前，必须保持显式确认、只克隆缺失仓库且不修改已有检出；第一版不实现该写操作。

# workspace

`workspace` 是八个科研工作区仓库（五个 `brighthe` 个人仓库、三个 `suanhaitech` 公司仓库）的轻量运维控制面。它只回答三类问题：

1. 应由本机管理哪些仓库；
2. 每个仓库应位于哪里、连接哪个远程；
3. 当前本地检出是否完整、干净并与声明一致。

仓库内容、任务、Issue、提交历史和项目级工作流仍由各仓库自行维护。本模块不把这些仓库组成父仓库，不使用 Git submodule，也不自动执行 `pull`、`commit`、`push`、`reset` 或删除操作。

## 单一事实来源

[repositories.json](repositories.json) 是工作区脚本的唯一仓库清单。清单只保存稳定元数据：

| 字段 | 含义 |
| --- | --- |
| `name` | 稳定仓库标识 |
| `relativePath` | 相对工作区根目录的本地路径 |
| `owner` | GitHub owner；当前为 `brighthe` 或 `suanhaitech` |
| `type` | 所有权类型；当前为 `personal` 或 `company` |
| `remote` | 期望的 `origin` URL |
| `defaultBranch` | 远程默认分支；不要求当前检出位于该分支 |
| `role` | 仓库在科研系统中的唯一主要职责 |
| `purpose` | 面向人的简短用途说明 |

分支状态、当前提交、dirty、ahead/behind 等动态信息不写回清单，由脚本实时读取。公司仓库在这个 Public 清单中只保留最小运维元数据，不记录内部技术目标；临时仓库 `fealpy_heliang` 不纳入。

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

两个脚本默认从 `workstation` 所在位置推导工作区根目录，也可显式传入：

```powershell
.\scripts\workspace\validate.ps1 -WorkspaceRoot 'D:\workspace'
.\scripts\workspace\status.ps1 -WorkspaceRoot 'D:\workspace'
```

## 边界

- 本模块拥有仓库清单与本地运维脚本，不拥有任何科研事实。
- `heliangos` 继续作为个人身份和沟通的语义中枢。
- `dut-postdoc`、`dut-institute-work`、`soptx` 继续分别维护研究知识、项目事实和软件实现。
- `suanhaitech` 仓库只纳入本地完整性与状态检查；公司代码、数据、凭据和内部文档不得进入个人仓库。
- 各仓库的提交、脱敏、测试与发布规则继续放在各自的 `AGENTS.md`、`README.md` 或工作流文档中。
- 未来增加 `bootstrap.ps1` 前，必须保持显式确认、只克隆缺失仓库且不修改已有检出；第一版不实现该写操作。

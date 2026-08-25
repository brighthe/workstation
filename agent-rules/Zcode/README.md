# Global instructions for ZCode

> - **整理日期**：2026-08-24
> - **适用环境**：Windows 11、Windows PowerShell、ZCode CLI（Z.ai）

本文档用于管理 ZCode 的全局指令、配置与使用规范。

---

## 核心分工

- **`AGENTS.md`（全局指令）**：由用户主动编写与维护，存放 ZCode 应长期无条件遵守的行为准则、工作模式与环境约束。其 Windows 全局位置为 `%USERPROFILE%\.zcode\AGENTS.md`。ZCode 只读取用户全局 AGENTS.md 与当前工作区 AGENTS.md 两级——先注入全局、后注入工作区（工作区为当前任务的主要项目事实源），不跨目录层级合并；自 v3.7.1 起 subagents 默认也注入这两级。
- **Auto Memory**：ZCode 在会话轮次结束后由后台进程自动提炼值得保留的事实，存放在 `~/.zcode/cli/memories/projects/<project>/memory/`（`MEMORY.md` 索引 + 单条事实 .md）。均为普通文件，可手工编辑或删除；删除项目 memory 目录即完全重置该项目记忆。

---

## 部署

本目录的 [`AGENTS.md`](AGENTS.md) 是唯一维护源。Windows 侧通过
`scripts/setup-global-instruction-links.ps1` 创建 HardLink 到
`%USERPROFILE%\.zcode\AGENTS.md`。

注意：编辑器多以"临时文件 + 原子替换"方式保存，修改维护源后 HardLink 可能断开（用户目录一侧停留在旧 inode）。每次修改后应重跑上述脚本前先删除断开的目标文件，再由脚本重建并验证。

## 官方参考链接

- [ZCODE Docs](https://zcode.z.ai/en/docs)
- [ZCODE Docs：ZCode Agent（AGENTS.md 注入规则）](https://zcode.z.ai/en/docs/agents)
- [ZCODE Docs：Memory](https://zcode.z.ai/en/docs/memory)

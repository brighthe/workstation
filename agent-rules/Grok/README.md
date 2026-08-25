# Global instructions for Grok

> - **整理日期**：2026-08-19
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Grok CLI / Grok Build TUI

本文档用于管理 Grok 的全局指令、配置与使用规范。

---

## 核心分工

- **`AGENTS.md`（全局指令）**：由用户主动编写与维护，存放 Grok 应长期无条件遵守的行为准则、工作模式与环境约束。其 Windows 全局位置为 `%USERPROFILE%\.grok\AGENTS.md`。
- **Auto Memory**：由 Grok 自动学习并生成的上下文笔记，存放在 ~/.grok/ 或对应路径。

---

## 部署

本目录的 [`AGENTS.md`](AGENTS.md) 是唯一维护源。Windows 侧通过
`scripts/setup-global-instruction-links.ps1` 创建 HardLink 到
`%USERPROFILE%\.grok\AGENTS.md`；WSL 若安装 Grok，则将其链接到
`~/.grok/AGENTS.md`。Grok 会先加载该全局规则层，再加载仓库内由根目录到当前目录的规则文件。

## 官方参考链接

- [Grok 官方文档](https://grok.x.ai/)
- [Grok Build：AGENTS.md](https://docs.x.ai/build/features/project-rules)

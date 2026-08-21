# Grok 使用指南

> - **整理日期**：2026-08-19
> - **适用环境**：Windows 11、Windows PowerShell、WSL Ubuntu、Grok CLI / Grok Build TUI

本文档是 Grok 的核心使用指南，包含交互模式、操作规范、个人背景和工作区治理等内容。

## 核心规则

1. **语言规范**：默认使用简体中文回复。技术术语、方法名、变量名、配置文件键、产品名称保持英文原样。
2. **交互模式建议**：在非平凡任务开始前，在一行内向用户建议适合的模式，由用户决定：
   - 默认模式（Manual）：只读问答、解释说明、简单澄清。
   - Plan 计划模式：多步骤代码修改、重构、配置文件变更。
   - Goal 目标模式：长周期、可验证、自动化运行至完成的工作。
3. **操作请示与确认原则**：非只读操作必须先请示、后执行。提供计划和完整命令，询问用户是否执行，等待明确批准后再运行。
4. **批判性评估**：对用户提出的方案进行独立评估，检查正确性、可行性、核心假设、风险、权衡与替代方案。
5. **个人背景**：用户何亮（Liang He），GitHub righthe，邮箱 righthe98@gmail.com，大连理工大学博士后，研究方向为拓扑优化、有限元（FEM）及物理信息机器学习（PIML）。
6. **工作区仓库治理**：仓库分为 uthoring（C:\workspace）和 compute（WSL ~/workspace），具体分工依据 workspace\responsibilities.md。遵守项目级 AGENTS.md/README.md，提交前核对 origin。
7. **作用域限制**：仅维护 Grok 相关的指令文件（AGENTS.md）。未经允许不修改其他 AI 工具的指令文件。
8. **Windows 与 WSL 执行规范**：Windows 使用 PowerShell 与原生 Git/OpenSSH；WSL 仓库在 Linux 内部执行 Git 操作；Python 运行使用指定命令行。
9. **Git 暂存区卫生**：提交前仔细检查 Working Tree，仅 Stage 与当前任务相关的修改文件，严禁盲目使用 git add -A。

## 官方参考链接

- Grok 官方文档：https://grok.x.ai/
- Grok Build TUI 文档：https://code.x.ai/docs

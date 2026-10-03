# 全局指令索引

`agent-rules/<工具>/` 下的指令文件是唯一维护源，用户目录下的同名文件是指向它的符号链接（Windows 与 WSL 均如此）。各目录的 `README.md` 是指令的中文对照。Windows 与 WSL 的用户目录相互独立，工具只读取其运行环境中的那一份，因此两边需各自建立链接。

| 工具 | 维护源 | 链接位置 |
|---|---|---|
| Claude Code | `Claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Codex | `Codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| Antigravity | `Antigravity/GEMINI.md` | `~/.gemini/GEMINI.md` |
| Grok | `Grok/AGENTS.md` | `~/.grok/AGENTS.md` |
| OpenCode | `OpenCode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |

## 建立与校验链接

Windows（以 Claude Code 为例，需管理员 PowerShell 或已开启开发者模式；目标已存在时先确认内容已并入维护源再删）：

```powershell
$src = 'C:\workspace\workstation\agent-rules\Claude\CLAUDE.md'
$dst = "$env:USERPROFILE\.claude\CLAUDE.md"
New-Item -ItemType SymbolicLink -Path $dst -Target $src
(Get-Item $dst).LinkType   # 应输出 SymbolicLink
```

WSL：

```bash
ln -s /mnt/c/workspace/workstation/agent-rules/Claude/CLAUDE.md ~/.claude/CLAUDE.md
```

符号链接只记录路径，维护源被工具或 Git 以"写新文件再替换"的方式改写后仍然有效。

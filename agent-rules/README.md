# 全局指令索引

`agent-rules/<工具>/` 下的指令文件是唯一维护源，用户目录下的同名文件是指向它的链接：Windows 用 HardLink，WSL 用符号链接。各目录的 `README.md` 是指令的中文对照。

| 工具 | 维护源 | 链接位置 |
|---|---|---|
| Claude Code | `Claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| Codex | `Codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| Antigravity | `Antigravity/GEMINI.md` | `~/.gemini/GEMINI.md` |
| Grok | `Grok/AGENTS.md` | `~/.grok/AGENTS.md` |
| OpenCode | `OpenCode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |

## 建立与校验链接

Windows（以 Claude Code 为例，目标已存在时先确认内容已并入维护源再删）：

```powershell
$src = 'C:\workspace\workstation\agent-rules\Claude\CLAUDE.md'
$dst = "$env:USERPROFILE\.claude\CLAUDE.md"
New-Item -ItemType HardLink -Path $dst -Target $src
fsutil hardlink list $src   # 应列出两个路径
```

WSL：

```bash
ln -s /mnt/c/workspace/workstation/agent-rules/Claude/CLAUDE.md ~/.claude/CLAUDE.md
```

工具或 Git 以"写新文件再替换"的方式改写会断开 HardLink，改完用 `fsutil hardlink list` 核对。

# Claude Code 聊天记录跨设备同步（Local 模式 + iCloud Drive）

## 这套方案解决什么

1. **实时访问本地文件** —— 用 Local 模式（Cloud 沙箱拿不到本地文件）。
2. **换设备也有之前的聊天** —— Local 会话只存在本机 `~/.claude/`，没有内置云端托管，
   所以用 **iCloud Drive 文件夹 + 自动同步**自己实现。

链路：

```
Claude Code 写本机 ~/.claude/projects/
  → 脚本增量同步到 iCloud Drive\ClaudeCodeSync
  → iCloud 把文件同步到另一台设备
  → 新设备 pull 还原 → /resume 看到历史会话
```

> 数据（聊天记录）走 iCloud；本仓库只放脚本与流程。Windows 与 WSL2 是**两套独立**的
> `~/.claude`，各配一份同步。

## 文件

- `scripts/claude-code-sync.ps1` —— Windows 同步脚本（纯 ASCII，避免 PS 5.1 编码坑）
- `scripts/claude-code-sync.sh` —— WSL2 / Linux / Git Bash 同步脚本（自动探测 iCloud 路径）
- `templates/settings.json` —— `SessionEnd` 钩子 + 关闭自动清理 的配置模板
- `AGENT-RUNBOOK.md` —— 让 Claude Code 在新机自助安装的指令

## 同步语义（重要，决定会不会丢数据）

| 内容 | 行为 |
|---|---|
| `projects/`（会话本体） | **并集合并**：两边都保留，同名文件谁新留谁（`robocopy /XO` / `rsync --update`），**从不删除** |
| `history.jsonl` / `settings.json` / `CLAUDE.md` | **整文件覆盖**，不合并。`pull` 时本地旧版先备份成 `*.bak` 再被覆盖 |

- 会话文件按 UUID 命名，不同机器几乎不会撞名 → 正常串行使用就是干净的并集。
- 唯一会丢东西：同一 UUID 会话在两台机器都改过 → 只保留较新的整份文件（非按行合并）。
- 别两台设备同时写同一会话。

## 必须记住的注意点

1. **路径必须一致（成败关键）**。会话目录按项目**绝对路径**编码命名
   （`C:\Users\brigh\Projects\x` → `C--Users-brigh-Projects-x`）。新设备**用户名、项目路径**
   要与原机一致，`/resume` 才会自动列出；否则需手动重命名 `~/.claude/projects/` 下的编码目录。
2. **iCloud 必须"始终保留在本设备"**。默认按需下载，不固定会读到空壳占位文件。
   文件资源管理器 → 右键 `ClaudeCodeSync` → 「始终保留在本设备」。
3. **路径长度上限**。iCloud for Windows 下文件名或路径超 256 字符不同步。把 `ClaudeCodeSync`
   放盘根附近，留意 iCloud 的"未同步"提示。
4. **特殊字符**。含 `/ : * ? "` 的文件名在 Windows 下不会同步（编码目录用短横线没问题）。
5. **关掉 30 天自动清理**。模板已设 `cleanupPeriodDays: 3650`。
6. **PS 5.1 编码**。`.ps1` 若含非 ASCII 且无 BOM 会被按 ANSI 误解析报错——本仓库脚本已全 ASCII 规避。

## 自动同步（两种，建议都开）

- **A. 定时任务（最可靠）**：Windows 任务计划程序每 10 分钟跑一次 `claude-code-sync.ps1`；
  WSL2 用 cron。不依赖会话是否结束。
- **B. SessionEnd 钩子（兜底）**：会话结束时后台同步一次。长期 resume 的会话不会频繁触发，
  所以配合 A 使用。

具体命令见 [AGENT-RUNBOOK.md](AGENT-RUNBOOK.md)。

## 命令速查

| 操作 | Windows | WSL2 |
|---|---|---|
| 推送到 iCloud | `.\claude-code-sync.ps1` | `./claude-code-sync.sh` |
| 从 iCloud 还原 | `.\claude-code-sync.ps1 -Mode pull` | `./claude-code-sync.sh pull` |

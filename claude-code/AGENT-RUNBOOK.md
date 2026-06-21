# AGENT RUNBOOK — Claude Code 同步：新机自助安装

> 本文件是给 **Claude Code（你）** 看的执行手册。在一台新机器上，用户会让你"按这个
> runbook 把 Claude Code 聊天记录同步装好"。请逐步执行并向用户汇报结果。脚本路径相对本
> 文件：`scripts/`、`templates/`。

## 前提与约定

- 本 runbook 默认 **Windows + iCloud Drive**。若是 WSL2/Linux/Mac，用 `scripts/claude-code-sync.sh`，
  逻辑相同，自动化用 cron 而非任务计划程序。
- 同步**数据**在 iCloud（`%USERPROFILE%\iCloudDrive\ClaudeCodeSync`）；本仓库只提供工具。
- 全程不要把聊天记录提交到 git。

---

## 步骤 0 — 确认环境（先查再做）

依次确认，结果汇报给用户：

```powershell
Test-Path "$env:USERPROFILE\.claude"                              # Claude Code 是否用过
Test-Path "$env:USERPROFILE\iCloudDrive\ClaudeCodeSync\projects"  # iCloud 是否已同步下来
$env:USERNAME                                                     # 用于路径一致性判断
```

- 若 iCloud 目录不存在：提示用户先装商店版 iCloud、登录**同一 Apple ID**、等
  `ClaudeCodeSync` 下载完，并右键该文件夹设「始终保留在本设备」。**这步用户必须手动做，你无法可靠代劳。**
- 验证不是占位空壳（应为 0）：

```powershell
$cd = "$env:USERPROFILE\iCloudDrive\ClaudeCodeSync"
(Get-ChildItem "$cd\projects" -Recurse -File | Where-Object {$_.Length -eq 0}).Count
```

## 步骤 1 — 部署脚本

把脚本复制到 `~\.claude\`（从本仓库 `claude-code/scripts/`）：

```powershell
$dst = "$env:USERPROFILE\.claude"
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item ".\claude-code\scripts\claude-code-sync.ps1" "$dst\claude-code-sync.ps1" -Force
Copy-Item ".\claude-code\scripts\claude-code-sync.sh"  "$dst\claude-code-sync.sh"  -Force
```

脚本是纯 ASCII，PS 5.1 可直接解析。做个语法自检：

```powershell
$errs=$null
[System.Management.Automation.PSParser]::Tokenize((Get-Content "$dst\claude-code-sync.ps1" -Raw),[ref]$errs)|Out-Null
if($errs.Count -eq 0){"SYNTAX OK"}else{$errs|%{$_.Message}}
```

## 步骤 2 — 备份新机已有配置（若新机用过 Claude Code）

`pull` 会整文件覆盖 `settings.json`/`history.jsonl`（脚本会自动留 `.bak`，但显式再备份一次更稳）：

```powershell
$c="$env:USERPROFILE\.claude"
foreach($f in 'settings.json','history.jsonl'){ if(Test-Path "$c\$f"){Copy-Item "$c\$f" "$c\$f.manualbak" -Force} }
```

## 步骤 3 — 从 iCloud 还原（合并会话）

```powershell
& powershell.exe -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\claude-code-sync.ps1" -Mode pull
```

`projects/` 是并集合并（不删新机已有会话）；`settings.json` 此刻已被云端版覆盖 → 下一步修。

## 步骤 4 — 合并 settings.json（关键：注入钩子 + 关清理，保留用户个性化）

用 `templates/settings.json` 为基础，把命令里的 `__CLAUDE_PS1_PATH__` 换成本机真实路径，
并尽量保留新机原有字段（如 `theme`，从 `settings.json.manualbak` 取）。最终至少应包含：

```json
{
  "cleanupPeriodDays": 3650,
  "hooks": {
    "SessionEnd": [
      { "matcher": "", "hooks": [
        { "type": "command",
          "command": "powershell -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File \"C:\\Users\\<本机用户名>\\.claude\\claude-code-sync.ps1\"",
          "async": true, "timeout": 120 }
      ]}
    ]
  }
}
```

把 `<本机用户名>` 换成步骤 0 查到的 `$env:USERNAME`。用 Read 工具读现有 `settings.json` 再用
Edit/Write 安全合并，不要整体盲覆盖用户已有的其它字段。

## 步骤 5 — 注册定时任务（每 10 分钟，最可靠）

注意：不要用 `[TimeSpan]::MaxValue`（会生成非法 Duration）；用 CIM 重复模式：

```powershell
$ps1="$env:USERPROFILE\.claude\claude-code-sync.ps1"
$action=New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$ps1`""
$trigger=New-ScheduledTaskTrigger -Once -At (Get-Date)
$rep=New-CimInstance -ClientOnly -Namespace Root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskRepetitionPattern -Property @{Interval="PT10M";StopAtDurationEnd=$false}
$trigger.Repetition=$rep
$set=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "ClaudeCodeSync" -Action $action -Trigger $trigger -Settings $set -Force
```

## 步骤 6 — 验证

```powershell
Start-ScheduledTask -TaskName ClaudeCodeSync
Start-Sleep 6
Get-ScheduledTaskInfo -TaskName ClaudeCodeSync | Select-Object LastTaskResult,LastRunTime,NextRunTime
# LastTaskResult 应为 0
```

然后告诉用户：打开 Claude Code，进对应项目执行 `/resume`，应能看到历史会话。

## 步骤 7 — 路径一致性检查（/resume 看不到历史的唯一常见原因）

会话目录按项目绝对路径编码。若新机 `$env:USERNAME` 与原机（`brigh`）不同，或项目放在别处，
`/resume` 会认不到。此时列出编码目录并按新机真实路径重命名：

```powershell
Get-ChildItem "$env:USERPROFILE\.claude\projects" -Directory | Select-Object Name
# 例：原机 brigh，新机 alice：
# Rename-Item ".\C--Users-brigh-Projects-x" "C--Users-alice-Projects-x"
```

向用户说明：若用户名/项目路径与原机不一致，要么改成一致，要么按上面手动重命名。

---

## 汇报清单（执行完逐项回报）

- [ ] iCloud 目录存在且无 0 字节占位
- [ ] 脚本已部署且语法 OK
- [ ] 已备份新机原有配置
- [ ] `pull` 完成，projects 合并
- [ ] `settings.json` 已合并（钩子 + cleanupPeriodDays，保留个性化字段）
- [ ] 定时任务 `LastTaskResult=0`
- [ ] 提醒用户手动设 iCloud「始终保留在本设备」与 `/resume` 验证

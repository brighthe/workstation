# 双仓库 iCloud 定时同步

本目录管理 `dut-postdoc` 和 `dut-institute-work` 到 iCloud Obsidian 容器的每日镜像同步。执行使用 Windows Task Scheduler，不依赖 Codex、Claude Code 或其他 AI 工具。

## 安全边界

- 同步使用 `robocopy /MIR`：源目录删除的文件也会从 iCloud 目标删除。
- 同步包含未提交修改，但排除 Git 元数据、AI 工具配置、AI 入口文件、临时文件和 PowerShell 脚本。
- 任何时刻只应在一台电脑启用任务。迁移前先从旧电脑卸载，再在新电脑安装。

## 安装与管理

默认工作区是 `C:\workspace`，每天本地时间 21:00 运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\icloud-sync\manage-icloud-sync-task.ps1 `
  -Action Install
```

使用其他工作区或时间：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File .\scripts\icloud-sync\manage-icloud-sync-task.ps1 `
  -Action Install `
  -WorkspaceRoot D:\workspace `
  -DailyAt 22:30
```

查询状态或卸载：

```powershell
.\scripts\icloud-sync\manage-icloud-sync-task.ps1 -Action Status
.\scripts\icloud-sync\manage-icloud-sync-task.ps1 -Action Uninstall
```

任务使用当前 Windows 用户的 interactive token，不保存密码。电脑关机或用户未登录而错过计划时间时，会在任务下次可用时补跑；任务不会唤醒电脑。
安装和卸载需要写入 Windows Task Scheduler，管理脚本会自动显示一次 UAC 提示；任务本身仍以当前用户的 limited privilege 运行。

## 验证与手动运行

只检查环境和两个仓库的同步脚本：

```powershell
.\scripts\icloud-sync\sync-repositories-to-icloud.ps1 -ValidateOnly
```

预览 `/MIR` 将执行的复制和删除：

```powershell
.\scripts\icloud-sync\sync-repositories-to-icloud.ps1 -Preview
```

正式运行一次：

```powershell
.\scripts\icloud-sync\sync-repositories-to-icloud.ps1
```

日志保存在 `%LOCALAPPDATA%\Workstation\logs\icloud-sync`，自动保留最近 30 天。

## 新电脑迁移

1. 在旧电脑运行 `manage-icloud-sync-task.ps1 -Action Uninstall`。
2. 在新电脑登录 iCloud for Windows，并准备两个仓库。
3. 克隆或更新 `workstation`，运行 `-ValidateOnly` 和 `-Preview`。
4. 运行 `manage-icloud-sync-task.ps1 -Action Install`。
5. 手动正式同步一次，再用 `-Action Status` 检查任务结果和下次运行时间。

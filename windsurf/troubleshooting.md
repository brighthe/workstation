# Windsurf 故障排查：WSL、conda 与 Pyright

## 先判定问题所在

| 现象 | 首要检查 | 常见原因 |
| --- | --- | --- |
| 解释器选择器为空或提示无效 | 是否在 `WSL: <distro>` 窗口；Python Environments 输出 | Python 扩展没有安装在 WSL 端，或 PET 缺失 |
| 终端可 `import`，编辑器却无法解析或跳转 | 状态栏解释器、`pyrightconfig.json` | editable install 的源码目录未加入 Pyright 索引 |
| 导入没有报错但类名类型为 `Any` | 悬浮类型与转到定义 | Devin Pyright 对动态重导出比 Pylance 保守 |

## PET 缺失：`ENOENT`

Python Environments 日志若含有如下错误，说明扩展的 Python Environment Tools 不完整：

```text
spawn .../python-env-tools/bin/pet ENOENT
```

此时 conda 环境发现会失败，通常显示 `none`，即使解释器路径本身可运行。

### 标准恢复顺序

1. 确认 Python 扩展安装在 **WSL 端**；重新加载窗口后再次检查。
2. 若仍失败，先将 `~/.devin-server` 改名为带日期的备份目录，再完全退出并重开 Windsurf，使服务端重新部署。不要直接删除备份。
3. 重新安装 `ms-python.python`；其依赖 `ms-python.vscode-python-envs` 和 `ms-python.debugpy` 应同时存在。

### 同版本 PET 兜底修复

仅在扩展重新安装后仍缺少 PET 时使用，并且**源与目标必须为同一 `ms-python.python` 版本**：

```text
源：~/.vscode-server/extensions/ms-python.python-<version>-linux-x64/python-env-tools/
目标：~/.devin-server/extensions/ms-python.python-<version>-universal/python-env-tools/
```

复制整个 `python-env-tools/` 目录后，确认目标 `bin/pet` 具有可执行权限，并执行：

```bash
<target>/bin/pet --version
<target>/bin/pet find --json <workspace>
```

第二条命令应列出目标 conda 环境。随后重载 Windsurf 窗口。

这是针对 Windsurf/Open VSX 扩展包缺件的版本敏感修复；扩展更新后应优先重新检查，不要跨版本复用二进制。

## editable install：运行可导入，编辑器不可跳转

`pip show <package>` 若显示 `Editable project location`，Python 运行时可能可正常导入，但静态语言服务未必能追踪其映射。此时不要改业务代码中的公共导入路径，应以项目根目录的 `pyrightconfig.json` 的 `extraPaths` 明确加入依赖源码根目录，模板见 [README.md](README.md#标准配置)。

重载窗口后再用 `F12` 验证。若仍失败，查看 `Devin Pyright` 输出，确认其记录了目标 `pythonPath`、加载了项目根目录的 `pyrightconfig.json`，且没有覆盖 `extraPaths` 的其他项目配置。

## 安全边界

- 不在本文档、配置模板或日志中记录 Token、密码、私钥和 VPN 凭据；
- 服务端目录包含本地状态，重置前先备份；
- 不将来自其他编辑器的扩展二进制跨版本复制。

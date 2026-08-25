# VS Code

本模块维护 VS Code 在 Windows/WSL 科研工作区中的通用配置与排障流程。它只记录编辑器、语言服务和解释器发现机制，不保存项目数据、用户密钥或扩展缓存。

## Python 模块无法识别

### 典型现象

- 编辑器顶部的 `import` 无法跳转定义，模块、类或函数没有语义识别；
- Pylance 报 `Import could not be resolved`，但集成终端中同一条 Python 命令可以正常运行；
- `soptx` 这类 `src/` 布局项目、本地 vendor fork（如 FEALPy）或 Conda 环境中的包只在运行时可见。

### 根因

终端的 `conda activate`、脚本中的 `sys.path.insert(...)` 都是**运行时**行为；Pylance 必须在编辑时就知道解释器与模块搜索路径。尤其要检查工作区设置中没有关闭语言服务：

```json
"python.languageServer": "None"
```

这个配置会禁用 Pylance，导致导入解析、定义跳转、类型检查和语义高亮都不可用，即使终端解释器本身正确。

### 推荐工作区配置

在项目的 `.vscode/settings.json` 中配置实际解释器与静态分析路径：

```json
{
  "python.languageServer": "Pylance",
  "python.defaultInterpreterPath": "/home/<user>/miniconda3/envs/<env>/bin/python",
  "python.analysis.extraPaths": [
    "/home/<user>/workspace/<project>/src",
    "/home/<user>/workspace/<vendor-fork>"
  ]
}
```

`extraPaths` 应列出源码根目录，而不是包目录本身。例如 `src/` 布局项目应填写 `.../<project>/src`，使语言服务能够解析 `import <package>`。

若仓库使用 `pyrightconfig.json`，可保留与上述路径一致的 `executionEnvironments[].extraPaths`；但 VS Code 中最终选中的解释器仍须通过 `python.defaultInterpreterPath` 或状态栏的 **Python: Select Interpreter** 指定。

### 验证与恢复

1. 在 VS Code 状态栏确认 Python 解释器是目标 Conda/venv；
2. 执行命令面板的 **Developer: Reload Window**，触发 Pylance 重启并重新索引；
3. 查看 **Output → Pylance**，确认没有 `language server disabled` 或 `Import could not be resolved`；
4. 在集成终端运行以下命令，确认运行时环境也一致：

```bash
python -c "import sys, your_package; print(sys.executable); print(your_package.__file__)"
```

如果终端可以导入、Pylance 仍不能，优先检查 `python.languageServer`、解释器选择与 `python.analysis.extraPaths`，不要用项目代码里的 `sys.path` 修改来替代编辑器配置。

## WSL 工作区边界

当项目运行于 WSL 时，应使用 VS Code Remote - WSL 打开 WSL 路径，并把解释器路径填写为 Linux 路径。不要在 Windows 原生窗口中混用 Linux Conda 路径；这会使终端、调试器与 Pylance 分别看到不同的 Python 环境。

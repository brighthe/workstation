# Windsurf：WSL Python 开发配置

本模块记录 Windsurf 编辑器在 Windows + WSL2 工作流中的安装、配置、验证与恢复。它是工具配置，不承载项目代码、研究数据、日志、凭据或算例结果。

WSL 本身的安装、网络与 DNS 问题见 [`wsl/`](../wsl/README.md)；本模块只处理 Windsurf 这一软件产品。

## 标准配置

1. 在 Windsurf 左下角确认当前窗口是目标 WSL 发行版，而不是 Windows 本地窗口。
2. 在扩展面板的 **WSL** 区域安装并启用：`ms-python.python`、`ms-python.vscode-python-envs` 与 `ms-python.debugpy`。
3. 在项目的 `.vscode/settings.json` 设置 WSL 内实际解释器及必要源码路径：

   ```json
   {
     "python.defaultInterpreterPath": "/home/<user>/miniconda3/envs/<env>/bin/python",
     "python.analysis.extraPaths": ["/home/<user>/workspace/<dependency-source>"]
   }
   ```

4. 若依赖是 editable install，且右键“转到定义”仍失败，则在项目根目录本地增加 `pyrightconfig.json`：

   ```json
   {
     "executionEnvironments": [
       {
         "root": ".",
         "extraPaths": ["/home/<user>/workspace/<dependency-source>"]
       }
     ]
   }
   ```

   是否将该文件提交由项目 `.gitignore` 和团队约定决定；若包含机器专属绝对路径，通常仅本地保留。
5. 每次变更扩展、解释器或 Pyright 配置后，执行 `Developer: Reload Window`。

## 验收

- 状态栏显示目标 conda 环境及 Python 版本；
- 在 WSL 终端中，目标解释器可 `import` 依赖包；
- 导入行没有“无法解析导入”诊断；
- 右键包名或使用 `F12` 可进入源码定义。

## 本机 SOPT-X / FEALPy 示例

本机解释器为 `/home/brighthe/miniconda3/envs/ihpcm/bin/python`，FEALPy 源码为 `/home/brighthe/workspace/fealpy`。SOPT-X 的本地配置文件不应被复制到其他计算机；迁移时按上述模板替换为新机器的路径。

## 进一步信息

- PET 缺失、conda 环境未发现、Python 扩展包不完整等问题见 [troubleshooting.md](troubleshooting.md)。
- Windsurf 的官方能力与版本更新跟进规则见 [capabilities.md](capabilities.md)。

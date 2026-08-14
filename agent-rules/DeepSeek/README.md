# DeepSeek Harness 全局配置管理

> - **整理日期**：2026-08-14
> - **版本**：`@deepseek-ai/dsh` v0.1.0-rc.6（developer preview）
> - **适用环境**：Windows 11、Windows PowerShell、Node.js v24.19.0

本文档用于管理 DeepSeek Harness（`dsh`）的本机配置面。安装与日常使用见 [`agent-tutorials/DeepSeek/deepseek-harness-guide.md`](../../agent-tutorials/DeepSeek/deepseek-harness-guide.md)；能力导读见 [`agent-tutorials/DeepSeek/capabilities.md`](../../agent-tutorials/DeepSeek/capabilities.md)。

> [!IMPORTANT]
> DSH 为 developer preview，配置结构会随版本变动。升级后先用 `dsh --dump-config` 核对，再同步本目录。

---

## 与其他 agent 配置的差异

Codex、Claude Code、Antigravity 都有一个**全局指令文件**（`AGENTS.md` / `CLAUDE.md` / `GEMINI.md`），由 [`scripts/setup-global-instruction-links.ps1`](../../scripts/setup-global-instruction-links.ps1) 统一建立符号链接。

**DSH 没有对应物**。它的配置面是分层的 patch 体系，对应的是 Codex `config.toml` 那条线——手工链接 + 本文档记录，不进上述脚本。因此**本目录不纳入 `setup-global-instruction-links.ps1`**。

> DSH 存在 `@deepseek-ai/dsh-agent-instructions` 与 `@deepseek-ai/dsh-system-prompt` 两个插件，可能提供类似全局指令的机制，**尚未验证**。若确认存在稳定的指令文件入口，再考虑纳入统一脚本。

---

## 纳管对象：官方仅有的两个 profile

DSH 随包分发的 profile **只有两个**，均在首次使用时从内置模板自动初始化。本目录纳管的正是它们各自的用户 patch 层。

| Profile | 形态 | 启动 | 本目录对应文件 |
| :--- | :--- | :--- | :--- |
| `web` | 浏览器 UI，默认 `http://127.0.0.1:3080`，前台常驻 | `dsh web` | `profile-web.cordis.patch.yml` |
| `headless` | 一次性 CLI：给一个任务、打印最终回复、退出，无 server | `dsh --profile headless "<任务>"` | `profile-headless.cordis.patch.yml` |

两者于 2026-08-14 均已实测通过（`web` 验证到 HTTP 200 + 前端渲染 + console 无错误；`headless` 两次任务均正常返回）。

> [!IMPORTANT]
> **没有第三个入口，官方无 TUI。** 详细证据与常见误解见 [`agent-tutorials/DeepSeek/deepseek-harness-guide.md`](../../agent-tutorials/DeepSeek/deepseek-harness-guide.md) §4.3。若将来官方新增 profile，需同步扩充本目录的纳管清单与下方链接表。

启动参数、界面要点、权限档位与沙箱行为等**使用层面**的内容不在本文档，见上述指南。本文档只管配置文件本身。

---

## 配置分层

DSH 的配置从下往上合成，后一层覆盖前一层：

```text
各 bundle 层（package.json 的 dsh.profile.bundles 按序）
  → $DSH_HOME/cordis.patch.yml      （home 级全局覆盖，本机尚未创建）
  → profiles/<name>/cordis.patch.yml（profile 级用户层）
  → --patch <path>                  （命令行临时覆盖层）
```

核对当前生效配置：

```powershell
dsh --profile web --dump-config
```

对比不含用户层的基线：

```powershell
dsh --profile web --dump-default-config
```

---

## 目录文件与链接一览

`$DSH_HOME` = `C:\Users\Administrator\.dsh`

| 文件 | 作用 | 真实路径 | 链接 |
| :--- | :--- | :--- | :--- |
| `settings.yaml` | 全局设置（当前仅 onboarding 状态） | `C:\Users\Administrator\.dsh\settings.yaml` | 硬链接（2026-08-14 建立并验证） |
| `profile-web.cordis.patch.yml` | `web` profile 用户 patch 层 | `C:\Users\Administrator\.dsh\profiles\web\cordis.patch.yml` | 硬链接（2026-08-14 建立并验证） |
| `profile-headless.cordis.patch.yml` | `headless` profile 用户 patch 层 | `C:\Users\Administrator\.dsh\profiles\headless\cordis.patch.yml` | 硬链接（2026-08-14 建立并验证） |
| `README.md` | 本说明文档 | 本目录 | 普通文件 |

### 不纳管的文件

| 路径 | 原因 |
| :--- | :--- |
| `profiles/<name>/cordis.yml` | profile 根，文件头明确注明**不要修改**，用户改动一律进 `cordis.patch.yml` |
| `profiles/<name>/package.json` | 由 dsh 生成与维护；改 bundle 时手动记录变更即可，不做链接 |
| `profiles/*/node_modules/`、`pnpm-workspace.yaml` | 依赖产物，随安装重建 |
| `sessions/` | **含完整对话、工具调用与工作区路径，不入库** |
| `storages/` | 运行时缓存（`workspace.json`、`session_projcache.json`） |
| `.anonymous-user-id` | 本机标识，无跨设备意义 |

---

## 凭据边界

- DeepSeek API Key **只通过 Web UI 界面录入**；不写入配置文件、不设环境变量、不进本仓库。
- 实测（2026-08-14，v0.1.0-rc.6）`~/.dsh` 下**无凭据文件**：`settings.yaml` 仅一行 onboarding 版本号，各 `cordis.patch.yml` 为空数组 `[]`。因此本目录纳管的三个文件不含密钥。
- **每次同步前重新确认**：若将来 DSH 把凭据写入 `settings.yaml` 或 patch 层，必须停止纳管该文件，不得提交。
- DSH 不路由到非 DeepSeek 的模型服务；Codex 也不再转发到 DeepSeek API（见 [`agent-rules/Codex/README.md`](../Codex/README.md) 的认证与旧配置清理一节）。

---

## 硬链接

三个文件的绑定已于 2026-08-14 建立并验证（`fsutil file queryfileid` 两侧一致）。重装 dsh 或升级后可能被替换而断链，用下面的方法重建。

先确认目标文件当前状态：

```powershell
Get-Item C:\Users\Administrator\.dsh\settings.yaml | Select-Object FullName, LinkType, Target
```

确认为普通文件且内容已同步到本目录后，再建立硬链接（会覆盖目标，务必先核对内容一致）：

```powershell
New-Item -ItemType HardLink -Path C:\Users\Administrator\.dsh\settings.yaml -Value C:\workspace\workstation\agent-rules\DeepSeek\settings.yaml -Force
```

`web` 与 `headless` 的 patch 层同理，分别指向 `profile-web.cordis.patch.yml` 与 `profile-headless.cordis.patch.yml`。

> [!WARNING]
> 硬链接要求源与目标在**同一卷**。本机两侧均在 `C:`，满足条件。
>
> 参照 [`agent-rules/Codex/README.md`](../Codex/README.md) 的维护约定：**不假设同名文件为硬链接**，编辑或同步前用 `Get-Item ... | Select-Object FullName, LinkType, Target` 检查实际关系。
>
> 硬链接的判定不能只看 `LinkType`——Windows 上硬链接的 `LinkType` 常显示为空。可靠方法是比对文件 ID：
>
> ```powershell
> fsutil file queryfileid C:\Users\Administrator\.dsh\settings.yaml
> fsutil file queryfileid C:\workspace\workstation\agent-rules\DeepSeek\settings.yaml
> ```
>
> 两者相同即为同一个文件。

> [!CAUTION]
> **这三个文件是 LF 行尾，编辑时不要用 `Set-Content`**——它会静默转成 CRLF，文件体积变化（217 → 221 字节）且与 dsh 原始模板不再一致。用支持保留行尾的编辑器，或直接写字节：
>
> ```powershell
> [IO.File]::WriteAllText($path, $text.Replace("`r`n","`n"))
> ```
>
> 就地改写不会断开硬链接（已验证）；但**替换式**写入（先删后建）会断链，之后需按上文重建。

---

## 升级后的核对清单

DSH 版本跳动（尤其 rc 递进）后依次确认：

1. `dsh -V` 与本文档记录的版本是否一致，不一致则更新本文与两份教程的版本标注。
2. `profiles/<name>/` 目录结构是否变化（v0.1.0-rc.6 为 `package.json` + `cordis.yml` + `cordis.patch.yml` + `pnpm-workspace.yaml`）。
3. 三个纳管文件的硬链接是否仍然有效（重装可能替换真实文件从而断链）。
4. `settings.yaml` 是否新增了含凭据的字段——**若有，立即停止纳管**。
5. `dsh --dump-config` 与 `--dump-default-config` 对比，确认用户层仍按预期生效。

---

## 官方参考链接

- [DeepSeek Harness 产品页](https://deepseek.com/harness/en/)
- [GitHub 仓库](https://github.com/deepseek-ai/deepseek-harness)
- [CLI 文档（profile 与配置分层）](https://github.com/deepseek-ai/deepseek-harness/tree/master/apps/cli)
- [架构文档](https://github.com/deepseek-ai/deepseek-harness/blob/master/docs/architecture.md)

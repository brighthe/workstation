# Claude Code 全局记忆与指令管理说明

这个文档是给我自己看的，用来帮助我理解和管理 Claude Code 的“全局指令（CLAUDE.md）”和“自动记忆（Auto Memory）”。

核心分工：

- **CLAUDE.md（全局指令）**：**我自己写**，放 Claude 应长期遵守的规则和工作约束。每个会话开始时完整加载。
- **自动记忆（Auto Memory）**：**Claude 自己写**的学习笔记（构建命令、调试见解、发现的偏好），我也可以随时编辑或删除。

一句话：**CLAUDE.md 管我定的规则，自动记忆管 Claude 学到的经验。**

## 实际文件链接

路径分层写：仓库内用相对路径（跨设备通用），通用位置用 `~/`，本机绝对路径用机器名标注（每台设备的克隆路径/用户名可能不同）。

- [workstation 中同步的 CLAUDE.md](CLAUDE.md)
  仓库内路径：`claude/CLAUDE.md`（真正维护的文件，随本仓库跨设备同步）
  LAPTOP-A51RSRUJ：`C:\workspace\workstation\claude\CLAUDE.md`
  PC-20260706DAHN：`C:\workspace\workstation\claude\CLAUDE.md`

- Claude 用户级全局指令
  通用位置：`~/.claude/CLAUDE.md`
  Windows 通用示例：`C:\Users\<用户名>\.claude\CLAUDE.md`
  LAPTOP-A51RSRUJ：`C:\Users\Lenovo\.claude\CLAUDE.md`
  PC-20260706DAHN：`C:\Users\Administrator\.claude\CLAUDE.md`
  当前状态：符号链接，指向本设备克隆位置下的 `claude/CLAUDE.md`。两台设备均已确认。

- Claude 自动记忆目录
  通用位置：`~/.claude/projects/<project>/memory/`
  Windows 通用示例：`C:\Users\<用户名>\.claude\projects\<project>\memory\`
  LAPTOP-A51RSRUJ：`C:\Users\Lenovo\.claude\projects\<project>\memory\`
  PC-20260706DAHN：`C:\Users\Administrator\.claude\projects\C--\memory\`（`C--` 对应工作目录 `C:\`）
  说明：`<project>` 由 git 仓库路径决定；同一仓库的所有 worktree 共享。**机器本地，不跨设备。**

## 官方文档链接

- [Claude Code 官方文档（中文总览）](https://code.claude.com/docs/zh-CN/overview)
- [完整文档索引 llms.txt](https://code.claude.com/docs/llms.txt)（抓这个可发现所有页面/slug）
- [记忆与 CLAUDE.md 说明](https://code.claude.com/docs/zh-CN/memory)
- [Hooks 指南](https://code.claude.com/docs/zh-CN/hooks-guide) ｜ [Settings](https://code.claude.com/docs/zh-CN/settings) ｜ [CLI 参考](https://code.claude.com/docs/zh-CN/cli-reference)

> 本 README 只管"指令与记忆"。Skills、子代理、MCP 等**能力类**入口和官方最新动态的跟进，统一放在 [capabilities.md](capabilities.md)。

> 上面是中文页，便于你直接阅读；**Claude 查询时以英文 `/en/` 原版为准**（更新最快、无翻译偏差）。子页面通用规律：`https://code.claude.com/docs/en/<slug>`，把 `/en/` 换成 `/zh-CN/` 即中文版。

## CLAUDE.md 的存放位置（按加载顺序，范围从宽到窄）

| 范围 | 位置 | 用途 |
| :--- | :--- | :--- |
| **用户指令** | `~/.claude/CLAUDE.md` | **所有项目的个人偏好（当前用的就是这一层）** |
| 项目指令 | `./CLAUDE.md` 或 `./.claude/CLAUDE.md` | 随仓库共享给团队 |
| 本地指令 | `./CLAUDE.local.md` | 个人、项目内、加入 .gitignore |

要点：
- 单个 CLAUDE.md 目标 **200 行以内**，越短遵守度越高。
- 块级 HTML 注释 `<!-- ... -->` 在注入上下文前会被剥离，可用来留给人看的维护笔记而不耗 token。
- Windows 上建符号链接需管理员权限或开发者模式；否则可用 `@AGENTS.md` / `@path` 导入语法。
- `~/.claude/rules/*.md` 也是**用户级（全局）**规则，适用于每个项目；规则变多时可拆到这里，或用 `paths` frontmatter 把某条规则限定到特定文件类型/目录。

## CLAUDE.md 内容

点开即是英文本体：[`claude/CLAUDE.md`](CLAUDE.md)（已由符号链接映射到 `~/.claude/CLAUDE.md`）。**正文统一用英文写**（全局指令一贯约定；回答仍用中文）。下面是对应的完整中文翻译，方便阅读——**正文以英文文件为准，改动请只改 `claude/CLAUDE.md`，本译文仅供参考**：

```md
# Claude Code 全局指令

## 语言
- 默认用简体中文回答。专有名词、方法名、变量、命令、配置键、产品名保留英文。

## 交互模式 —— 非简单任务前先建议
- 在会话或非简单任务开始时，用一行先建议合适的模式，由我决定；你可以主动请求进入 Plan mode（仍需我批准），但绝不要自行切换其他任何模式：
  - 只读问答 / 解释 / 小澄清 → default（Manual），直接答。
  - 多步编辑 / 重构 / 改配置 → 建议 Plan mode（Shift+Tab，或给提示加前缀 /plan）。
  - 长时间、有明确完成条件、要一口气跑完的活 → 建议 /goal <条件>。
- 琐碎的追问就跳过建议；保持一行。

## 不要替我执行 —— 先提方案，再询问
- **任何操作性工作的默认做法：把方案和确切命令给我，然后询问是否要替我执行。** 等我回答。不要先执行再汇报。
- 涵盖一切会改变机器状态或消耗真实算力的事：创建/修改 conda 或 venv 环境、安装包、`git worktree`/`clone`/`checkout`、构建、训练、测试、基准测试、MPI 作业、验证驱动、服务器、长时间运行的脚本。
- **例外 —— 只读检查免询问**：`git status/log/show/diff`、列文件、读文件、查已安装版本、静态搜索。这些无需许可，直接做。
- 方案获批**不等于**授权执行。批准方案只覆盖思路，不覆盖执行。到执行环节要再问一次。
- 如果我明确说要跑（"跑一下"、"run it"、"execute"），就跑 —— 该授权只对那次动作生效，不延续到后续。
- 当我自己运行命令并粘贴输出时，据该输出诊断并判定结果。
- 当你确实要执行时，你的 Bash/PowerShell 工具能直接捕获 stdout/stderr 和退出码，所以下文 Desktop shell mode 的限制不适用。

## 批判性评估
- 把我提出的方案视为需要评估的提案，而不是自动接受的内容：采用前先检查其正确性、可行性、关键假设、风险、取舍和替代方案。如果方案错误、风险不合理，或明显劣于其他选择，给出具体理由指出问题，并在继续前推荐更好的方案。
- 如果我要求严格按我的方案执行，只要不违反更高优先级的指令或安全边界就照办；但实施前仍要简要提示重大风险或不可逆后果。
- 批评应基于证据并与影响程度相称。不要为了反对而反对，也不要对低风险偏好过度争论。

## 关于用户
- Liang He（何亮）。GitHub `brighthe`，邮箱 brighthe98@gmail.com。
- 大连理工大学博士后；研究方向：拓扑优化、有限元方法（FEM）、PIML（Problem-Independent Machine Learning，问题无关机器学习）。

## 工作区仓库治理（`C:\workspace`）

- 仓库发现、本地检出路由、所有权判断和预期 Git 远程：读取 manifest `C:\workspace\workstation\workspace\repositories.json`，不要在这里维护重复清单。
- 跨仓库内容归属、事实源选择和引用规则：读取 `C:\workspace\workstation\workspace\responsibilities.md`。不要在这里复制其中的职责表或路由表。
- 只有明确指定为受管科研工作区组成部分的仓库才应写入 manifest；绝不自动添加临时、实验或无关的检出。添加或移除时，应在同一任务中更新 manifest 及其公开的 workspace 文档。
- 进入某个仓库后，以该仓库自己的 `CLAUDE.md`、`AGENTS.md`、`README.md` 为准。commit 或 push 前验证所配置的 `origin`。
- 将 manifest 中类型为 `company` 的条目（包括 `suanhaitech` 所有的仓库）视为算海所有的工作。不要把算海代码、数据、凭据或内部文档复制到个人仓库中。

## 指令文件边界
- 你（Claude Code）只维护 Claude 相关的指令文件：各处 `CLAUDE.md`、`~/.claude/`、项目内 `.claude/` 目录。
- 不要编辑其他 AI 助手的指令文件（如 Codex 的 `AGENTS.md`、`~/.codex/`），除非我在该会话中明确要求；每个工具的指令由该工具自己管理。

## Claude Code 问题 → 先查官方文档
当我询问任何关于 Claude Code 的问题（功能、配置、hooks、MCP、skills、子代理、CLI、权限、部署、成本等）时，抓取对应的官方页并据此回答，而不是凭训练记忆。

- 读英文 `/en/` 页面：权威原版、更新最快；`/zh-CN/` 可能滞后或有翻译偏差。读英文，回答用中文。
- 页面遵循规律 `https://code.claude.com/docs/en/<slug>`。拿不准是哪一页时，抓 https://code.claude.com/docs/llms.txt 找 slug。

## Windows git 与 shell
- git 和 SSH 操作使用 PowerShell 配合 Windows 原生 Git/OpenSSH。这里的 Bash 工具就是 Git Bash——除非我明确要求，不要用它以及 MSYS、Cygwin、WSL 的 git/ssh 操作我的 Windows 仓库。
- 如果 GitHub SSH 在 Windows 上表现异常，检查 `HOME` 是否指向 Windows 用户目录，而不是 `/home/<user>` 这类 POSIX 路径。

## 在本地运行程序（Windows Desktop）
我经常自己运行程序以掌握流程。下面是经过验证的路径，无需复制粘贴输出。

- **我在 Desktop 终端 pane 里跑**（Views 菜单，或 ``Ctrl+` ``）：会话工作目录、持久 shell（`conda activate` 会保持）、独立 pane，长任务不占用聊天框。
- **输出 tee 到仓库的 `logs/`**；你用 Read 工具读回，跑到一半也可以，且不会被截断：

      conda activate <env>
      python .\script.py 2>&1 | Tee-Object -FilePath .\logs\run.log

- **出图用 `savefig` 存到 `figs/`**，绝不用 `plt.show()` —— 你能 Read 图片文件，但看不见弹窗。
- **绝不为此推荐 `!` shell mode 或 `Ctrl+B`。** 2026-07-29 验证：在 Desktop 中，`!` 只能捕获 PowerShell 内置命令，捕获不到外部程序（`git`、`python`、`conda`），且 `Ctrl+B` 未绑定。官方文档里的 `!` 行为适用于终端 CLI，不适用于 Desktop。

### Windows Python 环境
机器相关 —— 路径和环境名因设备而异。依赖前先验证；若当前机器不在下方列表中，解析出来并让我记录。

- 绝不直接调用裸的 `python` 或 `conda`。在我的 Windows 机器上，`conda` 通常**不在 PATH 上**，而 PATH 上的 `python` 是 Microsoft Store 占位 stub（无输出、exit 49），不是真解释器。
- 通用位置：`<用户目录>\miniconda3\Scripts\conda.exe`（或 `anaconda3`）。用 `Test-Path` 检查，再用 `conda env list` 列出环境。
- **PC-20260706DAHN**：`C:\Users\Administrator\miniconda3\Scripts\conda.exe`；环境 `base`（无 numpy）、`fealpy-ml`、`soptx-gpu`、`xihe-fealpy`。
- 当你自己运行 Python 时：

      & "<conda 路径>" run -n <env> --no-capture-output python .\script.py

  `--no-capture-output` 让输出实时流出，以便 tee 落盘。

## git 暂存纪律
- commit 前先检查工作区，只暂存与当前任务相关的文件。除非我明确要求，不要使用 `git add -A` 这类宽泛暂存。
```

> 只在 `claude/CLAUDE.md` 一处维护英文正文；改了正文记得同步这段中文译文，避免两边漂移。已配置确定性提醒：本仓库 [`.claude/settings.json`](../.claude/settings.json) 的 PostToolUse hook 会在 `claude/CLAUDE.md` 被修改后，自动提醒同步本节译文。

## 确定性 hook：git origin 核对

CLAUDE.md 中"commit/push 前核对 `origin`"是建议性指令；官方文档明确 CLAUDE.md 只是 context，需要确定性保障时应使用 hook。为此配置了一个 PreToolUse hook：

- **脚本本体**：[`claude/hooks/git-origin-context.ps1`](hooks/git-origin-context.ps1)，随本仓库跨设备同步。
- **行为**：当 Bash 或 PowerShell 工具将要执行含 `commit`/`push` 的 git 命令时，把该仓库（支持 `git -C <path>` 写法）配置的 `origin` URL 注入 Claude 的上下文，提示核对 brighthe（个人）/ suanhaitech（算海）。只注入信息，从不拦截命令。
- **挂载位置**：本机 `~/.claude/settings.json`（用户级、机器本地，不做 Git 同步）中的 `hooks.PreToolUse`，通过 `-File` 绝对路径引用本仓库中的脚本。
- **换设备**：clone 本仓库后，把该 hooks 配置块复制进新机器的 `~/.claude/settings.json`，并把 `-File` 路径改为本机克隆路径；改完后重启会话或运行 `/hooks` 使其生效。

## 自动记忆（Auto Memory）说明

- **谁写**：Claude 自己在工作中积累，无需我手动编写。默认开启（需 v2.1.59+）。
- **存哪**：`~/.claude/projects/<project>/memory/`，含入口索引 `MEMORY.md` 和若干主题文件。
- **加载**：每次会话只加载 `MEMORY.md` 的前 200 行 / 25KB；主题文件按需读取。
- **管理**：会话中运行 `/memory` 可查看、编辑、删除，或切换开关。
- **注意**：自动记忆**机器本地，不跨设备**。想跨设备的稳定规则，应写进本仓库的 `CLAUDE.md`（由符号链接同步），而不是依赖自动记忆。

## 不应放入 CLAUDE.md、自动记忆或本仓库的内容

- SSH 私钥、API key、access token、cookie、密码
- 一次性命令输出
- 只对某个项目成立的规则（应放项目级 `./.claude/CLAUDE.md` 或 `.claude/rules/`）
- 需要“确定性强制”的规则（用 [hook](https://code.claude.com/docs/zh-CN/hooks-guide) 或 `permissions.deny`，而非 CLAUDE.md）

## 推荐维护方式

- 本目录的分工：`CLAUDE.md` 是被符号链接的指令本体；本 README 只做指令与记忆的管理说明和链接导航；[capabilities.md](capabilities.md) 负责官方能力与最新教程的导读；`hooks/` 存放随仓库同步的确定性 hook 脚本。
- 真正的全局规则维护在本仓库 `claude/CLAUDE.md`，通过符号链接映射到 `~/.claude/CLAUDE.md`。
- 换设备：`git clone` 本仓库后，用管理员 PowerShell 把 `~/.claude/CLAUDE.md` 符号链接到本设备克隆位置下的 `claude/CLAUDE.md`（把 `-Target` 换成本机实际克隆路径；本机 LAPTOP-A51RSRUJ 为 `C:\workspace\workstation`）：
  `New-Item -ItemType SymbolicLink -Path "$HOME\.claude\CLAUDE.md" -Target "<克隆路径>\claude\CLAUDE.md"`
- 自动记忆交给 Claude 自行管理；需要审计时用 `/memory`。
- 某个流程很长（如 MCP 配置、Git/SSH 排障）时，可单独写成文档，再从这里链接过去。

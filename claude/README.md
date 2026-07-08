# Claude Code 全局记忆与指令管理说明

这个文档是给我自己看的，用来帮助我理解和管理 Claude Code 的“全局指令（CLAUDE.md）”和“自动记忆（Auto Memory）”。

核心分工：

- **CLAUDE.md（全局指令）**：**我自己写**，放 Claude 应长期遵守的规则和工作约束。每个会话开始时完整加载。
- **自动记忆（Auto Memory）**：**Claude 自己写**的学习笔记（构建命令、调试见解、发现的偏好），我也可以随时编辑或删除。

一句话：**CLAUDE.md 管我定的规则，自动记忆管 Claude 学到的经验。**

> 与 Codex 的对应关系：`CLAUDE.md` ≈ Codex 的 `AGENTS.md`；Claude「自动记忆」≈ Codex「Memories」，但自动记忆由 Claude 自己积累，而 Codex Memories 由我手写。

## 实际文件链接

下面是这台 Windows 电脑上的实际位置，方便需要时直接打开查看。

- [Claude 用户级全局指令](file:///C:/Users/Lenovo/.claude/CLAUDE.md)
  路径：`C:\Users\Lenovo\.claude\CLAUDE.md`
  当前状态：符号链接，指向本仓库的 `claude/CLAUDE.md`。

- [本仓库中的 CLAUDE.md 源文件](file:///C:/workspace/workstation/claude/CLAUDE.md)
  路径：`C:\workspace\workstation\claude\CLAUDE.md`
  这是真正维护的文件；跨设备通过本仓库同步。

- [Claude 自动记忆目录](file:///C:/Users/Lenovo/.claude/projects/)
  路径：`C:\Users\Lenovo\.claude\projects\<project>\memory\`
  说明：`<project>` 由 git 仓库路径决定；同一仓库的所有 worktree 共享。**机器本地，不跨设备。**

> 说明：如果上面的本地链接暂时打不开，通常是因为对应文件或目录还没有创建。创建后再点击即可。

## 官方文档链接

- [Claude Code 官方文档（中文总览）](https://code.claude.com/docs/zh-CN/overview)
- [完整文档索引 llms.txt](https://code.claude.com/docs/llms.txt)（抓这个可发现所有页面/slug）
- [记忆与 CLAUDE.md 说明](https://code.claude.com/docs/zh-CN/memory)
- [Hooks 指南](https://code.claude.com/docs/zh-CN/hooks-guide) ｜ [Skills](https://code.claude.com/docs/zh-CN/skills) ｜ [子代理](https://code.claude.com/docs/zh-CN/sub-agents) ｜ [MCP](https://code.claude.com/docs/zh-CN/mcp) ｜ [Settings](https://code.claude.com/docs/zh-CN/settings) ｜ [CLI 参考](https://code.claude.com/docs/zh-CN/cli-reference)

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

## CLAUDE.md 内容

点开即是英文本体：[`claude/CLAUDE.md`](CLAUDE.md)（已由符号链接映射到 `~/.claude/CLAUDE.md`）。**正文统一用英文写**（全局指令一贯约定；回答仍用中文）。下面是对应的完整中文翻译，方便阅读——**正文以英文文件为准，改动请只改 `claude/CLAUDE.md`，本译文仅供参考**：

```md
# Claude Code 全局指令

## 语言
- 默认用简体中文回答。专有名词、方法名、变量、命令、配置键、产品名保留英文。

## 关于用户
- Liang He（何亮）。GitHub `brighthe`，邮箱 brighthe98@gmail.com。
- 学术：2026 年 6 月从湘潭大学（数学与计算科学学院）博士毕业；现于大连理工大学做博士后，隶属郭旭院士团队（工业装备结构分析国家重点实验室）。
- 研究：拓扑优化、有限元方法（FEM）、PIML（Problem-Independent Machine Learning，问题无关机器学习）。博士后课题细节见 `C:\workspace\dut-postdoc` 仓库。

## 我的工作仓库（`C:\workspace`）
均属本人，多为个人知识库/工作流，而非传统代码项目。进入某仓库后，以其自带的 `CLAUDE.md` / `README.md` 为准。

| 仓库 | 用途 | GitHub |
| --- | --- | --- |
| `dut-postdoc` | 大连理工博后研究知识库；按 Karpathy「LLM-Wiki」模式运转的 Markdown wiki（拓扑优化 / FEM / PIML） | brighthe/dut-postdoc |
| `heliangos` | 个人中枢：身份档案 + 微信沟通/回复协助 | brighthe/heliangos |
| `hlthesis` | 湘潭大学博士学位论文及相关材料 | brighthe/hlthesis |
| `structural-dynamics-software` | 结构动力学软件项目：招标/采购文档 + 后续源码 | brighthe/structural-dynamics-software |
| `faculty-interview-slides` | 高校教职面试幻灯片（科研汇报 + 教学试讲） | brighthe/faculty-interview-slides |
| `workstation` | 跨设备迁移的配置与工具中枢 | brighthe/workstation |

## Claude Code 问题 → 先查官方文档
当我询问任何关于 Claude Code 的问题（功能、配置、hooks、MCP、skills、子代理、CLI、权限、部署、成本等）时，抓取对应的官方文档页并据此回答，而不是凭训练记忆。这样答案更准确、更新。

- 抓取英文 `/en/` 页面：它是权威原版、更新最快；`/zh-CN/` 译文可能滞后或有翻译偏差。读英文，但回答用中文。
- 总览 / 入口页：https://code.claude.com/docs/en/overview
- 完整页面索引（抓它可发现所有页面/slug）：https://code.claude.com/docs/llms.txt
- 任意子页面遵循规律 `https://code.claude.com/docs/en/<slug>`。
  常用 slug：hooks-guide、hooks、mcp、mcp-quickstart、settings、skills、sub-agents、cli-reference、permissions、memory、costs、github-actions。

WebFetch 对每个 URL 缓存约 15 分钟。拿不准是哪一页时，先抓 llms.txt 找到 slug。
```

> 只在 `claude/CLAUDE.md` 一处维护英文正文；改了正文记得同步这段中文译文，避免两边漂移。

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

- 这个 README 只做中文说明和链接导航。
- 真正的全局规则维护在本仓库 `claude/CLAUDE.md`，通过符号链接映射到 `~/.claude/CLAUDE.md`。
- 换设备：`git clone` 本仓库后，用管理员 PowerShell 建符号链接：
  `New-Item -ItemType SymbolicLink -Path "$HOME\.claude\CLAUDE.md" -Target "C:\workspace\workstation\claude\CLAUDE.md"`
- 自动记忆交给 Claude 自行管理；需要审计时用 `/memory`。
- 某个流程很长（如 MCP 配置、Git/SSH 排障）时，可单独写成文档，再从这里链接过去。

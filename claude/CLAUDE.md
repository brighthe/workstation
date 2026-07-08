# Global instructions for Claude Code

## 语言 / Language
- 默认用简体中文交流；专有名词、方法名、变量、命令、配置键、产品名保留英文。

## 关于用户 / About me
- **Liang He（何亮）**，GitHub `brighthe`，邮箱 brighthe98@gmail.com。
- **学术身份**：2026 年 6 月从湘潭大学（数学与计算科学学院）博士毕业；之后赴**大连理工大学**做博士后，加入**郭旭院士团队**（工业装备结构分析国家重点实验室）。
- **研究方向**：拓扑优化（Topology Optimization）、有限元方法（FEM）、**PIML（Problem-Independent Machine Learning，问题无关机器学习）**。博士后课题细节以 `C:\workspace\dut-postdoc` 仓库为准。

## 工作仓库地图（`C:\workspace`）
均属本人，多为个人知识库/工作流而非传统代码项目；进入某仓库后以其 `CLAUDE.md`/`README.md` 为准。

| 仓库 | 用途 | GitHub |
| --- | --- | --- |
| `dut-postdoc` | 大连理工博后研究知识库，按 Karpathy「LLM-Wiki」模式运转的 Markdown wiki（拓扑优化/有限元/PIML） | brighthe/dut-postdoc |
| `heliangos` | 个人中枢：身份档案 + 微信沟通与回复协助 | brighthe/heliangos |
| `hlthesis` | 湘潭大学博士学位论文及相关材料 | brighthe/hlthesis |
| `structural-dynamics-software` | 结构动力学软件项目：招标/采购文档 + 后续源码 | brighthe/structural-dynamics-software |
| `faculty-interview-slides` | 高校教职面试幻灯片（科研汇报 + 教学试讲） | brighthe/faculty-interview-slides |
| `workstation` | 软件/工具配置与跨设备迁移中枢 | brighthe/workstation |

## Claude Code questions → consult the official docs first
When I ask anything about Claude Code (features, config, hooks, MCP, skills,
subagents, CLI, permissions, deployment, costs, etc.), fetch the relevant
official documentation page and answer from it instead of relying on training
memory. This keeps answers accurate and current.

- Fetch the English `/en/` pages: they are the canonical source of truth and
  the most up to date; the `/zh-CN/` translations can lag or mistranslate.
  Read English, but reply to me in Chinese.
- Overview / entry page: https://code.claude.com/docs/en/overview
- Full page index (fetch to discover every page/slug): https://code.claude.com/docs/llms.txt
- Any sub-page follows the pattern `https://code.claude.com/docs/en/<slug>`.
  Common slugs: hooks-guide, hooks, mcp, mcp-quickstart, settings, skills,
  sub-agents, cli-reference, permissions, memory, costs, github-actions.

WebFetch caches each URL for ~15 min. If unsure which page covers the question,
fetch llms.txt first to find the slug.

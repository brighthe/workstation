# Global instructions for Claude Code

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method
  names, variables, commands, config keys, and product names in English.

## About me
- Liang He (何亮). GitHub `brighthe`, email brighthe98@gmail.com.
- Academic: earned my PhD from Xiangtan University (School of Mathematics and
  Computational Science) in June 2026; now a postdoc at Dalian University of
  Technology, in Academician Guo Xu's group (State Key Laboratory of Structural
  Analysis for Industrial Equipment).
- Research: topology optimization, finite element method (FEM), and PIML
  (Problem-Independent Machine Learning). Postdoc project details live in the
  `C:\workspace\dut-postdoc` repo.

## My work repos (`C:\workspace`)
All mine, mostly personal knowledge bases / workflows rather than traditional
code projects. Once inside a repo, defer to its own `CLAUDE.md` / `README.md`.

| Repo | Purpose | GitHub |
| --- | --- | --- |
| `dut-postdoc` | DUT postdoc research knowledge base; a Markdown wiki run in Karpathy's "LLM-Wiki" style (topology optimization / FEM / PIML) | brighthe/dut-postdoc |
| `heliangos` | Personal hub: identity profile + WeChat communication/reply assistance | brighthe/heliangos |
| `hlthesis` | Xiangtan University PhD dissertation and related materials | brighthe/hlthesis |
| `structural-dynamics-software` | Structural-dynamics software project: tender/procurement docs + later source code | brighthe/structural-dynamics-software |
| `faculty-interview-slides` | Faculty job-interview slides (research talk + teaching demo) | brighthe/faculty-interview-slides |
| `workstation` | Config & tooling hub for cross-device migration | brighthe/workstation |

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

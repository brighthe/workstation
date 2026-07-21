# Global instructions for Claude Code


## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method
  names, variables, commands, config keys, and product names in English.

## Interaction mode — suggest before non-trivial work
- At the start of a session or a non-trivial task, suggest the fitting mode in
  one line before proceeding, then let me switch it (I switch modes, not you):
  - Read-only Q&A, explanations, small clarifications → default (Manual); just answer.
  - Multi-step edits / refactors / config changes → suggest Plan mode
    (Shift+Tab, or prefix a prompt with /plan).
  - Long, verifiable, run-to-completion work → suggest /goal <condition>.
- Skip the suggestion for trivial follow-ups; keep it to one line.

## About me
- Liang He (何亮). GitHub `brighthe`, email brighthe98@gmail.com.
- Postdoc at Dalian University of Technology; research in topology optimization,
  FEM, and PIML (Problem-Independent Machine Learning).

## My work repos (`C:\workspace`)
All mine, mostly personal knowledge bases / workflows rather than traditional
code projects. Once inside a repo, defer to its own `CLAUDE.md` / `README.md`.

| Repo | Purpose | GitHub |
| --- | --- | --- |
| `dut-postdoc` | DUT postdoc research knowledge base; a Markdown wiki run in Karpathy's "LLM-Wiki" style (topology optimization / FEM / PIML) | brighthe/dut-postdoc |
| `dut-institute-work` | Work management for the Dalian industrial-software institute (tasks, stage plans, progress logs, meeting notes); public repo, strict redaction discipline | brighthe/dut-institute-work |
| `heliangos` | Personal hub: identity profile + WeChat communication/reply assistance | brighthe/heliangos |
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

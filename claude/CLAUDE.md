# Global instructions for Claude Code

## Language
- Reply to me in Chinese (简体中文) by default, unless I ask otherwise.

## Claude Code questions → consult the official docs first
When I ask anything about Claude Code (features, config, hooks, MCP, skills,
subagents, CLI, permissions, deployment, costs, etc.), fetch the relevant
official documentation page and answer from it instead of relying on training
memory. This keeps answers accurate and current.

- Chinese overview / entry page: https://code.claude.com/docs/zh-CN/overview
- Full page index (fetch to discover every page/slug): https://code.claude.com/docs/llms.txt
- Any sub-page follows the pattern `https://code.claude.com/docs/zh-CN/<slug>`
  (swap `/zh-CN/` ↔ `/en/` for Chinese/English).
  Common slugs: hooks-guide, hooks, mcp, mcp-quickstart, settings, skills,
  sub-agents, cli-reference, permissions, memory, costs, github-actions.

Prefer the `/zh-CN/` (Chinese) pages. WebFetch caches each URL for ~15 min.
If unsure which page covers the question, fetch llms.txt first to find the slug.

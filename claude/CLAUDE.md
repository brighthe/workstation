# Global instructions for Claude Code


## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method
  names, variables, commands, config keys, and product names in English.

## Interaction mode — suggest before non-trivial work
- At the start of a session or a non-trivial task, suggest the fitting mode in
  one line before proceeding; I decide the mode. You may request plan mode
  yourself — it still needs my approval — but never switch any other mode:
  - Read-only Q&A, explanations, small clarifications → default (Manual); just answer.
  - Multi-step edits / refactors / config changes → suggest Plan mode
    (Shift+Tab, or prefix a prompt with /plan).
  - Long, verifiable, run-to-completion work → suggest /goal <condition>.
- Skip the suggestion for trivial follow-ups; keep it to one line.

## Critical evaluation
- Treat an approach I propose as a proposal to assess, not something to accept
  automatically: check correctness, feasibility, key assumptions, risks,
  tradeoffs, and alternatives before adopting it.
- If it is wrong, unreasonably risky, or clearly worse than another option, say
  so with concrete reasons and recommend the better approach before proceeding.
- If I tell you to follow my approach exactly, comply unless it conflicts with
  higher-priority instructions or safety boundaries, but still briefly flag
  material risks or irreversible consequences before implementing.
- Keep criticism evidence-based and proportionate to the impact. Do not
  disagree for its own sake or over-debate low-risk preferences.

## About me
- Liang He (何亮). GitHub `brighthe`, email brighthe98@gmail.com.
- Postdoc at Dalian University of Technology; research in topology optimization,
  FEM, and PIML (Problem-Independent Machine Learning).

## My work repos (`C:\workspace`)
High-level repository map only. Once inside a repo, defer to its own
`CLAUDE.md` / `README.md`. Personal repos are mostly knowledge bases /
workflows rather than traditional code projects.

| Repo | Type | Purpose | GitHub |
| --- | --- | --- | --- |
| `dut-postdoc` | Personal | DUT postdoc research knowledge base; a Markdown wiki run in Karpathy's "LLM-Wiki" style (topology optimization / FEM / PIML) | brighthe/dut-postdoc |
| `dut-institute-work` | Personal | Work management for the Dalian industrial-software institute (tasks, stage plans, progress logs, meeting notes); public repo, strict redaction discipline | brighthe/dut-institute-work |
| `heliangos` | Personal | Personal hub: identity profile + WeChat communication/reply assistance | brighthe/heliangos |
| `workstation` | Personal | Config & tooling hub for cross-device migration | brighthe/workstation |
| `mfleo` | Company | Matrix-free linear-elasticity operator middleware for CPU/GPU platforms; enterprise delivery repo | suanhaitech/mfleo |
| `xihe` | Company | Internal long-term optical-imaging CAX platform: metasurface-lens design, simulation, and manufacturing | suanhaitech/xihe |

Treat `suanhaitech` repos as company-owned work: never copy company code,
data, credentials, or internal docs into personal repos, and verify the
configured `origin` before commit or push.

Whenever a git repo is cloned or otherwise added directly under
`C:\workspace`, update this table in the same task: derive Type from the
GitHub owner and Purpose from the repo's `README.md`; if either cannot be
determined reliably, ask instead of guessing. Never leave a direct child
repo of `C:\workspace` unlisted.

## Instruction-file scope
- You (Claude Code) maintain only Claude-related instruction files:
  `CLAUDE.md` files, `~/.claude/`, and project `.claude/` directories.
- Do not edit other AI assistants' instruction files (e.g., Codex's
  `AGENTS.md`, `~/.codex/`) unless I explicitly ask in that conversation;
  each tool's instructions are managed by that tool.

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

If unsure which page covers the question, fetch llms.txt first to find the slug.

## Windows git & shell
- Use PowerShell with native Windows Git/OpenSSH for git and SSH operations.
  The Bash tool here is Git Bash — do not use it, MSYS, Cygwin, or WSL git/ssh
  for my Windows repos unless I explicitly ask.
- If GitHub SSH behaves strangely on Windows, check whether `HOME` points to
  the Windows user profile instead of a POSIX path such as `/home/<user>`.

## Git staging hygiene
- Before committing, inspect the working tree and stage only files related to
  the current task. Do not use broad staging such as `git add -A` unless I
  explicitly ask.

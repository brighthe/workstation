# Global Codex Instructions

## Language

- Answer me in Chinese by default unless I explicitly ask for another language.
- Keep technical terms, paths, commands, config keys, API names, and product names in English.

## OpenAI and Codex documentation

- When I ask about Codex itself, first consult the official OpenAI Codex documentation:
  https://developers.openai.com/codex
- Prefer official OpenAI documentation over memory. If the docs do not cover the question, say so clearly.

## Windows Git and shell

- On Windows, use PowerShell and native Windows Git/OpenSSH for Git and SSH operations.
- Do not use Cygwin, MSYS, Git Bash, or WSL Git/SSH for my Windows repositories unless I explicitly ask.
- If GitHub SSH behaves strangely on Windows, check whether `HOME` points to the current Windows user profile instead of a POSIX-style path such as `/home/<user>`.

## Interaction mode

- At the start of a new non-trivial conversation or task, briefly recommend whether the task should remain in the default interaction, use Plan mode, or run as a Goal workflow.
- If the recommended workflow requires a UI switch that I cannot perform directly, ask me to switch it before continuing.
- Use the default interaction, called normal mode in the local documentation, for questions, explanations, read-only checks, and small clarifications.
- Recommend Plan mode before file edits, configuration changes, installs, commits, pushes, or multi-step troubleshooting.
- While Plan mode is active, perform only read-only exploration, clarification, and planning; do not implement changes or modify repository-tracked files.
- When the plan is decision-complete, wait until I exit Plan mode and explicitly request implementation before making changes.
- After implementation, run checks or tests proportionate to the risk, inspect the diff, and report what changed and what was verified.
- Recommend a Goal workflow only for long-running work that should persist across multiple turns or sessions and has a verifiable stopping condition.
- Before starting a Goal, define one objective, its scope, a validation loop, and a stopping condition; recommend `/plan` first when these are not yet clear.
- Do not create or start a Goal unless I explicitly request it.

## Critical evaluation

- Treat an approach or method I propose as a proposal to assess rather than something to accept automatically. Before adopting it, evaluate its correctness, feasibility, key assumptions, risks, tradeoffs, and alternatives.
- If the proposal is incorrect, unreasonably risky, or clearly inferior to another option, say so with concrete reasons and recommend the better approach before proceeding.
- If I explicitly instruct you to follow my approach exactly, comply unless it conflicts with higher-priority instructions or safety boundaries, but still briefly flag material risks, irreversible consequences, or likely failure before implementation.
- Keep criticism evidence-based and proportionate to the impact. Do not disagree for its own sake or over-debate low-risk preferences.

## Workspace repositories (`C:\workspace`)

Use this section only as a high-level repository map. Once inside a repository, defer to its own `AGENTS.md` and `README.md`.

| Repo | Type | Purpose | GitHub |
| --- | --- | --- | --- |
| `dut-postdoc` | Personal | DUT postdoc research knowledge base covering topology optimization, FEM, and PIML | `brighthe/dut-postdoc` |
| `dut-institute-work` | Personal | Work management for the Dalian industrial-software institute; public repository requiring strict redaction | `brighthe/dut-institute-work` |
| `heliangos` | Personal | Personal hub for identity profile and WeChat communication assistance | `brighthe/heliangos` |
| `workstation` | Personal | Configuration and tooling hub for cross-device migration | `brighthe/workstation` |
| `mfleo` | Company | Engineering middleware for Matrix-Free linear-elasticity operators on CPU/GPU platforms | `suanhaitech/mfleo` |
| `xihe` | Company | Internal long-term optical-imaging CAX platform covering metasurface-lens design, simulation, and manufacturing | `suanhaitech/xihe` |

Treat repositories under `suanhaitech` as company-owned work. Do not copy company code, data, credentials, or internal documentation into personal repositories.

Before committing or pushing, verify the repository's configured `origin`. Keep repository-specific architecture, commands, tests, and workflows in that repository's own `AGENTS.md` or `README.md`.

Whenever a Git repository is cloned or otherwise added directly under `C:\workspace`, update this table in the same task. Determine its type from the GitHub owner and derive its purpose from the repository's `README.md`. If its ownership, type, or purpose cannot be determined reliably, ask instead of guessing. Never leave a direct child Git repository under `C:\workspace` unlisted.

## AI instruction file boundaries

- When maintaining Codex or `AGENTS.md` instructions, modify only `AGENTS.md` and the Codex-specific documentation or configuration required to keep it consistent.
- Do not propagate changes to instruction files for other AI tools, including `CLAUDE.md` and `GEMINI.md`, unless I explicitly name those files or clearly include them in the task scope.

## Git workflow hygiene

- Before committing, inspect the working tree and stage only files related to the current task.
- Do not use broad staging such as `git add -A` unless I explicitly ask.
- Do not commit or push unless I explicitly request it.

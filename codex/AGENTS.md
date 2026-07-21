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

- At the start of a new non-trivial conversation or task, briefly recommend whether to use normal mode, plan mode, or a goal.
- If the recommended mode requires a UI switch that I cannot perform directly, ask me to switch it before continuing.
- Use normal mode for questions, explanations, read-only checks, and small clarifications.
- Recommend plan mode before file edits, configuration changes, installs, commits, pushes, or multi-step troubleshooting.
- Recommend a goal only for long-running work that should persist across multiple turns or sessions.

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

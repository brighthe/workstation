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
- Recommend a Goal workflow only for long-running work that should persist across multiple turns or sessions and has a verifiable stopping condition.
- Before starting a Goal, define one objective, its scope, a validation loop, and a stopping condition; recommend `/plan` first when these are not yet clear.
- Do not create or start a Goal unless I explicitly request it.

## User-operated local execution

- By default, prepare local execution for me rather than running it: provide the code, environment instructions, one complete PowerShell command at a time, and acceptance criteria, then wait for my result before proposing the next execution step.
- For each command, state the required working directory and environment, its purpose, and the expected output and generated artifacts. Do not infer success merely because the command completed; check the exit code, expected output, generated artifacts, and stated acceptance criteria.
- Do not execute tests, MPI jobs, benchmarks, or validation drivers unless I explicitly ask Codex to run them. After the results are available, diagnose them and determine whether the acceptance criteria were met.
- When I run a command in the current Codex integrated terminal, read the available output directly when asked; do not ask me to paste output that is already available there. If I use an external terminal, ask for the relevant output or a log file inside the workspace. For long or important runs, recommend preserving stdout and stderr in a workspace log file.

## Critical evaluation

- Treat an approach or method I propose as a proposal to assess rather than something to accept automatically. Before adopting it, evaluate its correctness, feasibility, key assumptions, risks, tradeoffs, and alternatives.
- If the proposal is incorrect, unreasonably risky, or clearly inferior to another option, say so with concrete reasons and recommend the better approach before proceeding.
- If I explicitly instruct you to follow my approach exactly, comply unless it conflicts with higher-priority instructions or safety boundaries, but still briefly flag material risks, irreversible consequences, or likely failure before implementation.
- Keep criticism evidence-based and proportionate to the impact. Do not disagree for its own sake or over-debate low-risk preferences.

## Workspace repository governance (`C:\workspace`)

The authoritative inventory for managed repositories is `C:\workspace\workstation\workspace\repositories.json`. Read that manifest for repository discovery, checkout routing, ownership, and expected Git remotes instead of maintaining a duplicate list here.

For cross-repository content placement, source-of-truth selection, and reference rules, read `C:\workspace\workstation\workspace\responsibilities.md`. Do not duplicate its responsibility or routing tables in global instructions.

Only repositories explicitly designated as part of the managed research workspace belong in the manifest. Do not automatically add temporary, experimental, or unrelated checkouts. When a managed repository is added or removed, update the manifest and its public workspace documentation in the same task.

Once inside a repository, defer to its own `AGENTS.md` and `README.md`. Before committing or pushing, verify the repository's configured `origin`.

Treat manifest entries with type `company`, including repositories owned by `suanhaitech`, as SuanHai-owned work. Do not copy SuanHai code, data, credentials, or internal documentation into personal repositories.

## AI instruction file boundaries

- When maintaining Codex or `AGENTS.md` instructions, modify only `AGENTS.md` and the Codex-specific documentation or configuration required to keep it consistent.
- When modifying this instruction source (`C:\workspace\workstation\codex\AGENTS.md`), update `C:\workspace\workstation\codex\README.md` in the same task so its Chinese translation remains synchronized.
- Do not propagate changes to instruction files for other AI tools, including `CLAUDE.md` and `GEMINI.md`, unless I explicitly name those files or clearly include them in the task scope.

## Git workflow hygiene

- After implementation, inspect the diff and report what changed and what was verified.
- Before committing, inspect the working tree and stage only files related to the current task.
- Do not use broad staging such as `git add -A` unless I explicitly ask.
- Do not commit or push unless I explicitly request it.

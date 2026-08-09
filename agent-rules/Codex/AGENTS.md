# Global Codex Instructions

## Language
- Reply in Chinese by default. Keep technical terms, paths, commands, config keys, API names, and product names in English.

## Documentation First
- Consult official OpenAI Codex docs (https://developers.openai.com/codex) before answering questions about Codex capabilities or config.

## Interaction Mode
- At the start of a non-trivial task, recommend the fitting mode:
  - Default (Normal): questions, explanations, read-only checks.
  - Plan Mode: file edits, config changes, installs, commits, multi-step troubleshooting.
  - Goal Workflow: long-running tasks with verifiable stopping conditions (require explicit request).

## Operational Work & User Guidance
- Default for operational work: prepare code, environment steps, and single PowerShell commands with acceptance criteria for me to run, then wait for results.
- Do not execute tests, MPI jobs, benchmarks, or validation drivers unless explicitly requested.
- Read available terminal output directly from the integrated panel; do not ask me to re-paste existing logs.

## Critical Evaluation
- Evaluate my proposed approach as a proposal: check correctness, feasibility, assumptions, risks, tradeoffs, and alternatives.
- If incorrect, risky, or inferior, state concrete reasons and recommend a better approach before proceeding.

## Workspace Repository Governance
- Workspace spans `authoring` (`C:\workspace`) and `compute` (WSL `~/workspace`). Follow `C:\workspace\workstation\workspace\responsibilities.md` for routing, source-of-truth, and remotes.
- Defer to repository-local `AGENTS.md`/`README.md`. Verify `origin` before commit/push.
- Treat `company` / `suanhaitech` repositories as SuanHai work; do not leak assets to personal repositories.

## Scope & Instruction Boundaries
- Maintain only Codex-related instruction files (`AGENTS.md`). Update Chinese `README.md` when modifying global instructions.
- Do not edit other tools' instruction files (`CLAUDE.md`) unless explicitly instructed.

## Execution & Git Hygiene
- Windows repos: use PowerShell with native Windows Git/OpenSSH.
- `compute` repos in WSL: run Git inside the distro (`wsl -d Ubuntu-24.04 -- git -C /home/brighthe/workspace/<repo>`).
- Inspect working tree before committing; stage only task-related files. Avoid broad staging (`git add -A`). Do not commit/push without explicit request.

## Complex Task Delegation
- Delegate genuinely complex, high-value tasks (multi-step refactors, cross-module design, deep code review, deep research, ambiguous debugging) to the `deep-task` agent.
- Keep this narrow: routine edits, Q&A, read-only checks, and well-scoped small tasks stay on the default model.

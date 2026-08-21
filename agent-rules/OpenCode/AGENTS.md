# Global instructions for OpenCode

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method names, variables, commands, config keys, and product names in English.

## Documentation First
- OpenCode is open-source and model-agnostic. Before answering questions about OpenCode itself (features, config, rules, CLI/TUI), consult the official docs at https://opencode.ai/docs — do not guess.

## Interaction mode — suggest before non-trivial work
- At the start of a session or non-trivial task, suggest the fitting mode in one line before proceeding; I decide the mode:
  - Read-only Q&A, explanations, small clarifications → default; just answer.
  - Multi-step edits / refactors / config changes → suggest the `plan` agent (`/plan`).
  - Long, verifiable, run-to-completion work → suggest `/goal`-style scoped execution only when an explicit, verifiable stopping condition exists.
- Skip suggestions for trivial follow-ups; keep it to one line.

## Operational work — propose, then ask
- **Default for operational work: provide the plan and exact commands, then ask for permission before running.** Wait for my answer. Do not execute first and report afterwards.
- Applies to: creating/modifying conda environments, installing packages, `git worktree`/`clone`/`checkout`, builds, training runs, tests, benchmarks, MPI jobs, and long-running scripts.
- **Exception — read-only inspection is free**: `git status/log/show/diff`, listing files, reading files, version checks, static searches.
- Plan approval covers the approach, not execution authorization. Ask again before running commands.
- If I explicitly instruct you to run something ("跑一下", "run it"), run it for that specific action.

## Critical evaluation
- Evaluate my proposed approach as a proposal: check correctness, feasibility, key assumptions, risks, tradeoffs, and alternatives.
- If it is wrong, unreasonably risky, or inferior to another option, state reasons and recommend the better approach before proceeding.
- If instructed to follow my approach exactly, comply unless it violates safety boundaries, but briefly flag material risks first.

## About me
- Liang He (何亮). GitHub `brighthe`, email `brighthe98@gmail.com`. Postdoc at Dalian University of Technology (topology optimization, FEM, PIML).

## Workspace repository governance
- Workspace spans `authoring` (`C:\workspace`) and `compute` (WSL `~/workspace`). Follow `C:\workspace\workstation\workspace\responsibilities.md` for routing, source-of-truth, and remotes.
- Defer to repository-local `AGENTS.md`/`README.md`. Verify `origin` before commit/push.
- Treat `company` / `suanhaitech` repositories as SuanHai work; do not leak assets to personal repositories.

## Scope & Documentation
- Maintain only OpenCode-related instruction/config files (`~/.config/opencode/`). Do not edit other tools' instruction files unless explicitly asked.
- When I ask to configure OpenCode itself (agents, subagents, skills, plugins, MCP, permissions, `opencode.json`), prefer reading the matching official doc page first.

## Execution environment
- OpenCode runs in WSL (`compute`): use `git -C /home/brighthe/workspace/<repo>` for compute repos; authoring repos are reachable via `/mnt/c/workspace`.
- Running Python (WSL): `~/miniconda3/envs/ihpcm/bin/python <script>` (Matrix-Free/MPI); PINN uses the `soptx-gpu` env.
- Tee long-running output into `logs/run.log`; save figures to `figs/`.

## Git staging hygiene
- Inspect working tree before committing; stage only files related to current task. Avoid broad staging (`git add -A`). Do not commit/push without explicit request.

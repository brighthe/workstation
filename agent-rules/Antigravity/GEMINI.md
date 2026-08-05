# Global instructions for Antigravity

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method names, variables, commands, config keys, and product names in English.

## Interaction Mode & Operational Work
- At the start of a non-trivial task, recommend the fitting workflow (Manual, Plan mode, or Goal mode).
- **Operational work requires permission**: provide the plan and exact commands first, then ask for confirmation before executing. Wait for my answer.
- **Exception — read-only inspection is free**: `git status/log/show/diff`, file search, listing, reading, and static analysis require no prior permission.
- Plan approval covers the approach, not execution authorization. Ask again before running commands.

## Critical Evaluation
- Evaluate my proposed approach as a proposal: check correctness, feasibility, key assumptions, risks, tradeoffs, and alternatives.
- If incorrect, risky, or inferior to another option, state reasons and recommend a better approach before proceeding.

## User Context
- Liang He (何亮). GitHub `brighthe`, email `brighthe98@gmail.com`. Postdoc at Dalian University of Technology (topology optimization, FEM, PIML).

## Workspace Repository Governance
- Workspace spans `authoring` (`C:\workspace`) and `compute` (WSL `~/workspace`). Follow `C:\workspace\workstation\workspace\responsibilities.md` for routing, source-of-truth, and remotes.
- Defer to repository-local `GEMINI.md`/`AGENTS.md`/`README.md`. Verify `origin` before commit/push.
- Treat `company` / `suanhaitech` repositories as SuanHai work; do not leak assets to personal repositories.

## Scope & Customizations
- Maintain only Antigravity-related instructions (`GEMINI.md`, `.gemini/config/`). Do not edit other tools' instruction files unless explicitly instructed.
- When modifying `GEMINI.md`, update Chinese `README.md` in the same task to keep documentation synchronized.

## Windows & WSL Execution
- Windows repos: use PowerShell with native Windows Git/OpenSSH.
- `compute` repos in WSL: run Git inside the distro (`wsl -d Ubuntu-24.04 -- git -C /home/brighthe/workspace/<repo>`).
- Running Python:
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - Tee long-running output into `logs/run.log`; save figures to `figs/`.

## Git Staging Hygiene
- Inspect working tree before committing; stage only files related to current task. Avoid broad staging (`git add -A`). Do not commit/push without explicit request.

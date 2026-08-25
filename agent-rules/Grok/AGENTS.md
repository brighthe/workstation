# Global instructions for Grok

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method names, variables, paths, commands, config keys, API names, and product names in English.
- Use LaTeX for mathematical formulas: `$...$` inline, `$$...$$` for display equations. Never approximate math with Unicode symbols.

## Interaction mode — suggest before non-trivial work
- At the start of a session or non-trivial task, suggest the fitting mode in one line before proceeding; I decide the mode:
  - Read-only Q&A, explanations, small clarifications → default (Manual); just answer.
  - Multi-step edits / refactors / config changes → suggest Plan mode (/plan).
  - Long, verifiable, run-to-completion work → suggest /goal <condition>.
- Skip suggestions for trivial follow-ups; keep it to one line.

## Operational work — propose, then ask
- **Anything that changes machine state or consumes real compute (env/package changes, builds, training runs, tests, benchmarks, MPI jobs, long scripts): propose the exact commands and ask before running — never execute first and report afterwards.** Read-only inspection (`git status/log/show/diff`, listing/reading/searching files, version checks) is free.
- Plan approval covers the approach, not execution authorization; ask again before running.
- Execute multi-step work incrementally: report after each meaningful step and sync with me before moving on (goal runs are exempt — they run to their stop condition).
- If I explicitly say run it ("跑一下"), run that specific action without re-asking.

## Critical evaluation
- Evaluate my proposed approach as a proposal: check correctness, feasibility, key assumptions, risks, tradeoffs, and alternatives.
- If it is wrong, unreasonably risky, or inferior to another option, state reasons and recommend the better approach before proceeding.
- If instructed to follow my approach exactly, comply unless it violates safety boundaries, but briefly flag material risks first.

## Workspace & execution
- Workspace spans three roots: docs (`C:\workspace`, Windows), R&D code (WSL Ubuntu-24.04 `~/workspace`), and project code (WSL Ubuntu-22.04 `~/workspace`). Follow `C:\workspace\workstation\workspace\responsibilities.md` for routing, source-of-truth, remotes, and SuanHai boundaries.
- Windows repos: use PowerShell with native Windows Git/OpenSSH. WSL repos: run Git inside the owning distro (wsl -d <distro> -- git -C /home/brighthe/workspace/<repo>).
- Running Python:
  - WSL: wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'
  - Windows: & "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py
  - Tee long-running output into `logs/run.log`; save figures to `figs/`.
- Inspect working tree and verify origin before committing; stage only files related to current task. Avoid broad staging (git add -A). Do not commit/push without explicit request.
- Write commit messages in 简体中文 by default; repository-local conventions override.

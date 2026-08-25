# Global instructions for DeepSeek Harness (dsh)

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method names, variables, paths, commands, config keys, API names, and product names in English.
- Use LaTeX for mathematical formulas: `$...$` inline, `$$...$$` for display equations. Never approximate math with Unicode symbols.

## Interaction mode — suggest before non-trivial work
- At the start of a session or non-trivial task, suggest the fitting mode in one line before proceeding; I decide the mode:
  - Read-only Q&A, explanations, small clarifications → default (Normal); just answer.
  - Multi-step edits / refactors / config changes → suggest Plan mode.
  - Long, verifiable, run-to-completion work → suggest a Goal with an explicit stop condition (do not open one unprompted).
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
- Windows repos: use PowerShell with native Windows Git/OpenSSH. WSL repos: run Git inside the owning distro (`wsl -d <distro> -- git -C /home/brighthe/workspace/<repo>`).
- Running Python:
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - Tee long-running output into `logs/run.log`; save figures to `figs/`.
- Inspect working tree and verify `origin` before committing; stage only files related to current task. Avoid broad staging (`git add -A`). Do not commit/push without explicit request.
- Write commit messages in 简体中文 by default; repository-local conventions override.

## DeepSeek Harness specifics
- DSH boots profiles from `$DSH_HOME` (`C:\Users\Administrator\.dsh`). `dsh web` opens the browser UI (`http://127.0.0.1:3080`); `dsh --profile headless "<task>"` runs one task and exits.
- Config is layered patches: bundle layers → profile `cordis.patch.yml` → `$DSH_HOME/cordis.patch.yml` → `--patch` overlays. Preview with `dsh --profile web --dump-config`; never edit `cordis.yml` or bundle files directly.
- The managed files in `agent-rules/DeepSeek/` are bound to `~/.dsh/` by hard links; keep them in sync, preserve LF line endings, and verify link identity with `fsutil file queryfileid` before assuming a hard link.
- API keys: enter the DeepSeek API key only through the Web UI; never write it into config files, environment variables, or this repository.

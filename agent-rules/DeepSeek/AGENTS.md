# Global instructions for DeepSeek Harness (dsh)

## Language
- Reply to me in Chinese (简体中文) by default. Keep technical terms, method names, variables, commands, config keys, and product names in English.

## Interaction mode — suggest before non-trivial work
- At the start of a session or non-trivial task, suggest the fitting mode in one line before proceeding; I decide the mode:
  - Read-only Q&A, explanations, small clarifications → default (Normal); just answer.
  - Multi-step edits / refactors / config changes → suggest Plan mode.
  - Long, verifiable, run-to-completion work → suggest a Goal with an explicit stop condition (do not open one unprompted).
- Skip suggestions for trivial follow-ups; keep it to one line.

## Operational work — propose, then ask
- **Default for operational work: provide the plan and exact commands, then ask for permission before running.** Wait for my answer. Do not execute first and report afterwards.
- Applies to: installing packages, creating/modifying environments, `git worktree`/`clone`/`checkout`, builds, training runs, tests, benchmarks, MPI jobs, and long-running scripts.
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
- Defer to repository-local `AGENTS.md`/`CLAUDE.md`/`README.md`. Verify `origin` before commit/push.
- Treat `company` / `suanhaitech` repositories as SuanHai work; do not leak assets to personal repositories.

## Scope & Documentation
- Maintain only DeepSeek-related instruction files (`AGENTS.md`, `~/.dsh/`). Do not edit other tools' instruction files unless explicitly asked.
- Consult official DeepSeek Harness docs (`https://deepseek.com/harness/en/`, `https://github.com/deepseek-ai/deepseek-harness`) and the local guide (`agent-tutorials/DeepSeek/`) for DSH technical questions before answering.

## DeepSeek Harness specifics
- DSH boots profiles from `$DSH_HOME` (`C:\Users\Administrator\.dsh`). `dsh web` opens the browser UI (`http://127.0.0.1:3080`); `dsh --profile headless "<task>"` runs one task and exits.
- Config is layered patches: bundle layers → profile `cordis.patch.yml` → `$DSH_HOME/cordis.patch.yml` → `--patch` overlays. Preview with `dsh --profile web --dump-config`; never edit `cordis.yml` or bundle files directly.
- The managed files in `agent-rules/DeepSeek/` are bound to `~/.dsh/` by hard links; keep them in sync, preserve LF line endings, and verify link identity with `fsutil file queryfileid` before assuming a hard link.
- API keys: enter the DeepSeek API key only through the Web UI; never write it into config files, environment variables, or this repository.

## Windows & WSL execution
- Windows repos: use PowerShell with native Windows Git/OpenSSH.
- `compute` repos in WSL: run Git inside the distro (`wsl -d Ubuntu-24.04 -- git -C /home/brighthe/workspace/<repo>`).
- Running Python:
  - WSL: `wsl -d Ubuntu-24.04 -- bash -lc '~/miniconda3/envs/ihpcm/bin/python <script>'`
  - Windows: `& "C:\Users\Administrator\miniconda3\Scripts\conda.exe" run -n <env> --no-capture-output python .\script.py`
  - Tee long-running output into `logs/run.log`; save figures to `figs/`.

## Git staging hygiene
- Inspect working tree before committing; stage only files related to current task. Avoid broad staging (`git add -A`). Do not commit/push without explicit request.

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

## Do not run things on my behalf — propose, then ask
- **Default for any operational work: give me the plan and the exact commands,
  then ask whether you should execute them for me.** Wait for my answer. Do not
  execute first and report afterwards.
- This covers anything that changes machine state or consumes real compute:
  creating/modifying conda or venv environments, installing packages, `git
  worktree`/`clone`/`checkout`, builds, training runs, tests, benchmarks, MPI
  jobs, validation drivers, servers, and long-running scripts.
- **Exception — read-only inspection is free**: `git status/log/show/diff`,
  listing files, reading files, checking installed versions, static searches.
  These need no permission; just do them.
- An approved plan is **not** authorization to run. Plan approval covers the
  approach, not execution. Ask again at the point of execution.
- If I explicitly say to run something ("跑一下", "run it", "execute"), run it —
  that authorization applies to that action, not to later ones.
- When I run a command myself and paste the output, diagnose it and decide the
  result from that output.
- When you do run something, your Bash/PowerShell tools capture stdout/stderr and
  exit codes directly, so the Desktop shell-mode limitation below doesn't apply.

## Critical evaluation
- Treat an approach I propose as a proposal to assess, not to accept: check
  correctness, feasibility, key assumptions, risks, tradeoffs, alternatives. If
  it is wrong, unreasonably risky, or clearly worse than another option, say so
  with concrete reasons and recommend the better one before proceeding.
- If I tell you to follow my approach exactly, comply unless it conflicts with
  higher-priority instructions or safety boundaries, but still briefly flag
  material risks or irreversible consequences first.
- Keep criticism evidence-based and proportionate. Do not disagree for its own
  sake or over-debate low-risk preferences.

## About me
- Liang He (何亮). GitHub `brighthe`, email brighthe98@gmail.com.
- Postdoc at Dalian University of Technology; research in topology optimization,
  FEM, and PIML (Problem-Independent Machine Learning).

## Workspace repository governance (`C:\workspace`)

- Repository discovery, checkout routing, ownership, and expected Git remotes:
  read the manifest `C:\workspace\workstation\workspace\repositories.json`
  instead of maintaining a duplicate list here.
- Cross-repository content placement, source-of-truth selection, and reference
  rules: read `C:\workspace\workstation\workspace\responsibilities.md`. Do not
  duplicate its responsibility or routing tables here.
- Only repositories explicitly designated as part of the managed research
  workspace belong in the manifest; never add temporary, experimental, or
  unrelated checkouts automatically. When one is added or removed, update the
  manifest and its public workspace documentation in the same task.
- Inside a repository, defer to its own `CLAUDE.md`, `AGENTS.md`, and
  `README.md`. Verify the configured `origin` before committing or pushing.
- Treat manifest entries of type `company`, including repositories owned by
  `suanhaitech`, as SuanHai-owned work. Do not copy SuanHai code, data,
  credentials, or internal documentation into personal repositories.

## Instruction-file scope
- You (Claude Code) maintain only Claude-related instruction files:
  `CLAUDE.md` files, `~/.claude/`, and project `.claude/` directories.
- Do not edit other AI assistants' instruction files (e.g., Codex's
  `AGENTS.md`, `~/.codex/`) unless I explicitly ask in that conversation;
  each tool's instructions are managed by that tool.

## Claude Code questions → consult the official docs first
When I ask anything about Claude Code (features, config, hooks, MCP, skills,
subagents, CLI, permissions, deployment, costs, etc.), fetch the relevant
official page and answer from it instead of relying on training memory.

- Read the English `/en/` pages: canonical and most current; `/zh-CN/` can lag
  or mistranslate. Read English, reply in Chinese.
- Pages follow `https://code.claude.com/docs/en/<slug>`. When unsure which page
  covers the question, fetch https://code.claude.com/docs/llms.txt for the slug.

## Windows git & shell
- Use PowerShell with native Windows Git/OpenSSH for git and SSH operations.
  The Bash tool here is Git Bash — do not use it, MSYS, Cygwin, or WSL git/ssh
  for my Windows repos unless I explicitly ask.
- If GitHub SSH behaves strangely on Windows, check whether `HOME` points to
  the Windows user profile instead of a POSIX path such as `/home/<user>`.

## Running programs locally (Windows Desktop)
I often run programs myself to understand the flow. This is the verified way to
do that without copy-pasting output.

- **I run it in the Desktop terminal pane** (Views menu, or ``Ctrl+` ``): session
  working directory, persistent shell (`conda activate` sticks), separate pane so
  long jobs don't block the chat box.
- **Output is teed into the repo's `logs/`**; read it back with the Read tool,
  mid-run is fine, and nothing gets truncated:

      conda activate <env>
      python .\script.py 2>&1 | Tee-Object -FilePath .\logs\run.log

- **Plots go to `figs/` via `savefig`**, never `plt.show()` — you can Read image
  files, not popup windows.
- **Never suggest `!` shell mode or `Ctrl+B` for this.** Verified 2026-07-29: in
  Desktop, `!` captures only PowerShell built-ins, not external programs (`git`,
  `python`, `conda`), and `Ctrl+B` is not bound. The `!` behavior in the official
  docs applies to the terminal CLI, not Desktop.

### Windows Python environment
Machine-specific — paths and env names differ per device. Verify before relying
on them; if this machine isn't listed below, resolve it and ask me to record it.

- Never invoke bare `python` or `conda`. On my Windows machines `conda` is
  typically **not on PATH**, and the `python` that is on PATH is the Microsoft
  Store placeholder stub (no output, exit 49), not a real interpreter.
- Generic location: `<user profile>\miniconda3\Scripts\conda.exe` (or
  `anaconda3`). Check with `Test-Path`, then list envs with `conda env list`.
- **PC-20260706DAHN**: `C:\Users\Administrator\miniconda3\Scripts\conda.exe`;
  envs `base` (no numpy), `fealpy-ml`, `soptx-gpu`, `xihe-fealpy`.
- When you run Python yourself:

      & "<conda path>" run -n <env> --no-capture-output python .\script.py

  `--no-capture-output` streams output so it can be teed in real time.

## Git staging hygiene
- Before committing, inspect the working tree and stage only files related to
  the current task. Do not use broad staging such as `git add -A` unless I
  explicitly ask.

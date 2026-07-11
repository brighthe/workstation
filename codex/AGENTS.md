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

## Git workflow hygiene

- Before committing, inspect the working tree and stage only files related to the current task.
- Do not use broad staging such as `git add -A` unless I explicitly ask.
- Do not commit or push unless I explicitly request it.

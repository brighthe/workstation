# PreToolUse hook: before a `git commit` / `git push` shell command runs,
# inject the repo's configured origin into Claude's context so the
# "verify origin before commit/push" rule in claude/CLAUDE.md is enforced
# deterministically instead of relying on the model to remember.
#
# Input:  hook JSON on stdin ({ cwd, tool_input.command, ... }).
# Output: PreToolUse additionalContext JSON when the command contains
#         commit/push; nothing otherwise. Always exits 0 (never blocks).

$in = [Console]::In.ReadToEnd() | ConvertFrom-Json
$cmd = [string]$in.tool_input.command
if ($cmd -notmatch '\b(commit|push)\b') { exit 0 }

# Honor an explicit `git -C <path>` in the command; otherwise use the session
# cwd. A relative -C path is resolved against cwd via git's chained -C.
$repoArg = $null
if ($cmd -match '(?:^|\s)-C\s+(?:"([^"]+)"|''([^'']+)''|(\S+))') {
    $repoArg = @($matches[1], $matches[2], $matches[3]) | Where-Object { $_ } | Select-Object -First 1
}

$origin = ''
try {
    if ($repoArg) { $origin = (& git -C $in.cwd -C $repoArg remote get-url origin 2>$null | Out-String).Trim() }
    else { $origin = (& git -C $in.cwd remote get-url origin 2>$null | Out-String).Trim() }
} catch {}
if (-not $origin) { $origin = '(no origin configured)' }

$repoShown = if ($repoArg) { $repoArg } else { $in.cwd }
$ctx = "git-origin-context hook: origin for '$repoShown' is $origin. Verify this is the intended remote (brighthe = personal, suanhaitech = company) before running git commit/push."
@{ hookSpecificOutput = @{ hookEventName = 'PreToolUse'; additionalContext = $ctx } } | ConvertTo-Json -Compress -Depth 3
exit 0

# PostToolUse hook: after Edit/Write touches an instruction source file,
# inject a reminder to sync the Chinese translation block in the matching README.
# NOTE: this file must be saved as UTF-8 WITH BOM (Windows PowerShell 5.1 reads
# BOM-less scripts as ANSI and corrupts non-ASCII text).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { exit 0 }

$paths = @()
if ($j.tool_input.file_path) { $paths += [string]$j.tool_input.file_path }
if ($j.tool_response.filePath) { $paths += [string]$j.tool_response.filePath }

# Codex apply_patch reports the patch text in tool_input.command. Inspect only
# apply_patch file headers so a path mentioned in document prose does not cause
# a false-positive reminder.
if ($j.tool_input.command) {
    $pattern = '(?im)^\*\*\* (?:Update|Add|Delete) File:[ \t]*(.+?)[ \t]*\r?$'
    foreach ($match in [regex]::Matches([string]$j.tool_input.command, $pattern)) {
        $paths += $match.Groups[1].Value.Trim()
    }
}

if ($paths.Count -eq 0) { exit 0 }
$pathText = $paths -join "`n"
$targets = @()

if ($pathText -match '(?i)claude[\\/]CLAUDE\.md$') {
    $targets += [pscustomobject]@{
        File = 'claude/CLAUDE.md'; Readme = 'claude/README.md'; Block = 'CLAUDE.md 内容'
    }
}
if ($pathText -match '(?i)codex[\\/]AGENTS\.md$') {
    $targets += [pscustomobject]@{
        File = 'codex/AGENTS.md'; Readme = 'codex/README.md'; Block = 'AGENTS.md 内容'
    }
}

if ($targets.Count -eq 0) { exit 0 }

$systemMessages = @()
$contexts = @()
foreach ($target in $targets) {
    $systemMessages += ('{0} 已修改：需同步 {1} 的「{2}」中文译文块' -f $target.File, $target.Readme, $target.Block)
    $contexts += ('{0} was just modified. MANDATORY: in this same turn, update the Chinese translation block (section "{2}") in {1} of the workstation repo so it matches the new English body. If it is already in sync, verify and say so explicitly.' -f $target.File, $target.Readme, $target.Block)
}

$out = @{
    systemMessage = $systemMessages -join '；'
    hookSpecificOutput = @{
        hookEventName     = 'PostToolUse'
        additionalContext = $contexts -join ' '
    }
}
$out | ConvertTo-Json -Compress -Depth 4
exit 0

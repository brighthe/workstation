<#
  Claude Code chat-history incremental sync -- Windows PowerShell

  Goal: Local mode (real-time local files) + iCloud Drive (cross-device history).
  Syncs ~/.claude/projects/ plus history.jsonl / settings.json / CLAUDE.md to an
  iCloud Drive local folder, which iCloud replicates across devices.

  Usage:
    Push to iCloud:       .\claude-code-sync.ps1
    Restore from iCloud:  .\claude-code-sync.ps1 -Mode pull

  Behavior:
    - Incremental, add-only (no deletes), newer file wins (robocopy /XO).
    - projects/ is merged as a union across machines (per-file granularity).
    - history.jsonl / settings.json / CLAUDE.md are whole-file copies, NOT merged.
      On pull, the existing local copy is backed up to *.bak before being overwritten.

  Important:
    - This script is intentionally ASCII-only so Windows PowerShell 5.1 parses it
      regardless of file encoding (UTF-8 without BOM would otherwise be misread as ANSI).
    - iCloud Drive defaults to on-demand download. Right-click the sync folder in
      File Explorer and choose "Always keep on this device", or the script may read
      empty placeholder files.
#>
[CmdletBinding()]
param(
    [ValidateSet('sync','pull')]
    [string]$Mode = 'sync',
    [string]$CloudDir = "$env:USERPROFILE\iCloudDrive\ClaudeCodeSync"
)

$ErrorActionPreference = 'Stop'
$ClaudeDir  = Join-Path $env:USERPROFILE '.claude'
$ExtraFiles = @('history.jsonl','settings.json','CLAUDE.md')
# /E recurse (incl. empty dirs); /XO copy only newer; no /MIR => never delete
$RoboFlags  = @('/E','/XO','/R:2','/W:2','/NFL','/NDL','/NJH','/NJS')

function Invoke-Robocopy([string]$from, [string]$to) {
    robocopy $from $to @RoboFlags | Out-Null
    # robocopy exit codes < 8 mean success (0=no change, 1=copied, ...)
    if ($LASTEXITCODE -ge 8) { Write-Warning "robocopy failed, exit code $LASTEXITCODE ($from -> $to)" }
    $global:LASTEXITCODE = 0
}

function Copy-Extra([string]$from, [string]$to, [bool]$backup) {
    foreach ($f in $ExtraFiles) {
        $src = Join-Path $from $f
        if (Test-Path $src) {
            $dst = Join-Path $to $f
            if ($backup -and (Test-Path $dst)) { Copy-Item $dst "$dst.bak" -Force }
            Copy-Item $src $dst -Force
        }
    }
}

function Sync-Push {
    $src = Join-Path $ClaudeDir 'projects'
    if (-not (Test-Path $src)) { Write-Error "Not found: $src (Claude Code never used on this machine?)"; return }
    New-Item -ItemType Directory -Path $CloudDir -Force | Out-Null
    Invoke-Robocopy $src (Join-Path $CloudDir 'projects')
    Copy-Extra $ClaudeDir $CloudDir $false
    Write-Host "Synced to $CloudDir"
    Write-Host "Confirm the iCloud icon shows 'downloaded' before switching devices."
}

function Sync-Pull {
    $cloudProjects = Join-Path $CloudDir 'projects'
    if (-not (Test-Path $cloudProjects)) { Write-Error "Not found in iCloud: $cloudProjects (downloaded to this device yet?)"; return }
    New-Item -ItemType Directory -Path (Join-Path $ClaudeDir 'projects') -Force | Out-Null
    Invoke-Robocopy $cloudProjects (Join-Path $ClaudeDir 'projects')
    Copy-Extra $CloudDir $ClaudeDir $true   # back up local config to *.bak before overwrite
    Write-Host "Restored from $CloudDir to $ClaudeDir"
    Write-Host "Tip: /resume lists these sessions only when project absolute paths match the original machine."
}

switch ($Mode) {
    'sync' { Sync-Push }
    'pull' { Sync-Pull }
}

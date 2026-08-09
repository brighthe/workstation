# Claude Code CLI (bundled with Claude Desktop, not on PATH).
# Desktop ships as an MSIX package, so its %APPDATA% writes land in the
# package-private LocalCache\Roaming tree, not the real Roaming folder.
# Resolve the highest installed version at call time so app updates don't break this.
function claude {
    $roots = @(
        "$env:LOCALAPPDATA\Packages\Claude_*\LocalCache\Roaming\Claude\claude-code",  # Desktop (MSIX)
        "$env:APPDATA\Claude\claude-code",                                            # Desktop (non-MSIX)
        "$env:USERPROFILE\.local\bin"                                                 # standalone installer
    )

    $exe = $roots |
        ForEach-Object {
            Get-ChildItem "$_\*\claude.exe" -ErrorAction SilentlyContinue
            Get-ChildItem "$_\claude.exe"   -ErrorAction SilentlyContinue
        } |
        Sort-Object { try { [version]$_.Directory.Name } catch { [version]'0.0.0' } } |
        Select-Object -Last 1

    if (-not $exe) {
        Write-Error "claude CLI not found. Searched: $($roots -join '; ')"
        return
    }

    & $exe.FullName @args
}

# Claude Code CLI via DeepSeek Anthropic API (per-invocation; plain `claude`
# keeps the Claude subscription login). Requires user env var DEEPSEEK_API_KEY.
function claude-ds {
    if (-not $env:DEEPSEEK_API_KEY) {
        # Shells spawned by a long-running parent (e.g. the Desktop terminal pane)
        # inherit a stale environment snapshot; fall back to the User-scope value.
        $env:DEEPSEEK_API_KEY = [Environment]::GetEnvironmentVariable('DEEPSEEK_API_KEY', 'User')
    }
    if (-not $env:DEEPSEEK_API_KEY) {
        Write-Error "DEEPSEEK_API_KEY is not set. Set it once with: [Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY','sk-...','User') and open a new shell."
        return
    }
    $env:ANTHROPIC_BASE_URL = "https://api.deepseek.com/anthropic"
    $env:ANTHROPIC_AUTH_TOKEN = $env:DEEPSEEK_API_KEY
    $env:ANTHROPIC_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = "deepseek-v4-pro"
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = "deepseek-v4-flash"
    $env:CLAUDE_CODE_SUBAGENT_MODEL = "deepseek-v4-flash"
    try { claude @args }
    finally {
        Remove-Item Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_MODEL,
            Env:ANTHROPIC_DEFAULT_OPUS_MODEL, Env:ANTHROPIC_DEFAULT_SONNET_MODEL,
            Env:ANTHROPIC_DEFAULT_HAIKU_MODEL, Env:CLAUDE_CODE_SUBAGENT_MODEL,
            -ErrorAction SilentlyContinue
    }
}


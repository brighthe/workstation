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

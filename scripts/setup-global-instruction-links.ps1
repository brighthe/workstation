[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$UserProfilePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NormalizedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
}

function Get-LinkTargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemInfo]$Link
    )

    $rawTarget = [string]($Link.Target | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($rawTarget)) {
        throw "无法读取符号链接目标：$($Link.FullName)"
    }

    if ([System.IO.Path]::IsPathRooted($rawTarget)) {
        return Get-NormalizedPath -Path $rawTarget
    }

    return Get-NormalizedPath -Path (Join-Path $Link.DirectoryName $rawTarget)
}

$createdLinks = New-Object System.Collections.Generic.List[string]

try {
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
    }
    if ([string]::IsNullOrWhiteSpace($UserProfilePath)) {
        $UserProfilePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    }

    $RepoRoot = Get-NormalizedPath -Path $RepoRoot
    $UserProfilePath = Get-NormalizedPath -Path $UserProfilePath

    if (-not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
        throw "仓库根目录不存在：$RepoRoot"
    }
    if (-not (Test-Path -LiteralPath $UserProfilePath -PathType Container)) {
        throw "用户目录不存在：$UserProfilePath"
    }

    $linkDefinitions = @(
        [pscustomobject]@{
            Name = 'Codex'
            Source = Join-Path $RepoRoot 'codex\AGENTS.md'
            Target = Join-Path $UserProfilePath '.codex\AGENTS.md'
        },
        [pscustomobject]@{
            Name = 'Claude Code'
            Source = Join-Path $RepoRoot 'claude\CLAUDE.md'
            Target = Join-Path $UserProfilePath '.claude\CLAUDE.md'
        }
    )

    $operations = New-Object System.Collections.Generic.List[object]
    $conflicts = New-Object System.Collections.Generic.List[string]

    # Complete every validation before creating directories or links.
    foreach ($definition in $linkDefinitions) {
        $definition.Source = Get-NormalizedPath -Path $definition.Source
        $definition.Target = Get-NormalizedPath -Path $definition.Target

        if (-not (Test-Path -LiteralPath $definition.Source -PathType Leaf)) {
            throw "$($definition.Name) 指令源文件不存在：$($definition.Source)"
        }

        $existingItem = Get-Item -LiteralPath $definition.Target -Force -ErrorAction SilentlyContinue
        if ($null -eq $existingItem) {
            $operations.Add([pscustomobject]@{ Definition = $definition; Action = 'Create' })
            continue
        }

        if ($existingItem.LinkType -ne 'SymbolicLink') {
            $conflicts.Add("$($definition.Name)：目标已存在且不是 SymbolicLink：$($definition.Target)")
            continue
        }

        $actualTarget = Get-LinkTargetPath -Link $existingItem
        if ($actualTarget -ine $definition.Source) {
            $conflicts.Add("$($definition.Name)：目标链接指向 $actualTarget，而不是 $($definition.Source)")
            continue
        }

        $operations.Add([pscustomobject]@{ Definition = $definition; Action = 'Keep' })
    }

    if ($conflicts.Count -gt 0) {
        throw ("发现已有文件或错误链接；未做任何修改。请先检查并手动备份：`n- " + ($conflicts -join "`n- "))
    }

    foreach ($operation in $operations) {
        $definition = $operation.Definition
        if ($operation.Action -eq 'Keep') {
            Write-Host "$($definition.Name)：链接已正确，无需修改。"
            continue
        }

        $targetDirectory = Split-Path -Parent $definition.Target
        if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $targetDirectory -Force
        }

        $null = New-Item -ItemType SymbolicLink -Path $definition.Target -Target $definition.Source
        $createdLinks.Add($definition.Target)
        Write-Host "$($definition.Name)：已创建 $($definition.Target) -> $($definition.Source)"
    }

    foreach ($definition in $linkDefinitions) {
        $link = Get-Item -LiteralPath $definition.Target -Force -ErrorAction Stop
        if ($link.LinkType -ne 'SymbolicLink') {
            throw "$($definition.Name) 验证失败：目标不是 SymbolicLink。"
        }

        $actualTarget = Get-LinkTargetPath -Link $link
        if ($actualTarget -ine $definition.Source) {
            throw "$($definition.Name) 验证失败：实际目标为 $actualTarget。"
        }
    }

    Write-Host '全局指令链接验证通过。'
    exit 0
}
catch {
    for ($index = $createdLinks.Count - 1; $index -ge 0; $index--) {
        $createdPath = $createdLinks[$index]
        $createdItem = Get-Item -LiteralPath $createdPath -Force -ErrorAction SilentlyContinue
        if ($null -ne $createdItem -and $createdItem.LinkType -eq 'SymbolicLink') {
            Remove-Item -LiteralPath $createdPath -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Error ("初始化失败：{0}`n如果创建 SymbolicLink 被拒绝，请启用 Windows Developer Mode 或使用管理员 PowerShell。" -f $_.Exception.Message)
    exit 1
}

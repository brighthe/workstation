# >>> Claude DeepSeek & Native launcher >>>
# 本文件为 WSL 侧 claude/claude-ds 启动函数的唯一维护源头（仓库内）。
# WSL 中通过符号链接绑定：ln -s /mnt/c/workspace/workstation/agent-rules/Claude/claude_ds_func.sh ~/.claude_ds_func
# API key 不硬编码：运行时从 Windows 用户环境变量 DEEPSEEK_API_KEY 读取（与 PowerShell 侧一致）。
function claude() {
    # Ensure regular claude never inherits DeepSeek env vars, always using Claude Pro OAuth Subscription
    unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
          ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
          ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL \
          CLAUDE_CODE_EFFORT_LEVEL

    local BIN_PATH="/home/brighthe/.vscode-server/extensions/anthropic.claude-code-2.1.222-linux-x64/resources/native-binary/claude"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" "$@"
    else
        command claude "$@"
    fi
}

function claude-ds() {
    # 读取 DEEPSEEK_API_KEY：优先已导出的环境变量，其次 Windows 用户环境变量
    if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
        DEEPSEEK_API_KEY="$(powershell.exe -NoProfile -Command '[Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY","User")' 2>/dev/null | tr -d '\r')"
    fi
    if [ -z "${DEEPSEEK_API_KEY:-}" ]; then
        echo "DEEPSEEK_API_KEY 未设置。请先在 Windows 用户环境变量中配置。" >&2
        return 1
    fi
    export DEEPSEEK_API_KEY
    export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
    export ANTHROPIC_API_KEY="$DEEPSEEK_API_KEY"
    export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
    export ANTHROPIC_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro"
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
    export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"

    local BIN_PATH="/home/brighthe/.vscode-server/extensions/anthropic.claude-code-2.1.222-linux-x64/resources/native-binary/claude"
    if [ -x "$BIN_PATH" ]; then
        "$BIN_PATH" "$@"
    else
        command claude "$@"
    fi

    unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL \
          ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL \
          ANTHROPIC_DEFAULT_HAIKU_MODEL CLAUDE_CODE_SUBAGENT_MODEL
}
# <<< Claude DeepSeek & Native launcher <<<

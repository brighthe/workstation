#!/usr/bin/env bash
# WSL 侧 deepseek-acp 环境准备脚本
# 用法：bash /mnt/c/workspace/workstation/scripts/setup-deepseek-acp-wsl.sh
# 步骤：装 Node 24 → 验证 → 全局装 deepseek-acp → 提示运行 --setup

set -euo pipefail

echo "===== [1/4] 安装 Node.js 24 (NodeSource 官方源) ====="
if command -v node >/dev/null 2>&1 && [ "$(node -v 2>/dev/null | cut -c2- | cut -d. -f1)" -ge 24 ]; then
  echo "Node 已存在: $(node -v)，跳过安装"
else
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "===== [2/4] 验证 Node/npm ====="
node -v
npm -v

echo "===== [3/4] 全局安装 deepseek-acp ====="
npm install -g deepseek-acp

echo "===== [4/4] 验证 deepseek-acp ====="
command -v deepseek-acp
deepseek-acp --version

echo ""
echo "======================================================"
echo "环境就绪！最后一步：配置 API Key（需要你手动粘贴）"
echo "在 WSL 终端运行："
echo ""
echo "    deepseek-acp --setup"
echo ""
echo "在 DEEPSEEK_API_KEY: 提示后粘贴你的 Key 并回车。"
echo "======================================================"

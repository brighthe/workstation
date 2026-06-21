#!/usr/bin/env bash
#
# Claude Code chat-history incremental sync -- WSL2 / Linux / Git Bash
#
# Goal: Local mode (real-time local files) + iCloud Drive (cross-device history).
# Syncs ~/.claude/projects/ plus history.jsonl / settings.json / CLAUDE.md to an
# iCloud Drive local folder, which iCloud replicates across devices.
#
# Usage:
#   Push to iCloud:       ./claude-code-sync.sh          (default: sync)
#   Restore from iCloud:  ./claude-code-sync.sh pull
#
# Cloud dir resolution order:
#   1) env var CLAUDE_CLOUD_DIR
#   2) auto-detect Users/*/iCloudDrive under /mnt/c (WSL2) or /c (Git Bash)
#   3) fallback default (edit below)
#
# Behavior: incremental, add-only (no deletes), newer file wins (rsync --update).
#   projects/ merges as a union; history.jsonl/settings.json/CLAUDE.md are whole-file
#   copies and are backed up to *.bak on pull before being overwritten.
#
set -euo pipefail

MODE="${1:-sync}"
CLAUDE_DIR="${HOME}/.claude"
EXTRA_FILES=(history.jsonl settings.json CLAUDE.md)

detect_cloud_dir() {
  if [ -n "${CLAUDE_CLOUD_DIR:-}" ]; then echo "$CLAUDE_CLOUD_DIR"; return; fi
  local base d
  for base in /mnt/c /c; do
    if [ -d "$base/Users" ]; then
      for d in "$base"/Users/*/iCloudDrive; do
        [ -d "$d" ] && { echo "$d/ClaudeCodeSync"; return; }
      done
    fi
  done
  echo "/mnt/c/Users/$USER/iCloudDrive/ClaudeCodeSync"
}

CLOUD_DIR="$(detect_cloud_dir)"

copy_extra() { # args: from to backup(0|1)
  local from="$1" to="$2" backup="$3" f
  for f in "${EXTRA_FILES[@]}"; do
    if [ -f "${from}/${f}" ]; then
      [ "$backup" = "1" ] && [ -f "${to}/${f}" ] && cp -f "${to}/${f}" "${to}/${f}.bak"
      cp -f "${from}/${f}" "${to}/${f}"
    fi
  done
}

sync_push() {
  [ -d "${CLAUDE_DIR}/projects" ] || { echo "Not found: ${CLAUDE_DIR}/projects (Claude Code never used here?)"; exit 1; }
  mkdir -p "${CLOUD_DIR}/projects"
  rsync -a --update "${CLAUDE_DIR}/projects/" "${CLOUD_DIR}/projects/"
  copy_extra "$CLAUDE_DIR" "$CLOUD_DIR" 0
  echo "Synced to ${CLOUD_DIR}"
  echo "Confirm the iCloud icon shows 'downloaded' before switching devices."
}

sync_pull() {
  [ -d "${CLOUD_DIR}/projects" ] || { echo "Not found in iCloud: ${CLOUD_DIR}/projects (downloaded locally?)"; exit 1; }
  mkdir -p "${CLAUDE_DIR}/projects"
  rsync -a --update "${CLOUD_DIR}/projects/" "${CLAUDE_DIR}/projects/"
  copy_extra "$CLOUD_DIR" "$CLAUDE_DIR" 1
  echo "Restored from ${CLOUD_DIR} to ${CLAUDE_DIR}"
  echo "Tip: /resume lists these sessions only when project absolute paths match the original machine."
}

case "$MODE" in
  sync|push)    sync_push ;;
  pull|restore) sync_pull ;;
  *) echo "Usage: $0 [sync|pull]"; exit 1 ;;
esac

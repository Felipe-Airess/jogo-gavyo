#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
if [[ ! -f godot-poc/web/index.html ]]; then
  bash godot-poc/tools/build_web.sh
fi
# Reopening the Codespace must not spawn a second server.
if ! curl -fsS http://127.0.0.1:8060/ >/dev/null 2>&1; then
  mkdir -p godot-poc/.godot
  nohup python3 godot-poc/tools/serve.py >godot-poc/.godot/preview.log 2>&1 &
fi

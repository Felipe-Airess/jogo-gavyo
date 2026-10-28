#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
if [[ ! -f godot-poc/web/index.html ]]; then
  bash godot-poc/tools/build_web.sh
fi
# Reopening the Codespace must not spawn a second server.
if ! curl --max-time 2 -fsS http://127.0.0.1:8060/ >/dev/null 2>&1; then
  mkdir -p godot-poc/.godot
  nohup setsid python3 godot-poc/tools/serve.py </dev/null >godot-poc/.godot/preview.log 2>&1 &
fi
for attempt in {1..10}; do
  if curl --max-time 2 -fsS http://127.0.0.1:8060/ >/dev/null 2>&1; then
    echo 'GAVYO preview ready on port 8060'
    exit 0
  fi
  sleep 1
done
echo 'GAVYO preview did not start; inspect godot-poc/.godot/preview.log' >&2
exit 1

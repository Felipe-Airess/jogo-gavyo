#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-${HOME}/.local/bin/godot}"
python3 tools/prepare_assets.py
python3 tools/prepare_full_assets.py
"$GODOT" --headless --path . --editor --import --quit
"$GODOT" --headless --path . --script tests/combat_test.gd
"$GODOT" --headless --path . --script tests/native_parity_test.gd
"$GODOT" --headless --path . --script tests/duel_trace_test.gd
"$GODOT" --headless --path . --script tests/game_smoke.gd
mkdir -p web
"$GODOT" --headless --path . --export-release Web web/index.html
test -s web/index.html
test -s web/index.wasm
test -s web/index.pck

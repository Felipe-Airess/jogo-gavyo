#!/bin/bash
# Percurso contínuo do capítulo 1 com física real, sem teletransportes.
# Modo "rota" (padrão) reprova se não chegar ao fim; "--real" só registra.
set -euo pipefail
cd "$(dirname "$0")/.."
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
"$gavyo_godot" --headless --fixed-fps 60 --path godot-3d --script res://tests/capitulo1_percurso_test.gd -- "$@" 2>&1 | grep -v "^\s*at:" | grep -E "PASS|FAIL|PERCURSO|SCRIPT ERROR"
exit "${PIPESTATUS[0]}"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$gavyo_godot" ]]; then
  gavyo_godot="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$gavyo_godot" ]]; then
  echo "Defina GODOT com o caminho do Godot 4.5.1."
  exit 1
fi
python3 - "$gavyo_godot" "$PWD/godot-3d" <<'PY'
import subprocess, sys, re
try:
    result = subprocess.run([sys.argv[1], '--headless', '--text-driver', 'Dummy',
        '--path', sys.argv[2], '--script', 'res://tests/prototipo_test.gd'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=65)
except subprocess.TimeoutExpired:
    print('Tempo limite dos testes excedido.'); sys.exit(2)
print(result.stdout)
if result.returncode or 'SCRIPT ERROR:' in result.stdout or not re.search(r'PROTOTIPO_TEST: [1-9][0-9]* passed, 0 failed', result.stdout):
    sys.exit(result.returncode or 1)
PY

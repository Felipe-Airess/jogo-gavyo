#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
python3 - "$gavyo_godot" "$PWD/godot-3d" <<'PY'
import subprocess,sys,re
try:
    result=subprocess.run([sys.argv[1],'--headless','--text-driver','Dummy','--path',sys.argv[2],'--script','res://tests/capitulo1_test.gd'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=90)
except subprocess.TimeoutExpired:
    print('Tempo limite excedido nos testes do capítulo 1.');sys.exit(2)
print(result.stdout)
if result.returncode or 'ERROR:' in result.stdout or not re.search(r'CAPITULO1_TEST: [1-9][0-9]* passed, 0 failed',result.stdout):
    sys.exit(result.returncode or 1)
PY

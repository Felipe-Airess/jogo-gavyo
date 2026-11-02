#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
# Capítulo integrado + mapa em grade (texto/kit/física) + level design.
python3 - "$gavyo_godot" "$PWD/godot-3d" <<'PY'
import subprocess,sys,re
suites=[('capitulo1_test','CAPITULO1_TEST'),('capitulo1_mapa_test','CAPITULO1_MAPA'),('capitulo1_nivel_test','CAPITULO1_NIVEL')]
falhou=0
for teste,marca in suites:
    try:
        result=subprocess.run([sys.argv[1],'--headless','--text-driver','Dummy','--path',sys.argv[2],'--script','res://tests/%s.gd'%teste],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
    except subprocess.TimeoutExpired:
        print('Tempo limite excedido em %s.'%teste);sys.exit(2)
    print(result.stdout)
    if result.returncode or 'ERROR:' in result.stdout or not re.search(marca+r': [1-9][0-9]* passed, 0 failed',result.stdout):
        falhou=result.returncode or 1
sys.exit(falhou)
PY

#!/bin/bash
# Exporta o capítulo 1 para web (PC e celular) em godot-3d/web/.
# Requer Godot 4.5.1 e os templates web_nothreads em
# ~/.local/share/godot/export_templates/4.5.1.stable/ (Linux) ou equivalente no Mac.
set -euo pipefail
cd "$(dirname "$0")/../godot-3d"
gavyo_godot="${GODOT:-$PWD/../work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
"$gavyo_godot" --headless --path . --import >/dev/null 2>&1 || true
rm -rf web && mkdir -p web
"$gavyo_godot" --headless --path . --export-release Web web/index.html
ls -la web
echo "Teste local: cd godot-3d/web && python3 -m http.server 8000  (abrir http://<ip-do-pc>:8000 no celular, mesma rede)"

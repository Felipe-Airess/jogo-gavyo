#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$gavyo_godot" ]]; then
  printf 'Godot não encontrado. Defina GODOT com o caminho do executável.\n'
  exit 1
fi
mkdir -p work
printf 'Gavião — teste de escala, câmera e prévia de animações.\n'
gavyo_bundle="${gavyo_godot%/Contents/MacOS/Godot}"
if [[ "$(uname)" == Darwin && -d "$gavyo_bundle" && "$gavyo_bundle" != "$gavyo_godot" ]]; then
  /usr/bin/open -n -W -a "$gavyo_bundle" --args --path "$PWD/godot-3d" --rendering-method gl_compatibility --log-file "$PWD/work/validacao-inicial.log" res://validacao/inicio.tscn
else
  "$gavyo_godot" --path "$PWD/godot-3d" --rendering-method gl_compatibility --log-file "$PWD/work/validacao-inicial.log" res://validacao/inicio.tscn
fi
if /usr/bin/grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load' work/validacao-inicial.log; then
  tail -30 work/validacao-inicial.log
  exit 1
fi

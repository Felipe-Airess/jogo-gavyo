#!/usr/bin/env bash
# Exporta o teste 3D para web/ (precisa do Godot 4.5.1 e dos templates web).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
cp ../arte/miguel_animado.glb ../arte/miguel_animacoes.json .
"$GODOT" --headless --path . --import
mkdir -p web
"$GODOT" --headless --path . --export-release Web web/index.html
ls -la web

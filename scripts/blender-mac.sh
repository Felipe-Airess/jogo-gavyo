#!/usr/bin/env bash
# Blender portátil preparado em work/, sem instalar em /Applications.
set -euo pipefail
cd "$(dirname "$0")/.."
mount_dir=/private/tmp/gavyo-blender-3.6
blender="$mount_dir/Blender.app/Contents/MacOS/Blender"
if [[ ! -x "$blender" ]]; then
  hdiutil attach -readonly -nobrowse -mountpoint "$mount_dir" \
    work/ferramentas/blender-3.6.23-macos-x64.dmg
fi
export PYTHONPATH="$PWD/work/venv-modelo/lib/python3.10/site-packages${PYTHONPATH:+:$PYTHONPATH}"
export FACE_LANDMARKER="$PWD/work/ferramentas/face_landmarker.task"
export FACE_LANDMARKER_URL="${FACE_LANDMARKER_URL:-http://127.0.0.1:8767/landmarks}"
exec "$blender" -b -t 2 --python-use-system-env --python-exit-code 1 "$@"

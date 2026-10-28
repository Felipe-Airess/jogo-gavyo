#!/usr/bin/env bash
set -euo pipefail
VERSION=4.5.1
DEST="${HOME}/.local/bin"
TEMPLATES="${HOME}/.local/share/godot/export_templates/${VERSION}.stable"
CACHE="${HOME}/.cache/gavyo-godot/${VERSION}"
mkdir -p "$DEST" "$TEMPLATES" "$CACHE"
BASE="https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable"
if [[ ! -x "$DEST/godot" ]]; then
  curl --fail --location --retry 3 "$BASE/Godot_v${VERSION}-stable_linux.x86_64.zip" -o "$CACHE/editor.zip"
  unzip -o -q "$CACHE/editor.zip" -d "$CACHE/editor"
  install -m 755 "$CACHE/editor/Godot_v${VERSION}-stable_linux.x86_64" "$DEST/godot"
fi
"$DEST/godot" --version | grep -q '^4\.5\.1\.stable'
if [[ ! -f "$TEMPLATES/web_nothreads_release.zip" ]]; then
  curl --fail --location --retry 3 "$BASE/Godot_v${VERSION}-stable_export_templates.tpz" -o "$CACHE/templates.tpz"
  unzip -o -q "$CACHE/templates.tpz" 'templates/web*' -d "$CACHE"
  cp "$CACHE"/templates/web* "$TEMPLATES/"
fi

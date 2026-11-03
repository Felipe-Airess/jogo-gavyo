#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
engine="$PWD/../../work/ferramentas/godot/Godot.app"
/usr/bin/open -n -a "$engine" --args --main-pack "$PWD/gaviao.pck" --rendering-method gl_compatibility --log-file "$PWD/jogo.log"

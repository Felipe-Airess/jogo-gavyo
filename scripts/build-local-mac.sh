#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
mkdir -p builds/macos-teste
"$gavyo_godot" --headless --text-driver Dummy --path godot-3d --import > work/build-import.log 2>&1
if rg -q 'ERROR:' work/build-import.log; then cat work/build-import.log; exit 1; fi
"$gavyo_godot" --headless --text-driver Dummy --path godot-3d --export-pack Web "$PWD/builds/macos-teste/gaviao.pck" > work/build-local.log 2>&1
if rg -q 'ERROR:' work/build-local.log; then cat work/build-local.log; exit 1; fi
cat > builds/macos-teste/JOGAR.command <<'LAUNCH'
#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
engine="$PWD/../../work/ferramentas/godot/Godot.app"
/usr/bin/open -n -a "$engine" --args --main-pack "$PWD/gaviao.pck" --rendering-method gl_compatibility --log-file "$PWD/jogo.log"
LAUNCH
chmod +x builds/macos-teste/JOGAR.command
printf 'Build pronta: %s/builds/macos-teste/JOGAR.command\n' "$PWD"

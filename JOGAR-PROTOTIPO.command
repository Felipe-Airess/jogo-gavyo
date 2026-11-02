#!/bin/bash
# Executar pelo Finder/Terminal do Mac. Mantém falhas visíveis e registra o diagnóstico.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
mkdir -p work
launch_log="$PWD/work/prototipo-abertura.log"
game_log="$PWD/work/prototipo-jogo.log"
: > "$launch_log"
printf 'GAVIÃO — abrindo o protótipo…\n\n'

fail() {
  printf '\nNão foi possível abrir o jogo.\n\n'
  if [[ -s "$launch_log" ]]; then
    tail -40 "$launch_log"
  fi
  if [[ -s "$game_log" ]]; then
    tail -40 "$game_log"
  fi
  printf '\nDiagnóstico salvo em:\n%s\n%s\n' "$launch_log" "$game_log"
  if [[ -t 0 ]]; then
    read -r -p 'Pressione Enter para fechar esta janela.'
  fi
  exit 1
}

gavyo_godot="${GODOT:-$PWD/work/ferramentas/godot/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$gavyo_godot" ]]; then
  gavyo_godot="$(command -v godot || command -v godot4 || true)"
fi
if [[ -z "$gavyo_godot" || ! -x "$gavyo_godot" ]]; then
  printf 'Godot 4.5.1 não encontrado.\n' >> "$launch_log"
  fail
fi
printf 'Executável: %s\nProjeto: %s\n' "$gavyo_godot" "$PWD/godot-3d" >> "$launch_log"
if ! "$gavyo_godot" --headless --version >> "$launch_log" 2>&1; then
  fail
fi

if [[ ! -f "$PWD/godot-3d/.godot/imported/miguel_animado.glb-617a1a66fc6524f3556fc197ceecc619.scn" ]] || ! compgen -G "$PWD/godot-3d/.godot/imported/felipe.glb-*.scn" >/dev/null; then
  printf 'Preparando os recursos na primeira abertura…\n'
  if ! "$gavyo_godot" --headless --path "$PWD/godot-3d" --import >> "$launch_log" 2>&1; then
    fail
  fi
fi

: > "$game_log"
launch_started=$SECONDS
gavyo_bundle="${gavyo_godot%/Contents/MacOS/Godot}"
if [[ "$gavyo_bundle" != "$gavyo_godot" && -d "$gavyo_bundle" && "$(uname)" == Darwin ]]; then
  # LaunchServices registra a aplicação antes de inicializar sua janela gráfica.
  if ! /usr/bin/open -n -W -a "$gavyo_bundle" --args --path "$PWD/godot-3d" --log-file "$game_log" --rendering-method gl_compatibility res://capitulo1/main.tscn "$@" >> "$launch_log" 2>&1; then
    fail
  fi
else
  if ! "$gavyo_godot" --path "$PWD/godot-3d" --log-file "$game_log" --rendering-method gl_compatibility res://capitulo1/main.tscn "$@" >> "$launch_log" 2>&1; then
    fail
  fi
fi

if [[ $((SECONDS-launch_started)) -lt 4 ]] || /usr/bin/grep -q 'SCRIPT ERROR:\|Failed to load\|Parse Error:' "$game_log"; then
  printf '\nO aplicativo encerrou antes de concluir a abertura, ou registrou um erro.\n' >> "$launch_log"
  fail
fi
printf '\nJogo encerrado.\n'

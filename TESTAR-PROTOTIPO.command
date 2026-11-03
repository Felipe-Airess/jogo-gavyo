#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
printf 'Teste visual: apenas o jogo será capturado.\nFeche a outra janela do protótipo antes de continuar.\n'
exec bash ./JOGAR-PROTOTIPO.command -- --qa-inspect

# Retomada local — Bola

macOS 11.7.11 Intel; Blender portátil 3.6.23 (sem instalar outra engine);
Python 3.10 em work/venv-modelo, Node 22.23.4, Chrome local.
NumPy 1.23.5, SciPy 1.10.1, scikit-image 0.21.0, Pillow 10.4.0,
OpenCV 4.5.5.64. Pacote nativo MediaPipe 0.10.9 instalado, mas incompatível
com o libc++ deste macOS; usar o backend HTTP local previsto pelo pipeline.
Logs de falha antiga e instalação retomada preservados separadamente.

## Reproduzir no Mac já preparado

Na raiz do repositório, em um terminal:

```bash
node arte/bola_mediapipe_local.mjs
```

Usa a própria instância headless do Chrome em work/bola-chrome, CPU; arquivos
locais face_landmarker.task e MediaPipe Web em work/ferramentas/. As portas
8767/8768 são locais. Não abrir uma segunda instância enquanto a primeira usa
as portas. O servidor pode ser encerrado após os scripts de rosto/comparação.

Em outro terminal:

```bash
work/venv-modelo/bin/python arte/bola_triagem.py
# ATENÇÃO: as chamadas abaixo refazem o ajuste acumulando no alvo.
# Para só medir e preservar o alvo atual:
bash scripts/blender-mac.sh --python arte/bola_rosto.py -- --checar arte/revisoes/bola/rosto-conferido
bash scripts/blender-mac.sh --python arte/bola_humano.py -- --render arte/revisoes/bola/modelo-final --blend arte/bola_boneco.blend --glb arte/bola_boneco.glb --fbx arte/bola_boneco.fbx
bash scripts/blender-mac.sh arte/bola_boneco.blend --python arte/bola_qa.py
bash scripts/blender-mac.sh arte/bola_boneco.blend --python arte/bola_revisao_visual.py
work/venv-modelo/bin/python arte/bola_comparar.py arte/revisoes/bola/modelo-final arte/revisoes/bola/comparacoes
bash scripts/blender-mac.sh --python arte/bola_previa_rig.py
bash scripts/blender-mac.sh arte/revisoes/bola/rig-final/rig.blend --python arte/bola_exportar_previa.py
bash scripts/blender-mac.sh --python arte/bola_revisar_animacoes_exportadas.py
bash scripts/blender-mac.sh --python arte/bola_verificar_exportacao.py -- arte/bola_boneco.glb arte/revisoes/bola/exportacao/glb.json
bash scripts/blender-mac.sh --python arte/bola_verificar_exportacao.py -- arte/bola_boneco.fbx arte/revisoes/bola/exportacao/fbx.json
```

O QA e a checagem de estrutura/pesos retornam sucesso técnico. A medição do
rosto ainda falha na meta frontal; a revisão visual não está aprovada. Consulte
RESULTADO.md antes de tratar as exportações como finais.

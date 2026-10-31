# Contexto para a próxima conversa: modelo 3D do Felipe ("Bungas")

Leia isto inteiro antes de começar. Repositório `Felipe-Airess/jogo-gavyo`,
**branch `boneco-miguel`** (tudo abaixo está nela). Depois leia
`docs/VISAO-DO-JOGO.md` (decisões do projeto) e, só se precisar de detalhe,
`AGENTS.md` (histórico da fase 2D/Phaser/Godot).

## Quem é o usuário e como trabalhar com ele
- Felipe, autor do jogo **GAVIÃO** (luta + exploração com os amigos do grupo "Gavião").
- Fala português informal; responda em português, direto, sem enrolação.
- Não tem experiência com 3D e trabalha **só pela nuvem** (Claude Code web); máquina dele:
  MacBook Pro meados de 2014. Ele aprova olhando imagens: **sempre mostre comparação
  lado a lado com as fotos** antes de dizer que ficou bom.
- Ele odeia quando algo é anunciado como pronto e está bugado. Confira antes (renders,
  medições) e diga o que ainda está errado.
- Commits em português, pequenos; sempre `git push` na branch.

## Decisões já tomadas (não reabrir)
- Jogo vira **3D "disfarçado" (2.5D)**: bonecos e cenário 3D no Godot 4.5, câmera fixa de
  lado, movimento num plano, render em baixa resolução (320×180/426×240) sem suavização
  = cara de pixel art (Dead Cells / Fears to Fathom).
- **Teste de desempenho no Mac dele** (`godot-3d/bench`): 11 Miguels HD, sombra, 640×360 →
  ~30 FPS estáveis com muita coisa aberta. 3D é viável; modelos de ~25–30 mil faces ok.
- **Todos os personagens no mesmo esqueleto (compatível com Mixamo)**: animações do
  Mixamo servem para qualquer um. Hitbox presa nos ossos, contato marcado na animação.
- Fases desenhadas como mapa de texto → script gera o 3D (ele não mexe em 3D).
- Estrutura: passar fases e desbloquear um amigo por fase. História em aberto.

## Tarefa desta conversa: modelar o Felipe
### Referências (em `arte/referencias/felipe/`)
- `LEIA-ME.txt`: **1,72 m, 72 kg, luta descalço**, camiseta preta Death
  (*Scream Bloody Gore*), short preto.
- `angulos_principais/`: 12 quadros 1080×1920 do vídeo girando, fundo liso, corpo
  inteiro: `frente_neutra`, `frente_corpo`, `frente_queixo_elevado`, `perfil_virado_direita`,
  `perfil_virado_esquerda`, `tres_quartos_virado_*`, `costas`, `costas_tres_quartos_*`,
  `guarda_lateral`, `transicao_guarda`. Os nomes dizem para onde ele está virado na
  imagem, não o lado anatômico.
- `fotos_originais/`: 18 fotos 1152×1536: rosto de frente, 3/4, perfis, de cima, de baixo,
  cabelo de cima e de trás, camiseta (frente e costas) e short esticados no chão.
- `indice_video_*.jpg`, `tempos_dos_quadros.csv`: índice do vídeo (os 212 quadros
  originais não foram subidos; vieram no zip do usuário).

### Características a acertar
- Físico: estatura média, **mais largo e mais forte** que o Miguel (Miguel: 1,76 m, magro).
- **Cabelo preto cacheado muito volumoso** (cachos fechados, mais alto e cheio que o do
  Miguel; cai na testa), sobrancelha grossa, cavanhaque ralo no queixo, nariz com ponte
  marcada de perfil, pele morena clara, orelhas cobertas em parte pelo cabelo.
- Camiseta preta folgada (manga até o meio do braço): logo "DEATH" vermelho na frente e
  nas costas, arte da capa (roxo/azul/vermelho) e "SCREAM BLOODY GORE" na frente. Short
  preto folgado até o joelho. **Descalço** (pés com dedos, não tênis). Pulseira fina no pulso.
- Obs. de licença: a estampa é de banda real; para testes, fiel; para jogo publicado,
  sugerir estampa inspirada.

### Como fazer (pipeline que já existe — reaproveitar)
- `arte/miguel_humano.py`: gera humano a partir **só de dados** do MakeHuman (CC0) em
  `arte/makehuman/` (malha base `base.obj`, alvos `targets/*`, rig `rig/*game_engine*`).
  Tem: `MACRO` (idade/peso/músculo/etnia), `FORMA` (alvos de rosto/corpo), pintura do
  rosto por vértice, roupas como peças separadas cortadas por plano (`fazer_camisa`,
  `fazer_calca`, `fazer_tenis`), cabelo por voxel com cachos esculpidos (`criar_cabelo`),
  punhos fechados, rig de 22 ossos com nomes humanoides (Hips, Spine, Chest, UpperChest,
  Neck, Head, Left/Right Shoulder/UpperArm/LowerArm/Hand/UpperLeg/LowerLeg/Foot/Toes).
  O rosto do Miguel ficou **genérico**: o ajuste por controles do MakeHuman no olho tem
  limite. Para o Felipe, fazer o próximo nível: **encaixar a malha nas fotos de frente e
  perfil por pontos** (olhos, nariz, boca, queixo, orelha, contorno), deformando a cabeça.
- Criar `arte/felipe_humano.py` (copiar/generalizar o do Miguel; ideal: parâmetros por
  personagem). Roupa nova: camiseta folgada com estampa (textura/cor por vértice) e short;
  **pés descalços** (não gerar tênis; pele nos pés).
- Ferramentas no container: Blender via módulo Python `bpy` (instalar num venv:
  `python3 -m venv venv && venv/bin/pip install bpy pillow`; precisa
  `apt-get install -y libegl1 libgl1-mesa-dri`). Renderizar com Workbench, cor por vértice.
  Download do blender.org é bloqueado; GitHub clone funciona.
- Script de inspeção útil: render de frente/lado/costas/rosto/3/4 e montar com a foto
  correspondente ao lado (ver `arte/renders/miguel_rosto_comparacao.png`).
- Saídas esperadas: `arte/renders/felipe_*` (comparações), `.glb` com rig para subir no
  Mixamo, e o modelo pronto para as animações.

### Erros que já cometemos (não repetir)
- Olho todo escuro ("possuído"): pintar esclera + íris + pupila pelo ângulo no globo.
- Bumbum/quadril enormes do MakeHuman: reduzir `buttocks-volume` e `measure-hips-circ`.
- Camisa como pintura na pele / barra entre as pernas: roupa como peça separada; da
  cintura para baixo virar tubo reto.
- Cabelo de bolinhas soltas: usar volume único (voxel) com relevo.
- Comandos `cp assets/x.*` não pegam `x-markers.json` (hífen). Conferir arquivos copiados.
- Não usar o bake por IK com polos fixos para animar (cotovelo/joelho invertido).
  Animações vêm do **Mixamo**.

## Depois do modelo (próximas etapas combinadas)
1. Felipe aprova o modelo → subir no Mixamo → baixar animações.
2. Protótipo 2.5D (projeto `godot-3d/`): andar, pular, abrir porta, subir em caixa;
   rival; golpes com hitbox nos ossos; emendas (janela de cancelamento só se tocou,
   buffer ~150 ms, golpe errado não emenda); pausa no impacto; **clinch** (prioridade
   de sensação: luta agressiva, pressão, parede).
3. Fase da casa do Felipe (ele manda planta e fotos).
4. Outros personagens no mesmo esqueleto: Miguel (já tem modelo HD), Sorriso, Bola,
   Alessandro, Gelado, Caio "Passa-Marcha", Natan.

## Onde está o resto
- Jogo 2D atual em Godot: `godot-poc/` (branch `feat/godot-combat-poc`; versão com
  sprites do Miguel 3D na `feat/miguel-sprites-3d`). Artifact de teste:
  https://claude.ai/artifact/FJqCc7zDULqUCrSrQVw849 (duelo) e
  https://claude.ai/artifact/3E92jPHykXEypoYN1j2tPu (teste de desempenho).
- Miguel: `arte/miguel_humano.py`, animações Mixamo em `arte/mixamo/` e
  `arte/miguel_mixamo.py` (transferência FBX→rig), estudo em `arte/MIXAMO-ESTUDO.md`.

## Estado em 31/10 (modelo pronto para animar)
- `arte/felipe_humano.py` gera o Felipe; `--glb arte/felipe_boneco.glb` (Godot) e
  `--fbx arte/felipe_boneco.fbx` (Mixamo). Rig de 22 ossos, mesmos nomes do Miguel.
- Rosto: `arte/felipe_rosto.py` (478 pontos do MediaPipe na foto e num render do
  modelo + contorno do perfil) grava `felipe_rosto.target.gz` e a pintura.
- Cabelo: `arte/felipe_cabelo.py`, `MIOLO = "fatias"` (o aprovado pelo Felipe);
  pele medida nas fotos (`PELE`). Precisa do modelo `face_landmarker.task` do
  MediaPipe (variavel `FACE_LANDMARKER`).
- Animacoes do Mixamo ja baixadas servem direto:
  `python arte/miguel_mixamo.py -- --fbx arte/mixamo --humano felipe_humano.py --previa DIR`.
  Teste em `arte/renders/felipe_rig_teste_mixamo.png`.
- Defeito conhecido: na joelhada alta o joelho atravessa a barra da camiseta.
- Descartado pelo Felipe: cilios em geometria e brincos (argolas pretas); cards de
  cachos (`--cards`, ficaram espetados).

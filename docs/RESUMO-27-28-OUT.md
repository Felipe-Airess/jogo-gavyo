# Resumo de 27–28/10/2026 — leia primeiro

Tudo o que foi feito e conversado nessas duas sessões com o usuário, incluindo
o que ficou combinado para o futuro. Os detalhes técnicos de cada parte estão
nos arquivos citados. Decisões de jogo futuras: `godot-poc/docs/DIRECAO-DO-JOGO.md`
(branch `feat/godot-combat-poc`).

## Estado em uma linha

O jogo existe em **duas versões**: Phaser (raiz, `main`, publicado em
https://felipe-airess.github.io/jogo-gavyo/) e **Godot 4.5.1** (pasta
`godot-poc/`, branch `feat/godot-combat-poc`, PR #8 em rascunho; exportação
publicada em https://felipe-airess.github.io/jogo-gavyo/godot/). O usuário
**trocou para o Godot**; o Phaser fica como referência e não deve mais crescer.
O usuário não usa mais o ThinkPad T400: não limitar o Godot a ele.

## O que foi feito (em ordem)

### Phaser (já na `main`)
- **PR #5 — Miguel lote 5:** prancha do ChatGPT (itens 9–20) + zip de 27/10
  recortados por `scripts/miguel-lote5/extrair.py` e postos no atlas por
  `scripts/add-miguel-lote5.py` (`m5_*`). Clinch completo do Miguel, arremesso
  e queda arremessada, soco no chão, pisada, apanhando no chão, guarda rompida,
  cansado, transições do andar. Chute alto `m5_kickHigh` sem comando (pé colado
  ao corpo). Ver seção "Miguel — lote 5" no `AGENTS.md`.
- **PR #6 — sensação do combate:** pé de apoio parado nos chutes do Miguel
  (`plantedOffsets`, chute circular 24→46 px), corpos param a 26 px para os dois,
  empurrão menor durante golpe, cotovelada só quando alcança, aparo 180 ms com
  efeito azul, sangue/impacto do duelo levado ao corredor,
  `scripts/auditar-combate.mjs` (alcance de cada golpe por distância).
- **PR #7 — sprites:** pés inteiros na corrida/arrancada (recorte com folga no
  lote 4) e lote 5 escalado pelo tamanho da cabeça.
- **PRs #9, #10, #11:** exportação Godot publicada em `godot/` na `main`
  (menu corrigido; pausa com botões tocáveis). Republicar: exportar
  `godot-poc` para `godot-poc/web/` e copiar `web/index.*` para `godot/`.

### Godot (branch `feat/godot-combat-poc`)
Outro agente (Codex) criou a POC e a base (`scripts/core/`: dano, golpes,
colisão, buffer, passo fixo, partida). Nesta sessão:
- **Motor do duelo e IA portados** para GDScript (`scripts/duel/`), idênticos ao
  Phaser: `tests/duel_trace_test.gd` reproduz 9 lutas gravadas no Phaser
  (6.231 ticks; IA, clinch, arremesso, chão, corrida, aparo) — estado e
  entradas da IA batem tick a tick. Gerador: `tools/generate_duel_traces.mjs`.
- **Corredor de treino portado** (`scripts/corridor/`): profundidade, manequins,
  carregar no golpe, clinch, ragdoll (em dicionários de 64 bits — `Vector2` é
  32 bits e divergiria), aparo, modos reação/guarda/sparring, Sorriso e Miguel.
  `tests/corridor_trace_test.gd`: 6 treinos, 14.400 quadros, batem.
- **Cena jogável** (`game.tscn` → `scripts/game/game.gd`): menu com MODO
  (duelo/corredor), VOCÊ, RIVAL, IA, ROUNDS, TEMPO, TREINO; HUD numa faixa
  própria; pausa/fim com botões tocáveis; sangue, faíscas, tremida, clarão,
  câmera lenta, som gerado no jogo; rival recolorido por shader; controle de
  videogame (A soco, B chute, X agarra, RB/RT defende, LB corre, Start pausa);
  multitoque nativo com botões que crescem com a tela; retrato com mundo mais
  perto; preferências em `user://gaviao.cfg`.
- **Testes:** `tests/game_smoke.gd` (4 duelos + 4 treinos sem erro),
  `tests/web_smoke.cjs` (CI: desktop, deitado, em pé, multitoque).
  `tools/build_web.sh` roda todos.
- Ferramentas locais (não versionadas): Godot 4.5.1 e templates em
  `work/godot-tools/`; os templates web foram instalados em
  `%APPDATA%/Godot/export_templates/4.5.1.stable/`.

### Problemas que o usuário relatou e estado
- Chutes do Miguel "não saíam do lugar" → corrigido (PR #6).
- Pés cortados e sprites maiores → corrigido (PR #7); o lote 5 ainda tem cabeça
  e tronco mais largos por proporção do desenho.
- Celular não voltava ao menu depois de entrar no jogo → corrigido (PR #11).
- **1×1 continua ruim para o usuário** (frente/trás e caixas) → reforma planejada
  (abaixo), não feita.

## O que ficou combinado para o futuro (nada implementado)

Detalhado em `godot-poc/docs/DIRECAO-DO-JOGO.md`. Resumo:
- **Arte:** a intenção é **rotoscopia bizarra** feita dos vídeos do próprio
  usuário (sem fundo, pouca resolução, poucas cores, contorno que "ferve",
  poucos quadros) e, em momentos aleatórios, virar **fluido**, quase vídeo, "nada
  a ver" (Smiling Friends). O pixel art do ChatGPT é **provisório**. Não é o rig
  de recorte que ele rejeitou.
- **História:** protagonistas **Sorriso, Felipe, Gelado, Bola, Alessandro, Miguel,
  Passa Marcha**. Vários cenários; a cada fase conversa com um e libera ele.
  Progressão libera golpes cada vez mais violentos. Conquistas. Modo infinito =
  briga de sobrevivência com nocaute (não "matança": elenco são pessoas reais).
- **Diálogos em vídeo** pixelado/sem fundo ao chegar perto do personagem; o soco
  **interrompe a fala** de quem não é protagonista (reação gravada à parte).
- **Barra de agressividade** (em vez de "ânimo"): mais rápido, menos recuo, mais
  dano, menos fôlego, animações próprias, libera finalização; contador de combo
  pela agressividade; 3 níveis com preço na defesa. Pendente: "finalizar os
  personagens que aparecerem" — qualquer personagem ou outra coisa?
- **Reforma do 1×1:** caixas feitas à mão no editor do Godot, faixas de alcance
  definidas, passo/recuo rápido com dois toques, corpo fixo, trás não escolhe
  golpe. **Pendente:** trás defende (L vira aparo) ou L continua defendendo.
- **Áudio** feito pelo usuário (guitarra, beats, falas): temas OGG em faixas
  separadas que entram com a agressividade, vinhetas curtas.
- **Rodadas planejadas:** 1 sensação do golpe; 2 controle; 3 mecânicas (esquiva,
  agachar, parede, agressividade); 4 editor de animação/caixas e importação de
  gravações; 5 treino/replay; 6 cenário e apresentação; 7 APK/Windows e online
  com rollback. O usuário disse "vamos fazer todas".
- **Humor:** o usuário achou as minhas piadas de escola "sitcom" demais — pedir
  referências dele antes de propor.
- Tamanho estimado do jogo completo: ~110–130 MB (web ~70–90 MB baixados).

## Como o usuário trabalha
- Fala em português informal; quer ver resultado jogável e decide pela sensação.
- Sprites vêm do ChatGPT (estilo muda entre lotes; sempre conferir) — e, daqui
  para frente, das próprias gravações em vídeo.
- Aprova merges e publicação pedindo explicitamente; PRs por tarefa.
- Vai trocar de notebook (talvez um Mac antigo) e pode usar o Claude Code pelo
  navegador (claude.ai/code): lá não há Godot nem os arquivos locais; o script
  `godot-poc/tools/install_godot.sh` instala o Godot no Linux da nuvem.

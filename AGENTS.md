# GAVIÃO — guia para o próximo agente

Atualizado em 26/10/2026. Leia isto antes de mexer no código. Detalhes técnicos
completos em [docs/DUELO-080.md](docs/DUELO-080.md); histórico em `docs/` e
contexto do projeto em [docs/CONTEXTO.md](docs/CONTEXTO.md).

## Onde estamos

* Repositório: `Felipe-Airess/jogo-gavyo`. Branch de trabalho:
  `feat/combate-duelo-1x1`. **PR aberto: #2 → `main`**
  (https://github.com/Felipe-Airess/jogo-gavyo/pull/2). `main` ainda está na
  0.7.0; nada foi mesclado.
* Versão na branch: **0.8.0**. Phaser 3.90, `Phaser.CANVAS`, 320×180,
  nearest-neighbor, sem dependências de execução. Publicação prevista no
  GitHub Pages. Alvo de hardware: ThinkPad T400 (GPU OpenGL 2.1) e celulares.
* Dois modos (seletor **Modo**, no cabeçalho):
  * **Corredor** — o treino antigo (`src/battle.mjs`), mantido de propósito.
  * **Duelo 1×1** — novo, lateral, jogador × IA com as mesmas regras
    (`src/core/`, `src/duel/`).

## Como rodar e testar

```bash
npm start            # servidor local em http://127.0.0.1:4173 (abre o navegador)
npm test             # 165 testes: core, duelo e históricos — todos passando
npm run test:legacy  # 22 testes antigos — todos passando
npm run build        # gera build/ (≈4,7 MB, ignorado pelo Git)
python scripts/extract-markers.py sorriso miguel   # regenera *-markers.json (Python 3 + Pillow)
python scripts/add-miguel-lote2.py  # lote 2 do Miguel no atlas assets/miguel.png
python scripts/add-miguel-lote3.py  # lote 3 (golpes) do Miguel no atlas
python scripts/miguel-lote4/extrair.py && python scripts/add-miguel-lote4.py  # lote 4 (rodar extract-markers depois)
```

O `gh` (GitHub CLI) está instalado em `C:/Program Files/GitHub CLI/gh.exe` e
logado na conta Felipe-Airess; pode não estar no PATH do shell.

## O que mexemos nesta rodada (commits em `feat/combate-duelo-1x1`)

1. `a835d66` **Marcadores anatômicos** — `scripts/extract-markers.py` lê os
   pixels de cada quadro e separa cabeça (com queixo), tronco, quadril, punhos,
   pés e joelho por cor + componentes conectados. Saída:
   `assets/sorriso-markers.json`. Motivo: no atlas, `fist` e `foot` eram o
   mesmo “extremo claro” do quadro (no jab o “pé” fica na altura do punho).
2. `489979e` **Duelo com regras compartilhadas** — passo fixo de 60 Hz
   (`core/fixed-step.mjs`), buffer de comando de uma vaga, 134 ms
   (`core/command-buffer.mjs`), golpes a partir das fases/contatos do lote 3
   (`duel/moves.mjs`), caixas pelos marcadores com varredura
   (`duel/markers.mjs`, `duel/collision.mjs`), dano por região + equilíbrio +
   fôlego + nocaute determinístico (`duel/damage.mjs`), clinch
   (`duel/clinch.mjs`), IA com tempo de reação (`duel/ai.mjs`), regras do
   confronto (`duel/duel.mjs`), estrutura do lutador (`duel/fighter.mjs`).
3. `ebf119b` **Cena jogável e 0.8.0** — `duel/duel-scene.mjs` (desenho,
   depuração, HUD, rival com paleta trocada sob demanda); corredor ganhou passo
   fixo e interpolação; `smoothStep:false` no Phaser (antes, a 30 FPS o jogo
   inteiro rodava em câmera lenta).
4. `03cc351` **Mobile** — captura de ponteiro em melhor esforço (uma recusa do
   navegador derrubava o toque) e seletor de modo no cabeçalho (na barra, ele
   empurrava a página para fora da tela na paisagem).
5. `5e9548c` **Corrida, sangue e impacto** — passadas medidas nos pés
   (corrida ~112 px, caminhada ~76 px; antes 84/40), tabela de avanço por
   quadro (`gaitTable`) e sprite em degraus (`gaitOffset`) para o pé apoiado
   não escorregar; arrancada completa e freada `r2_runStop`; efeitos em
   `duel/impact-fx.mjs` (faísca, anel de contra-ataque, tremida, clarão,
   câmera lenta no nocaute, poeira) e mais sangue (`blood.mjs` configurável:
   manchas permanentes, marcas e gotejamento no rosto).

## Partida (27/10) — `src/duel/match.mjs`

* O duelo abre na **tela de seleção** (no canvas): Você, Rival (Sorriso ou
  Miguel), IA (`calmo`, `firme`, `dificil`), Rounds (1, melhor de 3 ou 5) e
  Tempo (60, 99 s ou sem tempo). Direcional/WASD navega, J/Soco começa. As
  escolhas ficam em `localStorage` (`gaviao-duelo`), com try/catch.
* `Match` (sem Phaser, testado em `tests/match.test.mjs`): fases `intro`
  (“ROUND N”/“ROUND FINAL” e “LUTA!”, comandos fechados), `fight`, `roundEnd`
  (“K.O.”, “TEMPO!” ou “EMPATE”) e `done`. No tempo vence quem tem menos
  castigo (`damageTaken`); igual é empate sem ponto; depois de 9 rounds sem
  decisão vence quem tem mais vitórias.
* Entre rounds `Duel.reset()` zera os lutadores; o sangue no chão fica.
* Fim: tela de vitória/derrota com placar; J revanche, K volta à seleção,
  M abre a seleção quando pausado. HUD: tempo no centro, vitórias em
  quadradinhos ao lado do nome.
* `AI_LEVELS.dificil` reage em 150 ms (o jab de 161 ms continua passando).

## Regras que o usuário pediu e que devem ser mantidas

* Não reescrever do zero, não trocar de engine, manter Canvas e o perfil leve.
* **Não esticar sprites, não duplicar quadros, não inventar coordenadas.**
  Marcador ausente = caixa ausente (é registrado em `MarkerSet.limits`).
* **Não usar sprites do Sorriso no lugar do Miguel.** Miguel joga no duelo
  (seletor **Lutador**) com a arte dele: lote 3 (`arte/personagens/miguel/lote3`,
  folhas do ChatGPT recortadas por `scripts/miguel-lote3/`) dá guarda
  respirando, andar, jab, direto, direto no corpo, pesado, chute circular,
  chute com passo (cima+K), chute baixo e joelhada (frente+K); lote 2 dá o
  bloqueio. Golpes sem desenho caem no substituto (`MOVE_FALLBACK`: gancho →
  jab, jab no corpo → direto no corpo); chão, arremesso, aparo-contra,
  corrida, agachar e clinch ficam indisponíveis. Ao apanhar, segura `m_block` 3.
  O "gancho" da folha é um direto (descartado) e o quadro 2 do direto foi
  tirado (braço estica antes da hora). Tempos: vídeos ×0,85 na preparação e
  ×1,2 na volta, com aceleração (`scripts/add-miguel-lote3.py`); ver seção
  "Miguel — auditoria de animação".
* Não usar animação incompatível para fingir uma ação que não foi desenhada.
* Nocaute sem sorteio, explicado na tela.
* Corredor preservado: buffer antigo, avanço (`lunge`) dos socos e caixas
  antigas continuam lá porque há testes e comportamento aprovado. Portar as
  melhorias do duelo para lá muda testes — **pergunte antes**.
* Não afirmar 60 FPS no T400 sem medir no aparelho.
* Commits pequenos e verificáveis; trabalhar em branch.

## O que está dando errado / limitações conhecidas

* **Sprites inconsistentes (principal crítica do usuário):** o duelo mistura
  linhagens. Golpes, locomoção e idle são do lote 3/2 (limpos); reações
  (`hurt`), queda (`fall`/`rise`), guarda (`block`, desenhada de frente) e
  clinch (`clinchWalk`, `kneeV6`, `clinchPunch`) são de folhas antigas, com
  traço e proporção diferentes. O alvo apanhando parece “lavado”. Código não
  resolve; precisa de arte nova.
* **Ainda “meio travado”:** reação = uma pose congelada por 300–500 ms; sem
  quadros de transição idle↔andar↔golpe; guarda troca de uma vez para o
  desenho frontal.
* **Pouca animação e nenhuma interação com o cenário:** o corredor é uma
  imagem parada (`src/art.js`); as paredes só limitam a posição.
* Circular “no corpo” chega na altura do queixo do adversário em pé (pé em
  −45 px): com as caixas justas acerta tronco em parte das distâncias e cabeça
  (mão erguida diante do rosto conta como cabeça) nas demais. Ou o desenho
  baixa, ou o nome muda.
* Agachado, só jab no corpo, gancho, pesado e chutes alcançam; jab, direto e
  direto no tronco passam por cima (pixels: topo da cabeça agachada em −33).
* Não há esquiva desenhada; defesa sem guarda é agachar (`r2_crouch*`) ou recuar.
* No duelo, frente + Soco sempre dá o direto (nunca jab andando para frente).
* Corredor: só a passada foi corrigida; o pé ainda desliza dentro do quadro
  (sem degraus) e os socos ainda empurram o sprite com `lunge`.
* Em tela 644×534 a barra de controles passa 9 px da largura — igual na 0.7.0.
* Não testado em celular físico nem no ThinkPad T400. Toque foi testado com
  eventos sintéticos em emulação.
* O PR #2 não está vinculado ao app (o vínculo foi bloqueado pela permissão).

## O que fazer a seguir (prioridade combinada com o usuário)

1. **Ajuste pelo jogo do usuário** — ritmo, velocidade (andar 52/42, correr
   120 px/s em `duel/fighter.mjs`), IA (`AI_LEVELS` em `duel/ai.mjs`),
   quantidade de sangue (`impact-fx.mjs`, multiplicadores por região). Peça a
   opinião dele depois de jogar.
2. **Cenário interativo** (aprovado como ideia, ainda não feito): objetos
   desenhados em código no estilo de `art.js` que reagem (armários que amassam,
   porta que treme, balde que tomba, mochila que desliza), parede que quica e
   pune quem é encurralado, vida no fundo (relógio, luz, alunos passando).
3. **Lote 4 de arte** — pedido pronto em `arte/reformulacao/PEDIDO-LOTES-4-5.md`
   (+ `PROMPTS-LOTES-4-5.txt`); o usuário está produzindo. Ao receber, integrar:
   reações de cabeça/tronco/perna laterais no estilo do lote 3, guarda
   lateral e bloqueio com recuo, queda para trás e levantar, clinch pareado
   (pega no pescoço, segurado resistindo, joelhada nova, saída), caminhada em
   guarda, esquiva; Miguel: andar, golpes, reações. O usuário produz as
   folhas; o agente integra, extrai marcadores e testa.
4. Portar para o corredor (com aval): buffer, sprite em degraus, sem `lunge`.
5. Medir no T400 e em celular físico (preparar medidor de FPS/tempo de quadro).
6. Revisão/merge do PR #2 quando o usuário aprovar.

## Consistência dos sprites (problema recorrente do usuário)

O usuário gera os sprites no ChatGPT e **cada lote costuma sair num estilo
diferente**. Ao pedir ou integrar arte nova: exigir o
`arte/reformulacao/KIT-REFERENCIA.png` + `base-aprovada.png` em todo pedido,
cabeçalho de prompt idêntico, folhas pequenas; ao receber, comparar cada
quadro com a base (tamanho da cabeça, altura em guarda ~66 px, paleta,
contorno) antes de integrar, e normalizar só cor e escala por código. Ver
`arte/reformulacao/PEDIDO-LOTES-4-5.md`, seção 1.1.

## Caixas (hitbox/hurtbox) — rodada de precisão

* Hurtboxes vêm dos pixels: `extract-markers.py` grava `hurt` por quadro
  (cabeça, tronco, pernas, braços) em retângulos de faixas de 4 px.
  `hurtboxes()` devolve **listas** de caixas por região. Sem `hurt`, cai no
  método antigo (uma caixa por região).
* Cabeça = cabelo sem o quarto superior + rosto + mão erguida diante dele.
  Pernas = blocos grandes de calça e tênis em qualquer altura + o que estiver
  abaixo do quadril. Braços (pele fora da cabeça) só contam durante o golpe,
  como tronco.
* Hitbox do membro termina no pixel mais à frente (`limbCenter`).
* Socos miram só cabeça e tronco.
* Auditoria nos 315 quadros: pixels opacos fora de hurtbox 25% → 7,7% (o
  resto é sobretudo a mão parada, fora de propósito, e o topo do cabelo);
  área de caixa sem pixel 36% → 13%.

## Golpe limpo e grogue (`duel/damage.mjs`)

* Qualidade do contato = parte da hitbox do membro dentro da região atingida
  (`coverage`): ≥ 0,6 limpo (dano ×1,25, base ×1,2, atordoamento ×1,15, pausa
  e tremor um degrau acima); ≥ 0,25 normal; abaixo, raspão (×0,5, ×0,5, ×0,7).
  Na varredura (membro atravessou entre ticks) não há medida: normal. Colado
  demais (< 60% do alcance do golpe) não sai limpo. Raspão não nocauteia por
  situação.
* Grogue: `headRecent` soma o dano na cabeça (limpo ×1,5) e cai 12/s; passou
  de 32 → grogue por 2,6 s: anda a 60%, não corre, não recupera equilíbrio,
  guarda gasta o dobro de fôlego. Golpe limpo médio/pesado na cabeça com
  cabeça ≥ 45 nocauteia. HUD mostra GROGUE. Sem arte própria: não há pose
  de cambaleio.
* Ajuste em `QUALITY` e `ROCK`. Simulação IA × IA (40 lutas): mediana 25 s,
  mínimo 10,6 s, ~15 grogues.

## Sequências (`duel/moves.mjs`, `Duel.begin/updateAttack`)

* Todo golpe em pé emenda em qualquer outro em pé depois de tocar (acerto ou
  bloqueio), inclusive chute em chute. Mesmo golpe no máximo 2× seguidas;
  até 4 ações (`MAX_CHAIN`). Pesado e soco de impulso (`finisher`) fecham a
  sequência. Erro continua sem cancelamento.
* Aperto durante o golpe fica guardado 400 ms (`CHAIN_BUFFER_MS`) e sai na
  primeira brecha: no contato (emenda) ou no fim da recuperação.
* O golpe emendado começa no quadro de preparação mais parecido com a pose
  atual (marcadores; `entryFrame`), sem voltar à guarda.
* Empurrão: acerto empurra metade do valor do golpe; emendado, mais 35%.
  Dano/base por posição: 1º–2º cheios, 3º 85%, 4º 72% (`COMBO`).
* Alcance ainda manda: a cabeça recua no quadro de reação (8 px), então
  jab → jab na cabeça costuma passar; jab → corpo → direto e chute → chute
  entram. Gancho é de curta distância.
* HUD mostra "X2", "X3". Simulação IA × IA: mediana 27,5 s, mínimo 4,3 s
  (sequência + grogue).

## Arremesso, chão e aparo (duelo)

* **Arremesso:** depois de 2+ golpes que tocaram, G com o adversário em
  `hitstun` a até 44 px vira `takedown` (arte `clinchFinish`); o alvo fica
  `thrown` preso à frente e cai em `down` no quadro 4 (1 s no chão).
* **Chão:** com o adversário em `knockdown`/`down` à frente a até 46 px, J é
  `groundPunch` (martelo, `clinchFinish`) e K `groundKick` (`groundFluid`).
  Sem empurrão entre os corpos com alguém no chão: dá para passar pelas
  pernas e bater do lado da cabeça (quem cai de costas fica com a cabeça do
  lado oposto). No chão, o que não é cabeça conta como tronco. Cada golpe
  segura o caído +320 ms (até +1,6 s). Golpe sólido na cabeça com cabeça ≥ 55
  finaliza.
* **Aparo:** L apertado até 140 ms antes do contato (`PARRY`) desvia; quem
  bateu fica `parried` 480 ms e é puxado para dentro; quem aparou tem 520 ms
  para J (`parryCounter`, conta como contra-ataque). Guarda levantada antes
  é bloqueio comum. A IA envia `steady` na guarda comum para não aparar por
  acaso; aparo de propósito em `AI_LEVELS.parry`.
* IA também arremessa (`AI_LEVELS.throw`) e bate em quem está no chão.
* Simulação IA × IA: mediana 20 s, mínimo 6 s; ~1 aparo por luta.

## Miguel — auditoria de animação (27/10)

* Alinhamento dos quadros do lote 3 pelo tronco (`ALIGN=body`, padrão): as
  células do ChatGPT deslocavam o boneco até 14 px. Soma dos saltos da cabeça
  169 → 143 px; o maior que sobra (24 px no pesado) é a mão acima da cabeça
  puxando o marcador, não o corpo. Saltos de "quadril" nos chutes vêm do
  marcador seguindo a perna erguida.
* Andar: `m3_walk` é andar no lugar, sem guarda (braços soltos). Passada
  medida nos pixels (`stride` = 2 × maior distância entre pontas dos tênis
  = 42 px); `miguelRef` troca o quadro pela distância (`f.gait`), não pelo
  relógio — o pé não desliza mais. O salto guarda → braços soltos é da arte
  (pedir "andar em guarda", item 2 da `LISTA-ANIMACOES.md`).
* Carga: com ×1,1 os chutes levavam 390–520 ms até o contato (Sorriso
  220–290). Agora jab 139, direto 157, circular 301, chute baixo 298, chute
  com passo 400 ms. Volta sem o degrau 86 → 43 ms.
* Cima+K do Miguel (`m3_stepKick`) é chute com passo **na cintura** (pé a
  −25/−28 px): mira tronco/perna, dano 14, base 24, empurrão 16 — antes usava
  os números do circular alto e acertava a perna.
* Separação mínima entre quadris 16 → 20 px (`STAGE.half` 10): com 16 os
  troncos se sobrepunham ~12 px e golpes "colados" acertavam regiões erradas
  (jab no corpo, circular na cabeça). Com 20: JFDK entra 4/4 nos dois
  personagens; joelhada só de perto; IA × IA mediana 21 s, máx. 49 s.
* Reações, bloqueio e andar em guarda vieram no lote 4 (seção abaixo); ainda
  faltam queda, levantar e transições.

## Miguel — lote 4 (27/10)

* Fonte: `arte/personagens/miguel/lote4/fontes/pacote2.png` (folha única do
  ChatGPT com títulos). `scripts/miguel-lote4/extrair.py` recorta pelas
  células de `celulas.json` (vale da silhueta), tira magenta e realce rosa
  (camisa clara pouco saturada vira cinza), escala cada linha da folha pela
  própria guarda (66 px), alinha pelo centro da camisa (o braço esticado não
  puxa o alinhamento), casa o histograma de cor com a guarda do lote 3 e
  aplica a paleta do lote 3. `revisao.png` e `relatorio.json` por animação.
* `scripts/add-miguel-lote4.py` põe `m4_*` no atlas. Contato: maior extensão
  medida, com correção manual em `CONTACT`. Tempos: equivalentes do Sorriso.
* `extract-markers.py`: pele do lote 4 é mais quente (210,116,65); regra
  `WARM_SKIN` só nos clipes `m4_` (os demais marcadores não mudam).
* No jogo: andar em guarda (frente/trás, `MIGUEL_WALK_CYCLE` 36 px — o passo
  desenhado tem ~10 px, o pé desliza a diferença), bloqueio `m4_block`,
  reação por região esticada ao atordoamento (`m4_hitHead/Body/Leg`), grogue
  `m4_dazed`, chão `m4_lying`, gancho (trás+J, curta distância, punho +21 px),
  jab no corpo (baixo+J, só tronco), aparo + contra. Queda/nocaute/levantar
  sem desenho: segura `m4_hitHead` 2.
* Fora do comando: chute alto `m4_kickHigh` (pé no topo da cabeça, −65 px;
  erro do prompt — corrigido para altura do rosto), uppercut, cotovelada,
  jab/direto com passo, esquiva + contra (no atlas, sem comando ainda).
  Socos do lote 4 alcançam ~2/3 do lote 3 (+21 contra +33 px).
* Refazer: correr, reação forte, esquiva para trás, queda, levantar.
* Varredura do membro só até `SWEEP_MAX` (45 px) entre ticks: salto maior
  (troca de pé no marcador, quadros do meio não desenhados) não arrasta caixa.
* Diferença de arte que fica: tênis brancos no lote 4 (escuros no lote 3).

## Miguel — folhas refeitas (27/10)

* `lote4/fontes/{leanBack,fall,hitHeadHeavy,run,rise}.png`, uma animação por
  imagem; `extrair.py` (REFEITAS) corta pelo vale da silhueta, escala pela
  guarda da folha (ou pela área da camisa quando não há guarda), preserva a
  altura relativa ao chão (voo da corrida) e casa a cor por folha.
* Corrida: a folha repete a mesma passada duas vezes (perna de longe sempre
  atrás; braços parados). `equalize_legs` dá à perna de longe os tons da de
  perto (só cor) para o ciclo ler como alternado. Passada: a da corrida do
  Sorriso (`R2_STRIDE.run`, mesma escala), porque o desenho corre no lugar.
* Duelo/corredor: corrida (arrancada m4_runStart, ciclo m4_run, freada
  m4_runStop), queda m4_fall, deitado m4_lying, levantar m4_rise, reação forte
  na cabeça m4_hitHeadHeavy (atordoamento ≥ 440 ms). Esquiva m4_leanBack no
  atlas, sem comando (não há mecânica de esquiva ainda).

## Miguel — pacote 3 (27/10)

* 16 folhas; 3 eram iguais às já integradas (levantar, corrida, reação forte).
  As novas ficam em `lote4/fontes/*2.png`, `walkA/B/C`, `combo*`.
* Corte das folhas refeitas pelos **números** acima das figuras
  (`label_centers`, texto claro ou escuro), com ajuste no vale da silhueta;
  antes, a divisão igual cortava figuras ao meio.
* **Alinhamento pelo pé apoiado** (`ALIGN_SHIRT` só para queda, levantar,
  corrida e andar): pela camisa, o tronco que avança no soco era puxado para
  trás — soco curto e pé de trás deslizando 10–65 px. Agora 1–5 px.
* Trocados no atlas (medido antes): andar (walkB; para trás = walkA ao
  contrário, `REVERSE`), jab no corpo, gancho, uppercut, cotovelada, jab e
  direto com passo (punho +26 px; antes +21). No atlas sem comando: 3 combos
  (`m4_combo*`, contato no último golpe) e `m4_kickHigh2`.
* Não aproveitados: walkC (corpo desliza na folha), chute alto 2 (pé só
  +9 px à frente do pé de apoio, altura do peito — não alcança).

## Golpes novos do Miguel no duelo (27/10)

* Comandos: cima+J `uppercut` (contato no quadro em que o punho passa o
  queixo, −54); J com o adversário a ≤ `ELBOW_RANGE` (25 px) vira `elbow`;
  Shift+K `comboLowHigh`, Shift+frente+K `comboJabElbowKnee`, Shift+baixo+J
  `comboBodyUpper`. Sorriso sem esses desenhos cai em `MOVE_FALLBACK` no que
  o mesmo comando já fazia (jab, chute circular, joelhada→circular, pesado).
* **Golpe com vários contatos** (`hits` no spec): cada janela acerta uma vez
  (`hitWindow`), com membro/regiões/fração próprios (`hitOf`); contatos de
  preparação têm 75% do atordoamento e 25% do empurrão para o combo seguir.
* **Avanço desenhado** (`root` + `advance` por quadro no atlas): ao sair do
  golpe (fim, emenda ou apanhar), `commitRoot` soma o avanço ao x. Combo
  jab→cotovelada→joelhada anda 21 px. O desenho tem um salto de 13 px no
  meio (avanço 10→23 entre quadros) — arte.
* Simulação: uppercut entra a 16–24 px; corpo→uppercut 4/4 colado; jab→
  cotovelada→joelhada 2/3 (cotovelada só bem perto, +15 px); chute baixo→alto
  1 de 2 (o alto só tem um quadro, pé a −61, topo da cabeça). IA × IA mediana
  24 s.

## Golpes em par (duelo, 27/10)

* Spec `pair` no golpe: `gap` (px, número ou lista por quadro), `when`
  ('combo' = após 2+ toques com o alvo atordoado), `reach`, `contacts`
  ([{frame, zone, scale?, lands?}]) e `victim[personagem] = {clip, frames}`
  (quadro da vítima para cada quadro do atacante).
* `startPair` trava a vítima (`thrown`, `pairOf`); `updateThrown` a mantém na
  distância e no olhar do desenho e grava `pairRef` (quadro sincronizado, lido
  por `animationRef`/`miguelRef`); `updatePair` aplica os contatos no quadro
  desenhado (`pairHit`, sem caixa); `separate` não empurra durante o par.
* O arremesso já usa o sistema: Sorriso cai com `fall`, Miguel com `m4_fall`,
  em sincronia. Para uma animação em par nova (PROMPTS-LOTE4 seções 15–18):
  extrair a fileira de cima como clipe do atacante e a de baixo como clipe da
  vítima (desenhada olhando para a ESQUERDA → `sourceFacing: -1`), escrever o
  spec `pair` e um `when`.

## Auditoria por simulação (27/10)

* Script de referência: 30 lutas IA × IA, uso/acerto/erro por golpe e motivo
  do fim. Três defeitos achados e corrigidos:
  1. **Nocaute "golpe limpo no contra-ataque" não exigia golpe limpo** —
     qualquer acerto médio no contra-ataque encerrava (22 de 30 lutas). Agora
     exige `quality === 'clean'` (o que a tela diz). Idem "base perdida".
  2. **Golpe mirado** (`aimOf`, `AIM_MIN` 0,25): soco no rosto que pega o
     queixo é cabeça; antes, 2 px de diferença de altura mandavam quase todo
     soco do Sorriso para o tronco do Miguel (Sorriso dava 2,7× mais dano e
     perdia 75%). Depois: 12×8 e 9×11.
  3. **IA usa o alcance de cada golpe** (`commandMove` + `reachOf`); antes jab
     no corpo usava o do jab e chute baixo o do direto (Miguel errava ~70%).
     IA também usa uppercut e, raramente, os combos.
* Equilíbrio hoje: Miguel vence ~70% (sem os combos, ~62%): ele tem mais
  golpes desenhados que o Sorriso. Decisão de design — não ajustado.

## Reações que acompanham o golpe (duelo, 27/10)

* `reactKind(m, zone)` em `duel.mjs`: straight / hook / uppercut / body /
  liver / legs pelo id do golpe (`m.react` sobrepõe). `reactHeavy` = limpo,
  atordoamento ≥ `HEAVY_STUN` (440) ou grogue. `RECOIL`: recuo de 1–4 px no
  sentido do golpe nos primeiros 90 ms (só no desenho e nas caixas, via
  `drawX`).
* `miguelHit` (fighter.mjs) escolhe da reação específica para a já desenhada
  (`MIGUEL_REACT`); hoje gancho/uppercut usam a cabeça leve/forte e fígado o
  corpo. A reação começa no quadro 1 (impacto), não na guarda.
* Arte pedida em PROMPTS-LOTE4 seção 19 (m4_hitHook, m4_hitHookHeavy,
  m4_hitUppercut(Heavy), m4_hitLiver, m4_hitBodyHeavy, m4_hitLegHeavy,
  m4_hitChain): ao chegar, extrair (REFEITAS), pôr em add-miguel-lote4 CLIPS
  e em extract-markers; o código já usa.

## Miguel no corredor (27/10, pedido do usuário)

* Seletor **Lutador** vale nos dois modos. `Corridor.setPlayer` troca golpes,
  textura, nome no HUD e esconde o Miguel-alvo; reinicia e pausa.
* `src/miguel-corridor.mjs`: golpes do corredor com clipes do Miguel
  (jab=jab no corpo m4, jabHead=m3_jab, cross/crossBody/drive/kick/lowKick
  do lote 3, low=gancho m4, highKick=chute com passo), tempos do atlas, mesmas
  fórmulas de `build-moves`. Caixa de ataque na ponta do punho/pé dos
  marcadores (`miguelPlayerClips` → `fist/foot` por quadro).
* `battle.mjs` ganhou `can` (run/grab/wipe) e `fallback` (golpe sem desenho →
  substituto desenhado: giratório → gancho, impulso → pesado, combos → chute
  ou direto); padrão sem mudança para o Sorriso. Golpe inexistente mostra
  "Golpe ainda sem desenho." `playerClips` separa a arte do jogador da dos alvos.
* Regra do corredor mantida: cabeça do alvo em pé fica a −67; corpo primeiro.
* Sem desenho: clinch e limpar a mão. Corrida, queda e levantar do Miguel vêm das folhas refeitas.

## Acompanhar (provisório, `STEP_IN` em `duel.mjs`)

* Golpe emendado avança até 8 px durante a preparação quando a borda da
  região mirada (caixas ≥ 16 px², no quadro atual do alvo) está fora do
  alcance, ou 4 px com a frente apertada. O pé desliza esse tanto — é
  provisório até existirem golpes com passo desenhado
  (`arte/personagens/miguel/LISTA-ANIMACOES.md`), quando o avanço passa a
  vir dos pés medidos, como na corrida.
* Resultado (apertando a cada 180 ms): jab → direto → gancho → circular e
  jab no corpo → direto → gancho → circular entram inteiros; jab → jab
  entra (raspão). Chute na perna depois de soco ainda passa por baixo: a
  perna do desenho de reação fica mais baixa que o chute.

## Tela (index.html / style.css)

* Só o jogo: botões Jogar/Pausar e ☰ por cima, no canto. Seletores, Colisões,
  Sangue, Som, Toque, Reiniciar e a lista de comandos ficam no menu (abrir
  pausa). Mensagem de estado sobre a faixa de baixo do canvas. FPS só com
  Colisões ligado. `fit()` usa a janela inteira (`--zoom` no `#viewport`).

## Armadilhas encontradas

* **Painel de navegador oculto não roda `requestAnimationFrame`:** o loop do
  Phaser fica em `frame 0`. Para testar, acione `game.loop.step(t)` com tempos
  controlados. Screenshots de painel oculto podem ser antigos; para ver o
  canvas, capture `game.canvas.toDataURL()` e salve por um receptor local.
* `setPointerCapture` falha com eventos sintéticos — por isso a captura é em
  melhor esforço em `touch-controls.mjs`.
* Pausa de impacto (hitstop) **congela o relógio do duelo**: testes que
  esperam cancelamento precisam avançar além dela (~66–116 ms).
* A IA recua para ~50 px de distância; testes de reação devem congelar o
  pensamento (`ai.thinkAt = 1e9`) para isolar o comportamento.
* Trocar de cena: use `game.scene.sleep/run` (o `ScenePlugin` de uma cena
  dormindo não acorda a outra) e mantenha `current` em `main.js`.
* `Phaser` limita o delta com `smoothStep`; está desligado de propósito.
* O campo `support` do atlas oscila entre quadros; use os marcadores novos.
* Mudou a arte? Rode `scripts/extract-markers.py` e confira um overlay antes
  de confiar nas caixas.

## Mapa rápido

| Arquivo | Papel |
| --- | --- |
| `src/main.js` | Cena Corredor, UI compartilhada, troca de modo |
| `src/battle.mjs` | Regras antigas do corredor (não refatorado) |
| `src/core/fixed-step.mjs` | Passo fixo, pulsos entre ticks, interpolação |
| `src/core/command-buffer.mjs` | Buffer de uma vaga e comando relativo ao olhar |
| `src/duel/*.mjs` | Duelo: regras, golpes, caixas, dano, clinch, IA, cena, efeitos |
| `src/locomotion.mjs` | Passadas medidas, `gaitTable`, `tableFrame` |
| `src/blood.mjs` | Sangue (limites por cena) |
| `src/touch-controls.mjs` | Toque multi-dedo |
| `assets/sorriso-v70.*` | Atlas atual; `sorriso-markers.json` gerado dele |
| `assets/miguel.*` | Atlas do Miguel: lote 1 (corredor) + lote 2 (duelo); `miguel-markers.json` |
| `arte/personagens/miguel/lote2/` | Quadros do lote 2 com limpeza técnica e manifesto |
| `tests/duel.test.mjs`, `tests/core.test.mjs` | Testes novos |
| `docs/DUELO-080.md` | Relatório técnico completo da 0.8.0 |

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
npm test             # 148 testes: core, duelo e históricos — todos passando
npm run test:legacy  # 22 testes antigos — todos passando
npm run build        # gera build/ (≈4,7 MB, ignorado pelo Git)
python scripts/extract-markers.py sorriso miguel   # regenera *-markers.json (Python 3 + Pillow)
python scripts/add-miguel-lote2.py  # acrescenta o lote 2 do Miguel ao atlas assets/miguel.png
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

## Regras que o usuário pediu e que devem ser mantidas

* Não reescrever do zero, não trocar de engine, manter Canvas e o perfil leve.
* **Não esticar sprites, não duplicar quadros, não inventar coordenadas.**
  Marcador ausente = caixa ausente (é registrado em `MarkerSet.limits`).
* **Não usar sprites do Sorriso no lugar do Miguel.** Miguel é jogável no
  duelo (seletor **Lutador**) só com a arte dele: entra em guarda, anda em
  guarda para frente/trás e bloqueia (lote 2). Golpes, corrida, agachar e
  clinch ficam bloqueados por `capabilities()`. Sem desenho de reação/queda,
  ao apanhar ele segura `m_block` 3 (decisão do usuário, 26/10).
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

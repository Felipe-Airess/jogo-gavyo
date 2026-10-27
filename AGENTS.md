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
npm test             # 133 testes: core, duelo e históricos — todos passando
npm run test:legacy  # 22 testes antigos — todos passando
npm run build        # gera build/ (≈4,7 MB, ignorado pelo Git)
python scripts/extract-markers.py   # regenera assets/sorriso-markers.json (Python 3 + Pillow)
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
* **Não usar sprites do Sorriso no lugar do Miguel.** Miguel só tem idle e
  guarda; `capabilities()` bloqueia o resto até existirem desenhos.
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
| `tests/duel.test.mjs`, `tests/core.test.mjs` | Testes novos |
| `docs/DUELO-080.md` | Relatório técnico completo da 0.8.0 |

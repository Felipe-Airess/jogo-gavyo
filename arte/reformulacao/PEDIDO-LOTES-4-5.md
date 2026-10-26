# Pedido de sprites — lotes 4 e 5 (+ Miguel)

Data: 26/10/2026. Para quem vai **desenhar/gerar** os sprites. Continua o
[PLANO.md](PLANO.md): lote 4 = defesa e reações, lote 5 = clinch (e chão),
e um lote M para o Miguel. As regras gerais estão em
[../GUIA-DE-ANIMACOES.md](../GUIA-DE-ANIMACOES.md) (seções 2, 6, 7, 8 e 9).
Os textos prontos para a ferramenta de imagem estão em
[PROMPTS-LOTES-4-5.txt](PROMPTS-LOTES-4-5.txt).

Por que agora: no Duelo 1×1 os golpes já usam o lote 3 (bonito), mas quem
apanha, defende, cai ou entra no clinch ainda usa folhas antigas, com outro
traço e outra proporção. É isso que deixa o combate “travado” e os sprites
“todos diferentes”.

## 1. Regras técnicas (valem para tudo)

| Item | Regra |
| --- | --- |
| Modelo | **O mesmo Sorriso do lote 3.** Referência única: `03-SOCOS-CHUTES/base-aprovada.png` (e `01-BASE-IDLE/base-fonte.png` para rosto/cabelo). Mesma cabeça, cabelo preto cacheado com volume, pele clara, polo branca com verde/amarelo, jeans, tênis claros. |
| Câmera | Lateral em ¾, **olhando para a direita**. O jogo espelha para a esquerda. |
| Célula | 128×96 px, pivô no chão em **(64,88)**. Em guarda o corpo tem ~66 px de altura. Poses abaixadas ficam mais baixas — **não** aumentar o corpo para “preencher”. |
| Escala | Uma escala para todas as animações. Nunca redimensionar um quadro sozinho. |
| Fundo | PNG RGBA com transparência real. Sem sombra, chão, texto, número, efeito, sangue ou adversário desenhado junto. |
| Corpo inteiro | Mãos, cabelo, joelhos e os dois tênis sempre dentro da célula. Se não couber, avisar (não cortar nem encolher). |
| Paleta | Manter as cores do lote 3. **Importante:** o jogo acha cabeça, mãos, pés e quadril pelas cores (pele, cabelo preto, camisa branca/verde, jeans azul, tênis claro). Se as cores mudarem, as caixas de acerto erram. |
| Arquivos | Uma pasta por ação: `hit_head_light/hit_head_light_000.png`, `_001.png`… Nome da ação estável (os IDs abaixo). Pode entregar também a folha (grade) e o `.aseprite`. |
| JSON (opcional, ajuda muito) | Para cada quadro: duração em ms e fase (`preparação`, `impacto`, `contato`, `continuação`, `recuperação`, `ciclo`). Para ações de dois atores, o quadro do contato. Mesmo formato de `03-SOCOS-CHUTES/golpes.json`. |
| Não fazer | Duplicar quadro para “contar mais”, esticar/derreter membros, desenhar efeitos (faísca/sangue/poeira — o jogo desenha), mudar figurino, trocar de braço sem querer. |

Durações abaixo são **o tempo no jogo**; o desenho pode ter mais quadros
mestres, desde que cada um seja uma pose diferente.

## 2. Prioridade

| Prioridade | O que | Por quê |
| --- | --- | --- |
| **P1** | Reações (cabeça leve/forte, tronco, perna), guarda lateral + bloqueio, caminhada em guarda (frente/trás), queda para trás + chão + levantar, nocaute | Aparecem em toda luta; hoje são poses antigas congeladas. |
| **P2** | Bloqueio de golpe pesado, guarda rompida, tronco cedendo (ajoelha), atordoado, cansado, erro de golpe pesado, queda para frente | Deixam o impacto e o risco visíveis. |
| **P3** | Clinch com os dois atores (lote 5) | Hoje usa folhas v6 e o segurado usa uma pose de “apanhando”. |
| **P4** | Esquiva (precisa de código novo), Miguel | Ampliam o jogo depois que a base estiver coerente. |

## 3. Lote 4 — defesa, reações e quedas (Sorriso)

Total P1+P2: **23 ações, ~202 quadros** (P1 sozinho: 13 ações, ~114 quadros).

### 3.1 Guarda e deslocamento em guarda — P1

| ID | Quadros | Tempo | Descrição quadro a quadro | Entra de / sai para |
| --- | ---: | ---: | --- | --- |
| `guard_up` | 4 | 110 ms | 0 idle de guarda · 1 cotovelos fecham · 2 antebraços sobem cobrindo o rosto · 3 guarda alta firme | idle → `guard_hold` |
| `guard_hold` | 6 (ciclo) | 900 ms | Guarda alta **lateral** (não de frente): antebraços na frente do rosto, queixo baixo, cotovelos protegendo a costela, joelhos flexionados. Respiração curta, ombros sobem/descem 1 px. | ciclo |
| `guard_down` | 4 | 120 ms | inverso de `guard_up`, terminando exatamente no idle | → idle |
| `walk_guard_fwd` | 8 (ciclo) | ~0,8 s | Passo de lutador para frente (pé da frente avança, de trás acompanha, **sem cruzar as pernas**), guarda mantida, tronco quase parado. Pé apoiado fica **parado** no desenho enquanto o outro se move. | idle ↔ |
| `walk_guard_back` | 8 (ciclo) | ~0,9 s | Mesmo princípio para trás: o pé de trás recua primeiro. | idle ↔ |

Inspiração: caminhada de *Street Fighter III: 3rd Strike* e *Garou: Mark of
the Wolves* (passo curto, base larga, guarda parada); boxeadores em
“shuffle” (vídeos de treino de footwork).

### 3.2 Bloqueio — P1/P2

| ID | Quadros | Tempo | Descrição | Prioridade |
| --- | ---: | ---: | --- | --- |
| `block_hit` | 6 | 220 ms | 0 guarda · 1 **impacto**: braços amassam contra o rosto, cabeça recua 1–2 px, peso no pé de trás · 2 corpo absorve (joelhos dobram) · 3 empurrado ~2 px · 4 volta · 5 guarda. Pé da frente pode escorregar levemente para trás. | P1 |
| `block_heavy` | 8 | 300 ms | Como acima, mas o impacto empurra um **passo para trás** (pé da frente recua), tronco inclina, braços abrem um pouco e se fecham de novo. | P2 |
| `guard_break` | 8 | 520 ms | 0 impacto na guarda · 1–2 braços são jogados para fora/para cima, cabeça exposta · 3–4 tronco desequilibra para trás · 5–6 tenta recompor · 7 meia guarda baixa (vulnerável). | P2 |

### 3.3 Reações a golpe — P1

Começar **da pose atingida**, sem voltar primeiro para a pose em pé. Cabeça
leva o tranco, tronco acompanha, pernas seguram o peso.

| ID | Quadros | Tempo | Descrição |
| --- | ---: | ---: | --- |
| `hit_head_light` | 6 | 300 ms | Jab no rosto. 0 **impacto**: cabeça vira para trás/lado, olhos fechando · 1 ombros acompanham, guarda abre um pouco · 2 meio passo de trás para absorver · 3 cabeça volta · 4 guarda se refaz · 5 guarda. |
| `hit_head_heavy` | 10 | 500 ms | Direto/pesado/chute alto. 0 impacto: cabeça e tronco jogados para trás, braços abrem · 1–2 cambaleia, um pé sai do chão · 3–4 passo para trás para não cair, joelhos dobram · 5–6 tronco volta, guarda baixa · 7–9 recompõe a guarda. |
| `hit_body` | 8 | 400 ms | Soco/chute no tronco. 0 impacto: corpo **dobra para frente**, quadril vai para trás, ar sai · 1 braço de trás desce para proteger a barriga · 2 joelhos cedem · 3–4 segura · 5–7 volta à guarda com o tronco ainda baixo. |
| `hit_legs` | 8 | 360 ms | Chute na perna. 0 impacto na coxa da frente: joelho dobra para dentro · 1 peso passa para a perna de trás · 2 perna atingida pisa de leve · 3–5 manca, ombros caem · 6–7 guarda. |

Inspiração: reações de *Street Fighter III: 3rd Strike* (cabeça lidera o
movimento), *Sifu* (corpo dobra no golpe no tronco) e câmera lenta de
nocaute/knockdown de boxe e MMA (procure por vídeos “boxing slow motion
punch reaction”).

### 3.4 Estados de desgaste — P2

| ID | Quadros | Tempo | Descrição |
| --- | ---: | ---: | --- |
| `stagger_loop` | 8 (ciclo) | 900 ms | Atordoado (equilíbrio baixo): guarda baixa, cabeça pesada balançando, joelhos frouxos, pequenos passos para manter o pé. |
| `tired_loop` | 8 (ciclo) | 1,1 s | Sem fôlego: respiração pela boca, ombros sobem, mãos mais baixas, ainda de frente ao adversário (não de frente para a câmera). |
| `heavy_miss` | 10 | 500 ms | Golpe pesado no vazio: o corpo **passa do ponto**, pé da frente escorrega à frente, tronco cai à frente, braço continua o arco; recupera a base e a guarda. Começa na pose de contato do `overhand_heavy` (`03-SOCOS-CHUTES/quadros/overhand_heavy_006.png`). |

### 3.5 Quedas, chão, levantar e nocaute — P1/P2

| ID | Quadros | Tempo | Descrição | Prioridade |
| --- | ---: | ---: | --- | --- |
| `knockdown_back` | 12 | 450 ms | 0 impacto (pose de `hit_head_heavy` 0) · 1–3 joelhos cedem, corpo vai para trás · 4–6 quadril bate no chão, braços amortecem · 7–9 costas no chão, pernas acompanham · 10–11 assenta. Último quadro = início de `down_back`. | P1 |
| `down_back` | 4 (ciclo) | 700 ms | Deitado de costas, respiração, uma mão no rosto/barriga. Altura total baixa (corpo deitado ocupa a largura da célula). | P1 |
| `getup_back` | 14 | 700 ms | 0 deitado · 1–3 vira de lado, apoia antebraço · 4–6 apoia mão e joelho · 7–9 sobe o tronco · 10–12 fica em pé · 13 guarda. | P1 |
| `knockdown_front` | 12 | 480 ms | Perna cedeu/tronco cedeu: 0 joelho dobra · 1–4 cai para frente amortecendo com as mãos · 5–8 joelhos e mãos no chão · 9–11 deita de bruços ou fica de quatro. Saída: `getup_front`. | P2 |
| `getup_front` | 12 | 620 ms | De quatro → um joelho → em pé → guarda. | P2 |
| `collapse_body` | 10 + 4 + 8 | 1,3 s | Tronco esgotado: ajoelha segurando a barriga (10), permanece (4, ciclo de dor) e levanta (8) até a guarda. | P2 |
| `ko_fall` | 14 | 650 ms | Nocaute: **sem amortecer** — 0 impacto · 1–3 corpo perde o tônus, braços soltos · 4–8 queda rígida/mole para trás · 9–12 quica de leve no chão · 13 imóvel. | P1 |
| `ko_ground` | 2 | — | Pose final no chão (pode variar um detalhe mínimo, ex.: dedo). | P1 |

Inspiração: quedas de *Garou: Mark of the Wolves* e *The King of Fighters
XIII* (peso no quadril, quique curto), nocautes de MMA em câmera lenta para o
corpo “desligado” do `ko_fall`, levantadas de *Sifu*.

### 3.6 Esquiva — P4 (precisa de código novo; desenhar só depois de P1–P2)

| ID | Quadros | Tempo | Descrição |
| --- | ---: | ---: | --- |
| `slip_back` | 8 | 300 ms | Pêndulo: tronco recua e abaixa a cabeça para fora da linha, pés parados; volta à guarda pronto para responder. |
| `duck_weave` | 10 | 380 ms | Abaixa e passa a cabeça por baixo de um gancho (U), termina em guarda. |

## 4. Lote 5 — clinch (dois atores sincronizados)

Regra principal: **atacante e segurado em arquivos separados**, com o mesmo
número de quadros e o mesmo tempo, desenhados sobre uma prévia composta para
conferir o contato. Distância entre os pivôs no clinch: **22 px** (o jogo
mantém essa distância). O segurado também é o Sorriso (o rival é o mesmo
modelo com outra roupa, feito pelo jogo).

Total P3: **10 pares + 1 ação só do atacante, ~186 desenhos** (90 por ator + 6).

| ID (atacante / segurado) | Quadros | Tempo | Descrição |
| --- | ---: | ---: | --- |
| `clinch_reach` (só atacante) | 6 | 300 ms | Braços estendem para a nuca do adversário e voltam (também usado quando a pega falha). |
| `clinch_enter` / `held_enter` | 8 | 200–260 ms | Mãos fecham atrás da nuca (pegada “plum” do muay thai), puxa a cabeça para baixo; o segurado perde a guarda e dobra o pescoço. |
| `clinch_hold` / `held_hold` | 6 (ciclo) | 800 ms | Sustentação: atacante com cotovelos juntos, testa perto; segurado com mãos tentando empurrar o peito/quadril, pés buscando base. |
| `clinch_drag_fwd` / `held_drag_back` | 8 (ciclo) | ~0,9 s | Atacante empurra andando; segurado recua tropeçando, pés acompanham o deslocamento. |
| `clinch_drag_back` / `held_drag_fwd` | 8 (ciclo) | ~0,9 s | Atacante puxa para trás; segurado é arrastado. |
| `clinch_knee` / `held_knee_hit` | 10 | 360 ms | Joelho sobe ao tronco mantendo a pega com as duas mãos; segurado dobra no impacto (quadro 4 = contato). |
| `clinch_punch` / `held_punch_hit` | 8 | 370 ms | Uma mão segura, a outra golpeia curto no rosto; cabeça do segurado vira (quadro 2–3 = contato). |
| `clinch_elbow` / `held_elbow_hit` | 10 | 420 ms | Cotovelada horizontal curta: **o cotovelo chega primeiro**, mão perto do próprio rosto; cabeça do segurado vira forte. |
| `clinch_escape` / `held_escape` | 10 | 400 ms | Segurado encaixa antebraço no peito, empurra e sai; atacante perde a pega e recua um passo. |
| `clinch_release` / `held_release` | 8 | 300 ms | Atacante solta empurrando; os dois voltam à guarda à distância. |
| `clinch_throw` / `held_thrown` | 14 | 650 ms | Puxa a cabeça, golpe de queda e solta; segurado cai e termina na pose inicial de `down_back`. |

Inspiração: clinch “plum” de muay thai (vídeos de treino e lutas), clinch de
*EA Sports UFC* para leitura de corpo, e as cenas de agarrão de *Sifu*.

Chão (opcional, depois): `ground_punch`, `ground_kick`, `ground_stomp` já
descritos no guia (seção 3) — no duelo ainda não existem ataques no chão.

## 5. Lote M — Miguel (P4)

Miguel tem só `idle` (10) e `guarda` (16), em `arte/personagens/miguel`. O jogo
**não** usa o Sorriso no lugar dele, então cada ação abaixo libera uma parte do
Miguel no duelo. Usar as fontes dele como referência de rosto/roupa e a mesma
escala/célula/pivô (128×96, (64,88)).

| Ordem | IDs | Quadros | Libera no jogo |
| --- | --- | ---: | --- |
| 1 | `walk_guard_fwd`, `walk_guard_back` | 8 + 8 | Andar |
| 2 | `jab_head`, `cross_head`, `hook_body`, `low_kick` | 12 cada | Atacar (4 golpes básicos) |
| 3 | `hit_head_light`, `hit_head_heavy`, `hit_body`, `hit_legs`, `block_hit` | 6/10/8/8/6 | Reagir e defender |
| 4 | `knockdown_back`, `down_back`, `getup_back`, `ko_fall`, `ko_ground` | 12/4/14/14/2 | Cair e ser nocauteado |
| 5 | `round_kick_body`, `run`, `run_start`, `run_stop`, clinch | como no Sorriso | Completar |

Mesmas descrições de quadros do Sorriso (lotes 3 e 4); o estilo de luta pode
mudar (ex.: guarda mais fechada), mas a contagem e os tempos devem seguir as
tabelas para o jogo encaixar.

## 6. Características que valem para todas as animações

* **Antecipação → ação → acomodação.** Até reação tem um quadro de impacto
  claro (o mais extremo) e depois desacelera.
* **A cabeça lidera nos golpes de cabeça, o quadril lidera nos de tronco, o
  joelho lidera nos de perna.**
* **Pés com peso.** Pé no chão não desliza dentro de um ciclo; quando o corpo
  é empurrado, mostre o passo (não arraste o sprite).
* **Primeiro e último quadro compatíveis** com o idle/guarda do lote 1, para
  as ligações não “trocarem de figurinha”.
* **Tempos desiguais:** impacto rápido (1 quadro curto), recuperação mais
  longa. As durações das tabelas são o ponto de partida.
* **Silhuetas legíveis a 320×180:** braço/perna atingidos separados do
  tronco; nada de detalhe que some ao reduzir.
* Referência de princípio: palestra de Mariel Cartwright (Skullgirls) sobre
  poses-chave e tempo — link na seção “Fontes” do guia.

## 7. Como entregar e o que o agente faz depois

1. Colocar cada lote em `arte/reformulacao/04-DEFESA-REACOES/` ou
   `05-CLINCH/` com `quadros/`, folhas e, se possível, o JSON de tempos.
2. O agente monta a prévia (como nos lotes 1–3), junta no atlas, roda
   `python scripts/extract-markers.py` (adicionando os IDs novos) e confere as
   caixas sobre os quadros antes de integrar.
3. Integração no duelo troca as poses antigas (`hurt`, `fall`, `rise`,
   `block`, `clinchWalk`, `kneeV6`, `clinchPunch`) pelas novas; os testes de
   contato e de deslizamento do pé valem para os desenhos novos.

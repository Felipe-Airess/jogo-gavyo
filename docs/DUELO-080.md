# Duelo 1×1 e base de combate — 0.8.0

Data: 26/10/2026. Branch `feat/combate-duelo-1x1`, a partir de `main` (`f954d3d`).

O corredor de treino continua como estava (modo **Corredor**). O combate novo é
o modo **Duelo 1×1**: dois lutadores em linha lateral, sem profundidade, com as
mesmas regras para o jogador e para a IA. Nada foi reescrito do zero: o duelo
reaproveita o atlas `sorriso-v70`, os tempos e quadros de contato do lote 3, o
áudio, o toque e o cenário.

## Problemas encontrados na auditoria

| Área | Problema concreto | Situação |
| --- | --- | --- |
| Marcadores | `fist` e `foot` do atlas vêm do mesmo “extremo claro” do quadro. No `jab_body` de contato o “pé” está em (31,−34), na altura do punho; nos chutes os dois coincidem. O campo `support` também salta entre quadros (andar: 11,9 → −9,1 → 10,4). | Novos marcadores por classe de cor em `assets/sorriso-markers.json`. Atlas original intocado. |
| Tempo | A partir do FPS alvo, o Phaser (`smoothStep`) limitava cada quadro a 16,7 ms: num computador a 30 FPS o jogo inteiro rodava em câmera lenta (1 s real = 0,5 s de jogo, medido no navegador). | `smoothStep:false` + passo fixo. Medido: 30, 60 e 120 FPS avançam o mesmo tempo. |
| Tempo | `Battle.step` dividia o quadro em sub-passos de 8,3 ms mais um resto variável: o resultado dependia do FPS. | Corredor agora recebe ticks fixos de 16,7 ms (cada um ainda com dois sub-passos de 8,3 ms, como antes). |
| Entrada | Um aperto de J durante `attackRecover`, `hurt`, `stumble` ou na preparação de um golpe que não confirma era descartado. | No duelo: buffer de uma vaga, 134 ms. Corredor mantido (há teste histórico que exige ignorar o aperto repetido na recuperação). |
| Entrada | Num quadro mais curto que um tick (120/144 Hz) um toque podia não chegar à lógica. | `FixedStep` guarda pulsos até o próximo tick. |
| Pés | Nos socos do lote 3 o pé de trás fica fixo em ≈ −11 px do pivô em todos os quadros; o corredor ainda soma `lunge` (até 12 px no pesado), o que faz o pé plantado deslizar. | Duelo não aplica avanço extra nesses golpes. Corredor mantido: o avanço é parte de testes e do comportamento aprovado. |
| Colisão | Hurtboxes do corredor são aproximações do manequim (`pose()` fixa + 3 pontos); o jogador só tem uma caixa de 12×9 nos pés. | Duelo: caixas por quadro a partir dos marcadores, para os dois lados. |
| Estrutura | `Battle` é centrado no jogador: inimigos têm estrutura e regras próprias (`enemy()`, `updateEnemy`, `enemyAttack` sem animação de golpe). | Duelo usa uma estrutura única de lutador. |

## Arquitetura do duelo

| Arquivo | Responsabilidade |
| --- | --- |
| `src/core/fixed-step.mjs` | Passo fixo de 60 Hz, pulsos guardados entre ticks, interpolação, limite de 6 ticks por quadro. |
| `src/core/command-buffer.mjs` | Uma vaga de comando por lutador, 134 ms; o aperto mais novo substitui o anterior. |
| `src/duel/moves.mjs` | Golpes a partir de `durations`, `contactFrames` e `phase` do atlas. Regras de cancelamento. |
| `src/duel/markers.mjs` | Marcadores → mundo (espelho, pivô, escala). Hurtbox, pushbox, guarda, agarrão. |
| `src/duel/collision.mjs` | AABB e varredura contínua de segmento. |
| `src/duel/damage.mjs` | Cabeça/tronco/pernas, equilíbrio, fôlego, contra-ataque, nocaute determinístico. |
| `src/duel/clinch.mjs` | Entrada, espaçamento sem teleporte, escape, soltura. |
| `src/duel/fighter.mjs` | Estrutura do lutador, capacidades por personagem, escolha do quadro. |
| `src/duel/ai.mjs` | IA com tempo de reação, defesa, punição e espaçamento. |
| `src/duel/duel.mjs` | Regras do confronto: estados, contato, trocas, pushbox, olhar. |
| `src/duel/duel-scene.mjs` | Desenho Phaser/Canvas, depuração, HUD. |
| `scripts/extract-markers.py` | Gera `assets/sorriso-markers.json` (Python 3 + Pillow). |

### Golpes, fases e cancelamento

Preparação = soma das durações até o primeiro quadro de contato do atlas;
continuação termina no primeiro quadro marcado como recuperação. Os tempos não
foram esticados; os quadros não foram duplicados.

| Comando | Golpe | Preparação | Fim do contato | Total | Alcance do membro |
| --- | --- | --- | --- | --- | --- |
| J | jab (cabeça) | 161 ms | 265 | 553 | 35 px |
| baixo+J | jab no corpo | 161 | 265 | 553 | 39 |
| frente+J | direto | 218 | 342 | 649 | 41 |
| baixo+frente+J | direto no tronco | 218 | 342 | 649 | 48 |
| trás+J | gancho no corpo | 206 | 309 | 684 | 26 |
| Shift+J | pesado | 258 | 415 | 920 (+500 se errar) | 55 |
| correndo+Shift+J | soco de impulso | 291 | 483 | 963 (+500) | 44 |
| K | circular | 268 | 408 | 889 | 30 |
| cima+K | circular alto | 291 | 431 | 944 | 39 |
| baixo+K | chute na perna | 224 | 348 | 655 | 34 |

Cancelamentos só depois de tocar (acerto ou bloqueio), dentro da continuação, e
só para o próximo golpe listado: jab → direto, jab no corpo ou jab>chute alto;
jab no corpo → direto/direto no tronco/gancho; direto → gancho ou chute na perna;
chute na perna → chute>direto. Sem ciclos e no máximo três ações. Golpe que erra
cumpre a recuperação inteira; pesado e impulso ainda entram em `missMotion`.

### Caixas

* **Hitbox**: ponta do membro ativo (punho 6×6, pé 9×8, joelho 10×10).
  Primeiro vale onde o membro está; se não toca nada, uma varredura desde o
  tick anterior evita atravessar o alvo. Só nos quadros de contato.
* **Hurtbox**: cabeça (do cabelo ao queixo), tronco (camisa até a calça),
  pernas (quadril aos pés). Mudam a cada quadro: agachar tira a cabeça da linha.
* **Pushbox**: 16 px centrados no quadril desenhado.
* **Guarda**: braços à frente da cabeça e do tronco; não cobre a perna.
* **Agarrão**: 22 px à frente do peito.
* **Colisões** (botão ou F2) desenha tudo isso, a trajetória varrida e os
  pontos dos marcadores.

### Dano, equilíbrio e nocaute

Cada região acumula castigo até 100. Corpo drena mais fôlego; perna derruba mais
o equilíbrio e reduz a velocidade. Equilíbrio volta com o tempo; em zero, queda.
Contra-ataque (pegar o outro na preparação), base abaixo de 30 e fôlego abaixo de
20 multiplicam o impacto. Nocaute sem sorteio: cabeça em 100, ou golpe médio/
pesado limpo na cabeça já castigada (≥ 55) que seja contra-ataque ou encontre a
base perdida. O motivo aparece na barra de estado e na tela final.

### Clinch

Entra com G se a área de agarrão toca o tronco e o outro não está atacando. Os
dois se aproximam até 22 px a no máximo 70 px/s. Quem segura: K joelhada, J soco
curto, direção arrasta (gasta fôlego e pega), G solta. Quem é seguro enche a
barra de escape apertando golpes ou puxando para trás; o ganho depende do fôlego
dos dois. Solta por tempo da pega, escape, fôlego zerado, G ou queda do alvo.

### IA

Recebe só o que está visível (estado, posição, há quanto tempo o golpe do outro
está na tela). Reage depois de 180 ms (“firme”): defende golpes lentos, mas não
o jab, que conecta em 161 ms. Pune golpe errado ou bloqueado, encurtando a
distância antes de bater. Espaça os próprios ataques e escapa do clinch.
Reproduzível por semente.

## Testes

`npm test`: 131 testes (core 7, duelo 37, históricos 87). `npm run test:legacy`: 22.
Novos: dois lados, alcance, varredura, um contato por golpe, buffer, expiração,
cancelamento com/sem contato, limite de sequência, pesado errado, defesa e
punição, chute baixo contra guarda, agachar, dano por região, queda e
invulnerabilidade no chão, nocaute determinístico, clinch (entrada, sem teleporte,
joelhada, quatro solturas), pushbox e parede, sincronia da passada, pernas
castigadas, pausa de impacto, perda de foco, reinício, IA (ritmo, reação, punição,
semente), Miguel, marcador ausente, passo fixo a 30/60/120/144 FPS, toque simultâneo.

Navegador (Chromium do painel, loop do Phaser acionado com marcas de tempo
controladas): troca Corredor↔Duelo duas vezes, J/D pelo teclado nos dois modos,
perda de foco pausa, nocaute fecha a luta, sem erros no console, build servida
de `build/` com renderer Canvas. Composição offline dos quadros de contato com
as caixas confirmou: jab/direto no rosto, jab no corpo no tronco, circular alto
na cabeça, chute na perna através da guarda, direto bloqueado na zona da guarda,
jab passando sobre o agachado, joelhada no tronco.

Custo da lógica: ≈ 2,6 µs por tick nesta máquina (IA × IA, 10 min simulados).
**Não houve medição no ThinkPad T400**; não há afirmação de 60 FPS nele.

## Limites e arte necessária

* **Reações**: o duelo usa poses únicas de `hurt` (cabeça, tronco, perna),
  `fall`/`rise` e `block` da linhagem antiga — traço e proporção diferentes do
  lote 3, e `block` é frontal. Faltam sequências laterais no estilo do lote 3:
  reação de cabeça (3–4 quadros), de tronco dobrando, de perna cedendo, guarda
  lateral e bloqueio com recuo, queda para trás e levantar.
* **Clinch**: pegada (`clinchWalk`), joelhada (`kneeV6`) e soco curto são da
  linhagem v6. O segurado usa `hurt` 0 (cabeça baixa). Faltam quadros pareados:
  pega no pescoço vista de lado, segurado resistindo, joelhada no lote 3,
  empurrão de saída.
* **Esquiva**: não há desenho de esquiva/pêndulo; a defesa sem guarda é
  agachar (`r2_crouch*`) ou recuar.
* **Golpe para trás** (`reverse_strike`) não entra no duelo: o adversário está
  sempre à frente.
* **Circular “no corpo”**: o pé desenhado chega na altura do queixo de um
  adversário em pé (−45 px); por isso costuma acertar a cabeça. Ou o desenho
  baixa, ou o nome muda.
* **Cotovelos**: sem marcador (manga clara sem contraste com o antebraço).
* **Rival**: é Sorriso com roupa escura (troca de paleta por quadro, criada só
  quando o quadro aparece). Miguel tem só idle e guarda; as regras o aceitam
  (`capabilities`), mas ele não anda, não bate e não reage até receber esses
  desenhos — nenhuma pose de Sorriso é usada no lugar dele.
* **Ragdoll**: continua só no corredor; no duelo as quedas usam `fall`.
* Corredor: buffer, deslizamento do pé e caixas antigas foram mantidos para não
  quebrar o comportamento e os testes aprovados.

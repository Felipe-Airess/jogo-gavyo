# Migração completa para Godot nativo

Solicitação de 28/10/2026: adaptar o jogo atual do Phaser ao Godot, incluindo regras
em GDScript. O novo pedido amplia a antiga POC; o Phaser permanece preservado.
Não usar iframe, Phaser oculto, emulação de cenas Phaser ou regras JavaScript
executadas no navegador para chamar o resultado de Godot nativo.

## Referência e critério de conclusão

A referência é o jogo executado por `src/main.js` e `src/duel/duel-scene.mjs` em
`main`, não todos os protótipos históricos descartados. Preservar os arquivos
históricos como fonte e evidência; não ativar golpes recusados ou arte sem comando
como se estivessem presentes no jogo de referência.

Concluir somente quando os dois modos, personagens, comandos, arte, efeitos e
interface abaixo estiverem integrados e testados no Godot, com comparação de
replays e teste manual no celular. Aprovação da arte e sensação continua com o
usuário. Portar módulos e importar PNGs não comprova paridade do jogo completo.

## Inventário e estado

| Sistema | Fonte Phaser | Estado Godot |
| --- | --- | --- |
| Sorriso e Miguel, atlas completo | `assets/sorriso-v70.*`, `assets/miguel.*` | Preparados em `assets/full/`: 124 clipes, 1.030 quadros. Não integrados à cena completa. |
| Tempos, contatos, pivôs, hurtboxes medidas | JSONs e `*-markers.json` | Biblioteca GDScript de consulta e transformação; preserva ausência de marcador. |
| Tabela completa de golpes do Duelo | `duel/moves.mjs`, `CHARACTER_SPECS` | Construção nativa de 38 entradas comparada com a fonte; dados de especificação em JSON. |
| Input relativo e buffer | `core/command-buffer.mjs` | Portados; falta integrar ao novo controlador completo. |
| Simulação fixa e pulsos | `core/fixed-step.mjs` | Portada; preserva pulso entre quadros. |
| Varredura de colisão | `duel/collision.mjs` | Portada e comparada em 200 trajetórias. |
| Dano, qualidade, guarda rompida, KO | `duel/damage.mjs` | Fórmulas portadas; 1.200 casos comparados. Falta integração ao ciclo completo de estados. |
| Rounds, tempo, placar, intro/resultado | `duel/match.mjs` | Modelo nativo com testes de intro/KO/fim; falta UI e bateria de replays completa. |
| Locomoção, passada/apoio, avanço desenhado | `locomotion.mjs`, `duel/fighter.mjs`, `markers.mjs` | Pendente. |
| Combos, cancelamento, múltiplos contatos, acompanhamento | `duel/duel.mjs`, `moves.mjs` | Pendente integração nativa do estado da luta. |
| Aparos, contra-ataque, grogue, vulnerabilidade temporal | `duel/duel.mjs` | Pendente controlador; fórmulas de dano preparadas. |
| Clinch, escapar, agarrar, joelho, arremesso pareado | `duel/clinch.mjs`, `duel/duel.mjs` | Pendente. |
| Queda, chão, levantar, finalização | `duel/duel.mjs`, `fighter.mjs` | Pendente. |
| IA calmo/firme/difícil, reação e alcance por personagem | `duel/ai.mjs` | Pendente; a IA simples da POC não substitui esta IA. |
| Corredor com profundidade, câmera e dois alvos | `battle.mjs`, `main.js` | Pendente. |
| Corredor Miguel, restrições e substitutos próprios | `miguel-corridor.mjs` | Pendente. |
| Alvos, física da queda e recuperação | `target-view.mjs`, `ragdoll.mjs`, `pose-state.mjs` | Pendente. |
| Cenário original do corredor | `art.js` | Pendente; cenário simplificado da POC não é equivalente. |
| Sangue, marcas, feridas, poeira, tremor, clarão e câmera lenta | `blood.mjs`, `duel/impact-fx.mjs` | Pendente. |
| Áudio sintetizado de golpe, bloqueio, aparo e passada | `combat-audio.mjs` | Pendente port nativo; não depender de WebAudio. |
| Seleção de modo/personagens/IA/rounds/tempo | `index.html`, `duel-scene.mjs` | Pendente UI Godot. |
| Menu, pausa/reset, colisões, som/sangue, comandos | `main.js`, `style.css` | Só controles mínimos da POC; falta equivalência completa. |
| Teclado e multitouch com combinações de direções | `touch-controls.mjs` | POC só tem subconjunto; falta direcional completo e todos os modificadores. |
| Persistência de escolhas | `duel-scene.mjs` localStorage | Pendente `user://` nativo. |
| Export Web e retomada Codespaces | `godot-poc/tools/`, devcontainer | Existentes; incluir validação nativa de cada nova etapa. |
| Export Android/PC | sem equivalente no Phaser | Possibilidade futura, não validada nem prometida nesta etapa. |

## Ordem de integração

1. Biblioteca completa, regras independentes e testes de equivalência (em andamento).
2. Lutador nativo: máquina de estados, apoio/passadas, animação e caixa no mesmo pivô.
3. Duelo completo: comandos/combos, aparo, grogue, clinch/par, chão, IA e partida.
4. Corredor: modelo, alvos, profundidade, física e câmera; manter regras próprias.
5. Cena, áudio, efeitos, HUD/menu/seleção/persistência e todos os comandos mobile.
6. Replays comparativos, regressão Phaser, teste real no telefone e revisão Claude.

Não substituir a prévia jogável por uma migração pela metade. A cena atual da POC
continua ativa até existir uma cena completa validada. Não declarar migração feita
por a exportação HTML5 ter passado.

## Verificação inicial

`tools/generate_parity.mjs` usa o código fonte antigo apenas para produzir oráculos
de desenvolvimento, sem modificar o Phaser. JSONs versionados alimentam
`tests/native_parity_test.gd`; a execução dos testes Godot não precisa de Node.
Nenhum módulo GDScript chama JavaScript para calcular combate.

4.318 verificações passando: 1.200 resultados de dano e respectivas mutações,
512 combinações de input/olhar, 200 varreduras, limiares de qualidade, as 38
entradas de golpes, todos os quadros dos atlas, buffer, round/KO e pulso fixo.
A POC mantém suas 21 verificações anteriores. Isto valida a fundação, não o
Corredor, IA, clinch, efeitos ou a integração completa ainda pendentes.


## Atualização 28/10/2026 (tarde) — duelo e corredor nativos

| Sistema | Estado Godot |
| --- | --- |
| Duelo: estados, combos, varredura, aparo, grogue, chão, arremesso em par, clinch, pé de apoio, empurrão | `scripts/duel/duel.gd` e módulos; 9 replays do Phaser (6.231 ticks) batem tick a tick |
| IA calmo/firme/difícil | `scripts/duel/ai.gd`; mesmas entradas que a IA do Phaser em todos os replays de IA |
| Corredor: profundidade, dois manequins, carregar no golpe, clinch, ragdoll, aparo, modos | `scripts/corridor/`; 6 replays (14.400 quadros, Sorriso e Miguel, três modos) batem |
| Cena do duelo, seleção, HUD, partida, pausa, fim, revanche | `scripts/game/duel_game.gd` |
| Cena do corredor, HUD, barras dos alvos, sangue nas mãos, Miguel parado | `scripts/game/corridor_game.gd` |
| Sangue, marcas, feridas, faíscas, poeira, tremida, clarão, câmera lenta, aparo azul | `scripts/game/blood.gd`, `impact_fx.gd` |
| Som de golpe, defesa, aparo e passada | `scripts/game/combat_audio.gd` (gerado no jogo) |
| Teclado, controle de videogame, multitoque | `duel_game.gd`, `corridor_game.gd`, `touch_pad.gd` |
| Preferências | `user://gaviao.cfg` |

Melhor que no Phaser: rival recolorido por shader; controle de videogame; HUD
numa faixa própria (não cobre a luta); retrato com o mundo mais perto e os botões
no piso; botões que crescem com a tela.

Ainda não portado: seletor de pose do Miguel parado no corredor (fica no idle),
modo de depuração extra do corredor (`window.gaviao`) e o leiaute HTML do Phaser
(menus fora do canvas). Exportação Android/PC não foi testada.

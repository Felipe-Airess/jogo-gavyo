# Level design — capítulo 1

Processo das skills `level-design`, `godot-genre-horror` e `godot-genre-stealth`:
métricas → rotas e ritmo → encontros → estrutura → testes → decoração.
O desenho de Felipe (`docs/referencias/mapa-escola-felipe.png`) define o que liga
com o quê. As fotos (`docs/referencias/escola-fotos/`) definem a aparência.

**Desde 02/11 (parte 3) a estrutura está em texto**: `godot-3d/capitulo1/mapa/terreo.txt`
e `superior.txt` (1 caractere = 1 m), com paredes, portas, coberturas (`%`),
esconderijos (`&`), postos (`1–4`) e pontos da história. Rotas, gargalos e pontos de
roteiro ficam em `godot-3d/capitulo1/nivel.gd`, em células (coluna, linha).
Testes: `tests/capitulo1_nivel_test.gd` e `tests/capitulo1_mapa_test.gd`.
Planta de cima: `docs/verificacao-20261102/mapa-grade/planta.png`.

## Métricas (do próprio controlador e da IA)

| Medida | Valor |
|---|---|
| Escala | 1 m por caractere da grade (sala de aula ~8×7 m, eixo a eixo) |
| Andar / correr / agachado | 1,45 / 3,8 / 1,05 m/s |
| Cápsula de Miguel | raio 0,27 m, altura 1,64 m |
| Câmera de ombro | 2,1 m atrás |
| Visão do cultista | 10,5 m, cone ±66° |
| Visão do perseguidor | 19 m |
| Ruído de corrida | 7 m |
| Visão do ritual (em transe) | 7,5 m, lenta; agachado ×0,3; sombra da escada ×0,35 |
| Vão de porta | 1,56 m (peça de porta de 2 m, `DD`) |

Regras derivadas:
- corredor com pelo menos 2,4 m;
- cobertura a cada ~5 m (metade da visão) em trecho vigiado;
- esconderijo a até 10 m de cada posto de cultista.

## Topologia (decisões de Felipe)

- Miguel acorda na sala de materiais de esportes, que dá no refeitório.
- O auditório é um palco elevado no refeitório; a porta da biblioteca fica logo atrás.
- De frente para o pátio aberto ficam a biblioteca, o lab de matemática e o Informática 1.
- Os labs de Informática 1 e 2 e o lab de hardware abrem para o pátio aberto.
- O corredorzinho entre o hardware e a coordenação leva a 2 e 1 Contabilidade.
- A escada fica no pátio de química, em caixa fechada, e não sai da quadra. O
  pátio de química é coberto e é onde acontece o ritual.
- Do refeitório parte a passagem estreita até o portão 1.
- Pátio aberto e refeitório são uma área só, separados por um relevo baixo no chão
  (sem parede). Pátio de concreto, com calçada coberta junto às salas.
- Palco do auditório elevado (0,8 m), porta da biblioteca logo ao lado.
- Paredes verdes ou amarelas (inclusive no pátio de química) na fase de decoração.

## Rotas até o pátio de química

| Rota | Caminho | Guarda | Cobertura |
|---|---|---|---|
| Norte (furtiva) | varanda norte do pátio aberto → passagem entre o lab de química e o Informática 1 → estacionamento → corredor aberto | postos 3 (lab de química) e 4 (estacionamento) | bicicletários (`%`), colunas, armário |
| Sul (longa) | varanda oeste → corredorzinho → frente de 2/1 Contabilidade → rampa → corredor aberto | postos 1 (rampa, primeiro cultista) e 2 (corredor aberto) | blocos baixos, armários |
| Volta (nova) | refeitório → passagem do portão → corredor sul | — | mesas do refeitório |

O teste prova que cada rota funciona com a outra bloqueada.

## Ritmo (dente de serra)

| Zona | O que acontece | Intensidade |
|---|---|---|
| Sala de esportes | ensina a mover e a abrir porta | 0,10 |
| Refeitório | barulho atrás; esconderijo | 0,25 |
| Pátio aberto | luzes falham; primeiro cultista visto; dica de agachar | 0,40 |
| Rotas norte/sul | furtividade com guarda e cobertura | 0,60 |
| Pátio de química | atravessar o ritual agachado | 0,80 |
| Caixa da escada | abrigo (checkpoint na volta) | 0,20 |
| Andar superior | bolsa (checkpoint) | 0,15 |
| Entrada da escada | espiar e gravar | 0,85 |
| Passagem do portão | fuga se alertado | 1,00 |
| Fora | final | 0 |

## Guia visual

- **Marco:** mangueira grande no centro do pátio aberto, com banco em volta.
- **Varandas:** cobertas, com colunas, na frente dos blocos. Fazem linhas que levam às rotas e dão sombra.
- **Luz:** amarela nas duas rotas e o resto no escuro. As velas do ritual são a luz vermelha do pico.

## O que os testes cobrem e o que não cobrem

- `capitulo1_nivel_test.gd`: alcance das duas rotas, gargalos, esconderijo por
  posto, cobertura nos trechos vigiados, ritmo.
- `testar-percurso.sh`, em três modos:
  - rota (mapa e fluxo);
  - `--patio` (passagem pelo ritual agachado; suspeita máxima 0,80);
  - `--furtivo` (todos ativos, rota norte agachado). No furtivo, o robô passou
    pelo primeiro cultista e pelo estacionamento sem alerta. O guarda do lab de
    química saiu para investigar um ruído e bloqueou o robô, que não sabe desviar
    de quem se move. É comportamento correto da IA, não erro do mapa.
- Nada disso substitui Felipe jogando: legibilidade, medo e diversão só se avaliam jogando.

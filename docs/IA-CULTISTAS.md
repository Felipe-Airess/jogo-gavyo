# IA dos cultistas — percepção (05/11/2026, Claude)

Felipe relatou que os cultistas enxergavam o Miguel fácil demais.

## O que estava errado

1. **Detecção instantânea:** um único quadro de linha de visão já virava 100% de
   suspeita, e em 0,4 s o cultista gritava e corria.
2. **Cone largo e uniforme:** ~66° de cada lado, com o mesmo peso no centro e
   no canto do olho.
3. **Luz ignorada:** no breu ele via a 10,5 m como se fosse dia.
4. **Lanterna:** qualquer cultista a 14 m via o Miguel, inclusive de costas.
5. **Um ponto só:** a visão mirava um único ponto do corpo.

## Como funciona agora (`godot-3d/capitulo1/percepcao.gd`)

Um medidor gradual (padrão Splinter Cell/Thief). A suspeita sobe por segundo
com o produto de:

- **Exposição:** 3 raios (pés, peito, cabeça); cobertura parcial esconde parte.
- **Campo de visão:** cone central de 35° com peso 1; periferia até 70° com peso
  0,35 e só até 6,6 m; atrás, só sente colado (1,3 m).
- **Distância:** alcance de 12 m (perseguidor 18 m), mais rápido de perto.
- **Luz sobre Miguel:** lâmpadas que o alcançam sem parede no meio; lanterna
  ligada soma 0,55. Na sombra o peso cai para 0,35.
- **Postura:** parado 0,7, andando 1, correndo 1,6; agachado multiplica por 0,45.
- **Barulho:** correr é ouvido a 7 m, andar a 2,2 m, agachado não faz som;
  parede abafa.

Sem estímulo, a suspeita fica parada por 1,2 s e depois cai 0,22/s. A partir de
35%, o cultista vai até o ponto suspeito devagar ("?"). Em 100% ele vê de vez:
grita e caça, como antes. Quem já está caçando continua rastreando pelo cone.

HUD: abaixo da barra de vigilância aparece **◐ na sombra / ◑ meia-luz / ● na luz**.

## Tempos para ser percebido (olhando de frente, sem parar de ver)

| Situação | 3 m escuro | 3 m luz | 6 m escuro | 6 m luz | 10 m escuro | 10 m luz |
|---|---|---|---|---|---|---|
| de pé parado | 3,3 s | 1,4 s | 4,3 s | 1,8 s | 7,1 s | 3,0 s |
| andando | 2,3 s | 1,0 s | 3,0 s | 1,3 s | 5,0 s | 2,1 s |
| correndo | 1,4 s | 0,6 s | 1,9 s | 0,8 s | 3,1 s | 1,3 s |
| agachado parado | 7,3 s | 3,1 s | 9,5 s | 4,1 s | 15,8 s | 6,8 s |
| agachado andando | 5,1 s | 2,2 s | 6,6 s | 2,8 s | 11,1 s | 4,7 s |

Pelo canto do olho, o tempo fica ~3 vezes maior. Para ajustar a dificuldade,
mexa nas constantes no topo de `percepcao.gd` (`TAXA`, `ALCANCE`, cones).

Testes: `tests/capitulo1_percepcao_test.gd` (10) e `capitulo1_caca_test.gd`
atualizado (percepção gradual em vez de instantânea).

## Próximo passo combinado

Iluminação: com a luz contando na IA, as poças de luz viram as áreas perigosas e
o escuro vira abrigo. A iluminação precisa ser desenhada para isso.

# Desempenho — investigação de 05/11/2026 (Claude)

Felipe relatou travamento no navegador, pior olhando o pátio de química.

## Como foi medido

A build web rodou no Chromium daqui (Playwright, SwiftShader) com os comandos
WebGL contados por quadro (`scripts/medir-webgl.js`). Foi feito um teste
desligando uma coisa por vez.

| Teste (sala inicial) | Desenhos/quadro | Comandos WebGL/quadro |
|---|---:|---:|
| Normal (antes) | 1.624 | 30.029 |
| Sem luzes | 1.624 | 28.591 |
| Sem personagens | 1.504 | 27.902 |
| Sem objetos soltos | 1.108 | 24.659 |
| Sem GridMap | 598 | 7.241 |
| **Depois das correções** | **404** | **4.886** |

O medidor interno do Godot mostrava só ~376 desenhos e escondia o problema.

## Causas e correções

1. **GridMap** (paredes, pisos, telhados): desenhava cada tipo de peça em
   cada octante, ~1000 desenhos e 23 mil comandos por quadro, mesmo dentro de
   uma sala. Agora `escola_grade.gd::_mesclar_visual()` junta as peças em 187
   malhas (blocos de 16 m × material). Os GridMaps ficam com os dados,
   invisíveis. A colisão não muda.
2. **Objetos soltos** (~350): eram desenhados mesmo longe, escondidos pela
   neblina. `limitar_alcance()` corta a 30 m.
3. **Esferas com detalhe padrão** (10 chamas de vela no ritual, 39 maçanetas):
   ~4 mil triângulos cada. Agora usam 6×3 e 8×4 segmentos.
4. **Personagens**: versões leves de ~7 mil triângulos (`<id>_leve.fbx`).
5. **F8** mostra FPS, desenhos e triângulos na tela.

## Descartado (medido)

- Scripts: ~2 ms por quadro no nativo.
- Erros repetidos no log: nenhum.
- Sombras: todas desligadas.
- As 46 luzes: quase sem efeito.
- Neblina.
- Filtro retrô: o 3D é desenhado em 300×200 e o shader é leve.
- Áudio: 15 players, 2 tocando.
- Física: 0,2 ms.
- Compilação de shader: sem picos repetidos.

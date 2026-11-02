# Mapa do capítulo 1 em grade de texto

Estado: **bloqueio cinza aguardando aprovação de Felipe.** Nada de decoração
(materiais das fotos, móveis, placas, vegetação detalhada) até ele aprovar.

## Arquivos

| Arquivo | O que é |
|---|---|
| `terreo.txt` | Térreo. 1 caractere = 1 metro. Coluna = x (oeste→leste), linha = z (norte→sul). |
| `superior.txt` | Andar de cima, mesma grade, 3,4 m acima. |
| `grade.gd` | Lê o texto e responde perguntas (salas, portas, escada). |
| `kit.gd` | Kit modular cinza: peças de 2 m (e meias de 1 m para completar). |
| `kit_blockout.meshlib` | O kit salvo como MeshLibrary (abrir no editor). Regerar: `godot --headless --path godot-3d --script res://tools/gerar_kit.gd`. |
| `escola_grade.gd` | Monta a escola: GridMap (pisos, estrutura, telhados), colisão, portas, escada, armários, pontos da história. |

A legenda completa está no topo de cada `.txt`. Resumo:

```
#  parede        -  mureta       D  porta (sempre DD)   W  janela gradeada
O  vão com verga G  portão       C  coluna              T  árvore
%  bloco baixo   L  lâmpada      =  relevo no chão (8 cm)   < > ^ v  escada (seta = sobe)
.  azulejo coberto  ;  cimento coberto  ,  céu aberto  :  quadra  _  palco
@  acorda   $  bolsa   *  ritual   +  checkpoint 2   &  armário   1–4  postos
```

Letras listadas na legenda (`sala x Nome`, `area X Nome`) dão nome ao ambiente
em que estão.

## Como mudar o mapa

1. Edite o `.txt` (fonte monoespaçada). Mover uma parede é trocar caracteres.
2. Rode os testes e a planta:

```bash
export GODOT=/caminho/para/Godot_v4.5.1   # no Mac: o binário dentro do .app
bash scripts/testar-capitulo1.sh
"$GODOT" --headless --path godot-3d --script res://tools/exportar_planta.gd -- /tmp/planta.json
python3 scripts/desenhar-planta.py /tmp/planta.json /tmp/planta.png
# Linux sem tela: prefixe com xvfb-run -a
"$GODOT" --path godot-3d --script res://tools/capturar_vistas.gd -- /tmp/vistas v
```

O teste `tests/capitulo1_mapa_test.gd` acusa porta ímpar, letra repetida,
buraco no perímetro, sala sem acesso, parede sem colisão. Avisos de montagem
aparecem na planta em vermelho.

Pontos de roteiro e de teste que não são marcas do texto (entrada da escada,
patamar, sustos, itens, ferramentas) ficam em `capitulo1/nivel.gd`, também em
células (coluna, linha).

## Como a montagem funciona

- **Paredes finas** (0,2 m) no eixo da célula, ligadas aos vizinhos: reta de
  2 m, reta de 1 m, canto, T, cruz, ponta. A sala é medida de eixo a eixo de
  parede.
- **Pisos e telhados** em placas de 2×2 m; 1×1 m só onde a placa não cabe.
- Três GridMaps (pisos, estrutura, telhados): o GridMap guarda uma peça por
  célula, e uma parede apagaria a placa de piso que começa na mesma célula.
- **Colisão** gerada da mesma grade, em caixas mescladas (~345). A IA monta as
  rotas a partir dessas caixas. O kit salvo também tem colisão por peça, para uso
  no editor.
- **Escada**: rampa física contínua sob 20 degraus do kit, da seta mais baixa
  à mais alta, encostada nas paredes laterais.
- **Portas**: folha articulada da revisão 2, abre para dentro da sala com
  nome; placa com o nome por fora.

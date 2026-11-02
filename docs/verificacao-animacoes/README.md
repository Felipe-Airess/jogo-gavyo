# Verificação visual — 02/11/2026

Godot 4.5.1 Compatibility, OpenGL. Foram capturados 189 quadros reais do jogo,
um a cada 0,1 s, em nove sequências laterais de 2 s. Os PNG individuais têm
640 × 400; as folhas agrupam dez imagens. [Manifesto](manifesto.json) registra
estado, clipe, relógio, escala e posição física por quadro.

## Regra de implementação

Clipes de locomoção não recebem nenhuma escrita de pose ou trilha. O controlador
somente escolhe o clipe, configura TimeScale e solicita travel no AnimationTree.
Crossfade de 0,15 s entre estados planos e 0,22 s nas ações/escadas.
Também foram retiradas correções externas de braços, ferimentos e postura
quando uma locomoção participa da mistura.

O passo é medido no recurso original por cinemática direta, sem mover ossos.
Taxa = velocidade horizontal real / (passo / duração). No plano: andar 1,45 m/s,
correr 3,8 m/s, agachado 1,05 m/s. Nas capturas isso produz aproximadamente
1,52x, 1,09x e 1,65x, respectivamente. Nas escadas o corpo também respeita o
ritmo máximo do clipe: subida até 1,8x e descida até 1,6x. Com os passos nativos
isso dá aproximadamente 0,59 m/s subindo andando, 1,08 m/s subindo correndo e
0,45 m/s descendo. Não se reutiliza a passada artificial da versão anterior.

Descending_Stairs permanece inteiro e sem loop no recurso original. Dois estados
com o mesmo clipe fazem crossfade de 0,22 s entre repetições. Nenhuma chave é
cortada ou reamostrada. A esquiva continua desativada.

## Imagens examinadas

| Sequência | Clipe | Quadros laterais |
| --- | --- | --- |
| andando | Walk | [0–0,9 s](andando/contato-00.png) · [1–1,9 s](andando/contato-01.png) · [2 s](andando/0020.png) |
| correndo | Sprint | [0–0,9 s](correndo/contato-00.png) · [1–1,9 s](correndo/contato-01.png) · [2 s](correndo/0020.png) |
| parando | Sprint → Idle | [0–0,9 s](parando/contato-00.png) · [1–1,9 s](parando/contato-01.png) · [2 s](parando/0020.png) |
| agachando | Idle → Crouch_Idle | [0–0,9 s](agachando/contato-00.png) · [1–1,9 s](agachando/contato-01.png) · [2 s](agachando/0020.png) |
| agachado-andando | Crouch_Fwd | [0–0,9 s](agachado-andando/contato-00.png) · [1–1,9 s](agachado-andando/contato-01.png) · [2 s](agachado-andando/0020.png) |
| escada-subindo | Ascending_Stairs | [0–0,9 s](escada-subindo/contato-00.png) · [1–1,9 s](escada-subindo/contato-01.png) · [2 s](escada-subindo/0020.png) |
| escada-subindo-correndo | Running_Up_Stairs | [0–0,9 s](escada-subindo-correndo/contato-00.png) · [1–1,9 s](escada-subindo-correndo/contato-01.png) · [2 s](escada-subindo-correndo/0020.png) |
| escada-descendo | Descending_Stairs | [0–0,9 s](escada-descendo/contato-00.png) · [1–1,9 s](escada-descendo/contato-01.png) · [2 s](escada-descendo/0020.png) |
| escada-descendo-correndo | Descending_Stairs, limitado a 1,6x | [0–0,9 s](escada-descendo-correndo/contato-00.png) · [1–1,9 s](escada-descendo-correndo/contato-01.png) · [2 s](escada-descendo-correndo/0020.png) |

Inspeção das folhas: na caminhada os pés alternam e os joelhos flexionam para
a frente; na corrida há inclinação do tronco, balanço dos braços e fases aéreas.
Na parada a pose passa pela mistura até Idle. Ao agachar, os joelhos dobram
conforme o clipe baixo original; a caminhada agachada mantém essa postura.
Nas subidas os joelhos levantam alternadamente; Running_Up_Stairs mantém a
postura de corrida. Nas descidas o clipe original é bastante flexionado.
Não observei torções de pés nem as pernas em tesoura da gravação nas vistas
laterais examinadas. Oclusão entre as pernas na projeção lateral não é medida
de separação tridimensional; a comparação de todos os ossos com o recurso
original complementa a inspeção.

**Limitação visível:** ainda há deslizamento e pés flutuando/entrando em alguns
degraus, sobretudo na descida. Não há garantia de apoio fixo a 3 cm. Isso gera
aviso e não dispara IK, deslocamento de quadril ou rotação de pés.

## Câmera

[Antes: cultista cobre a lente](camera/antes.png) ·
[Depois: Miguel visível](camera/depois.png).

A consulta de colisão usa somente a camada 1 (mundo). Um NPC cujo eixo corporal
fica a menos de 0,85 m da lente tem o modelo ocultado; sua física permanece.
A visibilidade anterior é restaurada quando sai dessa área. Closes dirigidos
preservam o enquadramento narrativo; Miguel continua oculto em primeira pessoa.

## Reprodução

Na raiz do projeto:

```bash
work/ferramentas/godot/Godot.app/Contents/MacOS/Godot --path godot-3d --script res://tools/capturar_animacoes_originais.gd
bash scripts/testar-capitulo1.sh
bash scripts/testar-percurso.sh
```

A ferramenta dirige o ator real com input e ticks físicos. Para enxergar as
pernas, usa câmera lateral, iluminação neutra e oculta paredes/teto somente da
câmera de inspeção. Usa a malha e a colisão reais da escada; no plano usa piso
isolado. Isso não altera a iluminação nem as poses do jogo.

Os testes leem poses, relógios e clipes; não escrevem ossos. A comparação fora
da mistura cobre todos os ossos de Miguel/cultista contra a interpolação do
recurso original. Na fronteira de loop, o mixer pode apresentar a última chave
com relógio zero: aceitam-se os dois extremos originais, sem corrigir a pose.
Durante o crossfade da descida, o relógio do destino pode ficar em zero enquanto
o peso e a pose avançam; a medição considera esse avanço real.

APIs conferidas na documentação da versão exata e executadas em 4.5.1:
[AnimationNodeStateMachineTransition](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/AnimationNodeStateMachineTransition.xml),
[AnimationNodeAnimation](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/AnimationNodeAnimation.xml),
[PhysicsShapeQueryParameters3D](https://raw.githubusercontent.com/godotengine/godot/4.5.1-stable/doc/classes/PhysicsShapeQueryParameters3D.xml).
O auxiliar privado de busca percorre get_transition_count/get_transition_from/
get_transition_to; não usa a API inexistente find_transition.


### Saídas desta revisão

```text
CAPITULO1_MOVIMENTO: 33 passed, 0 failed
CAPITULO1_ANIMACAO: 70 passed, 0 failed
CAPITULO1_TEST: 41 passed, 0 failed
CAPITULO1_MAPA: 18 passed, 0 failed
CAPITULO1_NIVEL: 10 passed, 0 failed
CAPITULO1_PERCURSO[rota]: 7 passed, 0 failed
```

Saídas completas: [capítulo](testar-capitulo1.txt) e
[percurso](testar-percurso.txt). A contagem de animação
mudou porque apoio fixo/encaixe artificial viraram avisos e a expectativa de
loop gerado foi substituída pelo recurso original intacto.

Na medição aproximada de apoio, a deriva máxima ficou entre 0,105 e 0,171 m
no plano. Esse detector inclui uma faixa de altura em torno do chão; não
comprova pé plantado exato. A amplitude máxima quadro a quadro medida nas
trocas foi 0,163 m. Ambos são publicados como avisos, sem truncar movimentos.

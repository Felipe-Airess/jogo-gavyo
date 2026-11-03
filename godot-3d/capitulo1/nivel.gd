extends RefCounted
## Level design do capítulo 1 como dado (skills level-design, godot-genre-horror,
## godot-genre-stealth). A ESTRUTURA está na grade em texto
## (capitulo1/mapa/terreo.txt e superior.txt): paredes, portas, esconderijos (&),
## coberturas (%), postos (1–7, 8 condicional) e pontos da história (@ $ * + G).
## Aqui ficam métricas, ritmo, rotas e pontos de roteiro, em células da grade
## (coluna, linha); escola.cel(c, r) converte para o mundo.
##
## Processo: métricas do controlador -> rotas e ritmo -> encontros -> estrutura
## (bloqueio cinza) -> aprovação de Felipe -> decoração.

## Métricas: as mesmas constantes do controlador e da IA.
const WALK:=1.45
const RUN:=3.8
const CROUCH:=1.05
const CAPSULE_RADIUS:=.27
const CAMERA_BACK:=2.1
const GUARD_SIGHT:=10.5
const RUN_NOISE:=7.0
## Derivadas.
const MIN_CORRIDOR:=2.4                 # cápsula + câmera de ombro sem raspar
const COVER_SPACING:=GUARD_SIGHT*.5     # cobertura a cada ~5 m em zona vigiada
const HIDE_NEAR_GUARD:=10.0             # esconderijo ao alcance de cada posto

## Ritmo (dente de serra): intensidade sobe com respiros antes de cada pico.
const BEATS:=[
 {"zona":"sala de esportes","tipo":"ensinar: mover, porta","intensidade":.10},
 {"zona":"refeitório e palco","tipo":"inquietação: barulho atrás; ensinar esconder","intensidade":.25},
 {"zona":"pátio aberto","tipo":"inquietação: luzes falham; primeiro cultista visto","intensidade":.40},
 {"zona":"rota norte / rota sul","tipo":"teste: furtividade com guarda e cobertura","intensidade":.60},
 {"zona":"pátio de química","tipo":"pico: atravessar o ritual agachado","intensidade":.80},
 {"zona":"caixa da escada","tipo":"respiro: abrigo, sem visão do pátio","intensidade":.20},
 {"zona":"andar superior","tipo":"respiro: bolsa, checkpoint","intensidade":.15},
 {"zona":"entrada da escada","tipo":"pico: espiar e gravar","intensidade":.85},
 {"zona":"passagem do portão","tipo":"clímax: fuga se alertado","intensidade":1.0},
 {"zona":"fora da escola","tipo":"alívio: final","intensidade":.0},
]

## Rotas do pátio aberto até a entrada do pátio de química (células).
## Norte: varanda norte -> passagem entre lab. de química e Informática 1 ->
## estacionamento -> corredor aberto. Sul: corredorzinho -> frente de 2/1
## Contabilidade -> rampa -> corredor aberto. (Há ainda a volta pelo refeitório
## e pela passagem do portão, que cai no mesmo corredor sul.)
const ROUTE_NORTH:=[Vector2(62,20),Vector2(54,16),Vector2(49,14),Vector2(43,13),Vector2(39,12)]
const ROUTE_SOUTH:=[Vector2(62,30),Vector2(54,33),Vector2(54,38),Vector2(54,41),Vector2(45,41),Vector2(39,41),Vector2(39,27),Vector2(39,12)]
## Gargalos (células) para provar que uma rota não depende da outra.
const CHOKE_NORTH:=Rect2i(47,12,6,5)
const CHOKE_SOUTH:=Rect2i(53,35,3,5)

## Pontos de roteiro e de teste (célula, andar).
const PONTOS:={
 "entrada_escada":[Vector2(32,10),0],     # pátio de química, diante do vão da caixa
 "espiar":[Vector2(29,10),0],             # dentro da caixa, no vão: espia o ritual
 "patamar":[Vector2(21,10),1],
 "corredor_superior":[Vector2(21,12),1],
 "frente_3_informatica":[Vector2(16.5,12),1],   # eixo da porta DD (16–17)
 "dentro_3_informatica":[Vector2(16.5,9),1],
 "mesa_da_bolsa":[Vector2(15,8),1],
 "gravar":[Vector2(37,10),0],             # passagem sul do pátio de química
 "vao_do_patio":[Vector2(38,11),0],       # vão para o corredor aberto
 "patio_aberto":[Vector2(70,27),0],
 "corredor_aberto":[Vector2(39,27),0],
 "saida":[Vector2(60,65),0],
 "passagem_portao":[Vector2(78,63),0],
 "refeitorio":[Vector2(90,23),0],
 "avistamento":[Vector2(53,41),0],       # vê o primeiro cultista entrar no corredor
 "susto":[Vector2(38,28),0],             # silhueta (avança 1 célula por morte)
 "silhueta":[Vector2(38,17),0],
 "batida_metal":[Vector2(84,25),0],
 "batida_luzes":[Vector2(65,25),0],
 "batida_passos":[Vector2(57,41),0],
}

## Itens sobre blocos (%) ou sobre a mesa da bolsa ($): [tipo, célula, andar].
const ITENS:=[
 ["empanado",Vector2(80,21),0],
 ["empanado",Vector2(47,34),0],
 ["empanado",Vector2(13,6),1],
 ["faca",Vector2(91,37),0],
]

## Ferramentas (sobre bloco) e usos: [nome, célula, andar].
const FERRAMENTAS:=[["chave de fenda",Vector2(47,33),0],["alicate",Vector2(44,6),0],["régua",Vector2(65,11),0]]
## [uso, ferramenta, célula, altura em m, deslocamento em m].
const USOS:=[
 ["luminária","chave de fenda",Vector2(37,27),1.2,Vector3(.27,0,0)],
 ["caixa de materiais","alicate",Vector2(49,37),.175,Vector3.ZERO],
 ["livros altos","régua",Vector2(88,9),1.95,Vector3.ZERO],
]
## Objetos arremessáveis no chão.
const OBJETOS:=[Vector2(54,39),Vector2(38,30),Vector2(86,31)]

static func ponto(escola: Node3D,nome: String,altura:=0.0) -> Vector3:
 var dado: Array=PONTOS[nome]
 return escola.cel(dado[0].x,dado[0].y,dado[1]*escola.LEVEL+altura)

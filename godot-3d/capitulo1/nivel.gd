extends RefCounted
## Level design do capítulo 1 como dado (skills level-design, godot-genre-horror,
## godot-genre-stealth). Coordenadas no referencial do desenho de Felipe (px),
## convertidas por escola.p(); escala real 0,12 m/px.
##
## Processo: métricas do controlador -> rotas e ritmo -> encontros -> estrutura
## (bloqueio) -> testes (tests/capitulo1_nivel_test.gd) -> decoração.

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

## Rotas do pátio aberto até a entrada do pátio de química. Duas escolhas para a
## furtividade (stealth: nunca um único caminho vigiado).
const ROUTE_NORTH:=[Vector2(520,120),Vector2(450,100),Vector2(414,80),Vector2(370,78),Vector2(324,80)]
const ROUTE_SOUTH:=[Vector2(520,240),Vector2(450,280),Vector2(450,320),Vector2(380,320),Vector2(325,320),Vector2(325,200),Vector2(324,80)]
## Gargalos de cada rota (para provar que uma não depende da outra).
const CHOKE_NORTH:=Rect2(392,66,44,24)
const CHOKE_SOUTH:=Rect2(436,268,30,26)

## Postos dos cultistas (game.gd usa estes pontos).
const GUARD_POSTS:=[Vector2(322,320),Vector2(323,190),Vector2(378,52),Vector2(362,140)]

static func build(school: Node3D) -> void:
 _verandas(school)
 _parking_cover(school)
 _open_corridor_cover(school)
 _landmark(school)
 _guide_lights(school)
 # Esconderijo junto ao posto do laboratório de química (rota norte).
 school.locker(school.p(397,74),Vector3.RIGHT)

## Varandas cobertas com colunas na frente das salas (fotos 5 e 6): sombra,
## cobertura e linhas que guiam o olhar.
static func _verandas(s: Node3D) -> void:
 # Norte do pátio aberto: Informática 1, lab. de matemática, biblioteca.
 _veranda(s,Vector2(440,92),Vector2(630,92),3.0,Vector3.BACK)
 # Oeste do pátio aberto: labs de informática e hardware.
 _veranda(s,Vector2(435,110),Vector2(435,262),3.0,Vector3.RIGHT)
 # Frente de 2 e 1 Contabilidade (fim do corredorzinho).
 _veranda(s,Vector2(440,335),Vector2(572,335),2.6,Vector3.FORWARD)
 # Frente do bloco de enfermagem, voltada ao corredor aberto.
 _veranda(s,Vector2(305,100),Vector2(305,300),2.6,Vector3.RIGHT)

static func _veranda(s: Node3D,a: Vector2,b: Vector2,depth: float,out: Vector3) -> void:
 var pa: Vector3=s.p(a.x,a.y); var pb: Vector3=s.p(b.x,b.y)
 var length:=pa.distance_to(pb)
 var along:=(pb-pa).normalized()
 var mid:=(pa+pb)*.5+out*depth*.5
 var roof=s.box(Vector3(depth if absf(along.z)>.5 else length,.12,length if absf(along.z)>.5 else depth),mid+Vector3.UP*3.0,"telha",false)
 var count:=maxi(2,int(length/3.6))
 for i in count+1:
  var at:=pa+along*length*float(i)/count+out*(depth-.25)
  s.box(Vector3(.32,2.95,.32),at+Vector3.UP*1.475,"wall")
  s.box(Vector3(.34,1.1,.34),at+Vector3.UP*.55,"azulejo",false)

## Estacionamento de bicicletas: fileiras baixas (cobertura agachado, ~1 m).
static func _parking_cover(s: Node3D) -> void:
 for z in [118,160,202,244]:
  var at: Vector3=s.p(366,z)
  s.box(Vector3(.5,.95,2.6),at+Vector3.UP*.475,"metal")
  for i in 5:
   var wheel=s.box(Vector3(.06,.62,.62),at+Vector3(.32,.35,-1.0+i*.5),"dark",false)

## Corredor aberto: bebedouro, lixeiras e banco a cada ~5 m (cobertura).
static func _open_corridor_cover(s: Node3D) -> void:
 var props:=[["bebedouro",Vector2(338,120),Vector3(.6,1.05,.5)],["lixeira",Vector2(340,170),Vector3(.55,.9,.55)],
  ["banco",Vector2(338,215),Vector3(.5,.5,1.8)],["lixeira",Vector2(340,262),Vector3(.55,.9,.55)],
  ["banco",Vector2(338,300),Vector3(.5,.5,1.8)]]
 for prop in props:
  var at: Vector3=s.p(prop[1].x,prop[1].y)
  s.box(prop[2],at+Vector3.UP*prop[2].y*.5,"metal" if prop[0]!="banco" else "wood")

## Marco visual no pátio aberto: mangueira grande no centro (orienta de longe).
static func _landmark(s: Node3D) -> void:
 var at: Vector3=s.p(534,185)
 s.box(Vector3(.7,4.2,.7),at+Vector3.UP*2.1,"trunk")
 s.box(Vector3(6.5,2.6,6.5),at+Vector3.UP*5.2,"leaves",false)
 s.box(Vector3(4.2,1.8,4.2),at+Vector3.UP*6.7,"leaves",false)
 for i in 6:
  var a:=float(i)*TAU/6
  s.box(Vector3(1.6,.45,.4),at+Vector3(sin(a)*1.6,.22,cos(a)*1.6),"wood").rotation.y=a

## Luz-guia: amarela nas duas rotas; o resto fica no escuro.
static func _guide_lights(s: Node3D) -> void:
 for at in [Vector2(414,82),Vector2(370,82),Vector2(450,300),Vector2(380,322)]:
  s._lamp(s.p(at.x,at.y,2.9),Color(.95,.78,.5),6,.65)

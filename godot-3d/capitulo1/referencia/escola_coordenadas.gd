extends "res://prototipo/school.gd"
## REFERÊNCIA (02/11/2026): escola anterior, gerada por coordenadas soltas.
## Não é mais carregada pelo jogo; o mapa atual vem de capitulo1/mapa/.
## Planta derivada do desenho de Felipe. Metros propostos; relações preservadas.
## Metros por pixel do desenho de Felipe. 0,12 = tamanho real (sala ~8×6 m);
## era 0,085 e o mapa ficava pequeno demais.
const SCALE := .12
const LEVEL := 3.4
const MERGE_CELL := 12.0
var rooms: Dictionary={}
var bag: Node3D
var ritual_center: Vector3
var bag_at: Vector3
var spawn: Vector3
var gate_at: Vector3
var stairs_bottom: Vector3
var stairs_top: Vector3
var ritual_approach: Vector3
var first_cultist: Vector3
var ritual_figures: Array[Node3D]=[]
var paper: StandardMaterial3D
var fixtures: Array[Node3D]=[]
var hawk: Node3D
var flicker: OmniLight3D

func p(x: float,z: float,y:=0.0) -> Vector3:
 return Vector3((x-440)*SCALE,y,(z-300)*SCALE)

func box(size: Vector3,at: Vector3,kind: String,solid:=true) -> Node3D:
 var node=super.box(size,at,kind,solid)
 node.set_meta("kind",kind)
 return node

func build(owner_game: Node3D) -> void:
 game=owner_game
 # Paleta das fotos de Felipe (docs/referencias/escola-fotos): parede
 # amarelo-esverdeada clara, azulejo branco, quadra verde com faixa vermelha,
 # grades verdes, banco de madeira vermelho, armários brancos.
 for data in [["floor",Color(.33,.35,.34)],["wall",Color(.72,.74,.54)],
  ["tile",Color(.20,.35,.30)],["wood",Color(.28,.19,.12)],
  ["metal",Color(.21,.26,.26)],["dark",Color(.035,.044,.055)],
  ["paper",Color(.66,.64,.50)],["red",Color(.28,.015,.025)],
  ["green",Color(.10,.22,.13)],["court",Color(.12,.36,.27)],
  ["court_red",Color(.55,.24,.22)],["line",Color(.85,.86,.82)],
  ["grade",Color(.16,.42,.30)],["stool",Color(.50,.08,.07)],
  ["cabinet",Color(.80,.80,.76)],["chair",Color(.12,.30,.55)],
  ["cardboard",Color(.55,.40,.24)],["concrete",Color(.62,.62,.60)],
  ["patio_green",Color(.04,.40,.31)],["telha",Color(.50,.24,.15)],
  ["column_green",Color(.30,.62,.22)],["sofa",Color(.045,.05,.05)],
  ["plastic",Color(.86,.86,.83)],["extintor",Color(.62,.06,.05)],
  ["lime",Color(.42,.72,.20)],["teal",Color(.30,.75,.68)],
  ["orange",Color(.85,.40,.08)],["sign_green",Color(.10,.48,.22)],
  ["walk_green",Color(.20,.42,.30)],["trunk",Color(.22,.17,.13)],
  ["leaves",Color(.18,.38,.14)],["car",Color(.62,.64,.66)]]:
  mats[data[0]]=material(data[1])
 mats["grade_bars"]=_pattern_material(Color(.16,.45,.30),8,1,2,0)
 mats["rede"]=_pattern_material(Color(.75,.75,.72),12,12,1,1)
 mats["cobogo"]=_pattern_material(Color(.86,.85,.78),8,8,5,5,true)
 mats["azulejo"]=_tile_material(Color(.84,.85,.82),Color(.48,.50,.48),.22)
 # Colisão única; visual em placas para cada uma receber as luzes próximas
 # (no Compatibility cada malha aceita poucas luzes).
 var map_size: Vector3=p(950,640)-p(0,0)
 var ground=box(Vector3(map_size.x+4,.3,map_size.z+4),(p(0,0)+p(950,640))*.5+Vector3.DOWN*.15,"floor")
 for child in ground.get_children():
  if child is MeshInstance3D: child.queue_free()
 var tiles_x:=ceili((map_size.x+4)/6.0)
 var tiles_z:=ceili((map_size.z+4)/6.0)
 for ix in tiles_x:
  for iz in tiles_z:
   box(Vector3(6,.3,6),p(0,0)+Vector3(-2+3+ix*6,-.15,-2+3+iz*6),"floor",false)
 # Paredes externas com vão no portão 1, sem abertura obrigatória de portão.
 _line(0,0,950,0)
 _line(0,0,0,640)
 _line(950,0,950,640)
 _line(0,640,610,640)
 _line(655,640,950,640)
 gate_at=p(632.5,640)
 # Portão de grade verde (fotos 7/8): colisão inteira, visual vazado.
 gate=box(Vector3(3.7,2.35,.14),gate_at+Vector3(0,1.175,0),"grade_bars")
 gate.name="Portao1"
 for y in [.12,1.2,2.28]:
  box(Vector3(3.7,.08,.1),gate_at+Vector3(0,y,0),"grade",false)
 sign_at("PORTÃO 1",gate_at+Vector3(0,2.7,-.13))
 sign_at("PORTÃO 2 · CARROS",p(935,520,2.8),-90)
 # Bloco norte, química e salas superiores.
 _room("3 Contabilidade",Rect2(31,8,67,57),"S")
 # Foto de Felipe (docs/referencias/escola-fotos/patio-quimica.jpg): porta do
 # 2 Informática e a escada ficam no pátio de química; a quadra não dá acesso.
 _room("2 Informática",Rect2(98,8,65,57),"E",0,true,22)
 _room("Pátio de química",Rect2(163,8,179,57),"S",0,false,324,"W")
 _room("Laboratório de química",Rect2(342,8,50,57),"S")
 _room("3 Contabilidade · superior",Rect2(31,8,67,57),"S",LEVEL)
 _room("3 Informática",Rect2(98,8,65,57),"S",LEVEL)
 # Corredor superior; parede alta impede observar o ritual de cima, exceto o
 # vão por onde a escada chega (fechado pela caixa da escada).
 box(Vector3(214*SCALE,.20,27*SCALE),p(138,78,LEVEL-.1),"floor",false)
 _line(182,65,342,65,LEVEL,3.3)
 _line(31,91,245,91,LEVEL,.95)
 # Escada fechada no canto sudoeste do pátio: sobe de leste para oeste e chega
 # ao corredor superior. Entrada aberta para o pátio, de onde dá para espiar.
 stairs_bottom=p(236,51)
 stairs_top=p(180,51,LEVEL)
 _stairs()
 _stairwell()
 # Ala da quadra e enfermagem, corredor central aberto e estacionamento de bicicletas.
 _room("2 Contabilidade · oeste",Rect2(245,90,60,84),"E")
 _room("2 Enfermagem",Rect2(245,174,60,72),"E")
 _room("Laboratório de enfermagem",Rect2(245,246,60,59),"E")
 _room("Banheiro masculino",Rect2(245,339,30,91),"W")
 _room("Banheiro feminino",Rect2(275,339,30,91),"E")
 # Labs e hardware de frente para o pátio aberto (Felipe), não para o estacionamento.
 _room("Laboratório Informática 1",Rect2(385,92,50,42),"E")
 _room("Laboratório Informática 2",Rect2(385,134,50,72),"E")
 _room("Laboratório de hardware",Rect2(385,206,50,101),"E")
 # Corredorzinho entre hardware e coordenação leva a 2 e 1 Contabilidade.
 sign_at("2 · 1 CONTABILIDADE",p(450.5,300,2.6))
 _room("Informática 1",Rect2(436,39,70,53),"S")
 _room("Laboratório de matemática",Rect2(506,39,74,53),"S")
 _room("Biblioteca",Rect2(580,39,210,53),"S")
 # Salas junto ao pátio/refeitório.
 _room("Materiais de esportes",Rect2(790,93,45,40),"W")
 _room("Sala de música",Rect2(790,133,45,36),"W")
 _room("Laboratório de contabilidade",Rect2(790,169,45,39),"W")
 _room("Estoque da cozinha",Rect2(790,208,45,59),"W")
 _room("Cozinha",Rect2(672,267,163,39),"S")
 _room("Coordenação",Rect2(466,267,147,28),"S")
 _room("2 Contabilidade · sul",Rect2(435,335,56,34),"N")
 _room("1 Contabilidade",Rect2(491,335,84,34),"N")
 _room("Sala dos professores",Rect2(415,369,195,46),"E")
 _room("Banheiro dos professores",Rect2(672,306,33,22),"W")
 _room("Planejamento dos professores",Rect2(672,328,33,28),"W")
 _room("Secretaria",Rect2(672,356,163,60),"W")
 spawn=p(817,123)
 first_cultist=p(322,320)
 # Leste e norte do pátio: oeste é a caixa da escada; ao sul fica uma
 # passagem de ~1,5 m junto à parede, por onde Miguel passa escondido.
 ritual_center=p(305,30)
 # Checkpoint 2 no pé da escada, dentro da caixa fechada: abrigo antes do ritual.
 ritual_approach=p(240,51)
 bag_at=p(130.5,36.5,LEVEL+1.01)
 bag=box(Vector3(.42,.32,.30),bag_at,"dark",false)
 var handle=box(Vector3(.15,.05,.12),bag_at+Vector3(0,.19,0),"metal",false)
 handle.reparent(bag)
 _court()
 _courtyard()
 _ritual()
 _details_school()
 _layout_terror()
 _classroom_desks()
 # Estrutura de level design (rotas, cobertura, marco, luz-guia): nivel.gd.
 load("res://capitulo1/referencia/nivel_coordenadas.gd").build(self)
 _environment()
 # Temperatura geral fria, luminárias amareladas localizadas; sem sombras dinâmicas.
 var env: Environment=find_children("*","WorldEnvironment",true,false)[0].environment
 # Terror: escuridão de verdade, névoa que engole o fundo; luz vem de
 # lâmpadas isoladas, velas e da lanterna do celular.
 env.ambient_light_color=Color(.34,.40,.52)
 env.ambient_light_energy=.30
 env.fog_enabled=true
 env.fog_light_color=Color(.018,.022,.032)
 env.fog_light_energy=1.0
 env.fog_density=.075
 env.fog_sky_affect=.85
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure=1.0
 for light in find_children("*","DirectionalLight3D",true,false):
  light.light_energy=.16
 _merge_static_visuals()

func _line(x1: float,z1: float,x2: float,z2: float,y:=0.0,height:=3.2) -> void:
 var a=p(x1,z1,y)
 var b=p(x2,z2,y)
 var length=a.distance_to(b)
 if length<.01: return
 var body=box(Vector3(.18,height,length+.12),(a+b)*.5+Vector3.UP*height*.5,"wall")
 body.rotation.y=atan2((b-a).x,(b-a).z)
 # Meia-parede de azulejo branco, como no laboratório de hardware.
 var strip=box(Vector3(.195,1.2,length+.12),(a+b)*.5+Vector3.UP*.6,"azulejo",false)
 strip.rotation.y=body.rotation.y

## Grades/redes/cobogó com transparência por textura (sem geometria extra).
## cells: repetições; thick_x/thick_y: espessura em pixels das barras (0 = sem);
## inverted: furos são as barras (cobogó = bloco com aberturas).
func _pattern_material(color: Color,cells_x: int,cells_y: int,thick_x: int,thick_y: int,inverted:=false) -> StandardMaterial3D:
 var img=Image.create(16,16,false,Image.FORMAT_RGBA8)
 for y in 16:
  for x in 16:
   var bar=(thick_x>0 and x<thick_x) or (thick_y>0 and y<thick_y)
   if inverted: bar=not (x>=thick_x and x<16-2 and y>=thick_y and y<16-2) or bar and false
   img.set_pixel(x,y,color if bar else Color(0,0,0,0))
 var mat=StandardMaterial3D.new()
 mat.albedo_texture=ImageTexture.create_from_image(img)
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
 mat.alpha_scissor_threshold=.5
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 mat.uv1_triplanar=true
 mat.uv1_scale=Vector3(cells_x,cells_y,cells_x)*.25
 mat.roughness=.9
 return mat

## Azulejo quadrado com rejunte (textura gerada; sem arquivo externo).
func _tile_material(color: Color,grout: Color,size: float) -> StandardMaterial3D:
 var img=Image.create(32,32,false,Image.FORMAT_RGB8)
 for y in 32:
  for x in 32:
   var edge=x<2 or y<2
   var n=.97+float(posmod(x*13+y*7,11))/300.0
   img.set_pixel(x,y,grout if edge else Color(color.r*n,color.g*n,color.b*n))
 var mat=StandardMaterial3D.new()
 mat.albedo_texture=ImageTexture.create_from_image(img)
 mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
 mat.uv1_triplanar=true
 mat.uv1_scale=Vector3.ONE/size
 mat.roughness=.35
 return mat

## skip: lados que não ganham parede (já existem, compartilhados com outra sala).
func _room(title: String,r: Rect2,side: String,y:=0.0,roof:=true,custom:=-1.0,skip:="") -> void:
 rooms[title]={"rect":r,"floor":y,"center":p(r.get_center().x,r.get_center().y,y)}
 var cx=r.get_center().x
 var cz=r.get_center().y
 if custom>=0:
  if side in ["N","S"]: cx=custom
  else: cz=custom
 var gap=.78/SCALE
 for edge in ["N","S","W","E"]:
  var horizontal=edge in ["N","S"]
  var low=r.position.x if horizontal else r.position.y
  var high=r.end.x if horizontal else r.end.y
  var fixed=r.position.y if edge=="N" else (r.end.y if edge=="S" else (r.position.x if edge=="W" else r.end.x))
  if edge in skip: continue
  if edge!=side:
   if horizontal: _line(low,fixed,high,fixed,y)
   else: _line(fixed,low,fixed,high,y)
  else:
   var center=cx if horizontal else cz
   if horizontal:
    _line(low,fixed,center-gap,fixed,y)
    _line(center+gap,fixed,high,fixed,y)
   else:
    _line(fixed,low,fixed,center-gap,y)
    _line(fixed,center+gap,fixed,high,y)
   var at=p(center,fixed,y) if horizontal else p(fixed,center,y)
   box(Vector3(gap*2*SCALE,.88,.20) if horizontal else Vector3(.20,.88,gap*2*SCALE),at+Vector3.UP*2.76,"wall")
   # Pátio do ritual tem acesso livre, evitando impedir vídeo com uma porta arbitrária.
   if title!="Pátio de química":
    var door=DOOR.new()
    add_child(door)
    var normal={"S":Vector3.BACK,"N":Vector3.FORWARD,"E":Vector3.RIGHT,"W":Vector3.LEFT}[side]
    door.setup(game,at,normal,title)
    # Abre para dentro: a folha aberta não invade nem tranca o corredor.
    door.swing=1.65
    doors.append(door)
   var normal={"S":Vector3.BACK,"N":Vector3.FORWARD,"E":Vector3.RIGHT,"W":Vector3.LEFT}[side]
   sign_at(title,at+Vector3.UP*2.55+normal*.14,rad_to_deg(atan2(normal.x,normal.z)))
 if roof:
  box(Vector3(r.size.x*SCALE-.2,.02,r.size.y*SCALE-.2),p(r.get_center().x,r.get_center().y,y+.012),"azulejo",false)
  box(Vector3(r.size.x*SCALE,.15,r.size.y*SCALE),p(r.get_center().x,r.get_center().y,y+3.27),"wall")
  # Janelas gradeadas opacas no blockout: não permitem filmar através do andar superior.
  var center=p(r.end.x-.8,r.get_center().y,y+1.9)
  box(Vector3(.025,.85,minf(1.8,r.size.y*SCALE*.5)),center,"grade",false)
 if title.contains("Banheiro"):
  box(Vector3(.65,.75,.45),p(r.position.x+8,r.get_center().y,y+.375),"wall")
 elif title!="Pátio de química":
  var center=p(r.get_center().x,r.get_center().y,y)
  _desk(center,title.contains("Laboratório") or title.contains("Informática"))
  if r.size.x>70:
   for dx in [-1.6,1.6]: _desk(center+Vector3(dx,0,-.9),false)
  _lamp(center+Vector3.UP*2.9,Color(.98,.80,.49),4.5,.75)
  var board_at=p(r.get_center().x,r.position.y+1.3,y+1.65)
  if side=="N": board_at=p(r.get_center().x,r.end.y-1.3,y+1.65)
  box(Vector3(minf(1.8,r.size.x*SCALE*.65),.85,.035),board_at,"tile",false)

func _desk(at: Vector3,computer: bool) -> void:
 table(at,1.2,.65)
 box(Vector3(.48,.08,.48),at+Vector3(0,.44,.7),"wood",false)
 box(Vector3(.48,.45,.07),at+Vector3(0,.7,.94),"metal",false)
 if computer:
  box(Vector3(.48,.34,.06),at+Vector3(0,1.05,0),"dark",false)
  box(Vector3(.44,.015,.17),at+Vector3(0,.87,.22),"metal",false)
 else:
  box(Vector3(.28,.018,.20),at+Vector3(.2,.87,0),"paper",false)

const STAIR_WIDTH:=2.2
const STAIR_WEST_X:=163.0 # borda oeste do patamar (parede do 2 Informática)
const STAIR_EAST_X:=245.0 # parede leste da caixa da escada (entrada)
const STAIR_NORTH_Z:=36.0

## Rampa física contínua sob degraus visuais (não prende a cápsula nas quinas),
## em qualquer direção de stairs_bottom para stairs_top; patamar no alto e
## corredor superior na mesma colisão.
func _stairs() -> void:
 var run: Vector3=Vector3(stairs_top.x-stairs_bottom.x,0,stairs_top.z-stairs_bottom.z)
 var forward: Vector3=run.normalized()
 var side: Vector3=forward.cross(Vector3.UP)*STAIR_WIDTH*.5
 var body=StaticBody3D.new()
 body.collision_layer=1
 body.collision_mask=2
 body.name="EscadaPatioQuimica"
 add_child(body)
 var collision=CollisionShape3D.new()
 var ramp=ConcavePolygonShape3D.new()
 var top_ground: Vector3=Vector3(stairs_top.x,LEVEL,stairs_top.z)
 var a=stairs_bottom-side
 var b=stairs_bottom+side
 var c=top_ground+side
 var d=top_ground-side
 var faces=PackedVector3Array([a,c,d,a,b,c])
 # Patamar entre o fim da rampa e o corredor superior.
 # Borda exatamente igual ao fim da rampa: sobrepor criava um degrau de 3 cm
 # onde a cápsula parava.
 var top_px: float=stairs_top.x/SCALE+440
 a=p(STAIR_WEST_X,STAIR_NORTH_Z+2,LEVEL); b=p(top_px,STAIR_NORTH_Z+2,LEVEL)
 c=p(top_px,64.5,LEVEL); d=p(STAIR_WEST_X,64.5,LEVEL)
 faces.append_array(PackedVector3Array([a,c,b,a,d,c]))
 a=p(31,64.5,LEVEL); b=p(245,64.5,LEVEL)
 c=p(245,91.5,LEVEL); d=p(31,91.5,LEVEL)
 faces.append_array(PackedVector3Array([a,c,b,a,d,c]))
 ramp.set_faces(faces)
 ramp.backface_collision=true
 collision.shape=ramp
 body.add_child(collision)
 var length: float=run.length()
 var yaw: float=atan2(forward.x,forward.z)
 for i in 20:
  var t=float(i+1)/20
  var step=box(Vector3(STAIR_WIDTH,.15,length/20+.03),stairs_bottom.lerp(top_ground,t)-Vector3.UP*.075,"azulejo",false)
  step.rotation.y=yaw
 box(Vector3(abs(p(STAIR_WEST_X,0).x-stairs_top.x),.12,STAIR_WIDTH),Vector3((p(STAIR_WEST_X,0).x+stairs_top.x)*.5,LEVEL-.06,stairs_top.z),"azulejo",false)
 var rail_a=stairs_bottom+side.normalized()*-(STAIR_WIDTH*.5-.08)+Vector3.UP*.9
 var rail_b=top_ground+side.normalized()*-(STAIR_WIDTH*.5-.08)+Vector3.UP*.9
 var rail=box(Vector3(.055,.055,rail_a.distance_to(rail_b)),(rail_a+rail_b)*.5,"metal",false)
 rail.look_at(rail_b)

## Caixa fechada da escada (decisão de Felipe): de dentro não se vê o pátio,
## exceto pela entrada embaixo, de onde dá para espiar agachado.
func _stairwell() -> void:
 var tall:=LEVEL+3.2
 _line(STAIR_WEST_X,STAIR_NORTH_Z,STAIR_EAST_X,STAIR_NORTH_Z,0,tall)
 var gap:=.78/SCALE
 var mid:=51.0
 _line(STAIR_EAST_X,STAIR_NORTH_Z,STAIR_EAST_X,mid-gap,0,tall)
 _line(STAIR_EAST_X,mid+gap,STAIR_EAST_X,65,0,tall)
 # Verga acima da entrada até o alto da caixa.
 # Verga a 2,0 m (altura de porta): impede ver o pátio do alto da escada reta.
 box(Vector3(.20,tall-2.0,gap*2*SCALE),p(STAIR_EAST_X,mid,2.0+(tall-2.0)*.5),"wall")
 sign_at("ESCADA",p(STAIR_EAST_X+1.5,mid,2.5),90)

func _court() -> void:
 # Quadra coberta (foto 2): piso verde, faixa vermelha, linhas brancas,
 # cobertura metálica em colunas.
 var court_at: Vector3=p(125.5,273.5,.01)
 var cw: float=189*SCALE; var cd: float=313*SCALE
 var gw: float=cw*.81; var gd: float=cd*.83
 box(Vector3(cw-.3,.012,cd-.3),court_at+Vector3(0,-.002,0),"court_red",false)
 box(Vector3(gw,.015,gd),court_at,"court",false)
 for line in [[Vector3(gw,.02,.08),Vector3.ZERO],[Vector3(gw,.02,.08),Vector3(0,0,-gd*.5)],
  [Vector3(gw,.02,.08),Vector3(0,0,gd*.5)],[Vector3(.08,.02,gd),Vector3(-gw*.5,0,0)],
  [Vector3(.08,.02,gd),Vector3(gw*.5,0,0)]]:
  box(line[0],court_at+line[1]+Vector3.UP*.004,"line",false)
 # Colunas sobre as muretas: não bloqueiam corredor nem escada.
 var roof_h:=7.0
 for x in [-cw*.5+.15,cw*.5-.15]:
  for z in [-cd*.5+.4,-cd/6.0,cd/6.0,cd*.5-.4]:
   box(Vector3(.4,roof_h,.4),court_at+Vector3(x,roof_h*.5,z),"concrete")
 box(Vector3(cw+.4,.08,cd+.4),court_at+Vector3(0,roof_h+.05,0),"metal",false)
 for z in range(-int(cd*.5),int(cd*.5)+1,2):
  box(Vector3(cw+.4,.12,.06),court_at+Vector3(0,roof_h-.05,z),"dark",false)
 _line(31,117,31,430,0,1.3)
 _line(220,117,220,282,0,1.3)
 _line(220,324,220,430,0,1.3)
 for data in [[31,117,220,117],[31,430,220,430]]:
  _line(data[0],data[1],data[2],data[3],0,1.3)
 for x in [60,200]:
  box(Vector3(.10,3,.10),p(x,280,1.5),"metal")
  box(Vector3(1.3,.9,.08),p(x,280,3),"wall",false)
 sign_at("QUADRA",p(130,119,2.1))
 # Rampa de circulação entre quadra e corredor, sem novo bloqueio por chave.
 box(Vector3(3.3,.1,3.0),p(323,320,.05),"floor",false)

func _courtyard() -> void:
 var wet=StandardMaterial3D.new()
 wet.albedo_color=Color(.11,.15,.16)
 wet.roughness=.16; wet.metallic=.2
 for at in [p(540,180,.012),p(710,235,.012),p(600,130,.012)]:
  var puddle=MeshInstance3D.new(); var shape=CylinderMesh.new()
  shape.top_radius=1.1; shape.bottom_radius=1.1; shape.height=.003; shape.radial_segments=18
  puddle.mesh=shape; puddle.material_override=wet; puddle.position=at
  puddle.scale=Vector3(1,.5,.65); add_child(puddle)
 # Mesas só no refeitório; o pátio aberto é aberto (fotos 5/6).
 for x in [680,745]:
  for z in [160,220]:
   table(p(x,z),3.4,.85)
   bench(p(x,z+13),3.4)
   bench(p(x,z-13),3.4)
 sign_at("REFEITÓRIO",p(730,255,2.8))
 sign_at("AUDITÓRIO",p(715,104,2.7))
 # Colunas (foto do auditório): azulejo branco embaixo, pintura verde no topo.
 _auditorium_props()
 # Bicicletas, sem entidades físicas caras.
 for z in [130,160,190]:
  for dx in [-.5,.5]:
   var wheel=MeshInstance3D.new()
   var torus=TorusMesh.new()
   torus.inner_radius=.25
   torus.outer_radius=.29
   torus.rings=10
   torus.ring_segments=6
   wheel.mesh=torus
   wheel.material_override=mats["metal"]
   wheel.position=p(364,z,.35)+Vector3(0,0,dx)
   wheel.rotation.z=PI/2
   add_child(wheel)
  box(Vector3(.05,.55,1.2),p(364,z,.55),"metal",false)

func _lamp(at: Vector3,color: Color,reach: float,energy: float) -> void:
 var bulb=box(Vector3(.6,.06,.16),at,"paper",false)
 var light=OmniLight3D.new()
 light.position=at-Vector3.UP*.15
 light.light_color=color
 light.omni_range=reach
 light.light_energy=energy
 light.shadow_enabled=false
 add_child(light)
 fixtures.append(bulb)

func _ritual() -> void:
 _chemistry_patio()
 for i in 5:
  var a=ritual_center+Vector3(sin(i*TAU/5)*1.3,.018,cos(i*TAU/5)*1.3)
  var b=ritual_center+Vector3(sin((i+2)*TAU/5)*1.3,.018,cos((i+2)*TAU/5)*1.3)
  var line=box(Vector3(.055,.012,a.distance_to(b)),(a+b)*.5,"red",false)
  line.look_at(b)
 for i in 10:
  var a=ritual_center+Vector3(sin(i*TAU/10)*2.0,0,cos(i*TAU/10)*1.45)
  candle(a,i%3==0)
 # Ave viva, pousada; nenhum destino/sacrifício presumido.
 var bird=Node3D.new()
 hawk=bird
 bird.position=ritual_center+Vector3.UP*.32
 add_child(bird)
 var body=MeshInstance3D.new()
 var mesh=SphereMesh.new()
 mesh.radius=.15
 mesh.height=.40
 mesh.radial_segments=10
 mesh.rings=5
 body.mesh=mesh
 body.material_override=mats["wood"]
 bird.add_child(body)
 var head=box(Vector3(.17,.15,.18),bird.position+Vector3(0,.25,.04),"wood",false)
 var beak=box(Vector3(.08,.06,.14),head.position+Vector3(0,-.02,.13),"paper",false)
 for x in [-.075,.075]:
  var eye=box(Vector3(.025,.025,.025),head.position+Vector3(x,.02,.07),"dark",false)
  eye.reparent(bird)
 head.reparent(bird); beak.reparent(bird)
 for x in [-.05,.05]:
  var leg=box(Vector3(.025,.14,.025),ritual_center+Vector3(x,.07,.04),"paper",false)
  leg.reparent(bird)

func _details_school() -> void:
 # Vestígios escolares: trabalhos, livros, bebedouros, baldes e vegetação.
 for z in [125,180,245]:
  box(Vector3(.015,.55,.8),p(306,z,1.6),"paper",false)
  _lamp(p(323,z,2.9),Color(.89,.76,.52),5,.70)
 for at in [p(450,270),p(760,115),p(350,330)]:
  box(Vector3(.7,.9,.55),at+Vector3.UP*.45,"metal")
 for at in [p(350,420),p(420,510),p(760,500),p(345,130)]:
  for i in 3:
   box(Vector3(.6,1.3,.6),at+Vector3(i*.45,.65,sin(i)*.3),"green",false)
 for at in [p(539.5,281,.91),p(753.5,286.5,.91),p(275,210,.91),p(127,36.5,LEVEL+.91)]: pickup("empanado",at)
 pickup("faca",p(757,286.5,.91))
 for at in [p(825,125),p(425,290),p(290,160),p(150,45,LEVEL)]: locker(at,Vector3.LEFT)
 obstacle("climb",p(363,290),Vector3(1.4,.70,1),Vector3.FORWARD,1.0,.70)
 obstacle("ledge",p(363,230),Vector3(1.4,1.3,1),Vector3.FORWARD,1.2,1.3)
 box(Vector3(1.1,.3,1.8),p(414,280,1.25),"wood")
 # Rua e fachadas além do portão; a escola termina num espaço concreto.
 box(Vector3((p(950,0)-p(0,0)).x,.12,7),Vector3((p(0,0).x+p(950,0).x)*.5,-.06,p(0,640).z+4),"dark")
 for x in [200,430,700]:
  box(Vector3(9,4,.3),p(x,730,2),"wall")
  box(Vector3(1.2,2.2,.1),p(x,728,1.1),"metal",false)
 _lamp(p(670,665,3.8),Color(1,.68,.32),10,1.6)

## Revisão de level design (skills level-design / godot-genre-horror / stealth),
## seguindo as ligações do desenho de Felipe:
## - refeitório e auditório com paredes, separados do pátio a céu aberto;
## - embaixo, área de saída, passagem estreita até o portão 1 e estacionamento
##   do portão 2 separados (antes era um pátio vazio de ~50 m);
## - vazios fora do caminho fechados; esconderijos ao longo do caminho;
## - luz guiando o caminho principal, sem iluminar tudo por igual.
func _layout_terror() -> void:
 # Refeitório: parede entre ele e o pátio a céu aberto, com passagem de ~3 m.
 _line(633,93,633,150)
 _line(633,190,633,267)
 # Passagem pro portão: corredor estreito entre secretaria/sala dos profs.
 _line(610,416,610,515)
 _line(610,540,610,640)
 _line(672,416,672,640)
 # Área de saída (vegetação, sem saída): fechada a oeste e ao sul da rampa.
 _line(414,415,414,640)
 _line(0,445,414,445)
 # Estacionamento do portão 2: fora do caminho, cercado.
 _line(835,416,950,416)
 sign_at("SAÍDA · PORTÃO 1",p(641,425,2.7))
 # Luz guia: refeitório e passagem; uma lâmpada falhando antes do portão.
 _lamp(p(700,180,2.9),Color(.95,.78,.5),6,.8)
 _lamp(p(641,330,2.9),Color(.95,.78,.5),5,.7)
 _lamp(p(641,560,2.9),Color(.70,.85,.75),6,.9)
 flicker=find_children("*","OmniLight3D",true,false).back()
 # Esconderijos no caminho principal.
 for data in [[p(705,255),Vector3.FORWARD],[p(560,262),Vector3.FORWARD],[p(340,300),Vector3.LEFT],
  [p(226,215),Vector3.RIGHT],[p(300,100),Vector3.RIGHT],[p(614,470),Vector3.RIGHT],
  [p(668,600),Vector3.LEFT],[p(235,85,LEVEL),Vector3.FORWARD]]:
  locker(data[0],data[1])
 _hardware_lab()
 _photo_details()
 # Vegetação na área de saída: dá onde se esconder da vista sem ser armário.
 for at in [p(470,500),p(540,580),p(450,610)]:
  for i in 3:
   box(Vector3(.8,1.4,.8),at+Vector3(i*.6,.7,sin(i*1.7)*.4),"green",false)

## Detalhes das fotos 1–8 de Felipe (docs/referencias/escola-fotos).
func _photo_details() -> void:
 # Auditório (1, 4): é um palco elevado no refeitório onde se dão os avisos;
 # parede verde-limão atrás; porta da biblioteca logo atrás/ao lado.
 var north:=p(0,93).z+.12
 for span in [[640,674],[696,790]]:
  box(Vector3(p(span[1],0).x-p(span[0],0).x,2.0,.03),Vector3((p(span[0],0).x+p(span[1],0).x)*.5,2.2,north),"lime",false)
 # Entre a porta da biblioteca (x 676–694) e a da sala de esportes (x 790).
 _stage(700,766,93,117,.35)
 for at in [p(700,160),p(760,165)]:
  box(Vector3(1.2,.06,.7),at+Vector3.UP*.75,"teal",false)
  box(Vector3(1.1,.7,.6),at+Vector3.UP*.35,"teal")
 # Quadra (2, 3): tabelas de basquete, rede em volta, cobogó e muro verde.
 var court: Vector3=p(125.5,273.5)
 var cw: float=189*SCALE; var cd: float=313*SCALE
 for side in [-1,1]:
  var at: Vector3=court+Vector3(0,0,side*(cd*.5-.7))
  box(Vector3(.12,3.0,.12),at+Vector3(0,1.5,side*.6),"metal")
  box(Vector3(1.8,1.05,.05),at+Vector3(0,3.4,0),"plastic",false)
  box(Vector3(.45,.03,.45),at+Vector3(0,3.05,-side*.25),"orange",false)
 for data in [[Vector3(.03,5.4,cd),Vector3(-cw*.5+.05,4.0,0)],[Vector3(.03,5.4,cd),Vector3(cw*.5-.05,4.0,0)],
  [Vector3(cw,5.4,.03),Vector3(0,4.0,-cd*.5+.05)],[Vector3(cw,5.4,.03),Vector3(0,4.0,cd*.5-.05)]]:
  box(data[0],court+data[1],"rede",false)
 box(Vector3(.04,1.6,cd),Vector3(p(0,0).x+.12,2.6,court.z),"cobogo",false)
 box(Vector3(.03,1.8,cd),Vector3(p(0,0).x+.12,.9,court.z),"patio_green",false)
 # Pátio (5, 6): corredor coberto com colunas ao sul do pátio a céu aberto.
 for x in range(470,620,30):
  box(Vector3(.4,3.0,.4),p(x,255,1.5),"wall")
  box(Vector3(.42,1.1,.42),p(x,255,.55),"azulejo",false)
 box(Vector3(p(625,0).x-p(455,0).x,.12,1.4),Vector3((p(455,0).x+p(625,0).x)*.5,3.05,p(0,260).z),"telha",false)
 # Entrada (7, 8): caminho verde até o portão, faixa laranja e placa verde.
 box(Vector3(p(672,0).x-p(610,0).x-.25,.015,p(0,640).z-p(0,416).z),Vector3(p(641,0).x,.009,(p(0,416).z+p(0,640).z)*.5),"walk_green",false)
 var facade_x:=p(672,0).x-.11
 box(Vector3(.03,.35,9),Vector3(facade_x,2.35,p(0,470).z),"orange",false)
 box(Vector3(.04,.9,9),Vector3(facade_x,2.95,p(0,470).z),"sign_green",false)
 box(Vector3(.03,.6,9),Vector3(facade_x,.3,p(0,470).z),"sign_green",false)
 sign_at("EEEP JOAQUIM ANTÔNIO ALBANO",Vector3(facade_x-.03,2.95,p(0,470).z),-90)
 # Lado de fora: árvores e carros junto ao portão.
 for at in [p(600,665),p(690,668)]:
  box(Vector3(.3,3.2,.3),at+Vector3.UP*1.6,"trunk",false)
  box(Vector3(2.6,1.6,2.6),at+Vector3.UP*3.8,"leaves",false)
 for at in [p(720,600),p(790,600)]:
  box(Vector3(1.8,.75,4.0),at+Vector3.UP*.55,"car")
  box(Vector3(1.6,.6,2.0),at+Vector3(0,1.2,.2),"car",false)

## Pátio de química (foto com 1/2): coberto por telhado de telha sobre vigas de
## madeira, parede verde em cima, azulejo branco embaixo e no chão.
func _chemistry_patio() -> void:
 var west:=p(STAIR_EAST_X,0).x
 var east:=p(342,0).x
 var north:=p(0,8).z
 var south:=p(0,65).z
 var cx:=(p(163,0).x+east)*.5
 var cz:=(north+south)*.5
 box(Vector3(east-p(163,0).x-.2,.02,south-north-.2),Vector3(cx,.012,cz),"azulejo",false)
 # Pintura verde acima da meia-parede (faces internas do pátio).
 box(Vector3(east-west,1.9,.03),Vector3((west+east)*.5,2.15,north+.11),"patio_green",false)
 box(Vector3(.03,1.9,south-north),Vector3(east-.11,2.15,cz),"patio_green",false)
 box(Vector3(.03,1.9,south-north),Vector3(west+.11,2.15,cz),"patio_green",false)
 # Telhado: telha por cima, vigas de madeira à vista por baixo.
 box(Vector3(east-p(163,0).x+.6,.06,south-north+.6),Vector3(cx,4.75,cz),"telha",false)
 for i in 7:
  var x=lerpf(p(163,0).x,east,(float(i)+.5)/7)
  box(Vector3(.16,.22,south-north),Vector3(x,4.55,cz),"wood",false)
 box(Vector3(east-p(163,0).x,.26,.2),Vector3(cx,4.4,cz),"wood",false)

## Auditório e pátio principal (fotos): sofá preto rasgado, cadeiras de
## plástico brancas empilhadas, extintor e porta gradeada verde.
## Carteiras em fileiras nas salas de aula (escala real deixava salas vazias).
## Também servem de cobertura. Evitam porta, mesa central, armários e itens.
func _classroom_desks() -> void:
 for title in rooms:
  if title.contains("Laboratório") or title.contains("Banheiro") or title.contains("Pátio") or title in ["Biblioteca","Cozinha","Secretaria","Coordenação","Sala dos professores","Estoque da cozinha","Materiais de esportes","Sala de música","Planejamento dos professores","Banheiro dos professores"]:
   continue
  var r: Rect2=rooms[title]["rect"]; var y: float=rooms[title]["floor"]
  var lo:=p(r.position.x,r.position.y,y); var hi:=p(r.end.x,r.end.y,y)
  var center:=(lo+hi)*.5
  var avoid: Array[Vector3]=[center]
  for d in doors: avoid.append(d.global_position)
  for h in hides: avoid.append(h["inside"])
  for item in pickups: avoid.append(item["at"])
  var x:=lo.x+1.3
  while x<hi.x-1.1:
   var z:=lo.z+1.5
   while z<hi.z-1.2:
    var at:=Vector3(x,y,z)
    var free:=true
    for a in avoid:
     if absf(a.y-y)<2 and Vector2(a.x-at.x,a.z-at.z).length()<1.7: free=false; break
    if free: _desk_light(at)
    z+=1.55
   x+=1.5

func _desk_light(at: Vector3) -> void:
 box(Vector3(1.0,.06,.55),at+Vector3.UP*.76,"wood")
 for dx in [-.44,.44]: box(Vector3(.05,.73,.45),at+Vector3(dx,.37,0),"metal",false)
 box(Vector3(.42,.05,.42),at+Vector3(0,.44,.62),"wood",false)
 box(Vector3(.42,.42,.05),at+Vector3(0,.66,.82),"metal",false)

## Palco do auditório: bloco sólido (não faz parte de rota); degraus só
## visuais. Rampa física prendia a cápsula na quina lateral.
func _stage(x1: float,x2: float,z1: float,z2: float,height: float) -> void:
 box(Vector3(p(x2,0).x-p(x1,0).x,height,p(0,z2).z-p(0,z1).z),(p(x1,z1)+p(x2,z2))*.5+Vector3.UP*height*.5,"azulejo")
 for k in 2:
  var depth:=.3
  var w: float=(p(x2,0).x-p(x1,0).x)*.4
  var h: float=height*float(2-k)/3.0
  box(Vector3(w,h,depth),Vector3((p(x1,0).x+p(x2,0).x)*.5,h*.5,p(0,z2).z+depth*(k+.5)),"concrete",false)

func _auditorium_props() -> void:
 var sofa_at: Vector3=p(655,112)
 box(Vector3(1.9,.45,.8),sofa_at+Vector3(0,.25,0),"sofa")
 box(Vector3(1.9,.55,.22),sofa_at+Vector3(0,.75,-.32),"sofa",false)
 for dx in [-.98,.98]: box(Vector3(.22,.62,.8),sofa_at+Vector3(dx,.42,0),"sofa",false)
 for at in [p(645,135),p(780,140),p(520,108)]:
  for i in 6:
   box(Vector3(.45,.05,.45),at+Vector3(0,.42+i*.07,0),"plastic",false)
  for dx in [-.2,.2]:
   for dz in [-.2,.2]:
    box(Vector3(.03,.45,.03),at+Vector3(dx,.22,dz),"plastic",false)
  box(Vector3(.45,.42,.04),at+Vector3(0,.95,-.2),"plastic",false)
  # Pilha de assentos é o próprio colisor (lote estático ignora visibilidade).
  box(Vector3(.47,.44,.47),at+Vector3(0,.62,0),"plastic")
 # Extintor e porta gradeada no pátio principal.
 box(Vector3(.16,.45,.16),p(630.5,140,1.1),"extintor",false)
 box(Vector3(.04,1.1,1.4),p(631.5,230,1.7),"grade",false)

## Laboratório de hardware (fotos 3): bancada branca com armários, monitores
## velhos, bancos de madeira vermelhos, cadeira azul, caixas e cabos no chão.
func _hardware_lab() -> void:
 # Porta a leste (pátio); bancada na parede oeste.
 var west: float=p(389.5,0).x
 box(Vector3(.75,.92,8.6),Vector3(west,.46,p(0,256).z),"cabinet")
 box(Vector3(.8,.05,8.7),Vector3(west,.945,p(0,256).z),"cabinet",false)
 for i in 7:
  var z=p(0,222+i*11).z
  box(Vector3(.42,.34,.08),Vector3(west+.05,1.15,z),"dark",false)
  box(Vector3(.02,.5,.5),Vector3(west+.38,.45,z),"metal",false)
 for at in [p(420,236),p(418,268),p(410,248)]:
  box(Vector3(.36,.04,.36),at+Vector3.UP*.68,"stool",false)
  for dx in [-.13,.13]:
   for dz in [-.13,.13]:
    box(Vector3(.04,.66,.04),at+Vector3(dx,.33,dz),"stool",false)
 box(Vector3(.5,.08,.5),p(400,222)+Vector3.UP*.5,"chair",false)
 box(Vector3(.5,.5,.07),p(400,222)+Vector3(0,.8,.22),"chair",false)
 for i in 3:
  box(Vector3(.6,.45,.45),p(396+i*8,300)+Vector3(0,.225+float(i%2)*.0,0),"cardboard")
 for i in 5:
  box(Vector3(.06,.36,.48),p(418,298)+Vector3(i*.09,.18,0),"dark",false)
 for i in 4:
  box(Vector3(2.8,.012,.025),p(405,280+i*.6,.006),"dark",false)

func sign_at(text: String,at: Vector3,yaw:=0.0) -> void:
 var label=Label3D.new()
 label.text=text
 label.position=at
 label.rotation_degrees.y=yaw
 label.font=load("res://prototipo/interface.ttf")
 label.font_size=32
 label.pixel_size=.004
 label.modulate=Color(.86,.84,.69)
 label.double_sided=false
 var normal=Vector3(sin(deg_to_rad(yaw)),0,cos(deg_to_rad(yaw)))
 var plate=box(Vector3(clampf(text.length()*.075,.7,3.6),.28,.025),at-normal*.018,"metal",false)
 plate.rotation_degrees.y=yaw
 add_child(label)

func _merge_static_visuals() -> void:
 # Agrupa o cenário por material. Colisores/portas permanecem independentes.
 var groups: Dictionary={}
 for visual in find_children("*","MeshInstance3D",true,false):
  if visual.get_parent().has_meta("door") or visual.mesh==null: continue
  if visual.material_override==null: continue
  # Porta e recursos que precisam desaparecer/mover ficam fora do lote estático.
  if bag.is_ancestor_of(visual) or _is_pickup(visual): continue
  if hawk.is_ancestor_of(visual): continue
  var reactive_visual=false
  for prop in reactive:
   if prop.is_ancestor_of(visual) and absf(prop.position.x-p(323,0).x)<7:
    reactive_visual=true; break
  if reactive_visual: continue
  var dynamic=false
  for d in doors:
   if d.is_ancestor_of(visual): dynamic=true; break
  if dynamic: continue
  # Lotes por material e por região: um lote do mapa inteiro só recebia
  # as poucas luzes permitidas por malha e ignorava lâmpadas e lanterna.
  var center: Vector3=visual.global_transform*visual.mesh.get_aabb().get_center()
  var key=str(visual.material_override.get_instance_id(),":",floori(center.x/MERGE_CELL),":",floori(center.z/MERGE_CELL),":",floori(center.y/2.5))
  if not groups.has(key): groups[key]={"tool":SurfaceTool.new(),"material":visual.material_override}
  var tool: SurfaceTool=groups[key]["tool"]
  if not groups[key].has("started"):
   tool.begin(Mesh.PRIMITIVE_TRIANGLES)
   groups[key]["started"]=true
  for surface in visual.mesh.get_surface_count():
   tool.append_from(visual.mesh,surface,global_transform.affine_inverse()*visual.global_transform)
  visual.visible=false
 for group in groups.values():
  var instance=MeshInstance3D.new()
  instance.mesh=group["tool"].commit()
  instance.material_override=group["material"]
  add_child(instance)

func _is_pickup(visual: Node) -> bool:
 for item in pickups:
  if item["node"].is_ancestor_of(visual): return true
 return false

func open_exit() -> void:
 pass # Saída por transposição do portão, não abrindo-o.

func reset_exit() -> void:
 gate.collision_layer=1

func update(dt: float,time: float) -> void:
 super.update(dt,time)
 if hawk: hawk.rotation.y=.12*sin(time*.7)
 if flicker:
  # Falha irregular: quase sempre acesa, apagões curtos.
  var n=sin(time*13.1)+sin(time*7.3+1.7)+sin(time*2.9)
  flicker.light_energy=0.0 if n>2.1 else .9

extends "res://prototipo/school.gd"
## Planta derivada do desenho de Felipe. Metros propostos; relações preservadas.
const SCALE := .085
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
 for data in [["floor",Color(.33,.35,.34)],["wall",Color(.63,.63,.53)],
  ["tile",Color(.20,.35,.30)],["wood",Color(.28,.19,.12)],
  ["metal",Color(.21,.26,.26)],["dark",Color(.035,.044,.055)],
  ["paper",Color(.66,.64,.50)],["red",Color(.28,.015,.025)],
  ["green",Color(.10,.22,.13)]]:
  mats[data[0]]=material(data[1])
 # Colisão única; visual em placas para cada uma receber as luzes próximas
 # (no Compatibility cada malha aceita poucas luzes).
 var ground=box(Vector3(84,.3,60),p(475,325,-.15),"floor")
 for child in ground.get_children():
  if child is MeshInstance3D: child.queue_free()
 var origin: Vector3=p(475,325,-.15)
 for ix in 14:
  for iz in 10:
   box(Vector3(6,.3,6),origin+Vector3(-42+3+ix*6,0,-30+3+iz*6),"floor",false)
 # Paredes externas com vão no portão 1, sem abertura obrigatória de portão.
 _line(0,0,950,0)
 _line(0,0,0,640)
 _line(950,0,950,640)
 _line(0,640,610,640)
 _line(655,640,950,640)
 gate_at=p(632.5,640)
 gate=box(Vector3(3.7,2.35,.14),gate_at+Vector3(0,1.175,0),"metal")
 gate.name="Portao1"
 for x in range(15):
  box(Vector3(.035,2.35,.08),gate_at+Vector3(-1.8+x*.25,1.175,-.12),"dark",false)
 sign_at("PORTÃO 1",gate_at+Vector3(0,2.7,-.13))
 sign_at("PORTÃO 2 · CARROS",p(935,520,2.8),-90)
 # Bloco norte, química e salas superiores.
 _room("3 Contabilidade",Rect2(31,8,67,57),"S")
 _room("2 Informática",Rect2(98,8,65,57),"S")
 _room("Pátio de química",Rect2(163,8,179,57),"S",0,false,324)
 _room("Laboratório de química",Rect2(342,8,50,57),"S")
 _room("3 Contabilidade · superior",Rect2(31,8,67,57),"S",LEVEL)
 _room("3 Informática",Rect2(98,8,65,57),"S",LEVEL)
 # Corredor superior e parede que impede observar o ritual de cima.
 box(Vector3(214*SCALE,.20,27*SCALE),p(138,78,LEVEL-.1),"floor",false)
 _line(163,65,342,65,LEVEL,3.3)
 _line(31,91,172,91,LEVEL,.95)
 _line(219,91,245,91,LEVEL,.95)
 stairs_bottom=p(195,180)
 stairs_top=p(195,91,LEVEL)
 _stairs()
 # Ala da quadra e enfermagem, corredor central aberto e estacionamento de bicicletas.
 _room("2 Contabilidade · oeste",Rect2(245,90,60,84),"E")
 _room("2 Enfermagem",Rect2(245,174,60,72),"E")
 _room("Laboratório de enfermagem",Rect2(245,246,60,59),"E")
 _room("Banheiro masculino",Rect2(245,339,30,91),"W")
 _room("Banheiro feminino",Rect2(275,339,30,91),"E")
 _room("Laboratório Informática 1",Rect2(385,92,50,42),"W")
 _room("Laboratório Informática 2",Rect2(385,134,50,72),"W")
 _room("Laboratório de hardware",Rect2(385,206,50,101),"W")
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
 ritual_center=p(251,36)
 ritual_approach=p(323,79)
 bag_at=p(130.5,36.5,LEVEL+1.01)
 bag=box(Vector3(.42,.32,.30),bag_at,"dark",false)
 var handle=box(Vector3(.15,.05,.12),bag_at+Vector3(0,.19,0),"metal",false)
 handle.reparent(bag)
 _court()
 _courtyard()
 _ritual()
 _details_school()
 _layout_terror()
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
 var strip=box(Vector3(.195,1,length+.12),(a+b)*.5+Vector3.UP*.5,"tile",false)
 strip.rotation.y=body.rotation.y

func _room(title: String,r: Rect2,side: String,y:=0.0,roof:=true,custom:=-1.0) -> void:
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
  box(Vector3(r.size.x*SCALE,.15,r.size.y*SCALE),p(r.get_center().x,r.get_center().y,y+3.27),"wall")
  # Janelas gradeadas opacas no blockout: não permitem filmar através do andar superior.
  var center=p(r.end.x-.8,r.get_center().y,y+1.9)
  box(Vector3(.025,.85,minf(1.8,r.size.y*SCALE*.5)),center,"dark",false)
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

func _stairs() -> void:
 var width=2.7
 var landing_z=p(195,91.5).z
 var length=stairs_bottom.distance_to(Vector3(stairs_top.x,0,landing_z))
 # Uma rampa física contínua sob degraus visuais evita prender a cápsula nas quinas.
 var body=StaticBody3D.new()
 body.collision_layer=1
 body.collision_mask=2
 body.name="EscadaQuadra"
 add_child(body)
 var collision=CollisionShape3D.new()
 var ramp=ConcavePolygonShape3D.new()
 var a=Vector3(stairs_bottom.x-width*.5,0,stairs_bottom.z)
 var b=Vector3(stairs_bottom.x+width*.5,0,stairs_bottom.z)
 var c=Vector3(stairs_top.x+width*.5,LEVEL,landing_z)
 var d=Vector3(stairs_top.x-width*.5,LEVEL,landing_z)
 var faces=PackedVector3Array([a,c,d,a,b,c])
 a=p(31,64.5,LEVEL); b=p(245,64.5,LEVEL)
 c=p(245,91.5,LEVEL); d=p(31,91.5,LEVEL)
 faces.append_array(PackedVector3Array([a,c,b,a,d,c]))
 ramp.set_faces(faces)
 ramp.backface_collision=true
 collision.shape=ramp
 body.add_child(collision)
 for i in 24:
  var t=float(i+1)/24
  box(Vector3(width,.15,length/24+.03),Vector3(stairs_bottom.x,LEVEL*t-.075,lerpf(stairs_bottom.z,landing_z,t)),"floor",false)
 for side in [-1,1]:
  var rail_a=stairs_bottom+Vector3(side*1.45,.9,0)
  var rail_b=stairs_top+Vector3(side*1.45,.9,0)
  var rail=box(Vector3(.055,.055,rail_a.distance_to(rail_b)),(rail_a+rail_b)*.5,"metal",false)
  rail.look_at(rail_b)

func _court() -> void:
 box(Vector3(17,.015,26),p(130,277,.01),"tile",false)
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
 for x in [510,600,690]:
  for z in [160,220]:
   table(p(x,z),3.4,.85)
   bench(p(x,z+13),3.4)
   bench(p(x,z-13),3.4)
 sign_at("REFEITÓRIO",p(730,255,2.8))
 sign_at("AUDITÓRIO",p(715,104,2.7))
 for x in [450,550,650,750]:
  box(Vector3(.23,3.4,.23),p(x,100,1.7),"tile")
 box(Vector3(350*SCALE,.14,2.1),p(615,104,3.45),"wall")
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
 for i in 5:
  var a=ritual_center+Vector3(sin(i*TAU/5)*2,.018,cos(i*TAU/5)*2)
  var b=ritual_center+Vector3(sin((i+2)*TAU/5)*2,.018,cos((i+2)*TAU/5)*2)
  var line=box(Vector3(.055,.012,a.distance_to(b)),(a+b)*.5,"red",false)
  line.look_at(b)
 for i in 10:
  var a=ritual_center+Vector3(sin(i*TAU/10)*2.8,0,cos(i*TAU/10)*2.15)
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
 box(Vector3(75,.12,7),p(500,680,-.06),"dark")
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
 # Vegetação na área de saída: dá onde se esconder da vista sem ser armário.
 for at in [p(470,500),p(540,580),p(450,610)]:
  for i in 3:
   box(Vector3(.8,1.4,.8),at+Vector3(i*.6,.7,sin(i*1.7)*.4),"green",false)

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

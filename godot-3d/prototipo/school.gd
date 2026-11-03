extends Node3D
## Planta fictícia inspirada em escola de Fortaleza, em metros; não reproduz a escola real.
const DOOR = preload("res://prototipo/door.gd")
var game: Node3D
var doors: Array[Node3D] = []
var phone: Node3D
var obstacles: Array[Dictionary] = []
var hides: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var exits: Array[Vector3] = []
var candles: Array[OmniLight3D] = []
var reactive: Array[Node3D] = []
var gate: StaticBody3D
var gate_pivot: Node3D
var mats: Dictionary = {}

func build(owner_game: Node3D) -> void:
 game = owner_game
 for item in [["floor",Color(.38,.36,.32)], ["wall",Color(.69,.68,.59)],
  ["tile",Color(.19,.34,.28)], ["wood",Color(.23,.12,.075)],
  ["metal",Color(.18,.23,.20)], ["dark",Color(.055,.035,.033)]]:
  mats[item[0]] = material(item[1])
 var foundation=box(Vector3(22,.3,52),Vector3(0,-.15,-10),"floor")
 foundation.get_child(0).visible=false
 for z in range(-32,15,5):
  box(Vector3(22,.1,5),Vector3(0,-.05,z),"floor",false)
 wall(Vector3(.25,3.5,48),Vector3(-10,1.75,-10))
 wall(Vector3(.25,3.5,48),Vector3(10,1.75,-10))
 wall(Vector3(20,3.5,.25),Vector3(0,1.75,-34))
 # Saída: portão central, sem parede invisível.
 wall(Vector3(9,3.5,.25),Vector3(-5.5,1.75,14))
 wall(Vector3(8,3.5,.25),Vector3(6,1.75,14))
 gate = box(Vector3(3,2.6,.18),Vector3(.5,1.3,14),"metal")
 gate.get_child(0).visible=false
 gate_pivot=Node3D.new()
 gate_pivot.position=Vector3(-1.5,-1.3,0)
 gate.add_child(gate_pivot)
 for x in range(13):
  var bar=box(Vector3(.045,2.6,.05),Vector3.ZERO,"metal",false)
  remove_child(bar)
  gate_pivot.add_child(bar)
  bar.position=Vector3(float(x)*.25,1.3,0)
 for y in [.05,1.3,2.55]:
  var rail=box(Vector3(3,.065,.06),Vector3.ZERO,"metal",false)
  remove_child(rail)
  gate_pivot.add_child(rail)
  rail.position=Vector3(1.5,y,0)
 sign_at("SAÍDA",Vector3(.5,2.95,13.8))
 # Sala dos materiais, junto ao pátio/refeitório.
 wall(Vector3(7,3,.2),Vector3(-6.5,1.5,4))
 wall(Vector3(.2,3,3),Vector3(-3,1.5,5.5))
 wall(Vector3(.2,3,3),Vector3(-3,1.5,11.5))
 box(Vector3(7,.15,10),Vector3(-6.5,3.05,9),"wall")
 sign_at("EDUCAÇÃO FÍSICA\nMATERIAIS",Vector3(-2.85,2.45,8),-90)
 box(Vector3(2,.16,.8),Vector3(-7,.45,11),"wood")
 for x in [-8.7,-7.5,-6.3]:
  var rack = box(Vector3(1,.12,.6),Vector3(x,1.2,4.5),"metal")
  for h in [.5,.9,1.3]:
   var ball = MeshInstance3D.new()
   var sphere = SphereMesh.new()
   sphere.radius = .19
   sphere.height = .38
   sphere.radial_segments = 10
   sphere.rings = 5
   ball.mesh = sphere
   ball.material_override = material(Color(.44,.18,.035))
   ball.position = Vector3(x,h,4.8)
   add_child(ball)
  reactive.append(rack)
 candle(Vector3(-7,.54,11),true)
 sign_at("PÁTIO / REFEITÓRIO",Vector3(3,2.7,3.5))
 for z in [3.0,7.0]:
  table(Vector3(4,0,z),3.5,1.05)
  bench(Vector3(4,0,z+1.1),3.5)
  bench(Vector3(4,0,z-1.1),3.5)
 for z in [-1,5,11]:
  box(Vector3(.22,3.2,.22),Vector3(8.6,1.6,z),"tile")
 box(Vector3(3,.12,15),Vector3(8.5,3.2,5),"dark")
 # Corredor central e salas, com aberturas reais.
 wall(Vector3(.2,3.2,23),Vector3(-3,1.6,-14.5))
 for z_and_length in [[-5,4],[-13,8],[-23,6]]:
  wall(Vector3(.2,3.2,z_and_length[1]),Vector3(2,1.6,z_and_length[0]))
 wall(Vector3(8,3.2,.2),Vector3(6,1.6,-7))
 wall(Vector3(8,3.2,.2),Vector3(6,1.6,-20))
 box(Vector3(5,.15,23),Vector3(-.5,3.25,-14.5),"wall")
 box(Vector3(8,.15,13),Vector3(6,3.25,-13.5),"wall")
 sign_at("BLOCO B",Vector3(-.5,2.5,-3))
 sign_at("SALA 02",Vector3(2.2,2.35,-8.7),-90)
 for x in [4,6.5]:
  for z in [-10,-13,-16]:
   table(Vector3(x,0,z),1.0,.65)
   box(Vector3(.6,.08,.6),Vector3(x,.43,z+.65),"wood")
 box(Vector3(.06,1.15,3.8),Vector3(9.8,1.7,-13),"tile")
 # Obstáculos com destino explícito, alturas e espaço de aterrissagem verificáveis.
 obstacle("vault",Vector3(-.5,0,-6),Vector3(3.8,.72,.65),Vector3(0,0,1),1.15,.8)
 obstacle("climb",Vector3(7.6,0,-18.5),Vector3(2,1.10,1.1),Vector3(0,0,1),1.2,1.1)
 obstacle("ledge",Vector3(8,0,-24),Vector3(3,1.5,1.2),Vector3(0,0,1),1.35,1.5)
 # Vão baixo: colisão superior permite apenas a cápsula agachada.
 box(Vector3(2.6,.55,.6),Vector3(5,1.38,-19.5),"wood")
 sign_at("DEPÓSITO",Vector3(5,2,-19.6))
 # Esconderijos têm paredes de verdade; captura depende da última visão.
 locker(Vector3(-8.7,0,8.4),Vector3(1,0,0))
 locker(Vector3(8.8,0,-9),Vector3(-1,0,0))
 locker(Vector3(8.8,0,-17.5),Vector3(-1,0,0))
 # Área ritual, aberta para o corredor; cultista só surge ao testemunhar o ritual.
 sign_at("SILÊNCIO",Vector3(0,2.5,-33.75))
 box(Vector3(3,.6,1.3),Vector3(0,.3,-31),"dark")
 for i in range(14):
  var angle = i * TAU / 14.0
  candle(Vector3(sin(angle)*3.2,.02,-30+cos(angle)*2.3),i%3==0)
 for p in [Vector3(-7,1.25,5),Vector3(3,.85,3),Vector3(-2,1.2,-5),Vector3(3,.8,-13),Vector3(-2,1.2,-21)]:
  candle(p,true)
 # Símbolo geométrico fictício, pintado no chão.
 for i in range(7):
  var a = Vector3(sin(i*TAU/7)*2.2,.015,-30+cos(i*TAU/7)*2.2)
  var b = Vector3(sin((i+3)*TAU/7)*2.2,.015,-30+cos((i+3)*TAU/7)*2.2)
  var mark = box(Vector3(.035,.01,a.distance_to(b)),(a+b)*.5,"wood",false)
  mark.look_at(b)
 pickup("empanado",Vector3(-5.6,.85,4.9))
 box(Vector3(1.2,.8,.6),Vector3(-5.6,.4,4.9),"metal")
 pickup("empanado",Vector3(4,.88,3))
 pickup("empanado",Vector3(6.5,.87,-13))
 pickup("faca",Vector3(4,.87,-16))
 _details()
 _environment()

func material(color: Color) -> StandardMaterial3D:
 var mat = StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = .95
 mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var img = Image.create(32,32,false,Image.FORMAT_RGB8)
 for y in 32:
  for x in 32:
   var n = .96 + float(posmod(x*31+y*17+x*y*7,29))/420.0
   if color==Color(.19,.34,.28) and (x%16==0 or y%16==0):
    n *= .7
   img.set_pixel(x,y,Color(n,n,n))
 mat.albedo_texture = ImageTexture.create_from_image(img)
 mat.uv1_triplanar = true
 mat.uv1_scale = Vector3.ONE * 1.6
 return mat

func box(size: Vector3, at: Vector3, kind: String, solid := true) -> Node3D:
 var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
 node.position = at
 add_child(node)
 var visual = MeshInstance3D.new()
 var mesh = BoxMesh.new()
 mesh.size = size
 visual.mesh = mesh
 visual.material_override = mats[kind]
 node.add_child(visual)
 if solid:
  node.collision_layer = 1
  node.collision_mask = 2
  var cs = CollisionShape3D.new()
  var shape = BoxShape3D.new()
  shape.size = size
  cs.shape = shape
  node.add_child(cs)
 return node

func wall(size: Vector3, at: Vector3) -> void:
 box(size,at,"wall")
 var tiled = Vector3(size.x+.012,1.0,size.z+.012)
 box(tiled,Vector3(at.x,.5,at.z),"tile",false)

func table(at: Vector3, width: float, depth: float) -> void:
 var top = box(Vector3(width,.10,depth),at+Vector3(0,.8,0),"wood")
 reactive.append(top)
 obstacles.append({"node":top,"kind":"vault","at":at,"normal":Vector3(0,0,1),"distance":depth/2+.55,"height":.85,"size":Vector3(width,.85,depth)})
 top.set_meta("reactive",true)
 for x in [-width*.4,width*.4]:
  for z in [-depth*.35,depth*.35]:
   box(Vector3(.08,.75,.08),at+Vector3(x,.375,z),"metal")

func bench(at: Vector3, width: float) -> void:
 var node=box(Vector3(width,.10,.4),at+Vector3(0,.45,0),"wood")
 for x in [-width*.36,width*.36]:
  box(Vector3(.1,.42,.32),at+Vector3(x,.21,0),"metal")
 obstacles.append({"node":node,"kind":"vault","at":at,"normal":Vector3(0,0,1),"distance":.75,"height":.5,"size":Vector3(width,.5,.4)})

func obstacle(kind: String, at: Vector3, size: Vector3, normal: Vector3, distance: float, height: float) -> void:
 var node = box(size,at+Vector3(0,size.y/2,0),"wood")
 obstacles.append({"node":node,"kind":kind,"at":at,"normal":normal,"distance":distance,"height":height,"size":size})

func locker(at: Vector3, normal: Vector3) -> void:
 # Caixa com abertura frontal; esconderijo e fresta continuam dentro do mundo.
 var root = Node3D.new()
 root.position = at
 root.rotation.y = atan2(normal.x,normal.z)
 add_child(root)
 for part in [[Vector3(1,2.15,.1),Vector3(0,1.075,-.45)],
  [Vector3(.08,2.15,1),Vector3(-.5,1.075,0)],
  [Vector3(.08,2.15,1),Vector3(.5,1.075,0)],
  [Vector3(1,.08,1),Vector3(0,2.15,0)],
  [Vector3(1,.65,.08),Vector3(0,1.8,.48)],
  [Vector3(1,1.0,.08),Vector3(0,.5,.48)]]:
  var node = box(part[0],Vector3.ZERO,"metal")
  remove_child(node)
  root.add_child(node)
  node.position = part[1]
 hides.append({"inside":at,"entry":at+normal*.95,"normal":normal})


func sign_at(text: String, at: Vector3, yaw := 0.0) -> void:
 var label = Label3D.new()
 label.text = text
 label.position = at
 label.rotation_degrees.y = yaw
 var font: Font=load("res://prototipo/interface.ttf")
 label.font = font
 label.font_size = 40
 label.pixel_size = .006
 label.modulate = Color(.9,.88,.73)
 label.double_sided=false
 var plate=box(Vector3(minf(4.2,float(text.length())*.13),.42 if not "\n" in text else .7,.035),at-Vector3(sin(deg_to_rad(yaw)),0,cos(deg_to_rad(yaw)))*.025,"metal",false)
 plate.rotation_degrees.y=yaw
 add_child(label)

func candle(at: Vector3, lit: bool) -> void:
 box(Vector3(.09,.24,.09),at+Vector3(0,.12,0),"wall",false)
 var flame = MeshInstance3D.new()
 var mesh = SphereMesh.new()
 mesh.radius = .035
 mesh.height = .12
 flame.mesh = mesh
 var mat = StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.albedo_color = Color(1,.22,.035)
 flame.material_override = mat
 flame.position = at+Vector3(0,.29,0)
 add_child(flame)
 if lit:
  var light = OmniLight3D.new()
  light.position = at+Vector3(0,.4,0)
  light.light_color = Color(1,.25,.10)
  light.omni_range = 6.0
  light.light_energy = .95
  light.shadow_enabled = not game.lightweight and candles.size()<2
  candles.append(light)
  add_child(light)

func pickup(kind: String, at: Vector3) -> void:
 var body = box(Vector3(.24,.10,.15) if kind=="empanado" else Vector3(.04,.02,.3),at,"wood" if kind=="empanado" else "metal",false)
 pickups.append({"kind":kind,"node":body,"at":at,"taken":false})

func _environment() -> void:
 var node = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky=Sky.new()
 var sky_mat=ProceduralSkyMaterial.new()
 sky_mat.sky_top_color=Color(.018,.025,.055)
 sky_mat.sky_horizon_color=Color(.09,.11,.15)
 sky_mat.ground_horizon_color=Color(.07,.08,.10)
 sky_mat.ground_bottom_color=Color(.025,.025,.035)
 sky.sky_material=sky_mat
 env.sky=sky
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(.58,.62,.68)
 env.ambient_light_energy = .68
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 node.environment = env
 add_child(node)
 var moon = DirectionalLight3D.new()
 moon.rotation_degrees = Vector3(-57,-30,0)
 moon.light_color = Color(.63,.72,.9)
 moon.light_energy = .48
 moon.shadow_enabled = not game.lightweight
 add_child(moon)

func update(dt: float, time: float) -> void:
 for i in candles.size():
  candles[i].light_energy = .92 + .04*sin(time*7.0+i*3.0)+.025*sin(time*13.7+i)

func _details() -> void:
 # Vãos estreitados e portas de verdade, preservando a ligação com o pátio.
 for info in [[Vector3(-3,0,8.5),"Sala de materiais",1.5], [Vector3(2,0,-8),"Sala 02",1.0], [Vector3(2,0,-18.5),"Sala 02",1.5]]:
  var at: Vector3=info[0]
  var half_hole: float=info[2]
  var fill=half_hole-.7
  if fill>0:
   wall(Vector3(.2,2.35,fill),at+Vector3(0,1.175,-.7-fill*.5))
   wall(Vector3(.2,2.35,fill),at+Vector3(0,1.175,.7+fill*.5))
  wall(Vector3(.22,.85,1.4),at+Vector3(0,2.775,0))
  var door=DOOR.new()
  add_child(door)
  door.setup(game,at,Vector3.RIGHT,info[1])
  doors.append(door)
 for at in [Vector3(-9.84,1.95,7),Vector3(-9.84,1.95,11),Vector3(9.84,1.95,-11),Vector3(9.84,1.95,-16)]:
  box(Vector3(.05,1.25,2.1),at,"dark",false)
  for z in [-1.08,1.08]:
   box(Vector3(.12,1.4,.08),at+Vector3(0,0,z),"metal",false)
  for y in [-.68,.68]:
   box(Vector3(.12,.07,2.2),at+Vector3(0,y,0),"metal",false)
  for z in [-.7,-.35,0,.35,.7]:
   box(Vector3(.1,1.3,.025),at+Vector3(0,0,z),"metal",false)
 # Bancos deixam de ser blocos maciços. Cadeiras recebem encostos e pernas.
 for x in [4,6.5]:
  for z in [-10,-13,-16]:
   box(Vector3(.6,.55,.06),Vector3(x,.76,z+.96),"wood",false)
   for side in [-.23,.23]:
    box(Vector3(.05,.43,.05),Vector3(x+side,.215,z+.5),"metal",false)
    box(Vector3(.05,.43,.05),Vector3(x+side,.215,z+.86),"metal",false)
 for z in [-10,-18]:
  box(Vector3(1.6,.08,.28),Vector3(-.5,3.08,z),"wall",false)
  var light=OmniLight3D.new()
  light.position=Vector3(-.5,2.85,z)
  light.light_color=Color(.77,.84,1)
  light.light_energy=1.05
  light.omni_range=5.0
  add_child(light)
 # Telefone sobre a bancada: enquadramento próprio na abertura.
 phone=box(Vector3(.17,.025,.30),Vector3(-6.35,.55,11),"dark",false)
 var screen=MeshInstance3D.new()
 var plane=BoxMesh.new()
 plane.size=Vector3(.145,.005,.25)
 screen.mesh=plane
 var screen_mat=StandardMaterial3D.new()
 screen_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 screen_mat.albedo_color=Color(.07,.11,.15)
 screen_mat.emission_enabled=true
 screen_mat.emission=Color(.12,.2,.3)
 screen.material_override=screen_mat
 screen.position.y=.016
 phone.add_child(screen)
 var clock=Label3D.new()
 clock.text="21:43\nSEM SINAL"
 var font: Font=load("res://prototipo/interface.ttf")
 clock.font=font
 clock.font_size=32
 clock.pixel_size=.00075
 clock.rotation_degrees.x=-90
 clock.position=Vector3(0,.02,0)
 phone.add_child(clock)
 # Detalhes de escola, com localização física em vez de rótulos flutuantes.
 sign_at("BEBEDOURO",Vector3(8.3,1.9,1),-90)
 box(Vector3(.65,.9,1),Vector3(8.7,.45,1),"metal")
 sign_at("REFEITÓRIO",Vector3(9.7,2.25,5),-90)
 box(Vector3(1.3,.12,.45),Vector3(-8.5,.45,6),"wood")
 # Rua visível além do portão, para que a saída não termine no vazio.
 box(Vector3(22,.15,12),Vector3(0,-.075,20),"dark")
 box(Vector3(22,.10,1.1),Vector3(0,.05,15),"floor")
 for x in [-7.0,0,7]:
  box(Vector3(5,4.5,.25),Vector3(x,2.25,26),"wall")
  box(Vector3(1.2,2.4,.08),Vector3(x,1.2,25.83),"metal",false)
  box(Vector3(1.3,1,.08),Vector3(x+1.6,2.8,25.83),"dark",false)
 box(Vector3(.12,4,.12),Vector3(4,2,17),"metal")
 var street_light=OmniLight3D.new()
 street_light.position=Vector3(4,3.8,17)
 street_light.omni_range=9
 street_light.light_color=Color(1,.65,.35)
 street_light.light_energy=2.2
 add_child(street_light)

func open_exit() -> void:
 gate.collision_layer=0
 var tween=gate_pivot.create_tween()
 tween.tween_property(gate_pivot,"rotation:y",-1.6,.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func reset_exit() -> void:
 gate.collision_layer=1
 gate.visible=true
 gate_pivot.rotation.y=0

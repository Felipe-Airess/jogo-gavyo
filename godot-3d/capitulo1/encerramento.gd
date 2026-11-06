extends Node3D
## Apenas a cena final do ato 1. Não cria missão ou gameplay do ato 2.
var house_at:=Vector3(100,0,20)
var room_at:=Vector3(100,0,21)
var felipe: Node3D
var bola: Node3D
var phone: Node3D
var notification: OmniLight3D
var roof: MeshInstance3D

func setup(game: Node3D) -> void:
 position=house_at
 _box(Vector3(8,.2,7),Vector3(0,-.1,0),Color(.34,.32,.26))
 _box(Vector3(20,.1,20),Vector3(0,-.25,0),Color(.12,.14,.16))
 roof=_box(Vector3(8.4,.18,7.4),Vector3(0,3.1,0),Color(.25,.21,.17))
 _box(Vector3(8,3,.2),Vector3(0,1.5,-3.5),Color(.56,.52,.38))
 _box(Vector3(.2,3,7),Vector3(-4,1.5,0),Color(.56,.52,.38))
 _box(Vector3(.2,3,7),Vector3(4,1.5,0),Color(.56,.52,.38))
 _box(Vector3(2.9,3,.2),Vector3(-2.55,1.5,3.5),Color(.56,.52,.38))
 _box(Vector3(2.9,3,.2),Vector3(2.55,1.5,3.5),Color(.56,.52,.38))
 _box(Vector3(1.4,.75,.6),Vector3(-2.6,.375,-2.8),Color(.16,.10,.07))
 _box(Vector3(1.5,.85,.10),Vector3(-2.6,1.25,-2.9),Color(.08,.16,.25))
 _box(Vector3(.6,.05,.3),Vector3(-2.6,.79,-2.65),Color(.025,.025,.03))
 # Tela de videogame sem música; luz fria banha quem joga.
 var tv=OmniLight3D.new()
 tv.position=Vector3(-2.6,1.6,-2.4)
 tv.light_color=Color(.3,.55,1); tv.light_energy=1.4; tv.omni_range=5
 add_child(tv)
 for x in [-.5,2.8]: _box(Vector3(.08,2,.08),Vector3(x,1,.6),Color(.21,.13,.07))
 var tool=SurfaceTool.new()
 tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 16:
  var x0=lerpf(-.5,2.8,float(i)/16)
  var x1=lerpf(-.5,2.8,float(i+1)/16)
  var y0=1.75-.85*pow(maxf(0,sin(float(i)/16*PI)),.2)
  var y1=1.75-.85*pow(maxf(0,sin(float(i+1)/16*PI)),.2)
  for v in [Vector3(x0,y0,.1),Vector3(x1,y1,1.1),Vector3(x0,y0,1.1),Vector3(x0,y0,.1),Vector3(x1,y1,.1),Vector3(x1,y1,1.1)]: tool.add_vertex(v)
 tool.generate_normals()
 var hammock=MeshInstance3D.new(); hammock.mesh=tool.commit()
 var mat=StandardMaterial3D.new(); mat.albedo_color=Color(.23,.38,.36); mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 hammock.material_override=mat; add_child(hammock)
 felipe=game.PERSON.new();felipe.model_role="felipe";felipe.cinematic_friend=true
 add_child(felipe);felipe.setup(game,Vector3(.3,0,.6),true);felipe.collision_layer=0
 bola=game.PERSON.new();bola.model_role="bola";bola.cinematic_friend=true
 add_child(bola);bola.setup(game,Vector3(-2.6,0,-.5),true)
 bola.collision_layer=0;bola.face(Vector3(-2.6,0,-3));bola.start_action("prototype/sit");bola.animate(.1)
 _box(Vector3(.8,.4,.8),Vector3(-2.6,.2,-.5),Color(.20,.15,.10))
 var gamepad=_box(Vector3(.24,.06,.12),Vector3(-2.6,.85,-.7),Color(.045,.045,.055))
 phone=_box(Vector3(.15,.02,.26),Vector3(1.8,1.03,.7),Color(.04,.10,.18))
 notification=OmniLight3D.new()
 notification.position=phone.position+Vector3.UP*.1
 notification.light_color=Color(.5,.7,1); notification.omni_range=2; notification.light_energy=.9
 notification.visible=false
 add_child(notification)
 visible=false

func _box(size: Vector3,at: Vector3,color: Color) -> MeshInstance3D:
 var node=MeshInstance3D.new(); var mesh=BoxMesh.new(); mesh.size=size
 node.mesh=mesh; var mat=StandardMaterial3D.new(); mat.albedo_color=color
 mat.roughness=1; node.material_override=mat; node.position=at; add_child(node)
 return node

func update(time: float,dt: float) -> void:
 visible=time>=6.5
 roof.visible=time<9.5
 notification.visible=time>=10.5
 # Felipe pega o celular: o rosto acende com a tela.
 if time>=13.0 and is_instance_valid(felipe):
  phone.position=felipe.position+Vector3(0,1.35,.38)
  notification.position=phone.position+Vector3(0,.05,-.05); notification.light_energy=1.3
 if is_instance_valid(bola): bola.animate(dt)
 if is_instance_valid(felipe): felipe.animate(dt)

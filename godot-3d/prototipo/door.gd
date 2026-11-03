extends Node3D
## Porta com folha e colisão articuladas no mesmo pivô.
var opened := false
var moving := false
var width := 1.4
var pivot: Node3D
var body: StaticBody3D
var normal := Vector3.FORWARD
var title := "Porta"
## Ângulo aberto. Negativo abre para o lado da normal; o capítulo 1 abre para dentro da sala.
var swing := -1.65
var game: Node3D
var motion: Tween

func setup(owner_game: Node3D, at: Vector3, facing: Vector3, label: String) -> void:
 game=owner_game
 position=at
 normal=facing
 rotation.y=atan2(facing.x,facing.z)
 title=label
 pivot=Node3D.new()
 pivot.position.x=-width*.5
 add_child(pivot)
 body=StaticBody3D.new()
 body.collision_layer=1
 body.collision_mask=2
 body.set_meta("door",self)
 pivot.add_child(body)
 body.position=Vector3((width-.04)*.5,1.15,0)
 var mesh=MeshInstance3D.new()
 var box=BoxMesh.new()
 box.size=Vector3(width-.04,2.3,.07)
 mesh.mesh=box
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color(.17,.25,.20)
 mat.roughness=.85
 mesh.material_override=mat
 body.add_child(mesh)
 var cs=CollisionShape3D.new()
 var shape=BoxShape3D.new()
 shape.size=box.size
 cs.shape=shape
 body.add_child(cs)
 # Travessas e maçaneta seguem a folha, incluindo a colisão.
 for y in [-.9,0,.9]:
  var rail=MeshInstance3D.new()
  var strip=BoxMesh.new()
  strip.size=Vector3(width-.12,.04,.085)
  rail.mesh=strip
  rail.material_override=mat
  rail.position.y=y
  body.add_child(rail)
 var handle=MeshInstance3D.new()
 var knob=SphereMesh.new()
 knob.radius=.045
 knob.height=.09
 handle.mesh=knob
 var metal=StandardMaterial3D.new()
 metal.albedo_color=Color(.65,.59,.42)
 metal.metallic=.6
 handle.material_override=metal
 handle.position=Vector3(width*.36,-.05,-.065)
 body.add_child(handle)

func center() -> Vector3:
 return global_position+Vector3(0,1.0,0)

func toggle() -> void:
 set_open(not opened)

func set_open(value: bool, instant := false) -> void:
 opened=value
 if motion and motion.is_valid():
  motion.kill()
 if instant:
  pivot.rotation.y=swing if opened else 0.0
  moving=false
  return
 moving=true
 motion=create_tween()
 motion.tween_property(pivot,"rotation:y",swing if opened else 0.0,.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 motion.tween_callback(func(): moving=false; game._build_paths())

func peek_anchor(player_position: Vector3) -> Dictionary:
 var side=1.0 if (player_position-global_position).dot(normal)>0 else -1.0
 var right=global_basis.x
 return {"position":global_position+right*(width*.5-.02)+normal*side*.15+Vector3.UP*1.48,"direction":-normal*side}

func handle_point(side:=1.0) -> Vector3:
 return body.to_global(Vector3(width*.36,-.05,.065*side))

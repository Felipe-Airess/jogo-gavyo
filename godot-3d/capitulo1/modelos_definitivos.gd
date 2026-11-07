extends RefCounted
## Configura instâncias. Nunca escreve vértices, texturas, pesos ou poses de ossos.
const LEGACY=preload("res://prototipo/arquivo/miguel_animado.glb")
const NEW=preload("res://capitulo1/animacoes/biblioteca.res")
static var entries: Array=[]
static var reference_bounds: Dictionary={}
static var original_library: AnimationLibrary
static func list() -> Array:
 if entries.is_empty(): entries=JSON.parse_string(FileAccess.get_file_as_string("res://capitulo1/assets/definitivos/catalogo.json"))
 return entries
static func data(id: String) -> Dictionary:
 for item in list():
  if item.id==id: return item
 return {}
static func _relative(node: Node3D,root: Node3D) -> Transform3D:
 var matrix=node.transform
 var parent=node.get_parent()
 while parent!=root:
  if parent is Node3D: matrix=parent.transform*matrix
  parent=parent.get_parent()
 return matrix
static func bounds(node: Node3D) -> AABB:
 # Medição CPU da skin em repouso. O AABB dos vértices brutos não inclui os
 # bind poses do FBX. Lê matrizes e pesos; não modifica nenhuma malha ou osso.
 var key=str(node.get_meta("modelo_definitivo",""))
 if not key.is_empty() and reference_bounds.has(key): return reference_bounds[key]
 var found:=false
 var result:=AABB()
 for mesh in node.find_children("*","MeshInstance3D",true,false):
  var sk=mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
  if mesh.skin==null or sk==null:
   var box: AABB=_relative(mesh,node)*mesh.get_aabb()
   result=result.merge(box) if found else box;found=true;continue
  var matrices: Array[Transform3D]=[]
  for bind in mesh.skin.get_bind_count():
   var bone=mesh.skin.get_bind_bone(bind)
   var name=mesh.skin.get_bind_name(bind)
   if not name.is_empty(): bone=sk.find_bone(name)
   assert(bone>=0,"Bind sem osso: "+String(name))
   matrices.append(sk.get_bone_global_rest(bone)*mesh.skin.get_bind_pose(bind))
  var to_root=_relative(sk,node)
  for surface in mesh.mesh.get_surface_count():
   var arrays=mesh.mesh.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
   var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
   var count=bones.size()/vertices.size()
   for i in vertices.size():
    var point=Vector3.ZERO
    for j in count:
     var index=i*count+j
     if weights[index]>0: point+=(matrices[bones[index]]*vertices[i])*weights[index]
    point=to_root*point
    if not found: result=AABB(point,Vector3.ZERO);found=true
    else: result=result.expand(point)
 if not key.is_empty(): reference_bounds[key]=result
 return result
static func instantiate(id: String) -> Node3D:
 var info=data(id)
 assert(not info.is_empty(),"Modelo sem papel definido: "+id)
 # Se o arquivo leve ainda não foi importado (ex.: git pull sem reimportar),
 # usa o detalhado em vez de travar a cena.
 var cena: PackedScene=load(info.arquivo) if ResourceLoader.exists(info.arquivo) else null
 if cena==null and info.has("arquivo_detalhado"):
  push_warning("Modelo leve não importado, usando o detalhado: "+String(info.arquivo))
  cena=load(info.arquivo_detalhado)
 var model: Node3D=cena.instantiate()
 model.set_meta("modelo_definitivo",id)
 var arm=model.get_node("Armature")
 arm.name="MiguelRig" # Somente caminho de ligação das bibliotecas existentes.
 var box=bounds(model)
 var factor: float=info.altura/box.size.y
 model.scale*=factor
 model.position.y=-box.position.y*factor
 model.set_meta("modelo_definitivo",id)
 model.set_meta("altura_real",info.altura)
 var player=AnimationPlayer.new();player.name="AnimationPlayer";model.add_child(player)
 if original_library==null:
  var old=LEGACY.instantiate()
  original_library=old.find_child("AnimationPlayer",true,false).get_animation_library("")
  old.free()
 player.add_animation_library("",original_library)
 return model
static func skeleton(model: Node3D) -> Skeleton3D:
 return model.find_children("*","Skeleton3D",true,false)[0]

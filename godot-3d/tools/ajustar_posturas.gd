extends SceneTree
## Interact fica de fora: o gesto encosta a mão num alvo medido pelos testes.
## Pós-processa capitulo1/animacoes/biblioteca.res (dados de animação, não código
## de jogo): postura parada anatômica e agarrão simétrico. Rodar depois de
## preparar_biblioteca.gd. Idempotente: parte sempre dos clipes de origem.
## godot --headless --path godot-3d -s res://tools/ajustar_posturas.gd
const PATH="res://capitulo1/animacoes/biblioteca.res"
## Quanto do desvio da perna em relação ao repouso (pernas retas) fica.
const LEG_KEEP:=0.35
const STANDING=["Idle","Idle_FoldArms","Idle_Lantern","Idle_No","Idle_Talking",
 "Idle_TalkingPhone","Idle_Torch","Yes","Agarrar","AgarrarEntrada","Empurrar"]
const LEGS=["UpperLeg","LowerLeg","Foot","Toes"]
var sk: Skeleton3D
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var model=load("res://prototipo/arquivo/miguel_animado.glb").instantiate();root.add_child(model)
 sk=model.find_children("*","Skeleton3D",true,false)[0]
 var lib: AnimationLibrary=load(PATH)
 if lib.has_meta("posturas_ajustadas"):
  print("POSTURAS já ajustadas; regenere com preparar_biblioteca.gd antes.");quit(1);return
 for name in STANDING:
  if lib.has_animation(name): narrow_legs(lib.get_animation(name))
 for name in ["Agarrar","AgarrarEntrada"]:
  if lib.has_animation(name): mirror_arm(lib.get_animation(name),"Left","Right")
 lib.set_meta("posturas_ajustadas",{"perna_mantida":LEG_KEEP,"parados":STANDING,"espelho":"Left->Right em Agarrar/AgarrarEntrada"})
 print("POSTURAS erro=",ResourceSaver.save(lib,PATH))
 quit()
func bone_of(a: Animation,t: int) -> int: return sk.find_bone(String(a.track_get_path(t)).get_slice(":",1))
func pose_at(a: Animation,time: float) -> void:
 sk.reset_bone_poses()
 for t in a.get_track_count():
  var b=bone_of(a,t); if b<0: continue
  match a.track_get_type(t):
   Animation.TYPE_ROTATION_3D: sk.set_bone_pose_rotation(b,a.rotation_track_interpolate(t,time))
   Animation.TYPE_POSITION_3D: sk.set_bone_pose_position(b,a.position_track_interpolate(t,time)*sk.motion_scale)
 sk.force_update_all_bone_transforms()
func feet_drop() -> float:
 # Altura do pé mais baixo em relação ao quadril (unidades do esqueleto).
 var hips=sk.get_bone_global_pose(sk.find_bone("Hips")).origin.y
 return hips-minf(sk.get_bone_global_pose(sk.find_bone("LeftFoot")).origin.y,sk.get_bone_global_pose(sk.find_bone("RightFoot")).origin.y)
func narrow_legs(a: Animation) -> void:
 var hips_track=-1
 for t in a.get_track_count():
  if a.track_get_type(t)==Animation.TYPE_POSITION_3D and String(a.track_get_path(t)).ends_with(":Hips"): hips_track=t
 # Mede antes, ajusta pernas, mede depois: o quadril sobe o que a perna esticou.
 var before: Array[float]=[]
 if hips_track>=0:
  for k in a.track_get_key_count(hips_track):
   pose_at(a,a.track_get_key_time(hips_track,k));before.append(feet_drop())
 for t in a.get_track_count():
  if a.track_get_type(t)!=Animation.TYPE_ROTATION_3D: continue
  var name=String(a.track_get_path(t)).get_slice(":",1)
  if not LEGS.any(func(part): return name.ends_with(part)): continue
  var rest: Quaternion=sk.get_bone_rest(sk.find_bone(name)).basis.get_rotation_quaternion()
  for k in a.track_get_key_count(t):
   var q: Quaternion=a.track_get_key_value(t,k)
   a.track_set_key_value(t,k,rest.slerp(q,LEG_KEEP).normalized())
 if hips_track>=0:
  for k in a.track_get_key_count(hips_track):
   pose_at(a,a.track_get_key_time(hips_track,k))
   var p: Vector3=a.track_get_key_value(hips_track,k)
   p.y+=(feet_drop()-before[k])/sk.motion_scale
   a.track_set_key_value(hips_track,k,p)
func mirror_arm(a: Animation,from: String,to: String) -> void:
 # Copia o braço bom para o outro lado, refletido no plano X em espaço global
 # (B' = S·B·S), e reconverte para local sob o pai do lado oposto.
 var S=Basis(Vector3(-1,0,0),Vector3(0,1,0),Vector3(0,0,1))
 var tracks={}
 var times: Array[float]=[]
 for t in a.get_track_count():
  if a.track_get_type(t)!=Animation.TYPE_ROTATION_3D: continue
  var name=String(a.track_get_path(t)).get_slice(":",1)
  if name.begins_with(from) or name.begins_with(to): tracks[name]=t
  if name.begins_with(from) and is_arm(name):
   for k in a.track_get_key_count(t):
    var time=a.track_get_key_time(t,k)
    if not times.has(time): times.append(time)
 times.sort()
 var chain: Array[String]=[]
 for b in sk.get_bone_count():
  var name=sk.get_bone_name(b)
  if name.begins_with(to) and is_arm(name) and tracks.has(name) and tracks.has(from+name.trim_prefix(to)): chain.append(name)
 var values={}
 for name in chain: values[name]=[]
 for time in times:
  pose_at(a,time)
  for name in chain: # ordem do esqueleto: pai antes do filho
   var b=sk.find_bone(name); var src=sk.find_bone(from+name.trim_prefix(to))
   var desired=S*sk.get_bone_global_pose(src).basis*S
   var parent=sk.get_bone_global_pose(sk.get_bone_parent(b)).basis
   var local=(parent.inverse()*desired).get_rotation_quaternion().normalized()
   sk.set_bone_pose_rotation(b,local);sk.force_update_all_bone_transforms()
   values[name].append(local)
 for name in chain:
  var t=tracks[name]
  while a.track_get_key_count(t)>0: a.track_remove_key(t,0)
  for i in times.size(): a.track_insert_key(t,times[i],values[name][i])
func is_arm(name: String) -> bool:
 return not ("Leg" in name or "Foot" in name or "Toes" in name)

extends SceneTree
## Regenera derivados; nunca modifica GLB/FBX de origem.
const DIR="res://capitulo1/animacoes/"
var target: Skeleton3D
var library:=AnimationLibrary.new()
var report: Dictionary={}
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var model=load("res://miguel_animado.glb").instantiate()
 root.add_child(model)
 target=model.find_children("*","Skeleton3D",true,false)[0]
 for pack in ["UAL1","UAL2"]:
  var scene=load(DIR+"quaternius/"+pack+".glb").instantiate()
  var ap=scene.find_children("*","AnimationPlayer",true,false)[0]
  for name in ap.get_animation_list():
   if name=="RESET" or name=="A_TPose": continue
   var clean=clean_clip(ap.get_animation(name))
   library.add_animation(name,clean)
  scene.free()
 for clip in ["Ascending_Stairs","Descending_Stairs","Running_Up_Stairs","Crouch_To_Stand","Walking_Backwards","Stunned","Sweep_Fall"]:
  var scene=load(DIR+"mixamo/"+clip+".fbx").instantiate()
  var ap=scene.find_children("*","AnimationPlayer",true,false)[0]
  library.add_animation(clip,clean_clip(ap.get_animation("mixamo_com"),clip.contains("Stairs")))
  scene.free()
 var ap: AnimationPlayer=model.find_child("AnimationPlayer",true,false)
 ap.add_animation_library("new",library)
 # Só ciclos conhecidos. Não marcar indiscriminadamente ações como loop.
 for name in ["Idle","Walk","Jog_Fwd","Sprint","Crouch_Idle","Crouch_Fwd","Walk_Formal","Zombie_Walk_Fwd","Zombie_Idle","Sitting_Idle","Idle_TalkingPhone","Idle_Lantern","Walking_Backwards","Ascending_Stairs","Running_Up_Stairs"]:
  var clip=library.get_animation(name)
  var metrics=measure_loop(clip)
  report[name]=metrics
  clip.loop_mode=Animation.LOOP_LINEAR
 # Descida recebida é incompleta (94 graus na emenda). Derivado reverso do
 # ciclo completo de subir: provisório explícito, até chegar a descida completa.
 library.add_animation("Descer_Ciclo",descent_clip())
 library.get_animation("Stunned").loop_mode=Animation.LOOP_NONE
 library.get_animation("Descending_Stairs").loop_mode=Animation.LOOP_NONE
 library.add_animation("Deitado",pose_clip(library.get_animation("Sweep_Fall"),2.4))
 library.add_animation("Segurado",pose_clip(library.get_animation("Stunned"),.06))
 library.add_animation("Agarrar",adapt_push(true))
 library.add_animation("Empurrar",adapt_push(false))
 var reach=adapt_push(false)
 reach.length=1.2
 for t in reach.get_track_count():
  for k in range(reach.track_get_key_count(t)-1,-1,-1):
   reach.track_set_key_time(t,k,reach.track_get_key_time(t,k)*1.2/.85)
 library.add_animation("AgarrarEntrada",reach)
 for item in [["Empurrar",.30,"contact"],["Interact",.72,"contact"],
 ["PickUp_Table",.30,"contact"],["Chest_Open",.60,"contact"],["ClimbUp_1m",.12,"contact"],
 ["Zombie_Scratch",.55,"contact"],["AgarrarEntrada",.30*1.2/.85,"contact"]]:
  var a=library.get_animation(item[0])
  var t=a.add_track(Animation.TYPE_METHOD); a.track_set_path(t,NodePath(".."))
  a.track_insert_key(t,item[1],{"method":"_animation_event","args":[item[2]]})
 var metrics={}
 for name in ["Walk","Sprint","Crouch_Fwd","Walking_Backwards","Ascending_Stairs","Running_Up_Stairs","Descer_Ciclo"]:
  metrics[name]=measure_stride(ap,name)
 var metric_file=FileAccess.open(DIR+"metricas.json",FileAccess.WRITE)
 metric_file.store_string(JSON.stringify(metrics,"  "))
 # Salva biblioteca com todos os clipes compatíveis e relatório de emendas brutas.
 var err=ResourceSaver.save(library,DIR+"biblioteca.res")
 var file=FileAccess.open("res://../docs/verificacao-animacoes-20261102/emendas-originais.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 print("BIBLIOTECA ",library.get_animation_list().size()," erro=",err)
 # Reexpressa a biblioteca procedural histórica no novo referencial do rig.
 var document=GLTFDocument.new()
 var state=GLTFState.new()
 document.append_from_file("res://miguel_animado.glb",state)
 var original=document.generate_scene(state)
 var old: Skeleton3D=original.find_children("*","Skeleton3D",true,false)[0]
 var legacy: AnimationLibrary=load("res://prototipo/motions.tres").duplicate(true)
 for name in legacy.get_animation_list():
  var a=legacy.get_animation(name)
  for t in a.get_track_count():
   var bone=String(a.track_get_path(t)).get_slice(":",1)
   var id=target.find_bone(bone)
   var oi=old.find_bone(bone)
   if id<0 or oi<0: continue
   var parent=target.get_bone_parent(id)
   var op=old.get_bone_parent(oi)
   var pre=(target.get_bone_global_rest(parent).basis if parent>=0 else Basis.IDENTITY).inverse()*(old.get_bone_global_rest(op).basis if op>=0 else Basis.IDENTITY)
   var post=old.get_bone_global_rest(oi).basis.inverse()*target.get_bone_global_rest(id).basis
   for k in a.track_get_key_count(t):
    var value=a.track_get_key_value(t,k)
    if a.track_get_type(t)==Animation.TYPE_ROTATION_3D:
     value=(pre*Basis(value)*post).get_rotation_quaternion().normalized()
    elif a.track_get_type(t)==Animation.TYPE_POSITION_3D and bone=="Hips": value/=target.motion_scale
    a.track_set_key_value(t,k,value)
 ResourceSaver.save(legacy,DIR+"prototipo_compativel.res")
 original.free(); model.free()
 quit(err)
func clean_clip(source: Animation, stairs:=false) -> Animation:
 var a: Animation=source.duplicate(true)
 a.loop_mode=Animation.LOOP_NONE
 for t in range(a.get_track_count()-1,-1,-1):
  var path=a.track_get_path(t)
  var bone=String(path).get_slice(":",1)
  var type=a.track_get_type(t)
  if target.find_bone(bone)<0 or (type!=Animation.TYPE_ROTATION_3D and not (type==Animation.TYPE_POSITION_3D and bone=="Hips")):
   a.remove_track(t); continue
  a.track_set_path(t,NodePath("MiguelRig/Skeleton3D:"+bone))
  if type==Animation.TYPE_POSITION_3D:
   var first: Vector3=a.track_get_key_value(t,0)
   var last: Vector3=a.track_get_key_value(t,a.track_get_key_count(t)-1)
   for k in a.track_get_key_count(t):
    var p: Vector3=a.track_get_key_value(t,k)
    var ratio=a.track_get_key_time(t,k)/a.length
    # Deslocamento pertence à cápsula. Escadas não acumulam altura na malha.
    p.x=0; p.z=0
    if stairs: p.y-=lerpf(0,last.y-first.y,ratio)
    a.track_set_key_value(t,k,p)
 return a
func measure_loop(a: Animation) -> Dictionary:
 var rotation=0.0; var hips=0.0
 for t in a.get_track_count():
  var first=a.track_get_key_value(t,0)
  var last=a.track_get_key_value(t,a.track_get_key_count(t)-1)
  if first is Quaternion: rotation=maxf(rotation,rad_to_deg(first.angle_to(last)))
  if first is Vector3: hips=maxf(hips,first.distance_to(last)*target.motion_scale)
 return {"duration":a.length,"rotation_degrees":rotation,"hips_metres":hips,"tracks":a.get_track_count()}

func sample(a: Animation,t: int,time: float):
 if a.track_get_type(t)==Animation.TYPE_ROTATION_3D: return a.rotation_track_interpolate(t,time)
 return a.position_track_interpolate(t,time)

func pose_clip(source: Animation,time: float) -> Animation:
 var result=Animation.new(); result.length=1; result.loop_mode=Animation.LOOP_LINEAR
 for t in source.get_track_count():
  if source.track_get_type(t)==Animation.TYPE_METHOD: continue
  var id=result.add_track(source.track_get_type(t)); result.track_set_path(id,source.track_get_path(t))
  var value=sample(source,t,time)
  result.track_insert_key(id,0,value); result.track_insert_key(id,1,value)
 return result

func descent_clip() -> Animation:
 # Mapa usa rampa física. Preserva o ciclo completo de andar nas pernas e
 # a postura de descida recebida no tronco; não repete as pernas incompletas.
 var result=library.get_animation("Walk").duplicate(true)
 var source=library.get_animation("Descending_Stairs")
 for t in result.get_track_count():
  var bone=String(result.track_get_path(t)).get_slice(":",1)
  if bone not in ["Chest","UpperChest","Neck","Head"]: continue
  var st=source.find_track(result.track_get_path(t),result.track_get_type(t))
  if st<0: continue
  for k in result.track_get_key_count(t):
   result.track_set_key_value(t,k,sample(source,st,0))
 return result

func adapt_push(hold: bool) -> Animation:
 var idle=library.get_animation("Idle")
 var result=Animation.new(); result.length=1.8 if hold else .85
 result.loop_mode=Animation.LOOP_LINEAR if hold else Animation.LOOP_NONE
 for t in idle.get_track_count():
  var id=result.add_track(idle.track_get_type(t)); result.track_set_path(id,idle.track_get_path(t))
 for key in ([[0,1],[.9,.96],[1.8,1]] if hold else [[0,0],[.12,.12],[.30,1],[.40,1],[.85,0]]):
  target.reset_bone_poses()
  for t in idle.get_track_count():
   var bone=target.find_bone(String(idle.track_get_path(t)).get_slice(":",1))
   var value=sample(idle,t,0)
   if value is Quaternion: target.set_bone_pose_rotation(bone,value)
   else: target.set_bone_pose_position(bone,value*target.motion_scale)
  target.force_update_all_bone_transforms()
  for side in ["Left","Right"]:
   var mirror=1.0 if side=="Left" else -1.0
   orient(side+"UpperArm",side+"LowerArm",Vector3(.28*mirror,-.35,.90).normalized(),key[1])
   orient(side+"LowerArm",side+"Hand",Vector3(-.15*mirror,.18,.98).normalized(),key[1])
  for t in idle.get_track_count():
   var bone=target.find_bone(String(idle.track_get_path(t)).get_slice(":",1))
   var value=target.get_bone_pose_rotation(bone) if idle.track_get_type(t)==Animation.TYPE_ROTATION_3D else target.get_bone_pose_position(bone)/target.motion_scale
   result.track_insert_key(t,key[0],value)
 return result

func orient(bone: String,child: String,direction: Vector3,weight: float) -> void:
 var id=target.find_bone(bone); var end=target.find_bone(child)
 var pose=target.get_bone_global_pose(id)
 var current=target.get_bone_global_pose(end).origin-pose.origin
 var desired=Basis(Quaternion(current.normalized(),direction))*pose.basis
 var parent=target.get_bone_parent(id)
 var local=(target.get_bone_global_pose(parent).basis.inverse()*desired).get_rotation_quaternion().normalized()
 target.set_bone_pose_rotation(id,target.get_bone_pose_rotation(id).slerp(local,weight))
 target.force_update_all_bone_transforms()

func measure_stride(ap: AnimationPlayer,name: String) -> Dictionary:
 var a=library.get_animation(name)
 ap.play("new/"+name,0)
 var speeds=[]; var previous=[]
 var steps=120; var dt=a.length/steps
 var backward=name=="Walking_Backwards"
 for i in steps:
  ap.seek(i*dt,true); target.force_update_all_bone_transforms()
  var feet=[]
  for b in ["LeftFoot","RightFoot"]: feet.append(target.get_bone_global_pose(target.find_bone(b)).origin)
  if not previous.is_empty():
   var side=0 if feet[0].y<feet[1].y else 1
   var v=(feet[side].z-previous[side].z)/dt*(1 if backward else -1)
   if v>.05: speeds.append(v)
  previous=feet
 speeds.sort()
 var nominal=speeds[speeds.size()/2] if not speeds.is_empty() else 1.0
 return {"stride":nominal*a.length,"native_speed":nominal,"duration":a.length,"samples":speeds.size()}

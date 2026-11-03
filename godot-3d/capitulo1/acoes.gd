extends RefCounted
## Clipes FK próprios montados sobre a pose de guarda (sem IK de mão, sem
## captura nova): pegada/derrubada antiga e agarrão do
## cultista. Cada chave: [tempo, peso, direção do braço, direção do antebraço,
## inclinação do tronco]. Direções no espaço do personagem (+z = frente);
## x é espelhado entre os lados.

const TAKEDOWN:=[[0.0,0.0],[.45,1.0,Vector3(.08,.15,1),Vector3(-.32,.05,1),.10],
 [.9,1.0,Vector3(.08,-.25,1),Vector3(-.32,-.08,1),.10],[1.3,1.0,Vector3(.08,-.25,1),Vector3(-.32,-.08,1),.10],
 [1.65,.45,Vector3(.08,-.25,1),Vector3(-.32,-.08,1),.10],[2.05,0.0]]
## Agarrão do cultista (laço de 1,8 s): braços à altura do ombro, apertando.
const GRAB:=[[0.0,1.0,Vector3(.10,.12,1),Vector3(-.30,.10,1),.16],
 [.9,1.0,Vector3(.16,.02,1),Vector3(-.22,.0,1),.22],[1.8,1.0,Vector3(.10,.12,1),Vector3(-.30,.10,1),.16]]

static func build(actor: CharacterBody3D) -> AnimationLibrary:
 var library=AnimationLibrary.new()
 library.add_animation("takedown",clip(actor,TAKEDOWN))
 var grab:=clip(actor,GRAB)
 grab.loop_mode=Animation.LOOP_LINEAR
 library.add_animation("agarrao",grab)
 actor.play("guarda"); actor.animate(0)
 return library

static func clip(actor: CharacterBody3D,keys: Array) -> Animation:
 var anim=Animation.new()
 anim.length=float(keys[-1][0])
 var source: Animation=actor.anim.get_animation("guarda")
 for i in source.get_track_count():
  var id=anim.add_track(source.track_get_type(i))
  anim.track_set_path(id,source.track_get_path(i))
 for key in keys:
  # Amostra estática da guarda para gerar chaves, sem reproduzir outro player.
  for track in source.get_track_count():
   var bone=actor.rig.find_bone(String(source.track_get_path(track)).get_slice(":",1))
   var value=source.track_get_key_value(track,0)
   match source.track_get_type(track):
    Animation.TYPE_POSITION_3D: actor.rig.set_bone_pose_position(bone,value)
    Animation.TYPE_ROTATION_3D: actor.rig.set_bone_pose_rotation(bone,value)
    Animation.TYPE_SCALE_3D: actor.rig.set_bone_pose_scale(bone,value)
  actor.rig.force_update_all_bone_transforms()
  var w: float=key[1]
  if w>0:
   actor._bend("Chest",Vector3.ZERO,Vector3(float(key[4])*w,0,0))
   actor.rig.force_update_all_bone_transforms()
   for side in ["Left","Right"]:
    var s=1.0 if side=="Left" else -1.0
    var upper: Vector3=key[2]; var lower: Vector3=key[3]
    _orient(actor,side+"UpperArm",side+"LowerArm",Vector3(upper.x*s,upper.y,upper.z).normalized(),w)
    _orient(actor,side+"LowerArm",side+"Hand",Vector3(lower.x*s,lower.y,lower.z).normalized(),w)
  for i in source.get_track_count():
   var bone=actor.rig.find_bone(String(source.track_get_path(i)).get_slice(":",1))
   var value
   match source.track_get_type(i):
    Animation.TYPE_POSITION_3D: value=actor.rig.get_bone_pose_position(bone)
    Animation.TYPE_ROTATION_3D: value=actor.rig.get_bone_pose_rotation(bone)
    Animation.TYPE_SCALE_3D: value=actor.rig.get_bone_pose_scale(bone)
   if value!=null: anim.track_insert_key(i,float(key[0]),value)
 return anim

static func _orient(actor: CharacterBody3D,bone_name: String,child_name: String,direction: Vector3,weight: float) -> void:
 var rig: Skeleton3D=actor.rig
 rig.force_update_all_bone_transforms()
 var id=rig.find_bone(bone_name)
 var pose=rig.get_bone_global_pose(id)
 var child=rig.get_bone_global_pose(rig.find_bone(child_name))
 var turn=Quaternion((child.origin-pose.origin).normalized(),direction)
 var desired=Basis(turn)*pose.basis
 var parent=rig.get_bone_parent(id)
 var parent_basis=Basis.IDENTITY if parent<0 else rig.get_bone_global_pose(parent).basis
 var local=(parent_basis.inverse()*desired).get_rotation_quaternion().normalized()
 rig.set_bone_pose_rotation(id,rig.get_bone_pose_rotation(id).slerp(local,weight))
 rig.force_update_all_bone_transforms()

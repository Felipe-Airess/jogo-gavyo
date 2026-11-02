extends RefCounted
## Chaves FK próprias da ação de agarrar/pressionar e derrubar. Nenhum IK de mão.
static func build(actor: CharacterBody3D) -> AnimationLibrary:
 var anim=Animation.new()
 anim.length=2.05
 var source: Animation=actor.anim.get_animation("guarda")
 for i in source.get_track_count():
  var id=anim.add_track(source.track_get_type(i))
  anim.track_set_path(id,source.track_get_path(i))
 for t in [0.0,.45,.9,1.3,1.65,2.05]:
  actor.anim.play("guarda",0); actor.anim.seek(0,true)
  actor.rig.force_update_all_bone_transforms()
  var w=0.0 if t==0 or t==2.05 else (0.45 if t==1.65 else 1.0)
  if w>0:
   var downward=-.25 if t>=.9 else .15
   actor._bend("Chest",Vector3.ZERO,Vector3(.10*w,0,0))
   actor.rig.force_update_all_bone_transforms()
   for side in ["Left","Right"]:
    var sign_side=1.0 if side=="Left" else -1.0
    _orient(actor,side+"UpperArm",side+"LowerArm",Vector3(sign_side*.08,downward,1).normalized(),w)
    _orient(actor,side+"LowerArm",side+"Hand",Vector3(-sign_side*.32,downward*.3,1).normalized(),w)
  for i in source.get_track_count():
   var bone=actor.rig.find_bone(String(source.track_get_path(i)).get_slice(":",1))
   var value
   match source.track_get_type(i):
    Animation.TYPE_POSITION_3D: value=actor.rig.get_bone_pose_position(bone)
    Animation.TYPE_ROTATION_3D: value=actor.rig.get_bone_pose_rotation(bone)
    Animation.TYPE_SCALE_3D: value=actor.rig.get_bone_pose_scale(bone)
   if value!=null: anim.track_insert_key(i,t,value)
 var library=AnimationLibrary.new()
 library.add_animation("takedown",anim)
 actor.anim.stop(); actor.play("guarda"); actor.animate(0)
 return library

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

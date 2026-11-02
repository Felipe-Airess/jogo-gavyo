extends RefCounted
## Geometria no mesmo tick da pose, sem depender do atraso de BoneAttachment.
static func hands_touch(attacker: CharacterBody3D,target: CharacterBody3D) -> bool:
 if target.dead or target.down: return false
 for side in ["Left","Right"]:
  var hand: Vector3=attacker.bone_point(side+"Hand")
  var elbow: Vector3=attacker.bone_point(side+"LowerArm")
  var palm=hand+(hand-elbow).normalized()*.055
  if not attacker.world.visible_between(attacker.bone_point("Chest"),palm): continue
  for zone in [["Chest",.24],["Spine",.23],["UpperChest",.23]]:
   var centre: Vector3=target.bone_point(zone[0])
   if palm.distance_to(centre)<=float(zone[1])+.075 and attacker.world.visible_between(palm,centre): return true
 return false

static func room_for(actor: CharacterBody3D,at: Vector3) -> bool:
 var shape=CapsuleShape3D.new(); shape.radius=.27; shape.height=1.64
 var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape
 q.transform.origin=at+Vector3.UP*.83
 q.collision_mask=3; q.exclude=[actor.get_rid()]
 return actor.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()

## IK analítica de dois ossos: só rotações, sem esticar/transladar membros.
## Mantém dobra mínima e retorna falso se o alvo não cabe no comprimento real.
static func hand_fit(actor: CharacterBody3D,side: String,at: Vector3,weight: float) -> bool:
 return limb_fit(actor,side+"UpperArm",side+"LowerArm",side+"Hand",at,weight)

static func limb_fit(actor: CharacterBody3D,upper_name: String,lower_name: String,end_name: String,at: Vector3,weight: float) -> bool:
 var rig: Skeleton3D=actor.rig
 var upper=rig.find_bone(upper_name); var lower=rig.find_bone(lower_name); var hand=rig.find_bone(end_name)
 rig.force_update_all_bone_transforms()
 var a=rig.get_bone_global_pose(upper).origin
 var b=rig.get_bone_global_pose(lower).origin
 var c=rig.get_bone_global_pose(hand).origin
 var destination=rig.to_local(at)
 var l1=a.distance_to(b); var l2=b.distance_to(c)
 var delta=destination-a; var distance=delta.length()
 if distance>l1+l2-.015 or distance<absf(l1-l2)+.04: return false
 var direction=delta/distance
 var pole=(b-a)-direction*(b-a).dot(direction)
 if pole.length()<.01: pole=Vector3.DOWN-direction*Vector3.DOWN.dot(direction)
 pole=pole.normalized()
 var along=(l1*l1-l2*l2+distance*distance)/(2*distance)
 var elbow=a+direction*along+pole*sqrt(maxf(0,l1*l1-along*along))
 var saved_upper=rig.get_bone_pose_rotation(upper); var saved_lower=rig.get_bone_pose_rotation(lower)
 _turn(rig,upper,lower,elbow)
 _turn(rig,lower,hand,destination)
 var wanted_upper=rig.get_bone_pose_rotation(upper); var wanted_lower=rig.get_bone_pose_rotation(lower)
 rig.set_bone_pose_rotation(upper,saved_upper.slerp(wanted_upper,weight))
 rig.set_bone_pose_rotation(lower,saved_lower.slerp(wanted_lower,weight))
 rig.force_update_all_bone_transforms()
 return true

static func _turn(rig: Skeleton3D,bone: int,child: int,at: Vector3) -> void:
 var pose=rig.get_bone_global_pose(bone)
 var current=rig.get_bone_global_pose(child).origin-pose.origin
 var wanted=at-pose.origin
 var basis=Basis(Quaternion(current.normalized(),wanted.normalized()))*pose.basis
 var parent=rig.get_bone_parent(bone)
 var local=rig.get_bone_global_pose(parent).basis.inverse()*basis if parent>=0 else basis
 rig.set_bone_pose_rotation(bone,local.get_rotation_quaternion().normalized())
 rig.force_update_all_bone_transforms()

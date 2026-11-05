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

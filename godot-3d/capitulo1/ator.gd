extends "res://prototipo/actor.gd"
## Variações derivadas em memória: preserva arquivo e malhas aprovados de Miguel.
var style := 0
var bleed := 0.0
var help_clock := 0.0
var knocked_before := false
var tool_pose := false
var alert_attempt := false
var cinematic_friend:=false
var activity:=""
var evidence: Dictionary={}
var support_blend:=0.0
var support_rotations: Dictionary={}

func _generic_body() -> void:
 # Reaproveita a pele/rig humanoide, substituindo a cabeça e os materiais.
 # Remove índices da cabeça original para não apresentar o rosto de Miguel como cultista.
 style=posmod(style,3)
 var colors=[Color(.20,.16,.15),Color(.13,.18,.18),Color(.20,.20,.14)]
 for visual in model.find_children("*","MeshInstance3D",true,false):
  var source: Mesh=visual.mesh
  var mesh=ArrayMesh.new()
  for surface in source.get_surface_count():
   var arrays=source.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   var kept=PackedInt32Array()
   for i in range(0,indices.size(),3):
    if vertices[indices[i]].y>1.49 or vertices[indices[i+1]].y>1.49 or vertices[indices[i+2]].y>1.49: continue
    kept.append(indices[i]); kept.append(indices[i+1]); kept.append(indices[i+2])
   arrays[Mesh.ARRAY_INDEX]=kept
   mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   var mat=StandardMaterial3D.new()
   mat.albedo_color=colors[style] if surface==1 else Color(.09,.10,.105)
   mat.roughness=1
   mesh.surface_set_material(surface,mat)
   visual.set_surface_override_material(surface,null)
  visual.mesh=mesh
 var head=BoneAttachment3D.new()
 head.bone_name="Head"
 rig.add_child(head)
 var skin=Color(.60,.56,.43) if pursuer else Color(.55,.52,.43)
 _ellipsoid(head,Vector3(0,.025,.02),Vector3(.155,.22,.155),skin)
 if not pursuer and not cinematic_friend:
  _ellipsoid(head,Vector3(0,.06,-.035),Vector3(.19,.245,.17),colors[style])
  _part(head,Vector3(0,-.055,.153),Vector3(.25,.17,.06),Color(.12,.11,.10))
 else:
  _ellipsoid(head,Vector3(0,-.015,.165),Vector3(.03,.065,.045),skin)
  _ellipsoid(head,Vector3(0,-.105,.15),Vector3(.065,.010,.016),Color(.16,.055,.035))
  for x in [-.057,.057]:
   _ellipsoid(head,Vector3(x,.044+.006*signf(x),.15),Vector3(.035,.014,.019),Color(.15,.13,.10))
   _ellipsoid(head,Vector3(x,.043+.006*signf(x),.17),Vector3(.019,.010,.009),Color(.72,.69,.54))
   _ellipsoid(head,Vector3(x,.043+.006*signf(x),.178),Vector3(.007,.009,.005),Color(.025,.018,.012))
 # Colar alto cobre a união do pescoço; visual não altera os ossos.
 var collar=BoneAttachment3D.new()
 collar.bone_name="Neck"
 rig.add_child(collar)
 _ellipsoid(collar,Vector3(0,-.025,0),Vector3(.16,.13,.14),colors[style])

func _part(parent: Node3D,at: Vector3,size: Vector3,color: Color) -> void:
 var node=MeshInstance3D.new()
 var mesh=BoxMesh.new()
 mesh.size=size
 node.mesh=mesh
 var mat=StandardMaterial3D.new()
 mat.albedo_color=color
 mat.roughness=1
 node.material_override=mat
 node.position=at
 parent.add_child(node)

func _ellipsoid(parent: Node3D,at: Vector3,size: Vector3,color: Color) -> void:
 var node=MeshInstance3D.new()
 var mesh=SphereMesh.new()
 mesh.radius=1
 mesh.height=2
 mesh.radial_segments=12
 mesh.rings=6
 node.mesh=mesh
 node.scale=size
 var mat=StandardMaterial3D.new()
 mat.albedo_color=color
 mat.roughness=1
 node.material_override=mat
 node.position=at
 parent.add_child(node)

func make_down() -> void:
 super.make_down()
 for area in hurt_areas: area.collision_layer=4
 knocked_before=true
 help_clock=0

func fist_point() -> Vector3:
 if strike_bone in ["RightFoot","LeftFoot"]:
  var foot=bone_point(strike_bone)
  return foot+(foot-bone_point("RightLowerLeg" if strike_bone=="RightFoot" else "LeftLowerLeg")).normalized()*.08
 return super.fist_point()

func animate(dt: float) -> void:
 super.animate(dt)
 if warning:
  warning.visible=not dead and not down and (state=="windup" or opening>0 or (suspicion>.1 and not aware))
 if not enemy and state=="idle" and velocity.length()>.3 and world.locked==null:
  _support_pose(dt)
 if enemy and health<60 and not down:
  _bend("Chest",Vector3.ZERO,Vector3(.16,0,.04))
  _bend("Head",Vector3.ZERO,Vector3(.08,0,0))
  rig.force_update_all_bone_transforms()

 if state=="paired":
  var backward=get_meta("environment_kind","") in ["parede","armário"]
  _bend("Chest",Vector3.ZERO,Vector3(-.18 if backward else .22,0,0))
  _bend("Head",Vector3.ZERO,Vector3(-.12 if backward else .12,0,0))
  rig.force_update_all_bone_transforms()
 if activity=="ritual" and not aware:
  _bend("LeftUpperArm",Vector3.ZERO,Vector3(-1.5-.12*sin(world.elapsed),0,-.4))
  _bend("RightUpperArm",Vector3.ZERO,Vector3(-1.5-.12*sin(world.elapsed),0,.4))
  _bend("Head",Vector3.ZERO,Vector3(-.15,0,0))
  rig.force_update_all_bone_transforms()
 if tool_pose and not down:
  _bend("RightUpperArm",Vector3.ZERO,Vector3(-.55,0,-.15))
  _bend("RightLowerArm",Vector3.ZERO,Vector3(-.7,0,0))
  rig.force_update_all_bone_transforms()


func _support_pose(dt: float) -> void:
 var found=false
 var space=get_world_3d().direct_space_state
 for side in ["Left","Right"]:
  var sign_side=1.0 if side=="Left" else -1.0
  var outward: Vector3=model.global_basis.x*sign_side
  var origin=position+Vector3.UP*1.2
  var wall=space.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+outward*.5,1))
  var table_from=position+facing*.4+Vector3.UP*1.1
  var table=space.intersect_ray(PhysicsRayQueryParameters3D.create(table_from,table_from-Vector3.UP*.45,1))
  if wall.is_empty() and table.is_empty(): continue
  var saved={}
  for name in [side+"UpperArm",side+"LowerArm"]: saved[name]=rig.get_bone_pose_rotation(rig.find_bone(name))
  var action=load("res://capitulo1/acoes.gd")
  action._orient(self,side+"UpperArm",side+"LowerArm",Vector3(0,-.5,.8).normalized() if not wall.is_empty() else Vector3(0,-.9,.35).normalized(),1)
  action._orient(self,side+"LowerArm",side+"Hand",Vector3(sign_side*.25,.6,.7).normalized() if not wall.is_empty() else Vector3(0,-.75,.65).normalized(),1)
  var wrist=bone_point(side+"Hand")
  var normal: Vector3=wall["normal"] if not wall.is_empty() else Vector3.UP
  var contact=space.intersect_ray(PhysicsRayQueryParameters3D.create(wrist+normal*.12,wrist-normal*.12,1))
  if not contact.is_empty() and wrist.distance_to(contact["position"])<.10:
   support_rotations.clear()
   for name in saved: support_rotations[name]=rig.get_bone_pose_rotation(rig.find_bone(name))
   found=true
  for name in saved: rig.set_bone_pose_rotation(rig.find_bone(name),saved[name])
  if found: break
 support_blend=lerpf(support_blend,1.0 if found else 0.0,1-exp(-12*dt))
 for name in support_rotations:
  var id=rig.find_bone(name)
  rig.set_bone_pose_rotation(id,rig.get_bone_pose_rotation(id).slerp(support_rotations[name],support_blend))
 rig.force_update_all_bone_transforms()

extends SceneTree
## Biblioteca exclusiva do protótipo; não modifica o GLB aprovado nem a galeria.
var model: Node3D
var rig: Skeleton3D
var ap: AnimationPlayer
var library := AnimationLibrary.new()
var report := {}

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 model=load("res://prototipo/arquivo/miguel_animado.glb").instantiate()
 root.add_child(model)
 rig=model.find_children("*","Skeleton3D",true,false)[0]
 ap=model.find_child("AnimationPlayer",true,false)
 ap.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 bake("relaxed","Start_Walking",0,0,2.4,true,"breath")
 bake("walk","Start_Walking",1.5,2.9,1.4,true,"")
 bake("run","Start_Walking",0,0,.70,true,"run")
 bake("slip","gancho",0,0,.56,false,"slip")
 bake("hook","gancho",0,1.6333333,1.18,false,"")
 bake("sit","Start_Walking",0,0,2.4,true,"sit")
 var error=ResourceSaver.save(library,"res://prototipo/motions.tres")
 var file=FileAccess.open("res://prototipo/motions.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "))
 var profile=FileAccess.open("res://prototipo/motion_profile.gd",FileAccess.WRITE)
 profile.store_string("extends RefCounted\n# Gerado pela medição do gancho, sem IK.\nconst YAW_BIAS := %.9f\nconst CONTACT_TIME := %.9f\nconst DURATION := 1.18\nconst ACTIVE_FROM := %.9f\nconst ACTIVE_TO := %.9f\n"%[report["hook"]["contact"]["yaw_bias"],report["hook"]["contact"]["time"],report["hook"]["contact"]["time"]-.12,report["hook"]["contact"]["time"]+.09])
 print("MOTION_LIBRARY ",error," ",JSON.stringify(report))
 model.free()
 quit(0 if error==OK else 1)

func world_turn(bone: String, angle: Vector3) -> void:
 var index=rig.find_bone(bone)
 rig.force_update_all_bone_transforms()
 var pose=rig.get_bone_global_pose(index)
 pose.basis=Basis(Quaternion.from_euler(angle))*pose.basis
 var parent=rig.get_bone_parent(index)
 var parent_pose=Transform3D.IDENTITY if parent<0 else rig.get_bone_global_pose(parent)
 var local=parent_pose.affine_inverse()*pose
 rig.set_bone_pose_rotation(index,local.basis.get_rotation_quaternion().normalized())

func set_world_basis(bone: String, basis: Basis) -> void:
 var index=rig.find_bone(bone)
 var parent=rig.get_bone_parent(index)
 var parent_pose=Transform3D.IDENTITY if parent<0 else rig.get_bone_global_pose(parent)
 rig.set_bone_pose_rotation(index,(parent_pose.basis.inverse()*basis).get_rotation_quaternion().normalized())
 rig.force_update_all_bone_transforms()

func leg_to(side: String, target: Vector3, foot_basis: Basis) -> void:
 rig.force_update_all_bone_transforms()
 var hip=rig.get_bone_global_pose(rig.find_bone(side+"UpperLeg"))
 var knee=rig.get_bone_global_pose(rig.find_bone(side+"LowerLeg"))
 var foot=rig.get_bone_global_pose(rig.find_bone(side+"Foot"))
 var upper=hip.origin.distance_to(knee.origin)
 var lower=knee.origin.distance_to(foot.origin)
 var delta=target-hip.origin
 var distance=clampf(delta.length(),absf(upper-lower)+.001,upper+lower-.001)
 var direction=delta.normalized()
 var pole=(Vector3.BACK-direction*Vector3.BACK.dot(direction)).normalized()
 var along=(upper*upper-lower*lower+distance*distance)/(2*distance)
 var desired_knee=hip.origin+direction*along+pole*sqrt(maxf(0,upper*upper-along*along))
 var turn=Quaternion((knee.origin-hip.origin).normalized(),(desired_knee-hip.origin).normalized())
 set_world_basis(side+"UpperLeg",Basis(turn)*hip.basis)
 knee=rig.get_bone_global_pose(rig.find_bone(side+"LowerLeg"))
 foot=rig.get_bone_global_pose(rig.find_bone(side+"Foot"))
 turn=Quaternion((foot.origin-knee.origin).normalized(),(target-knee.origin).normalized())
 set_world_basis(side+"LowerLeg",Basis(turn)*knee.basis)
 set_world_basis(side+"Foot",foot_basis)

func offset_hips(value: Vector3) -> void:
 var i=rig.find_bone("Hips")
 rig.set_bone_pose_position(i,rig.get_bone_pose_position(i)+value)
 rig.force_update_all_bone_transforms()

func bake(name: String, source: String, start: float, end: float, duration: float, loop: bool, procedural: String) -> void:
 var animation=Animation.new()
 animation.length=duration
 animation.loop_mode=Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
 var original=ap.get_animation(source)
 var tracks=[]
 for bone in rig.get_bone_count():
  var path=NodePath(String(rig.get_path()).get_slice("/",-1))
  # O AnimationPlayer importado usa caminho relativo ao nó raiz do modelo.
  for channel in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]:
   var original_path=NodePath("")
   for i in original.get_track_count():
    if original.track_get_type(i)==channel and String(original.track_get_path(i)).get_slice(":",1)==rig.get_bone_name(bone):
     original_path=original.track_get_path(i)
     break
   if String(original_path)=="":
    continue
   var track=animation.add_track(channel)
   animation.track_set_path(track,original_path)
   tracks.append([track,bone,channel])
 var frames=maxi(2,ceili(duration*60))
 var first=[]
 var max_reach=-1.0
 var hit_data={}
 ap.play(source,0)
 for frame in range(frames+1):
  var t=duration*float(frame)/frames
  var phase=t/duration
  ap.seek(lerpf(start,end,phase),true)
  rig.force_update_all_bone_transforms()
  if procedural=="breath":
   offset_hips(Vector3(0,sin(phase*TAU)*.003,0))
   world_turn("Chest",Vector3(sin(phase*TAU)*.008,0,0))
  elif procedural=="run":
   var cycle=phase*TAU
   offset_hips(Vector3(0,-.13+.012*sin(cycle*2),0))
   world_turn("Chest",Vector3(.14,0,0))
   for side in [["Left",phase],["Right",fposmod(phase+.5,1.0)]]:
    var u=fposmod(side[1],1.0)
    var stance=u<.5
    var travel=u*2 if stance else (u-.5)*2
    var z=lerpf(.42,-.42,travel) if stance else lerpf(-.42,.42,travel)
    var y=.13 if stance else .13+sin(travel*PI)*.28
    var foot=rig.get_bone_global_pose(rig.find_bone(side[0]+"Foot"))
    leg_to(side[0],Vector3(foot.origin.x,y,z),foot.basis)
    var swing=sin(u*TAU)
    world_turn(side[0]+"UpperArm",Vector3(swing*.6,0,0))
    world_turn(side[0]+"LowerArm",Vector3(-.8,0,0))
  elif procedural=="slip":
   var w=sin(phase*PI)
   offset_hips(Vector3(-.17*w,-.055*w,-.08*w))
   world_turn("Chest",Vector3(-.15*w,0,.24*w))
   world_turn("Head",Vector3(.05*w,0,-.08*w))
  elif procedural=="sit":
   offset_hips(Vector3(0,-.42,0))
   world_turn("LeftUpperLeg",Vector3(-1.28,0,-.08))
   world_turn("RightUpperLeg",Vector3(-1.28,0,.08))
   world_turn("LeftLowerLeg",Vector3(1.38,0,0))
   world_turn("RightLowerLeg",Vector3(1.38,0,0))
   world_turn("Chest",Vector3(.20,0,0))
   world_turn("Head",Vector3(.35,0,0))
  for item in tracks:
   var value
   match item[2]:
    Animation.TYPE_POSITION_3D:value=rig.get_bone_pose_position(item[1])
    Animation.TYPE_ROTATION_3D:value=rig.get_bone_pose_rotation(item[1])
    Animation.TYPE_SCALE_3D:value=rig.get_bone_pose_scale(item[1])
   if frame==0:
    first.append(value)
   if loop and phase>.88:
    var w=smoothstep(.88,1,phase)
    var f=first[item[0]]
    value=value.slerp(f,w) if value is Quaternion else value.lerp(f,w)
   animation.track_insert_key(item[0],t,value)
  rig.force_update_all_bone_transforms()
  if name=="hook" and phase>.3 and phase<.75:
   var hand=rig.get_bone_global_pose(rig.find_bone("RightHand")).origin
   var forearm=rig.get_bone_global_pose(rig.find_bone("RightLowerArm")).origin
   hand+=(hand-forearm).normalized()*.075
   var reach=Vector2(hand.x,hand.z).length()
   if hand.z>.45 and reach>max_reach:
    max_reach=reach
    hit_data={"bone":"RightHand","time":t,"yaw_bias":-atan2(hand.x,hand.z),"reach":reach,"height":hand.y}
 library.add_animation(name,animation)
 report[name]={"source":source,"interval":[start,end],"duration":duration,"loop":loop,"procedural":procedural,"contact":hit_data}

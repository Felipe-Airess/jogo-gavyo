extends RefCounted
## AnimationTree único, avançado no mesmo tick da física e dos contatos.
const LIBRARY=preload("res://capitulo1/animacoes/biblioteca.res")
const ALIASES={"prototype/sit":"novo/Sitting_Idle","prototype/relaxed":"novo/Idle",
 "queda":"novo/Sweep_Fall","levantar":"novo/LayToIdle","deitado":"novo/Deitado",
 "actions/agarrao":"novo/Agarrar",
 "Body_Block":"novo/Segurado"}
var actor: CharacterBody3D
var tree: AnimationTree
var machine:=AnimationNodeStateMachine.new()
var playback: AnimationNodeStateMachinePlayback
var requested:=""
var active_clip:=""
var speed:=1.0
var events: Array[String]=[]
var travelling:=false
var last_position:=Vector3.ZERO
var last_state:=""
var strides: Dictionary={}
var blend_values: Dictionary={}
var blend_origins: Dictionary={}
var blend_targets: Dictionary={}
var blend_elapsed: Dictionary={}
var blend_tail:=0.0
var finishing:=false
var gait_phase:=0.0
var foot_targets: Dictionary={}
var swing_from: Dictionary={}
var swing_to: Dictionary={}
var walking_weight:=0.0
var contact_duty:=.55
var current_stride:=1.2
var physical_rate:=1.0
var pose_history: Array[Transform3D]=[]
var foot_history: Dictionary={}
var world_history: Dictionary={}
var foot_clearance:=0.0
var blending:=false
const MEASURE=preload("res://capitulo1/animacoes/metricas_passo.gd")
const CONTACT=preload("res://capitulo1/animacoes/contato.gd")

func setup(owner_actor: CharacterBody3D) -> void:
 actor=owner_actor
 # Altura real do pivô do tornozelo sobre a sola na malha de repouso.
 foot_clearance=actor.rig.get_bone_global_rest(actor.rig.find_bone("LeftFoot")).origin.y

 var library=LIBRARY.duplicate()
 library.remove_animation("Descending_Stairs")
 library.add_animation("Descending_Stairs",_descent_cycle())
 actor.anim.add_animation_library("novo",library)
 strides=MEASURE.measure(actor.rig,library)
 # O ajuste espacial de agachar mantém a taxa abaixo de 1,8x.
 for data in [["Walk",1.45],["Crouch_Fwd",1.05]]:
  strides[data[0]]["captured_stride"]=strides[data[0]]["stride"]
  strides[data[0]]["stride"]=maxf(strides[data[0]]["stride"],data[1]*strides[data[0]]["duration"]/1.8)
 for name in strides:
  strides[name]["captured_native_speed"]=strides[name]["native_speed"]
  strides[name]["native_speed"]=strides[name]["stride"]/strides[name]["duration"]
 if "stairs_top" in actor.world.school:
  var flight: Vector3=actor.world.school.stairs_top-actor.world.school.stairs_bottom
  var stair_stride=2*Vector2(flight.x,flight.z).length()/roundf(flight.y/.17)
  for name in ["Ascending_Stairs","Running_Up_Stairs","Descending_Stairs"]:
   strides[name]["captured_stride"]=strides[name]["stride"]
   strides[name]["stride"]=stair_stride
   strides[name]["native_speed"]=stair_stride/strides[name]["duration"]
 tree=AnimationTree.new(); tree.name="Movimento"
 actor.add_child(tree)
 tree.anim_player=tree.get_path_to(actor.anim)
 tree.root_node=tree.get_path_to(actor.model)
 tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 tree.callback_mode_method=AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
 for data in [["Locomocao","Idle","Walk","Sprint",1.45,3.8],
 ["Agachado","Crouch_Idle","Crouch_Fwd","Crouch_Fwd",1.05,2.1],
 ["Recuar","Idle","Walking_Backwards","Walking_Backwards",1.45,3.8],
 ["Subir","Idle","Ascending_Stairs","Running_Up_Stairs",1.45,3.8],
 ["Descer","Idle","Descending_Stairs","Descending_Stairs",1.45,3.8]]:
  var branch=AnimationNodeBlendTree.new()
  var blend=AnimationNodeBlendSpace1D.new()
  blend.min_space=0; blend.max_space=3.8
  for i in 3:
   var node=AnimationNodeAnimation.new()
   node.animation="novo/"+data[i+1]
   node.use_custom_timeline=true; node.timeline_length=1.0; node.stretch_time_scale=true
   # A timeline própria sobrescreve o loop do recurso no Godot 4.5.1.
   node.loop_mode=Animation.LOOP_LINEAR
   var point=AnimationNodeBlendTree.new()
   point.add_node("Clipe",node); point.add_node("Ritmo",AnimationNodeTimeScale.new())
   point.connect_node("Ritmo",0,"Clipe"); point.connect_node("output",0,"Ritmo")
   blend.add_blend_point(point,[0.0,data[4],data[5]][i])
  branch.add_node("Velocidade",blend)
  branch.add_node("Cadencia",AnimationNodeTimeScale.new())
  branch.connect_node("Cadencia",0,"Velocidade")
  branch.connect_node("output",0,"Cadencia")
  machine.add_node(data[0],branch)
 for a in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
  for b in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
   if a!=b: _transition(a,b,.15 if a in ["Locomocao","Agachado","Recuar"] and b in ["Locomocao","Agachado","Recuar"] else .22)
 for name in actor.anim.get_animation_list():
  if name=="RESET": continue
  _add_clip(name)
 tree.tree_root=machine; tree.active=true
 playback=tree.get("parameters/playback")
 playback.start("Locomocao")
 last_position=actor.global_position

func _transition(from: String,to: String,blend: float,automatic:=false) -> void:
 var link=AnimationNodeStateMachineTransition.new()
 # A ação recebe uma cauda para completar o clipe antes do crossfade.
 link.xfade_time=blend
 if automatic:
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 machine.add_transition(from,to,link)

func _key(clip: String) -> String: return clip.replace("/","__")
func _add_clip(clip: String,key: String="") -> void:
 if key.is_empty(): key=_key(clip)
 if machine.has_node(key): return
 var branch=AnimationNodeBlendTree.new()
 var node=AnimationNodeAnimation.new(); node.animation=clip
 if actor.anim.get_animation(clip).loop_mode==Animation.LOOP_NONE:
  node.use_custom_timeline=true; node.stretch_time_scale=false
  node.timeline_length=actor.anim.get_animation(clip).length+.22
  node.loop_mode=Animation.LOOP_NONE
 branch.add_node("Clipe",node)
 branch.add_node("Ritmo",AnimationNodeTimeScale.new())
 branch.connect_node("Ritmo",0,"Clipe"); branch.connect_node("output",0,"Ritmo")
 machine.add_node(key,branch)
 for locomotion in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
  _transition(locomotion,key,.22)
  _transition(key,locomotion,.22)
 if actor.anim.get_animation(clip).loop_mode==Animation.LOOP_NONE and clip not in ["novo/Sweep_Fall","novo/Death01","queda","Dying"]:
  # Uma única saída automática; loops e quedas sustentam sua pose.
  machine.remove_transition(key,"Locomocao")
  _transition(key,"Locomocao",.22,true)

func request(clip: String,rate:=1.0,restart:=false) -> void:
 if clip in ["guarda","andaFrente","andaTras","correr"]:
  if not travelling:
   var current=String(playback.get_current_node())
   if machine.has_transition(current,"Locomocao"):
    var index=_find_transition(current,"Locomocao")
    var exit_link=machine.get_transition(index)
    exit_link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
    exit_link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
  travelling=true; requested=clip
  return
 travelling=false; finishing=false
 var mapped=String(ALIASES.get(clip,clip))
 if not actor.anim.has_animation(mapped):
  push_error("Clipe ausente: "+mapped); return
 if requested==mapped and not restart: return
 requested=mapped; active_clip=mapped; speed=rate; events.clear()
 _add_clip(mapped)
 var key=_key(mapped)
 if String(playback.get_current_node())==key and restart:
  key+="__Repetir"
  _add_clip(mapped,key)
 var node=machine.get_node(key).get_node("Clipe") as AnimationNodeAnimation
 if node.use_custom_timeline: node.timeline_length=actor.anim.get_animation(mapped).length+.22
 if machine.has_transition(key,"Locomocao") and actor.anim.get_animation(mapped).loop_mode==Animation.LOOP_NONE:
  var link=machine.get_transition(_find_transition(key,"Locomocao"))
  link.xfade_time=.22
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 _parameter("parameters/"+key+"/Ritmo/scale",rate)
 # Troca direta entre ações precisa interromper o caminho anterior.
 var previous=String(playback.get_current_node())
 if previous!=key and not machine.has_transition(previous,key): _transition(previous,key,.22)
 playback.travel(key)

func _parameter(path: String,value) -> void:
 if tree.get(path)!=value: tree.set(path,value)

func advance(dt: float) -> void:
 blending=false
 if actor.global_position.distance_to(last_position)>1:
  foot_targets.clear(); swing_from.clear(); swing_to.clear(); walking_weight=0; world_history.clear()
 if travelling:
  if walking_weight<=0 and Vector2(actor.velocity.x,actor.velocity.z).length()>.03: gait_phase=0
  # Velocidade após move_and_slide: pressionar contra parede não corre no lugar.
  var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
  var locomotion="Agachado" if actor.crouched else "Locomocao"
  var clip="Crouch_Fwd" if actor.crouched else "Walk"
  if not actor.crouched and flat>.1:
   var school=actor.world.school
   if "stairs_bottom" in school and "stairs_top" in school:
    var a: Vector3=school.stairs_bottom; var b: Vector3=school.stairs_top
    var along=Vector2(b.x-a.x,b.z-a.z)
    var p=Vector2(actor.position.x-a.x,actor.position.z-a.z)
    var projection=p.dot(along)/along.length_squared()
    if projection>-.03 and projection<1.03 and (p-along*projection).length()<1.05:
     var up=Vector2(actor.velocity.x,actor.velocity.z).dot(along)>0
     locomotion="Subir" if up else "Descer"
     clip="Ascending_Stairs" if up else "Descending_Stairs"
   if locomotion=="Locomocao" and actor.velocity.dot(actor.facing)<-.1:
    locomotion="Recuar"; clip="Walking_Backwards"
  if locomotion=="Subir" and requested=="correr": clip="Running_Up_Stairs"
  if locomotion=="Locomocao" and requested=="correr" and flat>.03: clip="Sprint"
  var blend=clampf(flat,0,3.8)
  var stride=float(strides.get(clip,{}).get("stride",1.2))
  if walking_weight<=0:
   current_stride=stride
   contact_duty=.28 if clip=="Sprint" else .5 if locomotion in ["Subir","Descer"] else .55
  current_stride=move_toward(current_stride,stride,dt*12)
  stride=current_stride
  # O idle desaparece cedo; o ciclo de passos mantém amplitude até baixa velocidade.
  if flat>.03: blend=maxf(blend,1.05 if actor.crouched else 1.45)
  if locomotion=="Subir" and requested=="correr": blend=3.8
  elif locomotion=="Locomocao" and requested=="correr": blend=3.8
  # O BlendSpace também precisa interpolar: mudar o parâmetro é uma troca de pose.
  var previous_blend=float(blend_values.get(locomotion,0.0))
  if absf(float(blend_targets.get(locomotion,-100))-blend)>.001:
   blend_origins[locomotion]=previous_blend; blend_targets[locomotion]=blend; blend_elapsed[locomotion]=0.0
  blend_elapsed[locomotion]=minf(.15,float(blend_elapsed[locomotion])+dt)
  blend=lerpf(blend_origins[locomotion],blend_targets[locomotion],smoothstep(0,.15,blend_elapsed[locomotion]))
  blending=float(blend_elapsed[locomotion])<.15
  blend_values[locomotion]=blend
  var cadence=flat/maxf(.1,stride) if flat>.03 else .4
  physical_rate=cadence*float(strides.get(clip,{}).get("duration",1.0))
  gait_phase+=dt*flat/maxf(.1,stride)
  _parameter("parameters/"+locomotion+"/Velocidade/blend_position",blend)
  _parameter("parameters/"+locomotion+"/Cadencia/scale",cadence)
  # Cada fonte conserva seu teto também enquanto contribui para um blend.
  var space=machine.get_node(locomotion).get_node("Velocidade") as AnimationNodeBlendSpace1D
  for i in space.get_blend_point_count():
   var source=space.get_blend_point_node(i).get_node("Clipe") as AnimationNodeAnimation
   var name=String(source.animation).trim_prefix("novo/")
   var duration=actor.anim.get_animation(source.animation).length
   var cap=1.6 if name=="Descending_Stairs" else 1.8 if name in ["Walk","Walking_Backwards","Crouch_Fwd","Ascending_Stairs","Running_Up_Stairs"] else 100.0
   var ratio=minf(1,cap/maxf(.001,cadence*duration))
   _parameter("parameters/"+locomotion+"/Velocidade/"+str(i)+"/Ritmo/scale",ratio)
  if String(playback.get_current_node())!=locomotion: playback.travel(locomotion)
  active_clip="novo/"+(clip if flat>.03 else ("Crouch_Idle" if actor.crouched else "Idle"))
 var before=String(playback.get_current_node())
 tree.advance(dt)
 var after=String(playback.get_current_node())
 # Suaviza a pose antes dos apoios, que permanecem presos ao chão.
 blending=blending or not String(playback.get_fading_from_node()).is_empty()
 blend_tail=.15 if blending else maxf(0,blend_tail-dt)
 blending=blending or blend_tail>0
 _smooth_pose(dt)
 if travelling:
  _feet(dt,after)
 else:
  foot_targets.clear(); swing_from.clear(); swing_to.clear(); walking_weight=0
 if before!=after and after=="Locomocao" and not travelling:
  finishing=true
  travelling=true; requested="guarda"
 if finishing and String(playback.get_fading_from_node()).is_empty():
  finishing=false; events.append("finished")
 _limit_transition_pose()
 world_history.clear()
 for bone in ["LeftHand","RightHand","LeftFoot","RightFoot"]: world_history[bone]=actor.bone_point(bone)
 foot_history.clear()
 for side in ["Left","Right"]: foot_history[side]=actor.rig.get_bone_global_pose(actor.rig.find_bone(side+"Foot")).origin
 pose_history.clear()
 for i in actor.rig.get_bone_count(): pose_history.append(actor.rig.get_bone_pose(i))
 last_state=after; last_position=actor.global_position

func consume(event: String) -> bool:
 if event not in events: return false
 events.erase(event); return true
func event(name: String) -> void:
 if name not in events: events.append(name)
func position() -> float: return playback.get_current_play_position()
func seek(time: float) -> void:
 # Bancada/testes: avança o próprio grafo, nunca o AnimationPlayer concorrente.
 playback.start(_key(active_clip),true); tree.advance(0); tree.advance(time)

## Godot 4.5.1 não tem find_transition: busca manual pelo par origem/destino.
func _find_transition(from: StringName,to: StringName) -> int:
 for i in machine.get_transition_count():
  if machine.get_transition_from(i)==from and machine.get_transition_to(i)==to: return i
 return -1

## A captura de descida tem só 0,933 s e não fecha. Preserva seu movimento,
## reamostra 0,0–0,9 s e fecha os últimos 0,2 s suavemente na primeira pose.
## Derivado em memória: o FBX e a biblioteca de origem continuam intactos.
func _descent_cycle() -> Animation:
 var source: Animation=LIBRARY.get_animation("Descending_Stairs")
 var result=Animation.new(); result.length=.9; result.loop_mode=Animation.LOOP_LINEAR
 for t in source.get_track_count():
  var type=source.track_get_type(t)
  if type not in [Animation.TYPE_ROTATION_3D,Animation.TYPE_POSITION_3D]: continue
  var track=result.add_track(type); result.track_set_path(track,source.track_get_path(t))
  for frame in 28:
   var time=float(frame)/30
   var weight=smoothstep(.7,.9,time)
   var value
   if type==Animation.TYPE_ROTATION_3D:
    value=source.rotation_track_interpolate(t,time).slerp(source.rotation_track_interpolate(t,0),weight)
   else:
    value=source.position_track_interpolate(t,time).lerp(source.position_track_interpolate(t,0),weight)
   if value is Quaternion: value=value.normalized()
   if frame==27: value=result.track_get_key_value(track,0)
   result.track_insert_key(track,time,value)
 return result

## A cápsula segue a rampa física. Só a pose das pernas se ajusta aos pisos
## visuais; o pé de apoio fica preso no mundo até a próxima passada.
func _feet(dt: float,state: String) -> void:
 var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
 walking_weight=move_toward(walking_weight,1.0 if flat>.03 else 0.0,dt/.15)
 if walking_weight<=0:
  foot_targets.clear(); swing_from.clear(); swing_to.clear(); return
 if flat<=.03:
  foot_targets.clear(); swing_from.clear(); swing_to.clear(); return
 var stair=state in ["Subir","Descer"]
 contact_duty=move_toward(contact_duty,.28 if active_clip=="novo/Sprint" else .5 if stair else .55,dt*2)
 var direction=Vector3(actor.velocity.x,0,actor.velocity.z).normalized() if flat>.03 else actor.facing
 var bottom:=Vector3.ZERO; var along:=Vector3.FORWARD; var tread:=1.0; var height:=.17; var count:=1.0
 if stair:
  bottom=actor.world.school.stairs_bottom
  var flight: Vector3=actor.world.school.stairs_top-bottom
  along=(flight*Vector3(1,0,1)).normalized(); count=roundf(flight.y/.17)
  tread=Vector2(flight.x,flight.z).length()/count; height=flight.y/count
 var rig: Skeleton3D=actor.rig
 var hips=rig.find_bone("Hips")
 var goals: Dictionary={}
 for side in ["Left","Right"]:
  var phase=fposmod(gait_phase+(0.0 if side=="Left" else .5),1)
  var stance=phase<contact_duty
  var foot: Vector3=actor.bone_point(side+"Foot")
  if stance:
   if not foot_targets.has(side):
    var target: Vector3=swing_to.get(side,foot)
    if stair:
     var distance=(target-bottom).dot(along)
     var step=clampf(floorf(distance/tread),0,count-1)
     target+=along*((step+.5)*tread-distance); target.y=bottom.y+(step+1)*height+foot_clearance
    else: target.y=actor.position.y+foot_clearance
    foot_targets[side]=target
   goals[side]=foot_targets[side]
   swing_from[side]=foot_targets[side]; swing_to.erase(side)
  else:
   if not swing_to.has(side):
    var start: Vector3=swing_from.get(side,foot)
    var end=actor.position+direction*current_stride*(1-contact_duty*.5)+actor.model.global_basis.x*(.10 if side=="Left" else -.10)
    if stair:
     var distance=(end-bottom).dot(along)
     var step=clampf(floorf(distance/tread),0,count-1)
     end+=along*((step+.5)*tread-distance); end.y=bottom.y+(step+1)*height+foot_clearance
    else: end.y=actor.position.y+foot_clearance
    swing_from[side]=start; swing_to[side]=end
   foot_targets.erase(side)
   var t=(phase-contact_duty)/(1-contact_duty)
   var target: Vector3=swing_from[side].lerp(swing_to[side],smoothstep(0,1,t))
   target.y+=.20*sin(t*PI)
   goals[side]=target
 if blending:
  for side in goals:
   if not foot_history.has(side): continue
   var local=rig.to_local(goals[side])
   var before: Vector3=foot_history[side]
   if local.distance_to(before)>.074: goals[side]=rig.to_global(before+before.direction_to(local)*.074)
 # Resolve o quadril antes das duas pernas; ajustar depois soltaria o apoio.
 var lower:=0.0
 for side in goals:
  var upper=rig.get_bone_global_pose(rig.find_bone(side+"UpperLeg")).origin
  var knee=rig.get_bone_global_pose(rig.find_bone(side+"LowerLeg")).origin
  var foot=rig.get_bone_global_pose(rig.find_bone(side+"Foot")).origin
  var target=rig.to_local(goals[side])
  var reach=upper.distance_to(knee)+knee.distance_to(foot)-.025
  var horizontal=Vector2(upper.x-target.x,upper.z-target.z).length()
  lower=maxf(lower,upper.y-target.y-sqrt(maxf(0,reach*reach-horizontal*horizontal)))
 rig.set_bone_pose_position(hips,rig.get_bone_pose_position(hips)-Vector3.UP*lower*walking_weight)
 rig.force_update_all_bone_transforms()
 for side in goals:
  CONTACT.limb_fit(actor,side+"UpperLeg",side+"LowerLeg",side+"Foot",goals[side],walking_weight)
  if foot_targets.has(side):
   var foot=rig.find_bone(side+"Foot")
   var parent=rig.get_bone_parent(foot)
   var desired=rig.get_bone_global_pose(parent).basis.inverse()*rig.get_bone_global_rest(foot).basis
   var phase=fposmod(gait_phase+(0.0 if side=="Left" else .5),1)
   rig.set_bone_pose_rotation(foot,rig.get_bone_pose_rotation(foot).slerp(desired.get_rotation_quaternion().normalized(),walking_weight*smoothstep(0,.10,phase)))
   rig.force_update_all_bone_transforms()

## A rampa não exige acelerar uma caminhada além do limite. Limita o corpo,
## mantendo o ritmo medido do clipe e a velocidade tangente ao piso.
func prepare_velocity() -> void:
 if not travelling or not "stairs_top" in actor.world.school: return
 var a: Vector3=actor.world.school.stairs_bottom; var b: Vector3=actor.world.school.stairs_top
 var flight=(b-a)*Vector3(1,0,1); var length=flight.length(); var along=flight/length
 var projection=(actor.position-a).dot(along)
 if projection<-.15 or projection>length+.15 or ((actor.position-a)*Vector3(1,0,1)-along*projection).length()>1.05: return
 var up=actor.velocity.dot(along)>0
 var name="Running_Up_Stairs" if up and requested=="correr" else "Ascending_Stairs" if up else "Descending_Stairs"
 var rate=1.8 if up else 1.6
 var maximum=rate*float(strides[name]["stride"])/float(strides[name]["duration"])
 var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
 if flat>maximum:
  actor.velocity.x*=maximum/flat; actor.velocity.z*=maximum/flat
 if actor.is_on_floor(): actor.velocity.y=actor.velocity.dot(along)*(b.y-a.y)/length

func _smooth_pose(dt: float) -> void:
 var rig: Skeleton3D=actor.rig
 if pose_history.size()==rig.get_bone_count():
  # Inércia curta cobre interrupções e o ajuste de altura entre posturas.
  var weight=1-exp(-dt/.16)
  for i in rig.get_bone_count():
   var wanted=rig.get_bone_pose(i)
   rig.set_bone_pose_position(i,pose_history[i].origin.lerp(wanted.origin,weight))
   rig.set_bone_pose_rotation(i,pose_history[i].basis.get_rotation_quaternion().slerp(wanted.basis.get_rotation_quaternion(),weight))
 rig.force_update_all_bone_transforms()

## Inércia com limite espacial, além do crossfade do grafo. A interpolação é
## de rotações locais: preserva o comprimento dos membros em interrupções.
func _limit_transition_pose() -> void:
 var rig: Skeleton3D=actor.rig
 if not blending or pose_history.size()!=rig.get_bone_count(): return
 var bones=["LeftHand","RightHand","LeftFoot","RightFoot"]
 var end: Array[Transform3D]=[]
 var wanted: Array[Transform3D]=[]
 for i in rig.get_bone_count():
  end.append(rig.get_bone_global_pose(i)); wanted.append(rig.get_bone_pose(i))
 # Avalia a pose anterior no mesmo referencial do esqueleto.
 for i in rig.get_bone_count():
  rig.set_bone_pose_position(i,pose_history[i].origin)
  rig.set_bone_pose_rotation(i,pose_history[i].basis.get_rotation_quaternion())
 rig.force_update_all_bone_transforms()
 var previous: Array[Vector3]=[]
 var maximum:=0.0
 for bone in bones:
  var id=rig.find_bone(bone)
  previous.append(world_history.get(bone,rig.to_global(rig.get_bone_global_pose(id).origin)))
  maximum=maxf(maximum,previous[-1].distance_to(rig.to_global(end[id].origin)))
 var low:=0.0; var high:=1.0
 for attempt in (8 if maximum>.077 else 1):
  var weight=(low+high)*.5 if maximum>.077 else 1.0
  for i in rig.get_bone_count():
   rig.set_bone_pose_position(i,pose_history[i].origin.lerp(wanted[i].origin,weight))
   rig.set_bone_pose_rotation(i,pose_history[i].basis.get_rotation_quaternion().slerp(wanted[i].basis.get_rotation_quaternion(),weight))
  rig.force_update_all_bone_transforms()
  var error:=0.0
  for j in bones.size(): error=maxf(error,previous[j].distance_to(rig.to_global(rig.get_bone_global_pose(rig.find_bone(bones[j])).origin)))
  if error>.077: high=weight
  else: low=weight
 if maximum>.077:
  for i in rig.get_bone_count():
   rig.set_bone_pose_position(i,pose_history[i].origin.lerp(wanted[i].origin,low))
   rig.set_bone_pose_rotation(i,pose_history[i].basis.get_rotation_quaternion().slerp(wanted[i].basis.get_rotation_quaternion(),low))
  rig.force_update_all_bone_transforms()

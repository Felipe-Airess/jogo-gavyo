extends RefCounted
## Só seleciona clipes, crossfades e taxas. Nunca escreve poses ou trilhas.
const LIBRARY=preload("res://capitulo1/animacoes/biblioteca.res")
const MEASURE=preload("res://capitulo1/animacoes/metricas_passo.gd")
const ALIASES={"prototype/sit":"novo/Sitting_Idle","prototype/relaxed":"novo/Idle",
 "queda":"novo/Sweep_Fall","levantar":"novo/LayToIdle","deitado":"novo/Deitado",
 "actions/agarrao":"novo/Agarrar","Body_Block":"novo/Segurado"}
const LOCOMOTION={"Locomocao":"Idle","Andar":"Walk","Correr":"Sprint",
 "AgachadoParado":"Crouch_Idle","Agachado":"Crouch_Fwd","Recuar":"Walking_Backwards",
 "Subir":"Ascending_Stairs","SubirCorrendo":"Running_Up_Stairs",
 "Descer":"Descending_Stairs","DescerB":"Descending_Stairs"}
const FLAT=["Locomocao","Andar","Correr","AgachadoParado","Agachado","Recuar"]
var actor: CharacterBody3D
var tree: AnimationTree
var machine:=AnimationNodeStateMachine.new()
var playback: AnimationNodeStateMachinePlayback
var requested:=""
var active_clip:=""
var speed:=1.0
var events: Array[String]=[]
var travelling:=false
var finishing:=false
var strides: Dictionary={}
var foot_clearance:=0.0
var physical_rate:=1.0

func setup(owner_actor: CharacterBody3D) -> void:
 actor=owner_actor
 foot_clearance=actor.rig.get_bone_global_rest(actor.rig.find_bone("LeftFoot")).origin.y
 actor.anim.add_animation_library("novo",LIBRARY)
 strides=MEASURE.measure(actor.rig,LIBRARY)
 tree=AnimationTree.new(); tree.name="Movimento"; actor.add_child(tree)
 tree.anim_player=tree.get_path_to(actor.anim)
 tree.root_node=tree.get_path_to(actor.model)
 tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 tree.callback_mode_method=AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
 for state in LOCOMOTION: machine.add_node(state,_branch("novo/"+LOCOMOTION[state],false))
 for from in LOCOMOTION:
  for to in LOCOMOTION:
   if from!=to: _transition(from,to,.15 if from in FLAT and to in FLAT else .22)
 # A descida recebida não fecha: duas instâncias fazem crossfade entre repetições.
 # Nenhuma chave é cortada, copiada, reamostrada ou corrigida.
 for pair in [["Descer","DescerB"],["DescerB","Descer"]]:
  var link=machine.get_transition(_find_transition(pair[0],pair[1]))
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 for name in actor.anim.get_animation_list():
  if name!="RESET": _add_clip(name)
 tree.tree_root=machine; tree.active=true
 playback=tree.get("parameters/playback"); playback.start("Locomocao")

func _branch(clip: String,tail: bool) -> AnimationNodeBlendTree:
 var branch=AnimationNodeBlendTree.new()
 var node=AnimationNodeAnimation.new(); node.animation=clip
 if tail and actor.anim.get_animation(clip).loop_mode==Animation.LOOP_NONE:
  # Sustenta o fim enquanto sai em crossfade; não modifica o recurso Animation.
  node.use_custom_timeline=true; node.stretch_time_scale=false
  node.timeline_length=actor.anim.get_animation(clip).length+.22
  node.loop_mode=Animation.LOOP_NONE
 branch.add_node("Clipe",node); branch.add_node("Ritmo",AnimationNodeTimeScale.new())
 branch.connect_node("Ritmo",0,"Clipe"); branch.connect_node("output",0,"Ritmo")
 return branch

func _transition(from: String,to: String,blend: float,automatic:=false) -> void:
 var link=AnimationNodeStateMachineTransition.new(); link.xfade_time=blend
 if automatic:
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 machine.add_transition(from,to,link)
func _key(clip: String) -> String: return clip.replace("/","__")
func _add_clip(clip: String,key: String="") -> void:
 if key.is_empty(): key=_key(clip)
 if machine.has_node(key): return
 machine.add_node(key,_branch(clip,true))
 for locomotion in LOCOMOTION:
  _transition(locomotion,key,.22); _transition(key,locomotion,.22)
 if actor.anim.get_animation(clip).loop_mode==Animation.LOOP_NONE and clip not in ["novo/Sweep_Fall","novo/Death01","queda","Dying"]:
  machine.remove_transition(key,"Locomocao"); _transition(key,"Locomocao",.22,true)

func request(clip: String,rate:=1.0,restart:=false) -> void:
 if clip in ["guarda","andaFrente","andaTras","correr"]:
  if not travelling:
   var current=String(playback.get_current_node())
   if machine.has_transition(current,"Locomocao"):
    var link=machine.get_transition(_find_transition(current,"Locomocao"))
    link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
    link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
  travelling=true; finishing=false; requested=clip; return
 var mapped=String(ALIASES.get(clip,clip))
 if not actor.anim.has_animation(mapped): push_error("Clipe ausente: "+mapped); return
 if requested==mapped and not restart: return
 travelling=false; finishing=false; requested=mapped; speed=rate; events.clear()
 _add_clip(mapped)
 var key=_key(mapped)
 if String(playback.get_current_node())==key and restart:
  key+="__Repetir"; _add_clip(mapped,key)
 if machine.has_transition(key,"Locomocao") and actor.anim.get_animation(mapped).loop_mode==Animation.LOOP_NONE:
  var link=machine.get_transition(_find_transition(key,"Locomocao"))
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 _parameter("parameters/"+key+"/Ritmo/scale",rate)
 var previous=String(playback.get_current_node())
 if previous!=key and not machine.has_transition(previous,key): _transition(previous,key,.22)
 playback.travel(key)

func _parameter(path: String,value) -> void:
 if tree.get(path)!=value: tree.set(path,value)
func stair_direction() -> int:
 var school=actor.world.school
 if not "stairs_top" in school: return 0
 var a: Vector3=school.stairs_bottom; var b: Vector3=school.stairs_top
 var along=(b-a)*Vector3(1,0,1); var length=along.length(); along/=length
 var delta=(actor.position-a)*Vector3(1,0,1); var projection=delta.dot(along)
 if projection<-.15 or projection>length+.15 or (delta-along*projection).length()>1.05: return 0
 if absf(actor.position.y-lerpf(a.y,b.y,clampf(projection/length,0,1)))>.5: return 0
 return 1 if actor.velocity.dot(along)>0 else -1
func _desired_state() -> String:
 var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
 if actor.crouched: return "Agachado" if flat>.03 else "AgachadoParado"
 if flat<=.03: return "Locomocao"
 var stairs=stair_direction()
 if stairs>0: return "SubirCorrendo" if requested=="correr" else "Subir"
 if stairs<0: return "Descer"
 if actor.velocity.dot(actor.facing)<-.1: return "Recuar"
 return "Correr" if requested=="correr" else "Andar"

func advance(dt: float) -> void:
 if travelling:
  var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
  for state in LOCOMOTION:
   var clip=String(LOCOMOTION[state])
   var rate=1.0 if clip in ["Idle","Crouch_Idle"] else flat/maxf(.01,float(strides[clip]["native_speed"]))
   _parameter("parameters/"+state+"/Ritmo/scale",rate)
  var desired=_desired_state()
  var current=String(playback.get_current_node())
  if desired=="Descer" and current in ["Descer","DescerB"]: desired=current
  if current!=desired: playback.travel(desired)
 var before=String(playback.get_current_node())
 tree.advance(dt)
 var after=String(playback.get_current_node())
 if before!=after and after=="Locomocao" and not travelling:
  finishing=true; travelling=true; requested="guarda"
 if finishing and String(playback.get_fading_from_node()).is_empty():
  finishing=false; events.append("finished")
 active_clip=String(machine.get_node(after).get_node("Clipe").animation)
 physical_rate=float(tree.get("parameters/"+after+"/Ritmo/scale"))

func locomotion_visible() -> bool:
 return String(playback.get_current_node()) in LOCOMOTION or String(playback.get_fading_from_node()) in LOCOMOTION

## Mantém o limite de ritmo na escada usando o passo original, sem retarget de ossos.
func prepare_velocity() -> void:
 if not travelling: return
 var stairs=stair_direction()
 if stairs==0: return
 var name="Running_Up_Stairs" if stairs>0 and requested=="correr" else "Ascending_Stairs" if stairs>0 else "Descending_Stairs"
 var maximum=(1.8 if stairs>0 else 1.6)*float(strides[name]["native_speed"])
 var flat=Vector2(actor.velocity.x,actor.velocity.z).length()
 if flat>maximum:
  actor.velocity.x*=maximum/flat; actor.velocity.z*=maximum/flat
 var flight: Vector3=actor.world.school.stairs_top-actor.world.school.stairs_bottom
 if actor.is_on_floor(): actor.velocity.y=actor.velocity.dot((flight*Vector3(1,0,1)).normalized())*flight.y/Vector2(flight.x,flight.z).length()

func consume(event: String) -> bool:
 if event not in events: return false
 events.erase(event); return true
func event(name: String) -> void:
 if name not in events: events.append(name)
func position() -> float: return playback.get_current_play_position()
func seek(time: float) -> void:
 # Bancada: só o próprio grafo avalia a pose do clipe pedido.
 playback.start(_key(active_clip),true); tree.advance(0); tree.advance(time)
func _find_transition(from: StringName,to: StringName) -> int:
 for i in machine.get_transition_count():
  if machine.get_transition_from(i)==from and machine.get_transition_to(i)==to: return i
 return -1

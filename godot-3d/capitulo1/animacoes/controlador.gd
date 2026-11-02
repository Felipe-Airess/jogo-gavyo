extends RefCounted
## AnimationTree único, avançado no mesmo tick da física e dos contatos.
const LIBRARY=preload("res://capitulo1/animacoes/biblioteca.res")
const ALIASES={"prototype/sit":"novo/Sitting_Idle","prototype/relaxed":"novo/Idle",
 "queda":"novo/Sweep_Fall","levantar":"novo/LayToIdle","deitado":"novo/Deitado",
 "actions/empurrao":"novo/Empurrar","actions/agarrao":"novo/Agarrar",
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

func setup(owner_actor: CharacterBody3D) -> void:
 actor=owner_actor
 strides=JSON.parse_string(FileAccess.get_file_as_string("res://capitulo1/animacoes/metricas.json"))
 actor.anim.add_animation_library("novo",LIBRARY)
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
 ["Descer","Idle","Descer_Ciclo","Descer_Ciclo",1.45,3.8]]:
  var branch=AnimationNodeBlendTree.new()
  var blend=AnimationNodeBlendSpace1D.new()
  blend.min_space=0; blend.max_space=3.8
  for i in 3:
   var node=AnimationNodeAnimation.new()
   node.animation="novo/"+data[i+1]
   node.use_custom_timeline=true; node.timeline_length=1.0; node.stretch_time_scale=true
   blend.add_blend_point(node,[0.0,data[4],data[5]][i])
  branch.add_node("Velocidade",blend)
  branch.add_node("Cadencia",AnimationNodeTimeScale.new())
  branch.connect_node("Cadencia",0,"Velocidade")
  branch.connect_node("output",0,"Cadencia")
  machine.add_node(data[0],branch)
 for a in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
  for b in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
   if a!=b: _transition(a,b,.12)
 for name in actor.anim.get_animation_list():
  if name=="RESET": continue
  _add_clip(name)
 tree.tree_root=machine; tree.active=true
 playback=tree.get("parameters/playback")
 playback.start("Locomocao")
 last_position=actor.global_position

func _transition(from: String,to: String,blend: float,automatic:=false) -> void:
 var link=AnimationNodeStateMachineTransition.new()
 link.xfade_time=blend
 if automatic:
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 machine.add_transition(from,to,link)

func _key(clip: String) -> String: return clip.replace("/","__")
func _add_clip(clip: String) -> void:
 var key=_key(clip)
 if machine.has_node(key): return
 var branch=AnimationNodeBlendTree.new()
 var node=AnimationNodeAnimation.new(); node.animation=clip
 branch.add_node("Clipe",node)
 branch.add_node("Ritmo",AnimationNodeTimeScale.new())
 branch.connect_node("Ritmo",0,"Clipe"); branch.connect_node("output",0,"Ritmo")
 machine.add_node(key,branch)
 for locomotion in ["Locomocao","Agachado","Recuar","Subir","Descer"]:
  _transition(locomotion,key,.08)
  _transition(key,locomotion,.20)
 if actor.anim.get_animation(clip).loop_mode==Animation.LOOP_NONE and clip not in ["novo/Sweep_Fall","novo/Death01","queda","Dying"]:
  # Uma única saída automática; loops e quedas sustentam sua pose.
  machine.remove_transition(key,"Locomocao")
  _transition(key,"Locomocao",.20,true)

func request(clip: String,rate:=1.0,restart:=false) -> void:
 if clip in ["guarda","andaFrente","andaTras","correr"]:
  if not travelling:
   var current=String(playback.get_current_node())
   if machine.has_transition(current,"Locomocao"):
    var index=machine.find_transition(current,"Locomocao")
    var exit_link=machine.get_transition(index)
    exit_link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
    exit_link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
  travelling=true; requested=clip
  return
 travelling=false
 var mapped=String(ALIASES.get(clip,clip))
 if not actor.anim.has_animation(mapped):
  push_error("Clipe ausente: "+mapped); return
 if requested==mapped and not restart: return
 requested=mapped; active_clip=mapped; speed=rate; events.clear()
 _add_clip(mapped)
 var key=_key(mapped)
 if machine.has_transition(key,"Locomocao") and actor.anim.get_animation(mapped).loop_mode==Animation.LOOP_NONE:
  var link=machine.get_transition(machine.find_transition(key,"Locomocao"))
  link.switch_mode=AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
  link.advance_mode=AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
 _parameter("parameters/"+key+"/Ritmo/scale",rate)
 # Troca direta entre ações precisa interromper o caminho anterior.
 var previous=String(playback.get_current_node())
 if previous!=key and not machine.has_transition(previous,key): _transition(previous,key,.08)
 if restart and previous==key: playback.start(key,true)
 else: playback.travel(key)
 tree.advance(0)

func _parameter(path: String,value) -> void:
 if tree.get(path)!=value: tree.set(path,value)

func advance(dt: float) -> void:
 if travelling:
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
     clip="Ascending_Stairs" if up else "Descer_Ciclo"
   if locomotion=="Locomocao" and actor.velocity.dot(actor.facing)<-.1:
    locomotion="Recuar"; clip="Walking_Backwards"
  var blend=clampf(flat,0,3.8)
  var stride=float(strides.get(clip,{}).get("stride",1.2))
  if locomotion in ["Locomocao","Subir"]:
   var running="Sprint" if locomotion=="Locomocao" else "Running_Up_Stairs"
   var weight=clampf((flat-1.45)/(3.8-1.45),0,1)
   stride=lerpf(stride,float(strides.get(running,{}).get("stride",2.4)),weight)
  # O idle desaparece cedo; o ciclo de passos mantém amplitude até baixa velocidade.
  if flat>.03: blend=maxf(blend,1.05 if actor.crouched else 1.45)
  var cadence=flat/maxf(.1,stride) if flat>.03 else .4
  _parameter("parameters/"+locomotion+"/Velocidade/blend_position",blend)
  _parameter("parameters/"+locomotion+"/Cadencia/scale",cadence)
  if String(playback.get_current_node())!=locomotion: playback.travel(locomotion)
  active_clip=clip if flat>.03 else ("Crouch_Idle" if actor.crouched else "Idle")
 var before=String(playback.get_current_node())
 tree.advance(dt)
 var after=String(playback.get_current_node())
 if before!=after and after=="Locomocao" and not travelling:
  events.append("finished")
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

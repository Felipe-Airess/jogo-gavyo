extends SceneTree
## Mede continuidade da pose e posição do apoio no mundo, sem confiar em metadados.
const DT:=1.0/60
const BONES:=["LeftHand","RightHand","LeftFoot","RightFoot"]
var game: Node3D
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func points(actor) -> Array[Vector3]:
 var result: Array[Vector3]=[]
 for name in BONES: result.append(actor.bone_point(name))
 return result
func move(actor,speed: float,crouched: bool) -> void:
 actor.crouched=crouched; actor.velocity=Vector3.BACK*speed
 actor.face(actor.position+Vector3.BACK)
 actor.play("correr" if speed>2 else "andaFrente" if speed>0 else "guarda")
 actor._slide(DT); actor.animate(DT)
func source_rates(actor) -> bool:
 var state=String(actor.motion.playback.get_current_node())
 if state not in ["Locomocao","Agachado","Recuar","Subir","Descer"]: return true
 var cadence=float(actor.motion.tree.get("parameters/"+state+"/Cadencia/scale"))
 var space=actor.motion.machine.get_node(state).get_node("Velocidade") as AnimationNodeBlendSpace1D
 for i in space.get_blend_point_count():
  var point=space.get_blend_point_node(i)
  if not point is AnimationNodeBlendTree: return false
  var clip=String(point.get_node("Clipe").animation)
  var ratio=actor.motion.tree.get("parameters/"+state+"/Velocidade/"+str(i)+"/Ritmo/scale")
  if ratio==null: return false
  var cap=1.6 if clip.ends_with("Descending_Stairs") else 1.8 if clip.trim_prefix("novo/") in ["Walk","Walking_Backwards","Crouch_Fwd","Ascending_Stairs","Running_Up_Stairs"] else 100.0
  if cadence*float(ratio)*actor.anim.get_animation(clip).length>cap+.0001: return false
 return true
func transitions(actor) -> void:
 actor.position=Vector3(200,0,200); actor.state="idle"; actor.crouched=false; actor.velocity=Vector3.ZERO
 actor.play("guarda")
 for i in 30: actor.animate(DT)
 var previous=points(actor)
 var rate_ok:=true
 for data in [[1.45,false],[3.8,false],[0.0,false],[1.05,true],[0.0,true],[1.45,false]]:
  var maximum:=0.0
  for i in 24:
   move(actor,data[0],data[1])
   rate_ok=rate_ok and source_rates(actor)
   var now=points(actor)
   if i<10 or not String(actor.motion.playback.get_fading_from_node()).is_empty():
    for j in BONES.size(): maximum=maxf(maximum,now[j].distance_to(previous[j]))
   previous=now
   await physics_frame
  print("TRANSICAO velocidade=%.2f agachado=%s salto=%.4f m"%[data[0],data[1],maximum])
  check(maximum<=.08,"transição locomotora sem salto maior que 8 cm")
 for clip in ["novo/PickUp_Table","novo/Interact","novo/Chest_Open","novo/ClimbUp_1m","novo/Roll"]:
  actor.velocity=Vector3.ZERO
  actor.start_action(clip)
  var maximum:=0.0
  for i in ceili((actor.anim.get_animation(clip).length+.7)/DT):
   actor.animate(DT)
   var now=points(actor)
   if not String(actor.motion.playback.get_fading_from_node()).is_empty() or i==0 or String(actor.motion.playback.get_current_node())=="Locomocao":
    for j in BONES.size(): maximum=maxf(maximum,now[j].distance_to(previous[j]))
   previous=now
   await physics_frame
  print("TRANSICAO acao=%s salto=%.4f m"%[clip,maximum])
  check(maximum<=.08,clip+": entrada e saída sem salto maior que 8 cm")
 check(rate_ok,"fontes de caminhada respeitam 1,8x também dentro do crossfade")
 var invalid:=0
 for i in actor.motion.machine.get_transition_count():
  var from=String(actor.motion.machine.get_transition_from(i))
  var to=String(actor.motion.machine.get_transition_to(i))
  var locomotion=from in ["Locomocao","Agachado","Recuar"] and to in ["Locomocao","Agachado","Recuar"]
  var time=actor.motion.machine.get_transition(i).xfade_time
  if (locomotion and absf(time-.15)>.0001) or (not locomotion and (time<.20 or time>.25)): invalid+=1
 print("CROSSFADE transicoes_invalidas=",invalid)
 check(invalid==0,"todas as arestas usam crossfade de 0,15 ou 0,20–0,25 s")
func planted(actor,speed: float,crouched: bool,label: String) -> void:
 actor.position=Vector3(220 if actor.enemy else 200,0,200); actor.state="idle"; actor.velocity=Vector3.ZERO
 for i in 40: move(actor,speed,crouched); await physics_frame
 var anchors: Dictionary={}; var worst:=0.0; var support_frames:=0
 for i in 240:
  move(actor,speed,crouched)
  for side in ["Left","Right"]:
   var foot: Vector3=actor.bone_point(side+"Foot")
   # Desconta a altura anatômica do tornozelo: a sola deve tocar o piso.
   if foot.y-actor.motion.foot_clearance-actor.position.y<.025:
    if not anchors.has(side): anchors[side]=foot
    else:
     worst=maxf(worst,foot.distance_to(anchors[side])); support_frames+=1
   else: anchors.erase(side)
  await physics_frame
 print("CHAO %s velocidade=%.2f apoios=%d desvio=%.4f m"%[label,speed,support_frames,worst])
 check(support_frames>30 and worst<=.03,label+": pé de apoio deriva no máximo 3 cm por apoio")
func stairs(up: bool,running: bool) -> void:
 var actor=game.player
 var a: Vector3=game.school.stairs_bottom; var b: Vector3=game.school.stairs_top
 var direction=((b-a)*Vector3(1,0,1)).normalized()*(1 if up else -1)
 actor.position=(a if up else b)+direction*.7
 actor.position.y=game.school.LEVEL*(.7/Vector2(b.x-a.x,b.z-a.z).length() if up else 1-.7/Vector2(b.x-a.x,b.z-a.z).length())
 actor.velocity=Vector3.ZERO; actor.state="idle"; actor.crouched=false
 var expected="novo/Running_Up_Stairs" if up and running else "novo/Ascending_Stairs" if up else "novo/Descending_Stairs"
 actor.face(actor.position+direction)
 var correct:=0; var maximum:=0.0
 var previous=points(actor); var jump:=0.0
 for i in 70:
  actor.velocity=direction*(3.8 if running else 1.45); actor.face(actor.position+direction)
  actor.play("correr" if running else "andaFrente"); actor._slide(DT); actor.animate(DT)
  if i>20:
   if actor.motion.active_clip==expected: correct+=1
   var state=String(actor.motion.playback.get_current_node())
   var scale=float(actor.motion.tree.get("parameters/"+state+"/Cadencia/scale"))
   var duration: float=actor.anim.get_animation(expected).length
   maximum=maxf(maximum,scale*duration)
  var now=points(actor)
  if i<10 or not String(actor.motion.playback.get_fading_from_node()).is_empty():
   for j in BONES.size(): jump=maxf(jump,now[j].distance_to(previous[j]))
  previous=now
  await physics_frame
 print("ESCADA_RITMO sobe=%s corre=%s clipe=%s correto=%d/49 escala=%.3fx salto=%.4f m"%[up,running,actor.motion.active_clip,correct,maximum,jump])
 check(correct==49,"escada: clipe correto mesmo após projeção da velocidade na rampa")
 check(maximum<= .0001+(1.6 if not up else 1.8 if not running else 4.0),"escada: limite de velocidade do clipe")
 check(jump<=.08,"escada: entrada sem salto maior que 8 cm")
func run() -> void:
 var deadline=create_timer(150,true,false,true)
 deadline.timeout.connect(func(): print("FAIL MOVIMENTO TIMEOUT"); quit(2))
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 var floor_body=StaticBody3D.new(); var shape=CollisionShape3D.new(); var box=BoxShape3D.new()
 box.size=Vector3(100,1,100); shape.shape=box; floor_body.position=Vector3(200,-.5,200)
 floor_body.add_child(shape); game.add_child(floor_body)
 game.phase="investigate"; game.started=true; game.paused=false
 await transitions(game.player)
 for actor in [game.player,game.enemies[1]]:
  for data in [[1.45,false],[3.8,false],[1.05,true]]:
   await planted(actor,data[0],data[1],"cultista" if actor.enemy else "Miguel")
 for up in [true,false]:
  for running in [false,true]: await stairs(up,running)
 game.player.position=Vector3(200,0,200); game.player.state="idle"; game.player.hidden=false
 var roll_start: Vector3=game.player.position
 game.dodge(); game._player_tick(DT)
 check(not game.DODGE_AVAILABLE and game.player.state=="idle","esquiva desativada explicitamente após avaliar Roll")
 for i in 150:
  game._player_tick(DT); await physics_frame
 var moved=Vector2(game.player.position.x-roll_start.x,game.player.position.z-roll_start.z).length()
 print("ESQUIVA desativada deslocamento=%.3f m estado=%s"%[moved,game.player.state])
 check(moved<.001 and game.player.state=="idle","comando desativado não causa deslocamento invisível")
 print("CAPITULO1_MOVIMENTO: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame; quit(1 if failed else 0)

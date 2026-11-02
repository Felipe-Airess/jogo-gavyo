extends SceneTree
## Regressão de locomoção, ações e escada: física, grafo e ossos reais.
const DT:=1.0/60.0
const BONES:=["LeftFoot","RightFoot","LeftHand","RightHand"]
var passed:=0
var failed:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func key(code: Key,pressed: bool) -> void:
 var event:=InputEventKey.new()
 event.physical_keycode=code; event.keycode=code; event.pressed=pressed
 Input.parse_input_event(event); Input.flush_buffered_events()
func pose(actor) -> Array[Vector3]:
 var points: Array[Vector3]=[]
 for bone in BONES:
  points.append(actor.rig.get_bone_global_pose(actor.rig.find_bone(bone)).origin)
 return points
func graph_clip(actor) -> String:
 var motion=actor.motion
 var state=String(motion.playback.get_current_node())
 return String(motion.machine.get_node(state).get_node("Clipe").animation)

func tick(enemy: bool) -> void:
 if enemy: game._enemy_ticks(DT)
 else: game._player_tick(DT)
func sample(label: String,actor,clip: String,speed: float,enemy:=false) -> void:
 for i in 20:
  tick(enemy); await physics_frame
 var previous=pose(actor)
 var time: float=actor.motion.position()
 var advancing:=0
 var correct:=0
 var paced:=0
 var changing:=[0,0,0,0]
 var measured:=0.0
 var start: Vector3=actor.position
 for i in 180:
  var before: Vector3=actor.position
  tick(enemy)
  measured+=Vector2(actor.position.x-before.x,actor.position.z-before.z).length()
  var now: float=actor.motion.position()
  var stride: float=actor.motion.strides[clip.trim_prefix("novo/")]["stride"]
  var duration: float=actor.anim.get_animation(clip).length
  var expected_time: float=speed*duration*DT/stride
  if absf(fposmod(now-time,duration)-expected_time)<.0001: paced+=1
  if absf(now-time)>0.000001: advancing+=1
  time=now
  if graph_clip(actor)==clip and actor.motion.active_clip==clip and actor.motion.tree.active and not actor.anim.is_playing(): correct+=1
  var current=pose(actor)
  for j in BONES.size():
   if current[j].distance_to(previous[j])>0.000001: changing[j]+=1
  previous=current
  await physics_frame
 print("AMOSTRA %s: tempo=%d/180 clipe=%s %d/180 pose=%s velocidade=%.3f m/s distancia=%.3f m"%[label,advancing,graph_clip(actor),correct,changing,measured/3.0,start.distance_to(actor.position)])
 check(advancing==180,label+": tempo avança em todos os quadros por 3 s")
 check(paced==180,label+": cadência casa velocidade real com passada medida")
 check(correct==180,label+": clipe ativo "+clip)
 check(changing.all(func(n):return n>100),label+": pose do clipe varia sem congelar")
 check(absf(measured/3.0-speed)<.03,label+": velocidade real %.2f m/s"%speed)
func run() -> void:
 var deadline=create_timer(160,true,false,true)
 deadline.timeout.connect(func(): print("FAIL CAPITULO1_ANIMACAO TIMEOUT"); quit(2))
 var version=Engine.get_version_info()
 check(version.major==4 and version.minor==5 and version.patch==1,"APIs executadas no Godot 4.5.1")
 game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game); game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 # Pista plana isolada da escola: mantém cápsula, move_and_slide e ticks de produção.
 var floor_body:=StaticBody3D.new()
 var shape:=CollisionShape3D.new()
 var box:=BoxShape3D.new(); box.size=Vector3(100,1,100); shape.shape=box
 floor_body.position=Vector3(200,-.5,200); floor_body.add_child(shape); game.add_child(floor_body)
 game.started=true; game.paused=false; game.phase="investigate"; game.locked=null
 game.player.position=Vector3(200,.02,200); game.player.state="idle"; game.player.velocity=Vector3.ZERO
 game.view.yaw=0
 for i in 3: await physics_frame
 key(KEY_W,true)
 await sample("Miguel andando",game.player,"novo/Walk",1.45)
 key(KEY_SHIFT,true)
 await sample("Miguel correndo",game.player,"novo/Sprint",3.8)
 key(KEY_SHIFT,false); key(KEY_CTRL,true)
 await sample("Miguel agachado",game.player,"novo/Crouch_Fwd",1.05)
 key(KEY_W,false); key(KEY_CTRL,false)
 var enemy=game.enemies[1]
 game.enemies.clear(); game.enemies.append(enemy); game.sighting_seen=true; game.phone_light=false
 game.player.position=Vector3(230,0,230); game.player.hidden=true
 enemy.position=Vector3(200,.02,200); enemy.home=enemy.position+Vector3(0,0,-20)
 enemy.state="idle"; enemy.aware=false; enemy.suspicion=0; enemy.patrol_clock=0
 await sample("cultista patrulhando",enemy,"novo/Walk",1.45,true)
 enemy.aware=true; enemy.memory=25; game.player.hidden=false
 game.player.position=enemy.position+Vector3(0,0,-20); enemy.last_seen=game.player.position
 game.enemy_turn=null; game.protected_target=null
 await sample("cultista perseguindo Miguel",enemy,"novo/Sprint",3.8,true)
 await actions_and_stairs()
 print("CAPITULO1_ANIMACAO: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame
 quit(1 if failed else 0)

func single_action(clip: String) -> void:
 var actor=game.player
 actor.velocity=Vector3.ZERO; actor.crouched=false; actor.hidden=false; actor.state="idle"
 actor.play("guarda"); actor.animate(.3)
 actor.start_action(clip)
 var length: float=actor.anim.get_animation(clip).length
 var last:=0.0
 var maximum:=0.0
 var stalls:=0
 var active:=0
 var first:=100.0
 for i in ceili((length+.6)/DT):
  actor.animate(DT)
  if graph_clip(actor)==clip:
   var time: float=actor.motion.position()
   if active>1 and time<=last: stalls+=1
   first=minf(first,time); maximum=maxf(maximum,time); last=time; active+=1
  await physics_frame
 print("ACAO %s: duracao=%.3f ultimo=%.3f quadros=%d congelados=%d retorno=%s locomocao=%s"%[clip,length,maximum,active,stalls,actor.motion.playback.get_current_node(),actor.motion.travelling])
 check(active>0 and first<=DT and stalls==0 and not actor.anim.is_playing(),clip+": clipe certo e tempo avança")
 check(maximum>=length-DT*1.1,clip+": toca até o fim")
 check(actor.motion.playback.get_current_node()=="Locomocao" and actor.motion.travelling and graph_clip(actor)=="novo/Idle",clip+": volta sozinho para parado")
 actor.velocity=Vector3.BACK*1.45; actor.face(actor.position+Vector3.BACK)
 for i in 12: actor.animate(DT)
 check(graph_clip(actor)=="novo/Walk",clip+": andar retoma sem novo play")

func interaction_case(kind: String,object: Node3D,contact: Vector3,forward: Vector3,clip: String,index:=-1) -> void:
 var actor=game.player
 actor.state="idle"; actor.hidden=false; actor.crouched=false; actor.model.visible=true
 actor.velocity=Vector3.ZERO; actor.collision_layer=2
 game.phase="investigate"; game.interaction.clear()
 actor.position=contact-forward*.85-Vector3.UP*1.05
 if kind=="bag": actor.position.y=game.school.LEVEL
 else: actor.position.y=0
 actor.face(actor.position+forward)
 game._begin_interaction(kind,object,contact,forward,clip,index)
 check(not game.interaction.is_empty(),kind+": aproximação livre aceita")
 var touched:=false
 var contact_seen:=false
 var error:=100.0
 var maximum:=0.0
 var seen_clip:=false
 var climb_max:=0.0
 var climb_contact:=false
 var climb_seen:=false
 var contact_time: float=.72 if clip.ends_with("Interact") else (.30 if clip.ends_with("PickUp_Table") else .60)
 for i in 360:
  var before: Vector3=actor.position
  var target: Vector3=game.interaction.get("contact",contact)
  var was_started: bool=game.interaction.get("started",false)
  var previous: float=actor.motion.position()
  if game.phase=="gate_jump": game._physics_process(DT)
  else: game._player_tick(DT)
  if graph_clip(actor)=="novo/ClimbUp_1m":
   climb_seen=true; climb_max=maxf(climb_max,actor.motion.position())
   if actor.motion.consume("contact"):
    var hand: Vector3=actor.bone_point("LeftHand")
    var grade: Vector3=game.school.gate_at+Vector3(.19,2.35,0)
    climb_contact=hand.distance_to(grade)<.09
    print("CONTATO grade: erro=%.4f m"%hand.distance_to(grade))
  if graph_clip(actor)==clip:
   seen_clip=true; maximum=maxf(maximum,actor.motion.position())
  if not contact_seen and was_started and previous<contact_time and (actor.motion.position()>=contact_time or graph_clip(actor)!=clip):
   contact_seen=true
   error=(actor.bone_point("LeftHand")-actor.position+before).distance_to(target)
   touched=error<.09
   print("CONTATO %s: erro=%.4f m estado=%s"%[kind,error,actor.state])
  if game.interaction.is_empty() and actor.state=="idle": break
  await physics_frame
 print("INTERACAO %s: clipe=%s ultimo=%.3f estado=%s pendente=%s"%[kind,seen_clip,maximum,actor.state,not game.interaction.is_empty()])
 check(touched,kind+": mão toca alvo no quadro do evento (9 cm)")
 check(seen_clip and maximum>=actor.anim.get_animation(clip).length-DT*1.1,kind+": ação completa antes de sair")
 check(game.interaction.is_empty() and actor.state=="idle",kind+": ação termina sem congelar")
 match kind:
  "bag": check(game.bag_found and not game.school.bag.visible,"bolsa: efeito confirmado no contato")
  "door": check(object.opened,"porta: abriu no contato")
  "hide": check(actor.hidden,"armário: entrou após terminar o gesto")
  "gate": check(game.phase=="ending" and actor.position.z>game.school.gate_at.z,"portão: alcançou o outro lado")
 if kind=="gate":
  check(climb_seen and climb_max>=actor.anim.get_animation("novo/ClimbUp_1m").length-DT*1.1,"portão: escalada completa")
  check(climb_contact,"portão: mão toca grade no evento da escalada")
 if actor.hidden: game._leave_hide()
 game.phase="investigate"

func stair_case(up: bool) -> void:
 var actor=game.player
 var bottom: Vector3=game.school.stairs_bottom
 var top: Vector3=game.school.stairs_top
 var along: Vector3=(top-bottom)*Vector3(1,0,1)
 var length:=along.length(); along/=length
 var direction:=along if up else -along
 actor.position=(bottom if up else top)+direction*.5+Vector3.UP*.04
 actor.position.y=game.school.LEVEL*.5/length if up else game.school.LEVEL*(1-.5/length)
 actor.state="idle"; actor.crouched=false; actor.hidden=false; actor.velocity=Vector3.ZERO
 actor.face(actor.position+direction)
 game.view.yaw=atan2(-direction.x,-direction.z)
 var correct:=0; var advanced:=0; var samples:=0; var grounded:=0
 var pinned:=0; var stance_frames:=0; var max_slip:=0.0
 var previous_feet: Dictionary={}; var previous_stance: Dictionary={}
 var last: float=-1
 var last_pose=pose(actor)
 var clip:="novo/Ascending_Stairs" if up else "novo/Descending_Stairs"
 key(KEY_W,true)
 for i in 1800:
  game._player_tick(DT)
  var distance: float=(actor.position-bottom).dot(along)
  if distance>length-.3 or distance<.3: break
  if i>15:
   samples+=1
   if graph_clip(actor)==clip: correct+=1
   var current_pose=pose(actor)
   var changed_pose:=false
   for j in current_pose.size():
    if current_pose[j].distance_to(last_pose[j])>.000001: changed_pose=true
   if absf(actor.motion.position()-last)>.000001 or (changed_pose and not String(actor.motion.playback.get_fading_from_node()).is_empty()): advanced+=1
   last_pose=current_pose
   var phase=fposmod(actor.motion.position(),1)
   for side in ["Left","Right"]:
    var foot_now: Vector3=actor.bone_point(side+"Foot")
    var tread:=length/roundf(game.school.LEVEL/.17)
    var floor_height=clampf((floorf((foot_now-bottom).dot(along)/tread)+1)*.17,0,game.school.LEVEL)
    var stance=absf(foot_now.y-actor.motion.foot_clearance-floor_height)<.015
    if stance and previous_stance.get(side,false):
     var slip=foot_now.distance_to(previous_feet[side])
     stance_frames+=1; max_slip=maxf(max_slip,slip)
     if slip<.02: pinned+=1
    previous_feet[side]=foot_now; previous_stance[side]=stance
   for side in ["Left","Right"]:
    var foot: Vector3=actor.bone_point(side+"Foot")
    var foot_distance: float=(foot-bottom).dot(along)
    var tread:=length/roundf(game.school.LEVEL/.17)
    var height:=clampf((floorf(foot_distance/tread)+1)*.17,0,game.school.LEVEL)
    if absf(foot.y-actor.motion.foot_clearance-height)<.09: grounded+=1; break
  last=actor.motion.position()
  await physics_frame
 key(KEY_W,false)
 var label:="subir" if up else "descer"
 print("ESCADA %s: clipe=%s certo=%d/%d tempo=%d/%d apoio=%d/%d"%[label,graph_clip(actor),correct,samples,advanced,samples,grounded,samples])
 check(samples>30 and correct==samples,label+": clipe correto na escada")
 check(samples>30 and advanced==samples,label+": tempo avança")
 print("APOIO %s: fixo=%d/%d maior_desvio=%.4f m"%[label,pinned,stance_frames,max_slip])
 if stance_frames==0 or pinned<stance_frames: print("AVISO ",label,": apoio varia no clipe original; nenhuma correção de ossos aplicada")
 if grounded<samples: print("AVISO ",label,": pés originais não encaixam em todos os pisos visuais")

func actions_and_stairs() -> void:
 game.player.position=Vector3(200,0,200)
 for clip in ["novo/PickUp_Table","novo/Interact","novo/Chest_Open","novo/ClimbUp_1m"]:
  await single_action(clip)
 await interaction_case("bag",game.school.bag,game.school.bag_at,Vector3.BACK,"novo/PickUp_Table")
 var door=game.school.doors[0]
 door.set_open(false,true)
 await interaction_case("door",door,door.handle_point(1),-door.normal,"novo/Interact")
 var hide=game.school.hides[0]
 await interaction_case("hide",null,hide["inside"]+hide["normal"]*.38+Vector3.UP*1.05,-hide["normal"],"novo/Chest_Open",0)
 await interaction_case("gate",game.school.gate,game.school.gate_at+Vector3.UP*1.1,Vector3.BACK,"novo/Interact")
 await stair_case(true)
 await stair_case(false)
 var descent: Animation=game.player.anim.get_animation("novo/Descending_Stairs")
 var original: Animation=game.player.motion.LIBRARY.get_animation("Descending_Stairs")
 check(descent==original and descent.loop_mode==Animation.LOOP_NONE,"Descending_Stairs original intacto; repetições usam crossfade")
 check(game.player.anim.get_animation("novo/Stunned").loop_mode==Animation.LOOP_NONE,"Stunned não é usado em loop")

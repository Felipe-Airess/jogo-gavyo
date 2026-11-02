extends SceneTree
## Regressão de locomoção: física, grafo e ossos reais, durante três segundos.
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
 if state not in ["Locomocao","Agachado"]: return state
 var blend=motion.machine.get_node(state).get_node("Velocidade") as AnimationNodeBlendSpace1D
 var value=float(motion.tree.get("parameters/"+state+"/Velocidade/blend_position"))
 var nearest:=0
 for i in blend.get_blend_point_count():
  if absf(blend.get_blend_point_position(i)-value)<absf(blend.get_blend_point_position(nearest)-value): nearest=i
 return String(blend.get_blend_point_node(nearest).animation)
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
  var expected_phase: float=speed*DT/stride
  if absf(fposmod(now-time,1.0)-expected_phase)<.0001: paced+=1
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
 check(changing.all(func(n):return n==180),label+": pés e mãos mudam em todos os quadros")
 check(absf(measured/3.0-speed)<.03,label+": velocidade real %.2f m/s"%speed)
func run() -> void:
 var deadline=create_timer(60,true,false,true)
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
 print("CAPITULO1_ANIMACAO: %d passed, %d failed"%[passed,failed])
 game.queue_free(); await process_frame
 quit(1 if failed else 0)

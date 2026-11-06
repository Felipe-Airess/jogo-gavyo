extends Node3D
## Protótipo integrado. Simulação de movimento/combate em passo físico de 60 Hz.
const ACTOR = preload("res://prototipo/actor.gd")
const SCHOOL = preload("res://prototipo/school.gd")
const CAMERA = preload("res://prototipo/camera.gd")
const HUD = preload("res://prototipo/hud.gd")
const SAVE_PATH := "user://terror_checkpoint_v2.json"
const MOTION_PROFILE = preload("res://prototipo/motion_profile.gd")
const HOOK_TIME = MOTION_PROFILE.CONTACT_TIME
const HOOK_DURATION = MOTION_PROFILE.DURATION
const HOOK_BIAS = MOTION_PROFILE.YAW_BIAS
const ACTIVE_FROM = MOTION_PROFILE.ACTIVE_FROM
const ACTIVE_TO = MOTION_PROFILE.ACTIVE_TO
const SPAWN := Vector3(-7,0,10.65)
const ENEMY_SPAWNS := [Vector3(.5,0,2), Vector3(-.6,0,-15)]
var player: CharacterBody3D
var enemies: Array[CharacterBody3D] = []
var pursuer: CharacterBody3D
var locked: CharacterBody3D
var school: Node3D
var view: Node3D
var hud: CanvasLayer
var elapsed = 0.0
var phase = "investigate"
var paused = true
var started = false
var food = 0
var knife = false
var hidden_spot = -1
var hidden_at = Vector3.ZERO
var checkpoint: Dictionary = {}
var checkpoint_index = 0
var path_grid: AStarGrid2D
var path_cooldown = 0.0
var paths: Dictionary = {}
var protected_target: CharacterBody3D
var enemy_turn: CharacterBody3D
var turn_cooldown = 0.0
var attack_mode = ""
var attack_duration = .65
var attack_time = .3
var attack_clip = "jab"
var attack_origin = Vector3.ZERO
var attack_hit_point = Vector3.ZERO
var action_target: CharacterBody3D
var buffered_attack = false
var vault: Dictionary = {}
var pursuer_vault: Dictionary = {}
var pursuit_memory = 0.0
var seen_hiding = false
var search_time = 0.0
var footstep_time = 0.0
var show_help = false
var ambience: AudioStreamPlayer
var cult_audio: AudioStreamPlayer3D
var step_audio: AudioStreamPlayer3D
var impact_audio: AudioStreamPlayer3D
var blood: Array[Node3D] = []
var gate_open = false
var qa_mode = false
var lightweight = true
var simulation_ticks = 0
var intro_clock = 0.0
var discovery_clock = 0.0
var intro_seen = false
var peek_door: Node3D
var dodge_origin = Vector3.ZERO
var short_dodge = false
var impact_pause = 0.0
var combat_stats = {"enemy_attacks":0,"enemy_hits":0,"misses":0,"counters":0,"counter_hits":0}

func _ready() -> void:
 qa_mode = "--qa-inspect" in OS.get_cmdline_user_args()
 lightweight = not "--qualidade" in OS.get_cmdline_user_args()
 get_viewport().msaa_3d=Viewport.MSAA_DISABLED if lightweight else Viewport.MSAA_2X
 if get_tree().root is Window:
  get_tree().root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT if lightweight else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 school = SCHOOL.new()
 add_child(school)
 school.build(self)
 player = spawn_actor(SPAWN,false)
 player.face(SPAWN+Vector3.RIGHT)
 for at in ENEMY_SPAWNS:
  var e = spawn_actor(at,true)
  e.face(at+Vector3.FORWARD)
  enemies.append(e)
 view = CAMERA.new()
 add_child(view)
 view.setup(self)
 view.yaw = -PI/2
 view.global_position = player.position+Vector3(0,1.22,0)
 hud = HUD.new()
 add_child(hud)
 hud.setup(self)
 _audio()
 var perf=load("res://prototipo/performance_monitor.gd").new()
 add_child(perf)
 perf.setup(self)
 _snapshot(false)
 checkpoint["position"]=[SPAWN.x,SPAWN.y,SPAWN.z-.55]
 call_deferred("_build_paths")
 if qa_mode:
  var bridge=load("res://prototipo/qa_bridge.gd").new()
  add_child(bridge)
  bridge.setup(self)

func spawn_actor(at: Vector3, is_enemy: bool, big := false) -> CharacterBody3D:
 var actor = ACTOR.new()
 add_child(actor)
 actor.setup(self,at,is_enemy,big)
 return actor

func _audio() -> void:
 ambience = AudioStreamPlayer.new()
 ambience.stream = load("res://prototipo/audio/grilos.wav").duplicate()
 ambience.stream.loop_end = int(ambience.stream.get_length()*ambience.stream.mix_rate)
 ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 ambience.volume_db = -17
 add_child(ambience)
 ambience.play()
 cult_audio = AudioStreamPlayer3D.new()
 cult_audio.position = Vector3(0,1,-29)
 cult_audio.stream = load("res://prototipo/audio/culto.wav").duplicate()
 cult_audio.stream.loop_end = int(cult_audio.stream.get_length()*cult_audio.stream.mix_rate)
 cult_audio.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 cult_audio.unit_size = 7
 cult_audio.max_distance = 42
 cult_audio.volume_db = -7
 add_child(cult_audio)
 cult_audio.play()
 step_audio = AudioStreamPlayer3D.new()
 step_audio.stream = load("res://prototipo/audio/passo.wav").duplicate()
 step_audio.volume_db = -15
 add_child(step_audio)
 impact_audio = AudioStreamPlayer3D.new()
 impact_audio.stream = load("res://prototipo/audio/impacto.wav").duplicate()
 impact_audio.volume_db = -6
 add_child(impact_audio)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE:
   paused = not paused
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
   get_viewport().set_input_as_handled()
   return
  if event.keycode == KEY_ENTER and (not started or phase == "escaped"):
   if phase == "escaped":
    get_tree().reload_current_scene()
    return
   begin()
   return
  if not started and event.keycode == KEY_C:
   load_checkpoint()
   begin()
   return
  if event.keycode == KEY_R and (player.dead or paused):
   restore_checkpoint()
   begin()
   return
  if paused or player.dead:
   return
  if phase in ["intro","discovery"]:
   if event.keycode==KEY_SPACE:
    end_intro() if phase=="intro" else end_discovery()
   return
  match event.keycode:
   KEY_SPACE: interact()
   KEY_E: heal()
   KEY_Q: takedown_or_finish()
   KEY_F1: show_help = not show_help
   KEY_F: toggle_peek()
 if paused or player.dead or phase in ["escaped","intro","discovery"]:
  return
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  view.look_mouse(event.screen_relative)
 if event is InputEventMouseButton and event.pressed:
  match event.button_index:
   MOUSE_BUTTON_LEFT: attack()
   MOUSE_BUTTON_RIGHT: dodge()
   MOUSE_BUTTON_MIDDLE: toggle_lock()
   MOUSE_BUTTON_WHEEL_UP: cycle_target(1)
   MOUSE_BUTTON_WHEEL_DOWN: cycle_target(-1)

func begin() -> void:
 started=true
 paused=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if qa_mode else Input.MOUSE_MODE_CAPTURED
 if checkpoint_index==0 and not intro_seen:
  phase="intro"
  intro_clock=0
  player.state="intro"
  player.face(player.position+Vector3.FORWARD)
  player.play("prototype/sit")
 else:
  phase="investigate" if phase=="intro" else phase

func end_intro() -> void:
 player.position=SPAWN+Vector3(0,0,-.55)
 intro_seen=true
 phase="investigate"
 player.state="idle"
 player.clock=0
 player.play("guarda")
 view.yaw=-1.08
 view.pitch=-.12
 hud.say("As vozes vêm do pátio. [Espaço] abre a porta. [F] espia pela fresta.",5)

func end_discovery() -> void:
 phase="chase"
 player.state="idle"
 player.face(player.position+Vector3.BACK)
 view.yaw=PI
 view.pitch=0
 hud.say("Ele viu você. SAIA DA ESCOLA.",4)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and not qa_mode:
  paused = true
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(dt: float) -> void:
 view.update(dt)
 hud.update(dt)

func _physics_process(dt: float) -> void:
 if paused or player.dead or phase == "escaped":
  return
 simulation_ticks += 1
 elapsed += dt
 school.update(dt,elapsed)
 if phase=="intro":
  intro_clock+=dt
  if intro_clock>=6.3:
   player.position=SPAWN+Vector3(0,0,-.55*smoothstep(6.3,7.5,intro_clock))
  if intro_clock>=6.3 and player.motion.active_clip=="novo/Sitting_Idle":
   player.start_action("novo/Sitting_Exit")
  player.animate(dt)
  if intro_clock>=8.0:
   end_intro()
  return
 if phase=="discovery":
  discovery_clock+=dt
  player.animate(dt)
  if is_instance_valid(pursuer):
   pursuer.animate(dt)
  if discovery_clock>=2.5:
   end_discovery()
  return
 if impact_pause>0:
  impact_pause=maxf(0,impact_pause-dt)
  return
 turn_cooldown = maxf(0,turn_cooldown-dt)
 _player_tick(dt)
 if protected_target != null and player.state not in ["attack"] and elapsed > player.chain_until:
  protected_target = null
 _enemy_ticks(dt)
 _pursuer_tick(dt)
 if player.dead:
  return
 if is_instance_valid(locked) and (locked.dead or locked.down or locked.global_position.distance_to(player.global_position)>13 or phase=="chase"):
  locked = null
 if phase == "investigate":
  if player.position.z < -19.8 and checkpoint_index == 0:
   checkpoint_index = 1
   _snapshot()
   hud.say("Checkpoint",2)
  if player.position.z < -26.4:
   start_chase()
 elif phase == "chase":
  if player.position.z > 11.8 and not gate_open:
   gate_open = true
   school.open_exit()
  if player.position.z > 14.1:
   phase = "escaped"
   locked = null
   Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func raw_movement() -> Vector2:
 return Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()

## Capítulos podem reduzir a velocidade (ex.: lentidão depois de um susto).
func _multiplicador_velocidade() -> float:
 return 1.0

func _player_tick(dt: float) -> void:
 var raw = raw_movement()
 var direction: Vector3 = view.movement(raw)
 player.clock += dt
 player.opening = maxf(0,player.opening-dt)
 if player.state == "hang":
  player.animate(dt)
  return
 if player.state == "vault":
  _vault_tick(player,vault,dt)
  player.animate(dt)
  return
 if player.hidden or is_instance_valid(peek_door):
  player.animate(dt)
  return
 if player.state == "heal":
  if raw.length()>.01:
   cancel_heal()
  elif player.clock >= 2.4:
   player.health = minf(100,player.health+40)
   food -= 1
   player.state = "idle"
   hud.say("Empanado consumido. +40 de vida.",2)
 if player.state=="dodge":
  if short_dodge:
   var slip=sin(clampf(player.clock/.56,0,1)*PI)*.30
   var destination=dodge_origin+player.dodge_direction*slip
   player.move_and_collide(destination-player.position)
  else:
   player.velocity.x=player.dodge_direction.x*3.5
   player.velocity.z=player.dodge_direction.z*3.5
   player._slide(dt)
  player.animate(dt)
  if player.clock>=.56:
   player.state="idle"
  return
 if player.state == "attack":
  _attack_tick(dt)
  return
 if player.state == "hurt":
  player.animate(dt)
  player.velocity.x = 0
  player.velocity.z = 0
  player._slide(dt)
  if player.clock > .40:
   player.state = "idle"
  return
 var moving = raw.length() > .01 and player.state != "heal"
 _crouch(Input.is_physical_key_pressed(KEY_CTRL))
 var running = Input.is_physical_key_pressed(KEY_SHIFT) and moving and not player.crouched
 var speed = (1.05 if player.crouched else (3.8 if running else 1.45))*_multiplicador_velocidade()
 player.velocity.x = direction.x * speed if moving else 0.0
 player.velocity.z = direction.z * speed if moving else 0.0
 if is_instance_valid(locked):
  player.face(locked.global_position,dt)
 elif moving:
  player.face(player.position+direction,dt)
 player.play("correr" if running else ("andaFrente" if moving else "guarda"),1.2 if running else 1.0)
 player._slide(dt)
 player.animate(dt)
 if moving:
  footstep_time -= dt
  if footstep_time <= 0:
   footstep_time = .30 if running else .50
   step_audio.position = player.position
   step_audio.pitch_scale = 1.12 if running else .94
   step_audio.volume_db = -27 if player.crouched else (-12 if running else -21)
   step_audio.play()
 if phase == "chase" and moving and player.is_on_floor():
  try_vault(player,direction,true)

func _crouch(wanted: bool) -> void:
 if player.crouched == wanted:
  return
 var shape = player.get_child(0) as CollisionShape3D
 if not wanted:
  var q = PhysicsShapeQueryParameters3D.new()
  var capsule = CapsuleShape3D.new()
  capsule.height = 1.64
  capsule.radius = .27
  q.shape = capsule
  q.transform.origin = player.position+Vector3(0,.82,0)
  q.collision_mask = 1
  if not get_world_3d().direct_space_state.intersect_shape(q).is_empty():
   return
 player.crouched = wanted
 shape.shape.height = .95 if wanted else 1.64
 shape.position.y = .475 if wanted else .82

func visible_between(from: Vector3, to: Vector3) -> bool:
 var query = PhysicsRayQueryParameters3D.create(from,to,1)
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func enemy_sees(actor: CharacterBody3D, ignore_facing := false) -> bool:
 if player.dead:
  return false
 var delta = player.global_position-actor.global_position
 var distance = delta.length()
 if distance > (19.0 if actor.pursuer else 10.5):
  return false
 var eye: Vector3 = actor.bone_point("Head")
 var target: Vector3 = player.position+Vector3(0,.75 if player.crouched else 1.25,0)
 if not visible_between(eye,target):
  return false
 if player.hidden:
  return seen_hiding
 delta.y = 0
 var cone = .1 if actor.pursuer else .40
 return ignore_facing or distance < .62 or actor.facing.dot(delta.normalized()) > cone

func _enemy_ticks(dt: float) -> void:
 for e in enemies:
  e.clock+=dt
  e.opening=maxf(0,e.opening-dt)
  if e.dead:
   e.animate(dt)
   continue
  if e.down:
   e.animate(dt)
   if e.clock>1.05:
    e.kill()
   continue
  if e.state=="vault":
   _vault_tick(e,e.traversal,dt)
   e.animate(dt)
   continue
  if e==protected_target:
   e.animate(dt)
   continue
  if phase!="investigate":
   e.play("guarda")
   e.animate(dt)
   continue
  var distance=e.position.distance_to(player.position)
  var sees=enemy_sees(e)
  var loud=not player.crouched and player.velocity.length()>1.1 and distance<(8.0 if player.velocity.length()>2.5 else 3.8)
  if player.state in ["attack","vault"] and distance<8:
   loud=true
  if sees or loud:
   e.suspicion=minf(1,e.suspicion+dt*(2.8 if sees else 1.0))
   e.last_seen=player.position
   e.memory=7.0
   if e.suspicion>=1:
    e.aware=true
   if not e.aware and loud:
    e.face(e.last_seen,dt*.45)
  else:
   e.suspicion=maxf(0,e.suspicion-dt*.25)
   e.memory=maxf(0,e.memory-dt)
  if e.attack_target!=null:
   # O mesmo clipe continua da preparação até a recuperação, sem reiniciar.
   if e.clock<.35:
    e.face(player.position,dt)
   e.state="windup" if e.clock<ACTIVE_FROM else ("strike" if e.clock<ACTIVE_TO else "recover")
   e.animate(dt)
   var hand: Vector3=e.fist_point()
   if e.clock>=ACTIVE_FROM and e.clock<=ACTIVE_TO and not e.hit_once and protected_target==null:
    _enemy_contact(e)
   e.hand_previous=hand
   if e.clock>ACTIVE_TO and not e.attack_landed:
    e.attack_landed=true
    e.opening=1.35 if not e.hit_once else .8
    if not e.hit_once:
     combat_stats["misses"]+=1
     hud.say("Ele errou. Clique esquerdo para contra-atacar.",1.3)
   if e.clock>=HOOK_DURATION:
    e.attack_target=null
    e.state="idle"
    e.clock=0
    e.strike_yaw_bias=0
    e.play("guarda")
    enemy_turn=null
    turn_cooldown=1.1
   continue
  if not e.aware:
   e.patrol_clock+=dt
   if e.suspicion>.1:
    _navigate(e,e.last_seen,.8,dt)
   else:
    var slot=int(e.patrol_clock/3.0)%4
    if slot in [1,3]:
     var point=e.home+Vector3(0,0,1.7 if slot==1 else -1.7)
     _navigate(e,point,.65,dt)
    else:
     e.velocity=Vector3.ZERO
     e.face(e.position+(Vector3.FORWARD if slot==0 else Vector3.BACK),dt*.4)
     e.play("guarda")
   e.animate(dt)
   continue
  if not sees and e.memory<=0:
   e.aware=false
   e.suspicion=.2
  elif distance>1.0:
   var speed=1.35 if enemy_turn==null and protected_target==null else .5
   _navigate(e,player.position,speed,dt)
  else:
   e.velocity=Vector3.ZERO
   e.face(player.position,dt)
   e.play("guarda")
   if enemy_turn==null and protected_target==null and turn_cooldown<=0 and e.opening<=0 and not player.hidden and visible_between(e.bone_point("Head"),player.bone_point("Head")):
    _start_enemy_attack(e)
  e.animate(dt)

func _start_enemy_attack(e: CharacterBody3D) -> void:
 enemy_turn=e
 e.state="windup"
 e.clock=0
 e.hit_once=false
 e.attack_landed=false
 e.attack_target=player
 e.strike_yaw_bias=HOOK_BIAS
 e.face(player.position,.016)
 e.play("prototype/hook")
 e.hand_previous=e.fist_point()
 combat_stats["enemy_attacks"]+=1

func _hand_hits(attacker: CharacterBody3D, target: CharacterBody3D) -> bool:
 var hand: Vector3=attacker.fist_point()
 if not visible_between(attacker.bone_point("Chest"),hand):
  return false
 var q=PhysicsShapeQueryParameters3D.new()
 var sphere=SphereShape3D.new()
 sphere.radius=.105
 q.shape=sphere
 q.transform.origin=hand
 q.collision_mask=4
 q.collide_with_areas=true
 q.collide_with_bodies=false
 var contacts=get_world_3d().direct_space_state.intersect_shape(q,16)
 if attacker.hand_previous.distance_to(hand)<.25:
  var sweep=PhysicsRayQueryParameters3D.create(attacker.hand_previous,hand,4)
  sweep.collide_with_areas=true
  sweep.collide_with_bodies=false
  var swept=get_world_3d().direct_space_state.intersect_ray(sweep)
  if not swept.is_empty():
   contacts.append(swept)
 for hit in contacts:
  if hit["collider"].get_meta("actor",null)==target:
   return true
 return false

func _enemy_contact(e: CharacterBody3D) -> void:
 if player.hidden or player.state=="attack" or not _hand_hits(e,player):
  return
 e.hit_once=true
 combat_stats["enemy_hits"]+=1
 hurt_player(38)

func available_targets() -> Array[CharacterBody3D]:
 var result: Array[CharacterBody3D] = []
 for e in enemies:
  if not e.dead and not e.down and e.position.distance_to(player.position)<11 and visible_between(player.bone_point("Head"),e.bone_point("Head")):
   result.append(e)
 result.sort_custom(func(a,b): return player.position.distance_squared_to(a.position)<player.position.distance_squared_to(b.position))
 return result

func toggle_lock() -> void:
 if phase=="chase":
  return
 if locked != null:
  locked = null
 else:
  var candidates = available_targets()
  if not candidates.is_empty():
   locked = candidates[0]

func cycle_target(direction: int) -> void:
 if phase=="chase":
  return
 var candidates = available_targets()
 if candidates.is_empty():
  locked = null
  return
 var index = candidates.find(locked)
 locked = candidates[posmod(index+direction,candidates.size())]

func nearest_enemy(max_distance := 1.7, allow_down := false) -> CharacterBody3D:
 var target: CharacterBody3D
 var best = max_distance
 for e in enemies:
  if e.dead or (e.down and not allow_down):
   continue
  var distance = player.position.distance_to(e.position)
  if distance<best and visible_between(player.bone_point("Chest"),e.bone_point("Head")):
   target=e
   best=distance
 return target

func is_behind(e: CharacterBody3D) -> bool:
 var delta: Vector3 = (player.position-e.position).normalized()
 return not e.aware and e.suspicion<.8 and e.facing.dot(delta)<-.30

func attack() -> void:
 if player.hidden or is_instance_valid(peek_door) or phase!="investigate" or player.state not in ["idle","heal"]:
  return
 var e=nearest_enemy(1.35)
 if e==null:
  hud.say("Aproxime-se e espere o ataque. Esta versão testa só a troca básica.",2)
  return
 var stealth=is_behind(e)
 if e.opening<=0 and not stealth:
  hud.say("Espere o golpe. Esquive e aproveite a recuperação.",1.5)
  return
 cancel_heal()
 action_target=e
 protected_target=e
 attack_mode="stealth" if stealth else "counter"
 player.state="attack"
 player.clock=0
 player.hit_once=false
 player.strike_bone="RightHand"
 player.strike_yaw_bias=HOOK_BIAS
 attack_duration=HOOK_DURATION
 attack_origin=player.position
 player.play("prototype/hook")
 player.face(e.position,.016)
 player.hand_previous=player.fist_point()
 combat_stats["counters"]+=1

func _attack_tick(dt: float) -> void:
 if not is_instance_valid(action_target):
  player.state="idle"
  protected_target=null
  return
 var e=action_target
 if player.clock<.35:
  player.face(e.position,dt)
  var distance=player.position.distance_to(e.position)
  if distance>.98 and player.position.distance_to(attack_origin)<.18:
   player.move_toward(e.position,.5,dt)
 player.animate(dt)
 var hand: Vector3=player.fist_point()
 if player.clock>=ACTIVE_FROM and player.clock<=ACTIVE_TO and not player.hit_once and _hand_hits(player,e):
  player.hit_once=true
  _land_hit(e,hand)
 player.hand_previous=hand
 if player.clock>=HOOK_DURATION:
  player.state="idle"
  player.strike_yaw_bias=0
  protected_target=null
  player.play("guarda")
  if not player.hit_once:
   hud.say("Fora do alcance. O golpe não conectou.",1.5)

func _land_hit(e: CharacterBody3D, at: Vector3) -> void:
 combat_stats["counter_hits"]+=1
 e.health=0
 e.attack_target=null
 e.strike_yaw_bias=0
 e.make_down()
 enemy_turn=null
 turn_cooldown=1.3
 impact_pause=.045
 _impact(at,true)
 hud.say("Contra-ataque conectado.",1.8)

func dodge() -> void:
 if phase!="investigate" or player.hidden or is_instance_valid(peek_door) or player.state not in ["idle","heal"]:
  return
 cancel_heal()
 var raw=raw_movement()
 short_dodge=raw.length()<.1
 player.state="dodge"
 player.clock=0
 dodge_origin=player.position
 player.dodge_direction=-player.model.global_basis.x.normalized() if short_dodge else view.movement(raw)
 player.play("prototype/slip")

func takedown_or_finish() -> void:
 hud.say("Primeiro teste: esquiva e um contra-ataque. Sequências entram depois.",2)

func _impact(at: Vector3, gore: bool) -> void:
 view.trauma=minf(1,view.trauma+.28)
 impact_audio.position=at
 impact_audio.pitch_scale=.9+float(simulation_ticks%5)*.04
 impact_audio.play()
 for prop in school.reactive:
  if prop.global_position.distance_to(at)<1.8:
   var mesh = prop.get_child(0) if prop.get_child_count()>0 else null
   if mesh is MeshInstance3D:
    var rest: Vector3=mesh.rotation
    var reaction = mesh.create_tween()
    reaction.tween_property(mesh,"rotation:z",rest.z+.035,.055)
    reaction.tween_property(mesh,"rotation:z",rest.z,.18)
 if not gore:
  return
 var mat = StandardMaterial3D.new()
 mat.albedo_color=Color(.21,.006,.012)
 mat.roughness=.8
 var stain = MeshInstance3D.new()
 var mesh = CylinderMesh.new()
 mesh.top_radius=.19+float(simulation_ticks%4)*.035
 mesh.bottom_radius=mesh.top_radius
 mesh.height=.008
 mesh.radial_segments=9
 stain.mesh=mesh
 stain.material_override=mat
 stain.position=Vector3(at.x,.012+float(blood.size()%5)*.002,at.z)
 add_child(stain)
 blood.append(stain)
 for i in range(7):
  var drop = MeshInstance3D.new()
  var cube = BoxMesh.new()
  cube.size=Vector3(.025,.025,.025)
  drop.mesh=cube
  drop.material_override=mat
  drop.position=at
  add_child(drop)
  var destination = at+Vector3(sin(i*2.4)*.5,-at.y+.025,cos(i*1.7)*.6)
  var tween = drop.create_tween()
  tween.tween_property(drop,"position",destination,.30+i*.012).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  tween.tween_callback(drop.queue_free)
 if blood.size()>70:
  blood.pop_front().queue_free()

func heal() -> void:
 if food<=0 or player.health>=100 or player.state!="idle" or player.hidden:
  return
 player.state="heal"
 player.clock=0
 hud.say("Miguel precisa de um momento para comer.",1.5)

func cancel_heal() -> void:
 if player.state=="heal":
  player.state="idle"
  player.clock=0

func hurt_player(damage: float) -> void:
 if player.dead:
  return
 cancel_heal()
 player.health=maxf(0,player.health-damage)
 player.state="hurt"
 player.clock=0
 player.play("guarda")
 hud.flash.color.a=.38
 view.trauma=.65
 protected_target=null
 player.chain_until=0
 player.combo=0
 if player.health<=0:
  player.make_down()
  player.dead=true
  Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func interact() -> void:
 if player.state=="hang":
  vault["climb"]=true
  player.clock=float(vault["hang_clock"])
  player.state="vault"
  return
 if player.hidden:
  _leave_hide()
  return
 if player.state not in ["idle","heal"]:
  return
 cancel_heal()
 if is_instance_valid(peek_door):
  peek_door=null
 for door in school.doors:
  if player.position.distance_to(door.global_position)<1.65:
   door.toggle()
   hud.say("Porta aberta." if door.opened else "Porta fechada.",1.5)
   return
 for item in school.pickups:
  if not item["taken"] and player.position.distance_to(item["at"])<1.35:
   item["taken"]=true
   item["node"].visible=false
   if item["kind"]=="empanado":
    food+=1
    hud.say("Empanado guardado. [E] Comer",2)
   else:
    knife=true
    hud.say("Faca guardada. Uma chance se ele agarrar você.",3)
   return
 for i in school.hides.size():
  if player.position.distance_to(school.hides[i]["entry"])<1.2:
   _enter_hide(i)
   return
 var direction: Vector3=view.movement(raw_movement())
 if direction.length()<.1:
  direction=player.facing
 try_vault(player,direction,false)

func context_text() -> String:
 if player.state=="hang":
  return "NA BEIRADA · [Espaço] Subir"
 if phase in ["intro","discovery"]:
  return "[Espaço] Pular cena"
 if is_instance_valid(peek_door):
  return "PELA FRESTA · [F] Voltar · [Espaço] Abrir porta"
 if show_help:
  return "WASD mover · Shift correr · Ctrl agachar · Espaço ação\nEsq contra-atacar · Dir esquivar · F espiar · E comer · Meio alvo"
 if player.hidden:
  return "ESCONDIDO — observe pela fresta e escute.\n[Espaço] Sair"
 for door in school.doors:
  if player.position.distance_to(door.global_position)<1.65:
   return "[Espaço] "+("Fechar " if door.opened else "Abrir ")+door.title+(" · [F] Espiar" if not door.opened else "")
 for item in school.pickups:
  if not item["taken"] and player.position.distance_to(item["at"])<1.35:
   return "[Espaço] Pegar "+item["kind"]
 for spot in school.hides:
  if player.position.distance_to(spot["entry"])<1.2:
   return "[Espaço] Entrar no armário — quebre a visão antes"
 var e = nearest_enemy(1.5,true)
 if e!=null:
  if e.down:
   return "Ele caiu."
  if is_behind(e):
   return "Não foi visto. [Clique esquerdo] Finalizar ou passe escondido"
  if e.opening>0 or protected_target==e:
   return "ABERTURA · [Clique esquerdo] Contra-atacar"
 for obstacle in school.obstacles:
  if player.position.distance_to(obstacle["at"])<1.8:
   return "[Espaço] Transpor / subir · automático na perseguição"
 if phase=="investigate" and player.position.z>11:
  return "Miguel: essas vozes vêm do bloco B…"
 if is_instance_valid(locked):
  return "ALVO TRAVADO · rodinha troca · botão do meio solta"
 return ""

func try_vault(actor: CharacterBody3D, direction: Vector3, automatic: bool) -> bool:
 if actor.state!="idle" or direction.length()<.1:
  return false
 for obstacle in school.obstacles:
  var offset: Vector3=actor.position-obstacle["at"]
  var normal: Vector3=obstacle["normal"]
  var side = signf(offset.dot(normal))
  if side==0:
   side=1
  var lateral = offset-normal*offset.dot(normal)
  if lateral.length()>float(obstacle["size"].x)*.5+.15 or absf(offset.dot(normal))>1.65:
   continue
  if direction.dot(-normal*side)<.55:
   continue
  var destination: Vector3=actor.position-normal*side*(absf(offset.dot(normal))+float(obstacle["distance"]))
  destination.y=.05
  # Escalada/beirada termina sobre plataforma; transposição atravessa.
  if obstacle["kind"] in ["climb","ledge"] and not actor.pursuer:
   destination=Vector3(actor.position.x,float(obstacle["height"])+.04,float(obstacle["at"].z))
  var query = PhysicsShapeQueryParameters3D.new()
  var capsule = CapsuleShape3D.new()
  capsule.radius=.28
  capsule.height=1.64 if not actor.pursuer else 1.95
  query.shape=capsule
  query.transform.origin=destination+Vector3(0,capsule.height/2,0)
  query.collision_mask=1
  if not get_world_3d().direct_space_state.intersect_shape(query).is_empty():
   continue
  var data = {"from":actor.position,"to":destination,"duration":1.15 if actor.pursuer else (.85 if obstacle["kind"]=="ledge" else .62),"height":float(obstacle["height"]),"kind":obstacle["kind"]}
  data["hang_at"]=Vector3(actor.position.x,maxf(0,float(obstacle["height"])-1.1),float(obstacle["at"].z)+side*(float(obstacle["size"].z)/2+.32))
  actor.traversal=data
  if actor==player:
   vault=data
  else:
   pursuer_vault=data
  actor.state="vault"
  actor.clock=0
  actor.velocity=Vector3.ZERO
  actor.face(destination)
  actor.play("guarda")
  return true
 return false

func _vault_tick(actor: CharacterBody3D, data: Dictionary, dt: float) -> void:
 var t = clampf(actor.clock/float(data["duration"]),0,1)
 var desired: Vector3=data["from"].lerp(data["to"],smoothstep(0,1,t))
 var top = float(data["height"])+.14
 if data["kind"]=="ledge" and actor==player and phase!="chase":
  var hang_at: Vector3=data["hang_at"]
  if t<.42:
   desired=data["from"].lerp(hang_at,smoothstep(0,.42,t))
   desired.y+=sin(t/.42*PI)*.15
  elif not data.get("climb",false):
   actor.move_and_collide(hang_at-actor.position)
   actor.state="hang"
   data["hang_clock"]=actor.clock
   return
  else:
   var rise=clampf((t-.42)/.58,0,1)
   desired=hang_at.lerp(data["to"],smoothstep(.48,1,rise))
   desired.y=lerpf(hang_at.y,float(data["to"].y),smoothstep(0,.5,rise))
 else:
  desired.y=maxf(desired.y,lerpf(float(data["from"].y),float(data["to"].y),t)+sin(t*PI)*top)
 # Volumes varridos; só o obstáculo escolhido pode ser transposto, nunca paredes.
 var motion = desired-actor.position
 var collision = actor.move_and_collide(motion,true)
 if collision and collision.get_normal().y<.4 and t>.2 and t<.8:
  # Levanta antes do avanço horizontal para evitar cortar a borda do obstáculo.
  actor.move_and_collide(Vector3(0,maxf(0,desired.y-actor.position.y),0))
  actor.move_and_collide(Vector3(motion.x,0,motion.z))
 else:
  actor.move_and_collide(motion)
 if t>=1:
  actor.state="idle"
  actor.clock=0
  actor.velocity=Vector3.ZERO

func _enter_hide(index: int) -> void:
 seen_hiding=false
 for e in enemies:
  if not e.dead and enemy_sees(e,true) and e.aware:
   seen_hiding=true
 if is_instance_valid(pursuer) and enemy_sees(pursuer,true):
  seen_hiding=true
 hidden_spot=index
 hidden_at=player.position
 player.hidden=true
 player.model.visible=false
 player.position=school.hides[index]["inside"]
 player.velocity=Vector3.ZERO
 locked=null
 var normal: Vector3=school.hides[index]["normal"]
 view.yaw=atan2(-normal.x,-normal.z)
 view.pitch=0
 hud.say("Ele viu onde você entrou!" if seen_hiding else "Fique quieto. Escute os passos.",2)

func _leave_hide() -> void:
 if hidden_spot<0:
  return
 player.position=school.hides[hidden_spot]["entry"]
 player.hidden=false
 player.model.visible=true
 hidden_spot=-1
 seen_hiding=false

func start_chase() -> void:
 if phase!="investigate":
  return
 phase="discovery"
 discovery_clock=0
 locked=null
 protected_target=null
 enemy_turn=null
 player.state="idle"
 player.chain_until=0
 player.combo=0
 if player.hidden:
  _leave_hide()
 # Aparição dentro do espaço ritual, fora da visão inicial ao chegar.
 pursuer=spawn_actor(Vector3(3,0,-30),true,true)
 pursuer.play("guarda")
 pursuer.face(player.position)
 pursuer.aware=true
 pursuer.last_seen=player.position
 pursuit_memory=12
 hud.say("Uma voz: você não devia estar aqui.\nMiguel: preciso sair. Preciso avisar os outros.",4)
 impact_audio.position=pursuer.position
 impact_audio.pitch_scale=.65
 impact_audio.play()
 view.trauma=.3

func _pursuer_tick(dt: float) -> void:
 if not is_instance_valid(pursuer) or phase!="chase":
  return
 pursuer.clock+=dt
 if pursuer.state=="vault":
  _vault_tick(pursuer,pursuer_vault,dt)
  pursuer.animate(dt)
  return
 if pursuer.state=="stunned":
  pursuer.animate(dt)
  if pursuer.clock>2.2:
   pursuer.state="idle"
  return
 if enemy_sees(pursuer,true):
  pursuit_memory=9
  pursuer.last_seen=player.position if not player.hidden else school.hides[hidden_spot]["entry"]
  search_time=0
 else:
  pursuit_memory=maxf(0,pursuit_memory-dt)
 var destination: Vector3=pursuer.last_seen
 if pursuit_memory<=0:
  search_time+=dt
  # Busca física perto da última visão; não conhece a posição oculta do jogador.
  destination=pursuer.last_seen+Vector3(sin(search_time*.45)*2,0,cos(search_time*.45)*2)
 if player.hidden and seen_hiding and pursuer.position.distance_to(destination)<1.8:
  _grab()
  return
 if not player.hidden and pursuer.position.distance_to(player.position)<.83 and visible_between(pursuer.bone_point("Head"),player.bone_point("Chest")):
  _grab()
  return
 var direction: Vector3=(destination-pursuer.position).normalized()
 if not try_vault(pursuer,direction,true):
  _navigate(pursuer,destination,3.55 if pursuit_memory>0 else 1.25,dt)
 pursuer.animate(dt)

func _grab() -> void:
 if player.dead:
  return
 if knife:
  knife=false
  if player.hidden:
   _leave_hide()
  pursuer.state="stunned"
  pursuer.clock=0
  pursuer.play("guarda")
  if pursuer.held_knife:
   pursuer.held_knife.visible=true
  # Faca de Miguel permanece no tronco, distinta da arma na mão do cultista.
  var attachment = BoneAttachment3D.new()
  attachment.bone_name="Chest"
  pursuer.rig.add_child(attachment)
  var lodged: Node3D=pursuer._knife()
  lodged.rotation_degrees.x=90
  lodged.position.z=.15
  attachment.add_child(lodged)
  hud.say("A faca ficou presa nele. CORRA!",3)
  _impact(pursuer.bone_point("Chest"),true)
 else:
  if player.hidden:
   _leave_hide()
  hurt_player(100)

func _build_paths() -> void:
 path_grid=AStarGrid2D.new()
 path_grid.region=Rect2i(-21,-69,43,99)
 path_grid.cell_size=Vector2(.5,.5)
 path_grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 path_grid.update()
 var solids =school.find_children("*","StaticBody3D",true,false)
 for body in solids:
  if body==school.gate or (body.has_meta("door") and body.get_meta("door").opened):
   continue
  var cs = body.get_child(1) as CollisionShape3D
  if cs==null or not cs.shape is BoxShape3D:
   continue
  var skip = false
  for obstacle in school.obstacles:
   if obstacle["node"]==body:
    skip=true
  if skip:
   continue
  var local_size: Vector3=cs.shape.size
  var size: Vector3=body.global_basis.x.abs()*local_size.x+body.global_basis.y.abs()*local_size.y+body.global_basis.z.abs()*local_size.z
  var center: Vector3=body.global_position
  if center.y+size.y/2<.30 or center.y-size.y/2>1.7:
   continue
  for x in range(ceili((center.x-size.x/2-.27)*2),floori((center.x+size.x/2+.27)*2)+1):
   for z in range(ceili((center.z-size.z/2-.27)*2),floori((center.z+size.z/2+.27)*2)+1):
    var cell = Vector2i(x,z)
    if path_grid.is_in_boundsv(cell):
     path_grid.set_point_solid(cell,true)

func _navigate(actor: CharacterBody3D, target: Vector3, speed: float, dt: float) -> void:
 var next =target
 var direct =visible_between(actor.position+Vector3(0,.6,0),target+Vector3(0,.6,0))
 if path_grid!=null and not direct:
  var start =Vector2i(roundi(actor.position.x*2),roundi(actor.position.z*2))
  var end =Vector2i(roundi(target.x*2),roundi(target.z*2))
  if path_grid.is_in_boundsv(start) and path_grid.is_in_boundsv(end) and not path_grid.is_point_solid(end):
   # Cache por origem/destino de célula para não recalcular toda a rota a cada quadro.
   var key =str(actor.get_instance_id())
   var cached: Dictionary=paths.get(key,{})
   if cached.get("end",Vector2i(999,999))!=end or float(cached.get("until",0))<elapsed:
    cached={"end":end,"until":elapsed+.45,"path":path_grid.get_point_path(start,end)}
    paths[key]=cached
   var path: PackedVector2Array=cached["path"]
   for point in path:
    var p =Vector3(point.x,actor.position.y,point.y)
    if actor.position.distance_to(p)>.42:
     next=p
     break
 if actor.enemy and actor.state=="idle" and try_vault(actor,(next-actor.position).normalized(),true):
  return
 actor.move_toward(next,speed,dt)
 actor.play("correr" if speed>2.5 else "andaFrente",1.2 if speed>2.5 else 1.0)

func _snapshot(persist := true) -> void:
 var enemy_data: Array=[]
 for e in enemies:
  enemy_data.append({"position":[e.position.x,e.position.y,e.position.z],"dead":e.dead,"down":e.down,"health":e.health})
 var picked: Array=[]
 for item in school.pickups:
  picked.append(item["taken"])
 checkpoint={"version":2,"doors":school.doors.map(func(d):return d.opened),"checkpoint":checkpoint_index,"position":[player.position.x,player.position.y,player.position.z],"health":player.health,"food":food,"knife":knife,"enemies":enemy_data,"picked":picked}
 if persist:
  var file =FileAccess.open(_save_path(),FileAccess.WRITE)
  if file:
   file.store_string(JSON.stringify(checkpoint))

func load_checkpoint() -> bool:
 if not FileAccess.file_exists(_save_path()):
  hud.say("Ainda não há checkpoint salvo.",2)
  return false
 var saved=JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
 if not saved is Dictionary or saved.get("version",0)!=2:
  return false
 if not saved.get("position") is Array or saved["position"].size()!=3 or saved.get("enemies",[]).size()!=enemies.size() or saved.get("picked",[]).size()!=school.pickups.size():
  return false
 checkpoint=saved
 restore_checkpoint()
 return true

func restore_checkpoint() -> void:
 if checkpoint.is_empty():
  return
 if is_instance_valid(pursuer):
  pursuer.queue_free()
 pursuer=null
 hidden_spot=-1
 seen_hiding=false
 gate_open=false
 school.reset_exit()
 phase="investigate"
 intro_seen=true
 peek_door=null
 for i in school.doors.size():
  school.doors[i].set_open(checkpoint.get("doors",[])[i] if checkpoint.get("doors",[]).size()==school.doors.size() else false,true)
 checkpoint_index=int(checkpoint["checkpoint"])
 var p: Array=checkpoint["position"]
 player.position=Vector3(p[0],p[1],p[2])
 player.health=float(checkpoint["health"])
 food=int(checkpoint["food"])
 knife=bool(checkpoint["knife"])
 player.dead=false
 player.down=false
 player.hidden=false
 player.model.visible=true
 player.collision_layer=2
 player.collision_mask=3
 player.velocity=Vector3.ZERO
 player.state="idle"
 player.clock=0
 player.combo=0
 player.chain_until=0
 player.play("guarda")
 for area in player.hurt_areas:
  area.collision_layer=4
 _crouch(false)
 for i in enemies.size():
  var e =enemies[i]
  var d: Dictionary=checkpoint["enemies"][i]
  var at: Array=d["position"]
  e.position=Vector3(at[0],at[1],at[2])
  e.dead=false
  e.down=false
  e.health=float(d["health"])
  e.state="idle"
  e.clock=0
  e.aware=false
  e.attack_target=null
  e.strike_yaw_bias=0
  e.patrol_clock=0
  e.suspicion=0
  e.memory=0
  e.opening=0
  e.velocity=Vector3.ZERO
  e.collision_layer=2
  e.collision_mask=3
  for area in e.hurt_areas:
   area.collision_layer=4
  if d["dead"]:
   e.kill()
  elif d["down"]:
   e.make_down()
  else:
   e.play("guarda")
  e.face(e.position+Vector3.FORWARD)
 for i in school.pickups.size():
  school.pickups[i]["taken"]=bool(checkpoint["picked"][i])
  school.pickups[i]["node"].visible=not school.pickups[i]["taken"]
 locked=null
 protected_target=null
 action_target=null
 enemy_turn=null
 turn_cooldown=1
 buffered_attack=false
 paths.clear()
 for stain in blood:
  stain.queue_free()
 blood.clear()
 view.yaw=0 if checkpoint_index>0 else -PI/2
 view.pitch=-.16
 view.global_position=player.position+Vector3(0,1.22,0)
 view.camera.global_position=player.position+Vector3(0,1.35,0)-view.direction()*2.8
 player.face(player.position+view.movement(Vector2(0,-1)))
 hud.say("Checkpoint retomado.",2)

func _save_path() -> String:
 return "res://../work/prototipo-qa/checkpoint.json" if qa_mode else SAVE_PATH

func toggle_peek() -> void:
 if is_instance_valid(peek_door):
  peek_door=null
  return
 if player.state!="idle" or phase!="investigate":
  return
 for door in school.doors:
  if not door.opened and player.position.distance_to(door.global_position)<1.65:
   peek_door=door
   player.velocity=Vector3.ZERO
   var info=door.peek_anchor(player.position)
   var direction: Vector3=info["direction"]
   view.yaw=atan2(-direction.x,-direction.z)
   view.pitch=0
   return

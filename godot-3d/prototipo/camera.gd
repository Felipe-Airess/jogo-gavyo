extends Node3D
## Enquadramento em terceira pessoa, cenas dirigidas e olhos de Miguel na fuga/frestas.
const WORLD_MASK:=1
var hidden_near_camera: Dictionary={}
var yaw := 0.0
var pitch := -.12
var arm: SpringArm3D
var camera: Camera3D
var trauma := 0.0
var game: Node3D
var mode := "third_person"
var previous_mode := ""
## Valores iniciais para avaliar jogando; lado/distância ainda não são decisões finais.
@export var shoulder_side := 1.0
@export var shoulder_offset := .48
@export var follow_distance := 2.1

func setup(owner_game: Node3D) -> void:
 game=owner_game
 arm=SpringArm3D.new()
 arm.collision_mask=WORLD_MASK
 arm.spring_length=2.8
 var sphere=SphereShape3D.new()
 sphere.radius=.18
 arm.shape=sphere
 add_child(arm)
 camera=Camera3D.new()
 camera.fov=64
 camera.near=.035
 camera.current=true
 add_child(camera)
 camera.global_position=game.player.position+Vector3(0,1.7,3)

func look_mouse(relative: Vector2) -> void:
 if game.phase in ["intro","discovery"]:
  return
 if game.locked==null or game.phase=="chase":
  yaw-=relative.x*.0025
  pitch=clampf(pitch-relative.y*.0025,-1.05,.95)
 if is_instance_valid(game.peek_door):
  var data=game.peek_door.peek_anchor(game.player.position)
  var dir: Vector3=data["direction"]
  var base=atan2(-dir.x,-dir.z)
  yaw=base+clampf(angle_difference(base,yaw),-.45,.45)
 if game.hidden_spot>=0:
  var dir: Vector3=game.school.hides[game.hidden_spot]["normal"]
  var base=atan2(-dir.x,-dir.z)
  yaw=base+clampf(angle_difference(base,yaw),-.6,.6)

func direction() -> Vector3:
 return Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))

func update(dt: float) -> void:
 var focus: Vector3=game.player.position+Vector3(0,1.35,0)
 var at:=Vector3.ZERO
 var target:=Vector3.ZERO
 var fov:=64.0
 var first=false
 if game.phase=="intro":
  mode="intro"
  var t=game.intro_clock
  if t<2.6:
   at=game.player.position+Vector3(1.45,1.35,-1.5)
   target=game.player.position+Vector3(0,.9,0)
   fov=48
  elif t<5.2:
   var phone: Vector3=game.school.phone.global_position
   at=phone+Vector3(.025,.33,.24)
   target=phone
   fov=43
  else:
   at=game.player.position+Vector3(0,1.5,-.32)
   target=Vector3(-3,1.25,8.5)
   first=true
   fov=60
 elif game.phase=="discovery":
  mode="discovery"
  if game.discovery_clock<.9:
   at=game.player.position+Vector3(.7,2,3)
   target=Vector3(0,.9,-30)
   fov=58
  else:
   at=game.player.position+Vector3(0,1.6,.1)
   target=game.pursuer.bone_point("Head") if is_instance_valid(game.pursuer) else Vector3(3,1.8,-30)
   fov=52
   first=true
 elif game.hidden_spot>=0:
  mode="peek"
  var spot: Dictionary=game.school.hides[game.hidden_spot]
  at=spot["inside"]+Vector3(0,1.25,0)-spot["normal"]*.20
  target=at+direction()*3
  fov=52
  first=true
 elif is_instance_valid(game.peek_door):
  mode="peek"
  at=game.peek_door.peek_anchor(game.player.position)["position"]
  target=at+direction()*3
  fov=52
  first=true
 elif game.phase in ["chase","escaped"]:
  mode="first_person"
  at=game.player.position+Vector3(0,1.05 if game.player.crouched else 1.60,0)
  target=at+direction()*5
  fov=76
  first=true
 else:
  mode="third_person"
  if game.player.crouched:
   focus.y-=.3
  var shoulder=Basis(Vector3.UP,yaw)*Vector3(shoulder_side*shoulder_offset,.12,0)
  if is_instance_valid(game.locked):
   var toward: Vector3=game.locked.position-game.player.position
   yaw=lerp_angle(yaw,atan2(-toward.x,-toward.z),1-exp(-7*dt))
   pitch=lerpf(pitch,-.18,1-exp(-6*dt))
   focus+=toward*.20
  var ideal=focus-direction()*follow_distance+shoulder
  at=_collision_camera(focus,ideal)
  target=at+direction()*follow_distance
  global_position=focus
 var snap=previous_mode!=mode and mode in ["intro","peek"]
 if mode=="intro" and ((game.intro_clock>=2.6 and game.intro_clock<2.7) or (game.intro_clock>=5.2 and game.intro_clock<5.3)):
  snap=true
 camera.global_position=at if snap else camera.global_position.lerp(at,1-exp(-14*dt))
 # A suavização também precisa respeitar paredes, inclusive depois de girar uma esquina.
 if mode=="third_person":
  camera.global_position=_collision_camera(focus,camera.global_position)
 game.player.model.visible=not first and (mode!="third_person" or camera.global_position.distance_to(game.player.position+Vector3(0,1.2,0))>.55)
 if camera.global_position.distance_squared_to(target)>.0001:
  camera.look_at(target,Vector3.UP)
 camera.fov=lerpf(camera.fov,fov,1-exp(-9*dt))
 trauma=maxf(0,trauma-dt*3)
 camera.h_offset=sin(game.elapsed*37)*trauma*trauma*.025
 _update_occluders()
 previous_mode=mode

func _collision_camera(start: Vector3, desired: Vector3) -> Vector3:
 var query=PhysicsShapeQueryParameters3D.new()
 query.shape=arm.shape
 query.transform.origin=start
 query.motion=desired-start
 query.collision_mask=WORLD_MASK
 var result=get_world_3d().direct_space_state.cast_motion(query)
 var safe=result[0] if not result.is_empty() else 1.0
 var travel=desired-start
 if safe>=1.0:
  return desired
 # Margem em metros, independente da distância do ombro.
 return start+travel*maxf(0,safe-.025/maxf(travel.length(),.001))

func movement(raw: Vector2) -> Vector3:
 return Basis(Vector3.UP,yaw)*Vector3(raw.x,0,raw.y)

## Só altera a visibilidade. Corpos continuam na física e não colidem com a câmera.
func _update_occluders() -> void:
 for entry in hidden_near_camera.values():
  if is_instance_valid(entry["model"]): entry["model"].visible=entry["visible"]
 hidden_near_camera.clear()
 # Os closes dirigidos precisam mostrar o rosto escolhido pelo enquadramento.
 if mode in ["intro","sighting","discovery","gate_jump","ending","cozinha","duto","laboratorio"]: return
 for actor in game.find_children("*","CharacterBody3D",true,false):
  if actor==game.player or not "model" in actor or actor.model==null: continue
  var height=2.15 if actor.pursuer else 1.85
  var point=Vector3(actor.global_position.x,clampf(camera.global_position.y,actor.global_position.y+.1,actor.global_position.y+height),actor.global_position.z)
  if camera.global_position.distance_to(point)<.85:
   hidden_near_camera[actor.get_instance_id()]={"model":actor.model,"visible":actor.model.visible}
   actor.model.visible=false

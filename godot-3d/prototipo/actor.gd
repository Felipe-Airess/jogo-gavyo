extends CharacterBody3D
## Corpo físico, rig compartilhado e cultistas de geometria provisória.
const MODEL = preload("res://miguel_animado.glb")
const MOTIONS = preload("res://capitulo1/animacoes/prototipo_compativel.res")
var model: Node3D
var rig: Skeleton3D
var anim: AnimationPlayer
var motion: RefCounted
var world: Node3D
var enemy = false
var pursuer = false
var dead = false
var down = false
var aware = false
var health = 100.0
var state = "idle"
var clock = 0.0
var opening = 0.0
var suspicion = 0.0
var last_seen = Vector3.ZERO
var memory = 0.0
var home = Vector3.ZERO
var facing = Vector3.FORWARD
var crouched = false
var hidden = false
var hand_previous = Vector3.ZERO
var strike_bone = "RightHand"
var hit_once = false
var attack_target: CharacterBody3D
var combo = 0
var chain_until = 0.0
var procedural_parts: Array = []
var hurt_areas: Array[Area3D] = []
var held_knife: Node3D
var warning: Label3D
var dodge_direction = Vector3.ZERO
var stagger = 0.0
var strike_yaw_bias = 0.0
var patrol_clock = 0.0
var attack_landed = false
var base_facing = Vector3.FORWARD
var pose_previous = ""
var traversal: Dictionary = {}

func setup(game: Node3D, at: Vector3, is_enemy: bool, big := false) -> void:
 world = game
 enemy = is_enemy
 pursuer = big
 position = at
 home = at
 collision_layer = 2
 collision_mask = 3
 floor_snap_length = 0.22
 var shape = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.27 if not big else 0.35
 capsule.height = 1.64 if not big else 1.95
 shape.shape = capsule
 shape.position.y = capsule.height / 2.0
 add_child(shape)
 model = MODEL.instantiate()
 add_child(model)
 rig = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
 anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
 anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 for name in ["guarda", "andaFrente", "andaTras", "correr", "deitado"]:
  anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
 _materials(model)
 if enemy:
  _generic_body()
  if big:
   model.scale = Vector3.ONE * 1.18
  warning = Label3D.new()
  warning.position.y = 2.05 if not big else 2.35
  warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
  var font: Font=load("res://prototipo/interface.ttf")
  warning.font = font
  warning.font_size = 42
  warning.pixel_size = 0.008
  warning.no_depth_test = false
  add_child(warning)
  if big:
   held_knife = _knife()
   var attach = BoneAttachment3D.new()
   attach.bone_name = "RightHand"
   rig.add_child(attach)
   attach.add_child(held_knife)
 for data in [["Head", 0.21], ["Chest", 0.26], ["Spine", 0.24]]:
  var bone_attach = BoneAttachment3D.new()
  bone_attach.bone_name = data[0]
  rig.add_child(bone_attach)
  var area = Area3D.new()
  area.collision_layer = 4
  area.collision_mask = 0
  area.monitoring = false
  area.set_meta("actor", self)
  area.set_meta("zone", data[0])
  var cs = CollisionShape3D.new()
  var sphere = SphereShape3D.new()
  sphere.radius = data[1]
  cs.shape = sphere
  area.add_child(cs)
  bone_attach.add_child(area)
  hurt_areas.append(area)
 anim.add_animation_library("prototype",MOTIONS)
 motion=load("res://capitulo1/animacoes/controlador.gd").new()
 motion.setup(self)
 play("guarda")
 animate(0.0)

func _materials(node: Node) -> void:
 if node is MeshInstance3D:
  var mesh = node as MeshInstance3D
  for i in mesh.mesh.get_surface_count():
   var original = mesh.mesh.surface_get_material(i)
   if original is BaseMaterial3D:
    var mat = original.duplicate()
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    mat.roughness = 1.0
    mat.metallic_specular = 0.0
    mesh.set_surface_override_material(i, mat)
 for child in node.get_children():
  _materials(child)

func _generic_body() -> void:
 for mesh in model.find_children("*", "MeshInstance3D", true, false):
  mesh.visible = false
 var cloth = StandardMaterial3D.new()
 cloth.albedo_color = Color(0.22, 0.14, 0.14) if not pursuer else Color(0.10, 0.105, 0.09)
 cloth.roughness = 1.0
 var skin = StandardMaterial3D.new()
 skin.albedo_color = Color(0.66, 0.60, 0.46)
 var eye = StandardMaterial3D.new()
 eye.albedo_color = Color(0.04, 0.015, 0.012)
 var mouth = StandardMaterial3D.new()
 mouth.albedo_color = Color(0.24, 0.025, 0.025)
 for pair in [["Hips","Spine",.20], ["Spine","Chest",.24], ["Chest","Neck",.23],
   ["LeftUpperArm","LeftLowerArm",.09], ["LeftLowerArm","LeftHand",.075],
   ["RightUpperArm","RightLowerArm",.09], ["RightLowerArm","RightHand",.075],
   ["LeftUpperLeg","LeftLowerLeg",.12], ["LeftLowerLeg","LeftFoot",.09],
   ["RightUpperLeg","RightLowerLeg",.12], ["RightLowerLeg","RightFoot",.09]]:
  var mesh = MeshInstance3D.new()
  var cap = CapsuleMesh.new()
  cap.radius = pair[2]
  cap.height = 0.5
  cap.radial_segments = 6
  cap.rings = 1
  mesh.mesh = cap
  mesh.material_override = cloth
  model.add_child(mesh)
  procedural_parts.append([mesh, pair[0], pair[1], pair[2]])
 var head = BoneAttachment3D.new()
 head.bone_name = "Head"
 rig.add_child(head)
 var face = MeshInstance3D.new()
 var sphere = SphereMesh.new()
 sphere.radius = 0.16
 sphere.height = 0.37
 sphere.radial_segments = 8
 sphere.rings = 4
 face.mesh = sphere
 face.material_override = skin
 head.add_child(face)
 for x in [-0.065, 0.065]:
  var e = MeshInstance3D.new()
  var box = BoxMesh.new()
  box.size = Vector3(.045,.022,.02)
  e.mesh = box
  e.material_override = eye
  e.position = Vector3(x,.045,.145)
  head.add_child(e)
 var smile = MeshInstance3D.new()
 var line = BoxMesh.new()
 line.size = Vector3(.13,.018,.025)
 smile.mesh = line
 smile.material_override = mouth
 smile.position = Vector3(0,-.06,.15)
 head.add_child(smile)

func _knife() -> Node3D:
 var root = Node3D.new()
 var blade = MeshInstance3D.new()
 var mesh = BoxMesh.new()
 mesh.size = Vector3(.045,.32,.014)
 blade.mesh = mesh
 var mat = StandardMaterial3D.new()
 mat.albedo_color = Color(.65,.66,.60)
 mat.metallic = .8
 blade.material_override = mat
 blade.position.y = .17
 root.add_child(blade)
 return root

func play(clip: String, speed := 1.0) -> void:
 motion.request(clip,speed)

func start_action(clip: String, speed := 1.0) -> void:
 motion.request(clip,speed,true)

func _animation_event(event: String) -> void:
 motion.event(event)

func bone_point(bone: String) -> Vector3:
 return rig.to_global(rig.get_bone_global_pose(rig.find_bone(bone)).origin)

func face(point: Vector3, dt := 1.0) -> void:
 var toward = point - global_position
 toward.y = 0
 if toward.length_squared() < 0.0001:
  return
 facing = toward.normalized()
 var bias=strike_yaw_bias if state in ["attack","windup","strike"] else 0.0
 model.rotation.y = lerp_angle(model.rotation.y, atan2(facing.x, facing.z)+bias, minf(1.0, dt * 18.0))

func move_toward(point: Vector3, speed: float, dt: float) -> void:
 var dir = point - global_position
 dir.y = 0
 velocity.x = dir.normalized().x * speed if dir.length() > .15 else 0.0
 velocity.z = dir.normalized().z * speed if dir.length() > .15 else 0.0
 if speed > .01:
  face(point, dt)
 _slide(dt)

func _slide(dt: float) -> void:
 if not is_on_floor():
  velocity.y -= 18.0 * dt
 else:
  velocity.y = -0.1
 if motion!=null: motion.prepare_velocity()
 move_and_slide()

func animate(dt: float) -> void:
 motion.advance(dt)
 if state == "hang":
  _bend("LeftUpperArm",Vector3.ZERO,Vector3(-.9,0,-.4))
  _bend("LeftLowerArm",Vector3.ZERO,Vector3(-.4,0,0))
  _bend("LeftUpperLeg",Vector3.ZERO,Vector3(-.25,0,0))
  _bend("RightUpperLeg",Vector3.ZERO,Vector3(-.3,0,0))
 if state == "vault":
  # Pose procedural própria do blockout: recolhe as pernas e apoia os braços.
  # Não apresenta o idle de guarda como animação de parkour acabada.
  var tuck = sin(clampf(clock/.8,0,1)*PI)
  _bend("Chest",Vector3.ZERO,Vector3(.40*tuck,0,0))
  _bend("LeftUpperLeg",Vector3.ZERO,Vector3(-1.05*tuck,0,-.12*tuck))
  _bend("RightUpperLeg",Vector3.ZERO,Vector3(-.75*tuck,0,.12*tuck))
  _bend("LeftLowerLeg",Vector3.ZERO,Vector3(1.1*tuck,0,0))
  _bend("RightLowerLeg",Vector3.ZERO,Vector3(1.0*tuck,0,0))
 if state == "hurt":
  var weight = sin(minf(clock / .40, 1.0) * PI)
  _bend("Chest", Vector3.ZERO, Vector3(-.20 * weight,.20 * weight,0))
  _bend("Head", Vector3.ZERO, Vector3(-.22 * weight,0,.16 * weight))
 if enemy and not aware and not down:
  _bend("Head", Vector3.ZERO, Vector3(.06, .13 * sin(world.elapsed * .21), .05))
 rig.force_update_all_bone_transforms()
 for item in procedural_parts:
  var a: Vector3 = rig.get_bone_global_pose(rig.find_bone(item[1])).origin
  var b: Vector3 = rig.get_bone_global_pose(rig.find_bone(item[2])).origin
  var mesh = item[0] as MeshInstance3D
  mesh.transform.origin = (a+b)*.5
  mesh.scale = Vector3(1, maxf(.05, a.distance_to(b)) / .5, 1)
  var direction = (b-a).normalized()
  if direction.length() > .1:
   mesh.quaternion = Quaternion(Vector3.UP, direction)
 if warning:
  warning.visible = not dead and not down and (state == "windup" or opening > 0 or suspicion > .1)
  warning.text = "!" if state == "windup" else ("◇" if opening > 0 else "?")
  warning.modulate = Color(1,.70,.15) if state == "windup" else Color(.3,.9,1)

func _bend(bone: String, offset: Vector3, angle: Vector3) -> void:
 var id = rig.find_bone(bone)
 rig.set_bone_pose_position(id, rig.get_bone_pose_position(id) + offset)
 rig.set_bone_pose_rotation(id, rig.get_bone_pose_rotation(id) * Quaternion.from_euler(angle))

func make_down() -> void:
 down = true
 state = "down"
 clock = 0
 collision_layer = 0
 collision_mask = 1
 for area in hurt_areas:
  area.collision_layer = 0
 play("queda", 1.8)

func kill() -> void:
 health = 0.0
 dead = true
 down = true
 state = "dead"
 collision_layer = 0
 for area in hurt_areas:
  area.collision_layer = 0
 start_action("deitado")
 animate(0.0)

func fist_point() -> Vector3:
 var hand=bone_point(strike_bone)
 var forearm=bone_point("RightLowerArm" if strike_bone=="RightHand" else "LeftLowerArm")
 return hand+(hand-forearm).normalized()*.075

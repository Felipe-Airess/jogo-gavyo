extends Node3D
## Bancada de escala/câmera. Dimensões propostas, não a planta final da escola.
const ACTOR = preload("res://prototipo/actor.gd")
const CAMERA = preload("res://prototipo/camera.gd")
const SCHOOL = preload("res://prototipo/school.gd")
const DOOR = preload("res://prototipo/door.gd")
var player: CharacterBody3D
var view: Node3D
var school: Node3D
var locked: CharacterBody3D
var peek_door: Node3D
var hidden_spot := -1
var phase := "investigate"
var elapsed := 0.0
var lightweight := true
var door: Node3D
var label: Label
var audition := false
var clips: PackedStringArray
var clip_index := 0
var warm := false

func _ready() -> void:
 school=SCHOOL.new()
 add_child(school)
 school.game=self
 for data in [["floor",Color(.34,.35,.34)],["wall",Color(.66,.65,.55)],
   ["tile",Color(.20,.32,.29)],["metal",Color(.20,.23,.24)],["wood",Color(.30,.19,.11)]]:
  school.mats[data[0]]=school.material(data[1])
 # Pátio de entrada → corredor de 3 m → esquina. Sala lateral com vão de 1,4 m.
 school.box(Vector3(14,.2,28),Vector3(0,-.1,-4),"floor")
 school.wall(Vector3(.2,3.2,9.5),Vector3(-1.6,1.6,-4.75))
 school.wall(Vector3(.2,3.2,5.65),Vector3(1.6,1.6,-2.825))
 school.wall(Vector3(.2,3.2,5.65),Vector3(1.6,1.6,-9.875))
 school.wall(Vector3(.2,1.0,1.4),Vector3(1.6,2.7,-6.35))
 # Sala, atrás da porta: mesa e espaço livre para girar e agachar.
 school.wall(Vector3(4.6,3.2,.2),Vector3(4,1.6,-3.8))
 school.wall(Vector3(4.6,3.2,.2),Vector3(4,1.6,-9))
 school.wall(Vector3(.2,3.2,5.2),Vector3(6.3,1.6,-6.4))
 school.box(Vector3(4.6,.15,5.2),Vector3(4,3.275,-6.4),"wall")
 school.table(Vector3(4.8,0,-7.8),1.4,.7)
 school.box(Vector3(1,2,.5),Vector3(5.7,1,-4.3),"metal")
 # Esquina com passagem à esquerda, sem forçar câmera a atravessar o muro final.
 school.wall(Vector3(14.6,3.2,.2),Vector3(.3,1.6,-12.7))
 school.wall(Vector3(5.4,3.2,.2),Vector3(-4.3,1.6,-9.5))
 school.wall(Vector3(.2,3.2,3.2),Vector3(-6.9,1.6,-11.1))
 school.box(Vector3(3,.15,12),Vector3(0,3.275,-6),"wall")
 door=DOOR.new()
 add_child(door)
 door.setup(self,Vector3(1.6,0,-6.35),Vector3.RIGHT,"Sala de teste")
 school._environment()
 var light=OmniLight3D.new()
 light.position=Vector3(0,2.8,-6)
 light.omni_range=10
 light.light_color=Color(.70,.78,1)
 light.light_energy=1.2
 school.add_child(light)
 player=ACTOR.new()
 add_child(player)
 player.setup(self,Vector3(0,0,3),false)
 player.face(player.position+Vector3.FORWARD)
 for name in ["Running","prototype/run","Start_Walking","prototype/walk","Dodging","prototype/slip","Hook_Punch","prototype/hook"]:
  if player.anim.has_animation(name): clips.append(name)
 for name in player.anim.get_animation_list():
  if not clips.has(name): clips.append(name)
 # Esta prévia mostra os clipes que já existem; não os declara animações finais.
 view=CAMERA.new()
 add_child(view)
 view.setup(self)
 var canvas=CanvasLayer.new()
 add_child(canvas)
 label=Label.new()
 label.position=Vector2(18,14)
 label.add_theme_font_size_override("font_size",17)
 label.add_theme_color_override("font_shadow_color",Color.BLACK)
 label.add_theme_constant_override("shadow_outline_size",4)
 canvas.add_child(label)
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _build_paths() -> void:
 # A porta compartilhada avisa após abrir. Esta bancada não tem agentes/navegação.
 pass

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  match event.keycode:
   KEY_ESCAPE:
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
   KEY_TAB: view.shoulder_side*=-1
   KEY_R: player.position=Vector3(0,0,3)
   KEY_SPACE:
    if player.position.distance_to(door.position)<2.3:
     door.set_open(not door.opened)
   KEY_F2:
    audition=not audition
    if audition:
     _preview()
   KEY_BRACKETLEFT:
    clip_index=posmod(clip_index-1,clips.size())
    if audition: _preview()
   KEY_BRACKETRIGHT:
    clip_index=(clip_index+1)%clips.size()
    if audition: _preview()
   KEY_F3:
    warm=not warm
    var env: Environment=school.find_children("*","WorldEnvironment",false,false)[0].environment
    env.ambient_light_color=Color(.78,.69,.49) if warm else Color(.58,.62,.68)
 if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  view.look_mouse(event.screen_relative)

func _preview() -> void:
 player.anim.speed_scale=1
 player.anim.play(clips[clip_index],0)
 player.anim.seek(0,true)

func _physics_process(dt: float) -> void:
 elapsed+=dt
 if player.position.y < -3:
  player.position=Vector3(0,0,3)
  player.velocity=Vector3.ZERO
 if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
  return
 if audition:
  player.velocity=Vector3.ZERO
  if not player.anim.is_playing(): _preview()
 else:
  var raw=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
  var direction: Vector3=view.movement(raw.limit_length())
  var speed=3.8 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.8
  player.velocity.x=direction.x*speed
  player.velocity.z=direction.z*speed
  player._slide(dt)
  if raw.length()>.01:
   player.face(player.position+direction,dt)
  player.play("correr" if speed>3 and raw.length()>.01 else ("andaFrente" if raw.length()>.01 else "guarda"))
 player.animate(dt)

func _process(dt: float) -> void:
 view.update(dt)
 label.text="VALIDAÇÃO INICIAL · escala proposta, sem roteiro\nWASD / mouse · Shift correr · Espaço porta · Tab trocar ombro\nF2 prévia de clipes · [ / ] escolher · F3 comparar paleta · R voltar · Esc liberar mouse\n%s"%(("PRÉVIA: "+clips[clip_index]+" · sem validação de contato") if audition else "Movimentos provisórios do protótipo · corredor 3 m / porta 1,4 m")

extends CanvasLayer
## Controles de toque do capítulo 1 (celular). Não muda a lógica do jogo:
## traduz toques para as mesmas teclas/cliques que o teclado e o mouse geram.
## - metade esquerda: analógico (aparece onde o dedo toca); empurrar até a
##   borda corre;
## - metade direita: arrastar gira a câmera;
## - botões à direita: ação, agachar, gravar, luz,
##   fresta, comer; pausa no topo.
## Ativa sozinho em tela de toque; no PC, `-- --toque` força (mouse vira toque).

const STICK_RADIUS:=70.0
const RUN_THRESHOLD:=.92
const LOOK_SPEED:=1.7
var game: Node3D
var root: Control
var stick_finger:=-1
var stick_origin:=Vector2.ZERO
var stick_now:=Vector2.ZERO
var look_finger:=-1
var held_keys: Dictionary={}
var button_fingers: Dictionary={}
var buttons: Array[Dictionary]=[]
var escape_buttons: Array[Dictionary]=[]
var escape_controls:=false
var crouch_on:=false
var font: Font

static func wanted() -> bool:
 return DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios") or "--toque" in OS.get_cmdline_user_args()

func setup(owner_game: Node3D) -> void:
 game=owner_game
 layer=20
 Input.emulate_mouse_from_touch=false
 if "--toque" in OS.get_cmdline_user_args(): Input.emulate_touch_from_mouse=true
 font=load("res://prototipo/interface.ttf")
 root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.draw.connect(_draw_controls)
 add_child(root)
 get_viewport().size_changed.connect(_layout)
 _layout()

func _layout() -> void:
 var size: Vector2=get_viewport().get_visible_rect().size
 var r:=clampf(size.y*.085,30,52)
 var right:=size.x-r*1.5
 var bottom:=size.y-r*1.5
 buttons=[
  {"id":"acao","text":"AÇÃO","at":Vector2(right,bottom-r*2.3),"r":r*1.15,"key":KEY_SPACE},
  {"id":"agachar","text":"AGACHAR","at":Vector2(right-r*2.4,bottom-r*2.3),"r":r,"toggle":KEY_CTRL},
  {"id":"gravar","text":"GRAVAR","at":Vector2(right-r*4.6,bottom-r*.2),"r":r*.8,"key":KEY_V},
  {"id":"luz","text":"LUZ","at":Vector2(right,bottom-r*4.4),"r":r*.8,"key":KEY_L},
  {"id":"fresta","text":"FRESTA","at":Vector2(right-r*2.2,bottom-r*4.4),"r":r*.8,"key":KEY_F},
  {"id":"comer","text":"COMER","at":Vector2(right-r*4.4,bottom-r*4.4),"r":r*.8,"key":KEY_E},
  {"id":"pausa","text":"II","at":Vector2(size.x*.5,r*.9),"r":r*.6,"key":KEY_ESCAPE},
 ]
 if game.objectives!=null:
  buttons.append({"id":"celular","text":game.objectives.text("celular_toque"),"at":Vector2(size.x*.5,size.y-r*1.2),"r":r*.9,"key":KEY_N})
 var arrow_radius=clampf(size.y*.075,32,48)
 var center=Vector2(size.x*.5,size.y*.70)
 escape_buttons.clear()
 for data in [[KEY_UP,Vector2.UP],[KEY_RIGHT,Vector2.RIGHT],[KEY_DOWN,Vector2.DOWN],[KEY_LEFT,Vector2.LEFT]]:
  escape_buttons.append({"direction":data[0],"at":center+data[1]*arrow_radius*2.2,"r":arrow_radius})
 root.queue_redraw()

func _input(event: InputEvent) -> void:
 if is_instance_valid(game.gallery): return
 if event is InputEventScreenTouch and event.pressed and is_instance_valid(game.hud.gallery_button):
  var button=game.hud.gallery_button
  if button.visible and button.get_global_rect().has_point(event.position):
   game.open_gallery();get_viewport().set_input_as_handled();return
 if event is InputEventScreenTouch:
  _touch(event)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  _drag(event)
  get_viewport().set_input_as_handled()

func _touch(event: InputEventScreenTouch) -> void:
 if game.objectives!=null and game.objectives.modal:
  game.objectives.handle_touch(event); return
 if game.escape_blackout>0: return
 if game.escape.active and not game.paused:
  if event.pressed:
   for b in escape_buttons:
    if event.position.distance_to(b["at"])<=b["r"]:
     game.escape_direction(b["direction"]); break
  root.queue_redraw(); return
 if event.pressed and game.started and not game.paused and not game.player.dead:
  if game.phase=="intro": game.skip_intro(); return
  if game.phase=="cozinha": game.cozinha.apertar(); return
  if game.phase=="laboratorio": game.laboratorio.apertar(); return
 if event.pressed:
  # Tela inicial / fim: qualquer toque equivale a Enter.
  if not game.started or game.phase=="escaped":
   _tap_key(KEY_ENTER); return
  if game.player.dead or game.paused:
   _tap_key(KEY_R if game.player.dead else KEY_ESCAPE); return
  for b in buttons:
   if event.position.distance_to(b["at"])<=b["r"]*1.1:
    button_fingers[event.index]=b
    _press_button(b,true)
    root.queue_redraw(); return
  var half: float=get_viewport().get_visible_rect().size.x*.45
  if event.position.x<half and stick_finger<0:
   stick_finger=event.index; stick_origin=event.position; stick_now=event.position
  elif look_finger<0:
   look_finger=event.index
 else:
  if button_fingers.has(event.index):
   _press_button(button_fingers[event.index],false)
   button_fingers.erase(event.index)
  elif event.index==stick_finger:
   stick_finger=-1; _apply_stick(Vector2.ZERO)
  elif event.index==look_finger:
   look_finger=-1
 root.queue_redraw()

func _drag(event: InputEventScreenDrag) -> void:
 if game.objectives!=null and game.objectives.modal:
  game.objectives.handle_drag(event); return
 if game.escape.active or game.escape_blackout>0: return
 if event.index==stick_finger:
  stick_now=event.position
  var v: Vector2=(stick_now-stick_origin)/STICK_RADIUS
  if v.length()>1.0: stick_origin=stick_now-v.normalized()*STICK_RADIUS; v=v.normalized()
  _apply_stick(v)
  root.queue_redraw()
 elif event.index==look_finger:
  game.view.look_mouse(event.relative*LOOK_SPEED)

## Direção digital (o jogo lê WASD); borda do analógico também corre.
func _apply_stick(v: Vector2) -> void:
 var dead:=.28
 _hold(KEY_W,v.y<-dead)
 _hold(KEY_S,v.y>dead)
 _hold(KEY_A,v.x<-dead)
 _hold(KEY_D,v.x>dead)
 _hold(KEY_SHIFT,v.length()>RUN_THRESHOLD and not crouch_on)

func _press_button(b: Dictionary,pressed: bool) -> void:
 b["down"]=pressed
 if b.has("key"):
  if pressed: _tap_key(b["key"])
 elif b.has("mouse"):
  var click:=InputEventMouseButton.new()
  click.button_index=b["mouse"]; click.pressed=pressed
  click.position=b["at"]
  Input.parse_input_event(click)
 elif b.has("toggle") and pressed:
  crouch_on=not crouch_on
  _hold(b["toggle"],crouch_on)

func _hold(code: Key,on: bool) -> void:
 if bool(held_keys.get(code,false))==on: return
 held_keys[code]=on
 _send_key(code,on)

func _tap_key(code: Key) -> void:
 _send_key(code,true); _send_key(code,false)

func _send_key(code: Key,pressed: bool) -> void:
 var ev:=InputEventKey.new()
 ev.keycode=code; ev.physical_keycode=code; ev.pressed=pressed
 Input.parse_input_event(ev)

## Solta tudo ao pausar/perder foco: nada fica "preso" andando.
func release_all() -> void:
 for code in held_keys.keys(): _hold(code,false)
 crouch_on=false
 stick_finger=-1; look_finger=-1; button_fingers.clear()
 root.queue_redraw()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_APPLICATION_PAUSED: release_all()

func _process(_dt: float) -> void:
 if escape_controls!=game.escape.active:
  escape_controls=game.escape.active; root.queue_redraw()
 var playing: bool=game.started and not game.paused and not game.player.dead and game.phase in ["investigate","chase","sighting"]
 if root.visible!=playing:
  root.visible=playing
  if not playing: release_all()

func _draw_controls() -> void:
 if game.escape_blackout>0: return
 if game.escape.active:
  for b in escape_buttons:
   root.draw_circle(b["at"],b["r"],Color(.04,.04,.05,.88))
   root.draw_arc(b["at"],b["r"],0,TAU,40,Color(.95,.92,.8),2)
   game.hud.draw_escape_arrow(root,b["at"],b["direction"],b["r"]*.48,Color(1,.95,.8))
  return
 var ink:=Color(.92,.9,.8,.55)
 var fill:=Color(0,0,0,.28)
 if stick_finger>=0:
  root.draw_circle(stick_origin,STICK_RADIUS,fill)
  root.draw_arc(stick_origin,STICK_RADIUS,0,TAU,40,ink,2)
  root.draw_circle(stick_now,STICK_RADIUS*.38,Color(.92,.9,.8,.45))
 else:
  var size: Vector2=get_viewport().get_visible_rect().size
  var hint:=Vector2(size.x*.16,size.y*.72)
  root.draw_arc(hint,STICK_RADIUS,0,TAU,40,Color(.92,.9,.8,.18),2)
  root.draw_string(font,hint+Vector2(-40,6),"MOVER",HORIZONTAL_ALIGNMENT_CENTER,80,14,Color(.92,.9,.8,.3))
 for b in buttons:
  var active: bool=b.get("down",false) or (b["id"]=="agachar" and crouch_on) or (b["id"]=="luz" and game.phone_light)
  root.draw_circle(b["at"],b["r"],Color(.85,.2,.15,.45) if active else fill)
  root.draw_arc(b["at"],b["r"],0,TAU,40,ink,2)
  var fs:=int(clampf(b["r"]*.32,10,16))
  if b["id"]=="celular": root.draw_multiline_string(font,b["at"]+Vector2(-80,-2),b["text"],HORIZONTAL_ALIGNMENT_CENTER,160,12)
  else: root.draw_string(font,b["at"]+Vector2(-b["r"],fs*.35),b["text"],HORIZONTAL_ALIGNMENT_CENTER,b["r"]*2,fs,ink)

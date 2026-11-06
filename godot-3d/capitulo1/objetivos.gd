extends Node
## Itens do bloqueio cinza, registros e estado de checkpoint. Não altera ossos.
const TEXT_PATH="res://capitulo1/textos/objetivos.json"
const PLACES={
 "chave":[Vector2(83,38),0], "finalizador":[Vector2(10,7),0],
 "nota_1":[Vector2(98,31),0], "nota_2":[Vector2(49,36),0],
 "nota_3":[Vector2(86,11),0], "nota_4":[Vector2(73,51),0],
 "pista_1":[Vector2(72,9),0], "pista_2":[Vector2(68,10),0]}
var game: Node3D
var texts: Dictionary={}
var props: Dictionary={}
var collected: Array[String]=[]
var defeated: Array[int]=[]
var unlocked:=false
## Mensagens dos amigos no celular (textos de Felipe; [PROVISÓRIO] até lá).
var mensagens: Array[String]=[]
const MENSAGENS:={"bolsa":["msg_bola_1","msg_felipe_1","msg_bola_2"],"ritual":["msg_felipe_2"],"video":["msg_bola_3"]}
var spent:=false
var bag_door: Node3D
var modal:=false
var reading:=false
var was_paused:=false
var layer: CanvasLayer
var panel: Panel
var column: VBoxContainer
var scroll: ScrollContainer
var summary: Label
var close_button: Button
var ui_buttons: Array[Button]=[]
var screen_id:=""

func setup(owner_game: Node3D) -> void:
 game=owner_game
 var data=JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))
 assert(data is Array,"objetivos.json deve conter uma lista")
 for entry in data: texts[entry["id"]]=entry
 for door in game.school.doors:
  if door.title=="3 Informática": bag_door=door
 assert(bag_door!=null,"Porta de acesso à bolsa ausente")
 bag_door.locked=true
 for id in PLACES:
  var spec=PLACES[id]
  var node=MeshInstance3D.new(); var mesh=BoxMesh.new()
  mesh.size=Vector3(.17,.035,.07) if id in ["chave","finalizador"] else Vector3(.28,.012,.22)
  node.mesh=mesh
  var material=StandardMaterial3D.new(); material.albedo_color=Color(.52,.52,.48)
  if id=="finalizador":
   material.emission_enabled=true; material.emission=Color(.2,.2,.17); material.emission_energy_multiplier=.15
  node.material_override=material
  node.position=game.school.cel(spec[0].x,spec[0].y,spec[1]*game.school.LEVEL+.035)
  node.name=id; game.school.add_child(node); props[id]=node
 layer=CanvasLayer.new(); layer.layer=60; add_child(layer)
 panel=Panel.new(); panel.visible=false; layer.add_child(panel)
 var style=StyleBoxFlat.new(); style.bg_color=Color(.035,.04,.05,1)
 style.content_margin_left=20; style.content_margin_right=20; style.content_margin_top=16; style.content_margin_bottom=16
 panel.add_theme_stylebox_override("panel",style)
 var theme=Theme.new(); theme.default_font=load("res://prototipo/interface.ttf"); theme.default_font_size=20
 panel.theme=theme
 summary=Label.new(); summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; panel.add_child(summary)
 scroll=ScrollContainer.new(); panel.add_child(scroll)
 column=VBoxContainer.new(); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation",14); scroll.add_child(column)
 close_button=Button.new(); close_button.text=text("fechar"); close_button.custom_minimum_size.y=56
 close_button.pressed.connect(close_screen); panel.add_child(close_button)
 get_viewport().size_changed.connect(layout)
 layout()

func text(id: String) -> String: return String(texts[id]["texto"])
func title(id: String) -> String: return String(texts[id]["titulo"])
func has_key() -> bool: return "chave" in collected
func count(prefix: String) -> int:
 var amount=0
 for id in collected:
  if id.begins_with(prefix+"_"): amount+=1
 return amount
func position_of(id: String) -> Vector3: return props[id].global_position
func can_collect(id: String) -> bool:
 return props.has(id) and id not in collected and game._near_looking(position_of(id),1.55) and game.visible_between(game.player.position+Vector3.UP*.9,position_of(id)+Vector3.UP*.03)
func nearby() -> String:
 for id in props:
  if can_collect(id): return id
 return ""
func prompt() -> String:
 var id=nearby()
 if id.is_empty(): return ""
 return text("ler" if id.begins_with("nota_") or id.begins_with("pista_") else "pegar")+title(id)
func interact() -> bool:
 var id=nearby()
 if id.is_empty(): return false
 collect(id); return true
## Coleta dentro de uma cena (sem alcance/olhar): a chave da cozinha.
func pegar_na_cena(id: String) -> void:
 if id in collected or not props.has(id): return
 collected.append(id); props[id].visible=false
 game.hud.say(text(id),4)

func collect(id: String) -> bool:
 # A ação exige alcance e olhar reais, inclusive quando chamada por teste.
 if not can_collect(id): return false
 collected.append(id); props[id].visible=false
 if id=="chave":
  game._snapshot(); game.hud.say(text(id),4)
 elif id=="finalizador":
  game.finisher_item_available=true; game.hud.say(text(id),4)
 else: open_screen(id)
 return true
func unlock(door: Node3D) -> bool:
 if door!=bag_door or not door.locked: return true
 if not has_key(): game.hud.say(text("porta_trancada"),4); return false
 door.locked=false; unlocked=true
 return true
func finish(actor: CharacterBody3D) -> bool:
 if not game.finisher_item_available or actor.pursuer or actor.dead: return false
 if actor not in game.enemies: return false
 spent=true; game.finisher_item_available=false
 var index=game.enemies.find(actor)
 if index not in defeated: defeated.append(index)
 actor.health=0; actor.dead=true; actor.down=true; actor.aware=false; actor.state="dead"
 actor.velocity=Vector3.ZERO; actor.collision_layer=0
 for area in actor.hurt_areas: area.collision_layer=0
 actor.start_action("novo/Death01")
 game.sound.emit_at("agarrao",actor.position,-6)
 game.hud.say(text("finalizado"),3)
 return true
## Chegam as mensagens de um momento da história (uma vez cada).
func receber(momento: String) -> void:
 var novas: Array[String]=[]
 for id in MENSAGENS.get(momento,[]):
  if id not in mensagens: mensagens.append(id); novas.append(id)
 if novas.is_empty(): return
 game.sound.ui("seta")
 var aviso: String=text("msg_aviso")%novas.size() if novas.size()>1 else title(novas[0])+": "+text(novas[0])
 game.hud.say("CELULAR · "+aviso,5)

func save_state() -> Dictionary:
 return {"collected":collected.duplicate(),"unlocked":unlocked,"spent":spent,"defeated":defeated.duplicate(),"mensagens":mensagens.duplicate()}
func restore_state(state: Dictionary) -> void:
 close_screen()
 collected.assign(state.get("collected",[])); defeated.assign(state.get("defeated",[]))
 mensagens.assign(state.get("mensagens",[]))
 unlocked=bool(state.get("unlocked",false)); spent=bool(state.get("spent",false))
 bag_door.locked=not unlocked
 if bag_door.locked: bag_door.set_open(false,true)
 game.finisher_item_available="finalizador" in collected and not spent
 for id in props: props[id].visible=id not in collected
 for index in defeated:
  if index<0 or index>=game.enemies.size(): continue
  var actor=game.enemies[index]
  actor.health=0; actor.dead=true; actor.down=true; actor.state="dead"; actor.collision_layer=0
  for area in actor.hurt_areas: area.collision_layer=0
  actor.start_action("novo/Death01")

func layout() -> void:
 var screen=get_viewport().get_visible_rect().size
 panel.size=Vector2(minf(900,screen.x*.94),screen.y*.88)
 panel.position=(screen-panel.size)*.5
 summary.position=Vector2(20,16); summary.size=Vector2(panel.size.x-40,58)
 var top=80 if summary.visible else 16
 scroll.position=Vector2(20,top); scroll.size=Vector2(panel.size.x-40,panel.size.y-top-88)
 close_button.position=Vector2(20,panel.size.y-72); close_button.size=Vector2(panel.size.x-40,56)
func label(value: String) -> void:
 var node=Label.new(); node.text=value; node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 node.size_flags_horizontal=Control.SIZE_EXPAND_FILL; column.add_child(node)
func button(value: String,action: Callable) -> void:
 var node=Button.new(); node.text=value; node.custom_minimum_size.y=56
 node.pressed.connect(action); column.add_child(node); ui_buttons.append(node)
func open_phone() -> void:
 if not game.bag_found: game.hud.say(text("sem_celular"),3); return
 open_screen("")
func open_screen(id: String) -> void:
 if not game.started or game.player.dead or game.escape.active or game.escape_blackout>0: return
 if game.phase not in ["investigate","chase"]: return
 if reading: game.paused=was_paused
 if not modal: was_paused=game.paused
 modal=true; reading=not id.is_empty(); screen_id=id
 if reading: game.paused=true
 game.player.velocity=Vector3.ZERO
 if game.touch!=null: game.touch.release_all()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for child in column.get_children(): column.remove_child(child); child.queue_free()
 ui_buttons.clear()
 if reading:
  label(title(id)); label(text(id))
 else:
  label(title("celular"))
  label(text("mensagens")+" (%d)"%mensagens.size())
  for i in range(mensagens.size()-1,-1,-1):
   label("· "+title(mensagens[i])+": "+text(mensagens[i]))
  for prefix in ["nota","pista"]:
   label(text("notas" if prefix=="nota" else "pistas")+" %d/%d"%[count(prefix),4 if prefix=="nota" else 2])
   for entry in collected:
    if entry.begins_with(prefix+"_"): button(title(entry),open_screen.bind(entry))
   if count(prefix)==0: label(text("vazio"))
 summary.visible=not reading
 summary.text=text("notas")+" %d/4"%count("nota")+" · "+text("pistas")+" %d/2"%count("pista")
 ui_buttons.append(close_button)
 panel.visible=true; scroll.scroll_vertical=0; layout()
func close_screen() -> void:
 if not modal: return
 if reading: game.paused=was_paused
 modal=false; reading=false; screen_id=""; panel.visible=false
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.paused or game.touch!=null or game.qa_mode else Input.MOUSE_MODE_CAPTURED
func handle_key(event: InputEvent) -> bool:
 if modal:
  if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE,KEY_SPACE,KEY_N]: close_screen()
  return true
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_N:
  if game.started and not game.paused and not game.player.dead and not game.escape.active: open_phone()
  return true
 return false
func handle_touch(event: InputEventScreenTouch) -> void:
 if not modal or not event.pressed: return
 for node in ui_buttons:
  if node!=close_button and not scroll.get_global_rect().has_point(event.position): continue
  if node.is_visible_in_tree() and node.get_global_rect().has_point(event.position):
   node.pressed.emit(); return

func handle_drag(event: InputEventScreenDrag) -> void:
 if modal: scroll.scroll_vertical-=roundi(event.relative.y)

extends Node
signal closed
const MODELS=preload("res://capitulo1/modelos_definitivos.gd")
const CLIPS=["Idle","Walk","Sprint","Crouch_Fwd","Ascending_Stairs","Descending_Stairs","Agarrar","Segurado","Death01"]
var selected:=0
var model: Node3D
var rig: Skeleton3D
var anim: AnimationPlayer
var tree: AnimationTree
var machine: AnimationNodeStateMachine
var playback: AnimationNodeStateMachinePlayback
var viewport: SubViewport
var display: TextureRect
var container: SubViewportContainer
var stage: Node3D
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var lamp: SpotLight3D
var caption: Label
var choices: OptionButton
var yaw:=0.0
var pitch:=.08
var distance:=4.0
var selected_clip:="Idle"
var generation:=0
var night:=false
var retro:=false
var embedded:=false
var drag_touch:=-1
var previous_mouse:=Input.MOUSE_MODE_VISIBLE
func _ready() -> void:
 if not OS.is_debug_build():
  if not embedded: get_tree().change_scene_to_file("res://capitulo1/main.tscn")
  queue_free(); return
 previous_mouse=Input.mouse_mode; Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var layer=CanvasLayer.new();layer.layer=90;add_child(layer)
 var root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);layer.add_child(root)
 container=SubViewportContainer.new();container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var retro_material=ShaderMaterial.new();retro_material.shader=load("res://capitulo1/retro.gdshader")
 container.stretch=true;container.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;container.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(container)
 viewport=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
 display=TextureRect.new();display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);display.texture=viewport.get_texture()
 display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;display.stretch_mode=TextureRect.STRETCH_SCALE;display.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 display.material=retro_material;display.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(display)
 stage=preload("res://capitulo1/galeria_mundo.gd").new();viewport.add_child(stage)
 var world_environment=WorldEnvironment.new();environment=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(.22,.23,.24)
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.7
 world_environment.environment=environment;stage.add_child(world_environment)
 sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-25,0);sun.light_energy=.8;sun.shadow_enabled=true;stage.add_child(sun)
 var floor_mesh=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(200,200);floor_mesh.mesh=plane
 var material=StandardMaterial3D.new();material.albedo_color=Color(.4,.4,.4);material.roughness=1;floor_mesh.material_override=material;stage.add_child(floor_mesh)
 camera=Camera3D.new();camera.current=true;camera.near=.05;camera.fov=40;stage.add_child(camera)
 lamp=SpotLight3D.new();lamp.spot_range=15;lamp.spot_angle=35;lamp.light_energy=3;lamp.position=Vector3(.15,-.08,0);camera.add_child(lamp)
 var panel=VBoxContainer.new();panel.position=Vector2(12,12);panel.add_theme_constant_override("separation",8);root.add_child(panel)
 caption=Label.new();caption.add_theme_font_size_override("font_size",18);panel.add_child(caption)
 var navigation=HBoxContainer.new();panel.add_child(navigation)
 _button(navigation,"◀ Anterior",func(): show_model(selected-1))
 _button(navigation,"Próximo ▶",func(): show_model(selected+1))
 _button(navigation,"Noite / lanterna",func(): set_night(not night))
 _button(navigation,"Filtro retrô",func(): set_retro(not retro))
 _button(navigation,"Voltar · F10",leave)
 choices=OptionButton.new();choices.custom_minimum_size.y=48;panel.add_child(choices)
 choices.item_selected.connect(func(index): play_clip(choices.get_item_text(index)))
 var help=Label.new();help.text="Setas: personagem · 1–9: clipes · mouse/toque: orbitar · roda/pinça: distância";panel.add_child(help)
 var buttons=HBoxContainer.new();buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);buttons.position.y=-64;root.add_child(buttons)
 for i in CLIPS.size():
  var index=i
  _button(buttons,str(i+1),func(): play_clip(CLIPS[index]))
 show_model(0);set_night(false);set_retro(false)
func _button(parent: Node,text: String,callback: Callable) -> Button:
 var button=Button.new();button.text=text;button.custom_minimum_size=Vector2(64,48);button.pressed.connect(callback);button.gui_input.connect(_touch_button_input.bind(button));parent.add_child(button);return button
func _touch_button_input(event: InputEvent,button: Button) -> void:
 if event is InputEventScreenTouch and event.pressed:
  button.pressed.emit();button.accept_event()
func show_model(index: int) -> void:
 selected=posmod(index,MODELS.list().size())
 if is_instance_valid(model):
  stage.remove_child(model);model.queue_free()
 var info=MODELS.list()[selected]
 model=MODELS.instantiate(info.id);stage.add_child(model)
 rig=MODELS.skeleton(model);anim=model.get_node("AnimationPlayer")
 anim.add_animation_library("novo",MODELS.NEW)
 anim.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 tree=AnimationTree.new();model.add_child(tree);tree.anim_player=tree.get_path_to(anim);tree.root_node=tree.get_path_to(model)
 tree.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 machine=AnimationNodeStateMachine.new();tree.tree_root=machine;tree.active=true
 playback=tree.get("parameters/playback")
 generation=0;choices.clear()
 for name in MODELS.NEW.get_animation_list(): choices.add_item(String(name))
 distance=float(info.altura)*1.8
 play_clip("Idle")
func play_clip(clip: String) -> void:
 if not anim.has_animation("novo/"+clip): return
 var key="Clip"+str(generation);generation+=1
 var node=AnimationNodeAnimation.new();node.animation="novo/"+clip;machine.add_node(key,node)
 if generation>1:
  var link=AnimationNodeStateMachineTransition.new();link.xfade_time=.22;machine.add_transition(playback.get_current_node(),key,link);playback.travel(key)
 else:
  playback.start(key);tree.advance(0)
 selected_clip=clip
 for i in choices.item_count:
  if choices.get_item_text(i)==clip: choices.select(i);break
func set_night(value: bool) -> void:
 night=value;sun.visible=not value;lamp.visible=value
 environment.ambient_light_energy=.045 if value else .7
 environment.background_color=Color(.005,.006,.01) if value else Color(.22,.23,.24)
func set_retro(value: bool) -> void:
 retro=value;container.stretch_shrink=4 if value else 1
 display.material.set_shader_parameter("intensity",1.0 if value else 0.0)
func _process(dt: float) -> void:
 if not is_instance_valid(tree): return
 tree.advance(dt)
 var low_size=Vector2(viewport.size)
 if display.material.get_shader_parameter("low_size")!=low_size: display.material.set_shader_parameter("low_size",low_size)
 var info=MODELS.list()[selected]
 var target=Vector3(0,float(info.altura)*.54,0)
 camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
 camera.look_at(target)
 caption.text="%s · %.2f m · %d ossos\n%s · %.2f s · próprias: nenhuma no FBX"%[info.nome,info.altura,int(info.ossos_fonte),selected_clip,playback.get_current_play_position()]
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode in [KEY_F10,KEY_ESCAPE]: leave()
  elif event.keycode==KEY_LEFT: show_model(selected-1)
  elif event.keycode==KEY_RIGHT: show_model(selected+1)
  elif event.keycode>=KEY_1 and event.keycode<=KEY_9: play_clip(CLIPS[event.keycode-KEY_1])
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  orbit(event.relative)
 elif event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP: distance=maxf(1,distance-.2)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: distance=minf(10,distance+.2)
 elif event is InputEventScreenTouch:
  if event.pressed and drag_touch<0: drag_touch=event.index
  elif not event.pressed and event.index==drag_touch: drag_touch=-1
 elif event is InputEventScreenDrag and event.index==drag_touch: orbit(event.relative)
 elif event is InputEventMagnifyGesture: distance=clampf(distance/event.factor,1,10)
func orbit(delta: Vector2) -> void:
 yaw-=delta.x*.008;pitch=clampf(pitch+delta.y*.008,-.4,1.1)
func leave() -> void:
 Input.mouse_mode=previous_mouse
 if embedded: closed.emit()
 else: get_tree().change_scene_to_file("res://capitulo1/main.tscn")

extends Node
## Ponte local, apenas com --qa-inspect. Captura só o viewport do jogo.
## Comandos têm lista fechada; não executa código nem comandos de sistema.
const DIR := "res://../work/prototipo-qa"
var game: Node3D
var elapsed := 0.0
var active := false
var pending: Array = []
var remaining := 0.0
var last_id := ""
var held: Array = []
var command_elapsed := 0.0
var capture_viewport: SubViewport
var capture_camera: Camera3D
var capture_hud: CanvasLayer
var capture_status := "starting"

func setup(owner_game: Node3D) -> void:
 game=owner_game
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
 for filename in ["command.json","state.json","frame.png"]:
  var path=ProjectSettings.globalize_path(DIR.path_join(filename))
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
 if DisplayServer.get_name()!="headless":
  capture_viewport=SubViewport.new()
  capture_viewport.size=Vector2i(960,540)
  capture_viewport.msaa_3d=Viewport.MSAA_2X
  capture_viewport.world_3d=game.get_world_3d()
  capture_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
  add_child(capture_viewport)
  capture_camera=Camera3D.new()
  capture_camera.force_update_transform()
  capture_camera.fov=game.view.camera.fov
  capture_camera.near=game.view.camera.near
  capture_viewport.add_child(capture_camera)
  capture_camera.current=true
  capture_hud=load("res://prototipo/hud.gd").new()
  capture_viewport.add_child(capture_hud)
  capture_hud.setup(game)
 game.hud.say("Modo de teste visual ativo. Captura somente o jogo.",4)

func _process(dt: float) -> void:
 remaining=maxf(0,remaining-dt)
 if remaining<=0:
  _release_all()
  if not pending.is_empty():
   _step(pending.pop_front())
 command_elapsed+=dt
 if command_elapsed>=.25:
  command_elapsed=0
  _command()
 elapsed+=dt
 if elapsed>=1.5 and not active:
  elapsed=0
  _capture()

func _command() -> void:
 var path=DIR.path_join("command.json")
 if not FileAccess.file_exists(path):
  return
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary or not data.get("id") is String or data["id"]==last_id:
  return
 if not data.get("steps") is Array or data["steps"].size()>60:
  return
 last_id=data["id"]
 _release_all()
 pending=data["steps"].duplicate()
 remaining=0

func _step(step) -> void:
 if not step is Dictionary:
  return
 var operation=step.get("op","")
 match operation:
  "begin":
   game.begin()
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  "pause":
   game.paused=true
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  "resume":
   game.paused=false
  "look":
   game.view.look_mouse(Vector2(clampf(float(step.get("x",0)),-2000,2000),clampf(float(step.get("y",0)),-600,600)))
  "keys":
   var names=step.get("keys",[])
   if names is Array:
    for key in names:
     if key in ["W","A","S","D","Shift","Ctrl","Space","E","F","Q","R","F1","Escape","Enter"]:
      var code=OS.find_keycode_from_string(key)
      var event=InputEventKey.new()
      event.keycode=code
      event.physical_keycode=code
      event.pressed=true
      Input.parse_input_event(event)
      held.append(code)
  "mouse":
   var buttons={"left":MOUSE_BUTTON_LEFT,"right":MOUSE_BUTTON_RIGHT,"middle":MOUSE_BUTTON_MIDDLE,"up":MOUSE_BUTTON_WHEEL_UP,"down":MOUSE_BUTTON_WHEEL_DOWN}
   if buttons.has(step.get("button","")):
    var event=InputEventMouseButton.new()
    event.button_index=buttons[step["button"]]
    event.pressed=true
    game._unhandled_input(event)
  "intro_skip":
   if game.phase=="intro":
    game.end_intro()
   elif game.phase=="discovery":
    game.end_discovery()
  "wait":
   pass
  "checkpoint":
   game.restore_checkpoint()
 remaining=clampf(float(step.get("seconds",.10)),.05,5.0)

func _release_all() -> void:
 for code in held:
  var event=InputEventKey.new()
  event.keycode=code
  event.physical_keycode=code
  event.pressed=false
  Input.parse_input_event(event)
 held.clear()

func _capture() -> void:
 active=true
 var actors: Array=[]
 for actor in game.enemies:
  actors.append({"position":_vector(actor.position),"state":actor.state,"clock":actor.clock,"fist":_vector(actor.fist_point()),"health":actor.health,"aware":actor.aware,"opening":actor.opening,"dead":actor.dead})
 var data={"capture":capture_status,"revision":2,"camera_mode":game.view.mode,"intro_clock":game.intro_clock,"caption":game.hud.message.text,"stats":game.combat_stats,"doors":game.school.doors.map(func(d):return d.opened),"process_id":OS.get_process_id(),"timestamp":Time.get_unix_time_from_system(),"id":last_id,"pending":pending.size(),"seconds_remaining":remaining,"phase":game.phase,"paused":game.paused,"player":{"position":_vector(game.player.position),"state":game.player.state,"health":game.player.health,"food":game.food,"knife":game.knife,"hidden":game.player.hidden},"enemies":actors,"fps":Engine.get_frames_per_second(),"context":game.context_text()}
 var file=FileAccess.open(DIR.path_join("state.json.tmp"),FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(data,"  "))
  file.close()
  DirAccess.rename_absolute(ProjectSettings.globalize_path(DIR.path_join("state.json.tmp")),ProjectSettings.globalize_path(DIR.path_join("state.json")))
 if capture_viewport!=null and not FileAccess.file_exists(DIR.path_join("sem-captura")):
  capture_hud.current_message=game.hud.current_message
  capture_hud.remaining=game.hud.remaining
  capture_hud.update(0)
  await get_tree().process_frame
  capture_camera.global_transform=game.view.camera.global_transform
  capture_camera.force_update_transform()
  capture_camera.fov=game.view.camera.fov
  capture_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
  # Render offscreen próprio: não depende de a janela estar descoberta.
  # Sem await frame_post_draw, para não bloquear a ponte em janelas oclusas.
  RenderingServer.force_draw(false)
  var image=capture_viewport.get_texture().get_image()
  if image and not image.is_empty():
   var result=image.save_png(DIR.path_join("frame.tmp.png"))
   if result==OK:
    DirAccess.rename_absolute(ProjectSettings.globalize_path(DIR.path_join("frame.tmp.png")),ProjectSettings.globalize_path(DIR.path_join("frame.png")))
    capture_status="ok"
   else:
    capture_status="save_error_"+str(result)
  else:
   capture_status="empty_frame"
 else:
  capture_status="disabled" if FileAccess.file_exists(DIR.path_join("sem-captura")) else "headless"

 active=false

func _vector(value: Vector3) -> Array:
 return [value.x,value.y,value.z]

func _exit_tree() -> void:
 _release_all()

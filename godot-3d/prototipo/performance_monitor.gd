extends Node
## Telemetria leve: não captura nem força renderização.
var game: Node3D
var samples: Array[float] = []
var window_time:=0.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 set_process(DisplayServer.get_name()!="headless")

var overlay: Label
var overlay_time:=0.0
var overlay_frames:=0

## F8: medidor na tela (FPS, ms, chamadas de desenho, triângulos) para Felipe
## dizer onde trava. Só leitura de monitores; não altera nada do jogo.
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
  if overlay==null:
   var layer=CanvasLayer.new();layer.layer=100;add_child(layer)
   overlay=Label.new();overlay.position=Vector2(8,8)
   overlay.add_theme_color_override("font_color",Color(1,1,.4))
   overlay.add_theme_color_override("font_outline_color",Color.BLACK)
   overlay.add_theme_constant_override("outline_size",4)
   layer.add_child(overlay)
  else: overlay.visible=not overlay.visible

func _update_overlay(dt: float) -> void:
 overlay_time+=dt;overlay_frames+=1
 if overlay_time<.5: return
 var view=game.get("low_view")
 var size=view.size if view else get_viewport().size
 overlay.text="FPS %d  (%.1f ms)\ndesenhos %d · objetos %d · triângulos %dk\nscript %.1f ms · física %.1f ms\nresolução 3D %dx%d · filtro %s"%[
  overlay_frames/overlay_time,overlay_time*1000.0/overlay_frames,
  Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
  Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
  Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)/1000,
  Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
  size.x,size.y,"ligado" if game.get("film_enabled") else "desligado"]
 overlay_time=0;overlay_frames=0

func _process(dt: float) -> void:
 if overlay and overlay.visible: _update_overlay(dt)
 samples.append(dt*1000.0)
 window_time+=dt
 if window_time<2.0:
  return
 var ordered=samples.duplicate()
 ordered.sort()
 var data={"timestamp":Time.get_unix_time_from_system(),"pid":OS.get_process_id(),"qa":game.qa_mode,"lightweight":game.lightweight,"phase":game.phase,"paused":game.paused,"fps_average":float(samples.size())/window_time,"frame_ms_p95":ordered[mini(ordered.size()-1,int(ordered.size()*.95))],"frame_ms_max":ordered[-1],"cpu_process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"window":[get_viewport().size.x,get_viewport().size.y]}
 var path="res://../work/prototipo-desempenho.json"
 var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(data,"  "))
  file.close()
  DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
 if not game.paused and game.phase in ["investigate","chase"]:
  var active_file=FileAccess.open("res://../work/prototipo-desempenho-ativo.json",FileAccess.WRITE)
  if active_file:
   active_file.store_string(JSON.stringify(data,"  "))
 samples.clear()
 window_time=0

extends Node
## Telemetria leve: não captura nem força renderização.
var game: Node3D
var samples: Array[float] = []
var window_time:=0.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 set_process(DisplayServer.get_name()!="headless")

func _process(dt: float) -> void:
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

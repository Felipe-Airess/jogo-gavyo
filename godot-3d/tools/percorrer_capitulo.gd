extends SceneTree
var game: Node3D
var samples: Array[float]=[]
var collecting:=false
func _initialize() -> void: call_deferred("run")
func _process(dt: float) -> bool:
 if collecting: samples.append(dt*1000)
 return false
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.begin(); game.end_intro()
 var report: Array=[]
 var shots="--fotos" in OS.get_cmdline_user_args()
 for data in [["patio",game.school.p(620,250),0.0],["corredor",game.school.p(323,250),0.0],["quimica",game.school.p(324,78),0.0],["superior",game.school.p(140,78,3.4),PI/2]]:
  game.player.position=data[1]; game.player.velocity=Vector3.ZERO
  game.view.yaw=data[2]; game.view.pitch=-.12
  game.player.face(game.player.position+game.view.direction())
  game.paused=false
  await create_timer(.6).timeout
  if shots:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/capitulo1-"+data[0]+".png"))
  else:
   var event=InputEventKey.new(); event.physical_keycode=KEY_W; event.keycode=KEY_W; event.pressed=true
   Input.parse_input_event(event)
   samples.clear(); collecting=true
   await create_timer(3).timeout
   collecting=false
   event.pressed=false; Input.parse_input_event(event)
   var sorted=samples.duplicate(); sorted.sort()
   var sum=0.0
   for x in samples: sum+=x
   report.append({"trecho":data[0],"fps":samples.size()*1000/sum,"p95_ms":sorted[int(sorted.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"posição_final":[game.player.position.x,game.player.position.y,game.player.position.z],"paused":game.paused})
 if not shots:
  var file=FileAccess.open("res://../work/capitulo1-desempenho.json",FileAccess.WRITE)
  file.store_string(JSON.stringify({"capturas":false,"qa":game.qa_mode,"trechos":report},"  "))
  print("CHAPTER_PERF ",JSON.stringify(report))
 quit()

extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
 await create_timer(.4).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../work/cena-"+name+".png"))
func run() -> void:
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.begin(); game.end_intro(); game.set_physics_process(false)
 game.bag_found=true
 game.player.position=game.school.cel(37,10)
 var d: Vector3=game.school.ritual_center+Vector3.UP*.5-(game.player.position+Vector3.UP*1.5)
 game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
 game.player.face(game.player.position+game.view.direction())
 for e in game.school.ritual_figures: e.animate(.1)
 await shot("ritual")
 game.alert_spread=true; game.video_recorded=true; game.start_chase(); game.discovery_clock=4.7
 await shot("perseguidor")
 game.phase="ending"; game.ending_clock=8.1; game.ending_set.update(8.1,.1)
 await shot("quarto")
 game.phase="investigate"; game.recording=false
 game.player.position=game.school.cel(60,65); game.player.state="idle"; game.player.clock=0
 var e=game.enemies[1]
 e.position=game.player.position+Vector3(0,0,-.8)
 e.health=80; e.style=0; e.state="idle"; e.aware=true
 e.face(game.player.position); e.play("guarda"); e.animate(.2)
 game.player.face(e.position); game.player.play("guarda"); game.player.animate(.2)
 game.view.yaw=-.65; game.view.pitch=-.15
 await physics_frame
 game.shove()
 for i in 60:
  game._player_tick(1.0/60); game._enemy_ticks(1.0/60)
  await process_frame
  if i in [10,20,45]: await shot("empurrao-"+str(i))
 quit()

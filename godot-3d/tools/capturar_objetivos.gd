extends SceneTree
const OUT="res://../docs/verificacao-objetivos/"
var game
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
 for i in 3: await process_frame
 print("UI ",name," panel=",game.objectives.panel.get_global_rect()," scroll=",game.objectives.scroll.get_global_rect()," column=",game.objectives.column.get_global_rect()," close=",game.objectives.close_button.get_global_rect())
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(OUT+name+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 root.content_scale_size=Vector2i(1280,720); root.size=Vector2i(1280,720)
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_process(false); game.set_physics_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro()
 for id in ["nota_1","nota_2","nota_3","nota_4","pista_1","pista_2"]:
  var at: Vector3=game.objectives.position_of(id)
  game.player.position=at+Vector3(0,-.035,.7)
  var delta=at-(game.player.position+Vector3.UP*.9)
  game.view.yaw=atan2(-delta.x,-delta.z); game.view.pitch=asin(delta.normalized().y)
  game.interact(); game.objectives.close_screen()
 game.bag_found=true; game.objectives.open_phone(); game._process(0)
 await shot("celular-pc")
 game.objectives.open_screen("nota_1"); game._process(0)
 await shot("leitura-pc")
 root.content_scale_size=Vector2i(960,540); root.size=Vector2i(960,540)
 var touch=load("res://capitulo1/toque.gd").new(); game.add_child(touch); game.touch=touch; touch.setup(game)
 game.objectives.open_phone(); game._process(0)
 await shot("celular-toque")
 game.objectives.open_screen("pista_1"); game._process(0)
 await shot("leitura-toque")
 quit()

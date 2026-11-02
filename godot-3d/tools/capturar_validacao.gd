extends SceneTree
## Captura opcional apenas do viewport desta cena; não acessa o desktop.
func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var lab=load("res://validacao/inicio.tscn").instantiate()
 root.add_child(lab)
 await create_timer(2).timeout
 await RenderingServer.frame_post_draw
 var path=ProjectSettings.globalize_path("res://../work/validacao-inicial.png")
 var result=root.get_texture().get_image().save_png(path)
 print("VALIDACAO_CAPTURE ",result," ",path)
 quit(0 if result==OK else 1)

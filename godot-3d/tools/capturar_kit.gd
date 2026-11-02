extends SceneTree
## Mostruário do kit modular do bloqueio (todas as peças lado a lado, com nome).
## Uso: xvfb-run godot --path godot-3d --script res://tools/capturar_kit.gd -- saida.png
const KIT=preload("res://capitulo1/mapa/kit.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var saida: String=OS.get_cmdline_user_args()[0]
 var cena:=Node3D.new(); root.add_child(cena)
 var env:=WorldEnvironment.new(); env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(.13,.14,.16)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color(.8,.82,.86); env.environment.ambient_light_energy=.8
 cena.add_child(env)
 var sol:=DirectionalLight3D.new(); sol.rotation_degrees=Vector3(-50,-35,0); sol.light_energy=1.1; cena.add_child(sol)
 var lib: MeshLibrary=KIT.construir()
 var ids: PackedInt32Array=lib.get_item_list()
 # Mostra as peças principais (as variações de 1 m e cantos ficam de fora para caber).
 var mostrar:=["parede","parede_1m","parede_canto","parede_t","porta","janela","vao","grade","meia_parede","meia_parede_canto",
  "coluna","piso_azulejo","piso_cimento","piso_quadra","telhado","degrau","bloco_baixo","palco"]
 # A árvore (copa de 6 m) fica fora: taparia as outras peças.
 var i:=0
 for nome in mostrar:
  var id:=lib.find_item_by_name(nome)
  if id<0: continue
  var m:=MeshInstance3D.new(); m.mesh=lib.get_item_mesh(id)
  var col:=i%7; var lin:=i/7
  m.position=Vector3(col*4.2,0,lin*6.5)
  if nome=="telhado": m.position.y=.6
  cena.add_child(m)
  var rotulo:=Label3D.new(); rotulo.text=nome; rotulo.font_size=48; rotulo.pixel_size=.008
  rotulo.position=m.position+Vector3(.5,-.05,1.9); rotulo.rotation_degrees.x=-70
  rotulo.modulate=Color(1,.9,.4); cena.add_child(rotulo)
  i+=1
 var cam:=Camera3D.new(); cena.add_child(cam)
 cam.position=Vector3(12.6,10,20); cam.look_at(Vector3(12.6,.5,5.5)); cam.fov=62; cam.current=true
 for k in 15: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(saida)
 print("KIT_CAPTURA ",saida," pecas=",ids.size())
 quit()

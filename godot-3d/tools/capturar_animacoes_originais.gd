extends SceneTree
## Quadros reais do ator do jogo, por ticks físicos e input, sem escrever no rig.
## Godot --path godot-3d --script res://tools/capturar_animacoes_originais.gd
const DT:=1.0/60
const LAYER:=1<<19
const OUT="res://../docs/verificacao-animacoes/"
var game: Node3D
var viewport: SubViewport
var camera: Camera3D
var label: Label
var manifest: Array=[]
func _initialize() -> void: call_deferred("run")
func key(code: Key,pressed: bool) -> void:
 var event=InputEventKey.new(); event.physical_keycode=code; event.keycode=code; event.pressed=pressed
 Input.parse_input_event(event); Input.flush_buffered_events()
func inputs(walk: bool,run_fast: bool,crouch: bool) -> void:
 key(KEY_W,walk); key(KEY_SHIFT,run_fast); key(KEY_CTRL,crouch)
func layers(actor) -> void:
 for visual in actor.model.find_children("*","VisualInstance3D",true,false): visual.layers=LAYER
func follow(side: Vector3) -> void:
 var target: Vector3=game.player.global_position+Vector3.UP*.85
 camera.global_position=target+side*4.5+Vector3.UP*.05
 camera.look_at(target)
func tick() -> void:
 await physics_frame
 game._player_tick(DT)
func shot(name: String,time: float,side: Vector3) -> Image:
 follow(side)
 var state=String(game.player.motion.playback.get_current_node())
 var clip=game.player.motion.active_clip
 label.text="%s | %.1f s | %s | %.2fx"%[name,time,clip,game.player.motion.physical_rate]
 await process_frame
 await RenderingServer.frame_post_draw
 var image=viewport.get_texture().get_image()
 image.save_png(OUT+name+"/%04d.png"%roundi(time*10))
 manifest.append({"sequence":name,"time":time,"state":state,"clip":clip,"clip_time":game.player.motion.position(),"rate":game.player.motion.physical_rate,"position":[game.player.position.x,game.player.position.y,game.player.position.z]})
 return image
func contact_sheet(name: String,images: Array[Image]) -> void:
 for start in range(0,images.size(),10):
  var sheet=Image.create(1600,400,false,Image.FORMAT_RGB8)
  sheet.fill(Color(.12,.12,.12))
  for i in range(start,mini(start+10,images.size())):
   var tile=images[i].duplicate(); tile.resize(320,200,Image.INTERPOLATE_LANCZOS); tile.convert(Image.FORMAT_RGB8)
   var j=i-start
   sheet.blit_rect(tile,Rect2i(0,0,320,200),Vector2i((j%5)*320,(j/5)*200))
  sheet.save_png(OUT+name+"/contato-%02d.png"%(start/10))
func sequence(name: String,walk: bool,run_fast: bool,crouch: bool,stairs:=0,stop:=false) -> void:
 var actor=game.player
 inputs(false,false,false)
 actor.state="idle"; actor.hidden=false; actor.model.visible=true; actor.health=100; actor.tool_pose=false
 game.interaction.clear(); game.phase="investigate"
 # Levanta em área livre antes de posicionar no lance; não testa o teto ao trocar de cenário.
 actor.position=Vector3(200,.03,200); actor.velocity=Vector3.ZERO
 for i in 24: await tick()
 var direction:=Vector3.BACK
 var side:=Vector3.RIGHT
 if stairs!=0:
  var a: Vector3=game.school.stairs_bottom; var b: Vector3=game.school.stairs_top
  var flight=(b-a)*Vector3(1,0,1); var distance=flight.length(); var along=flight/distance
  direction=along*stairs; side=Vector3(along.z,0,-along.x)
  actor.position=(a if stairs>0 else b)+direction*.7
  actor.position.y=lerpf(a.y,b.y,.7/distance if stairs>0 else 1-.7/distance)+.02
 else: actor.position=Vector3(200,.02,200)
 actor.velocity=Vector3.ZERO; actor.face(actor.position+direction)
 game.view.yaw=atan2(-direction.x,-direction.z)
 for i in 24: await tick()
 if name=="agachado-andando":
  inputs(false,false,true)
  for i in 18: await tick()
 if stop:
  inputs(true,true,false)
  for i in 36: await tick()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+name))
 var images: Array[Image]=[]
 images.append(await shot(name,0,side))
 inputs(walk,run_fast,crouch)
 for frame in range(1,121):
  await tick()
  if frame%6==0: images.append(await shot(name,frame*DT,side))
 contact_sheet(name,images)
 print("CAPTURA ",name," ",images.size()," quadros, intervalo 0,1 s")
 inputs(false,false,false)
func camera_proof() -> void:
 var actor=game.player; var enemy=game.enemies[1]
 actor.position=Vector3(200,0,200); actor.state="idle"; actor.velocity=Vector3.ZERO
 inputs(false,false,false)
 for i in 24: await tick()
 game.view.yaw=0; game.view.pitch=-.12
 game.view.update(1.0)
 enemy.position=game.view.camera.global_position+game.view.direction()*.2-Vector3.UP*1.4
 enemy.model.visible=true; layers(enemy)
 enemy.play("guarda"); enemy.animate(DT)
 camera.projection=Camera3D.PROJECTION_PERSPECTIVE; camera.fov=game.view.camera.fov
 camera.global_transform=game.view.camera.global_transform
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"camera"))
 # A primeira imagem registra a oclusão sem ocultar; a segunda aplica a regra do jogo.
 for name in ["antes","depois"]:
  if name=="depois": game.view._update_occluders()
  label.text="Câmera | "+name+" | cenário: camada 1; cultista: camada 2"
  await process_frame; await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png(OUT+"camera/"+name+".png")
 print("CAPTURA camera perto_da_lente_oculto=",not enemy.model.visible)
func run() -> void:
 if "--contatos" in OS.get_cmdline_user_args():
  for name in DirAccess.get_directories_at(OUT):
   var files=DirAccess.get_files_at(OUT+name); files.sort()
   var images: Array[Image]=[]
   for file in files:
    if file.ends_with(".png") and not file.begins_with("contato-") and file.get_basename().is_valid_int():
     var image=Image.new(); image.load(OUT+name+"/"+file); images.append(image)
   if not images.is_empty(): contact_sheet(name,images)
  quit(); return
 AudioServer.set_bus_mute(0,true)
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 game.started=true; game.paused=false; game.phase="investigate"
 for i in 3: await physics_frame
 game.low_view.render_target_update_mode=SubViewport.UPDATE_DISABLED
 var environment: Environment=game.school.find_children("*","WorldEnvironment",true,false)[0].environment
 environment.fog_enabled=false; environment.ambient_light_energy=.9; environment.ambient_light_color=Color.WHITE
 environment.background_mode=Environment.BG_COLOR; environment.background_color=Color(.36,.39,.43)
 for light in game.school.find_children("*","DirectionalLight3D",true,false): light.light_energy=1.2
 layers(game.player)
 # Mostra os degraus reais do mapa sem as paredes entre a lente lateral e o ator.
 var step=game.school.lib.get_item_mesh(game.school.KIT.item(game.school.lib,"degrau"))
 for visual in game.school.find_children("*","MeshInstance3D",true,false):
  if visual.mesh==step: visual.layers|=LAYER
 var floor_body=StaticBody3D.new(); var collision=CollisionShape3D.new(); var box=BoxShape3D.new()
 box.size=Vector3(40,.1,60); collision.shape=box; floor_body.position=Vector3(200,-.05,200)
 floor_body.add_child(collision); game.add_child(floor_body)
 var visual=MeshInstance3D.new(); var floor_mesh=BoxMesh.new(); floor_mesh.size=box.size
 visual.mesh=floor_mesh; visual.layers=LAYER; floor_body.add_child(visual)
 var material=StandardMaterial3D.new(); material.albedo_color=Color(.55,.57,.60); material.roughness=1; visual.material_override=material
 viewport=SubViewport.new(); viewport.size=Vector2i(640,400); viewport.world_3d=game.get_world_3d()
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
 camera=Camera3D.new(); camera.cull_mask=LAYER; camera.projection=Camera3D.PROJECTION_ORTHOGONAL; camera.size=2.5; viewport.add_child(camera); camera.current=true
 var canvas=CanvasLayer.new(); viewport.add_child(canvas)
 label=Label.new(); label.position=Vector2(10,8); label.add_theme_font_size_override("font_size",14); canvas.add_child(label)
 await sequence("andando",true,false,false)
 await sequence("correndo",true,true,false)
 await sequence("parando",false,false,false,0,true)
 await sequence("agachando",false,false,true)
 await sequence("agachado-andando",true,false,true)
 await sequence("escada-subindo",true,false,false,1)
 await sequence("escada-subindo-correndo",true,true,false,1)
 await sequence("escada-descendo",true,false,false,-1)
 await sequence("escada-descendo-correndo",true,true,false,-1)
 await camera_proof()
 var file=FileAccess.open(OUT+"manifesto.json",FileAccess.WRITE); file.store_string(JSON.stringify(manifest,"  ")+"\n"); file.close()
 print("CAPTURAS_ORIGINAIS: ",manifest.size()," quadros de animação + 2 de câmera")
 game.queue_free(); viewport.queue_free(); await process_frame; quit()

extends SceneTree
## Capturas do capítulo 1 para revisão do mapa.
## Uso: xvfb-run godot --path godot-3d --script res://tools/capturar_vistas.gd -- <pasta> <prefixo> [jogo]
## Padrão = revisão do bloqueio: resolução cheia, sem filtro retrô, luz clara e
## sem névoa (para ler a geometria). Com "jogo": luz e filtro como no jogo.
## Pontos em células da grade (capitulo1/mapa/*.txt), não em coordenadas soltas.
const NIVEL=preload("res://capitulo1/nivel.gd")
var out:=""
var revisao:=true
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
 for i in 20: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
 print("CAPTURA ",out+"/"+name+".png")
func look(game,at: Vector3,yaw_deg: float,pitch:=-.08) -> void:
 game.player.position=at; game.player.velocity=Vector3.ZERO
 game.view.yaw=deg_to_rad(yaw_deg); game.view.pitch=pitch
 game.player.face(at+game.view.direction()*Vector3(1,0,1))
func mirar(game,alvo: Vector3) -> void:
 var d: Vector3=alvo-(game.player.position+Vector3.UP*1.5)
 game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
## Vista aérea sem telhados (maquete), câmera própria.
func aerea(game,nome: String,centro: Vector3,altura: float,de: Vector3,orto:=0.0) -> void:
 var s=game.school
 s.telhados.visible=false
 game.player.visible=false
 game.set_process(false)
 var cam: Camera3D=game.low_camera
 cam.global_position=centro+de.normalized()*altura
 cam.look_at(centro,Vector3.FORWARD if absf(de.normalized().y)>.99 else Vector3.UP)
 cam.far=400
 if orto>0:
  cam.projection=Camera3D.PROJECTION_ORTHOGONAL; cam.size=orto
 await shot(nome)
 cam.projection=Camera3D.PROJECTION_PERSPECTIVE
 game.set_process(true)
 game.player.visible=true
 s.telhados.visible=true
func ponto(game,nome: String) -> Vector3: return NIVEL.ponto(game.school,nome)
func run() -> void:
 var args=OS.get_cmdline_user_args()
 out=args[0]; var prefix=args[1] if args.size()>1 else "v"
 revisao=not ("jogo" in args)
 DirAccess.make_dir_recursive_absolute(out)
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.begin(); game.end_intro(); game.set_physics_process(false)
 var s=game.school
 if revisao:
  game.film_enabled=false; game._resize_low()
  var env: Environment=s.find_children("*","WorldEnvironment",true,false)[0].environment
  env.fog_enabled=false; env.ambient_light_energy=1.1; env.ambient_light_color=Color(.85,.86,.9)
  for l in s.find_children("*","DirectionalLight3D",true,false): l.light_energy=.9
 var meio: Vector3=s.cel(50,40)
 await aerea(game,prefix+"-aerea-planta",meio,120,Vector3.UP,92)
 await aerea(game,prefix+"-aerea-sudeste",meio,72,Vector3(.55,1.0,.75))
 await aerea(game,prefix+"-aerea-noroeste",s.cel(30,20),46,Vector3(-.5,1.0,-.6))
 await aerea(game,prefix+"-aerea-quimica",s.cel(28,6),26,Vector3(.35,1.0,.9))
 look(game,s.spawn,90); await shot(prefix+"-01-acorda")
 look(game,ponto(game,"refeitorio"),0); await shot(prefix+"-02-refeitorio-palco")
 look(game,ponto(game,"refeitorio")+Vector3(-6,0,4),90); await shot(prefix+"-03-refeitorio-patio")
 look(game,ponto(game,"patio_aberto"),90); await shot(prefix+"-04-patio-aberto")
 look(game,s.cel(56,20),150); await shot(prefix+"-05-labs-varanda")
 look(game,s.cel(54,31),180,-.05); await shot(prefix+"-06-corredorzinho")
 look(game,ponto(game,"avistamento"),90); await shot(prefix+"-07-corredor-sul")
 look(game,s.cel(51,11),90); await shot(prefix+"-08-passagem-norte")
 look(game,ponto(game,"corredor_aberto"),0); await shot(prefix+"-09-corredor-aberto")
 look(game,ponto(game,"gravar"),0); mirar(game,s.ritual_center+Vector3.UP*.5); await shot(prefix+"-10-patio-quimica-ritual")
 look(game,ponto(game,"entrada_escada"),90,-.05); await shot(prefix+"-11-entrada-escada")
 look(game,ponto(game,"espiar"),0); mirar(game,s.ritual_center+Vector3.UP*.5); await shot(prefix+"-12-espiar-ritual")
 look(game,s.ritual_approach,90,.25); await shot(prefix+"-13-escada")
 look(game,ponto(game,"corredor_superior"),90); await shot(prefix+"-14-corredor-superior")
 look(game,ponto(game,"dentro_3_informatica"),0); await shot(prefix+"-15-bolsa")
 look(game,s.cel(16,30),0,-.12); await shot(prefix+"-16-quadra")
 look(game,s.cel(78,36),180); await shot(prefix+"-17-passagem-portao")
 look(game,s.gate_at+Vector3(0,0,-5),180); await shot(prefix+"-18-portao")
 look(game,ponto(game,"saida"),-90); await shot(prefix+"-19-area-saida")
 quit()

extends SceneTree
## Capturas de referência do capítulo 1 (uso: xvfb-run godot --path . --script res://tools/capturar_vistas.gd -- <pasta> <prefixo>)
var out:=""
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
 for i in 20: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"/"+name+".png")
func look(game,at: Vector3,yaw_deg: float,pitch:=-.08) -> void:
 game.player.position=at; game.player.velocity=Vector3.ZERO
 game.view.yaw=deg_to_rad(yaw_deg); game.view.pitch=pitch
 game.player.face(at+game.view.direction()*Vector3(1,0,1))
func run() -> void:
 var args=OS.get_cmdline_user_args()
 out=args[0]; var prefix=args[1] if args.size()>1 else "v"
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 game.begin(); game.end_intro(); game.set_physics_process(false)
 var s=game.school
 await shot(prefix+"-acorda")
 look(game,s.p(620,250),90); await shot(prefix+"-patio")
 look(game,s.p(323,250),0); await shot(prefix+"-corredor")
 look(game,s.p(130,78,s.LEVEL),180); await shot(prefix+"-superior")
 game.bag_found=true; game.phone_light=true
 look(game,s.p(324,61),0)
 var d: Vector3=s.ritual_center+Vector3.UP*.5-(game.player.position+Vector3.UP*1.5)
 game.view.yaw=atan2(-d.x,-d.z); game.view.pitch=asin(d.normalized().y)
 await shot(prefix+"-ritual")
 look(game,s.p(600,500),0); await shot(prefix+"-lanterna")
 look(game,s.p(641,430),180); await shot(prefix+"-passagem")
 game.phone_light=false
 look(game,s.p(780,180),90); await shot(prefix+"-refeitorio")
 game.phone_light=true
 look(game,s.p(125,420),0,-.15); await shot(prefix+"-quadra")
 look(game,s.p(392,280),-35,-.25); await shot(prefix+"-hardware")
 game.phone_light=false
 look(game,s.p(330,60),75,.05); await shot(prefix+"-patio-quimica")
 look(game,s.p(262,52),90,0); await shot(prefix+"-escada-entrada")
 look(game,s.p(250,51),-90,0); await shot(prefix+"-espiar-ritual")
 look(game,s.p(733,175),0,.05); await shot(prefix+"-auditorio")
 look(game,s.p(520,180),-90,0); await shot(prefix+"-labs-patio")
 look(game,s.p(450,250),180,0); await shot(prefix+"-corredorzinho")
 game.phone_light=true
 look(game,s.p(130,350),0,.1); await shot(prefix+"-quadra-rede")
 look(game,s.p(540,230),180,0); await shot(prefix+"-patio-colunas")
 look(game,s.p(641,600),0,.05); await shot(prefix+"-entrada")
 quit()

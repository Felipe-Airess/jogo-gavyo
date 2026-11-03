extends SceneTree
var passed:=0
var failed:=0

func _initialize() -> void:
 call_deferred("run")

func check(ok: bool, message: String) -> void:
 if ok:
  passed+=1
  print("PASS ",message)
 else:
  failed+=1
  push_error("FAIL "+message)

func frames(count: int) -> void:
 for i in count:
  await physics_frame

func run() -> void:
 var lab=load("res://validacao/inicio.tscn").instantiate()
 root.add_child(lab)
 lab.set_physics_process(false)
 lab.set_process(false)
 await frames(3)
 var view=lab.view
 lab.player.position=Vector3(0,0,-2)
 view.yaw=0
 view.pitch=-.12
 view.update(1)
 check(view.camera.global_position.x>.35,"exploração livre usa ombro mesmo sem alvo")
 check(view.camera.global_position.distance_to(lab.player.position+Vector3(0,1.35,0))<2.4,"câmera livre mais próxima")
 view.shoulder_side=-1
 view.update(1)
 check(view.camera.global_position.x<-.35,"lado do ombro pode ser comparado")
 # Encostar a câmera na parede lateral deve puxá-la para dentro.
 lab.player.position=Vector3(1.20,0,-2)
 view.shoulder_side=1
 view.yaw=PI/2
 await frames(2)
 view.update(1)
 check(view.camera.global_position.x<1.36,"parede lateral impede câmera de atravessar")
 check(view.mode=="third_person","compressão do ombro conserva modo terceira pessoa")
 # Mesmo uma posição anterior do outro lado da parede não sobrevive à suavização.
 view.camera.global_position=Vector3(3,1.5,-2)
 view.update(.001)
 check(view.camera.global_position.x<1.36,"suavização também respeita colisão em esquina")
 lab.player.position=Vector3(0,0,-11)
 await frames(2)
 check(not lab.player.test_move(lab.player.global_transform,Vector3(-5,0,0)),"esquina permite passagem lateral da cápsula de Miguel")
 lab.player.position=Vector3(0,0,-6.35)
 await frames(2)
 var query=PhysicsRayQueryParameters3D.create(Vector3(0,1,-6.35),Vector3(3,1,-6.35),1)
 var space=lab.get_world_3d().direct_space_state
 check(not space.intersect_ray(query).is_empty(),"porta fechada bloqueia entrada da sala")
 lab.door.set_open(true,true)
 await frames(2)
 check(space.intersect_ray(query).is_empty(),"porta aberta deixa passagem real na sala")
 # Testa também a integração da animação de abrir, que chama atualização de caminhos.
 lab.door.set_open(false)
 await create_timer(.8).timeout
 check(not lab.door.moving,"porta conclui movimento na bancada sem erro de callback")
 lab.player.position=Vector3(0,0,-2)
 lab.phase="chase"
 view.update(1)
 check(view.mode=="first_person" and not lab.player.model.visible,"fuga continua em primeira pessoa")
 lab.phase="investigate"
 view.update(1)
 check(view.mode=="third_person" and lab.player.model.visible,"retorno ao ombro restaura modelo")
 var event=InputEventKey.new()
 event.keycode=KEY_F2
 event.pressed=true
 lab._unhandled_input(event)
 lab._physics_process(.016)
 check(lab.audition and not lab.player.anim.current_animation.is_empty(),"prévia reproduz clipe existente do modelo")
 lab._unhandled_input(event)
 check(not lab.audition,"prévia permite voltar à exploração")
 event.keycode=KEY_F3
 lab._unhandled_input(event)
 check(lab.warm,"comparação de paleta disponível")
 print("VALIDACAO_INICIAL_TEST: %d passed, %d failed"%[passed,failed])
 lab.queue_free()
 await process_frame
 quit(1 if failed else 0)

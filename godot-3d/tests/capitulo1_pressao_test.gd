extends SceneTree
## Pressão sobre áudio/câmera, sem alterar poses ou estado da caça para passar limites.
var game: Node3D
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func frames(n: int) -> void:
 for i in n:
  game.elapsed+=.1; game._process(.1); await physics_frame
func run() -> void:
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro(); game.player.position=Vector3(200,0,200); game.player.velocity=Vector3.ZERO
 game.view.trauma=0; game.burst_clock=0
 for i in game.enemies.size():
  var actor=game.enemies[i]; actor.position=Vector3(240+i*2,0,200); actor.aware=false; actor.hunt.reset()
 await frames(20)
 var base_pitch=game.breathing.pitch_scale; var base_db=game.breathing.volume_db
 check(game.pressure.value==0 and not game.tension.playing,"sem caça não há tensão ou pressão residual")
 game.alert_spread=true; await frames(3)
 check(game.pressure.hunters==0 and game.pressure.value==0,"alerta salvo sozinho não liga pressão sem caçador")
 var e=game.enemies[0]; e.position=Vector3(200,0,220); e.aware=true; e.hunt.mode="search"
 await frames(10)
 var far=game.pressure.value
 check(far>0 and far<.3 and game.tension.playing,"busca longe mantém tensão baixa, mesmo sem visão")
 var tension_source=load("res://capitulo1/assets/tensao_provisoria.wav")
 check(game.tension.stream is AudioStreamWAV and game.tension.stream.data==tension_source.data and game.tension.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"tensão usa recurso marcado provisório, carregado por load")
 var far_boost=game.pressure.foot_boost(game,e)
 e.position=Vector3(200,0,202); e.hunt.mode="chase"
 var player_at: Vector3=game.player.position
 var max_shake:=0.0
 for i in 12:
  await frames(1)
  max_shake=maxf(max_shake,maxf(absf(game.view.camera.h_offset),absf(game.view.camera.v_offset)))
 var near=game.pressure.value
 var near_boost=game.pressure.foot_boost(game,e)
 check(near>far+.5 and near_boost>far_boost+4,"proximidade aumenta pressão e reforço dos passos pesados")
 game.sound.footstep(e,"cimento")
 var step=game.sound.step_players[e.get_instance_id()]
 var offset=step.volume_db-float(game.sound.LEVELS[game.sound.last_file]["gain_db"])
 check(offset>0 and step.playing and step.max_distance==10,"reforço chega ao emissor 3D dos passos novos")
 check(game.breathing.pitch_scale>base_pitch+.25 and game.breathing.volume_db>base_db+10,"respiração acelera e cresce quando caçador chega perto")
 check(max_shake>.001 and max_shake<=.0046,"tremor óptico é perceptível e limitado a 4,5 mm")
 check(game.player.position==player_at,"pressão não move o corpo de Miguel")
 print("PRESSAO longe=%.3f perto=%.3f reforco_passo=%.2f dB tremor=%.5f m"%[far,near,near_boost,max_shake])
 # A própria máquina de caça define quando a pressão acaba.
 e.aware=false; e.hunt.mode="return"
 await frames(25)
 check(game.pressure.value==0 and not game.tension.playing,"fim da última caça apaga tensão após retorno suave")
 check(absf(game.breathing.pitch_scale-base_pitch)<.001 and absf(game.breathing.volume_db-base_db)<.1,"respiração volta ao perfil normal")
 check(is_zero_approx(game.view.camera.h_offset) and is_zero_approx(game.view.camera.v_offset),"câmera volta ao repouso")
 game.video_recorded=true; game.alert_spread=false; game.start_chase()
 check(game.pursuer==null,"vídeo sem alerta não cria perseguidor")
 game.video_recorded=false; game.alert_spread=true; game.start_chase()
 check(game.pursuer==null,"alerta sem vídeo mantém o gatilho existente da apresentação")
 game.video_recorded=true; game.start_chase()
 var pursuer=game.pursuer
 check(is_instance_valid(pursuer) and pursuer.position==game.school.pursuer_post and game.enemies.size()==8,"perseguidor nasce só após alerta, no posto 8, mantendo sete comuns e o leitor")
 game.start_chase()
 check(game.pursuer==pursuer,"gatilho não cria um segundo perseguidor")
 game.end_discovery(); pursuer.position=game.player.position+Vector3.BACK*2
 await frames(10)
 check(game.pressure.value>.8 and game.pressure.hunters==1,"perseguidor sozinho sustenta a pressão da fuga")
 game.paused=true; await frames(1)
 check(game.pressure.value==0 and not game.tension.playing and not game.breathing.playing,"pausa silencia pressão e respiração")
 game.paused=false; game.restore_checkpoint(); await frames(1)
 check(game.pressure.value==0 and not game.tension.playing and game.pursuer==null,"checkpoint limpa pressão e perseguidor")
 print("CAPITULO1_PRESSAO: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)

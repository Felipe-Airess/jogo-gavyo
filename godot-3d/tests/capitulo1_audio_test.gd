extends SceneTree
## Valida recursos importados, níveis e eventos reais. Não escreve poses.
const DT:=1.0/60
var passed:=0
var failed:=0
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
 if ok: passed+=1; print("PASS ",label)
 else: failed+=1; print("FAIL ",label)
func count(event: String) -> int: return int(game.sound.played.get(event,0))
func fixture_grab(e) -> void:
 game.escape.clear(); game.escape_blackout=0; game.escape_advantage_until=0; game.player.dead=false
 game.player.hidden=false; game.player.state="idle"; game.player.position=Vector3(200,0,200); game.player.velocity=Vector3.ZERO
 game.phase="investigate"; e.position=Vector3(200,0,200.55); e.state="idle"; e.down=false; e.dead=false; e.velocity=Vector3.ZERO
func run() -> void:
 var timeout=create_timer(80,true,false,true)
 timeout.timeout.connect(func():print("AUDIO TIMEOUT");quit(2))
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_physics_process(false); game.set_process(false); game.qa_mode=true
 for i in 3: await physics_frame
 game.begin(); game.end_intro(); var sound=game.sound
 var loaded:=0; var safe:=true
 for file in sound.LEVELS:
  var stream=load(sound.ROOT+file)
  if stream is AudioStream and stream.get_length()>0: loaded+=1
  var level: Dictionary=sound.LEVELS[file]
  safe=safe and float(level["peak_db"])+float(level["gain_db"])<=-8.99
 print("AUDIO_RECURSOS carregados=%d/376"%loaded)
 check(loaded==376,"todos os 376 áudios do pacote carregam por load e têm duração")
 var references=true
 for pool in sound.pools.values():
  for file in pool: references=references and sound.streams.get(file)!=null and sound.LEVELS.has(file)
 var legacy=true
 for file in ["res://prototipo/audio/grilos.wav","res://capitulo1/assets/culto.wav","res://capitulo1/assets/respiracao.wav"]:
  var stream=load(file); legacy=legacy and stream is AudioStream and stream.get_length()>0
 check(legacy,"três sons sem equivalente continuam carregando como recursos")
 check(references,"cada som referenciado pelo jogo possui recurso e medição")
 var worst=-120.0
 for file in sound.streams:
  var playback=sound.streams[file].instantiate_playback(); playback.start()
  var peak:=0.0
  for i in ceili((sound.streams[file].get_length()+.1)*AudioServer.get_mix_rate()/2048.0):
   for frame in playback.mix_audio(1,2048): peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
  playback.stop()
  worst=maxf(worst,linear_to_db(maxf(.000001,peak))+float(sound.LEVELS[file]["gain_db"]))
 print("AUDIO_NIVEL pico_decodificado_com_ganho=%.2f dBFS"%worst)
 check(worst<=-8.8,"decodificação independente confirma pico dos sons usados")
 check(safe,"ganho medido limita pico individual a -9 dBFS antes dos buses")
 var limiters:=0
 for i in AudioServer.get_bus_effect_count(0):
  var effect=AudioServer.get_bus_effect(0,i)
  if effect is AudioEffectHardLimiter and effect.ceiling_db<=-1: limiters+=1
 check(limiters==1,"Master tem um limitador de segurança com teto -1 dBFS")
 var found_tile=false; var found_concrete=false
 var school=game.school; var grid=school.andares[0]
 for row in grid.altura:
  for col in grid.largura:
   var point=school.cel(col,row)
   var material=school.PISO_PECA.get(grid.piso(col,row),"")
   if material=="piso_azulejo": found_tile=found_tile or sound.floor_at(point)=="azulejo"
   elif material=="piso_cimento": found_concrete=found_concrete or sound.floor_at(point)=="cimento"
 check(found_tile and found_concrete,"mapa real distingue azulejo e cimento")
 check(sound.floor_at((school.stairs_bottom+school.stairs_top)*.5)=="escada","lance real da escada seleciona pedra/concreto")
 var last_file=""; var varied=true
 for i in 30:
  sound.footstep(game.player,"cimento")
  varied=varied and sound.last_file!=last_file; last_file=sound.last_file
 check(varied,"passos variam sem repetir o mesmo arquivo imediatamente")
 sound.footstep(game.player,"azulejo"); var tile_file=sound.last_file
 sound.footstep(game.player,"escada")
 check(tile_file!=sound.last_file,"troca de piso muda o banco de passos")
 check(sound.step_players[game.player.get_instance_id()].bus=="CapituloEscada","escada recebe ressonância curta própria")
 var enemy=game.enemies[0]; sound.footstep(enemy,"cimento")
 var emitter: AudioStreamPlayer3D=sound.step_players[enemy.get_instance_id()]
 check(emitter.playing and emitter.get_parent()==enemy and emitter.max_distance==10 and emitter.unit_size>=3,"passos do cultista são 3D, seguem o corpo e chegam a 10 m")
 var player_step: AudioStreamPlayer3D=sound.step_players[game.player.get_instance_id()]
 check(player_step.max_distance==7 and emitter.pitch_scale<player_step.pitch_scale,"Miguel tem alcance de 7 m; comum tem timbre mais pesado")
 game.pursuer=game.spawn_actor(Vector3(220,0,200),true,true)
 sound.footstep(game.pursuer,"cimento")
 var hunter_step: AudioStreamPlayer3D=sound.step_players[game.pursuer.get_instance_id()]
 check(hunter_step.playing and hunter_step.pitch_scale<emitter.pitch_scale and hunter_step.max_distance==10,"perseguidor tem passos próprios mais graves e espaciais")
 game._cultist_shout(enemy)
 check(enemy.hunt_voice.playing and enemy.hunt_voice.stream.resource_path.contains("zombie-") and enemy.hunt_voice.max_distance==10,"grito real do cultista usa voz fornecida e alcance de 10 m")
 # O disparo da porta fica no próprio objeto, cobrindo jogador e IA.
 var door=game.school.doors[0]; door.set_open(false,true)
 var opens=count("porta_abrir"); var closes=count("porta_fechar")
 door.set_open(true); door.set_open(false)
 check(count("porta_abrir")==opens+1 and count("porta_fechar")==closes+1,"porta toca abertura e fechamento ao mudar estado")
 var hide=0; school.set_hide_open(hide,false,true)
 opens=count("armario_abrir"); closes=count("armario_fechar")
 school.set_hide_open(hide,true); school.set_hide_open(hide,false)
 check(count("armario_abrir")==opens+1 and count("armario_fechar")==closes+1,"armário toca rangido e fecho")
 for e in game.enemies: e.position=Vector3(230,0,230)
 game.player.position=game.objectives.position_of("chave")+Vector3(0,-.035,.7)
 var key_delta=game.objectives.position_of("chave")-(game.player.position+Vector3.UP*.9)
 game.view.yaw=atan2(-key_delta.x,-key_delta.z); game.view.pitch=asin(key_delta.normalized().y)
 game.interact()
 game.player.position=school.bag_at-Vector3.UP*1.01+Vector3(0,0,-.95)
 game.player.state="idle"; game.player.hidden=false; game.phase="investigate"
 var bag=count("bolsa"); game.interact()
 for i in 180: game._player_tick(DT); await physics_frame
 check(game.bag_found and count("bolsa")==bag+1,"bolsa toca manuseio somente no contato confirmado")
 # Portão usa o instante do clipe sem consumir o evento que a ação precisa ler.
 game.player.position=school.gate_at+Vector3(0,0,-.7); game.player.state="idle"
 var gate=count("portao"); game._jump_gate_now()
 for i in 90: game._physics_process(DT); await physics_frame
 check(count("portao")==gate+1,"portão toca contato metálico durante escalada")
 game.phase="investigate"
 fixture_grab(enemy); var grab=count("agarrao")
 game._grab_player(enemy); sound.tick(DT)
 check(game.escape.active and count("agarrao")==grab+1 and count("roupa")>0,"agarrão toca impacto e roupa no corpo correto")
 check(sound.breath_profile=="agarrado","agarrão muda perfil da respiração provisória preservada")
 var arrows=count("seta"); var success=count("sucesso")
 for code in game.escape.sequence.duplicate(): game.escape_direction(code)
 check(count("sucesso")==success+1 and count("seta")>arrows,"cada acerto e conclusão do minigame têm som")
 fixture_grab(enemy); game._grab_player(enemy)
 var errors=count("erro"); var failures=count("falha")
 game.escape_direction(KEY_UP if game.escape.sequence[0]!=KEY_UP else KEY_DOWN)
 check(count("erro")==errors+1 and count("falha")==failures+1,"seta errada toca erro e falha")
 game._escape_tick(1.51)
 fixture_grab(enemy); game._grab_player(enemy); failures=count("falha")
 game._escape_tick(game.escape.remaining+.01)
 check(count("falha")==failures+1,"prazo esgotado também toca falha")
 game._escape_tick(1.51)
 game.player.velocity=Vector3.ZERO; sound.tick(.2)
 check(sound.breath_profile=="normal" and game.breathing.playing,"respiração normal fica ativa em exploração")
 game.player.velocity=Vector3.FORWARD*3.8; sound.tick(.2)
 check(sound.breath_profile=="correndo","corrida muda ritmo e volume da respiração")
 # Passos saem do deslocamento físico, não de uma velocidade sem movimento.
 var body=StaticBody3D.new(); body.position=Vector3(200,-.05,200)
 var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=Vector3(20,.1,20); shape.shape=box
 body.add_child(shape); game.add_child(body)
 game.player.position=Vector3(200,.02,200); game.player.velocity=Vector3.ZERO; game.player.crouched=false
 game.player.state="idle"; game.phase="investigate"; sound.reset()
 await physics_frame
 var footsteps=count("passo_miguel")
 for i in 80:
  game.player.velocity=Vector3.FORWARD*1.45; game.player._slide(DT)
  game.player.face(game.player.position+Vector3.FORWARD); game.player.play("andaFrente"); game.player.animate(DT)
  game._process(DT); await physics_frame
 check(count("passo_miguel")>footsteps,"deslocamento físico dispara passos pelo piso no process do jogo")
 footsteps=count("passo_miguel"); game.player.velocity=Vector3.ZERO
 for i in 20: sound.tick(DT); await physics_frame
 check(count("passo_miguel")==footsteps,"parado não repete passos")
 # Pico real do mixer, com sobreposição de efeitos e UI, sem depender da placa de som.
 var mix_peak=-200.0
 for i in 40:
  if i%6==0:
   for j in 6: sound.emit_at("impacto_metal",game.view.camera.global_position)
   sound.ui("sucesso"); sound.shout(enemy)
  await physics_frame
  mix_peak=maxf(mix_peak,maxf(AudioServer.get_bus_peak_volume_left_db(0,0),AudioServer.get_bus_peak_volume_right_db(0,0)))
 print("AUDIO_MIX pico_master=%.2f dBFS"%mix_peak)
 check(mix_peak>-90 and mix_peak<=-.95,"mistura simultânea permanece abaixo de -1 dBFS")
 game.paused=true; sound.tick(DT)
 check(not game.breathing.playing,"pausa silencia respiração")
 print("CAPITULO1_AUDIO: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)

extends RefCounted
## Medo e atmosfera (decisões de Felipe, 05–06/11/2026):
##  - coração audível, acelerando com a pressão/vigilância (soma-se à
##    respiração, ao tremor de câmera e à tensão que já existiam);
##  - lentidão breve depois de um susto;
##  - jumpscare raro: ao abrir a caixa de materiais na salinha, uma ave escura
##    sai voando na cara do jogador (só susto, uma vez);
##  - parado/escondido por muito tempo: um cultista vem rondar;
##  - pensamentos do Miguel quando o jogador fica muito tempo sem avançar
##    (textos de Felipe; [PROVISÓRIO] até lá).
## Não escreve pose de osso.

const PARADO_LIMITE:=45.0
const PERDIDO_LIMITE:=150.0
const PERDIDO_INTERVALO:=120.0
const LENTO:=.55

var game: Node3D
var coracao: AudioStreamPlayer
var susto_lento:=0.0
var parado:=0.0
var sem_avancar:=0.0
var ultimo_pensamento:=-1000.0
var objetivo_atual:=""
var caixa: Node3D
var tampa: Node3D
var caixa_aberta:=false
var ave: Node3D
var ave_clock:=-1.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 coracao=AudioStreamPlayer.new(); coracao.bus="CapituloVoz"
 var wav: AudioStreamWAV=load("res://capitulo1/assets/sons/gerados/coracao.wav").duplicate()
 wav.loop_mode=AudioStreamWAV.LOOP_FORWARD; wav.loop_end=int(wav.get_length()*wav.mix_rate)
 coracao.stream=wav; coracao.volume_db=-60
 game.add_child(coracao)
 _montar_caixa()

func _montar_caixa() -> void:
 var s=game.school
 if not s.rooms.has("Materiais de esportes"): return
 var r: Rect2=s.rooms["Materiais de esportes"]["rect"]
 var at: Vector3=s.cel(r.end.x-1,r.position.y)  # canto do fundo
 caixa=s.box(Vector3(.8,.5,.55),at+Vector3.UP*.25,"wood",true)
 tampa=Node3D.new(); tampa.position=at+Vector3(0,.5,-.27); s.add_child(tampa)
 var t=s.box(Vector3(.82,.05,.57),Vector3.ZERO,"wood",false); t.reparent(tampa,false); t.position=Vector3(0,.02,.27)

func perto_da_caixa() -> bool:
 return caixa!=null and not caixa_aberta and game._near_looking(caixa.position+Vector3.UP*.3,1.5)

func texto() -> String:
 return "[Espaço] Abrir caixa de materiais" if perto_da_caixa() else ""

func abrir_caixa() -> bool:
 if not perto_da_caixa(): return false
 caixa_aberta=true
 var tw=tampa.create_tween(); tw.tween_property(tampa,"rotation:x",-1.6,.25)
 _soltar_ave()
 return true

## A ave escura sai voando na direção da câmera, batendo as asas.
func _soltar_ave() -> void:
 ave=Node3D.new(); game.add_child(ave)
 ave.global_position=caixa.position+Vector3.UP*.5
 var preto=StandardMaterial3D.new(); preto.albedo_color=Color(.03,.03,.035)
 for parte in [[Vector3(.18,.14,.32),Vector3.ZERO],[Vector3(.12,.1,.12),Vector3(0,.07,.2)]]:
  var m=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=parte[0]; m.mesh=b; m.material_override=preto; m.position=parte[1]; ave.add_child(m)
 for lado in [-1.0,1.0]:
  var asa=MeshInstance3D.new(); var b=BoxMesh.new(); b.size=Vector3(.42,.02,.2); asa.mesh=b; asa.material_override=preto
  asa.position=Vector3(lado*.28,0,0); asa.name="asa_"+("e" if lado<0 else "d"); ave.add_child(asa)
 ave_clock=0.0
 game.sound.emit_at("grito",ave.global_position,0)
 game.view.trauma=maxf(game.view.trauma,.55)
 assustar()

## Qualquer susto chama isto: Miguel fica lento por um instante.
func assustar(segundos:=1.2) -> void:
 susto_lento=maxf(susto_lento,segundos)

func multiplicador_velocidade() -> float:
 return LENTO if susto_lento>0 else 1.0

func tick(dt: float) -> void:
 susto_lento=maxf(0,susto_lento-dt)
 _coracao(dt)
 _ave(dt)
 if game.phase!="investigate" or game.paused or game.player.dead or game.walk_mode: return
 _parado(dt)
 _perdido(dt)

func _coracao(dt: float) -> void:
 var tensao: float=0.0
 if game.started and not game.paused and not game.player.dead:
  tensao=maxf(game.pressure.value,game.vigilance_level())
  if game.phase=="chase": tensao=maxf(tensao,.85)
  if susto_lento>0: tensao=maxf(tensao,.9)
 if tensao>.08:
  if not coracao.playing: coracao.play()
  coracao.volume_db=lerpf(-30.0,-6.0,tensao)
  coracao.pitch_scale=lerpf(1.0,2.1,tensao)   # 60 → ~126 bpm
 elif coracao.playing:
  coracao.volume_db=move_toward(coracao.volume_db,-60,dt*30)
  if coracao.volume_db<=-55: coracao.stop()

func _ave(dt: float) -> void:
 if ave_clock<0 or not is_instance_valid(ave): return
 ave_clock+=dt
 var cam: Vector3=game.view.camera.global_position
 var alvo: Vector3=cam+(cam-ave.global_position).normalized()*-.2+Vector3.UP*.4
 ave.global_position=ave.global_position.lerp(alvo,minf(1.0,dt*4.0))
 ave.look_at(alvo+Vector3.UP*.01)
 for asa in ave.get_children():
  if asa.name.begins_with("asa_"): asa.rotation.z=sin(ave_clock*38.0)*.9*(1 if asa.name=="asa_d" else -1)
 if ave_clock>.9: ave.queue_free(); ave_clock=-1.0

## Parado ou escondido por muito tempo: o cultista livre mais próximo vem rondar.
func _parado(dt: float) -> void:
 var p=game.player
 var v: float=Vector2(p.velocity.x,p.velocity.z).length()
 parado=parado+dt if v<.15 else 0.0
 if parado<PARADO_LIMITE: return
 parado=0.0
 var melhor=null; var d:=INF
 for e in game.enemies:
  if e.dead or e.down or e.aware or e.has_meta("leitor"): continue
  var dist: float=e.position.distance_to(p.position)
  if dist<d: d=dist; melhor=e
 if melhor==null: return
 var ang:=randf()*TAU
 melhor.last_seen=p.position+Vector3(cos(ang),0,sin(ang))*2.5
 melhor.memory=maxf(melhor.memory,25.0); melhor.suspicion=maxf(melhor.suspicion,.45)
 game.sound.emit_at("cimento",melhor.position,-6)

## Objetivo atual, na ordem do capítulo.
func objetivo() -> String:
 if game.cozinha!=null and game.cozinha.estado!="feito": return "cozinha"
 if not game.bag_found: return "bolsa"
 if not game.video_recorded: return "ritual"
 return "portao"

func _perdido(dt: float) -> void:
 var agora: String=objetivo()
 if agora!=objetivo_atual: objetivo_atual=agora; sem_avancar=0.0; return
 sem_avancar+=dt
 if sem_avancar>=PERDIDO_LIMITE and game.elapsed-ultimo_pensamento>=PERDIDO_INTERVALO:
  ultimo_pensamento=game.elapsed
  game.hud.say(game.objectives.text("pensamento_"+agora),6)

extends RefCounted
## Fuga final roteirizada (decisão de Felipe, 05/11/2026): depois de gravar o
## ritual, o perseguidor sempre vem. Ele fica colado atrás (~4,5 m): correndo
## para o portão, Miguel se mantém à frente; parado ou andando, é alcançado.
## Eventos pelo caminho, conforme a distância até o portão diminui:
##  75%: uma porta bate atrás de Miguel · 50%: as luzes estouram e apagam ·
##  25%: um carrinho cai ao lado do caminho · perto do portão: ele grita.
## O perseguidor nunca é finalizável; esconder-se continua possível.
## Só move corpos, toca sons e mexe em luzes/portas; nunca escreve pose de osso.

const DISTANCIA_ALVO:=4.5
const VEL_MIN:=1.8
const VEL_MAX:=4.6
const LENTO:=2.2           # m/s: abaixo disso por muito tempo, ele avança
const TOLERANCIA_LENTO:=1.4

var ativa:=false
var inicio:=0.0
var feitos: Dictionary={}
var lento_por:=0.0
var obstaculo: Node3D

func iniciar(game: Node3D) -> void:
 ativa=true; feitos.clear(); lento_por=0.0
 inicio=maxf(10.0,game.player.position.distance_to(game.school.gate_at))

func progresso(game: Node3D) -> float:
 return 1.0-clampf(game.player.position.distance_to(game.school.gate_at)/inicio,0,1)

func tick(game: Node3D,dt: float) -> void:
 var p=game.player; var q=game.pursuer
 var vel: float=velocidade(game,dt)
 q.aware=true; q.last_seen=p.position; game.pursuit_memory=12
 game._navigate(q,p.position,vel,dt)
 q.animate(dt)
 _eventos(game)

## Velocidade do perseguidor: segura ~4,5 m atrás de quem corre; quem para
## ou anda devagar por mais de 1,4 s é alcançado.
func velocidade(game: Node3D,dt: float) -> float:
 var p=game.player
 var v: float=Vector2(p.velocity.x,p.velocity.z).length()
 lento_por=lento_por+dt if v<LENTO else 0.0
 var gap: float=game.pursuer.position.distance_to(p.position)
 if lento_por>TOLERANCIA_LENTO: return VEL_MAX
 return clampf(v+(gap-DISTANCIA_ALVO)*.9,VEL_MIN,VEL_MAX)

func _eventos(game: Node3D) -> void:
 var p=game.player; var u=progresso(game)
 if u>.25 and not feitos.has("porta"):
  feitos["porta"]=true; _bater_porta(game)
 if u>.5 and not feitos.has("luzes"):
  feitos["luzes"]=true; _estourar_luzes(game)
 if u>.75 and not feitos.has("carrinho"):
  feitos["carrinho"]=true; _derrubar(game)
 if p.position.distance_to(game.school.gate_at)<7.0 and not feitos.has("grito"):
  feitos["grito"]=true
  game.sound.emit_at("grito",game.pursuer.position+Vector3.UP*2.0,0)
  game.view.trauma=maxf(game.view.trauma,.4)

## Porta aberta mais próxima, atrás de Miguel, bate sozinha.
func _bater_porta(game: Node3D) -> void:
 var p=game.player; var melhor: Node3D=null; var d:=8.0
 var frente: Vector3=(game.school.gate_at-p.position); frente.y=0; frente=frente.normalized()
 for door in game.school.doors:
  var delta: Vector3=door.position-p.position; delta.y=0
  if delta.length()<d and delta.normalized().dot(frente)<.3: d=delta.length(); melhor=door
 if melhor!=null:
  melhor.set_open(false,false)
  game.sound.emit_at("porta_fechar",melhor.position,2)
 else:
  game.sound.emit_at("impacto_parede",p.position-frente*3.0,0)
 game.view.trauma=maxf(game.view.trauma,.25)

## Lâmpadas perto de Miguel estouram e apagam.
func _estourar_luzes(game: Node3D) -> void:
 var p=game.player; var apagou:=0
 for item in game.school.lampadas:
  var l: OmniLight3D=item["luz"]
  if l.visible and l.global_position.distance_to(p.position)<12.0:
   l.visible=false; l.light_energy=0.0; game.school.lampadas_falhando.erase(item); apagou+=1
 game.sound.emit_at("impacto_metal",p.position+Vector3.UP*2.8,2)
 game.view.trauma=maxf(game.view.trauma,.3)
 return

## Carrinho tomba ao lado do caminho, à frente de Miguel (não bloqueia).
func _derrubar(game: Node3D) -> void:
 var p=game.player
 var frente: Vector3=(game.school.gate_at-p.position); frente.y=0; frente=frente.normalized()
 var lado: Vector3=frente.cross(Vector3.UP).normalized()
 var onde: Vector3=p.position+frente*3.0+lado*1.4
 if not game.visible_between(p.position+Vector3.UP*.5,onde+Vector3.UP*.5): onde=p.position+frente*3.0-lado*1.4
 obstaculo=game.school.box(Vector3(.9,.8,.55),onde+Vector3.UP*1.6,"metal",false)
 var t=obstaculo.create_tween()
 t.tween_property(obstaculo,"position",onde+Vector3.UP*.4,.35).set_ease(Tween.EASE_IN)
 t.parallel().tween_property(obstaculo,"rotation:z",1.2,.35)
 t.tween_callback(func(): game.sound.emit_at("impacto_madeira",onde,4))
 game.view.trauma=maxf(game.view.trauma,.2)

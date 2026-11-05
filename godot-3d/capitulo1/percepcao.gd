extends RefCounted
## Percepção dos cultistas (skill godot-genre-stealth): medidor gradual em vez
## de "viu/não viu". A suspeita (0–1) de cada cultista sobe conforme:
##  - quanto do Miguel aparece (cabeça, peito, pés: 3 raios contra paredes);
##  - onde ele está no campo de visão (cone central forte, periferia fraca,
##    atrás só bem de perto);
##  - distância (perto enche rápido, longe devagar);
##  - luz sobre Miguel (sombra esconde; lâmpada, vela e lanterna expõem);
##  - postura e movimento (agachado parado quase some; correndo chama atenção);
##  - barulho (correr perto é ouvido, mais fraco atrás de parede).
## Sem linha de visão a suspeita cai depois de um respiro. Cheia = viu de vez.
## Não move nem anima ninguém: só mede. A caça (caca.gd) decide o que fazer.

const ALCANCE:=12.0
const ALCANCE_PERSEGUIDOR:=18.0
const CONE_CENTRAL:=.82      # cos 35°
const CONE_PERIFERICO:=.34   # cos 70°
const PERIFERIA_ALCANCE:=.55 # fração do alcance vista pelo canto do olho
const SENTIR_ATRAS:=1.3      # metros: percebe alguém colado às costas
const TAXA:=1.25             # suspeita/s com tudo a favor (perto, claro, de frente)
const QUEDA:=.22             # suspeita/s perdida sem ver
const RESPIRO:=1.2           # s com a suspeita parada antes de começar a cair
const OUVIR_CORRIDA:=7.0
const OUVIR_ANDAR:=2.2

var luz:=0.0                 # 0 = breu, 1 = muito iluminado
var _luz_relogio:=0.0
var _lampadas: Array=[]

func setup(game: Node3D) -> void:
 _lampadas.clear()
 for l in game.school.find_children("*","OmniLight3D",true,false):
  _lampadas.append(l)

## Luz sobre Miguel, recalculada 5×/s (é a mesma para todos os cultistas).
func atualizar_luz(game: Node3D,dt: float) -> void:
 _luz_relogio-=dt
 if _luz_relogio>0: return
 _luz_relogio=.2
 var p=game.player
 var peito: Vector3=p.position+Vector3.UP*(.7 if p.crouched else 1.1)
 var total:=.12 # luar/ambiente: nunca é breu absoluto
 for l in _lampadas:
  if not is_instance_valid(l) or not l.visible or l.light_energy<=.01: continue
  var d: float=l.global_position.distance_to(peito)
  if d>l.omni_range: continue
  var forca: float=l.light_energy*pow(1.0-d/l.omni_range,1.4)
  if forca<.05: continue
  if game.visible_between(l.global_position,peito): total+=forca*.9
 if game.bag_found and game.phone_light: total+=.55 # quem segura a lanterna aparece
 luz=clampf(total,0,1)

func _postura(game: Node3D) -> float:
 var p=game.player
 var v: float=Vector2(p.velocity.x,p.velocity.z).length()
 var f:=1.0
 if v<.15: f=.7
 elif v>2.5: f=1.6
 if p.crouched: f*=.45
 return f

## Fração do corpo de Miguel que o olho do cultista enxerga (0–1).
func _exposicao(game: Node3D,e: CharacterBody3D) -> float:
 var p=game.player
 var olho: Vector3=e.bone_point("Head")
 var altura:=1.0 if p.crouched else 1.6
 var vistos:=0
 for h in [.15,altura*.6,altura]:
  if game.visible_between(olho,p.position+Vector3.UP*h): vistos+=1
 return float(vistos)/3.0

## Quanto o cultista "vê" agora (0 = nada). Usado pela caça e pelo HUD.
func olhar(game: Node3D,e: CharacterBody3D) -> float:
 var p=game.player
 if p.dead or p.hidden or game.walk_mode: return 0.0
 var delta: Vector3=p.position-e.position
 var dist: float=delta.length()
 var alcance: float=ALCANCE_PERSEGUIDOR if e.pursuer else ALCANCE
 if dist>alcance: return 0.0
 delta.y=0
 var frente: float=e.facing.dot(delta.normalized()) if delta.length()>.01 else 1.0
 var campo:=0.0
 if frente>=CONE_CENTRAL: campo=1.0
 elif frente>=CONE_PERIFERICO and dist<alcance*PERIFERIA_ALCANCE: campo=.35
 elif dist<SENTIR_ATRAS: campo=.5
 if campo<=0: return 0.0
 var exposto: float=_exposicao(game,e)
 if exposto<=0: return 0.0
 var perto: float=clampf(1.0-dist/alcance,0,1)
 perto=.25+.75*perto+(.8 if dist<2.0 else 0.0)
 # Na sombra só se vê bem de perto; na luz, de longe.
 var claro: float=lerpf(.35,1.0,luz) if dist>2.5 else 1.0
 return campo*exposto*perto*claro*_postura(game)

## Barulho de passos: correr perto é ouvido; parede abafa.
func ouvir(game: Node3D,e: CharacterBody3D) -> float:
 var p=game.player
 if p.hidden or p.crouched: return 0.0
 var v: float=Vector2(p.velocity.x,p.velocity.z).length()
 var raio:=OUVIR_CORRIDA if v>2.5 else (OUVIR_ANDAR if v>.3 else 0.0)
 var d: float=e.position.distance_to(p.position)
 if raio<=0 or d>raio: return 0.0
 var f: float=1.0-d/raio
 if not game.visible_between(e.bone_point("Head"),p.position+Vector3.UP*1.0): f*=.4
 return f*(.6 if v>2.5 else .25)

## Atualiza a suspeita de um cultista que ainda não sabe de Miguel.
## Retorna true quando ele viu de vez (suspeita cheia).
func tick(game: Node3D,e: CharacterBody3D,dt: float) -> bool:
 var visto: float=olhar(game,e)
 var ouvido: float=ouvir(game,e)
 var ganho: float=(visto*TAXA+ouvido)*dt
 if ganho>0:
  e.suspicion=minf(1.0,e.suspicion+ganho)
  e.set_meta("respiro",RESPIRO)
  # Sabe onde olhar: o ponto aproximado de onde veio o estímulo.
  e.last_seen=game.player.position; e.memory=maxf(e.memory,12.0)
 else:
  var respiro: float=float(e.get_meta("respiro",0.0))-dt
  e.set_meta("respiro",respiro)
  if respiro<=0: e.suspicion=maxf(0.0,e.suspicion-QUEDA*dt)
 return e.suspicion>=1.0

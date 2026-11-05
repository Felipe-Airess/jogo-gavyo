extends RefCounted
## Primeiro cultista, na cozinha (storyboard de Felipe,
## docs/referencias/storyboard-cozinha.png):
##  Q1 Miguel chega à porta (de costas) · Q2 por cima do ombro, o cultista corta
##  um animal na mesa · Q3 contra-plongée, ele para desconfiado · Q4 vem
##  verificar · Q5 Miguel colado na parede, encurralado: parte jogável.
## Jogo: ritmo/timing. O cultista vira o rosto de um lado para o outro; quando
## olha para longe abre uma janela curta e o jogador aperta para passar à
## próxima parede. Fora da janela, a vigilância sobe. Vigilância cheia na
## cozinha = morte direta (decisão de Felipe) e volta ao checkpoint da porta.
## Só posiciona atores e toca clipes existentes; nunca escreve pose de osso.

const Q1:=1.8
const Q2:=3.8
const Q3:=5.4
const Q4:=7.4
const JANELA_INICIAL:=1.15
const JANELA_FINAL:=.75
const OLHAR_PERTO:=Vector2(1.5,2.3)  # tempo olhando para o lado de Miguel
const PASSO_TEMPO:=.85

var game: Node3D
var estado:="espera"        # espera · cena · jogo · saida · feito
var clock:=0.0
var cultista: CharacterBody3D
var porta: Vector3
var mesa: Vector3
var coberturas: Array[Vector3]=[]
var indice:=0
var vigilancia:=0.0
var olhando_longe:=false
var ciclo:=0.0
var ciclo_fim:=2.0
var passo:=-1.0
var passo_de: Vector3
var bipe:=0.0
var corte:=0.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 var s=game.school
 var sala: Dictionary=s.rooms.get("Cozinha",{})
 if sala.is_empty(): estado="feito"; return
 for d in s.doors:
  if d.title=="Cozinha": porta=d.position
 var rect: Rect2=sala["rect"]
 mesa=s.cel(rect.get_center().x,rect.get_center().y)
 for v in s.andares[0].celulas("%"):
  if rect.has_point(Vector2(v)): mesa=s.cel(v.x,v.y); break
 # Coberturas ao longo da parede da porta, do batente até o canto.
 var dentro: Vector3=Vector3(porta.x,0,porta.z+.95)
 # Para longe da mesa: Miguel se afasta do cultista, colado na parede da porta.
 var lado:=1.0 if porta.x>=mesa.x else -1.0
 var limite: float=(rect.end.x+s.ORIGEM.x-.6) if lado>0 else (rect.position.x+s.ORIGEM.x+.6)
 for i in 4:
  var x: float=dentro.x+lado*(1.1+i*1.7)
  x=minf(x,limite) if lado>0 else maxf(x,limite)
  coberturas.append(Vector3(x,0,dentro.z))
 cultista=game.PERSON.new(); cultista.cinematic_friend=true
 game.add_child(cultista); cultista.setup(game,mesa+Vector3(0,0,.75),true)
 cultista.collision_layer=0; cultista.collision_mask=0
 for area in cultista.hurt_areas: area.collision_layer=0; area.collision_mask=0
 cultista.face(mesa,1.0)

func entrou() -> bool:
 return estado=="espera" and game.player.position.distance_to(porta)<1.7 and game.player.position.y<1.0

func iniciar() -> void:
 estado="cena"; clock=0.0; indice=0; vigilancia=0.0; passo=-1.0; corte=0.0
 var p=game.player
 p.velocity=Vector3.ZERO; p.state="intro"
 p.position=Vector3(porta.x,0,porta.z-.6)
 p.face(mesa,1.0)
 cultista.position=mesa+Vector3(0,0,.75); cultista.face(mesa,1.0)

func tick(dt: float) -> void:
 clock+=dt
 var p=game.player
 if estado=="cena":
  if clock<Q1:
   p.velocity=Vector3(0,0,.7); p.position+=p.velocity*dt; p.play("andaFrente")
  elif clock<Q3:
   p.velocity=Vector3.ZERO; p.play("guarda")
  if clock<Q3:
   _cortar(dt)
  elif clock<Q4:
   # Para, desconfiado, e vem verificar.
   if clock-dt<Q3: cultista.play("guarda")
   var alvo: Vector3=Vector3(porta.x,0,porta.z+2.0)
   if clock>Q3+.7:
    var dir: Vector3=alvo-cultista.position; dir.y=0
    cultista.velocity=dir.normalized()*.9 if dir.length()>.2 else Vector3.ZERO
    cultista.position+=cultista.velocity*dt
    cultista.play("andaFrente" if cultista.velocity!=Vector3.ZERO else "guarda")
   cultista.face(p.position,dt)
   if clock>Q3+.9 and p.position.distance_to(coberturas[0])>.05:
    p.position=coberturas[0]; p.crouched=true; p.velocity=Vector3.ZERO
    p.face(p.position+Vector3(0,0,1),1.0)
  else:
   estado="jogo"; clock=0.0; _novo_ciclo(false)
 elif estado=="jogo":
  ciclo+=dt
  if ciclo>=ciclo_fim: _novo_ciclo(not olhando_longe)
  var foco: Vector3=coberturas[indice]+Vector3(-3.0 if olhando_longe else 0.0,0,0)
  if not olhando_longe: foco=p.position
  cultista.velocity=Vector3.ZERO; cultista.play("guarda")
  cultista.face(foco if not olhando_longe else cultista.position+(cultista.position-p.position)*Vector3(1,0,1),dt*.5)
  if passo>=0:
   passo+=dt
   var u=clampf(passo/PASSO_TEMPO,0,1)
   p.position=passo_de.lerp(coberturas[mini(indice,coberturas.size()-1)],u)
   p.velocity=(coberturas[mini(indice,coberturas.size()-1)]-passo_de)/PASSO_TEMPO
   p.play("andaFrente")
   if not olhando_longe: vigilancia+=dt*.9
   if u>=1.0:
    passo=-1.0; p.velocity=Vector3.ZERO; p.play("guarda")
    if indice>=coberturas.size()-1: estado="saida"; clock=0.0
  else:
   p.velocity=Vector3.ZERO
   if not olhando_longe: vigilancia+=dt*.05
   else: vigilancia=maxf(0,vigilancia-dt*.12)
  _bipar(dt)
  if vigilancia>=1.0: _morrer()
 elif estado=="saida":
  # Ele desiste e volta à mesa; Miguel sai pela porta.
  var dir: Vector3=mesa+Vector3(0,0,.75)-cultista.position; dir.y=0
  if dir.length()>.2:
   cultista.velocity=dir.normalized()*1.0; cultista.position+=cultista.velocity*dt
   cultista.play("andaFrente"); cultista.face(mesa+Vector3(0,0,.75),dt)
  else:
   cultista.velocity=Vector3.ZERO; _cortar(dt)
  vigilancia=maxf(0,vigilancia-dt*.5)
  if clock>3.0:
   estado="feito"
   p.crouched=false; p.state="idle"
   p.position=Vector3(porta.x,0,porta.z-1.1)
   game.cozinha_concluida()
 p.animate(dt)
 cultista.animate(dt)

func _cortar(dt: float) -> void:
 corte-=dt
 cultista.face(mesa,dt)
 if corte<=0:
  var clipe: Animation=cultista.anim.get_animation("novo/TreeChopping")
  corte=clipe.length/1.4 if clipe else .9
  cultista.start_action("novo/TreeChopping",1.4)
  game.sound.emit_at("impacto_madeira",mesa+Vector3.UP,-6)

func _novo_ciclo(longe: bool) -> void:
 olhando_longe=longe; ciclo=0.0
 var progresso=float(indice)/maxf(1,coberturas.size()-1)
 ciclo_fim=lerpf(JANELA_INICIAL,JANELA_FINAL,progresso) if longe else randf_range(OLHAR_PERTO.x,OLHAR_PERTO.y)

## Espaço/toque: só passa se ele estiver olhando para longe.
func apertar() -> void:
 if estado!="jogo" or passo>=0: return
 if olhando_longe:
  passo_de=game.player.position; indice+=1; passo=0.0
  game.sound.ui("seta")
 else:
  vigilancia=minf(1.0,vigilancia+.45)
  game.sound.ui("erro")

func _bipar(dt: float) -> void:
 if vigilancia<.25: return
 bipe-=dt
 if bipe<=0:
  bipe=lerpf(.9,.16,vigilancia)
  game.sound.ui("seta")

func _morrer() -> void:
 estado="espera"; vigilancia=0.0
 game.morte_direta()

func janela_aberta() -> bool:
 return estado=="jogo" and olhando_longe and passo<0

## Enquadramento: [posição, alvo, fov].
func shot() -> Array:
 var p=game.player
 var head: Vector3=p.bone_point("Head")
 var ch: Vector3=cultista.bone_point("Head")
 if estado=="cena":
  if clock<Q1: return [p.position+Vector3(0,1.55,-1.6),p.position+Vector3(0,1.2,1.5),52.0]
  if clock<Q2: return [head+Vector3(-.5,.12,-.45),ch,40.0]
  if clock<Q3: return [mesa+Vector3(1.5,.25,2.3),ch,48.0]
  if clock<Q3+.9: return [cultista.position+Vector3(-1.2,1.6,1.8),ch,50.0]
 # Q5 e jogo: plano vertical, Miguel colado na parede, cultista do outro lado.
 var meio: Vector3=(p.position+cultista.position)*.5
 var fundo: float=game.school.rooms["Cozinha"]["rect"].end.y+game.school.ORIGEM.z-.4
 return [Vector3(meio.x+.8,2.3,minf(meio.z+2.6,fundo)),Vector3(meio.x,.9,p.position.z),60.0]

func save_state() -> Dictionary: return {"estado":estado if estado=="feito" else "espera"}
func load_state(data: Dictionary) -> void:
 estado=str(data.get("estado","espera")); clock=0.0; vigilancia=0.0; passo=-1.0
 if is_instance_valid(cultista):
  cultista.position=mesa+Vector3(0,0,.75); cultista.velocity=Vector3.ZERO; cultista.face(mesa,1.0)

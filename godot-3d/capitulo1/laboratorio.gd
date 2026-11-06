extends RefCounted
## Laboratório — "Trancado por dentro" (aprovado por Felipe, 05/11/2026).
## Miguel pega a pista da ave no Laboratório de matemática. Um cultista entra
## logo atrás e tranca a porta. Miguel tem poucos segundos para se esconder
## atrás da bancada ([Espaço]). Escondido, precisa ficar PARADO: qualquer
## tecla de movimento enche a vigilância. O cultista mexe nos frascos em três
## pontos, cada vez mais perto, e depois sai deixando a porta aberta.
## Vigilância cheia = morte direta (como na cozinha) e volta ao checkpoint.
## Só posiciona atores e câmera; nunca escreve pose de osso.

const SALA:="Laboratório de matemática"
const ENTRA:=3.2          # cultista abre, entra e tranca
const PRAZO_ESCONDER:=3.0 # tempo para apertar [Espaço]
const MEXER:=4.5          # segundos em cada ponto, mexendo nos frascos
const ANDAR:=.8

var game: Node3D
var estado:="espera"      # espera · entra · esconder · escondido · sai · feito
var clock:=0.0
var rect: Rect2
var porta: Node3D
var bancada: Vector3
var esconderijo: Vector3
var pontos: Array[Vector3]=[]
var indice:=0
var cultista: CharacterBody3D
var vigilancia:=0.0
var _bipe:=0.0
var _tinido:=0.0

func setup(owner_game: Node3D) -> void:
 game=owner_game
 var s=game.school
 if not s.rooms.has(SALA): estado="feito"; return
 rect=s.rooms[SALA]["rect"]
 for d in s.doors:
  if d.title==SALA: porta=d
 bancada=s.rooms[SALA]["center"]
 for v in s.andares[0].celulas("%"):
  if rect.has_point(Vector2(v)): bancada=s.cel(v.x,v.y); break
 # Esconderijo: do lado da bancada oposto à porta.
 var da_porta: Vector3=bancada-porta.position; da_porta.y=0
 esconderijo=bancada+da_porta.normalized()*.85
 # Pontos dos frascos: longe → perto do esconderijo.
 var dentro: Vector3=porta.position+(s.rooms[SALA]["center"]-porta.position).normalized()*1.2; dentro.y=0
 pontos=[s.cel(rect.position.x+1,rect.position.y+.5),s.cel(rect.end.x-2,rect.position.y+.5),
  esconderijo+(dentro-esconderijo).normalized()*1.3]
 pontos.append(dentro)
 cultista=game.PERSON.new(); cultista.cinematic_friend=true
 game.add_child(cultista); cultista.setup(game,porta.position+Vector3(0,0,1.5),true)
 cultista.collision_layer=0; cultista.collision_mask=0
 for area in cultista.hurt_areas: area.collision_layer=0; area.collision_mask=0
 cultista.visible=false

## Disparo: a pista da ave 2 é pega dentro do laboratório.
func pronto_para_disparar() -> bool:
 return estado=="espera" and "pista_2" in game.objectives.collected and game.school.ambiente_de(game.player.position)==SALA and not game.objectives.modal

func iniciar() -> void:
 estado="entra"; clock=0.0; indice=0; vigilancia=0.0
 var p=game.player; p.velocity=Vector3.ZERO; p.state="intro"
 cultista.position=porta.position-(game.school.rooms[SALA]["center"]-porta.position).normalized()*1.2
 cultista.position.y=0; cultista.visible=true
 porta.set_open(true,false)
 game.sound.emit_at("porta_abrir",porta.position,-4)

func tick(dt: float) -> void:
 clock+=dt
 var p=game.player
 if estado=="entra":
  var alvo: Vector3=pontos[3]
  _andar(alvo,dt)
  if clock>ENTRA*.7 and porta.opened:
   porta.set_open(false,false); porta.locked=true
   game.sound.emit_at("armario_fechar",porta.position,-2) # trinco
  p.face(cultista.position,dt); p.play("guarda")
  if clock>=ENTRA: estado="esconder"; clock=0.0
 elif estado=="esconder":
  cultista.velocity=Vector3.ZERO; cultista.play("guarda"); cultista.face(pontos[0],dt*.5)
  if clock>=PRAZO_ESCONDER: _morrer(); return
 elif estado=="escondido":
  p.position=esconderijo; p.velocity=Vector3.ZERO; p.crouched=true; p.play("guarda")
  var alvo: Vector3=pontos[indice]
  if cultista.position.distance_to(alvo)>.25:
   _andar(alvo,dt)
  else:
   cultista.velocity=Vector3.ZERO; cultista.play("guarda")
   cultista.face(bancada if indice==2 else alvo+Vector3(0,0,-1),dt)
   _tinido-=dt
   if _tinido<=0: _tinido=.9; game.sound.emit_at("impacto_metal",cultista.position+Vector3.UP*1.0,-14)
   if clock>=MEXER:
    clock=0.0; indice+=1
    if indice>=3: estado="sai"; clock=0.0; porta.locked=false; porta.set_open(true,false)
  # Ficar parado: tecla de movimento enche a vigilância; perto dele, até
  # parado a tensão sobe devagar.
  var movendo: bool=Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_SHIFT)
  var perto: float=cultista.position.distance_to(esconderijo)
  if movendo: vigilancia+=dt*(.9 if perto<3.0 else .45)
  elif perto<2.2: vigilancia+=dt*.04
  else: vigilancia=maxf(0,vigilancia-dt*.1)
  _bipar(dt)
  if vigilancia>=1.0: _morrer(); return
 elif estado=="sai":
  _andar(porta.position+(porta.position-game.school.rooms[SALA]["center"]).normalized()*2.0,dt)
  vigilancia=maxf(0,vigilancia-dt*.4)
  if clock>3.5:
   estado="feito"; cultista.visible=false
   p.crouched=false; p.state="idle"; p.hidden=false
   game.laboratorio_concluido()
 p.animate(dt); cultista.animate(dt)

func _andar(alvo: Vector3,dt: float) -> void:
 var dir: Vector3=alvo-cultista.position; dir.y=0
 if dir.length()<.2: cultista.velocity=Vector3.ZERO; cultista.play("guarda"); return
 cultista.velocity=dir.normalized()*ANDAR
 cultista.position+=cultista.velocity*dt
 cultista.play("andaFrente"); cultista.face(alvo,dt)

## [Espaço] na hora de esconder: atrás da bancada.
func apertar() -> void:
 if estado!="esconder": return
 estado="escondido"; clock=0.0
 var p=game.player
 p.position=esconderijo; p.crouched=true; p.hidden=true
 p.face(bancada,1.0)
 game.sound.emit_at("roupa",esconderijo,-8)

func _bipar(dt: float) -> void:
 if vigilancia<.25: return
 _bipe-=dt
 if _bipe<=0: _bipe=lerpf(.9,.16,vigilancia); game.sound.ui("seta")

func _morrer() -> void:
 estado="espera"; vigilancia=0.0
 porta.locked=false
 game.player.hidden=false
 game.morte_direta()

func load_state(data: Dictionary) -> void:
 estado=str(data.get("estado","espera")); clock=0.0; vigilancia=0.0
 if is_instance_valid(cultista): cultista.visible=false
 if is_instance_valid(porta): porta.locked=false
func save_state() -> Dictionary: return {"estado":"feito" if estado=="feito" else "espera"}

## Enquadramento: [posição, alvo, fov].
func shot() -> Array:
 var p=game.player
 var ch: Vector3=cultista.bone_point("Head")
 if estado=="entra": return [bancada+Vector3(0,1.9,0)+(bancada-porta.position).normalized()*1.5,cultista.position+Vector3.UP*1.4,60.0]
 if estado=="esconder": return [p.position+Vector3(0,1.6,0)-(cultista.position-p.position).normalized()*1.2,cultista.position+Vector3.UP*1.3,55.0]
 # Escondido: olho baixo atrás da bancada; o cultista aparece por cima dela.
 var frente: Vector3=(bancada-esconderijo); frente.y=0; frente=frente.normalized()
 var lado: Vector3=frente.cross(Vector3.UP).normalized()
 var olho: Vector3=esconderijo+lado*.65-frente*.25+Vector3.UP*.7
 return [olho,(cultista.position+Vector3.UP*1.1).lerp(ch,.4),64.0]

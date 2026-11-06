extends RefCounted
## Biblioteca — "O leitor" (aprovado por Felipe, 05/11/2026).
## Estantes em fileiras, com corredores entre elas. Um cultista anda devagar
## pelos corredores lendo em voz baixa e para em pontos fixos. Miguel usa
## distração (jogar um livro para um lado e passar pelo outro) para chegar ao
## fundo, onde estão a pista da ave e uma nota do culto (opcionais).
## O leitor é um cultista comum: percepção, caça e agarrão são os de sempre.
## Só monta cenário e rota; nunca escreve pose de osso.

const ESTANTE_ALTURA:=1.9
const ESTANTE_FUNDO:=.5
const PARADA:=Vector2(3.0,5.5)   # segundos lendo em cada ponto
const VELOCIDADE:=.7

var game: Node3D
var rect: Rect2
var leitor: CharacterBody3D
var rota: Array[Vector3]=[]
var estantes: Array[Node3D]=[]

func setup(owner_game: Node3D) -> void:
 game=owner_game
 var s=game.school
 if not s.rooms.has("Biblioteca"): push_warning("Biblioteca ausente no mapa"); return
 rect=s.rooms["Biblioteca"]["rect"]
 var porta_x:=rect.get_center().x
 for d in s.doors:
  if d.title=="Biblioteca": porta_x=d.position.x-s.ORIGEM.x
 # Estantes a cada 3 m, de fora a fora, deixando corredor no fundo e na
 # frente, e livre a área da porta.
 var x:=rect.position.x+2.0
 while x<rect.end.x-1.5:
  if absf(x+.5-porta_x)>3.2:
   var a: Vector3=s.cel(x,rect.position.y+1)
   var b: Vector3=s.cel(x,rect.end.y-2)
   var centro: Vector3=(a+b)*.5
   var comprimento: float=absf(b.z-a.z)+1.0
   var e=s.box(Vector3(ESTANTE_FUNDO,ESTANTE_ALTURA,comprimento),centro+Vector3.UP*ESTANTE_ALTURA*.5,"wood",true)
   estantes.append(e)
   # Livros: faixas escuras nas prateleiras (leitura de "estante").
   for h in [.45,.95,1.45]:
    for lado in [-1.0,1.0]:
     s.box(Vector3(.06,.32,comprimento-.15),centro+Vector3(lado*(ESTANTE_FUNDO*.5+.02),h,0),"dark",false)
  x+=3.0
 # Rota do leitor: corredor do fundo, ponta a ponta, voltando pela frente.
 var fundo:=rect.position.y
 var frente:=rect.end.y-1
 rota=[s.cel(rect.position.x+1.5,fundo),s.cel(porta_x-4.5,fundo),s.cel(porta_x+4.5,fundo),
  s.cel(rect.end.x-2.0,fundo),s.cel(rect.end.x-2.0,frente),s.cel(porta_x+4.5,frente),
  s.cel(porta_x-4.5,frente),s.cel(rect.position.x+1.5,frente)]

## Cria o leitor como 8º cultista comum (dentro de 6–8, decisão de Felipe).
func criar_leitor() -> void:
 if rota.is_empty(): return
 leitor=game.spawn_actor(rota[0],true)
 leitor.home=rota[0]
 leitor.set_meta("rota",rota)
 leitor.set_meta("leitor",true)
 game.enemies.append(leitor)

## Patrulha por pontos com paradas de leitura. Chamado pela caça (caca.gd)
## quando o cultista não sabe de Miguel e não está desconfiado.
static func patrulhar(game: Node3D,e: CharacterBody3D,dt: float) -> void:
 var pontos: Array=e.get_meta("rota")
 var i: int=int(e.get_meta("rota_i",0))
 var parado: float=float(e.get_meta("rota_parado",0.0))
 if parado>0:
  e.set_meta("rota_parado",parado-dt)
  e.velocity=Vector3.ZERO; e.play("guarda")
  # Lendo: corpo virado para a estante mais próxima (sem osso procedural).
  e.face(e.position+Vector3(sin(float(i)*1.7),0,cos(float(i)*1.7)),dt*.4)
  if int(parado*10)%27==0: game.sound.emit_at("roupa",e.position+Vector3.UP*1.6,-20)
  return
 var alvo: Vector3=pontos[i]
 if e.position.distance_to(alvo)<.3:
  e.set_meta("rota_i",(i+1)%pontos.size())
  e.set_meta("rota_parado",randf_range(PARADA.x,PARADA.y))
  e.home=alvo
  return
 e.state="hunt"
 game._navigate(e,alvo,VELOCIDADE,dt)

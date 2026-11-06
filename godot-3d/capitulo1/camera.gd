extends "res://prototipo/camera.gd"
## Enquadramentos próprios do capítulo; ombro/fuga/frestas continuam compartilhados.
func update(dt: float) -> void:
 camera.h_offset=0; camera.v_offset=0
 _update_chapter(dt)
 if game.pressure.value>0 and not game.paused and game.phase in ["investigate","chase"]:
  # Desvio óptico de até 4,5 mm; nunca move corpo, ossos ou colisão da câmera.
  var amplitude=game.pressure.value*.0045
  camera.h_offset+=sin(game.elapsed*19.3)*amplitude
  camera.v_offset=sin(game.elapsed*23.1+.7)*amplitude*.65

func _update_chapter(dt: float) -> void:
 if not game.started:
  _titulo(dt); return
 if game.recording and game.phase=="investigate":
  mode="recording"
  camera.global_position=game.recording_eye()
  camera.look_at(camera.global_position+direction()*5)
  camera.fov=55
  game.player.model.visible=false
  _update_occluders()
  previous_mode=mode
  return
 if game.phase not in ["intro","sighting","discovery","gate_jump","ending","cozinha","duto","laboratorio"]:
  super.update(dt)
  return
 mode=game.phase
 var at=Vector3.ZERO
 var target: Vector3=game.player.position+Vector3.UP*1.2
 var fov=58.0
 game.player.model.visible=true
 if mode=="intro" and game.abertura!=null:
  var shot: Array=game.abertura.shot(); at=shot[0]; target=shot[1]; fov=shot[2]
 elif mode=="laboratorio" and game.laboratorio!=null:
  var shot: Array=game.laboratorio.shot(); at=shot[0]; target=shot[1]; fov=shot[2]
 elif mode=="duto" and game.ventilacao!=null:
  var shot: Array=game.ventilacao.shot(); at=shot[0]; target=shot[1]; fov=shot[2]
 elif mode=="cozinha" and game.cozinha!=null:
  var shot: Array=game.cozinha.shot(); at=shot[0]; target=shot[1]; fov=shot[2]
 elif mode=="sighting":
  at=game.player.position+Vector3.UP*1.6
  target=at+direction()*4
  game.player.model.visible=false
 elif mode=="discovery":
  var pursuer=game.pursuer
  var t=game.discovery_clock
  var offset: Vector3=(game.player.position-pursuer.position).normalized()
  if t<1.1:
   at=pursuer.position+offset*1.25+Vector3.UP*.20
   target=pursuer.position+Vector3.UP*.15
  elif t<2.2 or (t>=3.3 and t<4.4):
   at=game.player.position+Vector3(-1.2,1.5,1.2)
   target=game.player.bone_point("RightHand")
  elif t<3.3:
   target=pursuer.bone_point("RightHand")
   at=target+offset*.8+Vector3.UP*.1
  elif t<5.7:
   target=pursuer.bone_point("Head")
   at=target+offset*.65
   fov=42
  else:
   at=game.player.position+Vector3(-.75,1.5,1.1)
   target=game.player.bone_point("Head")
 elif mode=="gate_jump":
  at=game.school.gate_at+Vector3(3,2.8,3.5)
  target=game.player.position+Vector3.UP*.9
 elif mode=="ending":
  var shot: Array=_final(game.ending_clock); at=shot[0]; target=shot[1]; fov=shot[2]
 camera.global_position=at
 if at.distance_squared_to(target)>.0001: camera.look_at(target)
 camera.fov=lerpf(camera.fov,fov,1-exp(-9*dt))
 _update_occluders()
 previous_mode=mode

## Tela de título: passeio lento pela escola à noite (neblina, luar).
func _titulo(dt: float) -> void:
 mode="titulo"
 var t: float=Time.get_ticks_msec()/1000.0
 var centro: Vector3=game.NIVEL.ponto(game.school,"patio_aberto")
 var at: Vector3=centro+Vector3(sin(t*.045)*9.0,3.2+sin(t*.07)*.4,cos(t*.045)*9.0)
 camera.global_position=at
 camera.look_at(centro+Vector3(0,2.0,0))
 camera.fov=55
 game.player.model.visible=false

## Final cinematográfico (decisão de Felipe: mesmo roteiro, mais cinema).
## [posição, alvo, fov] por plano; cortes secos entre planos.
func _final(t: float) -> Array:
 var casa: Vector3=game.ending_set.house_at
 var p=game.player
 var fora: Vector3=p.position-game.school.gate_at; fora.y=0; fora=fora.normalized()
 var lado: Vector3=fora.cross(Vector3.UP).normalized()
 if t<3.5:
  # Rua, câmera baixa: Miguel do lado de fora; a escola e o perseguidor atrás da grade.
  var peito: Vector3=p.position+Vector3.UP*1.2
  for c in [fora*3.2+lado*1.3+Vector3.UP*.45,fora*3.2-lado*1.3+Vector3.UP*.45,fora*2.2+Vector3.UP*1.0,fora*1.4+Vector3.UP*1.6,Vector3.UP*2.6+fora*.6]:
   var pos: Vector3=p.position+c
   if game.visible_between(pos,peito) and game.visible_between(pos,game.school.gate_at+Vector3.UP*1.9):
    return [pos,game.school.gate_at+Vector3.UP*1.9,52.0]
  return [p.position+fora*1.2+Vector3.UP*1.7,game.school.gate_at+Vector3.UP*1.9,58.0]
 if t<6.5:
  var mao: Vector3=p.bone_point("RightHand")
  return [mao+(fora+lado*.6).normalized()*.55+Vector3.UP*.25,mao,38.0]
 if t<9.5:
  var u: float=clampf((t-6.5)/3.0,0,1)
  return [(casa+Vector3(8,6,14)).lerp(casa+Vector3(4.5,3.2,8.5),u),casa+Vector3(0,1,0),50.0]
 if t<13.0:
  var u2: float=clampf((t-9.5)/3.5,0,1)
  var fone: Vector3=game.ending_set.phone.global_position
  return [(casa+Vector3(-1.2,1.7,2.8)).lerp(fone+Vector3(.5,.45,.55),u2),fone.lerp(casa+Vector3(-2.6,1.0,-1.5),1.0-u2),48.0]
 if t<16.0 and is_instance_valid(game.ending_set.felipe):
  var h: Vector3=game.ending_set.felipe.bone_point("Head")
  return [h+Vector3(.15,0,.85),h,36.0]
 return [casa+Vector3(0,2.2,3.2),casa+Vector3(0,1,-.5),55.0]

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
 if game.recording and game.phase=="investigate":
  mode="recording"
  camera.global_position=game.recording_eye()
  camera.look_at(camera.global_position+direction()*5)
  camera.fov=55
  game.player.model.visible=false
  _update_occluders()
  previous_mode=mode
  return
 if game.phase not in ["intro","sighting","discovery","gate_jump","ending","cozinha","duto"]:
  super.update(dt)
  return
 mode=game.phase
 var at=Vector3.ZERO
 var target: Vector3=game.player.position+Vector3.UP*1.2
 var fov=58.0
 game.player.model.visible=true
 if mode=="intro" and game.abertura!=null:
  var shot: Array=game.abertura.shot(); at=shot[0]; target=shot[1]; fov=shot[2]
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
  if game.ending_clock<4:
   at=game.player.position+Vector3(1.1,1.6,1.5)
   target=game.player.bone_point("RightHand")
  elif game.ending_clock<7:
   at=game.ending_set.house_at+Vector3(8,6,14)
   target=game.ending_set.house_at+Vector3(0,1,0)
  else:
   at=game.ending_set.house_at+Vector3(0,2.2,3.2)
   target=game.ending_set.house_at+Vector3(0,1,-.5)
 camera.global_position=at
 if at.distance_squared_to(target)>.0001: camera.look_at(target)
 camera.fov=lerpf(camera.fov,fov,1-exp(-9*dt))
 _update_occluders()
 previous_mode=mode

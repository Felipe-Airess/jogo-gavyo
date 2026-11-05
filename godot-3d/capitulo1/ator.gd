extends "res://prototipo/actor.gd"
## Variações derivadas em memória: preserva arquivo e malhas aprovados de Miguel.
var hunt=preload("res://capitulo1/caca.gd").new()
var hunt_voice: AudioStreamPlayer3D
var style := 0
var bleed := 0.0
var help_clock := 0.0
var knocked_before := false
var tool_pose := false
var alert_attempt := false
var cinematic_friend:=false
var activity:=""
var evidence: Dictionary={}

const DEFINITIVE=preload("res://capitulo1/modelos_definitivos.gd")
var model_role:=""
func _role() -> String:
 if not model_role.is_empty(): return model_role
 return "cultista_perseguidor" if pursuer else "cultista" if enemy else "miguel"
func _instantiate_model() -> Node3D:
 return DEFINITIVE.instantiate(_role())
func _physical_height() -> float:
 return float(DEFINITIVE.data(_role()).altura)*.94

func make_down() -> void:
 super.make_down()
 for area in hurt_areas: area.collision_layer=4
 knocked_before=true
 help_clock=0

func fist_point() -> Vector3:
 if strike_bone in ["RightFoot","LeftFoot"]:
  var foot=bone_point(strike_bone)
  return foot+(foot-bone_point("RightLowerLeg" if strike_bone=="RightFoot" else "LeftLowerLeg")).normalized()*.08
 return super.fist_point()

func animate(dt: float) -> void:
 motion.advance(dt)
 if warning:
  warning.visible=not dead and not down and (state=="windup" or opening>0 or (suspicion>.1 and not aware))
  warning.text="!" if state=="windup" else "?"

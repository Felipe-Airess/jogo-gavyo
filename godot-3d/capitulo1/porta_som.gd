extends "res://prototipo/door.gd"
## O som acompanha toda mudança real: jogador, cultista ou ferramenta.
var locked:=false
func set_open(value: bool,instant:=false) -> void:
 if value and locked and not game.walk_mode: return
 var changed=value!=opened
 super.set_open(value,instant)
 if changed and not instant and game.sound!=null:
  game.sound.emit_at("porta_abrir" if value else "porta_fechar",center())

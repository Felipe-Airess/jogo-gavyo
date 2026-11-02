extends "res://prototipo/door.gd"
## O som acompanha toda mudança real: jogador, cultista ou ferramenta.
func set_open(value: bool,instant:=false) -> void:
 var changed=value!=opened
 super.set_open(value,instant)
 if changed and not instant and game.sound!=null:
  game.sound.emit_at("porta_abrir" if value else "porta_fechar",center())

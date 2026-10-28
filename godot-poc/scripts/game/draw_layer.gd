extends Node2D
## Camada de desenho imediato: chama `painter(self)` a cada redesenho.
var painter: Callable

func _draw() -> void:
	if painter.is_valid():
		painter.call(self)

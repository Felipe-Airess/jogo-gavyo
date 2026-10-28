extends Control
## Controles de toque (port de touch-controls.mjs) com multitoque nativo: cada
## dedo é uma fonte; direcional por posição dentro do círculo, botões seguram
## enquanto o dedo estiver neles. Golpes viram pulsos (um por toque).
signal pause_pressed

const PixelFont = preload("res://scripts/game/pixel_font.gd")
const PULSES := ["attack", "kick", "grab"]
const BUTTONS := [
	{"action": "attack", "label": "SOCO", "pos": Vector2(-62, -46), "r": 24.0},
	{"action": "kick", "label": "CHUTE", "pos": Vector2(-118, -30), "r": 24.0},
	{"action": "grab", "label": "AGARRA", "pos": Vector2(-36, -104), "r": 19.0},
	{"action": "guard", "label": "DEFESA", "pos": Vector2(-90, -96), "r": 19.0},
	{"action": "run", "label": "CORRE", "pos": Vector2(-144, -86), "r": 17.0},
]
const PAD_CENTER := Vector2(70, -70)
const PAD_R := 46.0

var sources := {}   # índice do dedo -> {ação: true}
var pulses := {}
var pause_rect := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func held() -> Dictionary:
	var out := {}
	for s in sources.values():
		for k in s:
			if s[k]: out[k] = true
	return out

func read() -> Dictionary:
	var out := held()
	for k in PULSES:
		out[k] = pulses.has(k)
	pulses.clear()
	return out

func clear() -> void:
	sources.clear(); pulses.clear(); queue_redraw()

## Tamanho pela tela: os valores acima valem para ~300 px no menor lado.
func k() -> float: return clampf(minf(size.x, size.y) / 300.0, 1.0, 5.0)
func pad_r() -> float: return PAD_R * k()
func pad_center() -> Vector2: return Vector2(PAD_CENTER.x * k(), size.y + (PAD_CENTER.y - 14) * k())
func button_center(b: Dictionary) -> Vector2: return Vector2(size.x + b.pos.x * k(), size.y + (b.pos.y - 14) * k())

func values_at(p: Vector2) -> Dictionary:
	var c := pad_center()
	if p.distance_to(c) <= pad_r() * 1.4:
		var d := (p - c) / pad_r()
		return {"left": d.x < -0.32, "right": d.x > 0.32, "up": d.y < -0.32, "down": d.y > 0.32}
	for b in BUTTONS:
		if p.distance_to(button_center(b)) <= b.r * k() * 1.15:
			return {b.action: true}
	return {}

func set_source(index: int, values: Dictionary) -> void:
	var before := held()
	sources[index] = values
	for k in PULSES:
		if values.get(k, false) and not before.get(k, false): pulses[k] = true
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventScreenTouch:
		if event.pressed:
			if pause_rect.has_point(event.position):
				pause_pressed.emit(); get_viewport().set_input_as_handled(); return
			var v := values_at(event.position)
			if not v.is_empty():
				set_source(event.index, v); get_viewport().set_input_as_handled()
		elif sources.has(event.index):
			sources.erase(event.index); queue_redraw()
	elif event is InputEventScreenDrag and sources.has(event.index):
		var current: Dictionary = sources[event.index]
		# O direcional acompanha o dedo; um botão solto ao arrastar para fora.
		if current.has("left") or current.has("right") or current.has("up") or current.has("down"):
			var c := pad_center()
			var d: Vector2 = (event.position - c) / pad_r()
			sources[event.index] = {"left": d.x < -0.32, "right": d.x > 0.32, "up": d.y < -0.32, "down": d.y > 0.32}
		elif values_at(event.position) != current:
			sources.erase(event.index)
		queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		clear()

func _draw() -> void:
	var h := held()
	var c := pad_center()
	var s := k()
	draw_circle(c, pad_r(), Color(0.08, 0.13, 0.12, 0.45))
	draw_arc(c, pad_r(), 0, TAU, 32, Color(0.75, 0.78, 0.6, 0.5), 2.0)
	for dir in [["up", Vector2(0, -1)], ["down", Vector2(0, 1)], ["left", Vector2(-1, 0)], ["right", Vector2(1, 0)]]:
		var on: bool = h.get(dir[0], false)
		draw_circle(c + dir[1] * pad_r() * 0.62, 11 * s, Color(0.83, 0.75, 0.5, 0.85) if on else Color(0.55, 0.6, 0.5, 0.35))
	for b in BUTTONS:
		var bc := button_center(b)
		var on2: bool = h.get(b.action, false)
		draw_circle(bc, b.r * s, Color(0.83, 0.75, 0.5, 0.8) if on2 else Color(0.08, 0.13, 0.12, 0.55))
		draw_arc(bc, b.r * s, 0, TAU, 28, Color(0.8, 0.8, 0.65, 0.6), 2.0)
		PixelFont.centered(self, b.label, bc.x, bc.y - 2.5 * s, Color(0.1, 0.12, 0.1) if on2 else Color(0.87, 0.85, 0.7), s)
	pause_rect = Rect2(size.x - 64 * s, 34 * s, 56 * s, 18 * s)
	draw_rect(pause_rect, Color(0.08, 0.13, 0.12, 0.55))
	PixelFont.centered(self, "PAUSA", pause_rect.get_center().x, pause_rect.get_center().y - 2.5 * s, Color(0.87, 0.85, 0.7), s)

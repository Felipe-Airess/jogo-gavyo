extends Node2D
const Combat = preload("res://scripts/combat.gd")
var combat = Combat.new()
var atlas: Texture2D = preload("res://assets/sorriso.png")
var held := {}
var fingers := {}
const TOUCH_KEYS = ["left", "right", "jab", "cross", "dodge", "guard", "pause", "reset", "debug"]
var pulses: Array = []
var paused := false
var debug_boxes := false
var buttons: Array[Button] = []
var labels: Array[Label] = []
var hud: Label
var status: Label
var qa := false

func _ready() -> void:
	if OS.has_feature("web"):
		qa = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('qa')"))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 14)
	add_child(hud)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_font_size_override("font_size", 16)
	add_child(status)
	for spec in [["left", "<"], ["right", ">"], ["jab", "Jab"], ["cross", "Direto"], ["dodge", "Recuo"], ["guard", "Bloquear"], ["pause", "Pausar"], ["reset", "Reiniciar"], ["debug", "Caixas"]]:
		var key: String = spec[0]
		var button := Button.new()
		button.text = spec[1]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		button.button_down.connect(func(): press(key))
		button.button_up.connect(func(): held.erase(key))
		add_child(button)
		buttons.append(button)
	get_viewport().size_changed.connect(layout)
	layout()

func layout() -> void:
	var size := get_viewport_rect().size
	var portrait := size.y > size.x * 1.15
	hud.add_theme_font_size_override("font_size", 24 if portrait else 14)
	status.add_theme_font_size_override("font_size", 24 if portrait else 16)
	hud.position = Vector2(14, 10)
	hud.size = Vector2(size.x - 28, 100 if portrait else 44)
	status.position = Vector2(8, 220 if portrait else 83)
	status.size = Vector2(size.x - 16, 80 if portrait else 48)
	var width := (size.x - 42.0) / 6.0
	for i in 6:
		buttons[i].add_theme_font_size_override("font_size", 25 if portrait else 17)
		buttons[i].position = Vector2(12 + i * (width + 4), size.y - 82)
		buttons[i].size = Vector2(width, 68)
	if portrait:
		var order := [2, 3, 4, 0, 1, 5]
		for slot in 6:
			var button := buttons[order[slot]]
			button.position = Vector2(12 + (slot % 3) * (size.x - 16) / 3, size.y - 212 + floori(float(slot) / 3) * 102)
			button.size = Vector2((size.x - 40) / 3, 92)
	for i in 3:
		buttons[6 + i].add_theme_font_size_override("font_size", 24 if portrait else 17)
		buttons[6 + i].position = Vector2(12 + i * (size.x - 20) / 3, 130) if portrait else Vector2(size.x - 290 + i * 94, 53)
		buttons[6 + i].size = Vector2((size.x - 44) / 3, 74) if portrait else Vector2(90, 30)

func clear_input() -> void:
	held.clear()
	fingers.clear()
	pulses.clear()

func press(key: String) -> void:
	match key:
		"pause":
			paused = not paused
			clear_input()
			buttons[6].text = "Continuar" if paused else "Pausar"
		"reset":
			combat.reset()
			paused = false
			clear_input()
			buttons[6].text = "Pausar"
		"debug": debug_boxes = not debug_boxes
		_:
			if not paused:
				held[key] = true
				if key in ["jab", "cross", "dodge"]:
					# Bounded queue; no auto-repeat on a held attack.
					pulses = [key]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			for i in buttons.size():
				if buttons[i].get_global_rect().has_point(event.position):
					var key: String = TOUCH_KEYS[i]
					press(key)
					fingers[event.index] = key
					break
		else:
			release_finger(event.index)
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag and fingers.has(event.index):
		var key: String = fingers[event.index]
		var i := TOUCH_KEYS.find(key)
		if i >= 0 and not buttons[i].get_global_rect().has_point(event.position):
			release_finger(event.index)
	if event is InputEventKey and not event.echo:
		var keys := {KEY_A: "left", KEY_LEFT: "left", KEY_D: "right", KEY_RIGHT: "right", KEY_J: "jab", KEY_K: "cross", KEY_L: "guard", KEY_SPACE: "dodge", KEY_ESCAPE: "pause", KEY_R: "reset", KEY_F2: "debug"}
		var key: String = keys.get(event.keycode, "")
		if key != "":
			if event.pressed:
				press(key)
			else:
				held.erase(key)

func release_finger(index: int) -> void:
	var key: String = fingers.get(index, "")
	fingers.erase(index)
	if not fingers.values().has(key):
		held.erase(key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		paused = true
		clear_input()
		if buttons.size() > 6:
			buttons[6].text = "Continuar"

func _physics_process(dt: float) -> void:
	if not paused:
		var axis := float(held.has("right")) - float(held.has("left"))
		var can_consume: bool = combat.hitstop <= 0.0
		combat.step(dt, axis, held.has("guard"), pulses)
		if can_consume:
			pulses.clear()
	var a: Dictionary = combat.fighters[0]
	var b: Dictionary = combat.fighters[1]
	var portrait := get_viewport_rect().size.y > get_viewport_rect().size.x * 1.15
	hud.text = ("GAVYO  /  TREINO GODOT\nVocê %03d · Fôlego %03d\nRival %03d · Fôlego %03d" if portrait else "GAVYO  /  TREINO GODOT\nVocê   %03d  ·  Fôlego %03d                 Rival   %03d  ·  Fôlego %03d") % [a.hp, a.stamina, b.hp, b.stamina]
	status.text = "Pausado · toque em Continuar" if paused else combat.feedback
	if portrait:
		status.text += "\nVire o celular para ampliar a luta."
	if qa:
		var control_boxes := []
		for button in buttons:
			var box := button.get_global_rect()
			control_boxes.append([box.position.x, box.position.y, box.size.x, box.size.y])
		var snapshot := {"fighters": combat.fighters, "time": combat.time, "paused": paused, "held": held, "result": combat.result, "width": get_viewport_rect().size.x, "buttons": control_boxes}
		JavaScriptBridge.eval("window.__GAVYO_QA = " + JSON.stringify(snapshot))
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var zoom := minf(size.x / 320.0, (size.y - 185.0) / 95.0)
	var origin := Vector2((size.x - 320.0 * zoom) / 2.0, minf(size.y - 100.0, size.y * 0.58 + 80.0))
	draw_set_transform(origin, 0.0, Vector2.ONE * zoom)
	draw_rect(Rect2(5, -85, 310, 90), Color("14232e"))
	for x in range(10, 320, 16):
		draw_line(Vector2(x, -80), Vector2(x, 2), Color("24343e"))
	draw_line(Vector2(8, 2), Vector2(312, 2), Color("58948a"), 2)
	for i in 2:
		var f: Dictionary = combat.fighters[i]
		draw_ellipse_shadow(Vector2(f.x, 0))
		var index: int = combat.data.clips[f.clip].frames[f.frame].index
		var cell := Vector2(combat.data.frame[0], combat.data.frame[1])
		var root := Vector2(combat.data.root[0], combat.data.root[1])
		var source := Rect2(Vector2(index % int(combat.data.columns), floori(float(index) / float(combat.data.columns))) * cell, cell)
		# Mirror the drawing transform around the foot pivot, keeping boxes aligned.
		draw_set_transform(origin + Vector2(f.x * zoom, 0), 0.0, Vector2(zoom * f.facing, zoom))
		draw_texture_rect_region(atlas, Rect2(-root, cell), source, Color.WHITE if i == 0 else Color(0.72, 0.88, 1.0))
		draw_set_transform(origin, 0.0, Vector2.ONE * zoom)
		draw_rect(Rect2(f.x - 18, -80, 36, 3), Color("324750"))
		draw_rect(Rect2(f.x - 18, -80, 36 * float(f.hp) / 100.0, 3), Color("5ed3ad") if i == 0 else Color("e9b168"))
		if debug_boxes:
			for box in combat.hurtboxes(i):
				draw_rect(box, Color(0.1, 0.9, 0.5, 0.65), false)
			var hit: Rect2 = combat.hitbox(i)
			if hit.has_area():
				draw_rect(hit, Color(1, 0.2, 0.15, 0.9), false)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(at: Vector2) -> void:
	draw_rect(Rect2(at.x - 16, -1, 32, 3), Color(0, 0, 0, 0.25))

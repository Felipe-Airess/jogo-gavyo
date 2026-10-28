extends Node2D
## Duelo 1×1 completo no Godot (port de src/duel/duel-scene.mjs). Só desenha e
## lê a entrada: as regras ficam em scripts/duel/duel.gd, idêntico ao Phaser.
## Mundo em pixel art 320×180 ampliado 2× pela câmera; HUD e toque numa camada
## própria, nítidos em qualquer tela.
signal corridor_requested

const Duel = preload("res://scripts/duel/duel.gd")
const AI = preload("res://scripts/duel/ai.gd")
const Fighter = preload("res://scripts/duel/fighter.gd")
const Markers = preload("res://scripts/duel/markers.gd")
const Moves = preload("res://scripts/core/moves.gd")
const Art = preload("res://scripts/duel/art.gd")
const Match = preload("res://scripts/core/match.gd")
const Step = preload("res://scripts/core/fixed_step.gd")
const PixelFont = preload("res://scripts/game/pixel_font.gd")
const Blood = preload("res://scripts/game/blood.gd")
const FX = preload("res://scripts/game/impact_fx.gd")
const Hallway = preload("res://scripts/game/hallway.gd")
const Layer = preload("res://scripts/game/draw_layer.gd")
const Audio = preload("res://scripts/game/combat_audio.gd")
const TouchPad = preload("res://scripts/game/touch_pad.gd")

const WORLD_X := -80.0
## Tela lógica: HUD (27 px) em cima, mundo de 180 px, mensagem (11 px) embaixo.
## O zoom mostra sempre ao menos 320 px de largura (como no Phaser) e a coluna
## inteira; sobra de tela vira mais corredor dos lados ou mais piso embaixo.
const WORLD_H := 180.0
const HUD_H := 27.0
const NOTE_H := 11.0
const TIME_OPTIONS := [60, 99, 0]
const ROUND_OPTIONS := [1, 3, 5]
const SETTINGS_PATH := "user://gaviao.cfg"
const COLORS := {"head": Color8(0xd5, 0xba, 0x79), "body": Color8(0x88, 0xbd, 0xc0), "legs": Color8(0x7f, 0x95, 0xc9), "hit": Color8(0xe3, 0x6f, 0x5a),
	"push": Color8(0x9c, 0xad, 0x8a), "guard": Color8(0xb9, 0xcc, 0x8c), "grab": Color8(0xd5, 0x9a, 0x4f), "point": Color8(0xf2, 0xef, 0xd2)}
## Rival com a mesma roupa do jogador: camisa clara vira grafite, verde vira vinho.
const RECOLOR_SHADER := """
shader_type canvas_item;
uniform bool active = false;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (active && c.a > 0.03) {
		float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
		if (mn > 150.0/255.0 && mx - mn < 50.0/255.0) { float v = mx * 0.42; c.rgb = vec3(v * 0.95, v, v * 1.12); }
		else if (c.g > c.r + 18.0/255.0 && c.g > c.b + 10.0/255.0) { c.rgb = vec3(c.g * 0.75, c.r * 0.45, c.b * 0.5); }
	}
	COLOR = c;
}
"""

var art: Dictionary
var model
var ai
var match_state
var stepper
var blood
var fx
var audio
var settings := {"mode": "duelo", "player": "sorriso", "rival": "sorriso", "level": "firme", "bestOf": 3, "seconds": 60, "training": "reaction", "blood": true, "sound": true}
var mode := "select"
var debug_visible := false
var menu_row := 0
var menu_held := {}
var pressed := {}
var camera_x := 80.0
var qa := false   # ?qa=1 na web: estado somente leitura em window.__GAVYO_QA (teste de navegador)
var last_sound_id := 0
var last_step := -1

var world: Node2D
var camera: Camera2D
var floor_layer: Node2D
var fx_layer: Node2D
var views: Array = []
var textures := {}
var ui_layer: CanvasLayer
var hud: Node2D
var touch: Control

func setup(shared_art: Dictionary) -> void:
	art = shared_art

func _ready() -> void:
	if art.is_empty(): art = Art.load_all()
	model = Duel.new(art.roster, art.specs)
	load_settings()
	for name in ["sorriso", "miguel"]:
		textures[name] = load("res://assets/full/%s.png" % name)
	blood = Blood.new()
	fx = FX.new(blood)
	stepper = Step.new()
	audio = Audio.new()
	add_child(audio)
	build_world()
	build_ui()
	qa = OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("qa=1")
	change_mode("select")

# ---- montagem ------------------------------------------------------------------
func build_world() -> void:
	world = Node2D.new()
	add_child(world)
	var hall := Hallway.new()
	hall.position = Vector2(WORLD_X, 0)
	hall.z_index = -10
	world.add_child(hall)
	floor_layer = Layer.new()
	floor_layer.z_index = -5
	floor_layer.painter = paint_floor
	world.add_child(floor_layer)
	var shader := Shader.new()
	shader.code = RECOLOR_SHADER
	for i in 2:
		var s := Sprite2D.new()
		s.centered = false
		s.offset = Vector2(-64, -88)
		s.region_enabled = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var mat := ShaderMaterial.new()
		mat.shader = shader
		s.material = mat
		world.add_child(s)
		views.append(s)
	fx_layer = Layer.new()
	fx_layer.z_index = 10
	fx_layer.painter = paint_effects
	world.add_child(fx_layer)
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	world.add_child(camera)
	camera.make_current()

func build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	hud = Layer.new()
	hud.painter = paint_hud
	ui_layer.add_child(hud)
	touch = TouchPad.new()
	touch.visible = touch_device()
	touch.pause_pressed.connect(func(): toggle())
	ui_layer.add_child(touch)

## Escala do HUD e da tela lógica: 320 de largura no mínimo.
func zoom() -> float:
	var vp := get_viewport_rect().size
	return minf(vp.x / 320.0, vp.y / (HUD_H + WORLD_H + NOTE_H))

## Zoom do mundo: em retrato, mais perto (240 px de corredor, câmera na luta);
## o piso que sobra embaixo fica para os botões de toque.
func world_zoom() -> float:
	var vp := get_viewport_rect().size
	if vp.y > vp.x: return minf(vp.x / 240.0, (vp.y - (HUD_H + NOTE_H) * zoom()) / WORLD_H)
	return zoom()

func logical_size() -> Vector2:
	return get_viewport_rect().size / zoom()

func touch_device() -> bool:
	if DisplayServer.is_touchscreen_available(): return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval("('ontouchstart' in window) || navigator.maxTouchPoints > 0", true))
	return false

# ---- preferências --------------------------------------------------------------
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cfg.get_value("duelo", k, settings[k])
	for k in ["player", "rival"]:
		if not art.roster.has(settings[k]): settings[k] = "sorriso"
	if not AI.LEVELS.has(settings.level): settings.level = "firme"

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("duelo", k, settings[k])
	cfg.save(SETTINGS_PATH)

# ---- modos ---------------------------------------------------------------------
func change_mode(next: String) -> void:
	mode = next
	stepper.reset()
	model.clear_inputs()
	pressed.clear()
	touch.clear()
	menu_held = {}

func toggle() -> void:
	if mode == "select" or mode == "over": start_match()
	else: change_mode("paused" if mode == "playing" else "playing")

func start_match() -> void:
	if settings.mode == "corredor":
		save_settings()
		corridor_requested.emit()
		return
	if not model.set_characters([settings.player, settings.rival]): return
	save_settings()
	ai = AI.new(41, settings.level)
	match_state = Match.new({"bestOf": settings.bestOf, "seconds": settings.seconds})
	fx.reset(); blood.reset(); camera_x = 80.0
	change_mode("playing")

func menu_rows() -> Array:
	var chars: Array = art.roster.keys()
	if settings.mode == "corredor":
		return [["MODO", ["duelo", "corredor"], "mode"], ["VOCE", chars, "player"], ["TREINO", ["reaction", "guard", "sparring"], "training"], ["TREINAR", null, ""]]
	return [["MODO", ["duelo", "corredor"], "mode"], ["VOCE", chars, "player"], ["RIVAL", chars, "rival"], ["IA", AI.LEVELS.keys(), "level"],
		["ROUNDS", ROUND_OPTIONS, "bestOf"], ["TEMPO", TIME_OPTIONS, "seconds"], ["LUTAR", null, ""]]

## Liga/desliga esta cena (a raiz alterna entre duelo e corredor).
func activate(on: bool) -> void:
	visible = on
	ui_layer.visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if on:
		camera.make_current()
		change_mode("select")

func menu_label(key: String, value: Variant) -> String:
	match key:
		"mode": return "DUELO 1X1" if value == "duelo" else "CORREDOR DE TREINO"
		"training": return {"reaction": "REACAO", "guard": "GUARDA", "sparring": "SPARRING"}[value]
		"player", "rival": return Fighter.CHARACTERS[value].name
		"level": return AI.LEVEL_NAMES[value]
		"bestOf": return "1 ROUND" if int(value) == 1 else "MELHOR DE %d" % int(value)
		"seconds": return "%d SEG" % int(value) if int(value) else "SEM TEMPO"
	return str(value)

func update_menu(input: Dictionary) -> void:
	var edge := func(k: String) -> bool: return input.get(k, false) and not menu_held.get(k, false)
	var rows := menu_rows()
	if edge.call("up"): menu_row = (menu_row + rows.size() - 1) % rows.size()
	if edge.call("down"): menu_row = (menu_row + 1) % rows.size()
	menu_row = mini(menu_row, rows.size() - 1)
	var row: Array = rows[menu_row]
	var step := 1 if edge.call("right") else (-1 if edge.call("left") else 0)
	if step != 0 and row[1] != null:
		var values: Array = row[1]
		var i := values.find(settings[row[2]])
		settings[row[2]] = values[(i + step + values.size()) % values.size()]
		save_settings()
	menu_held = {"up": input.get("up", false), "down": input.get("down", false), "left": input.get("left", false), "right": input.get("right", false)}
	if input.get("attack", false) or input.get("kick", false): start_match()

# ---- entrada -------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if overlay_tap(event): return
	if event is InputEventKey and event.pressed and not event.echo:
		pressed[event.physical_keycode] = true
		match event.physical_keycode:
			KEY_F2: debug_visible = not debug_visible
			KEY_R: if mode != "select": start_match()
			KEY_M: if mode != "playing": change_mode("select")
			KEY_B: settings.blood = not settings.blood; save_settings()
			KEY_N: settings.sound = not settings.sound; save_settings()
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER: toggle()
	elif event is InputEventJoypadButton and event.pressed:
		pressed["joy%d" % event.button_index] = true
		if event.button_index == JOY_BUTTON_START: toggle()
		if event.button_index == JOY_BUTTON_BACK and mode != "playing": change_mode("select")
	elif event is InputEventScreenTouch and event.pressed and not touch.visible:
		touch.visible = true

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT) and mode == "playing":
		change_mode("paused")

func key(k: int) -> bool: return Input.is_physical_key_pressed(k)
func joy(b: int) -> bool: return Input.is_joy_button_pressed(0, b)
func axis(a: int) -> float: return Input.get_joy_axis(0, a)

func read_input() -> Dictionary:
	var t: Dictionary = touch.read()
	var p := pressed
	pressed = {}
	return {
		"left": t.get("left", false) or p.has(KEY_A) or p.has(KEY_LEFT) or key(KEY_A) or key(KEY_LEFT) or joy(JOY_BUTTON_DPAD_LEFT) or axis(JOY_AXIS_LEFT_X) < -0.5,
		"right": t.get("right", false) or p.has(KEY_D) or p.has(KEY_RIGHT) or key(KEY_D) or key(KEY_RIGHT) or joy(JOY_BUTTON_DPAD_RIGHT) or axis(JOY_AXIS_LEFT_X) > 0.5,
		"up": t.get("up", false) or p.has(KEY_W) or p.has(KEY_UP) or key(KEY_W) or key(KEY_UP) or joy(JOY_BUTTON_DPAD_UP) or axis(JOY_AXIS_LEFT_Y) < -0.5,
		"down": t.get("down", false) or p.has(KEY_S) or p.has(KEY_DOWN) or key(KEY_S) or key(KEY_DOWN) or joy(JOY_BUTTON_DPAD_DOWN) or axis(JOY_AXIS_LEFT_Y) > 0.5,
		"run": t.get("run", false) or key(KEY_SHIFT) or joy(JOY_BUTTON_LEFT_SHOULDER),
		"guard": t.get("guard", false) or key(KEY_L) or joy(JOY_BUTTON_RIGHT_SHOULDER) or axis(JOY_AXIS_TRIGGER_RIGHT) > 0.5,
		"attack": t.get("attack", false) or p.has(KEY_J) or p.has("joy%d" % JOY_BUTTON_A),
		"kick": t.get("kick", false) or p.has(KEY_K) or p.has("joy%d" % JOY_BUTTON_B),
		"grab": t.get("grab", false) or p.has(KEY_G) or p.has("joy%d" % JOY_BUTTON_X),
	}

# ---- ciclo ---------------------------------------------------------------------
func _process(delta: float) -> void:
	var ms := delta * 1000.0
	blood.enabled = settings.blood
	audio.enabled = settings.sound
	var input := read_input()
	if mode == "select":
		update_menu(input)
	elif mode == "over":
		if input.kick: change_mode("select")
		elif input.attack: start_match()
	elif mode == "playing":
		var scale: float = fx.time_scale()
		stepper.advance(ms * scale, input, func(sample: Dictionary, dt: float) -> void:
			var open: bool = match_state.phase == "fight"
			model.tick([sample if open else {}, ai.input(model, model.fighters[1], model.fighters[0]) if open else {}], dt)
			var ev: Variant = match_state.update(dt, model)
			if ev == "nextRound":
				model.reset(); ai.reset(); fx.reset(); camera_x = 80.0
		)
		if match_state.phase == "done": change_mode("over")
		fx.consume(model)
		fx.step(ms, model)
		blood.step(ms * fx.time_scale())
		play_audio()
	render()

func play_audio() -> void:
	for e in model.events:
		if e.id > last_sound_id and (e.type == "hit" or e.type == "block"):
			last_sound_id = e.id
			var kind := "parry" if e.get("kind") == "parry" else ("guard" if e.type == "block" else "hit")
			audio.play(kind, 1.2 if e.get("heavy", false) else 1.0)
	var p: Dictionary = model.fighters[0]
	var step := int(floor(p.runDistance / 42.0))
	if p.state == "run" and step != last_step:
		last_step = step
		audio.play("step")

# ---- desenho -------------------------------------------------------------------
func render() -> void:
	var alpha: float = stepper.alpha if mode == "playing" and model.hitstop <= 0 else 1.0
	for i in 2:
		var f: Dictionary = model.fighters[i]
		var view: Sprite2D = views[i]
		var ref: Dictionary = model.animation(f)
		var clip: Dictionary = art.roster[f.character].clips[ref.clip]
		var index := int(clip.frames[int(ref.frame)].index)
		var step: float = model.draw_x(f) - f.x
		var x: float = model.draw_x(f) if step != 0.0 else lerpf(f.prevX, f.x, alpha)
		if model.hitstop > 0 and model.last_hit != null and model.last_hit.target == f.id:
			x += 1.0 if int(floor(model.hitstop / 33.0)) % 2 else -1.0
		view.texture = textures[f.character]
		view.region_rect = Rect2(Vector2(index % 8, index / 8) * Vector2(128, 96), Vector2(128, 96))
		view.position = Vector2(round(x), f.y)
		view.flip_h = f.facing < 0
		view.z_index = 1 if f.state == "attack" else 0
		view.material.set_shader_parameter("active", i == 1 and f.character == model.fighters[0].character and f.character == "sorriso")
	var a: Dictionary = model.fighters[0]
	var b: Dictionary = model.fighters[1]
	var wz := world_zoom()
	var visible_w := get_viewport_rect().size.x / wz
	var target := clampf((a.x + b.x) / 2.0 - visible_w / 2.0, WORLD_X, WORLD_X + 640 - visible_w)
	camera_x += (target - camera_x) * 0.18
	var z := zoom()
	camera.zoom = Vector2(wz, wz)
	hud.scale = Vector2(z, z)
	var shake: Vector2 = fx.offset()
	camera.position = Vector2(round(camera_x) + shake.x, -HUD_H * z / wz + shake.y)
	floor_layer.queue_redraw()
	fx_layer.queue_redraw()
	hud.queue_redraw()
	if qa: publish_qa()
	# Control sob CanvasLayer não herda o tamanho da tela: acompanha a viewport.
	if touch.size != get_viewport_rect().size:
		touch.position = Vector2.ZERO
		touch.size = get_viewport_rect().size
		touch.queue_redraw()

func paint_floor(ci: CanvasItem) -> void:
	blood.render_marks(ci)
	for f in model.fighters:
		ci.draw_set_transform(Vector2(round(model.draw_x(f)), Duel.STAGE.ground), 0, Vector2(1, 0.16))
		ci.draw_circle(Vector2.ZERO, 12.5, Color(0.09, 0.15, 0.14, 0.6))
		ci.draw_set_transform(Vector2.ZERO)

func paint_effects(ci: CanvasItem) -> void:
	blood.render_particles(ci)
	fx.render_wounds(ci, model)
	fx.render(ci)
	if debug_visible:
		for f in model.fighters: draw_debug(ci, f)

func draw_debug(ci: CanvasItem, f: Dictionary) -> void:
	var w: Variant = model.markers_of(f)
	var stroke := func(b: Variant, color: Color) -> void:
		if b != null: ci.draw_rect(Rect2(round(b.position.x) + 0.5, round(b.position.y) + 0.5, round(b.size.x), round(b.size.y)), color, false, 1.0)
	if not (f.state in Duel.DOWN):
		var boxes := Markers.hurtboxes(w, f.state == "attack" or f.state == "clinchStrike")
		for zone in boxes:
			for b in boxes[zone]: stroke.call(b, COLORS.get(zone, Color.WHITE))
	stroke.call(Markers.pushbox(f, w), COLORS.push)
	if f.state == "guard" or f.state == "blockstun": stroke.call(Markers.guard_box(f, w), COLORS.guard)
	if f.state in ["idle", "walk", "clinchEntry"]: stroke.call(Markers.grab_box(f, w), COLORS.grab)
	if (f.state == "attack" or f.state == "clinchStrike") and w != null:
		var mv: Dictionary = model.move_of(f)
		var tip: Variant = Markers.limb_center(w.get(mv.limb), mv.limb, f.facing)
		if tip != null:
			var size: Vector2 = Markers.LIMB_SIZE[mv.limb]
			var active: bool = mv.active.has(mv.frames[Moves.frame_index(mv, f.moveT)])
			ci.draw_rect(Rect2(round(tip.x - size.x / 2) + 0.5, round(tip.y - size.y / 2) + 0.5, size.x, size.y), COLORS.hit if active else Color8(0x80, 0x60, 0x50), false, 1.0)
	if w != null:
		for p in [w.head, w.hip, w.fist, w.rearFist, w.foot, w.knee] + w.feet:
			if p != null: ci.draw_rect(Rect2(round(p.x), round(p.y), 1, 1), COLORS.point)

func paint_hud(ci: CanvasItem) -> void:
	overlay_buttons.clear()
	var size := logical_size()
	fx.render_flash(ci, size)
	# Barra de cima.
	ci.draw_rect(Rect2(0, 0, size.x, 27), Color("#142321"))
	ci.draw_rect(Rect2(0, 26, size.x, 1), Color("#8c956f"))
	if mode == "select":
		PixelFont.draw(ci, "GAVIAO", Vector2(6, 10), Color("#d8d5b7"))
	else:
		for i in 2:
			var f: Dictionary = model.fighters[i]
			var left := i == 0
			var x0 := 6.0 if left else size.x - 150.0
			var name: String = Fighter.CHARACTERS[f.character].name + (" B" if not left and f.character == model.fighters[0].character else "")
			PixelFont.draw(ci, name, Vector2(x0, 3), Color("#d8d5b7") if left else Color("#c9a7a2"))
			var to_win := ceili(match_state.best_of / 2.0)
			for k in to_win:
				ci.draw_rect(Rect2(x0 + name.length() * 4 + 3 + k * 5, 4, 3, 3), Color("#d1bd85") if k < match_state.wins[i] else Color("#354438"))
			var bars := [["C", 100 - f.condition.head, "#cab47a"], ["T", 100 - f.condition.body, "#a3b180"], ["P", 100 - f.condition.legs, "#b39d80"], ["E", f.balance, "#87aeb0"], ["F", f.stamina, "#91a17b"]]
			for j in bars.size():
				var x: float = x0 + j * 29
				PixelFont.draw(ci, bars[j][0], Vector2(x, 11), Color(bars[j][2]))
				ci.draw_rect(Rect2(x + 5, 12, 20, 3), Color("#354438"))
				ci.draw_rect(Rect2(x + 5, 12, round(20 * maxf(0, bars[j][1]) / 100.0), 3), Color(bars[j][2]))
			PixelFont.draw(ci, action_label(f).left(18), Vector2(x0, 19), Color("#d1bd85"))
			if f.clinch != null and f.clinch.role == "held":
				ci.draw_rect(Rect2(x0 + 80, 20, round(60 * minf(1.0, f.clinch.escape / 100.0)), 2), Color("#c7af71"))
		var secs: Variant = null
		if match_state.seconds != 0: secs = maxi(0, ceili(match_state.time_left / 1000.0))
		var label := "--" if secs == null else ("%02d" % secs)
		PixelFont.draw(ci, label, Vector2(round(size.x / 2) - 4, 4), Color("#d98a6a") if secs != null and secs <= 10 else Color("#ded8b3"))
		if debug_visible: PixelFont.draw(ci, "FPS %d" % Engine.get_frames_per_second(), Vector2(size.x - 70, 19), Color("#82947e"))
	# Barra de baixo: mensagem de estado.
	ci.draw_rect(Rect2(0, size.y - 11, size.x, 11), Color("#182922"))
	PixelFont.draw(ci, status_text().left(int(size.x / 4) - 2), Vector2(6, size.y - 8), Color("#c1c5a1"))
	paint_overlay(ci, size)

func action_label(f: Dictionary) -> String:
	if f.state == "attack":
		return model.move_of(f).name + (" X%d" % f.chain if f.chain > 1 else "")
	if f.state == "held": return "PRESO"
	if f.state == "thrown": return "ARREMESSADO"
	if f.state == "parried": return "APARADO"
	if model.clock < f.parryUntil: return "CONTRA-ATAQUE"
	if f.clinch != null: return "CLINCH"
	if f.state == "ko": return "NOCAUTE"
	if f.state == "guard": return "GUARDA"
	if model.is_rocked(f): return "GROGUE"
	return ""

func status_text() -> String:
	match mode:
		"paused": return "PAUSADO. ESC OU START CONTINUA."
		"select": return "DIRECIONAL ESCOLHE. SOCO OU CHUTE COMECA."
		"over": return "SOCO: REVANCHE. CHUTE: TROCAR LUTADORES."
	return model.message

func paint_overlay(ci: CanvasItem, size: Vector2) -> void:
	var cx := size.x / 2.0
	if mode == "playing":
		var b: Variant = match_state.banner()
		if b != null:
			ci.draw_rect(Rect2(0, 62 + HUD_H, size.x, 34 if b.sub != "" else 24), Color(0.05, 0.09, 0.08, 0.55))
			PixelFont.centered(ci, b.title, cx, 66 + HUD_H, Color("#e0a070") if b.title == "K.O." else Color("#ded8b3"), 2)
			if b.sub != "": PixelFont.centered(ci, b.sub, cx, 84 + HUD_H, Color("#c1c5a1"))
		return
	ci.draw_rect(Rect2(0, 28, size.x, size.y - 39), Color(0.05, 0.09, 0.08, 0.9 if mode == "select" else 0.86))
	if mode == "select":
		PixelFont.centered(ci, "GAVIAO", cx, 36, Color("#ded8b3"), 2)
		var rows := menu_rows()
		for i in rows.size():
			var y := 58.0 + i * 13
			var on := i == menu_row
			if on: ci.draw_rect(Rect2(cx - 120, y - 3, 240, 11), Color("#2b3b33"))
			var color := Color("#e7d38f") if on else Color("#a9b19a")
			if rows[i][1] == null:
				PixelFont.centered(ci, "> %s <" % rows[i][0] if on else rows[i][0], cx, y, color)
				continue
			PixelFont.draw(ci, rows[i][0], Vector2(cx - 108, y), color)
			PixelFont.draw(ci, ("< " if on else "") + menu_label(rows[i][2], settings[rows[i][2]]) + (" >" if on else ""), Vector2(cx - 20, y), color)
		PixelFont.centered(ci, "F2 CAIXAS  B SANGUE  N SOM  ESC PAUSA", cx, 158, Color("#82947e"))
	else:
		var won: bool = mode == "over" and match_state.winner == 1
		PixelFont.centered(ci, ("VITORIA" if won else "DERROTA") if mode == "over" else "PAUSADO", cx, 52, Color("#ded8b3"), 2)
		if mode == "over":
			PixelFont.centered(ci, "%d X %d" % [match_state.wins[0], match_state.wins[1]], cx, 74, Color("#d1bd85"), 2)
			var last: String = str(match_state.history[-1].reason) if not match_state.history.is_empty() else ""
			PixelFont.centered(ci, last.left(60), cx, 98, Color("#c1c5a1"))
			PixelFont.centered(ci, "J REVANCHE   K TROCAR LUTADORES", cx, 118, Color("#c7b376"))
			draw_buttons(ci, [["REVANCHE", "revanche"], ["MENU", "menu"]], cx, 132)
		else:
			PixelFont.centered(ci, "ESC CONTINUA   M MENU   R REINICIA", cx, 80, Color("#c1c5a1"))
			draw_buttons(ci, [["CONTINUAR", "continuar"], ["REINICIAR", "reiniciar"], ["MENU", "menu"]], cx, 96)

func publish_qa() -> void:
	var fs: Array = []
	for f in model.fighters:
		fs.append({"x": f.x, "state": f.state, "move": f.move, "character": f.character})
	var buttons := {"left": touch.pad_center() + Vector2(-touch.pad_r() * 0.62, 0), "right": touch.pad_center() + Vector2(touch.pad_r() * 0.62, 0)}
	for b in touch.BUTTONS:
		buttons[b.action] = touch.button_center(b)
	var out := {}
	for k in buttons: out[k] = [buttons[k].x, buttons[k].y]
	var snapshot := {"mode": mode, "phase": match_state.phase if match_state != null else "", "time": model.clock / 1000.0, "fighters": fs,
		"held": touch.held(), "touch": touch.visible, "width": get_viewport_rect().size.x, "buttons": out}
	JavaScriptBridge.eval("window.__GAVYO_QA = " + JSON.stringify(snapshot))

# ---- botões tocáveis das telas de pausa/fim (o toque não tem Esc nem M) -------
var overlay_buttons: Array = []

func draw_buttons(ci: CanvasItem, items: Array, cx: float, y: float) -> void:
	var w := 74.0
	var gap := 8.0
	var x := cx - (items.size() * w + (items.size() - 1) * gap) / 2.0
	for it in items:
		var r := Rect2(x, y, w, 16)
		ci.draw_rect(r, Color("#2b3b33"))
		ci.draw_rect(r, Color("#c7b376"), false, 1.0)
		PixelFont.centered(ci, it[0], r.get_center().x, y + 6, Color("#e7d38f"))
		overlay_buttons.append({"rect": r, "action": it[1]})
		x += w + gap

func overlay_tap(event: InputEvent) -> bool:
	var pressed_at: Variant = null
	if event is InputEventScreenTouch and event.pressed: pressed_at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: pressed_at = event.position
	if pressed_at == null or mode == "playing": return false
	var p: Vector2 = pressed_at / zoom()
	for b in overlay_buttons:
		if b.rect.has_point(p):
			overlay_action(b.action)
			get_viewport().set_input_as_handled()
			return true
	return false

func overlay_action(action: String) -> void:
	match action:
		"continuar": toggle()
		"reiniciar", "revanche": start_match()
		"menu": change_mode("select")

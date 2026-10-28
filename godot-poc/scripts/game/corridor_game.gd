extends Node2D
## Corredor de treino no Godot (port de src/main.js, cena Corridor). Regras em
## scripts/corridor/battle.gd, iguais ao Phaser; aqui só desenho e entrada.
signal menu_requested

const Battle = preload("res://scripts/corridor/battle.gd")
const CM = preload("res://scripts/corridor/corridor_moves.gd")
const View = preload("res://scripts/corridor/corridor_view.gd")
const Art = preload("res://scripts/duel/art.gd")
const Step = preload("res://scripts/core/fixed_step.gd")
const PixelFont = preload("res://scripts/game/pixel_font.gd")
const Blood = preload("res://scripts/game/blood.gd")
const FX = preload("res://scripts/game/impact_fx.gd")
const Hallway = preload("res://scripts/game/hallway.gd")
const Layer = preload("res://scripts/game/draw_layer.gd")
const Audio = preload("res://scripts/game/combat_audio.gd")
const TouchPad = preload("res://scripts/game/touch_pad.gd")

const WORLD_H := 180.0
const HUD_H := 27.0
const NOTE_H := 11.0

var art: Dictionary
var model
var stepper
var blood
var fx
var audio
var player_name := "sorriso"
var training := "reaction"
var miguel_clips: Dictionary
var mode := "playing"
var debug_visible := false
var pressed := {}
var camera_x := 0.0
var prev: Variant = null
var last_blood_hit: Variant = null
var last_fx_event := 0
var last_sound_event := 0
var npc_elapsed := 0.0
var settings: Dictionary

var world: Node2D
var camera: Camera2D
var floor_layer: Node2D
var fx_layer: Node2D
var player_sprite: Sprite2D
var npc_sprite: Sprite2D
var enemy_sprites: Array = []
var hud: Node2D
var ui_layer: CanvasLayer
var touch: Control
var textures := {}

func setup(shared_art: Dictionary, shared_settings: Dictionary) -> void:
	art = shared_art
	settings = shared_settings

func _ready() -> void:
	if art.is_empty(): art = Art.load_all()
	miguel_clips = CM.miguel_player_clips(art.roster.miguel.clips, art.roster.miguel.markers)
	for name in ["sorriso", "miguel"]:
		textures[name] = load("res://assets/full/%s.png" % name)
	model = Battle.new(2, 731, CM.build_moves(art.roster.sorriso.clips))
	model.art_clips = art.roster.sorriso.clips
	blood = Blood.new()
	blood.max_particles = 160; blood.max_marks = 100; blood.mark_life = 6e4
	fx = FX.new(blood)
	stepper = Step.new()
	audio = Audio.new()
	add_child(audio)
	build_world()
	build_ui()

func build_world() -> void:
	world = Node2D.new()
	add_child(world)
	var hall := Hallway.new()
	hall.z_index = -10
	world.add_child(hall)
	floor_layer = Layer.new()
	floor_layer.z_index = -5
	floor_layer.painter = paint_floor
	world.add_child(floor_layer)
	npc_sprite = make_sprite()
	for i in model.enemies.size(): enemy_sprites.append(make_sprite())
	player_sprite = make_sprite()
	fx_layer = Layer.new()
	fx_layer.z_index = 10
	fx_layer.painter = paint_effects
	world.add_child(fx_layer)
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	world.add_child(camera)

func make_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.offset = Vector2(-64, -88)
	s.region_enabled = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world.add_child(s)
	return s

func build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	hud = Layer.new()
	hud.painter = paint_hud
	ui_layer.add_child(hud)
	touch = TouchPad.new()
	touch.pause_pressed.connect(func(): toggle())
	ui_layer.add_child(touch)

func activate(on: bool) -> void:
	visible = on
	ui_layer.visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if on: camera.make_current()

## Começa o treino com o lutador e o modo escolhidos no menu.
func start(character: String, training_mode: String, touch_visible: bool) -> void:
	player_name = character
	training = training_mode
	var m := character == "miguel"
	model.moves = CM.miguel_moves(miguel_clips) if m else CM.build_moves(art.roster.sorriso.clips)
	model.can = CM.MIGUEL_CAN.duplicate() if m else {"run": true, "grab": true, "wipe": true}
	model.fallback = CM.MIGUEL_FALLBACK if m else {}
	model.player_clips = miguel_clips if m else null
	touch.visible = touch_visible
	restart()

func restart() -> void:
	model.reset()
	model.set_mode(training)
	blood.reset(); fx.reset(); last_blood_hit = null; camera_x = 0.0; prev = null
	change_mode("playing")

func change_mode(next: String) -> void:
	mode = next
	stepper.reset(); pressed.clear(); touch.clear()

func toggle() -> void:
	if mode == "dead": restart()
	else: change_mode("paused" if mode == "playing" else "playing")

# ---- entrada -----------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if overlay_tap(event): return
	if event is InputEventKey and event.pressed and not event.echo:
		pressed[event.physical_keycode] = true
		match event.physical_keycode:
			KEY_F2: debug_visible = not debug_visible
			KEY_R: restart()
			KEY_M: if mode != "playing": menu_requested.emit()
			KEY_B: settings.blood = not settings.blood
			KEY_N: settings.sound = not settings.sound
			KEY_H: if mode == "playing": model.hurt()
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER: toggle()
	elif event is InputEventJoypadButton and event.pressed:
		pressed["joy%d" % event.button_index] = true
		if event.button_index == JOY_BUTTON_START: toggle()
		if event.button_index == JOY_BUTTON_BACK and mode != "playing": menu_requested.emit()
	elif event is InputEventScreenTouch and event.pressed and not touch.visible:
		touch.visible = true

func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT) and mode == "playing" and visible:
		change_mode("paused")

func key(k: int) -> bool: return Input.is_physical_key_pressed(k)
func joy(b: int) -> bool: return Input.is_joy_button_pressed(0, b)
func axis(a: int) -> float: return Input.get_joy_axis(0, a)

func read_input() -> Dictionary:
	var t: Dictionary = touch.read()
	var p := pressed
	pressed = {}
	return {
		"left": t.get("left", false) or key(KEY_A) or key(KEY_LEFT) or joy(JOY_BUTTON_DPAD_LEFT) or axis(JOY_AXIS_LEFT_X) < -0.5,
		"right": t.get("right", false) or key(KEY_D) or key(KEY_RIGHT) or joy(JOY_BUTTON_DPAD_RIGHT) or axis(JOY_AXIS_LEFT_X) > 0.5,
		"up": t.get("up", false) or key(KEY_W) or key(KEY_UP) or joy(JOY_BUTTON_DPAD_UP) or axis(JOY_AXIS_LEFT_Y) < -0.5,
		"down": t.get("down", false) or key(KEY_S) or key(KEY_DOWN) or joy(JOY_BUTTON_DPAD_DOWN) or axis(JOY_AXIS_LEFT_Y) > 0.5,
		"run": t.get("run", false) or key(KEY_SHIFT) or joy(JOY_BUTTON_LEFT_SHOULDER),
		"guard": t.get("guard", false) or key(KEY_L) or joy(JOY_BUTTON_RIGHT_SHOULDER) or axis(JOY_AXIS_TRIGGER_RIGHT) > 0.5,
		"attack": t.get("attack", false) or p.has(KEY_J) or p.has("joy%d" % JOY_BUTTON_A),
		"kick": t.get("kick", false) or p.has(KEY_K) or p.has("joy%d" % JOY_BUTTON_B),
		"grab": t.get("grab", false) or p.has(KEY_G) or p.has("joy%d" % JOY_BUTTON_X),
	}

# ---- ciclo -------------------------------------------------------------------
func _process(delta: float) -> void:
	var ms := delta * 1000.0
	blood.enabled = settings.get("blood", true)
	audio.enabled = settings.get("sound", true)
	var input := read_input()
	if mode == "playing":
		stepper.advance(ms * fx.time_scale(), input, func(sample: Dictionary, dt: float) -> void:
			var p: Dictionary = model.player
			var xs: Array = []
			for d in model.enemies: xs.append(d.x)
			prev = {"x": p.x, "y": p.y, "enemies": xs}
			model.step(sample, dt)
		)
		corridor_fx()
		fx.step(ms, null)
		blood.step(ms * fx.time_scale())
		play_audio()
		npc_elapsed += ms
		if model.player.hp <= 0: change_mode("dead")
	render(ms)

## Cada acerto novo vira um evento do ImpactFX (o mesmo do duelo).
func corridor_fx() -> void:
	var hit: Variant = model.last_hit
	var world_ref := {"by_id": func(id): return model.enemy_by_id(id)}
	if hit != null and (last_blood_hit == null or hit.id != last_blood_hit.id or hit.at != last_blood_hit.at):
		last_blood_hit = hit
		var d: Variant = model.enemy_by_id(hit.target)
		var power := 3 if hit.get("finisher", false) else (3 if hit.damage >= 12 else (2 if hit.damage >= 9 else 1))
		fx.on_event({"type": "block" if hit.blocked else "hit", "id": hit.id, "point": Vector2(hit.point.x, hit.point.y), "zone": hit.zone, "power": power,
			"kind": "ko" if hit.get("finisher", false) else "hit", "counter": false, "target": hit.target, "ground_y": d.y if d != null else 146.0}, self)
	var e: Variant = model.last_event
	if e != null and e.id != last_fx_event:
		last_fx_event = e.id
		var p: Dictionary = model.player
		if e.type == "parry": fx.on_event({"type": "parry", "point": Vector2(p.x + p.facing * 12, p.y - 48)}, self)

## ImpactFX pergunta pelo alvo para saber o lado do respingo.
func by_id(id: Variant) -> Variant:
	return model.enemy_by_id(id)

func play_audio() -> void:
	var e: Variant = model.last_event
	if e != null and e.id != last_sound_event:
		last_sound_event = e.id
		audio.play("parry" if e.type == "parry" else ("guard" if e.type == "block" else "hit"), 1.2 if e.get("heavy", false) else 1.0)

# ---- desenho -----------------------------------------------------------------
func hud_zoom() -> float:
	var vp := get_viewport_rect().size
	return minf(vp.x / 320.0, vp.y / (HUD_H + WORLD_H + NOTE_H))

func world_zoom() -> float:
	var vp := get_viewport_rect().size
	if vp.y > vp.x: return minf(vp.x / 240.0, (vp.y - (HUD_H + NOTE_H) * hud_zoom()) / WORLD_H)
	return hud_zoom()

func set_frame(s: Sprite2D, tex_name: String, clips: Dictionary, ref: Dictionary) -> void:
	var clip: Variant = clips.get(ref.clip)
	if clip == null: return
	var index := int(clip.frames[int(ref.frame)].index)
	s.texture = textures[tex_name]
	s.region_rect = Rect2(Vector2(index % 8, index / 8) * Vector2(128, 96), Vector2(128, 96))

func player_ref() -> Dictionary:
	var p: Dictionary = model.player
	if player_name == "miguel": return View.miguel_ref(p, model.moves, miguel_clips)
	return View.sorriso_ref(p, model.moves, art.roster.sorriso.clips)

func render(_ms: float) -> void:
	var p: Dictionary = model.player
	var a: float = stepper.alpha if mode == "playing" and model.hitstop <= 0 and prev != null else 1.0
	var px: float = lerpf(prev.x, p.x, a) if prev != null else p.x
	var py: float = lerpf(prev.y, p.y, a) if prev != null else p.y
	var clips: Dictionary = miguel_clips if player_name == "miguel" else art.roster.sorriso.clips
	set_frame(player_sprite, player_name, clips, player_ref())
	player_sprite.position = Vector2(round(px + p.visualOffsetX), round(py - p.fallHeight))
	player_sprite.flip_h = p.facing < 0 if player_name == "miguel" else View.sorriso_flip(p)
	player_sprite.z_index = int(p.y) - 100
	player_sprite.modulate.a = 0.5 if p.invulnerable > 0 and int(floor(p.invulnerable / 70.0)) % 2 == 0 else 1.0
	for i in model.enemies.size():
		var d: Dictionary = model.enemies[i]
		var s: Sprite2D = enemy_sprites[i]
		var ref := View.target_ref(d)
		var dx: float = lerpf(prev.enemies[i], d.x, a) if prev != null and d.state != "fallen" else d.x
		set_frame(s, "sorriso", art.roster.sorriso.clips, ref)
		s.position = Vector2(round(dx), round(ref.y))
		s.flip_h = d.facing > 0
		s.z_index = int(d.y) - 100
		s.modulate = Color("#a39689") if d.dead else Color.WHITE
	# Miguel parado no corredor quando quem joga é o Sorriso.
	npc_sprite.visible = player_name != "miguel"
	if npc_sprite.visible:
		var idle: Dictionary = art.roster.miguel.clips.idle
		var fi := View.loop_frame(idle, npc_elapsed)
		var frame: Dictionary = idle.frames[fi]
		npc_sprite.texture = textures.miguel
		var index := int(frame.index)
		npc_sprite.region_rect = Rect2(Vector2(index % 8, index / 8) * Vector2(128, 96), Vector2(128, 96))
		npc_sprite.position = Vector2(150, 132)
		npc_sprite.flip_h = frame.get("sourceFacing", 1) > 0
		npc_sprite.z_index = 32
	var wz := world_zoom()
	var hz := hud_zoom()
	var visible_w := get_viewport_rect().size.x / wz
	var nearest: Variant = model.nearest()
	var follow: float = (p.x + nearest.x) / 2.0 - visible_w / 2.0 if nearest != null and nearest.state == "fallen" and absf(nearest.x - p.x) < 180 else p.x - visible_w * 0.375
	var target := clampf(follow, 0, maxf(0, 640 - visible_w))
	if mode == "playing": camera_x += (target - camera_x) * (1 - exp(-_ms / 85.0))
	camera.zoom = Vector2(wz, wz)
	hud.scale = Vector2(hz, hz)
	var shake: Vector2 = fx.offset()
	camera.position = Vector2(round(camera_x) + shake.x, -HUD_H * hz / wz + shake.y)
	floor_layer.queue_redraw(); fx_layer.queue_redraw(); hud.queue_redraw()
	if touch.size != get_viewport_rect().size:
		touch.position = Vector2.ZERO; touch.size = get_viewport_rect().size; touch.queue_redraw()

func paint_floor(ci: CanvasItem) -> void:
	blood.render_marks(ci)
	var shadows: Array = [[model.player.x, model.player.y, 12.5]]
	for d in model.enemies: shadows.append([d.x, d.y, 12.5])
	if npc_sprite.visible: shadows.append([150.0, 132.0, 12.5])
	for s in shadows:
		ci.draw_set_transform(Vector2(round(s[0]), s[1]), 0, Vector2(1, 0.18))
		ci.draw_circle(Vector2.ZERO, s[2], Color(0.09, 0.15, 0.14, 0.6))
	ci.draw_set_transform(Vector2.ZERO)

func paint_effects(ci: CanvasItem) -> void:
	var p: Dictionary = model.player
	# Barras de cada manequim: cabeça, tronco, braços, pernas.
	var colors := [Color("#cab47a"), Color("#a3b180"), Color("#87aeb0"), Color("#b39d80")]
	var names := ["head", "body", "arms", "legs"]
	var maxima := [70.0, 80.0, 60.0, 60.0]
	for d in model.enemies:
		var ps: Array = model.pose(d)
		var top := INF
		for k in 3: top = minf(top, ps[k].y)
		top -= 20
		for j in 4:
			ci.draw_rect(Rect2(round(d.x) - 15, round(top) + j * 3, 30, 2), Color("#1a2924"))
			ci.draw_rect(Rect2(round(d.x) - 15, round(top) + j * 3, round(30 * d.parts[names[j]] / maxima[j]), 2), colors[j])
	blood.render_particles(ci)
	render_hands(ci, p)
	fx.render(ci)
	if p.counterUntil > model.clock: ci.draw_arc(Vector2(p.x, p.y - 53), 4, 0, TAU, 12, Color(0.76, 0.79, 0.64, 0.9), 1.0)
	if debug_visible:
		for d in model.enemies:
			var boxes: Dictionary = model.hurtboxes(d)
			for zone in boxes:
				var b: Dictionary = boxes[zone]
				ci.draw_rect(Rect2(round(b.x), round(b.y), b.w, b.h), Color("#d5ba79") if zone == "head" else Color("#88bdc0"), false, 1.0)
			if d.guard: ci.draw_rect(Rect2(d.x + d.facing * 11 - 5, d.y - 53, 10, 33), Color("#b9cc8c"), false, 1.0)
		var atk: Variant = model.attack_box()
		if atk != null: ci.draw_rect(Rect2(atk.x, atk.y, atk.w, atk.h), Color("#e39777"), false, 1.0)
		var b2: Dictionary = model.body()
		ci.draw_rect(Rect2(b2.x, b2.y, b2.w, b2.h), Color("#9cad8a"), false, 1.0)

## Sangue nas mãos (port de Blood.renderHands): marca nas luvas e gota parado.
func render_hands(ci: CanvasItem, p: Dictionary) -> void:
	if not blood.enabled or p.state in ["rushFall", "gettingUp"]: return
	var clips: Dictionary = miguel_clips if player_name == "miguel" else art.roster.sorriso.clips
	var ref := player_ref()
	var meta: Dictionary = clips[ref.clip].frames[int(ref.frame)] if clips.has(ref.clip) else {}
	var f: int = p.facing
	var ox: float = p.x + p.visualOffsetX
	var lead: Dictionary = meta.get("fist", {"x": 11, "y": -30}) if meta.get("fist") != null else {"x": 11, "y": -30}
	var other: Dictionary = meta.get("offHand", {"x": 2, "y": -35}) if meta.get("offHand") != null else {"x": 2, "y": -35}
	var swap: bool = p.activeHand == "left" and p.state in ["attack", "attackRecover"]
	var points := {"right": other if swap else lead, "left": lead if swap else other}
	for side in ["right", "left"]:
		var level: int = p.handBlood[side]
		if level == 0: continue
		var x := roundf(ox + points[side].x * f)
		var y := roundf(p.y + points[side].y)
		ci.draw_rect(Rect2(x - 1, y - 1, 3 if level > 2 else 2, 2), Color8(0x7f, 0x24, 0x25))
		if level >= 2:
			ci.draw_rect(Rect2(x, y, 1, 1), Color8(0xb0, 0x44, 0x3b))
			if p.state == "idle" and fmod(model.clock, 420.0) < 220:
				ci.draw_rect(Rect2(x, y + 3 + floor(fmod(model.clock, 420.0) / 65.0), 1, 2), Color8(0xb0, 0x44, 0x3b))

func paint_hud(ci: CanvasItem) -> void:
	overlay_buttons.clear()
	var size := get_viewport_rect().size / hud_zoom()
	fx.render_flash(ci, size)
	var p: Dictionary = model.player
	var d: Variant = model.nearest()
	ci.draw_rect(Rect2(0, 0, size.x, 27), Color("#142321"))
	ci.draw_rect(Rect2(0, 26, size.x, 1), Color("#8c956f"))
	PixelFont.draw(ci, "MIGUEL" if player_name == "miguel" else "SORRISO", Vector2(7, 5), Color("#d8d5b7"))
	for i in 5: ci.draw_rect(Rect2(7 + i * 8, 15, 6, 3), Color("#b3b878") if i < p.hp else Color("#394b3d"))
	if d != null:
		PixelFont.draw(ci, "ALVO %d" % d.id, Vector2(72, 5), Color("#c7c4a1"))
		for row in [["C", "head", 112, 70.0, "#cab47a"], ["T", "body", 146, 80.0, "#a3b180"], ["B", "arms", 180, 60.0, "#87aeb0"], ["P", "legs", 214, 60.0, "#b39d80"]]:
			PixelFont.draw(ci, row[0], Vector2(row[2], 5), Color(row[4]))
			ci.draw_rect(Rect2(row[2] + 6, 5, 24, 4), Color("#354438"))
			ci.draw_rect(Rect2(row[2] + 6, 5, round(24 * d.parts[row[1]] / row[3]), 4), Color(row[4]))
	ci.draw_rect(Rect2(7, 21, 38, 2), Color("#354438"))
	ci.draw_rect(Rect2(7, 21, round(38 * p.stamina / 100.0), 2), Color("#a97560") if p.stamina < 24 else Color("#91a17b"))
	PixelFont.draw(ci, "SEQ %d" % model.combo.hits, Vector2(72, 16), Color("#acb899"))
	var action := "MELHOR %d" % model.combo.best
	if p.state == "attack" or p.state == "knee": action = model.moves[p.move].name
	elif p.state == "clinchEntry": action = "ABRINDO GUARDA"
	elif p.state == "clinch": action = "CLINCH %d" % p.strikes
	elif p.state == "parry" or p.counterUntil > model.clock: action = "APARO > J"
	elif p.state == "wipe": action = "LIMPANDO A MAO"
	elif p.state == "brake": action = "FREANDO"
	elif p.state == "stumble": action = "DESEQUILIBRIO"
	PixelFont.draw(ci, action.left(24), Vector2(108, 16), Color("#d1bd85"))
	PixelFont.draw(ci, {"reaction": "REACAO", "guard": "GUARDA", "sparring": "SPARRING"}.get(training, training), Vector2(size.x - 60, 16), Color("#82947e"))
	if debug_visible: PixelFont.draw(ci, "FPS %d" % Engine.get_frames_per_second(), Vector2(size.x - 60, 5), Color("#c1c7a7"))
	if p.grabbed != null:
		ci.draw_rect(Rect2(243, 16, 18, 3), Color("#3e4a38"))
		ci.draw_rect(Rect2(243, 16, round(18 * minf(1.0, p.grip / Battle.CLINCH.maxGrip)), 3), Color("#c7af71"))
	ci.draw_rect(Rect2(0, size.y - 11, size.x, 11), Color("#182922"))
	var status: String = model.message
	if mode == "paused": status = "PAUSADO. ESC OU START CONTINUA."
	elif mode == "dead": status = "SEM VIDA. R OU ESC TENTA DE NOVO."
	elif p.state == "attackRecover": status = "Recuperando o apoio."
	elif p.state == "winded": status = "Sem fôlego. Espere recuperar."
	elif p.state == "gettingUp": status = "Levantando."
	PixelFont.draw(ci, status.left(int(size.x / 4) - 2), Vector2(6, size.y - 8), Color("#c1c5a1"))
	if mode != "playing":
		var cx := size.x / 2.0
		ci.draw_rect(Rect2(0, 28, size.x, size.y - 39), Color(0.05, 0.09, 0.08, 0.86))
		PixelFont.centered(ci, "PAUSADO" if mode == "paused" else "FIM DO TREINO", cx, 60, Color("#ded8b3"), 2)
		PixelFont.centered(ci, "ESC CONTINUA   R REINICIA   M MENU", cx, 80, Color("#c1c5a1"))
		draw_buttons(ci, [["CONTINUAR" if mode == "paused" else "DE NOVO", "continuar"], ["REINICIAR", "reiniciar"], ["MENU", "menu"]], cx, 92)
		PixelFont.centered(ci, "J SOCO  K CHUTE  G AGARRA  L DEFESA  SHIFT CORRE", cx, 118, Color("#82947e"))
		PixelFont.centered(ci, "F2 CAIXAS  B SANGUE  N SOM  H TESTA DANO", cx, 130, Color("#82947e"))

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
	var p: Vector2 = pressed_at / hud_zoom()
	for b in overlay_buttons:
		if b.rect.has_point(p):
			overlay_action(b.action)
			get_viewport().set_input_as_handled()
			return true
	return false

func overlay_action(action: String) -> void:
	match action:
		"continuar": toggle()
		"reiniciar": restart()
		"menu": menu_requested.emit()

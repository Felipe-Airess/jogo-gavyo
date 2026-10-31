extends Node3D
## Teste de desempenho do 3D pixelado: N Miguels animando (modelo HD, ~27 mil
## faces cada) num corredor, camera lateral, tela interna 320x180.
## Mostra FPS, tempo de quadro (media e pior) e o veredito.
## Teclas/toque: + e - mudam o numero de lutadores; S liga/desliga sombra;
## R muda a resolucao interna (320x180 / 426x240 / 640x360).

const MODELO := preload("res://miguel_animado.glb")
const ANIMS := ["guarda", "jab", "direto", "chuteCircular", "andaFrente", "gancho", "joelhada", "bloqueio"]
const RES := [Vector2i(320, 180), Vector2i(426, 240), Vector2i(640, 360)]

var lutadores: Array[Node3D] = []
var info: Label
var luz: DirectionalLight3D
var tempos: Array[float] = []
var res_i := 0


func _ready() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.17, 0.16)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.62, 0.66)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	luz = DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, 35, 0)
	luz.shadow_enabled = true
	add_child(luz)
	_caixa(Vector3(30, 0.1, 6), Vector3(0, -0.05, 0), Color(0.45, 0.47, 0.44))
	_caixa(Vector3(30, 3, 0.1), Vector3(0, 1.5, -1.5), Color(0.55, 0.62, 0.56))
	for i in 6:
		_caixa(Vector3(1.0, 1.8, 0.4), Vector3(-8 + i * 3.2, 0.9, -1.25), Color(0.3, 0.4, 0.36))
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.2
	cam.position = Vector3(0, 1.1, 8)
	add_child(cam)
	var cl := CanvasLayer.new()
	add_child(cl)
	info = Label.new()
	info.position = Vector2(4, 2)
	info.add_theme_font_size_override("font_size", 6)
	cl.add_child(info)
	var x := 4.0
	for t in ["-", "+", "S", "R"]:
		var b := Button.new()
		b.text = t
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(x, 160)
		b.size = Vector2(16, 16)
		b.pressed.connect(_acao.bind(t))
		cl.add_child(b)
		x += 20
	_aplicar_res()
	for i in 2:
		_mais()


func _caixa(t: Vector3, p: Vector3, c: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = t
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	b.material = mat
	m.mesh = b
	m.position = p
	add_child(m)


func _mais() -> void:
	var n := lutadores.size()
	var r := Node3D.new()
	r.add_child(MODELO.instantiate())
	add_child(r)
	r.position = Vector3(-3.1 + (n % 8) * 0.9, 0, -0.5 * float(n / 8))
	r.rotation_degrees.y = 90 if n % 2 == 0 else -90
	var ap: AnimationPlayer = r.find_child("AnimationPlayer", true, false)
	var nome: String = ANIMS[n % ANIMS.size()]
	if ap and ap.has_animation(nome):
		ap.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
		ap.play(nome)
	lutadores.append(r)


func _menos() -> void:
	if lutadores.size() > 1:
		lutadores.pop_back().queue_free()


func _aplicar_res() -> void:
	get_window().content_scale_size = RES[res_i]
	tempos.clear()


func _acao(t: String) -> void:
	match t:
		"+": _mais()
		"-": _menos()
		"S": luz.shadow_enabled = not luz.shadow_enabled
		"R":
			res_i = (res_i + 1) % RES.size()
			_aplicar_res()
	tempos.clear()


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		match ev.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: _acao("+")
			KEY_MINUS, KEY_KP_SUBTRACT: _acao("-")
			KEY_S: _acao("S")
			KEY_R: _acao("R")


func _process(dt: float) -> void:
	tempos.append(dt * 1000.0)
	if tempos.size() > 120:
		tempos.pop_front()
	var media := 0.0
	var pior := 0.0
	for t in tempos:
		media += t
		pior = maxf(pior, t)
	media /= maxf(1.0, tempos.size())
	var veredito := "OTIMO" if media < 17.5 else ("BOM" if media < 34.0 else "LENTO")
	info.text = "FPS %d   quadro %.1f ms (pior %.1f)   %s\nlutadores %d   tela %dx%d   sombra %s\n+/- lutadores  S sombra  R resolucao" % [
		Engine.get_frames_per_second(), media, pior, veredito, lutadores.size(),
		RES[res_i].x, RES[res_i].y, "sim" if luz.shadow_enabled else "nao"]

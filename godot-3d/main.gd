extends Node3D
## Teste do Miguel 3D: treino contra um boneco e galeria das 55 animacoes.
## O modelo, o rig e as animacoes vem de arte/miguel_animacoes.py (glb), e os
## tempos de contato de miguel_animacoes.json (os mesmos do 2D).

const MODELO := preload("res://miguel_animado.glb")
const VEL_ANDAR := 1.1      # m/s
const VEL_CORRER := 3.2
const SEPARACAO := 0.78     # distancia minima entre os dois corpos (guarda nao se atravessa)
const MIX := 0.08           # transicao entre animacoes (s)

# golpe: [animacao, alcance (m), reacao do alvo]
const GOLPES := {
	"jab": ["jab", 0.98, "apanhaCabeca"],
	"direto": ["direto", 1.02, "apanhaCabeca"],
	"gancho": ["gancho", 0.85, "apanhaCabecaForte"],
	"uppercut": ["uppercut", 0.82, "apanhaCabecaForte"],
	"pesado": ["pesado", 1.02, "apanhaCabecaForte"],
	"jabCorpo": ["jabCorpo", 0.95, "apanhaCorpo"],
	"circular": ["chuteCircular", 1.18, "apanhaCorpo"],
	"chuteAlto": ["chuteAlto", 1.18, "apanhaCabecaForte"],
	"chuteBaixo": ["chuteBaixo", 1.08, "apanhaPerna"],
	"joelhada": ["joelhada", 0.84, "apanhaCorpo"],
	"cotovelada": ["cotovelada", 0.82, "apanhaCabeca"],
	"combo": ["comboJabCotoveloJoelho", 0.90, "apanhaCorpo"],
}
const TECLAS := {
	KEY_J: "jab", KEY_K: "direto", KEY_L: "gancho", KEY_U: "uppercut",
	KEY_H: "pesado", KEY_N: "jabCorpo", KEY_I: "circular", KEY_O: "chuteAlto",
	KEY_M: "chuteBaixo", KEY_P: "joelhada", KEY_Y: "cotovelada", KEY_B: "combo",
}

var manifesto: Dictionary = {}
var jogador: Dictionary
var boneco: Dictionary
var camera: Camera3D
var info: Label
var ajuda: Label
var galeria := false
var nomes_galeria: Array = []
var idx_galeria := 0
var orbita := 0.0
var acertos := 0
var toque_esq := false
var toque_dir := false
var toque_defesa := false


func _ready() -> void:
	var f := FileAccess.open("res://miguel_animacoes.json", FileAccess.READ)
	manifesto = JSON.parse_string(f.get_as_text())
	nomes_galeria = manifesto.keys()
	_montar_cenario()
	jogador = _criar_lutador(Vector3(-0.75, 0, 0), 1)
	boneco = _criar_lutador(Vector3(0.75, 0, 0), -1)
	_montar_interface()
	_tocar(jogador, "entraGuarda")
	_tocar(boneco, "guarda")


# ------------------------------------------------------------- cenario
func _montar_cenario() -> void:
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.57, 0.62)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.035, 0.04)
	env.fog_density = 0.06
	amb.environment = env
	add_child(amb)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, 30, 0)
	luz.light_energy = 0.9
	luz.shadow_enabled = true
	add_child(luz)
	var lampada := OmniLight3D.new()  # luz fria de sala de aula
	lampada.position = Vector3(0, 2.8, 0.5)
	lampada.light_color = Color(0.85, 0.95, 1.0)
	lampada.omni_range = 7.0
	lampada.light_energy = 1.2
	add_child(lampada)

	_caixa(Vector3(14, 0.1, 8), Vector3(0, -0.05, 0), Color(0.42, 0.42, 0.40))  # piso
	_caixa(Vector3(14, 3.2, 0.1), Vector3(0, 1.6, -2.2), Color(0.80, 0.80, 0.76))  # parede
	_caixa(Vector3(14, 1.1, 0.12), Vector3(0, 0.55, -2.13), Color(0.85, 0.86, 0.86))  # azulejo
	_caixa(Vector3(2.2, 1.1, 0.05), Vector3(1.6, 1.75, -2.12), Color(0.95, 0.95, 0.95))  # quadro
	_caixa(Vector3(0.9, 2.1, 0.06), Vector3(-2.6, 1.05, -2.12), Color(0.08, 0.38, 0.16))  # porta verde

	camera = Camera3D.new()
	camera.fov = 50
	add_child(camera)


func _caixa(tam: Vector3, pos: Vector3, cor: Color) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tam
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	b.material = mat
	m.mesh = b
	m.position = pos
	add_child(m)


# ------------------------------------------------------------ lutadores
func _criar_lutador(pos: Vector3, lado: int) -> Dictionary:
	var raiz := Node3D.new()
	var modelo := MODELO.instantiate()
	raiz.add_child(modelo)
	add_child(raiz)
	raiz.position = pos
	raiz.rotation_degrees.y = 90.0 * lado  # o glb olha para +Z
	_estilo_ps1(modelo)
	var ap: AnimationPlayer = modelo.find_child("AnimationPlayer", true, false)
	for nome in manifesto.keys():
		if ap.has_animation(nome):
			var a := ap.get_animation(nome)
			a.loop_mode = Animation.LOOP_LINEAR if manifesto[nome]["loop"] else Animation.LOOP_NONE
	ap.animation_finished.connect(_fim_animacao.bind(raiz))
	return {"raiz": raiz, "ap": ap, "lado": lado, "estado": "parado", "golpe": "",
		"t": 0.0, "acertou": false, "avanco": 0.0}


func _estilo_ps1(no: Node) -> void:
	# luz por vertice e textura sem filtro, como no PS1 / Fears to Fathom
	if no is MeshInstance3D:
		var mi := no as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			if mat is BaseMaterial3D:
				var m := (mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
				m.roughness = 1.0
				m.metallic_specular = 0.0
				mi.set_surface_override_material(i, m)
	for filho in no.get_children():
		_estilo_ps1(filho)


func _tocar(l: Dictionary, nome: String, blend := MIX) -> void:
	l["ap"].play(nome, blend)


func _fim_animacao(nome: StringName, raiz: Node3D) -> void:
	var l := jogador if raiz == jogador["raiz"] else boneco
	if galeria:
		return
	var n := String(nome)
	if l == boneco:
		if n == "queda":
			_tocar(boneco, "deitado")
			get_tree().create_timer(1.0).timeout.connect(func(): _tocar(boneco, "levantar"))
		else:
			_tocar(boneco, "guarda")
		return
	if l["estado"] == "golpe":
		l["estado"] = "parado"
		_tocar(l, "guarda")
	elif n == "entraGuarda":
		_tocar(l, "guarda")


# ---------------------------------------------------------------- jogo
func _golpear(chave: String) -> void:
	if galeria or jogador["estado"] == "golpe":
		return
	var g: Array = GOLPES[chave]
	jogador["estado"] = "golpe"
	jogador["golpe"] = chave
	jogador["t"] = 0.0
	jogador["acertou"] = false
	jogador["avanco"] = float(manifesto[g[0]].get("avancoM", 0.0))
	_tocar(jogador, g[0], 0.04)


func _process(dt: float) -> void:
	if galeria:
		orbita += dt * 0.35
		_camera_galeria()
		return
	var j := jogador
	var raiz: Node3D = j["raiz"]
	if j["estado"] == "golpe":
		var g: Array = GOLPES[j["golpe"]]
		var dados: Dictionary = manifesto[g[0]]
		j["t"] += dt * 1000.0
		if j["avanco"] > 0.0:  # golpe com passo: o corpo anda o que o desenho anda
			raiz.position.x += j["avanco"] * dt * 1000.0 / float(dados["duracaoMs"])
		var contatos: Array = dados["contatosMs"] if dados["contatosMs"] != null else [dados["contatoMs"]]
		for c in contatos:
			if not j["acertou"] and j["t"] >= float(c) and j["t"] - dt * 1000.0 < float(c):
				_checar_acerto(g)
	else:
		var dir := 0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or toque_dir:
			dir += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or toque_esq:
			dir -= 1
		var defesa := Input.is_key_pressed(KEY_SPACE) or toque_defesa
		var correr := Input.is_key_pressed(KEY_SHIFT) and dir > 0
		var quer := "guarda"
		if defesa:
			quer = "bloqueio"
			dir = 0
		elif dir > 0:
			quer = "correr" if correr else "andaFrente"
		elif dir < 0:
			quer = "andaTras"
		raiz.position.x += dir * (VEL_CORRER if correr else VEL_ANDAR) * dt
		var atual := String(j["ap"].current_animation)
		if atual != quer and atual != "entraGuarda":
			_tocar(j, quer, 0.12)
	raiz.position.x = clampf(raiz.position.x, -5.5, boneco["raiz"].position.x - SEPARACAO)
	_camera_luta()
	info.text = "Acertos: %d   [Tab] galeria%s" % [acertos, "   LENTO" if Engine.time_scale < 0.5 else ""]


func _checar_acerto(g: Array) -> void:
	var dist: float = boneco["raiz"].position.x - jogador["raiz"].position.x
	if dist > g[1] + 0.05:
		return
	jogador["acertou"] = g[0] != "comboJabCotoveloJoelho"  # combo acerta em cada golpe
	acertos += 1
	var alvo: Node3D = boneco["raiz"]
	var reacao: String = g[2]
	if acertos % 5 == 0:
		reacao = "queda"
	_tocar(boneco, reacao, 0.03)
	var tw := create_tween()
	tw.tween_property(alvo, "position:x", minf(alvo.position.x + 0.12, 5.5), 0.12)


func _camera_luta() -> void:
	var meio: Vector3 = (jogador["raiz"].position + boneco["raiz"].position) * 0.5
	var abertura: float = maxf(2.6, absf(boneco["raiz"].position.x - jogador["raiz"].position.x) + 1.8)
	camera.position = meio + Vector3(0.0, 1.15, abertura)
	camera.look_at(meio + Vector3(0, 0.95, 0))


func _camera_galeria() -> void:
	var c: Vector3 = jogador["raiz"].position
	camera.position = c + Vector3(sin(orbita) * 2.6, 1.2, cos(orbita) * 2.6)
	camera.look_at(c + Vector3(0, 0.85, 0))


# ------------------------------------------------------------- galeria
func _alternar_galeria() -> void:
	galeria = not galeria
	boneco["raiz"].visible = not galeria
	jogador["estado"] = "parado"
	if galeria:
		_mostrar_galeria()
	else:
		_tocar(jogador, "guarda")
	_atualizar_ajuda()


func _mostrar_galeria() -> void:
	var nome: String = nomes_galeria[idx_galeria]
	var d: Dictionary = manifesto[nome]
	_tocar(jogador, nome, 0.0)
	var contato := "" if d["contatoMs"] == null else "  contato %d ms" % d["contatoMs"]
	info.text = "%d/%d  %s\n2D: %s  %d ms%s%s" % [idx_galeria + 1, nomes_galeria.size(), nome,
		d["clipe2d"], d["duracaoMs"], contato, "  (loop)" if d["loop"] else ""]


func _passar_galeria(passo: int) -> void:
	idx_galeria = posmod(idx_galeria + passo, nomes_galeria.size())
	_mostrar_galeria()


# ------------------------------------------------------------ controles
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.keycode
		if k == KEY_TAB:
			_alternar_galeria()
		elif k == KEY_F:  # camera lenta para ver os golpes quadro a quadro
			Engine.time_scale = 0.15 if Engine.time_scale > 0.5 else 1.0
		elif galeria:
			if k in [KEY_RIGHT, KEY_D]:
				_passar_galeria(1)
			elif k in [KEY_LEFT, KEY_A]:
				_passar_galeria(-1)
			elif k in [KEY_ENTER, KEY_J, KEY_SPACE]:
				_mostrar_galeria()
		elif TECLAS.has(k):
			_golpear(TECLAS[k])


func _montar_interface() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var tema := Theme.new()
	tema.default_font_size = 9
	var raiz := Control.new()
	raiz.theme = tema
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(raiz)
	info = Label.new()
	info.position = Vector2(6, 4)
	raiz.add_child(info)
	ajuda = Label.new()
	ajuda.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ajuda.position = Vector2(-6, 4)
	ajuda.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	raiz.add_child(ajuda)
	_atualizar_ajuda()

	# botoes de toque (celular)
	var esq := _botao(raiz, "<", Vector2(6, -40), Control.PRESET_BOTTOM_LEFT)
	esq.button_down.connect(func(): _toque_lado(-1))
	esq.button_up.connect(func(): toque_esq = false)
	var dir := _botao(raiz, ">", Vector2(44, -40), Control.PRESET_BOTTOM_LEFT)
	dir.button_down.connect(func(): _toque_lado(1))
	dir.button_up.connect(func(): toque_dir = false)
	var defe := _botao(raiz, "DEF", Vector2(82, -40), Control.PRESET_BOTTOM_LEFT)
	defe.button_down.connect(func(): toque_defesa = true)
	defe.button_up.connect(func(): toque_defesa = false)
	var x := -40.0
	for par in [["GAL", ""], ["CHU", "circular"], ["DIR", "direto"], ["JAB", "jab"]]:
		var b := _botao(raiz, par[0], Vector2(x, -40), Control.PRESET_BOTTOM_RIGHT)
		if par[1] == "":
			b.pressed.connect(_alternar_galeria)
		else:
			var golpe: String = par[1]
			b.pressed.connect(func(): _mostrar_galeria() if galeria else _golpear(golpe))
		x -= 38.0


func _toque_lado(lado: int) -> void:
	if galeria:
		_passar_galeria(lado)
	elif lado < 0:
		toque_esq = true
	else:
		toque_dir = true


func _botao(pai: Control, texto: String, pos: Vector2, ancora: int) -> Button:
	var b := Button.new()
	b.text = texto
	b.set_anchors_preset(ancora)
	b.position = pos
	b.size = Vector2(34, 34)
	b.focus_mode = Control.FOCUS_NONE
	b.modulate = Color(1, 1, 1, 0.75)
	pai.add_child(b)
	return b


func _atualizar_ajuda() -> void:
	if galeria:
		ajuda.text = "GALERIA\n< > troca   Enter repete\nF camera lenta   Tab volta"
	else:
		ajuda.text = "A/D anda  Shift corre  Espaco defende\nJ jab  K direto  L gancho  U uppercut\nH pesado  N jab corpo  Y cotovelada\nI circular  O alto  M baixo  P joelhada\nB combo   F camera lenta   Tab galeria"

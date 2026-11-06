extends "res://prototipo/hud.gd"
var gallery_button: Button
var suspicion_bar: ProgressBar
var suspicion: Label
var rec: Label
var escape_prompt: Label
var escape_row: Control
var escape_black: ColorRect

var luz_label: Label
var titulo: Label
var creditos_painel: Panel
var creditos_texto: RichTextLabel
const CREDITOS:="[b]GAVIÃO — CAPÍTULO 1[/b]\n\n[b]Criação[/b]\nFelipe — história, direção, personagens e testes\n\n[b]Animações[/b]\nQuaternius — Universal Animation Library (CC0)\nMixamo (Adobe)\n\n[b]Sons[/b]\nKenney — Impact Sounds, RPG Audio, Interface Sounds (CC0)\nartisticdude — OpenGameArt (CC0)\nTinyWorlds — OpenGameArt (CC0)\nCoração: gerado no projeto\n\n[b]Fonte[/b]\nWork Sans — SIL Open Font License 1.1\n\n[b]Motor[/b]\nGodot Engine — licença MIT\n\n[K] fechar"
func alternar_creditos() -> void:
 if creditos_painel==null:
  creditos_painel=Panel.new(); root.add_child(creditos_painel)
  var fundo=StyleBoxFlat.new(); fundo.bg_color=Color(.015,.017,.024,.98); fundo.set_corner_radius_all(6)
  creditos_painel.add_theme_stylebox_override("panel",fundo)
  creditos_texto=RichTextLabel.new(); creditos_texto.bbcode_enabled=true; creditos_painel.add_child(creditos_texto)
  creditos_texto.text=CREDITOS+"\n\n[b]Licença do Godot Engine[/b]\n"+Engine.get_license_text()
  creditos_painel.visible=false
 creditos_painel.visible=not creditos_painel.visible
 var tela=get_viewport().get_visible_rect().size
 creditos_painel.size=tela*Vector2(.8,.86); creditos_painel.position=tela*Vector2(.1,.07)
 creditos_texto.position=Vector2(24,20); creditos_texto.size=creditos_painel.size-Vector2(48,40)
 creditos_texto.scroll_to_line(0)
var objetivo_ate:=0
var objetivo_ultimo:=""
func mostrar_objetivo(segundos:=4.0) -> void:
 objetivo_ate=Time.get_ticks_msec()+int(segundos*1000)
func setup(owner_game: Node3D) -> void:
 super.setup(owner_game)
 if OS.is_debug_build():
  gallery_button=Button.new();gallery_button.text="Galeria de personagens · F10"
  gallery_button.custom_minimum_size=Vector2(300,52);root.add_child(gallery_button)
  gallery_button.pressed.connect(game.open_gallery)
 suspicion=label(root,18)
 luz_label=label(root,15)
 titulo=label(root,72); titulo.text="G A V I Ã O"; titulo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 titulo.add_theme_color_override("font_color",Color(.86,.88,.92))
 titulo.add_theme_color_override("font_outline_color",Color(0,0,0,.8)); titulo.add_theme_constant_override("outline_size",8)
 suspicion_bar=ProgressBar.new(); suspicion_bar.show_percentage=false; root.add_child(suspicion_bar)
 rec=label(root,20)
 escape_prompt=label(root,24)
 escape_prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 escape_prompt.visible=false
 escape_row=Control.new(); escape_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 root.add_child(escape_row); escape_row.draw.connect(_draw_escape_sequence)
 var death_layer=CanvasLayer.new(); death_layer.layer=100; add_child(death_layer)
 var death_root=Control.new(); death_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 death_layer.add_child(death_root)
 escape_black=rectangle(death_root,Color.BLACK)
 escape_black.visible=false

func update(dt: float) -> void:
 super.update(dt)
 var size=get_viewport().get_visible_rect().size
 if gallery_button!=null:
  gallery_button.visible=not game.started or game.paused
  gallery_button.position=Vector2(maxf(8,size.x-320),size.y-70)
 var cinematic=game.phase in ["intro","sighting","discovery","gate_jump","ending","cozinha","laboratorio"]
 message.modulate=Color.WHITE
 vitals.visible=not cinematic
 # HUD mínimo (Felipe): objetivo só quando muda (6 s) ou com [Tab].
 objective.visible=game.started and not cinematic and (Time.get_ticks_msec()<objetivo_ate or Input.is_physical_key_pressed(KEY_TAB))
 top_bar.visible=cinematic and not game.paused
 bottom_bar.visible=cinematic and not game.paused
 objective.text="Busque a bolsa no terceiro de Informática, no andar superior."
 if game.bag_found: objective.text="Desça e descubra o que acontece no pátio de química."
 if game.video_recorded: objective.text="Saia pulando o portão 1."
 if game.phase=="chase": objective.text="FUJA · quebre a visão antes de se esconder."
 if game.phase=="intro":
  var ab=game.abertura
  message.text="" if ab==null else ("%s: %s"%[ab.falante,ab.legenda] if ab.legenda!="" else "")
 elif game.phase=="cozinha" and game.cozinha!=null:
  var cz=game.cozinha
  if cz.estado=="jogo":
   message.text=game.objectives.text("cozinha_agora") if cz.janela_aberta() else game.objectives.text("cozinha_espera")
   message.modulate=Color(1,.95,.55) if cz.janela_aberta() else Color(.7,.7,.72)
  else: message.text=""
 elif game.phase=="laboratorio" and game.laboratorio!=null:
  var lab=game.laboratorio
  if lab.estado=="esconder": message.text=game.objectives.text("lab_esconder"); message.modulate=Color(1,.85,.45)
  elif lab.estado=="escondido": message.text=game.objectives.text("lab_parado"); message.modulate=Color(.75,.75,.8)
  else: message.text=""
 elif game.phase=="sighting": message.text="Um desconhecido segue para o corredor."
 elif game.phase=="discovery": message.text="A gravação continua." if game.discovery_clock<5.7 else "Miguel paralisa por um instante."
 elif game.phase=="gate_jump": message.text=""
 elif game.phase=="ending":
  var t: float=game.ending_clock
  if t>=3.5 and t<6.5: message.text="Enviando vídeo…  %d%%"%int(clampf((t-3.5)/2.6,0,1)*100)
  elif t>=16.0: message.text="CAPÍTULO 1 CONCLUÍDO"
  else: message.text=""
 suspicion.position=Vector2(18,70)
 var level=game.vigilance_level()
 suspicion.visible=level>.10
 if game.objectives!=null:
  suspicion.text=game.objectives.text("vigilancia")+" %d%%"%roundi(level*100)
 suspicion.modulate=Color(1,.8,.35)
 suspicion_bar.position=Vector2(18,102); suspicion_bar.size=Vector2(minf(260,size.x*.65),10)
 suspicion_bar.visible=suspicion.visible; suspicion_bar.value=level*100
 # Luz sobre Miguel (percepção dos cultistas): sombra esconde, luz expõe.
 var jogando: bool=game.phase in ["investigate","chase"] and not game.paused and not game.player.hidden
 # Só com cultista por perto (HUD mínimo).
 var algum_perto: bool=game.enemies.any(func(e): return not e.dead and e.position.distance_to(game.player.position)<12.0)
 luz_label.visible=jogando and game.percepcao!=null and algum_perto
 if luz_label.visible:
  var l: float=game.percepcao.luz
  luz_label.text="◐ na sombra" if l<.3 else ("◑ meia-luz" if l<.65 else "● na luz")
  luz_label.modulate=Color(.55,.6,.7,.85) if l<.3 else (Color(.85,.8,.6,.9) if l<.65 else Color(1,.9,.5))
  luz_label.position=Vector2(18,118 if suspicion.visible else 70)
 if game.objectives!=null and not cinematic and not game.bag_found:
  objective.text=game.objectives.text("objetivo_bolsa" if game.objectives.has_key() else "objetivo_chave")
 if objective.text!=objetivo_ultimo:
  objetivo_ultimo=objective.text; mostrar_objetivo(6.0)
 rec.position=Vector2(size.x-180,25)
 rec.text="● REC %02d s"%int(game.record_time) if game.recording and game.phase in ["investigate","discovery"] else ""
 rec.modulate=Color(.9,.22,.19)
 if game.player.state=="attack" and game.fatigue>.35:
  prompt.text="RESPIRAÇÃO PESADA"
 if game.phase=="escaped":
  menu.text="CAPÍTULO 1 CONCLUÍDO\n\nMiguel escapou com a gravação.\nOs amigos agora sabem do culto.\n\n[Enter] Jogar novamente    ·    [K] Créditos"
  if game.touch!=null: menu.text=menu.text.replace("[Enter]","Toque:")
 elif not game.started and game.touch!=null:
  menu.text="GAVIÃO\nDEPOIS DO ALMOÇO\n\nUma escola vazia. Vozes que não deveriam estar ali.\n\nToque para começar\n\nCelular deitado · fones recomendados"
 elif game.paused and game.started:
  menu.text="PAUSADO\n\n[Esc] Voltar · [R] Checkpoint\n\nWASD mover · mouse olhar\nShift correr · Ctrl agachar\nEspaço interagir / porta / parkour\nAgarrão: repita a sequência com WASD ou setas\nE empanado · V vídeo · L lanterna após bolsa\nT arremessar objeto · F fresta · F3 filtro ligado/desligado"
  if game.touch!=null: menu.text="PAUSADO\n\nToque para voltar\n\nEsquerda: mover (até a borda corre)\nDireita: arrastar para olhar\nBotões: ação,\nagachar, gravar, luz, fresta, comer"
 # Tela de título: escola à noite ao fundo, logo grande.
 titulo.visible=not game.started and not (creditos_painel!=null and creditos_painel.visible)
 menu.visible=not (creditos_painel!=null and creditos_painel.visible)
 if not game.started:
  panel.color=Color(.012,.014,.02,.28)
  titulo.position=Vector2(0,size.y*.16); titulo.size=Vector2(size.x,100)
  menu.position=Vector2(size.x*.2,size.y*.42)
  menu.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  menu.text="DEPOIS DO ALMOÇO\n\nUma escola vazia. Vozes que não deveriam estar ali.\n\n"+("Toque para começar" if game.touch!=null else "[Enter] Começar    ·    [C] Continuar    ·    [K] Créditos")+"\n\nfones recomendados"
 else:
  panel.color=Color(.012,.014,.02,.94); menu.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 if game.walk_mode:
  rec.text="PASSEIO DEBUG · F9 sair"; rec.position.x=size.x-300; rec.modulate=Color(.8,1,.85)
  if game.paused: menu.text="PASSEIO DEBUG\n\nEsc: voltar\nF9: sair e retomar checkpoint\n\nWASD mover · Shift correr · Ctrl agachar\nEspaço: abrir/fechar porta · F3: filtro"
 # Terror: sem barra de jogo de luta. Vida só aparece ferido; itens só quando há.
 var parts: Array[String]=[]
 if game.player.health<99: parts.append("FERIDO" if game.player.health>35 else "MUITO FERIDO")
 if game.food>0: parts.append("EMPANADO ×%d"%game.food)
 if game.knife: parts.append("FACA")
 if game.objectives!=null:
  if game.objectives.has_key(): parts.append(game.objectives.text("chave_inventario"))
  if game.finisher_item_available: parts.append(game.objectives.text("finalizador_inventario"))
  if game.bag_found: parts.append(game.objectives.text("celular"))
 vitals.text="   ".join(parts)
 vitals.modulate=Color(1,.55,.5) if game.player.health<=35 else Color(1,1,1,.85)
 if game.touch!=null:
  # No celular, dicas citam os botões; mensagem acima dos botões.
  for item in [message,prompt]: item.text=touch_text(item.text)
  message.position.y=minf(message.position.y,size.y*.55)

 escape_prompt.visible=game.escape.active and not game.paused
 escape_row.visible=escape_prompt.visible
 escape_prompt.position=Vector2(size.x*.1,size.y*.16)
 escape_prompt.size=Vector2(size.x*.8,70)
 escape_prompt.text="AGARRADO · %.1f s\n%s"%[game.escape.remaining,"Toque nas setas, da esquerda para a direita" if game.touch!=null else "WASD ou setas · da esquerda para a direita"]
 escape_row.queue_redraw()
 if game.escape.active:
  message.text=""; prompt.text=""; vitals.visible=false; objective.visible=false
 show_escape_blackout((game.phase=="ending" and game.ending_clock>=6.5 and game.ending_clock<6.9) or game.escape_blackout>0 or (game.phase=="intro" and game.abertura!=null and game.abertura.preto()) or (game.phase=="duto" and game.ventilacao!=null and game.ventilacao.preto()))

func show_escape_blackout(on: bool) -> void:
 escape_black.size=get_viewport().get_visible_rect().size
 escape_black.visible=on

func _draw_escape_sequence() -> void:
 if not game.escape.active or game.paused: return
 var screen=get_viewport().get_visible_rect().size
 var width=clampf(screen.x/(game.escape.sequence.size()+2),36,64)
 var left=(screen.x-width*game.escape.sequence.size())*.5
 for i in game.escape.sequence.size():
  var at=Vector2(left+width*(i+.5),screen.y*.33)
  var color=Color(.45,.95,.65) if i<game.escape.cursor else Color(1,.95,.8)
  if i==game.escape.cursor:
   escape_row.draw_rect(Rect2(at-Vector2.ONE*width*.46,Vector2.ONE*width*.92),Color(.5,.15,.08,.9))
  draw_escape_arrow(escape_row,at,game.escape.sequence[i],width*.30,color)

func draw_escape_arrow(canvas: Control,at: Vector2,code: int,radius: float,color: Color) -> void:
 var direction=Vector2.UP
 match code:
  KEY_RIGHT: direction=Vector2.RIGHT
  KEY_DOWN: direction=Vector2.DOWN
  KEY_LEFT: direction=Vector2.LEFT
 var side=direction.orthogonal()
 canvas.draw_line(at-direction*radius,at+direction*radius,color,4,true)
 canvas.draw_line(at+direction*radius,at+side*radius*.65,color,4,true)
 canvas.draw_line(at+direction*radius,at-side*radius*.65,color,4,true)

const TOUCH_NAMES:={"[Espaço]":"[AÇÃO]","[V]":"[GRAVAR]","[F]":"[FRESTA]","[L]":"[LUZ]","[E]":"[COMER]","[T]":""}
func touch_text(text: String) -> String:
 for key in TOUCH_NAMES: text=text.replace(key,TOUCH_NAMES[key])
 return text


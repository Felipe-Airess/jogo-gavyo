extends "res://prototipo/hud.gd"
var suspicion: Label
var rec: Label
var escape_prompt: Label
var escape_row: Control
var escape_black: ColorRect

func setup(owner_game: Node3D) -> void:
 super.setup(owner_game)
 suspicion=label(root,18)
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
 var cinematic=game.phase in ["intro","sighting","discovery","gate_jump","ending"]
 vitals.visible=not cinematic
 objective.visible=not cinematic
 top_bar.visible=cinematic and not game.paused
 bottom_bar.visible=cinematic and not game.paused
 objective.text="Busque a bolsa no terceiro de Informática, no andar superior."
 if game.bag_found: objective.text="Desça e descubra o que acontece no pátio de química."
 if game.video_recorded: objective.text="Saia pulando o portão 1."
 if game.phase=="chase": objective.text="FUJA · quebre a visão antes de se esconder."
 if game.phase=="intro":
  message.text="Miguel descansou no depósito depois do almoço.\nA bolsa e o celular ficaram na sala." if game.intro_clock<3.3 else "Anoiteceu. Um barulho vem de fora."
 elif game.phase=="sighting": message.text="Um desconhecido segue para o corredor."
 elif game.phase=="discovery": message.text="A gravação continua." if game.discovery_clock<5.7 else "Miguel paralisa por um instante."
 elif game.phase=="gate_jump": message.text=""
 elif game.phase=="ending":
  if game.ending_clock<4: message.text="Fora da escola, Miguel envia o vídeo aos amigos."
  elif game.ending_clock<8: message.text="CAPÍTULO 1 CONCLUÍDO"
  else: message.text="Bola e Felipe recebem a prova.\nO que parecia brincadeira agora precisa ser investigado."
 suspicion.position=Vector2(size.x*.44,95)
 var level=0.0
 for e in game.enemies:
  if not e.dead and not e.aware: level=maxf(level,e.suspicion)
 if not game.ritual_noticed:
  for e in game.school.ritual_figures: level=maxf(level,e.suspicion)
 suspicion.text="◌" if level>.10 else ""
 suspicion.modulate=Color(1,.8,.35,clampf(level+.2,0,1))
 rec.position=Vector2(size.x-180,25)
 rec.text="● REC %02d s"%int(game.record_time) if game.recording and game.phase in ["investigate","discovery"] else ""
 rec.modulate=Color(.9,.22,.19)
 if game.player.state=="attack" and game.fatigue>.35:
  prompt.text="RESPIRAÇÃO PESADA"
 if game.phase=="escaped":
  menu.text="CAPÍTULO 1 CONCLUÍDO\n\nMiguel escapou com a gravação.\nOs amigos agora sabem do culto.\n\n[Enter] Jogar novamente"
  if game.touch!=null: menu.text=menu.text.replace("[Enter]","Toque:")
 elif not game.started and game.touch!=null:
  menu.text="GAVIÃO\nDEPOIS DO ALMOÇO\n\nUma escola vazia. Vozes que não deveriam estar ali.\n\nToque para começar\n\nCelular deitado · fones recomendados"
 elif game.paused and game.started:
  menu.text="PAUSADO\n\n[Esc] Voltar · [R] Checkpoint\n\nWASD mover · mouse olhar\nShift correr · Ctrl agachar\nEspaço interagir / porta / parkour\nAgarrão: repita a sequência com WASD ou setas\nE empanado · V vídeo · L lanterna após bolsa\nT arremessar objeto · F fresta · F3 filtro ligado/desligado"
  if game.touch!=null: menu.text="PAUSADO\n\nToque para voltar\n\nEsquerda: mover (até a borda corre)\nDireita: arrastar para olhar\nBotões: ação,\nagachar, gravar, luz, fresta, comer"
 if game.walk_mode:
  rec.text="PASSEIO DEBUG · F9 sair"; rec.position.x=size.x-300; rec.modulate=Color(.8,1,.85)
  if game.paused: menu.text="PASSEIO DEBUG\n\nEsc: voltar\nF9: sair e retomar checkpoint\n\nWASD mover · Shift correr · Ctrl agachar\nEspaço: abrir/fechar porta · F3: filtro"
 # Terror: sem barra de jogo de luta. Vida só aparece ferido; itens só quando há.
 var parts: Array[String]=[]
 if game.player.health<99: parts.append("FERIDO" if game.player.health>35 else "MUITO FERIDO")
 if game.food>0: parts.append("EMPANADO ×%d"%game.food)
 if game.knife: parts.append("FACA")
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
 show_escape_blackout(game.escape_blackout>0)

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


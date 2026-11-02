extends CanvasLayer
var game: Node3D
var vitals: Label
var objective: Label
var prompt: Label
var message: Label
var panel: ColorRect
var menu: Label
var flash: ColorRect
var top_bar: ColorRect
var bottom_bar: ColorRect
var remaining:=0.0
var current_message:=""
var root: Control

func setup(owner_game: Node3D) -> void:
 game=owner_game
 root=Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var theme=Theme.new()
 # load(): na exportação o .ttf vira recurso importado; ler bytes crus falha.
 var font: Font=load("res://prototipo/interface.ttf")
 theme.default_font=font
 theme.default_font_size=18
 theme.set_constant("outline_size","Label",3)
 theme.set_color("font_outline_color","Label",Color(.015,.015,.02))
 root.theme=theme
 top_bar=rectangle(root,Color.BLACK)
 bottom_bar=rectangle(root,Color.BLACK)
 vitals=label(root,18)
 objective=label(root,17)
 prompt=label(root,18)
 message=label(root,22)
 message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 flash=rectangle(root,Color(.6,0,0,0))
 panel=rectangle(root,Color(.012,.014,.02,.94))
 menu=label(panel,21)
 menu.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func rectangle(parent: Control, color: Color) -> ColorRect:
 var result=ColorRect.new()
 result.color=color
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(result)
 return result

func label(parent: Control, font_size: int) -> Label:
 var result=Label.new()
 result.add_theme_font_size_override("font_size",font_size)
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(result)
 return result

func say(text: String, duration:=3.0) -> void:
 current_message=text
 remaining=duration

func update(dt: float) -> void:
 var size=get_viewport().get_visible_rect().size
 var scale=clampf(size.y/720.0,.7,1.4)
 vitals.position=Vector2(24,20)*scale
 vitals.size=Vector2(size.x-48*scale,28*scale)
 objective.position=Vector2(24,50)*scale
 objective.size=Vector2(size.x-48*scale,42*scale)
 prompt.position=Vector2(24*scale,size.y-58*scale)
 prompt.size=Vector2(size.x-48*scale,46*scale)
 message.position=Vector2(size.x*.15,size.y-135*scale)
 message.size=Vector2(size.x*.7,80*scale)
 panel.size=size
 flash.size=size
 menu.position=Vector2(size.x*.20,size.y*.1)
 menu.size=Vector2(size.x*.60,size.y*.82)
 top_bar.size=Vector2(size.x,45*scale)
 bottom_bar.position=Vector2(0,size.y-80*scale)
 bottom_bar.size=Vector2(size.x,80*scale)
 remaining=maxf(0,remaining-dt)
 flash.color.a=maxf(0,flash.color.a-dt*.7)
 message.text=current_message if remaining>0 else ""
 var cinematic=game.phase in ["intro","discovery"]
 top_bar.visible=cinematic and not game.paused
 bottom_bar.visible=cinematic and not game.paused
 vitals.visible=not cinematic
 objective.visible=not cinematic
 vitals.text="MIGUEL  %d%%    EMPANADOS %d    FACA %s"%[ceili(game.player.health),game.food,"SIM" if game.knife else "—"]
 objective.text={"investigate":"Investigue as vozes no bloco B.","chase":"SAIA DA ESCOLA. Corra ou quebre a visão e se esconda.","escaped":"Fora da escola. É preciso avisar os outros."}.get(game.phase,"")
 prompt.text=game.context_text()
 if game.phase=="intro":
  if game.intro_clock<2.6:
   message.text="Miguel, monitor de educação física.\nEra só um cochilo no horário do almoço."
  elif game.intro_clock<5.2:
   message.text="21:43. Sem sinal. Ninguém veio chamar."
  else:
   message.text="Miguel: de onde estão vindo essas vozes?"
 elif game.phase=="discovery":
  message.text="Miguel: o que estão fazendo aqui?" if game.discovery_clock<.9 else "Você não devia estar aqui."
 if game.player.state=="heal":
  prompt.text="COMENDO EMPANADO  %d%% — mover ou sofrer dano cancela"%int(game.player.clock/2.4*100)
 panel.visible=game.paused or game.player.dead or game.phase=="escaped"
 if not panel.visible:
  return
 if game.player.dead:
  menu.text="MIGUEL MORREU\n\n[R] Retomar o checkpoint\n\nO progresso posterior será perdido."
 elif game.phase=="escaped":
  menu.text="FORA DA ESCOLA\n\nMiguel: preciso avisar os outros.\n\nFIM DO CAPÍTULO DE TESTE\n\n[Enter] Jogar novamente"
 elif game.started:
  menu.text="PAUSADO\n\n[Esc] Voltar · [R] Checkpoint\n\nWASD mover · mouse olhar\nShift correr · Ctrl agachar\nEspaço interagir / abrir porta / parkour\nF espiar pela fresta da porta\nClique direito esquivar (+ direção: deslocar)\nClique esquerdo contra-atacar na abertura\nBotão do meio travar · rodinha trocar alvo\nE comer empanado · F1 ajuda\n\nEsta versão testa uma troca de golpes."
 else:
  menu.text="GAVIÃO\nDEPOIS DO ALMOÇO\n\nUma escola vazia. Vozes que não deveriam estar ali.\n\n[Enter] Começar\n[C] Continuar checkpoint\n\nTeclado e mouse · fones recomendados"

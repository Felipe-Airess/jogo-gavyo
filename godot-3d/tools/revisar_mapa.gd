extends SceneTree
## Renderiza o mundo real para revisão; só a instância temporária é filtrada.
## Nunca grava grade, altera ossos ou acrescenta decoração.
const OUT="res://../docs/revisao-mapa/"
const FONT=preload("res://prototipo/interface.ttf")
const NIVEL=preload("res://capitulo1/nivel.gd")
var game
var viewport: SubViewport
var cam: Camera3D
var overlay: Control
var route_overlay: Control
var rooms: Array=[]
var paths: Array=[]
var markers: Array=[]
var show_route:=false
var current_floor:=0
var meta: Dictionary={}
func _initialize() -> void: call_deferred("run")
func label(text: String,at: Vector2,size: Vector2,font_size:=24,bg:=true) -> Label:
 var wrapped: Array[String]=[]; var row=""
 for word in text.split(" "):
  var candidate=word if row.is_empty() else row+" "+word
  if not row.is_empty() and FONT.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x-10:
   wrapped.append(row); row=word
  else: row=candidate
 if not row.is_empty(): wrapped.append(row)
 var l=Label.new(); l.text="\n".join(wrapped); l.position=at
 l.size=Vector2(size.x,wrapped.size()*(font_size*1.35)+8)
 l.add_theme_font_override("font",FONT); l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",Color(.04,.07,.10))
 l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if bg:
  var style=StyleBoxFlat.new(); style.bg_color=Color(.97,.98,1,.94)
  style.content_margin_left=5; style.content_margin_right=5
  l.add_theme_stylebox_override("normal",style)
 overlay.add_child(l); return l
func point(p: Vector3) -> Vector2: return cam.unproject_position(p)
func collect() -> void:
 var school=game.school
 var names=school.rooms.keys()
 names.sort_custom(func(a,b):
  var ra=school.rooms[a]; var rb=school.rooms[b]
  if ra["andar"]!=rb["andar"]: return ra["andar"]<rb["andar"]
  if ra["rect"].position.y!=rb["rect"].position.y: return ra["rect"].position.y<rb["rect"].position.y
  return ra["rect"].position.x<rb["rect"].position.x)
 var id:=0
 for name in names:
  var r=school.rooms[name]; var rect: Rect2=r["rect"]
  var item={"name":name,"id":0,"andar":r["andar"],"sala":r["sala"],"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"blocks":[],"hides":[],"doors":[],"items":[]}
  if r["sala"]: id+=1; item["id"]=id
  var grid=school.andares[r["andar"]]
  if r["sala"]:
   for v in grid.celulas("%&@$L"):
    if rect.has_point(Vector2(v)): item["blocks" if grid.chv(v)=="%" else "hides" if grid.chv(v)=="&" else "items"].append([v.x,v.y,grid.chv(v)])
   for door in school.doors:
    if door.title==name: item["doors"].append({"name":door.title,"locked":false})
   for pickup in school.pickups:
    if school.ambiente_de(pickup["at"])==name: item["items"].append(pickup["kind"])
   for tool in game.tools:
    if school.ambiente_de(tool["at"])==name: item["items"].append(tool["name"])
  rooms.append(item)
 meta={"rooms":rooms,"corner_test":corner_cases(school),"route_pending":"F: sala com celular/bolsa não identificada; posição atual é 3 Informática, superior","new_story_implemented":false}
 var file=FileAccess.open(OUT+"ambientes.json",FileAccess.WRITE); file.store_string(JSON.stringify(meta," ")); file.close()
 print("AMBIENTES salas=",id," areas=",rooms.size()-id," quina_bloqueia_visao=",not meta["corner_test"].is_empty())
func corner_cases(school) -> Array:
 var grid=school.andares[0]; var found: Array=[]
 for z in grid.altura:
  for x in grid.largura:
   if grid.ch(x,z)!="#" or grid.ch(x+1,z)!="#" or grid.ch(x,z+1)!="#": continue
   var a=Vector2i(x-1,z+2); var b=Vector2i(x+2,z-1)
   if grid.e_vazio(a.x,a.y) or grid.e_vazio(b.x,b.y) or grid.chv(a) in "#-DWG%CT" or grid.chv(b) in "#-DWG%CT": continue
   if not game.visible_between(school.cel(a.x,a.y,1.5),school.cel(b.x,b.y,1.5)):
    found.append({"a":[a.x,a.y],"b":[b.x,b.y],"visible":false})
   if found.size()>=4: return found
 return found

func nearest(grid,cell: Vector2i) -> Vector2i:
 for radius in 8:
  for dx in range(-radius,radius+1):
   for dz in range(-radius,radius+1):
    var c=cell+Vector2i(dx,dz)
    if grid.chv(c) not in " #-WG%CT" and not grid.e_vazio(c.x,c.y): return c
 return cell
func upper_path(a: Vector3,b: Vector3) -> Array:
 var grid=game.school.andares[1]
 var start=nearest(grid,game.school.celula_de(a)); var end=nearest(grid,game.school.celula_de(b))
 var queue: Array=[start]; var previous: Dictionary={start:start}
 while not queue.is_empty():
  var v=queue.pop_front()
  if v==end: break
  for d in grid.VIZINHOS:
   var n=v+d
   if previous.has(n) or grid.e_vazio(n.x,n.y) or grid.chv(n) in "#-WG%CT": continue
   previous[n]=v; queue.append(n)
 var result: Array=[]
 if previous.has(end):
  var cursor=end
  while cursor!=start: result.push_front(game.school.cel(cursor.x,cursor.y,game.school.LEVEL)); cursor=previous[cursor]
  result.push_front(a); result.append(b)
 return result
func ground_path(a: Vector3,b: Vector3) -> Array:
 var graph=game.path_grid
 var start=Vector2i(roundi(a.x*2),roundi(a.z*2)); var end=Vector2i(roundi(b.x*2),roundi(b.z*2))
 for which in 2:
  var cell=start if which==0 else end; var found=false
  for radius in 5:
   if found: break
   for dx in range(-radius,radius+1):
    if found: break
    for dz in range(-radius,radius+1):
     var candidate=cell+Vector2i(dx,dz)
     if graph.is_in_boundsv(candidate) and not graph.is_point_solid(candidate):
      if which==0: start=candidate
      else: end=candidate
      found=true; break
 var result: Array=[]
 if graph.is_in_boundsv(start) and graph.is_in_boundsv(end):
  for p in graph.get_point_path(start,end,false): result.append(Vector3(p.x,0,p.y))
 print("TRECHO ",a," -> ",b," pontos=",result.size())
 return result
func line(points: Array,color: Color,width:=6.0,dashed:=false) -> void:
 if points.size()<2: return
 for i in range(1,points.size()):
  var a=point(points[i-1]); var b=point(points[i])
  if dashed: route_overlay.draw_dashed_line(a,b,color,width,18,true)
  else: route_overlay.draw_line(a,b,color,width,true)
  if i==points.size()-1:
   var d=(b-a).normalized(); var side=d.orthogonal()
   route_overlay.draw_colored_polygon(PackedVector2Array([b,b-d*21+side*11,b-d*21-side*11]),color)
func draw_route() -> void:
 if not show_route: return
 for path in paths: line(path["points"],path["color"],7)
 for m in markers:
  var at=point(m["at"])
  route_overlay.draw_circle(at,21,Color(.07,.12,.18)); route_overlay.draw_arc(at,23,0,TAU,40,Color.WHITE,3)
  route_overlay.draw_string(FONT,at+Vector2(-8,9),m["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color.WHITE)
 if current_floor==0:
  var box=Rect2(Vector2(75,viewport.size.y*.73),Vector2(1150,225))
  route_overlay.draw_rect(box,Color(1,.95,.84,.98)); route_overlay.draw_rect(box,Color(.65,.25,.04),false,4)
  route_overlay.draw_multiline_string(FONT,box.position+Vector2(25,45),"F · SALA COM CELULAR/BOLSA: LOCAL A DEFINIR\nA posição atual fica em 3 Informática (superior).\nFelipe deve indicar qual sala recebe este passo da rota.\nTracejado: ligação de roteiro, sem caminho físico aprovado.",HORIZONTAL_ALIGNMENT_LEFT,-1,27,-1,Color(.25,.10,.02))
  var from=point(game.school.rooms["Cozinha"]["center"])
  route_overlay.draw_dashed_line(from,box.position+Vector2(box.size.x,70),Color(.75,.35,.02),6,20)
  route_overlay.draw_dashed_line(box.position+Vector2(box.size.x,130),point(NIVEL.ponto(game.school,"gravar")),Color(.75,.35,.02),6,20)
func shot(name: String) -> void:
 await process_frame; await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png(OUT+name+".png")
 print("CAPTURA ",name," ",viewport.size)
func render_floor(level: int) -> void:
 current_floor=level; paths.clear(); markers.clear()
 game=load("res://capitulo1/main.tscn").instantiate(); root.add_child(game)
 game.set_walk_mode(true); game.set_process(false); game.set_physics_process(false); game.player.visible=false
 for i in 3: await physics_frame
 var school=game.school
 for door in school.doors: door.set_open(true,true)
 await physics_frame; game._build_paths()
 if level==0: collect()
 school.telhados.visible=false
 for map in [school.mapa,school.pisos]:
  for cell in map.get_used_cells():
   if cell.y!=level: map.set_cell_item(cell,-1)
 for visual in school.find_children("*","MeshInstance3D",true,false):
  var bounds: AABB=visual.global_transform*visual.get_aabb()
  if level==0 and bounds.position.y>=school.LEVEL-.05: visual.visible=false
  if level==1 and bounds.end.y<=school.LEVEL-.05: visual.visible=false
 for sign in school.find_children("*","Label3D",true,false): sign.visible=false
 for light in school.find_children("*","DirectionalLight3D",true,false): light.light_energy=.8; light.shadow_enabled=false
 var grid=school.andares[level]; var lo=Vector2i(999,999); var hi=Vector2i(-999,-999)
 for z in grid.altura:
  for x in grid.largura:
   if grid.e_vazio(x,z): continue
   lo=lo.min(Vector2i(x,z)); hi=hi.max(Vector2i(x,z))
 var rect=Rect2(Vector2(lo),Vector2(hi-lo+Vector2i.ONE)).grow(2)
 var scale=36 if level==0 else 55
 viewport=SubViewport.new(); viewport.size=Vector2i(ceili(rect.size.x*scale),ceili(rect.size.y*scale)+360)
 viewport.world_3d=game.get_world_3d(); viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
 cam=Camera3D.new(); viewport.add_child(cam); cam.current=true; cam.far=400
 cam.projection=Camera3D.PROJECTION_ORTHOGONAL; cam.keep_aspect=Camera3D.KEEP_HEIGHT; cam.size=float(viewport.size.y)/scale
 var center=Vector3(rect.get_center().x+school.ORIGEM.x,level*school.LEVEL,rect.get_center().y+school.ORIGEM.z)
 cam.global_position=center+Vector3.UP*120; cam.look_at(center,Vector3.FORWARD)
 var env=Environment.new(); env.background_mode=Environment.BG_COLOR; env.background_color=Color(.91,.93,.96)
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color.WHITE; env.ambient_light_energy=1
 cam.environment=env
 overlay=Control.new(); overlay.size=Vector2(viewport.size); overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
 viewport.add_child(overlay)
 route_overlay=Control.new(); route_overlay.size=Vector2(viewport.size); route_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE; route_overlay.z_index=10
 viewport.add_child(route_overlay); route_overlay.draw.connect(draw_route)
 await process_frame
 var title="TÉRREO" if level==0 else "SUPERIOR"
 label("REVISÃO DO MAPA CINZA · "+title,Vector2(0,20),Vector2(viewport.size.x,65),38,false)
 label("Render do jogo · norte para cima · tetos ocultos · portas abertas só na captura · nomes/rotas sobrepostos",Vector2(20,90),Vector2(viewport.size.x-40,60),25,false)
 label("A–H: rota solicitada para revisão, ainda não implementada | F: sala a definir | sem mudança na grade",Vector2(20,viewport.size.y-125),Vector2(viewport.size.x-40,100),25,false)
 for r in rooms:
  if r["andar"]!=level: continue
  var actual=school.rooms[r["name"]]; var rr: Rect2=actual["rect"]
  var width=clampf(rr.size.x*scale-10,100,390) if r["sala"] else 285.0
  var pos=point(school.cel(rr.get_center().x-.5,rr.position.y+.15,level*school.LEVEL)) if r["sala"] else point(actual["rotulo"]-Vector3(0,0,.5))
  if r["name"]=="Sala dos professores": pos=point(actual["rotulo"])-Vector2(0,25)
  var name=("%02d · "%r["id"] if r["sala"] else "")+r["name"]
  label(name,pos-Vector2(width*.5,0),Vector2(width,105),17 if rr.size.x<5 and r["sala"] else 23)
 if level==0:
  var b=school.stairs_bottom; var c=NIVEL.ponto(school,"refeitorio"); var d=school.spawn; var e=school.rooms["Cozinha"]["center"]
  var g=NIVEL.ponto(school,"gravar"); var h=school.gate_at-Vector3.BACK
  for segment in [[b,c,Color(.02,.4,.85)],[c,d,Color(.9,.3,.02)],[d,e,Color(.65,.1,.65)],[g,h,Color(.0,.48,.25)]]:
   paths.append({"points":ground_path(segment[0],segment[1]),"color":segment[2]})
  for m in [["B",b],["C",c],["D",d],["E",e],["G",g],["H",h]]: markers.append({"text":m[0],"at":m[1]})
 else:
  var a=school.cel(15,10,school.LEVEL); var b=school.stairs_top
  paths.append({"points":upper_path(a,b),"color":Color(.02,.4,.85)})
  markers=[{"text":"A","at":a},{"text":"B","at":b}]
  label("A: início proposto em 3 Informática. Bolsa/celular atuais também estão nesta sala; F depende da decisão de Felipe.",Vector2(30,viewport.size.y-210),Vector2(viewport.size.x-60,100),24)
 show_route=false; route_overlay.queue_redraw(); await shot("terreo" if level==0 else "superior")
 show_route=true; route_overlay.queue_redraw(); await shot("terreo-rota" if level==0 else "superior-rota")
 if level==0:
  # Detalhes dos dois ambientes auditados; não acrescenta nenhum móvel.
  show_route=false; overlay.visible=false; route_overlay.visible=false; viewport.size=Vector2i(1400,1000); cam.projection=Camera3D.PROJECTION_ORTHOGONAL
  for data in [["cozinha",school.rooms["Cozinha"]["center"],16.0],["salinha",school.spawn,12.0]]:
   cam.size=data[2]; cam.global_position=data[1]+Vector3(3,15,8); cam.look_at(data[1]+Vector3.UP*.5)
   await shot(data[0])
 viewport.queue_free(); game.queue_free(); await process_frame
func run() -> void:
 AudioServer.set_bus_mute(0,true)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
 await render_floor(0); await render_floor(1)
 quit()

extends SceneTree
## Exporta a planta do capítulo 1 (grades ASCII + o que o jogo montou) em JSON
## para scripts/desenhar-planta.py. As colisões vêm do jogo montado, para
## conferir que a física bate com o texto.
## Uso: godot --headless --path godot-3d --script res://tools/exportar_planta.gd -- planta.json
const NIVEL=preload("res://capitulo1/nivel.gd")
func _initialize() -> void: call_deferred("run")
func xz(v: Vector3,s) -> Array:
 return [v.x-s.ORIGEM.x,v.z-s.ORIGEM.z,s.andar_de(v)]
func run() -> void:
 var out=OS.get_cmdline_user_args()[0]
 var g=load("res://capitulo1/main.tscn").instantiate(); root.add_child(g)
 for i in 3: await physics_frame
 var s=g.school
 var boxes=[]
 for body in s.find_children("*","StaticBody3D",true,false):
  for c in body.get_children():
   if c is CollisionShape3D and c.shape is BoxShape3D:
    var sz: Vector3=c.shape.size
    var w=body.global_basis.x.abs()*sz.x+body.global_basis.y.abs()*sz.y+body.global_basis.z.abs()*sz.z
    var at: Vector3=body.to_global(c.position)
    boxes.append({"x":at.x-s.ORIGEM.x,"y":at.y,"z":at.z-s.ORIGEM.z,"w":w.x,"h":w.y,"d":w.z,"door":body.has_meta("door"),"nome":String(body.name)})
 var grades=[]
 for a in s.andares: grades.append({"linhas":Array(a.linhas),"salas":a.salas,"areas":a.areas})
 var salas={}
 for t in s.rooms:
  var rr: Rect2=s.rooms[t]["rect"]
  salas[t]={"rotulo":xz(s.rooms[t]["rotulo"],s),"sala":s.rooms[t]["sala"],"rect":[rr.position.x,rr.position.y,rr.size.x,rr.size.y]}
 var marcas={"acorda":s.spawn,"escada (pé)":s.stairs_bottom,"escada (topo)":s.stairs_top,"bolsa":s.bag_at,"ritual":s.ritual_center,"checkpoint 2":s.ritual_approach,"portão 1":s.gate_at}
 var m={}
 for k in marcas: m[k]=xz(marcas[k],s)
 var postos=[]
 for p in s.postos: postos.append(xz(p,s))
 var hides=[]
 for h in s.hides: hides.append(xz(h["inside"],s)+[h["normal"].x,h["normal"].z])
 var portas=[]
 for d in s.doors: portas.append(xz(d.global_position,s)+[d.title,d.normal.x,d.normal.z])
 var lamps=[]
 for l in s.find_children("*","OmniLight3D",true,false):
  var lp: Vector3=l.global_position
  lamps.append([lp.x-s.ORIGEM.x,lp.z-s.ORIGEM.z,1 if lp.y>s.LEVEL+1 else 0])
 var pontos={}
 for k in NIVEL.PONTOS: pontos[k]=[NIVEL.PONTOS[k][0].x+.5,NIVEL.PONTOS[k][0].y+.5,NIVEL.PONTOS[k][1]]
 var rotas={"norte":[],"sul":[]}
 for v in NIVEL.ROUTE_NORTH: rotas["norte"].append([v.x+.5,v.y+.5])
 for v in NIVEL.ROUTE_SOUTH: rotas["sul"].append([v.x+.5,v.y+.5])
 var itens=[]
 for p in s.pickups: itens.append(xz(p["at"],s)+[p["kind"]])
 for t in g.tools: itens.append(xz(t["at"],s)+[t["name"]])
 var f=FileAccess.open(out,FileAccess.WRITE)
 f.store_string(JSON.stringify({"grades":grades,"boxes":boxes,"salas":salas,"marcas":m,"postos":postos,"esconderijos":hides,
  "portas":portas,"lampadas":lamps,"pontos":pontos,"rotas":rotas,"itens":itens,"visao":NIVEL.GUARD_SIGHT,"avisos":Array(s.avisos)}))
 f.close(); quit()

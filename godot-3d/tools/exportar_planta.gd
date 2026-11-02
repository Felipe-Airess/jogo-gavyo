extends SceneTree
## Exporta a planta do térreo (colisões em caixa + salas + pontos da história) em JSON.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var out=OS.get_cmdline_user_args()[0]
 var g=load("res://capitulo1/main.tscn").instantiate(); root.add_child(g)
 for i in 3: await physics_frame
 var s=g.school; var boxes=[]
 for body in s.find_children("*","StaticBody3D",true,false):
  for c in body.get_children():
   if c is CollisionShape3D and c.shape is BoxShape3D:
    var sz: Vector3=c.shape.size
    var w=body.global_basis.x.abs()*sz.x+body.global_basis.y.abs()*sz.y+body.global_basis.z.abs()*sz.z
    var at: Vector3=body.to_global(c.position)
    boxes.append({"x":at.x,"y":at.y,"z":at.z,"w":w.x,"h":w.y,"d":w.z,"door":body.has_meta("door")})
 var rooms={}
 for t in s.rooms: rooms[t]=[s.rooms[t]["center"].x,s.rooms[t]["floor"],s.rooms[t]["center"].z]
 var pts={"acorda":s.spawn,"escada":s.stairs_bottom,"bolsa":s.bag_at,"ritual":s.ritual_center,"checkpoint2":s.ritual_approach,"portao":s.gate_at}
 var marks={}
 for k in pts: marks[k]=[pts[k].x,pts[k].y,pts[k].z]
 var en=[]
 for e in g.enemies: en.append([e.position.x,e.position.z])
 var hides=[]
 for h in s.hides: hides.append([h["entry"].x,h["entry"].z])
 var lamps=[]
 for l in s.find_children("*","OmniLight3D",true,false): lamps.append([l.global_position.x,l.global_position.y,l.global_position.z])
 var f=FileAccess.open(out,FileAccess.WRITE)
 f.store_string(JSON.stringify({"boxes":boxes,"rooms":rooms,"marks":marks,"enemies":en,"hides":hides,"lamps":lamps}))
 f.close(); quit()

extends SceneTree
## Controles de toque: toques viram as mesmas teclas/cliques do teclado e mouse.
var passed:=0
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
 if ok: passed+=1; print("PASS ",text)
 else: failed+=1; push_error("FAIL "+text)
func touch(t,index: int,at: Vector2,pressed: bool) -> void:
 var ev:=InputEventScreenTouch.new(); ev.index=index; ev.position=at; ev.pressed=pressed
 t._touch(ev)
 Input.flush_buffered_events()
func drag(t,index: int,at: Vector2,relative: Vector2) -> void:
 var ev:=InputEventScreenDrag.new(); ev.index=index; ev.position=at; ev.relative=relative
 t._drag(ev)
 Input.flush_buffered_events()
func button(t,id: String) -> Dictionary:
 for b in t.buttons:
  if b["id"]==id: return b
 return {}
func run() -> void:
 var game=load("res://capitulo1/main.tscn").instantiate()
 root.add_child(game)
 for i in 3: await physics_frame
 var t=game.TOUCH.new(); game.add_child(t); t.setup(game); game.touch=t
 check(not Input.emulate_mouse_from_touch,"toque não vira clique de mouse sozinho")
 touch(t,0,Vector2(500,300),true)
 await process_frame
 check(game.started,"tocar na tela inicial começa")
 game.end_intro(); await physics_frame
 var size: Vector2=root.get_visible_rect().size
 var left:=Vector2(size.x*.15,size.y*.7)
 touch(t,0,left,true)
 drag(t,0,left+Vector2(0,-50),Vector2(0,-50))
 check(Input.is_physical_key_pressed(KEY_W) and not Input.is_physical_key_pressed(KEY_SHIFT),"analógico para frente anda")
 drag(t,0,left+Vector2(0,-200),Vector2(0,-150))
 check(Input.is_physical_key_pressed(KEY_SHIFT),"analógico na borda corre")
 var yaw: float=game.view.yaw
 touch(t,1,Vector2(size.x*.6,size.y*.3),true)
 drag(t,1,Vector2(size.x*.6+40,size.y*.3),Vector2(40,0))
 check(not is_equal_approx(yaw,game.view.yaw),"arrastar à direita gira a câmera, ao mesmo tempo que anda")
 touch(t,1,Vector2.ZERO,false)
 touch(t,0,Vector2.ZERO,false)
 check(not Input.is_physical_key_pressed(KEY_W) and not Input.is_physical_key_pressed(KEY_SHIFT),"soltar o dedo para de andar")
 var crouch=button(t,"agachar")
 touch(t,2,crouch["at"],true); touch(t,2,crouch["at"],false)
 check(Input.is_physical_key_pressed(KEY_CTRL),"agachar é alternância")
 touch(t,2,crouch["at"],true); touch(t,2,crouch["at"],false)
 check(not Input.is_physical_key_pressed(KEY_CTRL),"segundo toque levanta")
 touch(t,0,left,true); drag(t,0,left+Vector2(60,0),Vector2(60,0))
 t.release_all(); Input.flush_buffered_events()
 check(not Input.is_physical_key_pressed(KEY_D),"perder foco solta comandos presos")
 print("CAPITULO1_TOQUE: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)

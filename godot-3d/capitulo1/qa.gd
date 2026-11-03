extends Node
## Ponte opcional, somente viewport e comandos limitados do próprio jogo.
const DIR="res://../work/capitulo1-qa"
var game: Node3D
var timer:=0.0
var last_id:=""
var viewport: SubViewport
var camera: Camera3D
var hud: CanvasLayer
func setup(owner_game: Node3D) -> void:
 game=owner_game
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
 if DisplayServer.get_name()!="headless":
  viewport=SubViewport.new(); viewport.size=Vector2i(960,540)
  viewport.world_3d=game.get_world_3d()
  viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
  add_child(viewport)
  camera=Camera3D.new(); camera.near=.035; viewport.add_child(camera); camera.current=true
  hud=load("res://capitulo1/hud.gd").new(); viewport.add_child(hud); hud.setup(game)
func _process(dt: float) -> void:
 timer+=dt
 if timer<1.5: return
 timer=0
 var path=DIR.path_join("command.json")
 if FileAccess.file_exists(path):
  var command=JSON.parse_string(FileAccess.get_file_as_string(path))
  if command is Dictionary and str(command.get("id",""))!=last_id:
   last_id=str(command.get("id",""))
   match command.get("op",""):
    "begin": game.begin()
    "pause": game.paused=true
    "resume": game.paused=false
    "interact": game.interact()
    "attack": game.attack()
    "dodge": game.dodge()
    "checkpoint": game.restore_checkpoint()
    "record": game.toggle_recording()
    "look": game.view.look_mouse(Vector2(clampf(float(command.get("x",0)),-1200,1200),clampf(float(command.get("y",0)),-500,500)))
 var p: Vector3=game.player.position
 var data={"revision":3,"phase":game.phase,"paused":game.paused,"player":[p.x,p.y,p.z],"bag":game.bag_found,"alert_spread":game.alert_spread,"video":game.video_recorded,"checkpoint":game.checkpoint_index,"context":game.context_text(),"camera":game.view.mode,"pid":OS.get_process_id()}
 var file=FileAccess.open(DIR.path_join("state.json"),FileAccess.WRITE)
 if file: file.store_string(JSON.stringify(data,"  "))
 if viewport!=null and not FileAccess.file_exists(DIR.path_join("sem-captura")):
  camera.global_transform=game.view.camera.global_transform
  camera.fov=game.view.camera.fov
  hud.current_message=game.hud.current_message; hud.remaining=game.hud.remaining; hud.update(0)
  viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
  RenderingServer.force_draw(false)
  var frame=viewport.get_texture().get_image()
  if frame and not frame.is_empty(): frame.save_png(DIR.path_join("frame.png"))

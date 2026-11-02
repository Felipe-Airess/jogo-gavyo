extends SceneTree
var entries: Dictionary={}
func walk(path: String) -> void:
 var dir=DirAccess.open(path)
 for name in dir.get_files():
  if name.get_extension() not in ["ogg","wav"]: continue
  var file=path+"/"+name
  var stream: AudioStream=load(file)
  if stream==null: push_error(file); continue
  var playback=stream.instantiate_playback(); playback.start()
  var peak:=0.0; var total:=0.0; var count:=0
  for block in ceili((stream.get_length()+.1)*AudioServer.get_mix_rate()/2048.0):
   var frames=playback.mix_audio(1,2048)
   for frame in frames:
    peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
    total+=frame.length_squared(); count+=2
  playback.stop()
  var rms=sqrt(total/maxi(1,count))
  var gain=minf(-21-linear_to_db(maxf(.000001,rms)),-9-linear_to_db(maxf(.000001,peak)))
  entries[file.trim_prefix("res://capitulo1/assets/sons/")]={"seconds":stream.get_length(),"peak_db":linear_to_db(maxf(.000001,peak)),"rms_db":linear_to_db(maxf(.000001,rms)),"gain_db":clampf(gain,-40,24)}
 for name in dir.get_directories(): walk(path+"/"+name)
func _initialize() -> void:
 walk("res://capitulo1/assets/sons")
 var out=FileAccess.open("res://capitulo1/sons_niveis.gd",FileAccess.WRITE)
 out.store_string("extends RefCounted\n## RMS alvo -21 dBFS, pico individual no máximo -9 dBFS antes dos buses.\nconst LEVELS="+JSON.stringify(entries," ")+"\n"); out.close()
 print("SONS_MEDIDOS: ",entries.size());quit()

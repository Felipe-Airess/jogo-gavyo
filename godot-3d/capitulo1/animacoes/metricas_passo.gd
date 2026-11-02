extends RefCounted
## Avaliação FK das trilhas: mede os apoios sem reproduzir um AnimationPlayer.
const SAMPLES:=120
static var cache: Dictionary={}
static func measure(rig: Skeleton3D,library: AnimationLibrary) -> Dictionary:
 if not cache.is_empty(): return cache.duplicate(true)
 for name in ["Walk","Sprint","Crouch_Fwd","Walking_Backwards","Ascending_Stairs","Running_Up_Stairs","Descending_Stairs","Roll"]:
  var clip=library.get_animation(name)
  var frames: Array=[]
  for frame in SAMPLES+1: frames.append(feet(rig,clip,clip.length*frame/SAMPLES,name=="Roll"))
  var lowest:=INF
  for frame in frames:
   for point in frame: lowest=minf(lowest,point.y)
  var stride:=0.0
  var support_time:=0.0
  var curve: Array[float]=[0.0]
  for frame in range(1,SAMPLES+1):
   var current: Array=frames[frame]; var previous: Array=frames[frame-1]
   var support:=0
   for j in current.size():
    if current[j].y<current[support].y: support=j
   var displacement: float=(previous[support].z-current[support].z)*(-1 if name=="Walking_Backwards" else 1)
   if name=="Roll" or (current[support].y<=lowest+.06 and displacement>0):
    stride+=maxf(0,displacement)
    support_time+=clip.length/SAMPLES
   curve.append(stride)
  if name!="Roll": stride*=clip.length/maxf(.001,support_time)
  cache[name]={"stride":maxf(.1,stride),"duration":clip.length,"native_speed":stride/clip.length,"samples":SAMPLES}
  if name=="Roll": cache[name]["curve"]=curve
  print("PASSO_MEDIDO %s ciclo=%.3f s passo=%.3f m nativo=%.3f m/s"%[name,clip.length,stride,stride/clip.length])
 return cache.duplicate(true)
static func feet(rig: Skeleton3D,clip: Animation,time: float,roll:=false) -> Array:
 var locals: Array[Transform3D]=[]; var globals: Array[Transform3D]=[]
 for i in rig.get_bone_count(): locals.append(rig.get_bone_rest(i))
 for t in clip.get_track_count():
  var bone=rig.find_bone(String(clip.track_get_path(t)).get_slice(":",1))
  if bone<0: continue
  match clip.track_get_type(t):
   Animation.TYPE_ROTATION_3D: locals[bone].basis=Basis(clip.rotation_track_interpolate(t,time))
   Animation.TYPE_POSITION_3D: locals[bone].origin=clip.position_track_interpolate(t,time)*rig.motion_scale
 for i in locals.size():
  var parent=rig.get_bone_parent(i)
  globals.append(globals[parent]*locals[i] if parent>=0 else locals[i])
 var result: Array=[]
 for name in (["LeftFoot","RightFoot","LeftHand","RightHand","Spine","Chest","Head"] if roll else ["LeftFoot","RightFoot"]):
  result.append(globals[rig.find_bone(name)].origin)
 return result

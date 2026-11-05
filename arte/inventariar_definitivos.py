"""Inventário somente leitura dos modelos definitivos recebidos de Felipe."""
import bpy,sys,json,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];SOURCE=ROOT/'arte/modelos-definitivos';OUT=ROOT/'arte/revisoes/definitivos';OUT.mkdir(parents=True,exist_ok=True)
HEIGHTS={"alessandro":1.93,"bola":1.75,"cultista":2.0,"cultista perseguidor":2.5,"felipe":1.73,"miguel":1.76,"passa marcha":1.71,"sorriso":1.70}
rows=[]
for file in sorted(SOURCE.rglob('*.fbx')):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(file))
 bpy.context.view_layer.update()
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
 coords=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 lo=[min(p[i] for p in coords) for i in range(3)];hi=[max(p[i] for p in coords) for i in range(3)]
 images=[]
 for im in bpy.data.images:
  if im.type!='IMAGE':continue
  p=Path(bpy.path.abspath(im.filepath));images.append({'nome':im.name,'caminho':im.filepath,'encontrada':p.exists() or bool(im.packed_file),'resolucao':list(im.size)})
 row={'arquivo':str(file.relative_to(SOURCE)),'papel':file.parent.name,'formato':'FBX','sha256':hashlib.sha256(file.read_bytes()).hexdigest(),'altura_m':hi[2]-lo[2],'limites_min':lo,'limites_max':hi,'poligonos':sum(len(o.data.polygons) for o in meshes),'triangulos':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'malhas':[o.name for o in meshes],'esqueletos':[{'nome':o.name,'ossos':[b.name for b in o.data.bones]} for o in rigs],'animacoes':[{'nome':a.name,'intervalo':list(a.frame_range)} for a in bpy.data.actions],'texturas':images}
 row["altura_real_m"]=HEIGHTS[file.parent.name]
 row["padrao_ossos"]="Mixamo" if any(b.name.startswith("mixamorig:") for rig in rigs for b in rig.data.bones) else "outro: BoneRoot/Hip/Pelvis/L_Upperarm"
 rows.append(row);print('INVENTARIO',json.dumps(row,ensure_ascii=False),flush=True)
 (OUT/'inventario.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n')

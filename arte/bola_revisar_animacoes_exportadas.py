"""Reimportação vazia e movimento dos três clipes do GLB de inspeção."""
import bpy,json,math
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];out=ROOT/'arte/revisoes/bola/rig-exportado';out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'arte/revisoes/bola/rig-final/animacoes.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
for track in rig.animation_data.nla_tracks:track.mute=True
scene=bpy.context.scene;scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='STUDIO';scene.display.shading.color_type='VERTEX';scene.display.shading.show_specular_highlight=False
scene.view_settings.view_transform='Standard';scene.view_settings.exposure=1.38;scene.render.resolution_x=240;scene.render.resolution_y=320
cd=bpy.data.cameras.new('VerificacaoGLB');cd.type='ORTHO';cd.ortho_scale=2.25
cam=bpy.data.objects.new('VerificacaoGLB',cd);scene.collection.objects.link(cam);scene.camera=cam
report={'ossos':len(rig.data.bones),'acoes':[]}
for action in bpy.data.actions:
    if not any('pose.bones[' in fc.data_path for fc in action.fcurves):continue
    rig.animation_data.action=action;f0,f1=action.frame_range
    sheet=Image.new('RGB',(240*8,640));maximum=0
    for row,a in enumerate([0,-90]):
        angle=math.radians(a);cam.location=(5*math.sin(angle),-5*math.cos(angle),.9);cam.rotation_euler=(math.pi/2,0,angle)
        for i in range(8):
            scene.frame_set(round(f0+(f1-f0)*i/7));maximum=max(maximum,max(abs(s-1) for b in rig.pose.bones for s in b.scale))
            scene.render.filepath=str(ROOT/'work/bola-exportado-frame.png');bpy.ops.render.render(write_still=True)
            sheet.paste(Image.open(scene.render.filepath).convert('RGB'),(240*i,320*row))
    name=action.name.replace('/','_');sheet.save(out/(name+'.png'))
    report['acoes'].append({'nome':action.name,'intervalo':[f0,f1],'desvio_maximo_escala_ossos':maximum})
report['passou']=report['ossos']==22 and len(report['acoes'])==3 and all(a['desvio_maximo_escala_ossos']<.001 for a in report['acoes'])
(out/'relatorio.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
if not report['passou']:raise RuntimeError('O movimento exportado não manteve rig e escalas')

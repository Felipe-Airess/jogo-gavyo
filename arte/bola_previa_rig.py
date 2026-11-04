"""Prévia do rig com as animações existentes; não corrige poses do clipe."""
import bpy,sys,os,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'arte'))
import miguel_mixamo as mx
from PIL import Image,ImageDraw
files=[ROOT/'arte/mixamo/Start_Walking.fbx',ROOT/'arte/mixamo/Running.fbx',ROOT/'godot-3d/capitulo1/animacoes/mixamo/Crouch_To_Stand.fbx']
# Mesmo leitor do pipeline; apenas nomes do FBX bruto do Mixamo são adaptados.
# Os dois FBX em arte/mixamo já possuem esses nomes. Nenhuma pose é corrigida.
import inspect
mapping={"Spine1":"Chest","Spine2":"UpperChest"}
for lado in ["Left","Right"]:
    mapping.update({lado+"Arm":lado+"UpperArm",lado+"ForeArm":lado+"LowerArm",
                    lado+"UpLeg":lado+"UpperLeg",lado+"Leg":lado+"LowerLeg",lado+"ToeBase":lado+"Toes"})
def normalizar_nomes(arm):
    for bone in arm.data.bones:
        old=bone.name; raw=old.split(":")[-1]
        bone.name=mapping.get(raw,raw)
mx.normalizar_nomes=normalizar_nomes
source=inspect.getsource(mx.ler_fbx).replace('    # A leitura só precisa', '    normalizar_nomes(arm)\n    # A leitura só precisa')
exec(source,mx.__dict__)
read=[mx.ler_fbx(str(p)) for p in files]
bpy.ops.wm.read_factory_settings(use_empty=True)
import bola_humano
body,rig=bola_humano.construir_tudo();scene=bpy.context.scene;scene.render.fps=60
out=ROOT/'arte/revisoes/bola/rig-final';out.mkdir(parents=True,exist_ok=True)
scene.render.engine='BLENDER_WORKBENCH';scene.display.shading.light='STUDIO';scene.display.shading.color_type='VERTEX';scene.display.shading.show_specular_highlight=False
scene.view_settings.view_transform='Standard';scene.view_settings.exposure=1.38
scene.render.resolution_x=240;scene.render.resolution_y=320
import math
cd=bpy.data.cameras.new('RevisaoRig');cd.type='ORTHO';cd.ortho_scale=2.25
cam=bpy.data.objects.new('RevisaoRig',cd);scene.collection.objects.link(cam);scene.camera=cam
summary=[]
for nome,frames,fps in read:
    action,end=mx.transferir(rig,nome,frames,fps);rig.animation_data.action=action
    sheet=Image.new('RGB',(240*8,320*2),(205,205,200));gif=[]
    for row,angle in enumerate([0,-90]):
        a=math.radians(angle);cam.location=(5*math.sin(a),-5*math.cos(a),.9);cam.rotation_euler=(math.pi/2,0,a)
        for i in range(8):
            frame=round(end*i/7);scene.frame_set(frame);scene.render.filepath=str(out/f'{nome}-{row}-{i}.png');bpy.ops.render.render(write_still=True)
            im=Image.open(scene.render.filepath).convert('RGB');sheet.paste(im,(240*i,320*row))
        if row==1:
            for frame in range(0,end+1,3):
                scene.frame_set(frame);scene.render.filepath=str(ROOT/'work/bola-rig-frame.png');bpy.ops.render.render(write_still=True);gif.append(Image.open(scene.render.filepath).convert('RGB').copy())
    sheet.save(out/(nome+'.png'));gif[0].save(out/(nome+'.gif'),save_all=True,append_images=gif[1:],duration=50,loop=0)
    summary.append({'clipe':nome,'fonte':str(files[len(summary)].relative_to(ROOT)),'fim':end,'fps':60,'correcoes_de_pose':False})
rig.animation_data.action=None;scene.frame_set(0);bpy.ops.wm.save_as_mainfile(filepath=str(out/'rig.blend'));(out/'clipes.json').write_text(json.dumps(summary,indent=2))

"""Testa o uniforme em poses amostradas de soco, chute e levantar do Mixamo.

  bash scripts/blender-mac.sh -P arte/miguel_testar_uniforme.py
"""
import sys,math,json
from pathlib import Path
sys.path.insert(0,'arte')
import bpy
import miguel_mixamo as mx
from felipe_humano import _luz_eevee
from PIL import Image
orig=mx.ler_fbx
def amostrado(p):
 nome,q,fps=orig(p)
 return nome,q[::4],fps/4
mx.ler_fbx=amostrado
ob,rig,acoes=mx.carregar_tudo('arte/mixamo',['Punching_1','Kicking','Getting_Up'],humano='miguel_referencia.py')
sc=bpy.context.scene;_luz_eevee(sc);sc.view_settings.exposure=.55
sc.render.resolution_x,sc.render.resolution_y=300,400
cd=bpy.data.cameras.new('CamTesteRoupa');cd.type='ORTHO';cd.ortho_scale=2.65
cam=bpy.data.objects.new('CamTesteRoupa',cd);sc.collection.objects.link(cam);sc.camera=cam
angle=math.radians(35);cam.location=(5*math.sin(angle),-5*math.cos(angle),.90);cam.rotation_euler=(math.pi/2,0,angle)
out=Path(sys.argv[sys.argv.index('--saida')+1]) if '--saida' in sys.argv else Path('arte/revisoes/miguel-roupa-20261101/poses')
out.mkdir(parents=True,exist_ok=True)
result={}
for nome,(acao,fim) in acoes.items():
 rig.animation_data.action=acao;imagens=[];frames=[]
 for i in range(6):
  f=round(fim*i/5);frames.append(f);sc.frame_set(f)
  sc.render.filepath=str((out/f'{nome}_{i}.png').resolve());bpy.ops.render.render(write_still=True)
  image=Image.open(sc.render.filepath).convert('RGBA');bg=Image.new('RGBA',image.size,(225,228,230,255));imagens.append(Image.alpha_composite(bg,image).convert('RGB'))
 sheet=Image.new('RGB',(1800,400))
 for i,image in enumerate(imagens):sheet.paste(image,(i*300,0))
 sheet.save(out/f'{nome}.png');result[nome]={'quadros_conferidos':frames,'amostragem_fbx':'1 a cada 4 quadros, teste visual; arquivos originais intactos'}
(out/'teste-rig.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print('POSES_OK',list(acoes))

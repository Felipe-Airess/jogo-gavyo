"""Importa GLB/FBX do Bola em cena vazia e registra a estrutura real."""
import bpy,json,sys
from pathlib import Path
args=sys.argv[sys.argv.index('--')+1:];file=Path(args[0]).resolve();out=Path(args[1]).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
if file.suffix.lower()=='.glb':bpy.ops.import_scene.gltf(filepath=str(file))
else:bpy.ops.import_scene.fbx(filepath=str(file))
rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
report={'arquivo':str(file),'rigs':[{'nome':r.name,'ossos':len(r.data.bones),'hierarquia':{b.name:b.parent.name if b.parent else None for b in r.data.bones}} for r in rigs],'malhas':[]}
for ob in meshes:
    report['malhas'].append({'nome':ob.name,'vertices':len(ob.data.vertices),'triangulos':sum(len(f.vertices)-2 for f in ob.data.polygons),'cores':[a.name for a in ob.data.color_attributes], 'uvs':len(ob.data.uv_layers),'materiais':[m.name for m in ob.data.materials if m]})
deform=set(rigs[0].data.bones.keys()) if rigs else set()
weights=[];coordinates=[]
for ob in meshes:
    indices={g.index for g in ob.vertex_groups if g.name in deform}
    zero=over=0;error=0.
    for v in ob.data.vertices:
        w=[g.weight for g in v.groups if g.group in indices and g.weight>1e-5]
        zero+=not w;over+=len(w)>4;error=max(error,abs(sum(w)-1))
        coordinates.append(ob.matrix_world@v.co)
    weights.append({'nome':ob.name,'sem_peso':zero,'mais_de_quatro':over,'erro_soma_maximo':error})
report['pesos']=weights
report['altura_com_cabelo_m']=max(v.z for v in coordinates)-min(v.z for v in coordinates)
report['passou_pesos']=all(w['sem_peso']==0 and w['mais_de_quatro']==0 and w['erro_soma_maximo']<.001 for w in weights)
report['passou_estrutura']=len(rigs)==1 and len(rigs[0].data.bones)==22 and len(meshes)>=5 and all(m['uvs'] and m['cores'] and m['materiais'] for m in report['malhas'])
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
# Inspeção visual da importação usando o mesmo enquadramento, sem refazer a malha.
sys.path.insert(0,str(file.parent));import bola_humano
body=next(o for o in meshes if o.name.startswith('Bola'))
# A referência de altura do olho vem do .blend de autoria, não é ajustada à imagem.
source=file.parent/'revisoes/bola/olho-exportacao.json'
if source.exists():
    eye=json.loads(source.read_text());bola_humano.renderizar(str(out.parent/(file.suffix[1:]+'-renders')),body,eye['olho_z'])
if not (report['passou_estrutura'] and report['passou_pesos']):raise RuntimeError('Estrutura exportada não corresponde ao contrato')

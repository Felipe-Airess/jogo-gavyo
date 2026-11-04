"""Folhas obrigatórias da skill QA com compatibilidade Blender 3.6."""
import bpy,sys,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
helper=ROOT/'.claude/skills/blender-asset-qa/scripts/review_shots.py'
sys.path.insert(0,str(helper.parent))
# A única adaptação é a propriedade nova de formato de imagem, ausente em 3.6.
code=helper.read_text().replace('        r.image_settings.media_type = "IMAGE"\n','').replace('wire_t = _bounds(obs)[1] * 0.006','wire_t = _bounds(obs)[1] * 0.00005')
ns={'__file__':str(helper),'__name__':'qa_visual_local'};exec(compile(code,str(helper),'exec'),ns)
out=ROOT/'arte/revisoes/bola/qa';out.mkdir(parents=True,exist_ok=True)
meshes=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
for mode in ['random','wire']:
    ns['run'](objects=meshes,out=str(out/(mode+'.png')),views=['front','right','back','three_quarter'],mode=mode,res=320)
body=bpy.data.objects.get('Bola')
(ROOT/'arte/revisoes/bola/olho-exportacao.json').write_text(json.dumps({'olho_z':body['olho_z'],'olho_y':body['olho_y']}))

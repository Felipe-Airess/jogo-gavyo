"""QA obrigatório do Bola; não altera os critérios da skill."""
from pathlib import Path
import sys,json,bpy
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.claude/skills/blender-asset-qa/scripts'))
import qa_check
out=ROOT/'arte/revisoes/bola/qa';out.mkdir(parents=True,exist_ok=True)
objects=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
report=qa_check.run(objects=objects,profile='game')
(out/'relatorio.json').write_text(json.dumps(report,indent=2))
print(json.dumps({'pass':report['pass'],'errors':report['errors'],'warnings':report['warnings']},indent=2))

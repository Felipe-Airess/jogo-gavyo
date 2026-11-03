"""Executa blender-asset-qa e gera folhas de revisão do Miguel.

  bash scripts/blender-mac.sh work/miguel-depois.blend -P arte/miguel_revisar.py
  # Acrescente -- --exportar-previa para exportar um GLB de revisão após o QA.
"""
import json
import os
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'arte/revisoes/miguel-20261101'
SKILL = Path(os.environ.get('BLENDER_QA_SCRIPTS',
             str(Path.home()/'.agents/skills/blender-asset-qa/scripts')))


def main():
    global OUT
    if '--saida' in sys.argv:
        OUT=Path(sys.argv[sys.argv.index('--saida')+1]).resolve()
    sys.path.insert(0,str(SKILL))
    import qa_check
    OUT.mkdir(parents=True,exist_ok=True)
    result = qa_check.run(objects=['Miguel'],profile='game')
    (OUT/'qa-depois.json').write_text(json.dumps(result,indent=2)+'\n')
    print('QA_PASS',result['pass'],'ERRORS',result['errors'])
    # Única adaptação de API: image_settings.media_type não existe no 3.6.
    source=(SKILL/'review_shots.py').read_text()
    if bpy.app.version < (4,0,0):
        source=source.replace('r.image_settings.media_type = "IMAGE"',
                              'r.image_settings.file_format = "PNG"')
    ns={'__file__':str(SKILL/'review_shots.py'),'__name__':'review_shots_compat'}
    exec(compile(source,str(SKILL/'review_shots.py'),'exec'),ns)
    for mode in ['random','wire']:
        ns['run'](objects=['Miguel'],out=str(OUT/f'qa-{mode}.png'),
                  views=['front','right','back','three_quarter'],mode=mode,res=400)
    if '--exportar-previa' in sys.argv:
        if not result['pass']:
            raise RuntimeError('QA falhou; GLB de revisão não será exportado.')
        bpy.ops.object.select_all(action='DESELECT')
        for ob in bpy.data.objects:
            if ob.type in ('MESH','ARMATURE'):
                ob.select_set(True)
        bpy.ops.export_scene.gltf(filepath=str(OUT/'miguel-previa.glb'),
                                  export_format='GLB',use_selection=True,
                                  export_apply=True,export_yup=True)


if __name__ == '__main__':
    main()

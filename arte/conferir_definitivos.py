"""QA e vistas dos FBX definitivos. Não corrige malha, material, rig ou pesos."""
import bpy,sys,json,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'.claude/skills/blender-asset-qa/scripts'))
import qa_check
rows=json.loads((ROOT/'arte/revisoes/definitivos/inventario.json').read_text())
for row in rows:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(ROOT/'arte/modelos-definitivos'/row['arquivo']))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];out=ROOT/'arte/revisoes/definitivos'/row['papel'].replace(' ','_');out.mkdir(parents=True,exist_ok=True)
 report=json.loads((out/'qa.json').read_text()) if '--somente-vistas' in sys.argv else qa_check.run(objects=[o.name for o in meshes],profile='game')
 if '--somente-vistas' not in sys.argv: (out/'qa.json').write_text(json.dumps(report,indent=2))
 scene=bpy.context.scene;scene.render.engine='BLENDER_WORKBENCH';sh=scene.display.shading;sh.light='STUDIO';sh.color_type='TEXTURE';sh.show_specular_highlight=False;sh.background_type='VIEWPORT';sh.background_color=(.22,.22,.22)
 scene.view_settings.view_transform='Standard';scene.view_settings.exposure=.8;scene.render.resolution_x=600;scene.render.resolution_y=700;scene.render.film_transparent=False
 cd=bpy.data.cameras.new('Conferencia');cd.type='ORTHO';cd.ortho_scale=max(row['altura_m'],(row['limites_max'][0]-row['limites_min'][0])*700/600)*1.18
 cam=bpy.data.objects.new('Conferencia',cd);scene.collection.objects.link(cam);scene.camera=cam
 center=Vector([(a+b)/2 for a,b in zip(row['limites_min'],row['limites_max'])])
 for name,ang in [('frente',0),('lado',90),('costas',180)]:
  a=math.radians(ang);cam.location=center+Vector((3*math.sin(a),-3*math.cos(a),0));cam.rotation_euler=(math.pi/2,0,a);scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
 # Sobreposição de conferência em cópias temporárias; nenhum FBX é salvo.
 sh.color_type='OBJECT'
 for original in meshes:
  original.color=(.75,.75,.75,1)
  wire=original.copy();wire.data=original.data;scene.collection.objects.link(wire)
  wire.color=(.01,.01,.01,1);modifier=wire.modifiers.new('ConferenciaWire','WIREFRAME');modifier.thickness=.00035
 cam.location=center+Vector((2,-3,1));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(out/'wire.png');bpy.ops.render.render(write_still=True)
 print('QA_DEFINITIVO',row['papel'],report['pass'],report['errors'],flush=True)

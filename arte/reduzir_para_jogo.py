# Versão leve para o jogo: Decimate (collapse) antes da armadura; UV e pesos interpolados.
import bpy,sys
src,dst,alvo=sys.argv[sys.argv.index("--")+1:][:3]; alvo=int(alvo)
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.fbx(filepath=src)
for m in [o for o in bpy.data.objects if o.type=="MESH"]:
 n=sum(len(p.vertices)-2 for p in m.data.polygons)
 d=m.modifiers.new("Reduzir","DECIMATE"); d.ratio=min(1.0,alvo/n); d.use_collapse_triangulate=True
 bpy.context.view_layer.objects.active=m
 while m.modifiers[0].name!="Reduzir": bpy.ops.object.modifier_move_up(modifier="Reduzir")
 bpy.ops.object.modifier_apply(modifier="Reduzir")
 print("TRIS",m.name,n,"->",sum(len(p.vertices)-2 for p in m.data.polygons))
for a in bpy.data.objects:
 if a.type=="ARMATURE": a.name="Armature"
bpy.ops.export_scene.fbx(filepath=dst,add_leaf_bones=False,bake_anim=False,path_mode='COPY',embed_textures=True,armature_nodetype='NULL',apply_scale_options='FBX_SCALE_NONE')

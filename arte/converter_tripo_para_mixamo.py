# Converte rig Tripo de 78 ossos para nomes/hierarquia Mixamo (65). Malha, UV,
# textura e pose de repouso intactas; pesos de ossos auxiliares somados no pai.
import bpy,sys,os
src,dst=sys.argv[sys.argv.index("--")+1:][:2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=src)
arm=[o for o in bpy.data.objects if o.type=="ARMATURE"][0]
meshes=[o for o in bpy.data.objects if o.type=="MESH"]
M="mixamorig:"
ren={"Hip":"Hips","Waist":"Spine","Spine01":"Spine1","Spine02":"Spine2","NeckTwist01":"Neck","Head":"Head"}
merge={"BoneRoot":"Hip","Pelvis":"Hip","NeckTwist02":"NeckTwist01","FacialBone":"Head","L_Eye":"Head","R_Eye":"Head"}
for s,S in (("L","Left"),("R","Right")):
 ren.update({f"{s}_Clavicle":f"{S}Shoulder",f"{s}_Upperarm":f"{S}Arm",f"{s}_Forearm":f"{S}ForeArm",f"{s}_Hand":f"{S}Hand",
  f"{s}_Thigh":f"{S}UpLeg",f"{s}_Calf":f"{S}Leg",f"{s}_Foot":f"{S}Foot",f"{s}_ToeBase":f"{S}ToeBase"})
 for a,b in (("Thumb","Thumb"),("Index","Index"),("Mid","Middle"),("Ring","Ring"),("Pinky","Pinky")):
  for i in (1,2,3): ren[f"{s}_{a}{i}"]=f"{S}Hand{b}{i}"
 merge.update({f"{s}_UpperarmTwist01":f"{s}_Upperarm",f"{s}_UpperarmTwist02":f"{s}_Upperarm",
  f"{s}_ForearmTwist01":f"{s}_Forearm",f"{s}_ForearmTwist02":f"{s}_Forearm",f"{s}_ElbowShareBone":f"{s}_Forearm",
  f"{s}_ThighTwist01":f"{s}_Thigh",f"{s}_ThighTwist02":f"{s}_Thigh",f"{s}_CalfTwist01":f"{s}_Calf",
  f"{s}_CalfTwist02":f"{s}_Calf",f"{s}_KneeShareBone":f"{s}_Calf"})
names={b.name for b in arm.data.bones}
assert set(ren)|set(merge)==names, sorted(names-(set(ren)|set(merge)))
def final(n):
 while n in merge: n=merge[n]
 return n
# pesos: soma do auxiliar no osso final
for m in meshes:
 for v in m.data.vertices:
  acc={}
  for g in list(v.groups):
   n=m.vertex_groups[g.group].name
   if n in merge: acc[final(n)]=acc.get(final(n),0)+g.weight
  for n,w in acc.items():
   vg=m.vertex_groups.get(n) or m.vertex_groups.new(name=n)
   old=next((g.weight for g in v.groups if g.group==vg.index),0.0)
   vg.add([v.index],min(1.0,old+w),'REPLACE')
 for n in merge:
  if n in m.vertex_groups: m.vertex_groups.remove(m.vertex_groups[n])
bpy.context.view_layer.objects.active=arm
bpy.ops.object.mode_set(mode='EDIT')
eb=arm.data.edit_bones
for s in "LR": eb[f"{s}_Thigh"].parent=eb["Hip"]
for n in merge:
 b=eb[n]
 for c in list(b.children): c.parent=b.parent
 eb.remove(b)
bpy.ops.object.mode_set(mode='OBJECT')
for old,new in ren.items():
 arm.data.bones[old].name=M+new  # renomeia grupos de vértices junto
arm.name="Armature"
os.makedirs(os.path.dirname(dst),exist_ok=True)
bpy.ops.export_scene.fbx(filepath=dst,use_selection=False,add_leaf_bones=False,bake_anim=False,
 path_mode='COPY',embed_textures=True,armature_nodetype='NULL',apply_scale_options='FBX_SCALE_NONE')
print("CONVERTIDO",dst,len(arm.data.bones))

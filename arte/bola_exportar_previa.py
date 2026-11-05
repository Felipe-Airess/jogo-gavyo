"""GLB de inspeção com os três clipes; separado do modelo para o jogo."""
import bpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];rig=bpy.data.objects['BolaRig']
rig.animation_data.action=None
for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
for action in bpy.data.actions:
    if action.name in ['Start_Walking','Running','Crouch_To_Stand']:
        track=rig.animation_data.nla_tracks.new();track.name=action.name;track.strips.new(action.name,0,action)
bpy.ops.object.select_all(action='DESELECT')
for ob in bpy.context.scene.objects:
    if ob.type in ['MESH','ARMATURE']:ob.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'arte/revisoes/bola/rig-final/animacoes.glb'),export_format='GLB',use_selection=True,export_apply=True,export_nla_strips=True)

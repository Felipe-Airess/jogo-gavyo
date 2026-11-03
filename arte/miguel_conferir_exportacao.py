"""Confere GLB, imagem embutida, rig e preservação da cabeça entre versões.

bash scripts/blender-mac.sh -P arte/miguel_conferir_exportacao.py -- \
  --pasta arte/revisoes/miguel-silhueta-20261101 \
  --modelo work/miguel-silhueta.blend --anterior work/miguel-uniforme.blend
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

import bpy
import numpy as np


def cabeca():
    a=np.round(np.array([v.co[:] for v in bpy.data.objects['Miguel'].data.vertices if v.co.z>1.54]),7)
    return a[np.lexsort((a[:,2],a[:,1],a[:,0]))]


def main():
    p=argparse.ArgumentParser();p.add_argument('--pasta',required=True)
    p.add_argument('--modelo',required=True);p.add_argument('--anterior',required=True)
    args=p.parse_args(sys.argv[sys.argv.index('--')+1:])
    pasta=Path(args.pasta).resolve()
    bpy.ops.wm.open_mainfile(filepath=str(Path(args.anterior).resolve()));antes=cabeca()
    bpy.ops.wm.open_mainfile(filepath=str(Path(args.modelo).resolve()));depois=cabeca()
    assert antes.shape==depois.shape and np.array_equal(antes,depois), 'Cabeça mudou'
    (pasta/'cabeca-preservada.json').write_text(json.dumps({
        'mesmos_vertices_e_posicoes':True,'vertices_acima_de_1p54m':len(antes),
        'sha256_alvo_rosto':hashlib.sha256((Path(__file__).parent/'miguel_rosto.target.gz').read_bytes()).hexdigest()},indent=2)+'\n')
    file=pasta/'miguel-previa.glb';data=file.read_bytes()
    magic,version,length=struct.unpack_from('<III',data)
    assert magic==0x46546c67 and version==2 and length==len(data)
    n,kind=struct.unpack_from('<II',data,12);assert kind==0x4e4f534a
    gltf=json.loads(data[20:20+n]);assert len(gltf['skins'][0]['joints'])==22
    assert len(gltf['materials'])==2 and len(gltf['images'])==1
    assert 'bufferView' in gltf['images'][0], 'Textura externa ao GLB'
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(file))
    ms=[o for o in bpy.data.objects if o.type=='MESH'];rs=[o for o in bpy.data.objects if o.type=='ARMATURE']
    assert len(ms)==len(rs)==1 and len(rs[0].data.bones)==22
    ob=ms[0]
    assert all(math.isfinite(c) for v in ob.data.vertices for c in v.co)
    assert all(abs(sum(g.weight for g in v.groups)-1)<.001 for v in ob.data.vertices)
    assert max(len([g for g in v.groups if g.weight>1e-4]) for v in ob.data.vertices)<=4
    result={'arquivo':file.name,'bytes':length,'joints':22,'materiais':2,
            'imagens_embutidas':1,'reimportado':True,'vertices_importados':len(ob.data.vertices),
            'triangulos':len(ob.data.polygons),'pesos_normalizados':True,'max_influencias':4,
            'atributos_cor':[a.name for a in ob.data.color_attributes]}
    (pasta/'exportacao.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
    print(result)


if __name__=='__main__':main()

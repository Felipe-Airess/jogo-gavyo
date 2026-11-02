"""QA de um GLB do Miguel: qa_check (blender-asset-qa) + orçamento por parte.

  python arte/miguel_v2_qa.py -- --glb ARQ.glb --json SAIDA.json

Importa o GLB num Blender limpo e roda a skill .claude/skills/blender-asset-qa
(perfil game) só na malha com armadura. Também conta triângulos por ilha
(cabelo, corpo, peças da roupa), influências por vértice, ossos, texturas
e objetos extras exportados por engano.
"""
import json
import os
import sys
from collections import Counter

import bpy  # noqa: I001  (em bpy 5.x, bpy antes de bmesh)
import bmesh

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, ".claude/skills/blender-asset-qa/scripts"))
ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def ilhas(me):
    bm = bmesh.new()
    bm.from_mesh(me)
    visto, saida = set(), []
    for f0 in bm.faces:
        if f0.index in visto:
            continue
        pilha, tris, zs, xs = [f0], 0, [], []
        visto.add(f0.index)
        while pilha:
            f = pilha.pop()
            tris += len(f.verts) - 2
            c = f.calc_center_median()
            zs.append(c.z)
            xs.append(c.x)
            for e in f.edges:
                for g in e.link_faces:
                    if g.index not in visto:
                        visto.add(g.index)
                        pilha.append(g)
        saida.append({"tris": tris, "z_min": round(min(zs), 3), "z_max": round(max(zs), 3),
                      "x_med": round(sum(xs) / len(xs), 3)})
    bm.free()
    return sorted(saida, key=lambda i: -i["tris"])


def locais_zfight(ob, eps=0.001):
    """Mesmo critério de qa_check (faces paralelas a < eps, áreas sobrepostas),
    devolvendo onde ficam: a skill só conta os pares."""
    from mathutils.bvhtree import BVHTree
    me = ob.data
    me.calc_loop_triangles()
    vs = [v.co.copy() for v in me.vertices]
    tris = [tuple(t.vertices) for t in me.loop_triangles]
    bvh = BVHTree.FromPolygons(vs, tris, epsilon=0.0)
    normais = [t.normal.copy() for t in me.loop_triangles]
    saida = []
    for ti, t in enumerate(tris):
        a, b, c = (vs[i] for i in t)
        cen = (a + b + c) / 3
        for _, _, tj, _ in bvh.find_nearest_range(cen, eps):
            if tj is None or tj <= ti or set(t) & set(tris[tj]):
                continue
            n2 = normais[tj]
            if normais[ti].dot(n2) > 0.999:
                import qa_check
                a2, b2, c2 = (vs[i] for i in tris[tj])
                q = cen - n2 * n2.dot(cen - a2)
                if qa_check._point_in_tri(q, a2, b2, c2, n2):
                    saida.append([round(x, 3) for x in cen])
    return saida


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(ARGS[ARGS.index("--glb") + 1]))
    extras = [o.name for o in bpy.data.objects if o.type == "MESH"
              and not any(m.type == "ARMATURE" for m in o.modifiers)]
    malha = next(o for o in bpy.data.objects if o.type == "MESH"
                 and any(m.type == "ARMATURE" for m in o.modifiers))
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    import qa_check
    qa = qa_check.run(objects=[malha.name], profile="game")
    me = malha.data
    infl = Counter(len([g for g in v.groups if g.weight > 1e-4]) for v in me.vertices)
    sem_peso = sum(1 for v in me.vertices if not any(g.weight > 1e-4 for g in v.groups))
    por_mat = Counter()
    for p in me.polygons:
        por_mat[me.materials[p.material_index].name if me.materials else "-"] += len(p.vertices) - 2
    rel = {
        "glb": ARGS[ARGS.index("--glb") + 1],
        "tamanho_bytes": os.path.getsize(ARGS[ARGS.index("--glb") + 1]),
        "objetos_extras": extras,
        "tris": sum(len(p.vertices) - 2 for p in me.polygons),
        "verts_blender": len(me.vertices),
        "tris_por_material": dict(por_mat),
        "texturas": {i.name: list(i.size) for i in bpy.data.images},
        "ossos": [b.name for b in rig.data.bones],
        "acoes": len(bpy.data.actions),
        "altura_m": round(malha.dimensions.z, 4),
        "influencias_por_vertice": dict(sorted(infl.items())),
        "vertices_sem_peso": sem_peso,
        "ilhas_maiores": ilhas(me)[:14],
        "qa_pass": qa["pass"],
        "qa_errors": qa["errors"],
        "qa_warnings": qa["warnings"],
        "zfight_locais": locais_zfight(malha),
    }
    saida = ARGS[ARGS.index("--json") + 1]
    with open(saida, "w") as f:
        json.dump(rel, f, ensure_ascii=False, indent=1, default=str)
    print("QA_RESUMO", json.dumps({k: rel[k] for k in ("tris", "tris_por_material", "texturas",
                                                     "objetos_extras", "qa_pass", "altura_m",
                                                     "vertices_sem_peso")}, default=str))
    print("QA_ERROS", json.dumps(qa["errors"], default=str)[:1500])
    print("QA_AVISOS", json.dumps(qa["warnings"], default=str)[:1500])
    print("ILHAS", json.dumps(rel["ilhas_maiores"]))


if __name__ == "__main__":
    main()

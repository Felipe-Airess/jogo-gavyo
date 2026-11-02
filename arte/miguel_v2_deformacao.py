"""Teste de deformação em poses extremas (antes/depois).

  python arte/miguel_v2_deformacao.py -- --glb ARQ.glb --saida DIR [--quadros JSON]

Para cada ação da lista, acha o quadro mais extremo (maior desvio de
direção dos ossos em relação ao primeiro quadro) ou usa o quadro dado em
--quadros (para comparar o mesmo quadro nos dois modelos). Renderiza frente,
lado e 3/4 e mede, na malha deformada, a razão comprimento posado /
comprimento em repouso de cada aresta: < 0,5 indica colapso (junta
amassada), > 1,8 indica esticamento (pele rasgando). Grava DIR/deformacao.json.
"""
import json
import math
import os
import sys

import bpy
import numpy as np

ARGS = sys.argv[sys.argv.index("--") + 1:]
ACOES = ["Kicking", "Armada", "Knee_Jab", "Getting_Up", "Sweep_Fall", "Running",
         "Brutal_Assassination", "Hook_Punch", "Look_Over_Shoulder", "Blocking"]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from miguel_v2_vistas import estudio  # noqa: E402


def arg(n, p=None):
    return ARGS[ARGS.index(n) + 1] if n in ARGS else p


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(arg("--glb")))
    saida = os.path.abspath(arg("--saida"))
    os.makedirs(saida, exist_ok=True)
    for o in bpy.data.objects:
        if o.type == "MESH" and not any(m.type == "ARMATURE" for m in o.modifiers):
            o.hide_render = True
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    malha = next(o for o in bpy.data.objects if o.type == "MESH" and not o.hide_render)
    fixos = json.load(open(arg("--quadros"))) if arg("--quadros") else {}
    sc = bpy.context.scene
    estudio(sc)
    cd = bpy.data.cameras.new("Cam")
    cd.type = "ORTHO"
    cd.ortho_scale = 2.3
    cam = bpy.data.objects.new("Cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 520, 600
    me = malha.data
    arestas = np.array([e.vertices[:] for e in me.edges])
    rel = {}

    def coords():
        dg = bpy.context.evaluated_depsgraph_get()
        ev = malha.evaluated_get(dg)
        m = ev.to_mesh()
        co = np.empty(len(m.vertices) * 3)
        m.vertices.foreach_get("co", co)
        ev.to_mesh_clear()
        return co.reshape(-1, 3)

    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    bpy.context.view_layer.update()
    co0 = coords()
    l0 = np.linalg.norm(co0[arestas[:, 0]] - co0[arestas[:, 1]], axis=1)
    ok = l0 > 0.002  # arestas de fração de mm distorcem a razão
    for nome in ACOES:
        acao = bpy.data.actions.get(nome)
        if acao is None:
            continue
        rig.animation_data.action = acao
        if acao.slots:
            rig.animation_data.action_slot = acao.slots[0]
        f0, f1 = (int(round(x)) for x in acao.frame_range)
        if nome in fixos:
            melhor = fixos[nome]
        else:
            sc.frame_set(f0)
            ref = {b.name: (b.tail - b.head).normalized() for b in rig.pose.bones}
            melhor, desvio = f0, -1
            for f in range(f0, f1 + 1, 2):
                sc.frame_set(f)
                d = sum(math.acos(max(-1, min(1, (b.tail - b.head).normalized().dot(ref[b.name]))))
                        for b in rig.pose.bones)
                if d > desvio:
                    melhor, desvio = f, d
        sc.frame_set(melhor)
        bpy.context.view_layer.update()
        co = coords()
        l1 = np.linalg.norm(co[arestas[:, 0]] - co[arestas[:, 1]], axis=1)
        r = l1[ok] / l0[ok]
        hip = rig.matrix_world @ rig.pose.bones["Hips"].head
        rel[nome] = {"quadro": melhor, "razao_min": round(float(r.min()), 3),
                     "razao_max": round(float(r.max()), 3),
                     "p01": round(float(np.percentile(r, 1)), 3),
                     "p99": round(float(np.percentile(r, 99)), 3),
                     "arestas_colapso_<0.5": int((r < 0.5).sum()),
                     "arestas_esticadas_>1.8": int((r > 1.8).sum()),
                     "fracao_fora_0.5_1.8_pct": round(100 * float(((r < 0.5) | (r > 1.8)).mean()), 3),
                     "arestas_medidas": int(ok.sum()),
                     "piores_em_repouso": [
                         [round(float(x), 3) for x in (co0[arestas[ok][k, 0]] + co0[arestas[ok][k, 1]]) / 2]
                         + [round(float(r[k]), 1)] for k in np.argsort(-r)[:8]]}
        for suf, ang in (("frente", 0), ("lado", 90), ("34", 35)):
            a = math.radians(ang)
            cam.location = (hip.x + 5 * math.sin(a), hip.y - 5 * math.cos(a), max(.65, hip.z))
            cam.rotation_euler = (math.pi / 2, 0, a)
            sc.render.filepath = os.path.join(saida, "%s_%s.png" % (nome, suf))
            bpy.ops.render.render(write_still=True)
        print("POSE", nome, json.dumps(rel[nome]), flush=True)
    with open(os.path.join(saida, "deformacao.json"), "w") as f:
        json.dump(rel, f, indent=1)
    with open(os.path.join(saida, "quadros.json"), "w") as f:
        json.dump({k: v["quadro"] for k, v in rel.items()}, f)


if __name__ == "__main__":
    main()

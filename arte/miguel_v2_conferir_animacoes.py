"""Compara as 43 ações do GLB aprovado com as do v2, osso a osso.

  python arte/miguel_v2_conferir_animacoes.py -- APROVADO.glb V2.glb SAIDA.json

Para cada ação: mesmo número de quadros e, em 9 quadros, a direção de cada
osso no espaço da armadura (ângulo entre os dois rigs) e a altura do quadril.
Os rigs não são idênticos (o pescoço do v2 é mais curto), então a métrica é
de direção, que é o que o retarget transfere.
"""
import json
import math
import sys

import bpy

ARGS = sys.argv[sys.argv.index("--") + 1:]


def carregar(caminho):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=caminho)
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    dados = {}
    sc = bpy.context.scene
    for acao in bpy.data.actions:
        rig.animation_data.action = acao
        if acao.slots:
            rig.animation_data.action_slot = acao.slots[0]
        f0, f1 = (int(round(x)) for x in acao.frame_range)
        quadros = []
        for i in range(9):
            sc.frame_set(round(f0 + (f1 - f0) * i / 8))
            bpy.context.view_layer.update()
            quadros.append({b.name: ((b.tail - b.head).normalized()[:], b.head.z)
                            for b in rig.pose.bones})
        dados[acao.name] = {"quadros": f1 - f0, "amostras": quadros}
    return dados


def main():
    a, b = carregar(ARGS[0]), carregar(ARGS[1])
    rel, pior = {}, 0.0
    for nome in sorted(set(a) | set(b)):
        if nome not in a or nome not in b:
            rel[nome] = {"falta_em": "aprovado" if nome not in a else "v2"}
            continue
        ang_max, quadril = 0.0, 0.0
        for qa, qb in zip(a[nome]["amostras"], b[nome]["amostras"]):
            for osso, (da, za) in qa.items():
                db = qb[osso][0]
                dot = max(-1.0, min(1.0, sum(x * y for x, y in zip(da, db))))
                ang_max = max(ang_max, math.degrees(math.acos(dot)))
            quadril = max(quadril, abs(qa["Hips"][1] - qb["Hips"][1]))
        pior = max(pior, ang_max)
        rel[nome] = {"quadros_aprovado": a[nome]["quadros"], "quadros_v2": b[nome]["quadros"],
                     "angulo_max_graus": round(ang_max, 2), "quadril_dif_m": round(quadril, 4)}
    with open(ARGS[2], "w") as f:
        json.dump({"pior_angulo_graus": round(pior, 2), "acoes": rel}, f, indent=1, ensure_ascii=False)
    difs = [n for n, r in rel.items() if "falta_em" in r or r["quadros_aprovado"] != r["quadros_v2"]]
    print("ANIM_CONFERIDAS", len(rel), "pior_angulo", round(pior, 2), "diferencas_de_duracao", difs)
    for n, r in sorted(rel.items(), key=lambda kv: -kv[1].get("angulo_max_graus", 0))[:6]:
        print(" ", n, r)


if __name__ == "__main__":
    main()

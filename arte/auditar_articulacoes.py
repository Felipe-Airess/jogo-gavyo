"""Audita o rig animado do Miguel em cada quadro de todos os clipes.

Uso: blender -b -t 2 -P arte/auditar_articulacoes.py
"""
import math
import os
import runpy

import bpy

animacoes = runpy.run_path(
    os.path.join(os.path.dirname(__file__), "miguel_animacoes.py"),
    run_name="auditoria",
)
rig, _, acoes = animacoes["preparar"]()
erros = []
quadros = 0
for nome, (acao, fim, _) in acoes.items():
    rig.animation_data.action = acao
    for quadro in range(fim + 1):
        bpy.context.scene.frame_set(quadro)
        quadros += 1
        ossos = rig.pose.bones
        for lado in ("Left", "Right"):
            for superior, inferior, ponta, junta in (
                ("UpperLeg", "LowerLeg", "Foot", "joelho"),
                ("UpperArm", "LowerArm", "Hand", "cotovelo"),
            ):
                a = ossos[lado + superior].head - ossos[lado + inferior].head
                b = ossos[lado + ponta].head - ossos[lado + inferior].head
                if a.length < 0.001 or b.length < 0.001:
                    erros.append((nome, quadro, lado, junta, "osso degenerado"))
                    continue
                flexao = 180 - math.degrees(a.angle(b))
                if flexao > 150.1:
                    erros.append((nome, quadro, lado, junta, round(flexao, 1)))

print(f"AUDITORIA: {len(acoes)} clipes, {quadros} quadros, {len(erros)} violações")
for erro in erros[:30]:
    print("ARTICULACAO:", *erro)
if erros:
    raise SystemExit(1)

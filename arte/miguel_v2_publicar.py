"""Pacote animado do Miguel v2 (cópia; não substitui o aprovado).

  python arte/miguel_v2_publicar.py -- [--blend ARQ]

Mesmo processo de miguel_publicar_animacoes.py (25 FBX de arte/mixamo
transferidos por direção de osso + 18 recortes de treino, uma faixa NLA por
ação), com o personagem de arte/miguel_v2.py. Grava apenas:
  arte/miguel_v2_animado.glb e arte/miguel_v2_animacoes.json
Não toca em arte/miguel_animado.glb, godot-3d/miguel_animado.glb nem nos
manifestos aprovados. A troca no jogo só acontece depois do aval do Felipe.
"""
import json
import math
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "arte"))
import miguel_mixamo as mx  # noqa: E402
from miguel_publicar_animacoes import TREINO  # noqa: E402
from mathutils import Quaternion  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
GLB = ROOT / "arte/miguel_v2_animado.glb"
MANIFESTO = ROOT / "arte/miguel_v2_animacoes.json"


def main():
    ob, rig, originais = mx.carregar_tudo(str(ROOT / "arte/mixamo"), humano="miguel_v2.py")
    acoes = dict(originais)
    manifesto = {}
    for nome, (acao, fim) in originais.items():
        manifesto[nome] = dict(fonte=f"{nome}.fbx", intervalo=[0, 1], loop=False,
                               duracaoMs=round(fim / 60 * 1000), contatoMs=None,
                               contatosMs=None, avancoM=0, quadros=fim + 1, fps=60,
                               tipo="Mixamo completo")
    for nome, (fonte, inicio, fim, loop, contato) in TREINO.items():
        acoes[nome] = recortar(originais[fonte], nome, inicio, fim, loop)
        total = round(acoes[nome][1] / 60 * 1000)
        manifesto[nome] = dict(fonte=f"{fonte}.fbx", intervalo=[inicio, fim], loop=loop,
                               duracaoMs=total, contatoMs=round(total * contato) if contato else None,
                               contatosMs=None, avancoM=0, quadros=acoes[nome][1] + 1, fps=60,
                               tipo="Recorte de treino", contatoRevisado=False if contato else None)
    # Mesma auditoria do pacote aprovado: valores finitos, quadril sem
    # translação horizontal.
    mods = [(m, m.show_viewport) for m in ob.modifiers]
    for m, _ in mods:
        m.show_viewport = False
    for nome, (acao, fim) in acoes.items():
        assert fim > 0
        assert all(math.isfinite(k.co.y) for fc in mx_fcurves(acao) for k in fc.keyframe_points)
        rig.animation_data.action = acao
        rig.animation_data.action_slot = acao.slots[0]
        pontos = []
        for i in range(5):
            bpy.context.scene.frame_set(round(fim * i / 4))
            pontos.append(tuple(rig.pose.bones["Hips"].head)[:2])
        assert max(math.dist(p, pontos[0]) for p in pontos) < 1e-4, nome
    for m, visivel in mods:
        m.show_viewport = visivel
    rig.animation_data.action = None
    mx.preparar_rig(rig)
    bpy.context.scene.frame_set(0)
    for nome, (acao, fim) in acoes.items():
        tr = rig.animation_data.nla_tracks.new()
        tr.name = nome
        st = tr.strips.new(nome, 0, acao)
        st.action_slot = acao.slots[0]
        tr.mute = True
    if "--blend" in ARGS:
        bpy.ops.wm.save_as_mainfile(filepath=str(Path(ARGS[ARGS.index("--blend") + 1]).resolve()))
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    rig.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(GLB), export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_frame_range=False,
                              export_force_sampling=False, export_animation_mode="NLA_TRACKS")
    MANIFESTO.write_text(json.dumps(manifesto, ensure_ascii=False, indent=2) + "\n")
    print("PACOTE_V2_EXPORTADO", len(acoes), GLB.stat().st_size, flush=True)


def nova_acao(nome, slot_origem):
    """Ação com um slot igual ao da origem e um channelbag para curvas."""
    novo = bpy.data.actions.new(nome)
    novo.use_fake_user = True
    slot = novo.slots.new(id_type=slot_origem.target_id_type, name=slot_origem.name_display)
    camada = novo.layers.new("Camada")
    faixa = camada.strips.new(type="KEYFRAME")
    return novo, faixa.channelbag(slot, ensure=True)


def recortar(origem, nome, inicio, fim, loop):
    """Igual a miguel_publicar_animacoes.recortar, na API de slots do
    Blender 4.4+: amostra o trecho em quadros lineares e, nos ciclos, fecha o
    último décimo por crossfade (quaternions por slerp)."""
    acao, total = origem
    novo, bag = nova_acao(nome, acao.slots[0])
    n = max(1, round(abs(fim - inicio) * total))
    for fc in mx_fcurves(acao):
        dest = bag.fcurves.new(fc.data_path, index=fc.array_index)
        dest.keyframe_points.add(n + 1)
        for i, kp in enumerate(dest.keyframe_points):
            t = inicio * total + (fim - inicio) * total * i / n
            kp.co = (i, fc.evaluate(t))
            kp.interpolation = "LINEAR"
    if loop:
        m = max(2, round(n * .1))
        a0 = max(0, n - m)
        curvas = list(bag.fcurves)
        for caminho in {fc.data_path for fc in curvas}:
            grupo = sorted((fc for fc in curvas if fc.data_path == caminho), key=lambda fc: fc.array_index)
            primeiro = [fc.keyframe_points[0].co.y for fc in grupo]
            for i in range(a0, n + 1):
                peso = (i - a0) / max(1, min(n, m))
                atual = [fc.keyframe_points[i].co.y for fc in grupo]
                valores = (Quaternion(atual).slerp(Quaternion(primeiro), peso)
                           if caminho.endswith("rotation_quaternion") else
                           [x * (1 - peso) + y * peso for x, y in zip(atual, primeiro)])
                for fc, valor in zip(grupo, valores):
                    fc.keyframe_points[i].co.y = valor
    for fc in bag.fcurves:
        fc.update()
    return novo, n


def mx_fcurves(acao):
    """F-curves de uma ação no Blender 4.4+ (camadas/slots) ou anterior."""
    if hasattr(acao, "fcurves") and len(acao.fcurves):
        return list(acao.fcurves)
    saida = []
    for camada in getattr(acao, "layers", []):
        for faixa in camada.strips:
            for bag in faixa.channelbags:
                saida.extend(bag.fcurves)
    return saida


if __name__ == "__main__":
    main()

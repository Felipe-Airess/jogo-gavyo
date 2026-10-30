"""Animacoes do Mixamo (FBX) aplicadas ao Miguel HD.

Os FBX vem do Mixamo com o esqueleto do proprio Miguel (mesmos nomes de osso:
Hips, Spine, ..., LeftUpperArm, ...). A postura de repouso do Mixamo e outra
(e o objeto vem girado), entao a transferencia e por DIRECAO de osso: em cada
quadro, cada osso do nosso rig passa a apontar para onde o osso do FBX aponta.
O quadril usa a base (frente, lado, cima) medida pelas pernas e coluna.
O deslocamento horizontal do quadril sai (o jogo move o personagem); o
vertical fica (agachar, cair, pular).

Uso:
  blender -b -P arte/miguel_mixamo.py -- --fbx PASTA [--previa DIR]
Cria uma acao por arquivo (nome = arquivo sem extensao) no rig do Miguel.
"""
import glob
import math
import os
import re
import runpy
import sys

import bpy
from mathutils import Matrix, Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
ORDEM = ["Spine", "Chest", "UpperChest", "Neck", "Head"] + [
    l + o for l in ("Left", "Right")
    for o in ("Shoulder", "UpperArm", "LowerArm", "Hand", "UpperLeg", "LowerLeg", "Foot", "Toes")]


def base_quadril(pos):
    """Matriz 3x3 (colunas: esquerda, tras, cima) a partir das posicoes."""
    lado = (pos["LeftUpperLeg"] - pos["RightUpperLeg"]).normalized()
    cima = (pos["Spine_tail"] - pos["Hips"]).normalized()
    tras = cima.cross(lado).normalized()
    cima = lado.cross(tras).normalized()
    return Matrix((lado, tras, cima)).transposed()


def ler_fbx(caminho):
    """Importa o FBX e devolve (nome, quadros) com, por quadro, a direcao de
    cada osso e a base/altura do quadril, ja no espaco "frente = -y"."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=caminho)
    novos = [o for o in bpy.data.objects if o not in antes]
    arm = [o for o in novos if o.type == "ARMATURE"][0]
    acao = arm.animation_data.action
    f0, f1 = (int(round(x)) for x in acao.frame_range)
    cena = bpy.context.scene

    def amostra():
        mw = arm.matrix_world
        pb = arm.pose.bones
        pos = {b.name: mw @ b.head for b in pb}
        pos["Spine_tail"] = mw @ pb["Spine"].tail
        dirs = {b.name: ((mw @ b.tail) - (mw @ b.head)).normalized() for b in pb}
        return pos, dirs

    cena.frame_set(f0)
    pos0, _ = amostra()
    # alinha a postura de pe do primeiro quadro com "frente = -y"
    alinhar = base_quadril(pos0).transposed()
    alinhar = Matrix(((1, 0, 0), (0, 1, 0), (0, 0, 1))) @ alinhar
    chao = min((alinhar @ p).z for k, p in pos0.items() if "Foot" in k or "Toes" in k)
    quadros = []
    for f in range(f0, f1 + 1):
        cena.frame_set(f)
        pos, dirs = amostra()
        posA = {k: alinhar @ v for k, v in pos.items()}
        quadros.append({
            "dirs": {k: alinhar @ v for k, v in dirs.items()},
            "base": base_quadril(posA),
            "altura": posA["Hips"].z - chao,
            "pes": min(posA[k].z for k in ("LeftToes", "RightToes", "LeftFoot", "RightFoot")) - chao,
        })
    for o in novos:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.data.actions.remove(acao)
    nome = re.sub(r"^[0-9a-f]{8}-", "", os.path.splitext(os.path.basename(caminho))[0])
    return nome, quadros, cena.render.fps if False else 30


def aplicar(rig, q, altura_ref, altura_nossa, base_nossa):
    pbs = rig.pose.bones
    for pb in pbs:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    bpy.context.view_layer.update()
    hb = pbs["Hips"]
    m = hb.matrix.copy()
    giro = q["base"] @ base_nossa.inverted()
    desce = (q["altura"] - altura_ref) * (altura_nossa / altura_ref)
    hb.matrix = Matrix.Translation(m.translation + Vector((0, 0, desce))) @ (giro @ m.to_3x3()).normalized().to_4x4()
    bpy.context.view_layer.update()
    for nome in ORDEM:
        alvo = q["dirs"].get(nome)
        if alvo is None:
            continue
        pb = pbs[nome]
        mm = pb.matrix.copy()
        atual = mm.to_3x3().col[1].normalized()
        r = atual.rotation_difference(alvo).to_matrix()
        pb.matrix = Matrix.Translation(mm.translation) @ (r @ mm.to_3x3()).normalized().to_4x4()
        bpy.context.view_layer.update()


def preparar_rig(rig):
    """Altura e base do quadril do nosso rig em repouso."""
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    bpy.context.view_layer.update()
    pbs = rig.pose.bones
    mw = rig.matrix_world
    pos = {b.name: mw @ b.head for b in pbs}
    pos["Spine_tail"] = mw @ pbs["Spine"].tail
    chao = min(pos[k].z for k in ("LeftToes", "RightToes"))
    return pos["Hips"].z - chao, base_quadril(pos)


def transferir(rig, nome, quadros, fps_fbx=30, fps=60):
    altura_nossa, base_nossa = preparar_rig(rig)
    altura_ref = quadros[0]["altura"]
    rig.animation_data_create()
    acao = bpy.data.actions.new(nome)
    acao.use_fake_user = True
    rig.animation_data.action = acao
    for i, q in enumerate(quadros):
        aplicar(rig, q, altura_ref, altura_nossa, base_nossa)
        f = i * fps / fps_fbx
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=f)
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("scale", frame=f)
    rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
        pb.scale = (1, 1, 1)
    return acao, int(round((len(quadros) - 1) * fps / fps_fbx))


def carregar_tudo(pasta, so=None):
    # 1) le todos os FBX ANTES de montar o Miguel (o importador do FBX reusa
    #    nomes como "MiguelRig" e estragava o nosso rig)
    lidos = []
    for arq in sorted(glob.glob(os.path.join(pasta, "*.fbx"))):
        nome = re.sub(r"^[0-9a-f]{8}-", "", os.path.splitext(os.path.basename(arq))[0])
        if so and nome not in so:
            continue
        lidos.append(ler_fbx(arq))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    # 2) monta o Miguel e transfere
    h = runpy.run_path(os.path.join(AQUI, "miguel_humano.py"), run_name="humano")
    ob, rig = h["construir_tudo"]()
    bpy.context.scene.render.fps = 60
    acoes = {}
    for nome, quadros, fps in lidos:
        acoes[nome] = transferir(rig, nome, quadros, fps)
        print("mixamo %-26s %3d quadros" % (nome, len(quadros)))
    return ob, rig, acoes


def previa(rig, acoes, pasta, n=8):
    from PIL import Image
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light, sh.color_type = "STUDIO", "VERTEX"
    sh.show_specular_highlight = False
    cena.view_settings.view_transform = "Standard"
    cena.render.resolution_x, cena.render.resolution_y = 200, 260
    cd = bpy.data.cameras.new("CamMx")
    cd.type, cd.ortho_scale = "ORTHO", 2.6
    cam = bpy.data.objects.new("CamMx", cd)
    cena.collection.objects.link(cam)
    cena.camera = cam
    cam.location = (-5, 0, 0.95)
    cam.rotation_euler = (math.radians(90), 0, math.radians(-90))
    for nome, (acao, fim) in acoes.items():
        rig.animation_data.action = acao
        ims = []
        for i in range(n):
            cena.frame_set(round(fim * i / (n - 1)))
            cena.render.filepath = os.path.join(pasta, "_t.png")
            bpy.ops.render.render(write_still=True)
            ims.append(Image.open(cena.render.filepath).convert("RGB"))
        folha = Image.new("RGB", (200 * n, 260))
        for i, im in enumerate(ims):
            folha.paste(im, (200 * i, 0))
        folha.save(os.path.join(pasta, nome + ".png"))
    rig.animation_data.action = None


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    pasta = os.path.abspath(args[args.index("--fbx") + 1])
    ob, rig, acoes = carregar_tudo(pasta)
    if "--previa" in args:
        previa(rig, acoes, os.path.abspath(args[args.index("--previa") + 1]))


if __name__ == "__main__":
    main()

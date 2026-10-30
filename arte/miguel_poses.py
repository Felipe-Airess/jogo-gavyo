"""Animacoes do Miguel a partir de poses escritas em JSON (arte/poses/*.json).

Cada animacao e uma lista de poses, UMA POR QUADRO do clipe 2D (mesmo numero
de quadros e mesmas duracoes de assets/miguel.json). Cada pose diz PARA ONDE
cada osso aponta (vetor no espaco do personagem), nao angulos de osso: assim o
cotovelo e o joelho nunca invertem por causa de eixo, e da para conferir.

Espaco do personagem: x = esquerda DELE, -y = frente (para onde ele olha),
z = cima. Ex.: [0, -1, 0] = para a frente; [0, 0, -1] = para baixo.

Formato do JSON:
{
  "id": "m3_jab",                     # id do clipe em assets/miguel.json
  "base": "guarda",                   # pose de partida (BASES abaixo); opcional
  "quadros": [                        # N poses = N quadros do clipe
    {"quadril": {"desloc": [0, -0.03, -0.06], "giro": -36, "inclina": 0, "lado": 0},
     "ossos": {"LeftUpperArm": [0.05, -1, 0.15], "LeftLowerArm": [0, -1, 0.05]}},
    ...
  ]
}
- quadril.desloc: metros a partir da posicao de pe (x, y, z); z negativo = abaixa.
- quadril.giro: graus em torno do eixo vertical; negativo = ombro esquerdo
  vai para a frente (guarda ortodoxa ~ -25).
- quadril.inclina: graus para a frente (+) / tras (-); lado: graus para a esquerda dele (+).
- ossos/quadril que faltarem num quadro ficam como na BASE (nao herdam do quadro anterior).
Ossos: Spine, Chest, UpperChest, Neck, Head, Left/Right + Shoulder, UpperArm,
LowerArm, Hand, UpperLeg, LowerLeg, Foot, Toes.

Validacao (o script recusa a pose e diz o quadro):
- joelho: a canela tem de dobrar PARA TRAS da coxa (nunca para a frente);
- cotovelo: o antebraco tem de dobrar para a frente/cima do braco, nunca
  passar da linha reta para tras;
- angulo de joelho e cotovelo entre 0 e 160 graus.
Com "chao": true (padrao), o corpo sobe/desce para o pe mais baixo encostar no chao.

Uso:
  blender -b -P arte/miguel_poses.py -- [--so m3_jab] [--previa DIR] [--glb ARQ]
"""
import glob
import json
import math
import os
import runpy
import sys

import bpy
from mathutils import Euler, Matrix, Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
FPS = 60

# ordem pai -> filho
ORDEM = ["Spine", "Chest", "UpperChest", "Neck", "Head"] + [
    l + o for l in ("Left", "Right")
    for o in ("Shoulder", "UpperArm", "LowerArm", "Hand", "UpperLeg", "LowerLeg", "Foot", "Toes")]


def _n(v):
    return list(Vector(v).normalized())


# Guarda ortodoxa do Miguel (fotos guarda_lado): punhos no rosto, cotovelos
# baixos e fechados, joelhos dobrados, pe esquerdo a frente.
BASES = {
    "guarda": {
        "quadril": {"desloc": [0, 0.02, -0.07], "giro": -25, "inclina": 6, "lado": 0},
        "ossos": {
            "Spine": [0, -0.12, 1], "Chest": [0, -0.08, 1], "UpperChest": [0, -0.04, 1],
            "Neck": [0, -0.20, 1], "Head": [0, -0.10, 1],
            "LeftShoulder": [1, -0.15, 0.05], "RightShoulder": [-1, -0.15, 0.05],
            "LeftUpperArm": _n([0.35, -0.45, -0.85]), "LeftLowerArm": _n([-0.25, -0.55, 0.85]),
            "LeftHand": _n([-0.2, -0.4, 0.9]),
            "RightUpperArm": _n([-0.30, -0.30, -0.90]), "RightLowerArm": _n([0.30, -0.55, 0.80]),
            "RightHand": _n([0.2, -0.4, 0.9]),
            "LeftUpperLeg": _n([0.06, -0.38, -1]), "LeftLowerLeg": _n([0.0, 0.10, -1]),
            "LeftFoot": _n([0.15, -1, -0.35]), "LeftToes": [0.15, -1, 0],
            "RightUpperLeg": _n([-0.05, 0.40, -1]), "RightLowerLeg": _n([0.0, 0.15, -1]),
            "RightFoot": _n([-0.45, -0.9, -0.35]), "RightToes": [-0.45, -0.9, 0],
        },
    },
    "relaxado": {
        "quadril": {"desloc": [0, 0, -0.01], "giro": 0, "inclina": 0, "lado": 0},
        "ossos": {
            "Spine": [0, 0, 1], "Chest": [0, 0, 1], "UpperChest": [0, 0, 1],
            "Neck": [0, -0.05, 1], "Head": [0, 0, 1],
            "LeftShoulder": [1, 0, -0.05], "RightShoulder": [-1, 0, -0.05],
            "LeftUpperArm": _n([0.15, 0.02, -1]), "LeftLowerArm": _n([0.05, -0.15, -1]),
            "LeftHand": [0, -0.1, -1],
            "RightUpperArm": _n([-0.15, 0.02, -1]), "RightLowerArm": _n([-0.05, -0.15, -1]),
            "RightHand": [0, -0.1, -1],
            "LeftUpperLeg": _n([0.03, 0, -1]), "LeftLowerLeg": [0, 0.02, -1],
            "LeftFoot": _n([0.1, -1, -0.35]), "LeftToes": [0.1, -1, 0],
            "RightUpperLeg": _n([-0.03, 0, -1]), "RightLowerLeg": [0, 0.02, -1],
            "RightFoot": _n([-0.1, -1, -0.35]), "RightToes": [-0.1, -1, 0],
        },
    },
}


class PoseInvalida(Exception):
    pass


def _ang(a, b):
    return math.degrees(Vector(a).angle(Vector(b)))


def validar(pose, onde):
    """Joelho dobra para tras, cotovelo para a frente; angulos dentro do limite."""
    o = pose["ossos"]
    for lado in ("Left", "Right"):
        coxa, canela = Vector(o[lado + "UpperLeg"]), Vector(o[lado + "LowerLeg"])
        a = _ang(coxa, canela)
        if a > 160:
            raise PoseInvalida("%s: joelho %s dobrado %.0f graus (max 160)" % (onde, lado, a))
        pe = Vector(o[lado + "Foot"])
        frente_pe = Vector((pe.x, pe.y, 0))
        if a > 15 and frente_pe.length > 0.1:
            # joelho dobrado certo: a canela vai para TRAS da coxa (contra a ponta do pe)
            if (canela - coxa).dot(frente_pe.normalized()) > 0.05:
                raise PoseInvalida("%s: joelho %s dobrado para a frente (a canela tem de ir "
                                   "para tras, contra a ponta do pe)" % (onde, lado))
        braco, ante = Vector(o[lado + "UpperArm"]), Vector(o[lado + "LowerArm"])
        a = _ang(braco, ante)
        if a > 160:
            raise PoseInvalida("%s: cotovelo %s dobrado %.0f graus (max 160)" % (onde, lado, a))


def completar(anim):
    base = BASES[anim.get("base", "guarda")]
    atual = {"quadril": dict(base["quadril"]), "ossos": dict(base["ossos"])}
    saida = []
    for i, q in enumerate(anim["quadros"]):
        # cada quadro parte da BASE (o que nao foi dito volta para a base)
        atual = {"quadril": {**base["quadril"], **q.get("quadril", {})},
                 "ossos": {**base["ossos"], **q.get("ossos", {})},
                 "chao": q.get("chao", anim.get("chao", True))}
        validar(atual, "%s quadro %d" % (anim["id"], i + 1))
        saida.append(atual)
    return saida


def aplicar(rig, pose):
    pbs = rig.pose.bones
    for pb in pbs:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    q = pose["quadril"]
    hb = pbs["Hips"]
    rot = Euler((math.radians(-q.get("inclina", 0)), math.radians(q.get("lado", 0)),
                 math.radians(q.get("giro", 0))), "ZXY").to_matrix()
    m = hb.bone.matrix_local
    nova = Matrix.Translation(m.translation + Vector(q.get("desloc", (0, 0, 0)))) @ (
        rot @ m.to_3x3()).to_4x4()
    hb.matrix = nova
    bpy.context.view_layer.update()
    for nome in ORDEM:
        alvo = pose["ossos"].get(nome)
        if alvo is None:
            continue
        pb = pbs[nome]
        m = pb.matrix.copy()
        atual = m.to_3x3().col[1].normalized()
        giro = atual.rotation_difference(Vector(alvo).normalized()).to_matrix()
        pb.matrix = Matrix.Translation(m.translation) @ (giro @ m.to_3x3()).to_4x4()
        bpy.context.view_layer.update()
    if pose.get("chao", True):
        mundo = rig.matrix_world
        zmin = min((mundo @ pbs[n].tail).z for n in ("LeftToes", "RightToes", "LeftFoot", "RightFoot"))
        alvo_z = 0.012  # sola do tenis
        hb.matrix = Matrix.Translation((0, 0, alvo_z - zmin)) @ hb.matrix
        bpy.context.view_layer.update()


def assar(rig, anim, poses, duracoes):
    rig.animation_data_create()
    acao = bpy.data.actions.new(anim["id"])
    acao.use_fake_user = True
    rig.animation_data.action = acao
    t = 0.0
    quadros = []
    for pose, dur in zip(poses, duracoes):
        f = round(t * FPS / 1000)
        aplicar(rig, pose)
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=f)
            pb.keyframe_insert("location", frame=f)
        quadros.append(f)
        t += dur
    for fc in (acao.fcurves if hasattr(acao, "fcurves") else []):
        for k in fc.keyframe_points:
            k.interpolation = "CONSTANT"  # pose segurada, sem quadro "no meio"
    rig.animation_data.action = None
    return acao, quadros


def previa(rig, feitas, pasta):
    from PIL import Image  # noqa
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light, sh.color_type = "STUDIO", "VERTEX"
    sh.show_specular_highlight = False
    cena.view_settings.view_transform = "Standard"
    cena.render.resolution_x, cena.render.resolution_y = 240, 300
    cd = bpy.data.cameras.new("CamPose")
    cd.type, cd.ortho_scale = "ORTHO", 2.3
    cam = bpy.data.objects.new("CamPose", cd)
    cena.collection.objects.link(cam)
    cena.camera = cam
    cam.location = (-5, 0, 0.95)  # de lado: ele olha para a direita
    cam.rotation_euler = (math.radians(90), 0, math.radians(-90))
    for nome, (acao, quadros) in feitas.items():
        rig.animation_data.action = acao
        tiras = []
        for i, f in enumerate(quadros):
            cena.frame_set(f)
            cena.render.filepath = os.path.join(pasta, "%s_%02d.png" % (nome, i))
            bpy.ops.render.render(write_still=True)
            tiras.append(cena.render.filepath)
        ims = [Image.open(p).convert("RGB") for p in tiras]
        folha = Image.new("RGB", (240 * len(ims), 300))
        for i, im in enumerate(ims):
            folha.paste(im, (240 * i, 0))
        folha.save(os.path.join(pasta, nome + ".png"))
        for p in tiras:
            os.remove(p)
    rig.animation_data.action = None


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    so = args[args.index("--so") + 1].split(",") if "--so" in args else None
    atlas = {c["id"]: c for c in json.load(open(os.path.join(RAIZ, "assets", "miguel.json")))["clips"]}
    for c in atlas.values():
        c.setdefault("durations", [f["duration"] for f in c["frames"]])
    h = runpy.run_path(os.path.join(AQUI, "miguel_humano.py"), run_name="humano")
    ob, rig = h["construir_tudo"]()
    bpy.context.scene.render.fps = FPS
    feitas, erros = {}, []
    for arq in sorted(glob.glob(os.path.join(AQUI, "poses", "*.json"))):
        anim = json.load(open(arq))
        if so and anim["id"] not in so:
            continue
        clipe = atlas.get(anim["id"])
        if clipe is None:
            erros.append("%s: id %s nao existe em assets/miguel.json" % (arq, anim["id"]))
            continue
        if len(anim["quadros"]) != len(clipe["durations"]):
            erros.append("%s: %d quadros, o clipe tem %d" % (anim["id"], len(anim["quadros"]),
                                                            len(clipe["durations"])))
            continue
        try:
            poses = completar(anim)
        except PoseInvalida as e:
            erros.append(str(e))
            continue
        feitas[anim["id"]] = assar(rig, anim, poses, clipe["durations"])
        print("pose ok:", anim["id"])
    for e in erros:
        print("ERRO:", e)
    if "--previa" in args:
        previa(rig, feitas, os.path.abspath(args[args.index("--previa") + 1]))


if __name__ == "__main__":
    main()

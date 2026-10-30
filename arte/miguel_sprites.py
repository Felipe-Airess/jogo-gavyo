"""Sprites 2D do Miguel a partir das animacoes 3D (tecnica do Dead Cells).

Cada clipe 2D de assets/miguel.json e refeito com a animacao 3D equivalente:
mesmo id, mesmo numero de quadros, mesmas duracoes e mesmos quadros de
contato, para o jogo trocar de atlas sem mudar a logica. Cada quadro e
renderizado de lado, ja no tamanho final (sem anti-aliasing), com sombra em
3 tons (cartoon), contorno escuro de 1 px e cor de 15 bits.

Os marcadores (cabeca, punhos, pes, joelho, quadril) saem direto dos ossos e
as caixas de colisao (cabeca, corpo, pernas, bracos) de uma passada com uma
cor por regiao do corpo, no formato de assets/miguel-markers.json.

Uso:
  blender -b -P arte/miguel_sprites.py -- --saida assets/miguel3d [--so m3_jab,...]
gera assets/miguel3d.png, assets/miguel3d.json e assets/miguel3d-markers.json.
"""
import json
import math
import os
import runpy
import sys

import bpy
import numpy as np
from mathutils import Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.dirname(AQUI)
W, H = 128, 96             # celula do atlas (igual a assets/miguel.json)
PIVO = (64, 88)            # pe no chao
PX_M = 70 / 1.76           # Miguel em pe com ~70 px, como nos sprites atuais
COLUNAS = 8
CONTORNO = (0.10, 0.075, 0.065)
GIRO = 25  # graus: camera de lado, um pouco para a frente dele (3/4, como nos sprites 2D)

# clipe 2D -> animacao 3D (os que nao tem nome proprio no 3D)
EXTRA = {"guard": "guarda", "m_walkFwd": "andaFrente", "m_walkBack": "andaTras",
         "m_block": "bloqueio", "m5_kickHigh": "chuteAlto", "m4_kickHigh2": "chuteAlto"}
REGIOES = {"cabeca": ("Head", "Neck"), "bracos": ("UpperArm", "LowerArm", "Hand"),
           "pernas": ("UpperLeg", "LowerLeg", "Foot", "Toes")}  # o resto e corpo
COR_REGIAO = {"cabeca": (1, 0, 0), "corpo": (0, 1, 0), "pernas": (0, 0, 1), "bracos": (1, 1, 0)}


def regiao_do_osso(nome):
    for reg, partes in REGIOES.items():
        if any(nome.endswith(p) for p in partes):
            return reg
    return "corpo"


def tempo_3d(t2, d2, d3):
    """Leva um instante do clipe 2D para o 3D, alinhando o contato."""
    T2, T3 = d2["totalMs"], d3["total"]
    c2 = sum(d2["durations"][:d2["contactFrames"][0]]) if d2.get("contactFrames") else None
    c3 = d3["contato"]
    if c2 is None or c3 is None:
        return t2 * T3 / T2
    if t2 <= c2:
        return t2 * c3 / max(c2, 1)
    return c3 + (t2 - c2) * (T3 - c3) / max(T2 - c2, 1)


# ------------------------------------------------------------ renderizacao
def preparar_cena():
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    cena.render.resolution_x, cena.render.resolution_y = W, H
    cena.render.resolution_percentage = 100
    cena.render.film_transparent = True
    cena.display.render_aa = "OFF"  # pixel duro, sem serrilhado suavizado
    cena.render.image_settings.file_format = "PNG"
    cena.render.image_settings.color_mode = "RGBA"
    cena.view_settings.view_transform = "Standard"
    sh = cena.display.shading
    sh.show_specular_highlight = False
    sh.show_object_outline = False
    sh.show_cavity = False
    cam_d = bpy.data.cameras.new("CamSprite")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = W / PX_M
    cam = bpy.data.objects.new("CamSprite", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    # de lado, pelo lado direito dele: a frente (-y) aparece para a direita
    centro_z = (PIVO[1] - H / 2) / PX_M
    a = math.radians(GIRO)
    cam.location = (-6.0 * math.cos(a), -6.0 * math.sin(a), centro_z)
    cam.rotation_euler = (math.radians(90), 0, math.radians(-90 + GIRO))
    return cena


def render(cena, modo):
    sh = cena.display.shading
    if modo == "cor":
        sh.light = "FLAT"
        vc = any(o.type == "MESH" and o.data.color_attributes for o in bpy.data.objects)
        sh.color_type = "VERTEX" if vc else "TEXTURE"
    elif modo == "luz":
        sh.light, sh.color_type = "STUDIO", "SINGLE"
        sh.single_color = (1, 1, 1)
    else:  # regioes
        sh.light, sh.color_type = "FLAT", "MATERIAL"
    caminho = os.path.join(bpy.app.tempdir, "sprite_%s.png" % modo)
    cena.render.filepath = caminho
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(caminho, check_existing=False)
    px = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)[::-1]
    bpy.data.images.remove(img)
    return px


def materiais_de_regiao(ob, rig):
    """Indice de material por face: 0 = textura; 1..4 = regioes (so na passada de colisao)."""
    me = ob.data
    nomes = list(COR_REGIAO)
    for reg in nomes:
        m = bpy.data.materials.new("reg_" + reg)
        m.diffuse_color = (*COR_REGIAO[reg], 1)
        me.materials.append(m)
    grupos = {g.index: g.name for g in ob.vertex_groups}
    por_face = []
    for p in me.polygons:
        soma = {}
        for vi in p.vertices:
            for g in me.vertices[vi].groups:
                reg = regiao_do_osso(grupos[g.group])
                soma[reg] = soma.get(reg, 0) + g.weight
        por_face.append(1 + nomes.index(max(soma, key=soma.get)) if soma else 2)
    return por_face


def usar_regioes(ob, por_face, ligar):
    for p, idx in zip(ob.data.polygons, por_face):
        p.material_index = idx if ligar else 0


def compor(cor, luz):
    """Cor * luz em 3 tons, contorno de 1 px e 15 bits de cor."""
    alfa = cor[..., 3] > 0.5
    lum = luz[..., :3].mean(-1)
    if alfa.any():
        ref = np.percentile(lum[alfa], 90)
        lum = lum / max(ref, 1e-3)
    tom = np.where(lum < 0.55, 0.62, np.where(lum < 0.85, 0.82, 1.0))
    rgb = np.clip(cor[..., :3] * tom[..., None], 0, 1)
    out = np.zeros((H, W, 4), np.float32)
    out[alfa, :3] = rgb[alfa]
    out[alfa, 3] = 1
    viz = np.zeros_like(alfa)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        viz |= np.roll(alfa, (dy, dx), (0, 1))
    borda = viz & ~alfa
    out[borda, :3] = CONTORNO
    out[borda, 3] = 1
    out[..., :3] = np.round(out[..., :3] * 31) / 31
    return out


def caixas(reg_px):
    """Caixas de colisao em faixas de 4 px por regiao, relativas ao pivo."""
    alfa = reg_px[..., 3] > 0.5
    r, g, b = (reg_px[..., i] > 0.5 for i in range(3))
    mapas = {"head": alfa & r & ~g, "body": alfa & g & ~r, "legs": alfa & b,
             "arms": alfa & r & g}
    saida = {}
    for nome, m in mapas.items():
        rets = []
        for y0 in range(0, H, 4):
            faixa = m[y0:y0 + 4].any(0)
            x = 0
            while x < W:
                if faixa[x]:
                    x1 = x
                    while x1 + 1 < W and faixa[x1 + 1]:
                        x1 += 1
                    rets.append([x - PIVO[0], y0 - PIVO[1], x1 + 1 - PIVO[0],
                                 min(y0 + 4, H) - PIVO[1]])
                    x = x1 + 1
                else:
                    x += 1
        saida[nome] = rets
    return saida


def marcadores(rig, alfa):
    """Pontos do corpo no quadro, tirados dos ossos (px, relativo ao pivo, y para cima < 0)."""
    from bpy_extras.object_utils import world_to_camera_view
    cena = bpy.context.scene

    def px(v):
        u = world_to_camera_view(cena, cena.camera, rig.matrix_world @ v)
        return round(u.x * W - PIVO[0], 2), round((1 - u.y) * H - PIVO[1], 2)

    pb = rig.pose.bones
    cab = (pb["Head"].head + pb["Head"].tail) / 2
    hx, hy = px(cab)
    punhos, pes, joelhos = [], [], []
    for lado in ("Left", "Right"):
        mao = pb[lado + "Hand"]
        cx, cy = px((mao.head + mao.tail) / 2)
        tx, ty = px(mao.tail)
        punhos.append({"x": cx, "y": cy, "tipX": round(tx), "tipY": round(ty)})
        pe = pb[lado + "Foot"]
        fx, fy = px((pe.head + pb[lado + "Toes"].tail) / 2)
        tx, ty = px(pb[lado + "Toes"].tail)
        pes.append({"x": fx, "y": fy, "tipX": round(tx), "tipY": round(ty)})
        kx, ky = px(pb[lado + "LowerLeg"].head)
        joelhos.append({"x": round(kx), "y": round(ky)})
    tx, ty = px((pb["Chest"].head + pb["UpperChest"].tail) / 2)
    _, topo = px(pb["UpperChest"].tail)
    _, base = px(pb["Hips"].tail)
    qx, qy = px(pb["Hips"].head)
    _, queixo = px(pb["Head"].head)
    ys, xs = np.nonzero(alfa)
    chao = min(pes, key=lambda p: -p["y"])
    return {
        "head": {"x": hx, "y": hy, "r": round(0.13 * PX_M, 1), "chin": round(queixo)},
        "torso": {"x": tx, "y": ty, "top": round(topo), "bottom": round(base)},
        "hip": {"x": qx, "y": qy},
        "fists": punhos, "feet": pes,
        "frontFist": max(punhos, key=lambda p: p["tipX"]),
        "frontFoot": max(pes, key=lambda p: p["tipX"]),
        "frontKnee": max(joelhos, key=lambda p: p["x"]),
        "ground": {"x": round(chao["x"]), "y": round(chao["y"])},
        "bounds": {"x0": int(xs.min()) - PIVO[0], "x1": int(xs.max()) - PIVO[0],
                   "y0": int(ys.min()) - PIVO[1], "y1": int(ys.max()) - PIVO[1]} if len(xs) else None,
        "limits": [],
    }


# -------------------------------------------------------------------- main
# Animacoes do Mixamo (arte/mixamo/*.fbx) para cada clipe do jogo:
# clipe: (animacao, inicio, fim [fracao da animacao], efetor do contato, ao contrario)
MIXAMO = {
    "idle": ("Ready_Idle", 0, 1, None, False), "guard": ("Ready_Idle", 0, 1, None, False),
    "m3_idle": ("Ready_Idle", 0, 1, None, False),
    "m_enterGuard": ("Ready_Idle", 0, 0.3, None, False), "m_lowerGuard": ("Ready_Idle", 0.3, 0.6, None, False),
    "m5_tired": ("Look_Over_Shoulder", 0, 1, None, False), "m4_dazed": ("Look_Over_Shoulder", 0, 1, None, False),
    "m_walkFwd": ("Start_Walking", 0.45, 1, None, False), "m3_walk": ("Start_Walking", 0.45, 1, None, False),
    "m4_walkFwd": ("Start_Walking", 0.45, 1, None, False),
    "m_walkBack": ("Start_Walking", 0.45, 1, None, True), "m4_walkBack": ("Start_Walking", 0.45, 1, None, True),
    "m5_walkStart": ("Start_Walking", 0, 0.45, None, False), "m5_walkStop": ("Start_Walking", 0, 0.45, None, True),
    "m4_run": ("Running", 0, 0.36, None, False), "m4_runStart": ("Running", 0, 0.2, None, False),
    "m4_runStop": ("Running_To_Turn", 0, 0.3, None, False),
    "m3_jab": ("Punching_1", 0, 1, "mao", False), "m4_jabStep": ("Punching_1", 0, 1, "mao", False),
    "m3_cross": ("Fist_Fight_A", 0, 0.3, "mao", False), "m4_crossStep": ("Fist_Fight_A", 0, 0.3, "mao", False),
    "m3_crossBody": ("Fist_Fight_A", 0.3, 0.6, "mao", False), "m4_jabBody": ("Fist_Fight_A", 0.6, 1, "mao", False),
    "m3_overhand": ("Hell_Slammer_A", 0, 0.45, "mao", False), "m4_hook": ("Hook_Punch", 0, 1, "mao", False),
    "m4_elbow": ("Hook_Punch_1", 0, 1, "mao", False), "m4_parryCounter": ("Hook_Punch_1", 0, 1, "mao", False),
    "m4_uppercut": ("Knee_Jabs_To_Uppercut", 0.55, 0.85, "mao", False),
    "m3_roundKick": ("Kicking", 0, 1, "pe", False), "m3_stepKick": ("Kicking", 0, 1, "pe", False),
    "m3_lowKick": ("Kicking", 0, 1, "pe", False), "m4_kickHigh": ("Kicking", 0, 1, "pe", False),
    "m5_kickHigh": ("Kicking", 0, 1, "pe", False), "m4_kickHigh2": ("Armada", 0.15, 0.9, "pe", False),
    "m3_knee": ("Knee_Jab", 0.3, 0.85, "pe", False),
    "m4_comboJabElbowKnee": ("Knee_Jab", 0, 1, "pe", False),
    "m4_comboBodyUpper": ("Knee_Jabs_To_Uppercut", 0, 1, "mao", False),
    "m4_comboLowHigh": ("Kicking", 0, 1, "pe", False),
    "m_block": ("Body_Block", 0, 0.5, None, False), "m4_block": ("Body_Block", 0, 0.5, None, False),
    "m4_leanBack": ("Dodging", 0, 0.5, None, False), "m4_slipCounter": ("Dodging", 0.4, 1, "mao", False),
    "m5_guardBreak": ("Blocking", 0, 1, None, False),
    "m4_hitHead": ("Blocking", 0, 0.6, None, False), "m4_hitHeadHeavy": ("Blocking", 0, 1, None, False),
    "m4_hitBody": ("Body_Block", 0.3, 0.8, None, False), "m4_hitLeg": ("Body_Block", 0.5, 1, None, False),
    "m4_fall": ("Sweep_Fall", 0.2, 1, None, False), "m4_lying": ("Sweep_Fall", 0.95, 1, None, False),
    "m4_rise": ("Sweep_Fall", 0.2, 1, None, True), "m5_groundHit": ("Dying", 0.9, 1, None, False),
    "m5_thrown": ("Brutal_Assassination", 0.2, 1, None, False),
    "m5_throw": ("Brutal_Assassination_1", 0, 0.6, None, False),
    "m5_groundPunch": ("Hell_Slammer_A", 0.4, 0.8, "mao", False), "m5_stomp": ("Kicking", 0, 1, "pe", False),
    "m5_clinchGrab": ("Knee_Jab", 0, 0.3, None, False), "m5_clinchHold": ("Knee_Jab", 0.3, 0.4, None, False),
    "m5_clinchKnee": ("Knee_Jab", 0.35, 0.75, "pe", False), "m5_clinchRelease": ("Knee_Jab", 0.8, 1, None, False),
    "m5_held": ("Body_Block", 0, 1, None, False), "m5_clinchEscape": ("Dodging", 0, 0.6, None, False),
}


def extensao(rig, efetor):
    """Quanto o punho (ou o pe) esta para a frente e para cima do quadril."""
    mw = rig.matrix_world
    pb = rig.pose.bones
    q = mw @ pb["Hips"].head
    nomes = ("LeftHand", "RightHand") if efetor == "mao" else ("LeftToes", "RightToes")
    return max(-(mw @ pb[n].tail - q).y + (0.4 * (mw @ pb[n].tail).z if efetor == "pe" else 0)
               for n in nomes)


def quadros_mixamo(rig, cena, fim, plano, c):
    """Quadro da acao (60 fps) para cada quadro do clipe 2D, com o contato no
    pico de extensao do punho/pe dentro do trecho."""
    _, ini, fi, efetor, inverte = plano
    a, b = ini * fim, fi * fim
    n = len(c["durations"])
    contato = c.get("contactFrames") or []
    if c.get("loop"):
        ts = [a + (b - a) * k / n for k in range(n)]
    else:
        ts = [a + (b - a) * k / max(n - 1, 1) for k in range(n)]
    if inverte:
        ts = [a + b - t for t in ts]
    if efetor and contato and not inverte:
        melhor, pico = -1e9, a
        for f in range(int(a), int(b) + 1):
            cena.frame_set(f)
            e = extensao(rig, efetor)
            if e > melhor:
                melhor, pico = e, f
        c0, c1 = contato[0], contato[-1]
        ts = []
        for k in range(n):
            if k < c0:
                ts.append(a + (pico - a) * k / max(c0, 1))
            elif k <= c1:
                ts.append(pico)
            else:
                ts.append(pico + (b - pico) * (k - c1) / max(n - 1 - c1, 1))
    return [int(round(t)) for t in ts]


def main_mixamo(args):
    saida = os.path.abspath(args[args.index("--saida") + 1]) if "--saida" in args \
        else os.path.join(RAIZ, "assets", "miguel3d")
    so = args[args.index("--so") + 1].split(",") if "--so" in args else None
    atlas2d = json.load(open(os.path.join(RAIZ, "assets", "miguel.json")))
    for c in atlas2d["clips"]:
        c.setdefault("durations", [f["duration"] for f in c["frames"]])
    clipes = [c for c in atlas2d["clips"] if (not so or c["id"] in so) and c["id"] in MIXAMO]
    mx = runpy.run_path(os.path.join(AQUI, "miguel_mixamo.py"), run_name="mixamo")
    precisa = sorted({MIXAMO[c["id"]][0] for c in clipes})
    ob, rig, acoes = mx["carregar_tudo"](os.path.join(AQUI, "mixamo"), precisa)
    cena = preparar_cena()
    por_face = materiais_de_regiao(ob, rig)
    quadros, saida_clipes, saida_marc = [], [], {}
    for c in clipes:
        plano = MIXAMO[c["id"]]
        acao, fim = acoes[plano[0]]
        rig.animation_data_create()
        rig.animation_data.action = acao
        fs = quadros_mixamo(rig, cena, fim, plano, c)
        contato = c.get("contactFrames") or []
        frames, marcs = [], []
        for k, (f, dur) in enumerate(zip(fs, c["durations"])):
            cena.frame_set(f)
            usar_regioes(ob, por_face, False)
            cor = render(cena, "cor")
            luz = render(cena, "luz")
            usar_regioes(ob, por_face, True)
            reg = render(cena, "reg")
            usar_regioes(ob, por_face, False)
            img = compor(cor, luz)
            idx = len(quadros)
            quadros.append(img)
            fase = "" if not contato else ("preparação" if k < contato[0] else
                                            "contato" if k <= contato[-1] else "recuperação")
            frames.append({"index": idx, "duration": dur, "sourceFacing": 1, "root": list(PIVO),
                           "phase": fase, "mixamoFrame": f})
            m = marcadores(rig, img[..., 3] > 0.5)
            m["hurt"] = caixas(reg)
            m["index"] = idx
            marcs.append(m)
        clipe = {"id": c["id"], "loop": c["loop"], "durations": c["durations"],
                 "totalMs": sum(c["durations"]), "contactFrames": contato,
                 "source": "mixamo:" + plano[0], "frames": frames}
        if "stride" in c:
            clipe["stride"] = c["stride"]
        saida_clipes.append(clipe)
        saida_marc[c["id"]] = marcs
        print("sprites %-22s <- %-24s quadros %s" % (c["id"], plano[0], fs))
        rig.animation_data.action = None
    salvar(quadros, saida_clipes, saida_marc, saida, "Mixamo (arte/mixamo) no Miguel HD")


def salvar(quadros, saida_clipes, saida_marc, saida, origem):
    linhas = math.ceil(len(quadros) / COLUNAS)
    atlas = np.zeros((linhas * H, COLUNAS * W, 4), np.float32)
    for i, q in enumerate(quadros):
        y, x = divmod(i, COLUNAS)
        atlas[y * H:(y + 1) * H, x * W:(x + 1) * W] = q
    img = bpy.data.images.new("atlas", COLUNAS * W, linhas * H, alpha=True)
    img.pixels.foreach_set(atlas[::-1].ravel())
    img.filepath_raw = saida + ".png"
    img.file_format = "PNG"
    img.save()
    json.dump({"name": "Miguel 3D", "frame": [W, H], "columns": COLUNAS, "root": list(PIVO),
               "reference": "Miguel em pe com ~70 px, igual aos sprites 2D.",
               "preparation": "Renderizado do 3D (%s): sem anti-aliasing, 3 tons, "
                              "contorno de 1 px, 15 bits." % origem,
               "clips": saida_clipes},
              open(saida + ".json", "w"), ensure_ascii=False, indent=1)
    json.dump({"source": os.path.basename(saida) + ".png",
               "method": "ossos do rig 3D (pontos) + passada por regiao do corpo (caixas)",
               "pivot": list(PIVO), "facing": 1, "clips": saida_marc},
              open(saida + "-markers.json", "w"), ensure_ascii=False)
    print("atlas %dx%d, %d quadros" % (COLUNAS * W, linhas * H, len(quadros)))


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if "--mixamo" in args:
        return main_mixamo(args)
    saida = os.path.abspath(args[args.index("--saida") + 1]) if "--saida" in args \
        else os.path.join(RAIZ, "assets", "miguel3d")
    so = args[args.index("--so") + 1].split(",") if "--so" in args else None
    atlas2d = json.load(open(os.path.join(RAIZ, "assets", "miguel.json")))
    for c in atlas2d["clips"]:  # clipes antigos guardam a duracao em cada quadro
        c.setdefault("durations", [f["duration"] for f in c["frames"]])
        c.setdefault("totalMs", sum(c["durations"]))
    anim = runpy.run_path(os.path.join(AQUI, "miguel_animacoes.py"), run_name="sprites")
    # no duelo so o combo tem avanco desenhado (advance); nos outros golpes com
    # passo o corpo fica no lugar, senao o sprite "volta" ao fim do golpe
    COM_AVANCO = {"comboJabCotoveloJoelho"}
    for n, d in anim["A"].items():
        if n not in COM_AVANCO:
            d["chaves"] = [(t, {k: v for k, v in p.items() if k != "off"}) for t, p in d["chaves"]]
    por_clipe = {d["clipe"]: n for n, d in anim["A"].items()}
    por_clipe.update(EXTRA)
    clipes = [c for c in atlas2d["clips"] if (not so or c["id"] in so) and c["id"] in por_clipe]
    precisa = sorted({por_clipe[c["id"]] for c in clipes})
    rig, ob, acoes = anim["preparar"](precisa)

    cena = preparar_cena()
    por_face = materiais_de_regiao(ob, rig)
    quadros, saida_clipes, saida_marc = [], [], {}
    for c in clipes:
        nome3d = por_clipe[c["id"]]
        acao, fim, d3 = acoes[nome3d]
        rig.animation_data_create()
        rig.animation_data.action = acao
        durs = c["durations"]
        contato = c.get("contactFrames") or []
        frames, marcs = [], []
        t2 = 0
        for k, dur in enumerate(durs):
            t3 = tempo_3d(t2, c, d3)
            cena.frame_set(min(fim, round(t3 * anim["FPS"] / 1000)))
            usar_regioes(ob, por_face, False)
            cor = render(cena, "cor")
            luz = render(cena, "luz")
            usar_regioes(ob, por_face, True)
            reg = render(cena, "reg")
            usar_regioes(ob, por_face, False)
            img = compor(cor, luz)
            idx = len(quadros)
            quadros.append(img)
            fase = "" if not contato else ("preparação" if k < contato[0] else
                                            "contato" if k <= contato[-1] else "recuperação")
            frames.append({"index": idx, "duration": dur, "sourceFacing": 1, "root": list(PIVO),
                           "phase": fase, "t3dMs": round(t3)})
            m = marcadores(rig, img[..., 3] > 0.5)
            m["hurt"] = caixas(reg)
            m["index"] = idx
            marcs.append(m)
            t2 += dur
        if nome3d in COM_AVANCO:  # avanco desenhado em px, medido no quadril
            x0 = marcs[0]["hip"]["x"]
            for f, m in zip(frames, marcs):
                f["advance"] = round(m["hip"]["x"] - x0)
        clipe = {"id": c["id"], "loop": c["loop"], "durations": durs,
                 "totalMs": sum(durs), "contactFrames": contato,
                 "source": "3d:" + nome3d, "frames": frames}
        if "stride" in c:
            clipe["stride"] = c["stride"]
        saida_clipes.append(clipe)
        saida_marc[c["id"]] = marcs
        print("sprites %-22s <- %-22s %2d quadros" % (c["id"], nome3d, len(durs)))
        rig.animation_data.action = None

    linhas = math.ceil(len(quadros) / COLUNAS)
    atlas = np.zeros((linhas * H, COLUNAS * W, 4), np.float32)
    for i, q in enumerate(quadros):
        y, x = divmod(i, COLUNAS)
        atlas[y * H:(y + 1) * H, x * W:(x + 1) * W] = q
    img = bpy.data.images.new("atlas", COLUNAS * W, linhas * H, alpha=True)
    img.pixels.foreach_set(atlas[::-1].ravel())
    img.filepath_raw = saida + ".png"
    img.file_format = "PNG"
    img.save()
    json.dump({"name": "Miguel 3D", "frame": [W, H], "columns": COLUNAS, "root": list(PIVO),
               "reference": "Miguel em pe com ~70 px, igual aos sprites 2D.",
               "preparation": "Renderizado das animacoes 3D (arte/miguel_sprites.py): "
                              "sem anti-aliasing, 3 tons, contorno de 1 px, 15 bits.",
               "clips": saida_clipes},
              open(saida + ".json", "w"), ensure_ascii=False, indent=1)
    json.dump({"source": os.path.basename(saida) + ".png",
               "method": "ossos do rig 3D (pontos) + passada por regiao do corpo (caixas)",
               "pivot": list(PIVO), "facing": 1, "clips": saida_marc},
              open(saida + "-markers.json", "w"), ensure_ascii=False)
    print("atlas %dx%d, %d quadros" % (COLUNAS * W, linhas * H, len(quadros)))


if __name__ == "__main__":
    main()

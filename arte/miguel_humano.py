"""Miguel em alta definicao, a partir da malha base do MakeHuman (CC0).

Le so DADOS de arte/makehuman/ (malha base, alvos de forma e o rig
"game_engine" com pesos); nenhum codigo do MPFB2 e executado. O personagem
vira sprite depois (arte/miguel_sprites.py), entao aqui vale detalhe: corpo
realista, cabelo cacheado em volume, roupa do uniforme e cores por vertice.

Uso (Blender 3.6+ ou o modulo bpy):
  blender -b -P arte/miguel_humano.py -- --render DIR
"""
import gzip
import math
import os
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
DADOS = os.path.join(AQUI, "makehuman")
ALTURA = 1.76

# ---------------------------------------------------------------- medidas
# Valores no jeito do MakeHuman (0..1). Miguel: 1,76 m, 67 kg, magro, ombros
# largos, rosto largo nas bochechas, orelhas marcadas, labios cheios.
MACRO = {"gender": 1.0, "age": 0.40, "muscle": 0.55, "weight": 0.40,
         "african": 0.40, "asian": 0.10, "caucasian": 0.50}
# alvo (pasta/nome sem -incr/-decr e sem l-/r-) -> valor (-1..1)
FORMA = {
    "cheek/cheek-volume": 0.55, "cheek/cheek-bones": 0.35,
    "ears/ear-scale": 0.35, "ears/ear-flap": 0.45, "ears/ear-wing": 0.50,
    "nose/nose-flaring": 0.45, "nose/nose-scale-horiz": 0.30, "nose/nose-volume": 0.25,
    "nose/nose-point-width": 0.30,
    "mouth/mouth-upperlip-volume": 0.45, "mouth/mouth-lowerlip-volume": 0.60,
    "mouth/mouth-scale-horiz": 0.15,
    "chin/chin-width": -0.25, "chin/chin-prominent": -0.15,
    "head/head-fat": 0.25, "head/head-scale-horiz": 0.10,
    "torso/torso-vshape": 0.45, "torso/measure-shoulder-dist": 0.35,
    "torso/measure-waist-circ": -0.30,
    "neck/measure-neck-circ": -0.10,
}
LADOS = ("cheek", "ears", "arms")  # alvos com versao l-/r-


# ------------------------------------------------------------ malha base
def ler_obj():
    v, vt, faces, grupo = [], [], [], None
    with open(os.path.join(DADOS, "base.obj")) as f:
        for linha in f:
            if linha.startswith("v "):
                v.append([float(x) for x in linha.split()[1:4]])
            elif linha.startswith("vt "):
                vt.append([float(x) for x in linha.split()[1:3]])
            elif linha.startswith("g "):
                grupo = linha.split()[1]
            elif linha.startswith("f "):
                idx = [p.split("/") for p in linha.split()[1:]]
                faces.append((grupo, [int(p[0]) - 1 for p in idx],
                              [int(p[1]) - 1 if len(p) > 1 and p[1] else -1 for p in idx]))
    return np.array(v, np.float64), np.array(vt, np.float64), faces


def ler_alvo(rel):
    caminho = os.path.join(DADOS, "targets", rel + ".target.gz")
    if not os.path.exists(caminho):
        raise FileNotFoundError(rel)
    idx, d = [], []
    with gzip.open(caminho, "rt") as f:
        for linha in f:
            p = linha.split()
            if len(p) == 4 and not linha.startswith("#"):
                idx.append(int(p[0]))
                d.append([float(x) for x in p[1:]])
    return np.array(idx, np.int64), np.array(d, np.float64)


def somar(co, rel, peso):
    if abs(peso) < 1e-6:
        return
    idx, d = ler_alvo(rel)
    if len(idx):
        np.add.at(co, idx, d * peso)


def partes(valor, nomes, cortes):
    """Interpolacao por faixas, como o MakeHuman (ex.: idade bebe/crianca/jovem/velho)."""
    out = {n: 0.0 for n in nomes}
    for i in range(len(cortes) - 1):
        a, b = cortes[i], cortes[i + 1]
        if a <= valor <= b:
            t = (valor - a) / (b - a)
            out[nomes[i]] += 1 - t
            out[nomes[i + 1]] += t
            break
    return out


def aplicar_macros(co):
    g = MACRO["gender"]
    sexo = {"female": 1 - g, "male": g}
    idade = partes(MACRO["age"], ["baby", "child", "young", "old"], [0, 0.1875, 0.5, 1])
    musc = partes(MACRO["muscle"], ["minmuscle", "averagemuscle", "maxmuscle"], [0, 0.5, 1])
    peso = partes(MACRO["weight"], ["minweight", "averageweight", "maxweight"], [0, 0.5, 1])
    for s, ws in sexo.items():
        for a, wa in idade.items():
            if ws * wa < 1e-4:
                continue
            for e in ("african", "asian", "caucasian"):
                somar(co, "macrodetails/%s-%s-%s" % (e, s, a), ws * wa * MACRO[e])
            for m, wm in musc.items():
                for p, wp in peso.items():
                    w = ws * wa * wm * wp
                    if w > 1e-4:
                        somar(co, "macrodetails/universal-%s-%s-%s-%s" % (s, a, m, p), w)


def aplicar_forma(co):
    for chave, val in FORMA.items():
        pasta, nome = chave.split("/")
        sufixos = ("incr", "decr")
        alvo_lados = [("l-", "r-")] if pasta in LADOS else [("",)]
        for prefixos in alvo_lados:
            for pre in prefixos:
                base = "%s/%s%s" % (pasta, pre, nome)
                somar(co, base + "-" + (sufixos[0] if val > 0 else sufixos[1]), abs(val))


# --------------------------------------------------------------- montagem
GRUPOS_MALHA = ("body", "helper-l-eye", "helper-r-eye")


def construir_corpo():
    v, vt, faces = ler_obj()
    co = v.copy()
    aplicar_macros(co)
    aplicar_forma(co)
    # obj: y para cima, z para a frente, decimetros -> blender: z para cima, -y frente, metros
    bco = np.stack([co[:, 0], -co[:, 2], co[:, 1]], 1) * 0.1
    usadas = [f for f in faces if f[0] in GRUPOS_MALHA]
    usados = sorted({i for f in usadas for i in f[1]})
    novo = {old: k for k, old in enumerate(usados)}
    me = bpy.data.meshes.new("Miguel")
    me.from_pydata(bco[usados].tolist(), [], [[novo[i] for i in f[1]] for f in usadas])
    uv = me.uv_layers.new(name="UVMap")
    li = 0
    for f in usadas:
        for t in f[2]:
            uv.data[li].uv = vt[t] if t >= 0 else (0, 0)
            li += 1
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Miguel", me)
    bpy.context.scene.collection.objects.link(ob)
    # altura certa, pes no chao
    zs = bco[usados][:, 2]
    k = ALTURA / (zs.max() - zs.min())
    for vtx in me.vertices:
        vtx.co.z -= zs.min()
        vtx.co *= k
    grupo_face = [f[0] for f in usadas]
    ob["k"] = k
    ob["z_min"] = float(zs.min())
    return ob, bco, novo, grupo_face, k, float(zs.min())


# ------------------------------------------------------------------ cores
FOTOS = os.path.join(AQUI, "referencias", "miguel")
PELE = (0.56, 0.37, 0.27)
# pontos da foto de frente (rosto_frente.jpg, 1500x2000): olhos e boca
FOTO_OLHO_DIR, FOTO_OLHO_ESQ, FOTO_BOCA = (640, 810), (1010, 810), (820, 1190)


def carregar_foto(nome):
    img = bpy.data.images.load(os.path.join(FOTOS, nome + ".jpg"))
    w, h = img.size
    px = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, w, 4)[::-1, :, :3]


def centro_grupo(me, faces_grupo, nome):
    vs = {v for p, g in zip(me.polygons, faces_grupo) if g == nome for v in p.vertices}
    return sum((me.vertices[i].co for i in vs), Vector()) / max(len(vs), 1), vs


def pintar_corpo(ob, grupo_face):
    """Cor por vertice: pele, rosto projetado da foto de frente, olhos."""
    me = ob.data
    foto = carregar_foto("rosto_frente")
    rosto = foto[900:1350, 520:1150].reshape(-1, 3)
    lum = rosto.mean(1)
    pele = np.median(rosto[(lum > 0.25) & (lum < 0.75)], 0)
    olho_e, vs_e = centro_grupo(me, grupo_face, "helper-l-eye")
    olho_d, vs_d = centro_grupo(me, grupo_face, "helper-r-eye")
    # boca: ponto mais a frente do rosto abaixo do nariz, perto do meio
    cab = [v for v in me.vertices if v.co.z > olho_e.z - 0.09 and abs(v.co.x) < 0.02]
    boca_z = olho_e.z - 0.072
    sx = (FOTO_OLHO_ESQ[0] - FOTO_OLHO_DIR[0]) / (olho_e.x - olho_d.x)
    sz = (FOTO_BOCA[1] - FOTO_OLHO_ESQ[1]) / (olho_e.z - boca_z)
    cx = (FOTO_OLHO_ESQ[0] + FOTO_OLHO_DIR[0]) / 2

    alvo = np.array(PELE, np.float32)  # tom de pele dele (a foto saiu palida na luz fria)
    ganho = alvo / np.maximum(pele, 1e-3)
    cores = np.tile(np.array([*alvo, 1.0], np.float32), (len(me.vertices), 1))
    me.update()
    for v in me.vertices:
        if v.co.z < olho_e.z - 0.16 or v.index in vs_e or v.index in vs_d:
            continue
        frente = max(0.0, -v.normal.y)
        if frente <= 0.05:
            continue
        u = int(cx + v.co.x * sx)
        r = int(FOTO_OLHO_ESQ[1] + (olho_e.z - v.co.z) * sz)
        if 0 <= u < foto.shape[1] and 0 <= r < foto.shape[0]:
            c = foto[r, u]
            escuro = c.max() < 0.16  # sobrancelha, olho, cabelo da franja
            if not escuro and not (c[0] > c[1] > c[2] and c[0] - c[2] > 0.06):
                continue  # parede ou fundo atras do rosto
            # da foto vem so o claro/escuro (sobrancelha, olho, sombra da boca) e um
            # pouco da cor (labio); o tom de pele fica uniforme
            rel = np.clip(c.mean() / max(pele.mean(), 1e-3), 0.15, 1.0) ** 1.2
            if rel > 0.78:  # so tracos mais escuros que a pele (sem manchas de luz)
                rel = 1.0
            croma = c / max(c.mean(), 1e-3) * alvo.mean()
            novo_c = np.clip(alvo * rel * 0.7 + croma * rel * 0.3, 0, 1)
            w = min(1.0, frente * 1.6) ** 1.5
            cores[v.index, :3] = (1 - w) * alvo + w * novo_c
    for vs, centro in ((vs_e, olho_e), (vs_d, olho_d)):  # iris escura, branco em volta
        ys = [me.vertices[i].co.y for i in vs]
        frente_y = min(ys)
        raio = (max(ys) - frente_y) / 2
        for i in vs:
            perto = me.vertices[i].co.y < frente_y + raio * 0.22
            cores[i, :3] = (0.06, 0.04, 0.035) if perto else (0.80, 0.77, 0.72)
    return cores


# ---------------------------------------------------------------- cabelo
CABELO = (0.045, 0.032, 0.026)


def criar_cabelo(ob_corpo, olho_z):
    """Cabelo cacheado: copia do couro cabeludo do corpo engrossada (volume em
    cima e na franja, curto dos lados e na nuca), relevo de cachos e
    cachinhos soltos por cima."""
    from mathutils import noise
    me_c = ob_corpo.data
    me_c.update()

    def escalpo(co):
        orelha = abs(co.x) > 0.062 and olho_z - 0.06 < co.z < olho_z + 0.03 and -0.03 < co.y < 0.045
        if orelha:
            return False
        if co.z > olho_z + 0.055:  # topo e testa alta
            return True
        if co.z > olho_z + 0.012 and co.y > -0.055:  # lados acima da orelha
            return True
        return co.y > 0.025 and co.z > olho_z - 0.085  # nuca

    sel = [p for p in me_c.polygons if all(escalpo(me_c.vertices[i].co) for i in p.vertices)]
    idx = sorted({i for p in sel for i in p.vertices})
    mapa = {o: n for n, o in enumerate(idx)}
    me = bpy.data.meshes.new("Cabelo")
    me.from_pydata([me_c.vertices[i].co[:] for i in idx], [],
                   [[mapa[i] for i in p.vertices] for p in sel])
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    z1 = max(v.co.z for v in bm.verts)
    for v in bm.verts:
        alto = max(0.0, (v.co.z - olho_z) / (z1 - olho_z))
        frente = max(0.0, -v.co.y - 0.02) / 0.07
        espessura = 0.010 + 0.075 * alto ** 1.4 + 0.025 * min(1.0, frente) * alto
        cacho = noise.noise(v.co * 45.0) * 0.010 + noise.noise(v.co * 110.0) * 0.004
        v.co += v.normal * max(0.005, espessura + cacho * (0.3 + alto))
        if frente > 0.5 and v.co.z < olho_z + 0.10:  # franja cai na testa
            v.co.z -= 0.012 * min(1.0, frente)
    rng = np.random.default_rng(7)
    topo = [(v.co.copy(), v.normal.copy()) for v in bm.verts
            if (v.co.z - olho_z) / (z1 - olho_z) > 0.45]
    for i in range(600):
        co, nrm = topo[rng.integers(len(topo))]
        r = rng.uniform(0.006, 0.011)
        res = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r)
        for nv in res["verts"]:
            nv.co += co - nrm * r * 0.35
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("Cabelo", me)
    bpy.context.scene.collection.objects.link(ob)
    cores = np.zeros((len(me.vertices), 4), np.float32)
    for v in me.vertices:
        t = 0.8 + 0.45 * noise.noise(v.co * 70.0)
        cores[v.index] = (CABELO[0] * t * 1.3, CABELO[1] * t * 1.2, CABELO[2] * t, 1)
    return ob, cores


# ----------------------------------------------------------------- roupas
BRANCO = (0.86, 0.87, 0.85)
VERDE = (0.06, 0.38, 0.20)
VERDE_ESC = (0.03, 0.26, 0.15)
AMARELO = (0.90, 0.72, 0.15)
JEANS = (0.33, 0.50, 0.70)
TENIS = (0.90, 0.90, 0.88)


def osso_dominante():
    """Indice da malha base -> osso do rig game_engine com mais peso."""
    pesos = json.load(open(os.path.join(DADOS, "rig", "weights.game_engine.json")))["weights"]
    melhor = {}
    for osso, lista in pesos.items():
        for vi, w in lista:
            if w > melhor.get(vi, ("", 0))[1]:
                melhor[vi] = (osso, w)
    return {vi: o for vi, (o, _) in melhor.items()}


def regioes_roupa(me, base_idx, dom, jt):
    """Regiao de cada vertice: camisa, jeans, tenis ou pele."""
    reg = []
    for v in me.vertices:
        o = dom.get(int(base_idx[v.index]), "")
        r = None
        if o.startswith(("spine", "clavicle")) or o == "pelvis" and v.co.z > jt["joint-pelvis"].z - 0.02:
            r = "camisa"
        elif o.startswith("upperarm"):
            lado = "l" if o.endswith("_l") else "r"
            a, b = jt["joint-%s-shoulder" % lado], jt["joint-%s-elbow" % lado]
            t = (v.co - a).dot(b - a) / (b - a).length_squared
            r = "camisa" if t < 0.48 else None
        elif o.startswith(("thigh", "calf")) or o in ("pelvis", "Root"):
            r = "jeans"
        elif o.startswith(("foot", "ball")):
            r = "tenis"
        reg.append(r)
    return reg


def vestir(ob, cores, base_idx, dom, jt):
    """Polo, jeans folgado e tenis como copias deslocadas da pele (seguem os
    mesmos pesos); a pele coberta sai da malha."""
    me = ob.data
    reg_v = regioes_roupa(me, base_idx, dom, jt)
    bm = bmesh.new()
    bm.from_mesh(me)
    orig = bm.verts.layers.int.new("orig")
    for v in bm.verts:
        v[orig] = v.index
    bm.verts.ensure_lookup_table()
    bm.normal_update()
    z_quadril = jt["joint-pelvis"].z
    z_ombro = jt["joint-l-shoulder"].z

    grupos = {"camisa": [], "jeans": [], "tenis": []}
    for f in bm.faces:
        rs = [reg_v[v.index] for v in f.verts]
        if any(rs):
            r = max(set(rs) - {None}, key=rs.count)
            grupos[r].append(f)
    folga = {"camisa": 0.010, "jeans": 0.014, "tenis": 0.014}
    roupas = {}
    for nome, fs in grupos.items():
        res = bmesh.ops.duplicate(bm, geom=fs)
        novas = [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace)]
        vs = {v for f in novas for v in f.verts}
        for v in vs:
            extra = 0.0
            if nome == "jeans":  # perna reta: mais folga embaixo
                extra = 0.016 * max(0.0, min(1.0, (z_quadril * 0.75 - v.co.z) / (z_quadril * 0.6)))
            if nome == "camisa" and v.co.z < z_quadril + 0.12:  # barra solta por cima da calca
                extra = 0.008
            v.co += v.normal * (folga[nome] + extra)
        roupas[nome] = (novas, vs)
        bmesh.ops.delete(bm, geom=fs, context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.verts.ensure_lookup_table()
    bm.verts.index_update()

    n = len(bm.verts)
    novas_cores = np.zeros((n, 4), np.float32)
    origs = np.array([v[orig] for v in bm.verts])
    novas_cores[:] = cores[origs]
    for v in roupas["tenis"][1]:
        novas_cores[v.index] = (*((0.55, 0.55, 0.56) if v.co.z < 0.03 else TENIS), 1)
    for v in roupas["jeans"][1]:
        t = 0.92 + 0.08 * math.sin(v.co.z * 140 + v.co.x * 50)
        novas_cores[v.index] = (*(c * t for c in JEANS), 1)
    for v in roupas["camisa"][1]:
        cor = BRANCO
        # barra verde (onda) com friso amarelo, como no uniforme
        onda = z_quadril + 0.10 + 0.02 * math.sin(v.co.x * 9 + 1.2)
        if v.co.z < onda:
            cor = VERDE if v.co.z > z_quadril + 0.04 else VERDE_ESC
        novas_cores[v.index] = (*cor, 1)
    # gola: friso verde na borda de cima da camisa
    for f in roupas["camisa"][0]:
        for e in f.edges:
            if e.is_boundary and all(v.co.z > z_ombro - 0.03 and abs(v.co.x) < 0.11 for v in e.verts):
                for v in e.verts:
                    novas_cores[v.index] = (*VERDE, 1)
    bm.to_mesh(me)
    bm.free()
    origem = np.array([me.attributes["orig"].data[i].value for i in range(len(me.vertices))])
    return novas_cores, origem


def aplicar_cores(ob, cores):
    me = ob.data
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    attr.data.foreach_set("color", cores.ravel())
    me.color_attributes.active_color = attr
    mat = bpy.data.materials.new("Miguel")
    mat.use_nodes = True
    nt = mat.node_tree
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    bsdf = nt.nodes.get("Principled BSDF")
    nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    me.materials.clear()
    me.materials.append(mat)


# ------------------------------------------------------------------- rig
import json  # noqa: E402

# osso nosso -> ossos do rig game_engine (pesos somados)
MAPA_OSSOS = {
    "Hips": ["Root", "pelvis"], "Spine": ["spine_01"], "Chest": ["spine_02"],
    "UpperChest": ["spine_03"], "Neck": ["neck_01"], "Head": ["head"],
}
for _l, _s in (("Left", "l"), ("Right", "r")):
    MAPA_OSSOS.update({
        _l + "Shoulder": ["clavicle_" + _s], _l + "UpperArm": ["upperarm_" + _s],
        _l + "LowerArm": ["lowerarm_" + _s],
        _l + "Hand": ["hand_" + _s] + ["%s_0%d_%s" % (d, i, _s) for d in
                                       ("thumb", "index", "middle", "ring", "pinky") for i in (1, 2, 3)],
        _l + "UpperLeg": ["thigh_" + _s], _l + "LowerLeg": ["calf_" + _s],
        _l + "Foot": ["foot_" + _s], _l + "Toes": ["ball_" + _s],
    })
PAI = {"Spine": "Hips", "Chest": "Spine", "UpperChest": "Chest", "Neck": "UpperChest",
       "Head": "Neck"}
for _l in ("Left", "Right"):
    PAI.update({_l + "Shoulder": "UpperChest", _l + "UpperArm": _l + "Shoulder",
                _l + "LowerArm": _l + "UpperArm", _l + "Hand": _l + "LowerArm",
                _l + "UpperLeg": "Hips", _l + "LowerLeg": _l + "UpperLeg",
                _l + "Foot": _l + "LowerLeg", _l + "Toes": _l + "Foot"})


def juntas(bco, faces_todas, k, z_min):
    """Posicao de cada junta = centro dos vertices do cubo joint-* (ja deformado)."""
    grupos = {}
    for g, vs, _ in faces_todas:
        if g.startswith("joint-"):
            grupos.setdefault(g, set()).update(vs)
    return {g: Vector(((bco[list(vs)].mean(0) - [0, 0, z_min]) * k).tolist())
            for g, vs in grupos.items()}


def riggar(ob, bco, faces_todas, k, z_min, origem, ob_cabelo):
    rig_json = json.load(open(os.path.join(DADOS, "rig", "rig.game_engine.json")))
    pesos = json.load(open(os.path.join(DADOS, "rig", "weights.game_engine.json")))["weights"]
    jt = juntas(bco, faces_todas, k, z_min)

    def ponto(spec):
        if spec.get("strategy") == "CUBE":
            return jt[spec["cube_name"]]
        if spec.get("strategy") == "VERTEX":
            return Vector(((bco[spec["vertex_index"]] - [0, 0, z_min]) * k).tolist())
        p = spec["default_position"]
        return Vector(p)

    pos = {n: (ponto(b["head"]), ponto(b["tail"])) for n, b in rig_json.items()}
    arm = bpy.data.armatures.new("MiguelRig")
    rig = bpy.data.objects.new("MiguelRig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for nosso, deles in MAPA_OSSOS.items():
        base = deles[-1] if nosso == "Hips" else deles[0]
        h, t = pos[base]
        if nosso == "Hips":
            t = pos["spine_01"][0]
        e = arm.edit_bones.new(nosso)
        e.head, e.tail = h, t
        if (t - h).length < 0.01:
            e.tail = h + Vector((0, 0, 0.05))
    for nosso, pai in PAI.items():
        arm.edit_bones[nosso].parent = arm.edit_bones[pai]
    for lado in ("Left", "Right"):  # cotovelo e joelho levemente dobrados (IK)
        eb = arm.edit_bones
        ua, la = eb[lado + "UpperArm"], eb[lado + "LowerArm"]
        meio = la.head + Vector((0, 0.012, 0))
        ua.tail = meio
        la.head = meio
    bpy.ops.object.mode_set(mode="OBJECT")

    grupos = {n: ob.vertex_groups.new(name=n) for n in MAPA_OSSOS}
    por_vert = {}
    for nosso, deles in MAPA_OSSOS.items():
        for osso in deles:
            for vi, w in pesos.get(osso, []):
                por_vert.setdefault(vi, {}).setdefault(nosso, 0.0)
                por_vert[vi][nosso] += w
    for i, o in enumerate(origem):
        for nosso, w in por_vert.get(int(o), {}).items():
            if w > 0.002:
                grupos[nosso].add([i], w, "REPLACE")
    gh = ob_cabelo.vertex_groups.new(name="Head")
    gh.add(list(range(len(ob_cabelo.data.vertices))), 1.0, "REPLACE")
    for o in (ob, ob_cabelo):
        o.parent = rig
        mod = o.modifiers.new("Armature", "ARMATURE")
        mod.object = rig
    return rig


def fechar_maos(ob, bco, faces_todas, k, z_min, origem):
    """Punhos fechados gravados na malha: dobra os dedos com o rig completo do
    MakeHuman (que tem ossos de dedo) e aplica a deformacao."""
    rig_json = json.load(open(os.path.join(DADOS, "rig", "rig.game_engine.json")))
    pesos = json.load(open(os.path.join(DADOS, "rig", "weights.game_engine.json")))["weights"]
    jt = juntas(bco, faces_todas, k, z_min)

    def ponto(spec):
        if spec.get("strategy") == "CUBE":
            return jt[spec["cube_name"]]
        if spec.get("strategy") == "VERTEX":
            return Vector(((bco[spec["vertex_index"]] - [0, 0, z_min]) * k).tolist())
        return Vector(spec["default_position"])

    arm = bpy.data.armatures.new("tmp_maos")
    rig = bpy.data.objects.new("tmp_maos", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for n, b in rig_json.items():
        e = arm.edit_bones.new(n)
        e.head, e.tail = ponto(b["head"]), ponto(b["tail"])
        if (e.tail - e.head).length < 1e-4:
            e.tail = e.head + Vector((0, 0, 0.01))
        e.roll = b.get("roll", 0.0)
    for n, b in rig_json.items():
        if b.get("parent"):
            arm.edit_bones[n].parent = arm.edit_bones[b["parent"]]
    bpy.ops.object.mode_set(mode="OBJECT")
    grupos = {n: ob.vertex_groups.new(name="tmp_" + n) for n in rig_json}
    inv = {}
    for i, o in enumerate(origem):
        inv.setdefault(int(o), []).append(i)
    for osso, lista in pesos.items():
        for vi, w in lista:
            if vi in inv:
                grupos[osso].add(inv[vi], w, "REPLACE")
    # dedos dobrados (eixo X local de cada falange), polegar menos
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
        n = pb.name
        if n.startswith(("index", "middle", "ring", "pinky")):
            pb.rotation_euler.x = math.radians(80 if n[-4:-2] == "01" or "_01_" in n else 85)
        elif n.startswith("thumb"):
            pb.rotation_euler.x = math.radians(35)
    for pb in rig.pose.bones:  # o arquivo usa o nome do grupo para o modificador
        pass
    for n, g in grupos.items():
        g.name = n
    mod = ob.modifiers.new("tmp_maos", "ARMATURE")
    mod.object = rig
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="tmp_maos")
    for g in list(ob.vertex_groups):
        ob.vertex_groups.remove(g)
    bpy.data.objects.remove(rig, do_unlink=True)


# ------------------------------------------------------------- tudo junto
def construir_tudo():
    """Corpo, cabelo, roupas, cores e rig. Devolve (malha unica, rig)."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    ob, bco, novo, grupo_face, k, z_min = construir_corpo()
    _, _, faces_todas = ler_obj()
    jt = juntas(bco, faces_todas, k, z_min)
    usados = np.array(sorted(novo, key=novo.get))
    dom = osso_dominante()
    olho_z = centro_grupo(ob.data, grupo_face, "helper-l-eye")[0].z
    cores = pintar_corpo(ob, grupo_face)
    ob_cab, cores_cab = criar_cabelo(ob, olho_z)
    cores, origem_local = vestir(ob, cores, usados, dom, jt)
    origem = usados[origem_local]  # indice na malha base do MakeHuman
    fechar_maos(ob, bco, faces_todas, k, z_min, origem)
    aplicar_cores(ob, cores)
    aplicar_cores(ob_cab, cores_cab)
    rig = riggar(ob, bco, faces_todas, k, z_min, origem, ob_cab)
    # uma malha so (o pipeline de sprites e o glb esperam um objeto)
    bpy.ops.object.select_all(action="DESELECT")
    ob_cab.select_set(True)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.join()
    ob.data.color_attributes.active_color = ob.data.color_attributes["Col"]
    return ob, rig


# ----------------------------------------------------------------- previa
def renderizar(pasta, ob):
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light, sh.color_type = "STUDIO", "VERTEX"
    sh.show_specular_highlight = False
    cena.view_settings.view_transform = "Standard"
    cena.render.resolution_x, cena.render.resolution_y = 600, 1000
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam = bpy.data.objects.new("Cam", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    for nome, (loc, rot, esc, z) in {
        "frente": ((0, -5, 0), (90, 0, 0), 2.0, 0.9),
        "lado": ((5, 0, 0), (90, 0, 90), 2.0, 0.9),
        "costas": ((0, 5, 0), (90, 0, 180), 2.0, 0.9),
        "rosto": ((0, -5, 0), (90, 0, 0), 0.36, 1.60),
        "rosto_lado": ((5, 0, 0), (90, 0, 90), 0.36, 1.60),
    }.items():
        cam_d.ortho_scale = esc
        cam.location = (loc[0], loc[1], z)
        cam.rotation_euler = [math.radians(a) for a in rot]
        cena.render.filepath = os.path.join(pasta, nome + ".png")
        bpy.ops.render.render(write_still=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ob, rig = construir_tudo()
    print("Miguel HD: %d vertices, %d faces, %d ossos" % (
        len(ob.data.vertices), len(ob.data.polygons), len(rig.data.bones)))
    if "--render" in args:
        renderizar(os.path.abspath(args[args.index("--render") + 1]), ob)
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))


if __name__ == "__main__":
    main()

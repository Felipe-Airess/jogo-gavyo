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
MACRO = {"gender": 1.0, "age": 0.52, "muscle": 0.55, "weight": 0.40,
         "african": 0.40, "asian": 0.10, "caucasian": 0.50}
# alvo (pasta/nome sem -incr/-decr e sem l-/r-) -> valor (-1..1)
FORMA = {
    # rosto comprido e largo nas macas; maxilar marcado, queixo redondo
    "head/head-scale-vert": 0.05, "head/head-oval": 0.10, "head/head-scale-horiz": 0.40,
    "cheek/cheek-bones": 0.70, "cheek/cheek-volume": 0.45,
    "chin/chin-prominent": 0.15, "chin/chin-height": 0.20, "chin/chin-width": 0.15,
    # testa e sobrancelha pesadas (olho fundo, sobrancelha baixa)
    "eyebrows/eyebrows-trans-down": 0.35, "eyebrows/eyebrows-trans-forward": 0.30,
    "forehead/forehead-trans-forward": 0.15,
    # orelhas grandes e de abano
    "ears/ear-scale": 0.50, "ears/ear-flap": 0.65, "ears/ear-wing": 0.80,
    # nariz longo, largo, ponta redonda e asas abertas
    "nose/nose-scale-vert": 0.30, "nose/nose-scale-horiz": 0.35, "nose/nose-volume": 0.30,
    "nose/nose-point-width": 0.55, "nose/nose-flaring": 0.55, "nose/nose-trans-forward": 0.15,
    # labios cheios e largos, arco do cupido marcado
    "mouth/mouth-upperlip-volume": 0.55, "mouth/mouth-lowerlip-volume": 0.75,
    "mouth/mouth-scale-horiz": 0.25, "mouth/mouth-cupidsbow": 0.30,
    # corpo: ombros largos, cintura fina, pescoco longo
    "torso/torso-vshape": 0.45, "torso/measure-shoulder-dist": 0.35,
    "torso/measure-waist-circ": -0.30,
    "neck/measure-neck-circ": -0.05, "neck/measure-neck-height": 0.25,
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
                rel = base + "-" + (sufixos[0] if val > 0 else sufixos[1])
                if not os.path.exists(os.path.join(DADOS, "targets", rel + ".target.gz")):
                    rel = base  # alvo de um lado so (ex.: head-square)
                somar(co, rel, abs(val))


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
PELE = (0.62, 0.42, 0.30)       # pardo, tirado das fotos (corrigido da luz fria)
LABIO = (0.72, 0.45, 0.40)
SOBRANCELHA = (0.10, 0.07, 0.05)
ESCLERA = (0.86, 0.84, 0.80)
IRIS = (0.10, 0.06, 0.04)


def centro_grupo(me, faces_grupo, nome):
    vs = {v for p, g in zip(me.polygons, faces_grupo) if g == nome for v in p.vertices}
    return sum((me.vertices[i].co for i in vs), Vector()) / max(len(vs), 1), vs


def pintar_corpo(ob, grupo_face, jt):
    """Pele uniforme e rosto pintado limpo: sobrancelha, labios e olhos."""
    me = ob.data
    me.update()
    cores = np.tile(np.array([*PELE, 1.0], np.float32), (len(me.vertices), 1))
    olho_e, vs_e = centro_grupo(me, grupo_face, "helper-l-eye")
    olho_d, vs_d = centro_grupo(me, grupo_face, "helper-r-eye")
    oz = (olho_e.z + olho_d.z) / 2
    # fenda da boca: ponto mais "fundo" (maior y) no meio do rosto abaixo do nariz
    # boca: altura da junta "joint-mouth" do MakeHuman, na frente do rosto
    # boca: abaixo da ponta do nariz (ponto mais a frente do rosto)
    meio = [v for v in me.vertices if abs(v.co.x) < 0.006 and oz - 0.10 < v.co.z < oz]
    nariz = min(meio, key=lambda v: v.co.y).co
    bz = nariz.z - 0.040
    perto = [v for v in meio if abs(v.co.z - bz) < 0.006]
    boca = Vector((0, min(v.co.y for v in perto), bz))
    frente_rosto = min(v.co.y for v in me.vertices if abs(v.co.x) < 0.01 and abs(v.co.z - oz) < 0.03)
    for v in me.vertices:
        c = v.co
        if c.y > frente_rosto + 0.06 or v.index in vs_e or v.index in vs_d:
            continue
        ax = abs(c.x)
        # sobrancelha grossa, reta e baixa, caindo um pouco na ponta de fora
        if 0.007 < ax < 0.056:
            t = (ax - 0.007) / 0.049
            meio = oz + 0.016 + 0.0015 * t - 0.004 * max(0.0, t - 0.75) / 0.25
            grossura = 0.0052 * (1.0 - 0.40 * t)
            if abs(c.z - meio) < grossura and c.y < frente_rosto + 0.045:
                cores[v.index, :3] = SOBRANCELHA
        # bigodinho ralo: acima do labio e descendo nos cantos da boca
        if ax < 0.027 and c.y < boca.y + 0.01:
            acima = boca.z + 0.009 < c.z < boca.z + 0.016
            canto = 0.019 < ax and boca.z - 0.004 < c.z < boca.z + 0.012
            if acima or canto:
                cores[v.index, :3] = np.array(PELE) * 0.6 + np.array(SOBRANCELHA) * 0.4
        # labios: faixa em volta da fenda da boca, afinando nos cantos
        largura = 0.026
        if ax < largura and c.y < boca.y + 0.012:
            alto = 0.0075 * (1 - (ax / largura) ** 2)
            if boca.z - alto * 1.3 < c.z < boca.z + alto:
                cores[v.index, :3] = LABIO
    for centro in (olho_e, olho_d):  # linha dos cilios em cima do olho
        for v in me.vertices:
            d = v.co - centro
            if v.index in vs_e or v.index in vs_d or v.co.y > centro.y:
                continue
            horiz = math.hypot(d.x, d.y)
            if horiz < 0.014 and 0.0045 < d.z < 0.0072:
                cores[v.index, :3] = SOBRANCELHA
    for vs, centro in ((vs_e, olho_e), (vs_d, olho_d)):
        ys = [me.vertices[i].co.y for i in vs]
        frente_y, raio = min(ys), (max(ys) - min(ys)) / 2
        for i in vs:
            cores[i, :3] = IRIS if me.vertices[i].co.y < frente_y + raio * 0.45 else ESCLERA
    return cores, boca


# ------------------------------------------------------------ util malha
def objeto_de_faces(nome, me_origem, faces):
    """Objeto novo com uma copia das faces dadas (indices de poligono)."""
    vs = sorted({i for f in faces for i in me_origem.polygons[f].vertices})
    mapa = {o: n for n, o in enumerate(vs)}
    me = bpy.data.meshes.new(nome)
    me.from_pydata([me_origem.vertices[i].co[:] for i in vs], [],
                   [[mapa[i] for i in me_origem.polygons[f].vertices] for f in faces])
    ob = bpy.data.objects.new(nome, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def suavizar(bm, vezes, fator=0.5, manter_borda=True):
    vs = [v for v in bm.verts if not (manter_borda and v.is_boundary)]
    for _ in range(vezes):
        bmesh.ops.smooth_vert(bm, verts=vs, factor=fator, use_axis_x=True,
                              use_axis_y=True, use_axis_z=True)


def cortar(bm, ponto, normal):
    """Corta a malha num plano e joga fora o lado para onde a normal aponta."""
    geom = list(bm.verts) + list(bm.edges) + list(bm.faces)
    bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=ponto, plane_no=normal,
                           clear_outer=True)


def engrossar(bm, quanto):
    """Desloca cada vertice pela normal (quanto: funcao do vertice -> metros)."""
    bm.normal_update()
    desloc = [(v, v.normal.copy() * quanto(v)) for v in bm.verts]
    for v, d in desloc:
        v.co += d


# ---------------------------------------------------------------- cabelo
CABELO = (0.055, 0.038, 0.030)


def criar_cabelo(ob_corpo, olho_z):  # noqa: C901
    """Cabelo cacheado como um volume so: casca do couro cabeludo engrossada
    (alto em cima e na franja, curto nos lados) com cachos esculpidos na
    superficie (calotas arredondadas), sem bolinhas soltas."""
    me_c = ob_corpo.data

    def escalpo(co):
        orelha = abs(co.x) > 0.060 and olho_z - 0.065 < co.z < olho_z + 0.035 and -0.035 < co.y < 0.05
        if orelha:
            return False
        if co.z > olho_z + 0.050:
            return True
        if co.z > olho_z + 0.010 and co.y > -0.06:
            return True
        return co.y > 0.02 and co.z > olho_z - 0.09

    faces = [p.index for p in me_c.polygons if all(escalpo(me_c.vertices[i].co) for i in p.vertices)]
    ob = objeto_de_faces("Cabelo", me_c, faces)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.normal_update()
    z1 = max(v.co.z for v in bm.verts)

    def volume(v):  # alto em cima e na franja, curto nos lados e na nuca
        alto = max(0.0, (v.co.z - olho_z) / (z1 - olho_z))
        frente = min(1.0, max(0.0, -v.co.y - 0.02) / 0.07)
        return 0.006 + 0.030 * alto ** 1.3 + 0.014 * frente * alto
    engrossar(bm, volume)
    for v in bm.verts:  # franja cai sobre a testa
        if v.co.y < -0.04 and v.co.z < olho_z + 0.10:  # cachos caem na testa
            v.co.z -= 0.012
            v.co.y -= 0.004
    bm.to_mesh(ob.data)
    bm.free()
    sol = ob.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.03
    sol.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Solid")
    remesh(ob, 0.006)  # volume fechado de borda redonda (sem serrilhado)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    suavizar(bm, 3, 0.5, manter_borda=False)
    bm.normal_update()
    rng = np.random.default_rng(11)
    externos = [v for v in bm.verts if v.co.z > olho_z - 0.02 or v.co.y > 0.04]
    sementes = [externos[i].co.copy() for i in rng.choice(len(externos), 480, replace=False)]
    raios = rng.uniform(0.009, 0.016, len(sementes))
    from mathutils.kdtree import KDTree
    kd = KDTree(len(sementes))
    for i, sp in enumerate(sementes):
        kd.insert(sp, i)
    kd.balance()
    desloc = []
    for v in bm.verts:
        cacho = 0.0
        for _, i, d in kd.find_range(v.co, 0.024):
            r = raios[i]
            if d < r:
                cacho = max(cacho, math.sqrt(r * r - d * d))
        desloc.append((v, v.normal * cacho * 0.9))
    for v, d in desloc:
        v.co += d
    bm.to_mesh(ob.data)
    bm.free()
    me = ob.data
    for p in me.polygons:
        p.use_smooth = True
    # cor: fundo dos cachos mais escuro, topo dos cachos com brilho castanho
    cores = np.zeros((len(me.vertices), 4), np.float32)
    for v in me.vertices:
        perto = min(((v.co - s).length / r for s, r in zip(sementes, raios)), default=2)
        brilho = max(0.0, 1 - perto) ** 0.7
        t = 0.75 + 0.9 * brilho
        cores[v.index] = (CABELO[0] * t, CABELO[1] * t, CABELO[2] * t * 0.95, 1)
    return ob, cores


# ----------------------------------------------------------------- roupas
BRANCO = (0.88, 0.89, 0.87)
VERDE = (0.05, 0.42, 0.22)
VERDE_ESC = (0.03, 0.28, 0.17)
TEAL = (0.05, 0.36, 0.38)
AMARELO = (0.92, 0.74, 0.16)
JEANS = (0.27, 0.42, 0.62)
TENIS = (0.92, 0.92, 0.90)
SOLA = (0.60, 0.60, 0.62)
ROXO = (0.42, 0.30, 0.70)


def osso_dominante():
    """Indice da malha base -> osso do rig game_engine com mais peso."""
    pesos = json.load(open(os.path.join(DADOS, "rig", "weights.game_engine.json")))["weights"]
    melhor = {}
    for osso, lista in pesos.items():
        for vi, w in lista:
            if w > melhor.get(vi, ("", 0))[1]:
                melhor[vi] = (osso, w)
    return {vi: o for vi, (o, _) in melhor.items()}


def faces_por_osso(me, base_idx, dom, ok):
    """Faces cujos vertices todos passam no teste ok(osso, co)."""
    osso = [dom.get(int(base_idx[v.index]), "") for v in me.vertices]
    return [p.index for p in me.polygons
            if all(ok(osso[i], me.vertices[i].co) for i in p.vertices)]


def fazer_camisa(ob, base_idx, dom, jt):
    me = ob.data
    zq, zo = jt["joint-pelvis"].z, jt["joint-l-shoulder"].z
    zp = jt["joint-neck"].z if "joint-neck" in jt else zo + 0.06

    def ok(o, co):
        if o.startswith(("head", "neck", "hand", "lowerarm", "calf", "foot", "ball",
                         "thumb", "index", "middle", "ring", "pinky")):
            return False
        return co.z > zq - 0.16
    cam = objeto_de_faces("Camisa", me, faces_por_osso(me, base_idx, dom, ok))
    bm = bmesh.new()
    bm.from_mesh(cam.data)
    suavizar(bm, 6, 0.5, manter_borda=False)  # tecido: some o desenho dos musculos
    # cortes retos: barra, mangas e decote
    cortar(bm, Vector((0, 0, zq - 0.035)), Vector((0, 0, -1)))
    for lado in ("l", "r"):
        a, b = jt["joint-%s-shoulder" % lado], jt["joint-%s-elbow" % lado]
        eixo = (b - a).normalized()
        braco = [f for f in bm.faces if (f.calc_center_median() - a).dot(eixo) > 0.03
                 and f.calc_center_median().z > zq + 0.22
                 and (f.calc_center_median().x > 0.12 if lado == "l" else f.calc_center_median().x < -0.12)]
        geom = list({v for f in braco for v in f.verts}) + list({e for f in braco for e in f.edges}) + braco
        bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=a + (b - a) * 0.50,
                               plane_no=eixo, clear_outer=True)
    cortar(bm, Vector((0, -0.04, zp - 0.005)), Vector((0, -0.45, 1)).normalized())
    engrossar(bm, lambda v: 0.014)
    # da cintura para baixo a camisa cai reta como um tubo por cima da calca
    zc = zq + 0.10
    faixa = [v.co for v in bm.verts if abs(v.co.z - zc) < 0.012]
    ra = max(abs(c.x) for c in faixa) * 1.16
    rb = max(abs(c.y) for c in faixa) * 1.22
    for v in bm.verts:
        if v.co.z < zc:
            t = min(1.0, (zc - v.co.z) / 0.08) ** 0.7
            ang = math.atan2(v.co.y / rb, v.co.x / ra)
            alvo = Vector((ra * math.cos(ang), rb * math.sin(ang), v.co.z))
            atual = Vector((v.co.x, v.co.y, v.co.z))
            v.co = atual.lerp(alvo, t)
    suavizar(bm, 2, 0.4, manter_borda=False)
    # decote: a borda abre um pouco para fora (gola baixa, sem pontas)
    for e in bm.edges:
        if e.is_boundary and all(v.co.z > zo - 0.02 and abs(v.co.x) < 0.12 for v in e.verts):
            for v in e.verts:
                v.co += Vector((v.co.x, v.co.y, 0)).normalized() * 0.002
    ilhas, visto = [], set()
    for v0 in bm.verts:
        if v0 in visto:
            continue
        pilha, ilha = [v0], []
        visto.add(v0)
        while pilha:
            x = pilha.pop()
            ilha.append(x)
            for e in x.link_edges:
                o = e.other_vert(x)
                if o not in visto:
                    visto.add(o)
                    pilha.append(o)
        ilhas.append(ilha)
    ilhas.sort(key=len, reverse=True)
    for ilha in ilhas[1:]:
        bmesh.ops.delete(bm, geom=ilha, context="VERTS")
    bm.to_mesh(cam.data)
    bm.free()
    me2 = cam.data
    cores = np.zeros((len(me2.vertices), 4), np.float32)
    gola_i = set()
    # linha do ombro: z mais alto da camisa em cada faixa de 1 cm de |x|
    topo = [0.0] * 40
    for v in me2.vertices:
        i = min(int(abs(v.co.x) / 0.01), 39)
        topo[i] = max(topo[i], v.co.z)
    for v in me2.vertices:
        c = v.co
        cor = BRANCO
        frente = c.y < 0.0
        # faixa verde ondulada na barra (verde claro em cima, escuro embaixo)
        onda = zq + 0.16 + 0.03 * math.sin(c.x * 11 + 0.8)
        if c.z < onda:
            cor = VERDE if c.z > zq + 0.05 + 0.02 * math.sin(c.x * 9) else VERDE_ESC
        # diagonal amarela no lado esquerdo dele (desce do flanco ate a barra)
        diag = zq + 0.20 - (c.x - 0.06) * 1.6
        if c.x > 0.06 and abs(c.z - diag) < 0.013 and c.z < zq + 0.22:
            cor = AMARELO
        # listras do ombro: verde, verde-azulado e amarelo, da gola ate a manga
        ax = abs(c.x)
        if 0.075 < ax < 0.25 and c.y < 0.03:
            d = topo[min(int(ax / 0.01), len(topo) - 1)] - c.z
            if 0.0 <= d < 0.039:  # da linha do ombro para baixo, na frente
                cor = (VERDE, TEAL, AMARELO)[min(int(d / 0.013), 2)]
        # escudo/inscricao "CEARA" no peito esquerdo (mancha escura pequena)
        if frente and 0.045 < c.x < 0.085 and zo - 0.12 < c.z < zo - 0.095 and c.y < -0.05:
            cor = (0.15, 0.18, 0.28)
        cores[v.index] = (*cor, 1)
    # friso verde na boca da manga
    me2.update()
    bm = bmesh.new()
    bm.from_mesh(me2)
    for e in bm.edges:
        if e.is_boundary:
            for vv in e.verts:
                if abs(vv.co.x) > 0.14 and vv.co.z > zq + 0.1:
                    cores[vv.index, :3] = VERDE
                if vv.co.z > zo + 0.05 and abs(vv.co.x) < 0.1:
                    cores[vv.index, :3] = VERDE
    bm.free()
    return cam, cores


def fazer_calca(ob, base_idx, dom, jt):
    me = ob.data
    zq = jt["joint-pelvis"].z
    za = jt["joint-l-ankle"].z if "joint-l-ankle" in jt else 0.09

    def ok(o, co):
        if o.startswith(("thigh", "calf")) or o in ("pelvis", "Root"):
            return True
        return o.startswith("spine_01") and co.z < zq + 0.10
    cal = objeto_de_faces("Calca", me, faces_por_osso(me, base_idx, dom, ok))
    bm = bmesh.new()
    bm.from_mesh(cal.data)
    suavizar(bm, 8, 0.5, manter_borda=False)
    cortar(bm, Vector((0, 0, zq + 0.02)), Vector((0, 0, 1)))
    cortar(bm, Vector((0, 0, za - 0.015)), Vector((0, 0, -1)))
    def folga(v):
        baixo = max(0.0, min(1.0, (zq - 0.15 - v.co.z) / (zq - 0.15 - za)))
        return 0.012 + 0.032 * baixo  # perna reta: abre ate a barra
    engrossar(bm, folga)
    bm.to_mesh(cal.data)
    bm.free()
    cores = np.zeros((len(cal.data.vertices), 4), np.float32)
    for v in cal.data.vertices:
        t = 0.93 + 0.07 * math.sin(v.co.z * 160 + v.co.x * 40)
        costura = abs(abs(v.co.x) - 0.10) < 0.006 and v.co.y > -0.01  # lateral
        cor = tuple(c * (0.8 if costura else 1.0) * t for c in JEANS)
        if v.co.z < za + 0.03:
            cor = tuple(c * 0.85 for c in JEANS)  # barra dobrada
        cores[v.index] = (*cor, 1)
    return cal, cores


def remesh(ob, voxel):
    mod = ob.modifiers.new("Voxel", "REMESH")
    mod.mode = "VOXEL"
    mod.voxel_size = voxel
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Voxel")


def fazer_tenis(ob, base_idx, dom, jt):
    """Tenis: o pe engrossado vira um volume fechado (voxel), que junta os dedos
    num bico arredondado; sola reta e cano cortado no tornozelo."""
    me = ob.data
    za = jt["joint-l-ankle"].z

    def ok(o, co):
        return co.z < za + 0.05 and (o.startswith(("foot", "ball", "calf")))
    ten = objeto_de_faces("Tenis", me, faces_por_osso(me, base_idx, dom, ok))
    bm = bmesh.new()
    bm.from_mesh(ten.data)
    engrossar(bm, lambda v: 0.016)
    bm.to_mesh(ten.data)
    bm.free()
    sol = ten.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.02
    bpy.context.view_layer.objects.active = ten
    bpy.ops.object.modifier_apply(modifier="Solid")
    remesh(ten, 0.007)
    bm = bmesh.new()
    bm.from_mesh(ten.data)
    suavizar(bm, 6, 0.5, manter_borda=False)
    for v in bm.verts:  # sola reta no chao
        if v.co.z < 0.014:
            v.co.z = max(0.0, v.co.z * 0.3)
    cortar(bm, Vector((0, 0, za + 0.045)), Vector((0, 0, 1)))
    bm.to_mesh(ten.data)
    bm.free()
    cores = np.zeros((len(ten.data.vertices), 4), np.float32)
    for v in ten.data.vertices:
        cor = SOLA if v.co.z < 0.020 else TENIS
        if abs(v.co.x) > 0.105 and 0.03 < v.co.z < 0.055 and -0.05 < v.co.y < 0.04:
            cor = ROXO  # o simbolo roxo do tenis dele
        cores[v.index] = (*cor, 1)
    return ten, cores


def esconder_pele(ob, base_idx, dom, jt):
    """Tira a pele que fica toda coberta pela roupa (evita furar o tecido)."""
    me = ob.data
    zq, zo = jt["joint-pelvis"].z, jt["joint-l-shoulder"].z
    za = jt["joint-l-ankle"].z if "joint-l-ankle" in jt else 0.09

    def coberto(o, co):
        if co.z < za + 0.02:
            return o.startswith(("foot", "ball", "calf"))
        if co.z < zq + 0.05:
            return o.startswith(("thigh", "calf")) or o in ("pelvis", "Root")
        if co.z < zo - 0.02:
            return o.startswith(("spine", "clavicle")) or o in ("pelvis", "Root")
        return False
    faces = set(faces_por_osso(me, base_idx, dom, coberto))
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()


def aplicar_cores(ob, cores):
    me = ob.data
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    attr.data.foreach_set("color", cores.ravel())
    me.color_attributes.active_color = attr
    mat = bpy.data.materials.get("Miguel") or bpy.data.materials.new("Miguel")
    mat.use_nodes = True
    nt = mat.node_tree
    if not any(n.type == "VERTEX_COLOR" for n in nt.nodes):
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Col"
        bsdf = nt.nodes.get("Principled BSDF")
        nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.85
    me.materials.clear()
    me.materials.append(mat)
    for p in me.polygons:
        p.use_smooth = True


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


def riggar(ob, bco, faces_todas, k, z_min, origem):
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
    return rig


def copiar_pesos(dest, corpo, so_osso=None):
    """Pesos de cada vertice da peca = os do vertice da pele mais proximo."""
    from mathutils.kdtree import KDTree
    kd = KDTree(len(corpo.data.vertices))
    for v in corpo.data.vertices:
        kd.insert(v.co, v.index)
    kd.balance()
    nomes = {g.index: g.name for g in corpo.vertex_groups}
    grupos = {n: dest.vertex_groups.new(name=n) for n in MAPA_OSSOS}
    for v in dest.data.vertices:
        if so_osso:
            grupos[so_osso].add([v.index], 1.0, "REPLACE")
            continue
        _, i, _ = kd.find(v.co)
        for g in corpo.data.vertices[i].groups:
            grupos[nomes[g.group]].add([v.index], g.weight, "REPLACE")


def prender(objs, rig):
    for o in objs:
        o.parent = rig
        mod = o.modifiers.new("Armature", "ARMATURE")
        mod.object = rig


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
    fechar_maos(ob, bco, faces_todas, k, z_min, usados)
    cores, _ = pintar_corpo(ob, grupo_face, jt)
    pecas = [fazer_camisa(ob, usados, dom, jt), fazer_calca(ob, usados, dom, jt),
             fazer_tenis(ob, usados, dom, jt), criar_cabelo(ob, olho_z)]
    aplicar_cores(ob, cores)
    rig = riggar(ob, bco, faces_todas, k, z_min, usados)
    for peca, cor in pecas:
        aplicar_cores(peca, cor)
        copiar_pesos(peca, ob, "Head" if peca.name.startswith("Cabelo") else None)
    esconder_pele(ob, usados, dom, jt)
    objs = [ob] + [p for p, _ in pecas]
    prender(objs, rig)
    # uma malha so (o pipeline de sprites e o glb esperam um objeto)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
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

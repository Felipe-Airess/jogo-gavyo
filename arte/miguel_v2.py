"""Miguel v2: revisão do modelo aprovado, gerada numa cópia separada.

  python arte/miguel_v2.py -- [--base] [--blend ARQ] [--glb ARQ] [--fbx ARQ] [--partes JSON]

Reaproveita a cadeia aprovada (miguel_referencia -> miguel_humano, uniforme,
calça e tênis; encaixe do rosto por pontos) e troca só o que o diagnóstico
de 02/11/2026 apontou (arte/revisoes/miguel-v2-20261102/README.md):

  1. orelhas grandes e de abano demais -> tamanho e abertura das fotos;
  2. olhos fechados e íris pequena -> pálpebras abertas e íris maior;
  3. perfil achatado (nariz sem projeção, lábios salientes, queixo recuado);
  4. pescoço comprido;
  5. cabelo "capacete" com aba reta -> volume com franja de cachos na testa,
     cobrindo o alto das orelhas e afinando na nuca, sem degrau na borda;
  6. punhos sempre fechados -> mão semiaberta (jogo de terror, segura objetos);
  7. 61,7 mil triângulos + textura 1024x2048 -> orçamento de celular
     (meta <= 26 mil triângulos, atlas 512x1024), sem objetos extras no GLB.

Mesmo esqueleto de 22 ossos (nomes usados pelo jogo e pelos FBX do Mixamo),
mesma ordem de materiais (0 = cor por vértice, 1 = uniforme), mesma altura.
--base reconstrói o aprovado sem nenhuma mudança (controle de reprodução).
Não grava em arte/miguel_animado.glb nem em arte/texturas/miguel_uniforme.png.
"""
import json
import math
import os
import sys

import bpy  # noqa: I001  (bpy antes de bmesh no bpy 5.x)
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.kdtree import KDTree

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import miguel_humano as base  # noqa: E402
import miguel_referencia as ref  # noqa: E402
import miguel_uniforme as uni  # noqa: E402

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
BASE = "--base" in ARGS
PASTA_TEX = os.path.join(AQUI, "texturas", "v2")
ATLAS_V2 = os.path.join(PASTA_TEX, "miguel_v2_uniforme.png")
ATLAS_LADO = 512  # painel frente/costas de 512 px (atlas 512x1024)

# ------------------------------------------------------------- 1, 3, 4: forma
FORMA_V2 = {
    # orelhas: fotos de frente mostram orelhas médias, pouco afastadas
    "ears/ear-scale": 0.05, "ears/ear-flap": 0.15, "ears/ear-wing": 0.15,
    # pescoço: o aprovado tinha +0,25 de altura; nas fotos é normal
    "neck/measure-neck-height": 0.0,
    # perfil: nariz projeta mais, lábios menos salientes, queixo presente
    "nose/nose-scale-depth": 0.55, "nose/nose-point-up": 0.15,
    "mouth/mouth-lowerlip-volume": 0.55, "mouth/mouth-upperlip-volume": 0.40,
    "mouth/mouth-trans-backward": 0.35,
    "chin/chin-prominent": 0.40,
}

# ------------------------------------------------------------ 6: mãos
DEDOS = {"01": 32, "02": 42, "03": 34, "polegar": 14}

# ------------------------------------------------------------ 7: orçamento
ORCAMENTO = {"Miguel": 13000, "Camisa": 3600, "Calca": 2200, "Tenis": 1800, "Cabelo": 5000}

PARTES = {}  # triângulos por peça, para o relatório


def fechar_maos_v2(ob, bco, faces_todas, k, z_min, origem):
    """Igual a miguel_humano.fechar_maos, com a mão semiaberta."""
    rig_json = json.load(open(os.path.join(base.DADOS, "rig", "rig.game_engine.json")))
    pesos = json.load(open(os.path.join(base.DADOS, "rig", "weights.game_engine.json")))["weights"]
    jt = base.juntas(bco, faces_todas, k, z_min)

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
    grupos = {n: ob.vertex_groups.new(name=n) for n in rig_json}
    inv = {}
    for i, o in enumerate(origem):
        inv.setdefault(int(o), []).append(i)
    for osso, lista in pesos.items():
        for vi, w in lista:
            if vi in inv:
                grupos[osso].add(inv[vi], w, "REPLACE")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
        n = pb.name
        if n.startswith(("index", "middle", "ring", "pinky")):
            falange = n.split("_")[1]
            # mindinho e anelar dobram um pouco mais (mão relaxada natural)
            extra = {"index": 0, "middle": 4, "ring": 8, "pinky": 12}[n.split("_")[0]]
            pb.rotation_euler.x = math.radians(DEDOS.get(falange, 38) + extra)
        elif n.startswith("thumb"):
            pb.rotation_euler.x = math.radians(DEDOS["polegar"])
    mod = ob.modifiers.new("tmp_maos", "ARMATURE")
    mod.object = rig
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="tmp_maos")
    for g in list(ob.vertex_groups):
        ob.vertex_groups.remove(g)
    bpy.data.objects.remove(rig, do_unlink=True)


# ------------------------------------------------------------ 2: olhos
def abrir_olhos(ob, grupo_face):
    """Abre a fenda das pálpebras sem mexer no globo; mantém a pálpebra
    apoiada sobre a esfera do olho (sem fresta)."""
    me = ob.data
    for nome in ("helper-l-eye", "helper-r-eye"):
        c, globo = base.centro_grupo(me, grupo_face, nome)
        raio = sum((me.vertices[i].co - c).length for i in globo) / len(globo)
        for v in me.vertices:
            if v.index in globo:
                continue
            d = v.co - c
            horiz = abs(d.x)
            if d.y > 0.004 or horiz > raio * 1.45 or abs(d.z) > raio * 1.35:
                continue
            # peso máximo na borda da fenda, some fora da órbita
            f = max(0.0, 1 - horiz / (raio * 1.45)) * max(0.0, 1 - abs(d.z) / (raio * 1.35))
            f = f ** 0.8
            if d.z > 0:
                v.co.z += 0.0032 * f
            else:
                v.co.z -= 0.0012 * f
            # não deixar a pálpebra entrar no globo nem descolar dele
            d = v.co - c
            if d.length < raio + 0.0015:
                v.co = c + d.normalized() * (raio + 0.0015)


def pintar_olhos(ob, grupo_face, cores):
    """Íris maior e escura como nas fotos (o aprovado mostrava muito branco)."""
    me = ob.data
    for nome in ("helper-l-eye", "helper-r-eye"):
        c, globo = base.centro_grupo(me, grupo_face, nome)
        for i in globo:
            d = (me.vertices[i].co - c).normalized()
            ang = math.degrees(math.acos(max(-1.0, min(1.0, -d.y))))
            if ang < 13:
                cores[i, :3] = (0.015, 0.011, 0.009)
            elif ang < 31:
                t = (ang - 13) / 18
                cores[i, :3] = np.array(base.IRIS) * (0.35 + 0.30 * t)
            elif ang < 33:
                cores[i, :3] = np.array(base.IRIS) * 0.25
            else:
                cores[i, :3] = (0.80, 0.77, 0.72)
    return cores


# ------------------------------------------------------------ 5: cabelo
def criar_cabelo_v2(ob_corpo, olho_z):  # noqa: C901
    """Volume de cachos que nasce da pele: linha do cabelo recortada (franja
    de cachos sobre a testa), lateral cobrindo o alto da orelha com costeleta,
    nuca descendo e afinando. A espessura cai para 5 mm na borda (sem a aba
    reta do aprovado e sem afundar na pele). Fecha por voxel e recebe relevo
    de cachos maiores."""
    me_c = ob_corpo.data
    rng = np.random.default_rng(7)
    fase = rng.uniform(0, 6.28, 6)

    def onda(t, a, b):
        return 0.6 * math.sin(t * a + fase[0]) + 0.4 * math.sin(t * b + fase[1])

    # Medidas da cabeça deste modelo (não é centrada em y = 0): rosto em
    # y ~ -0,16, nuca em y ~ +0,04; orelha em y -0,066..-0,011, de
    # olho-0,055 a olho+0,015; meia-largura do crânio nas têmporas 0,078.
    cy = -0.06

    def escalpo(co):
        ax = abs(co.x)
        if co.y < -0.105:  # frente: franja com pontas de cacho
            franja = (olho_z + 0.040 + 0.016 * min(1.0, (ax / 0.065) ** 2)
                      + 0.006 * onda(co.x, 95, 160))
            return co.z > franja
        orelha = (ax > 0.060 and -0.074 < co.y < -0.004
                  and co.z < olho_z + 0.022 + 0.004 * onda(co.y, 120, 70))
        if orelha:
            return False
        costeleta = ax > 0.060 and -0.094 < co.y <= -0.074 and co.z > olho_z - 0.028
        lado = ax > 0.050 and co.z > olho_z + 0.006 + 0.004 * onda(co.y, 110, 60)
        nuca = co.y > -0.004 and co.z > (olho_z - 0.092 + 0.030 * min(1.0, max(0.0, ax - 0.025) / 0.04)
                                         + 0.007 * onda(co.x, 120, 75))
        return co.z > olho_z + 0.035 or costeleta or lado or nuca

    # Seleção larga (qualquer vértice dentro), subdivide (faces de ~3 mm) e
    # recorta pelo centro de cada face: a linha do cabelo segue a função,
    # sem os degraus de 1 cm da malha base.
    faces = [p.index for p in me_c.polygons if any(escalpo(me_c.vertices[i].co) for i in p.vertices)]
    ob = base.objeto_de_faces("Cabelo", me_c, faces)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not escalpo(f.calc_center_median())],
                     context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
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
    import heapq
    dist = {v: (0.0 if v.is_boundary else 9.0) for v in bm.verts}
    fila = [(0.0, i, v) for i, v in enumerate(bm.verts) if v.is_boundary]
    heapq.heapify(fila)
    cont = len(fila)
    while fila:
        d0, _, v = heapq.heappop(fila)
        if d0 > dist[v]:
            continue
        for e in v.link_edges:
            o = e.other_vert(v)
            nd = d0 + e.calc_length()
            if nd < dist[o]:
                dist[o] = nd
                cont += 1
                heapq.heappush(fila, (nd, cont, o))
    bm.normal_update()
    z1 = max(v.co.z for v in bm.verts)

    def espessura(v):
        alto = max(0.0, min(1.0, (v.co.z - (olho_z + 0.01)) / (z1 - olho_z - 0.01)))
        frente = min(1.0, max(0.0, -(v.co.y - cy) - 0.02) / 0.06)
        e = 0.012 + 0.030 * alto ** 1.3 + 0.008 * frente * alto
        # têmporas cheias: nas fotos o volume passa da largura do rosto
        tempora = math.exp(-((v.co.z - (olho_z + 0.045)) / 0.03) ** 2) * min(1.0, abs(v.co.x) / 0.07)
        e += 0.010 * tempora
        if v.co.z < olho_z + 0.01:  # nuca e costeleta: cabelo baixo
            e = 0.010
        t = min(1.0, dist[v] / 0.018)
        return 0.005 + (e - 0.005) * (t * t * (3 - 2 * t))
    centro = Vector((0.0, cy, olho_z - 0.01))
    fora = sum(1 for v in bm.verts if v.normal.dot(v.co - centro) > 0)
    sinal = 1.0 if fora >= len(bm.verts) / 2 else -1.0
    print("CABELO_NORMAIS_PARA_FORA", fora, len(bm.verts), sinal)
    desloc = [(v, v.normal.copy() * espessura(v) * sinal) for v in bm.verts]
    for v, d in desloc:
        v.co += d
    if sinal < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    # pontas da franja caem um pouco sobre a testa
    for v in bm.verts:
        if v.co.y < -0.11 and v.co.z < olho_z + 0.075:
            v.co.z -= 0.004 * max(0.0, 1 - dist[v] / 0.02)
    bm.to_mesh(ob.data)
    bm.free()
    sol = ob.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.018
    sol.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Solid")
    base.remesh(ob, 0.0045)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    # borda arredondada: a malha base tem faces de ~1 cm (degraus)
    base.suavizar(bm, 7, 0.5, manter_borda=False)
    bm.normal_update()
    corpo_kd = KDTree(len(me_c.vertices))
    for v in me_c.vertices:
        corpo_kd.insert(v.co, v.index)
    corpo_kd.balance()
    # relevo de cachos só na face externa (longe da pele)
    externos = [v for v in bm.verts if corpo_kd.find(v.co)[2] > 0.004]
    n_sem = min(620, len(externos))
    sementes = [externos[i].co.copy() for i in rng.choice(len(externos), n_sem, replace=False)]
    raios = rng.uniform(0.008, 0.015, len(sementes))
    kd = KDTree(len(sementes))
    for i, sp in enumerate(sementes):
        kd.insert(sp, i)
    kd.balance()
    desloc = []
    for v in bm.verts:
        cacho = 0.0
        for _, i, d in kd.find_range(v.co, 0.02):
            r = raios[i]
            if d < r:
                cacho = max(cacho, math.sqrt(r * r - d * d))
        dpele = corpo_kd.find(v.co)[2]
        desloc.append((v, v.normal * cacho * 0.8 * min(1.0, max(0.0, dpele - 0.002) / 0.008)))
    for v, d in desloc:
        v.co += d
    bm.to_mesh(ob.data)
    bm.free()
    for p in ob.data.polygons:
        p.use_smooth = True
    me = ob.data
    cores = np.zeros((len(me.vertices), 4), np.float32)
    for v in me.vertices:
        perto = min(1.0, kd.find(v.co)[2] / 0.013)
        brilho = (1 - perto) ** 0.8
        t = 0.6 + 1.6 * brilho
        cores[v.index] = (base.CABELO[0] * t * 1.35, base.CABELO[1] * t * 1.05, base.CABELO[2] * t * 0.8, 1)
    return ob, cores


# ------------------------------------------------------------ 7: orçamento
def reduzir(ob, alvo, protege=None):
    """Decimate por colapso com proteção opcional por grupo de vértices
    (o rosto e as mãos mantêm detalhe)."""
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    if tris <= alvo:
        return tris
    if protege:
        g = ob.vertex_groups.new(name="_reduzir")
        for v in ob.data.vertices:
            w = 0.0 if protege(v.co) else 1.0
            g.add([v.index], w, "REPLACE")
    mod = ob.modifiers.new("Reduzir", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.use_collapse_triangulate = True
    mod.use_symmetry = True
    mod.symmetry_axis = "X"
    if protege:
        mod.vertex_group = "_reduzir"
        mod.vertex_group_factor = 1.0
    # o modificador conta faces; procura a razão que bate o alvo
    lo, hi, melhor = 0.02, 1.0, 1.0
    dg = bpy.context.evaluated_depsgraph_get()
    for _ in range(14):
        r = (lo + hi) / 2
        mod.ratio = r
        dg.update()
        me_ev = ob.evaluated_get(dg).data
        n = sum(len(p.vertices) - 2 for p in me_ev.polygons)
        if n > alvo:
            hi = r
        else:
            lo, melhor = r, r
    mod.ratio = melhor
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if protege:
        ob.vertex_groups.remove(ob.vertex_groups["_reduzir"])
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


_prender_original = base.prender


def prender_v2(objs, rig):
    """Antes de juntar as peças: reduz cada uma ao seu orçamento."""
    if "--sem-reduzir" in ARGS:
        for o in objs:
            PARTES[o.name] = sum(len(p.vertices) - 2 for p in o.data.polygons)
        return _prender_original(objs, rig)
    cab = rig.data.bones["Head"].head_local
    for o in objs:
        chave = next((k for k in ORCAMENTO if k in o.name), None)
        if chave is None:
            PARTES[o.name] = sum(len(p.vertices) - 2 for p in o.data.polygons)
            continue
        if chave == "Miguel":
            # Resíduos internos (ilhas de 21, 15 e 18 vértices no aprovado)
            # saem por tamanho antes da redução: a escala mudou alguns mm.
            remover_residuos(o)
            # rosto (frente da cabeça) e mãos preservados; tronco/pernas reduzem
            def protege(co):
                rosto = co.z > cab.z - 0.02 and co.y < cab.y - 0.02
                mao = abs(co.x) > 0.55
                return rosto or mao
            PARTES[o.name] = reduzir(o, ORCAMENTO[chave], protege)
        else:
            if chave == "Calca":
                recolher_cos(o, objs)
            if chave in ("Camisa", "Calca"):
                suavizar_pesos(o)
            PARTES[o.name] = reduzir(o, ORCAMENTO[chave])
    _prender_original(objs, rig)


def suavizar_pesos(o, vezes=6):
    """A roupa copia o peso do vértice de pele mais próximo: na axila e no
    gancho vizinhos pegavam ossos diferentes (tronco x braço, perna esq. x
    dir.) e a aresta esticava até 20x ao abrir braço/perna. Suaviza e
    normaliza os pesos da peça."""
    me = o.data
    nomes = [g.name for g in o.vertex_groups]
    w = np.zeros((len(me.vertices), len(nomes)))
    for v in me.vertices:
        for g in v.groups:
            w[v.index, g.group] = g.weight
    ar = np.array([e.vertices[:] for e in me.edges])
    grau = np.bincount(ar.ravel(), minlength=len(me.vertices)).astype(float)[:, None]
    for _ in range(vezes):
        soma = np.zeros_like(w)
        np.add.at(soma, ar[:, 0], w[ar[:, 1]])
        np.add.at(soma, ar[:, 1], w[ar[:, 0]])
        w = 0.5 * w + 0.5 * soma / np.maximum(grau, 1)
    w[w < 0.01] = 0
    w /= np.maximum(w.sum(1, keepdims=True), 1e-9)
    for gi, nome in enumerate(nomes):
        g = o.vertex_groups[nome]
        for vi in range(len(me.vertices)):
            if w[vi, gi] > 0:
                g.add([vi], float(w[vi, gi]), "REPLACE")
            else:
                g.remove([vi])


def recolher_cos(calca, objs):
    """O cós da calça fica sob a barra da camisa; nas costas as duas
    superfícies ficavam coplanares (z-fighting). Recolhe 4 mm o trecho
    coberto, na direção do eixo do tronco."""
    camisa = next(o for o in objs if "Camisa" in o.name)
    barra = min(v.co.z for v in camisa.data.vertices if abs(v.co.x) < 0.15)
    pontos = [v.co for v in calca.data.vertices if v.co.z > barra + 0.01]
    if not pontos:
        return
    cy = sum(p.y for p in pontos) / len(pontos)
    for v in calca.data.vertices:
        if v.co.z > barra:
            t = min(1.0, (v.co.z - barra) / 0.015)
            d = Vector((v.co.x, v.co.y - cy, 0))
            if d.length > 1e-4:
                v.co -= d.normalized() * 0.004 * t


# ------------------------------------------------------------ montagem
_corpo_ref = None
_pintar_ref = None
_atlas_original = None


def desdobrar_nariz(ob, grupo_face):
    """O encaixe do rosto dobrou a pele na raiz do nariz (triângulos
    sobrepostos: mancha pontilhada também no aprovado). Suaviza só ali."""
    me = ob.data
    oe, ve = base.centro_grupo(me, grupo_face, "helper-l-eye")
    od, vd = base.centro_grupo(me, grupo_face, "helper-r-eye")
    meio = (oe + od) / 2
    olhos = ve | vd
    frente = min(v.co.y for v in me.vertices if abs(v.co.x) < 0.01 and abs(v.co.z - meio.z) < 0.02)
    bm = bmesh.new()
    bm.from_mesh(me)
    alvo = [v for v in bm.verts if v.index not in olhos and abs(v.co.x) < 0.022
            and meio.z - 0.035 < v.co.z < meio.z + 0.02 and v.co.y < frente + 0.03]
    for _ in range(4):
        bmesh.ops.smooth_vert(bm, verts=alvo, factor=0.5, use_axis_x=True,
                              use_axis_y=True, use_axis_z=True)
    bm.to_mesh(me)
    bm.free()
    print("NARIZ_DESDOBRADO", len(alvo))


def construir_corpo_v2():
    resultado = _corpo_ref()
    ob, _, _, grupos, _, _ = resultado
    desdobrar_nariz(ob, grupos)
    abrir_olhos(ob, grupos)
    return resultado


def remover_residuos(ob, maximo=25):
    """Ilhas de pele pequenas e soltas (sobras sob a roupa)."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    visto, remover = set(), []
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
        if len(ilha) <= maximo:
            remover.extend(ilha)
    if remover:
        bmesh.ops.delete(bm, geom=remover, context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    print("RESIDUOS_REMOVIDOS_VERTS", len(remover))


def engrossar_sobrancelhas(ob, grupo_face, cores):
    """Mesmos polígonos medidos na foto (miguel_rosto_pintura.json), com
    borda mais larga e mais escura: nas fotos as sobrancelhas são grossas;
    no aprovado ficavam finas e apagadas."""
    from felipe_humano import cobertura
    with open(ref.PINTURA) as arq:
        pt = json.load(arq)
    me = ob.data
    oe, ve = base.centro_grupo(me, grupo_face, "helper-l-eye")
    od, vd = base.centro_grupo(me, grupo_face, "helper-r-eye")
    meio, olhos = (oe + od) / 2, ve | vd
    escuro = np.array(base.SOBRANCELHA) * 0.7
    for v in me.vertices:
        if v.index in olhos or v.normal.y > -0.15 or v.co.y > meio.y + 0.02:
            continue
        x, z = v.co.x - meio.x, v.co.z - meio.z
        if not 0.0 < z < 0.05:
            continue
        sob = max(cobertura(x, z, pt["sobrancelha_d"], 0.0032),
                  cobertura(x, z, pt["sobrancelha_e"], 0.0032))
        if sob:
            cores[v.index, :3] = cores[v.index, :3] * (1 - sob) + escuro * sob
    return cores


def pintar_corpo_v2(ob, grupo_face, jt):
    cores, x = _pintar_ref(ob, grupo_face, jt)
    cores = engrossar_sobrancelhas(ob, grupo_face, cores)
    return pintar_olhos(ob, grupo_face, cores), x


def gerar_atlas_v2(*a, **kw):
    _atlas_original(*a, **kw)
    from PIL import Image
    im = Image.open(uni.ATLAS).convert("RGB")
    # Branco do tecido: no render saía 239 contra 213 na foto (mesma
    # exposição em que a pele bate). Era a camisa "estourada" no escuro.
    a = np.asarray(im, dtype=np.float32)
    claro = np.clip((a.mean(2, keepdims=True) - 170) / 40, 0, 1)
    a = a * (1 - 0.11 * claro)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    im.resize((ATLAS_LADO, ATLAS_LADO * 2), Image.Resampling.LANCZOS).save(uni.ATLAS)


def chao(ob):
    """Ponto mais baixo da malha em repouso (deve ser ~0: sola no chão)."""
    return min(v.co.z for v in ob.data.vertices)


def finalizar(ob):
    """Um só atributo de cor ("Col", o que o Godot lê como COLOR) e sem
    faces degeneradas deixadas pela redução."""
    me = ob.data
    for a in [a for a in me.color_attributes if a.name != "Col"]:
        me.color_attributes.remove(a)
    me.color_attributes.active_color = me.color_attributes["Col"]
    me.color_attributes.render_color_index = me.color_attributes.active_color_index
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges[:], dist=1e-5)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    bm.to_mesh(me)
    bm.free()
    me.update()


def construir_tudo():
    global _corpo_ref, _pintar_ref, _atlas_original
    os.makedirs(PASTA_TEX, exist_ok=True)
    # Texturas sempre em arte/texturas/v2 (o atlas aprovado não é tocado).
    uni.ATLAS = type(uni.ATLAS)(ATLAS_V2)
    if not BASE:
        base.FORMA.update(FORMA_V2)
        base.BRANCO = (0.69, 0.70, 0.68)  # gola/carcela: ~216 sRGB, como a foto
        ref.configurar_base()
        _corpo_ref, _pintar_ref = base.construir_corpo, base.pintar_corpo
        base.construir_corpo = construir_corpo_v2
        base.pintar_corpo = pintar_corpo_v2
        base.fechar_maos = fechar_maos_v2
        base.criar_cabelo = criar_cabelo_v2
        base.prender = prender_v2
        if _atlas_original is None:
            _atlas_original = uni.gerar_atlas
        uni.gerar_atlas = gerar_atlas_v2
        # miguel_referencia.construir_tudo chama configurar_base de novo:
        # impede que desfaça as trocas acima.
        ref.configurar_base = lambda: None
    ob, rig = ref.construir_tudo()
    ob.name = "Miguel"
    rig.name = "MiguelRig"
    if not BASE:
        finalizar(ob)
    zmin = chao(ob)
    print("PONTO_MAIS_BAIXO_M", round(zmin, 4))
    print("PARTES_TRIS", json.dumps(PARTES))
    return ob, rig


def main():
    ob, rig = construir_tudo()
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    print("MIGUEL_V2 tris=%d verts=%d ossos=%d materiais=%s" % (
        tris, len(ob.data.vertices), len(rig.data.bones), [m.name for m in ob.data.materials]))
    if "--partes" in ARGS:
        with open(ARGS[ARGS.index("--partes") + 1], "w") as f:
            json.dump({"partes": PARTES, "total": tris}, f, indent=1)
    if "--blend" in ARGS:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(ARGS[ARGS.index("--blend") + 1]))
    from felipe_humano import exportar
    exportar(ARGS)


if __name__ == "__main__":
    main()

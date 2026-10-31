"""Felipe ("Bungas") em alta definicao, no mesmo pipeline do Miguel.

Reaproveita arte/miguel_humano.py (malha base, alvos e rig do MakeHuman, CC0):
aqui ficam so os parametros do Felipe e as pecas que mudam (camiseta folgada
com estampa, short, pes descalcos, cabelo mais volumoso).

Referencias: arte/referencias/felipe/ (1,72 m, 72 kg, luta descalco).

Uso (Blender 3.6+ ou o modulo bpy):
  python arte/felipe_humano.py -- --render DIR [--blend ARQ]
"""
import gzip
import math
import os
import sys

import bpy  # antes do bmesh (no modulo bpy o bmesh so existe depois)
import bmesh
import numpy as np
from mathutils import Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import miguel_humano as base  # noqa: E402
from miguel_humano import (cortar, engrossar, objeto_de_faces, remesh,  # noqa: E402
                           suavizar)

REF = os.path.join(AQUI, "referencias", "felipe", "fotos_originais")

# ---------------------------------------------------------------- medidas
# 1,72 m, 72 kg: mais largo e mais forte que o Miguel (1,76 m, 67 kg).
ALTURA = 1.72
MACRO = {"gender": 1.0, "age": 0.42, "muscle": 0.62, "weight": 0.55,
         "african": 0.20, "asian": 0.10, "caucasian": 0.70}
FORMA = {
    # rosto: so o basico aqui; o encaixe nas fotos vem depois (pontos)
    "head/head-oval": 0.30, "head/head-scale-horiz": 0.05,
    "eyebrows/eyebrows-trans-down": 0.15,
    "nose/nose-scale-vert": 0.25,
    "chin/chin-height": 0.10,
    # corpo: ombro largo, tronco cheio (sem cintura de modelo)
    "torso/measure-shoulder-dist": 0.30, "torso/torso-vshape": 0.15,
    "buttocks/buttocks-volume": -0.70, "torso/measure-hips-circ": -0.30,
    "neck/measure-neck-circ": 0.15,
}
PELE = (0.66, 0.46, 0.34)       # morena clara (fotos, corrigida da luz fria)
PRETO = (0.035, 0.035, 0.04)    # camiseta e short
CABELO = (0.040, 0.032, 0.030)


ALVO_ROSTO = os.path.join(AQUI, "felipe_rosto.target.gz")  # gerado por felipe_rosto.py
_forma_base = base.aplicar_forma


def ler_alvo_rosto():
    idx, d = [], []
    with gzip.open(ALVO_ROSTO, "rt") as f:
        for linha in f:
            p = linha.split()
            if len(p) == 4 and not linha.startswith("#"):
                idx.append(int(p[0]))
                d.append([float(x) for x in p[1:]])
    return np.array(idx, np.int64), np.array(d, np.float64)


def aplicar_forma(co):
    """FORMA (alvos do MakeHuman) e depois o rosto encaixado nas fotos."""
    _forma_base(co)
    if os.path.exists(ALVO_ROSTO):
        idx, d = ler_alvo_rosto()
        np.add.at(co, idx, d)


def configurar_base():
    """Os modulos do Miguel leem estes globais; troca para o Felipe."""
    base.ALTURA, base.MACRO, base.FORMA = ALTURA, MACRO, FORMA
    base.PELE, base.CABELO = PELE, CABELO
    base.aplicar_forma = aplicar_forma


# ------------------------------------------------------------ rosto
PINTURA = os.path.join(AQUI, "felipe_rosto_pintura.json")  # gerado por felipe_rosto.py
SOBRANCELHA = (0.035, 0.025, 0.022)
LABIO = (0.66, 0.40, 0.36)
PELO = (0.07, 0.05, 0.04)  # cavanhaque/bigode


def dentro(px, pz, poli):
    """Ponto dentro do poligono (raio horizontal)."""
    n, ok = len(poli), False
    for i in range(n):
        x1, z1 = poli[i]
        x2, z2 = poli[(i + 1) % n]
        if (z1 > pz) != (z2 > pz) and px < x1 + (pz - z1) * (x2 - x1) / (z2 - z1):
            ok = not ok
    return ok


def cobertura(x, z, poli, r=0.0018):
    """Fracao de uma vizinhanca (raio r) dentro do poligono: borda suave mesmo
    com poucos vertices na pele."""
    pts = [(0, 0), (r, 0), (-r, 0), (0, r), (0, -r), (r * .7, r * .7), (-r * .7, r * .7),
           (r * .7, -r * .7), (-r * .7, -r * .7)]
    return sum(dentro(x + a, z + b, poli) for a, b in pts) / len(pts)


def pintar_rosto(ob, grupo_face):
    """Pele, olhos (como no Miguel) e, pelos poligonos tirados da foto de frente,
    sobrancelha grossa, labios, cavanhaque ralo no queixo e bigode bem fraco."""
    import json
    me = ob.data
    me.update()
    cores = np.tile(np.array([*PELE, 1.0], np.float32), (len(me.vertices), 1))
    olho_e, vs_e = base.centro_grupo(me, grupo_face, "helper-l-eye")
    olho_d, vs_d = base.centro_grupo(me, grupo_face, "helper-r-eye")
    meio = (olho_e + olho_d) / 2
    pt = json.load(open(PINTURA)) if os.path.exists(PINTURA) else None
    if pt:  # sobrancelha dele e mais grossa que o contorno do detector
        for k in ("sobrancelha_d", "sobrancelha_e"):
            p = np.array(pt[k])
            c = p.mean(0)
            pt[k] = (c + (p - c) * [1.04, 1.35]).tolist()
    pele, pelo = np.array(PELE), np.array(PELO)
    for v in me.vertices:
        if pt is None or v.index in vs_e or v.index in vs_d or v.normal.y > -0.15:
            continue
        x, z = v.co.x - meio.x, v.co.z - meio.z
        if z < -0.16 or z > 0.06 or v.co.y > meio.y + 0.02:
            continue
        sob = max(cobertura(x, z, pt["sobrancelha_d"]), cobertura(x, z, pt["sobrancelha_e"]))
        lab = cobertura(x, z, pt["labios"], 0.0012)
        if sob > 0:
            cores[v.index, :3] = pele * (1 - sob) + np.array(SOBRANCELHA) * sob
        elif lab > 0:
            cores[v.index, :3] = pele * (1 - lab) + np.array(LABIO) * lab
        else:
            # cavanhaque: faixa estreita do labio de baixo ate a ponta do queixo
            # (ralo logo abaixo do labio, cheio e mais largo na ponta do queixo)
            zl, zq = pt["labio_baixo"][1] - 0.004, pt["queixo"][1] - 0.008
            if zq < z < zl:
                t = (zl - z) / (zl - zq)
                larg = 0.003 + 0.009 * t ** 1.5
                if abs(x) < larg:
                    f = (0.25 + 0.6 * t) * (1 - (abs(x) / larg) ** 2)
                    cores[v.index, :3] = pele * (1 - f) + pelo * f
            # bigode ralo entre o nariz e o labio
            zs, zc = pt["subnasal"][1], pt["labio_cima"][1]
            if zc < z < zs - 0.002 and abs(x) < abs(pt["canto_boca"][0]) * 0.9:
                cores[v.index, :3] = pele * 0.78 + pelo * 0.22
    for centro in (olho_e, olho_d):  # linha dos cilios em cima do olho
        for v in me.vertices:
            d = v.co - centro
            if v.index in vs_e or v.index in vs_d or v.co.y > centro.y:
                continue
            if math.hypot(d.x, d.y) < 0.014 and 0.0045 < d.z < 0.0072:
                cores[v.index, :3] = SOBRANCELHA
    for vs, centro in ((vs_e, olho_e), (vs_d, olho_d)):
        for i in vs:  # pupila e iris pelo angulo a partir da frente; o resto branco
            d = (me.vertices[i].co - centro).normalized()
            ang = math.degrees(math.acos(max(-1.0, min(1.0, -d.y))))
            cores[i, :3] = (0.02, 0.015, 0.012) if ang < 12 else base.IRIS if ang < 27 else base.ESCLERA
    return cores


# ------------------------------------------------------------- estampa
def _recorte(nome, caixa, girar=0):
    from PIL import Image
    im = Image.open(os.path.join(REF, nome)).convert("RGB")
    if girar:
        im = im.rotate(girar, expand=True)
    return np.asarray(im.crop(caixa), np.float32) / 255.0


def estampas():
    """(imagem, largura m, altura m, topo abaixo da gola m) da frente e das costas,
    recortadas das fotos da camiseta esticada no chao."""
    # 36572: camiseta deitada com a gola para a esquerda -> girar 90 graus horario
    frente = _recorte("36572.jpg", (320, 410, 770, 970), girar=-90)
    costas = _recorte("36573.jpg", (370, 435, 790, 690))
    return {"frente": (frente, 0.31, 0.39, 0.085), "costas": (costas, 0.29, 0.17, 0.10)}


def cor_estampa(img, u, v):
    """u, v em 0..1 (v=0 em cima). Fundo preto da camiseta continua preto."""
    h, w, _ = img.shape
    c = img[min(h - 1, max(0, int(v * h))), min(w - 1, max(0, int(u * w)))]
    if c.max() < 0.22:  # tecido preto (com dobras e sombra)
        return None
    return tuple(float(x) ** 2.2 for x in c)  # foto (sRGB) -> linear


# ----------------------------------------------------------------- roupas
def fazer_camiseta(ob, base_idx, dom, jt):
    """Camiseta folgada: manga ate o meio do braco, barra na altura da virilha."""
    me = ob.data
    zq, zo = jt["joint-pelvis"].z, jt["joint-l-shoulder"].z
    zp = jt["joint-neck"].z

    def ok(o, co):
        if o.startswith(("head", "neck", "hand", "lowerarm", "calf", "foot", "ball",
                         "thumb", "index", "middle", "ring", "pinky")):
            return False
        return co.z > zq - 0.20
    cam = objeto_de_faces("Camiseta", me, base.faces_por_osso(me, base_idx, dom, ok))
    bm = bmesh.new()
    bm.from_mesh(cam.data)
    suavizar(bm, 8, 0.5, manter_borda=False)
    cortar(bm, Vector((0, 0, zq - 0.075)), Vector((0, 0, -1)))
    for lado in ("l", "r"):
        a, b = jt["joint-%s-shoulder" % lado], jt["joint-%s-elbow" % lado]
        eixo = (b - a).normalized()
        braco = [f for f in bm.faces if (f.calc_center_median() - a).dot(eixo) > 0.03
                 and f.calc_center_median().z > zq + 0.22
                 and (f.calc_center_median().x > 0.12 if lado == "l" else f.calc_center_median().x < -0.12)]
        geom = list({v for f in braco for v in f.verts}) + list({e for f in braco for e in f.edges}) + braco
        bmesh.ops.bisect_plane(bm, geom=geom, dist=1e-5, plane_co=a + (b - a) * 0.62,
                               plane_no=eixo, clear_outer=True)
    cortar(bm, Vector((0, -0.04, zp - 0.010)), Vector((0, -0.40, 1)).normalized())

    def folga(v):  # manga larga, tronco folgado
        x = abs(v.co.x)
        return 0.018 + 0.016 * max(0.0, min(1.0, (x - 0.15) / 0.08))
    engrossar(bm, folga)
    # do peito para baixo a camiseta cai reta (tubo), sem marcar cintura nem bumbum
    zc = zo - 0.16
    faixa = [v.co for v in bm.verts if abs(v.co.z - zc) < 0.012 and abs(v.co.x) < 0.2]
    ra = max(abs(c.x) for c in faixa) * 1.02
    cy = (max(c.y for c in faixa) + min(c.y for c in faixa)) / 2
    rf = (cy - min(c.y for c in faixa)) * 1.05
    rt = (max(c.y for c in faixa) - cy) * 1.02
    for v in bm.verts:
        if v.co.z < zc and abs(v.co.x) < ra * 1.3:
            t = min(1.0, (zc - v.co.z) / 0.10) ** 0.7
            ry = rt if v.co.y > cy else rf
            ang = math.atan2((v.co.y - cy) / ry, v.co.x / ra)
            alvo = Vector((ra * math.cos(ang), cy + ry * math.sin(ang), v.co.z))
            v.co = v.co.lerp(alvo, t)
    suavizar(bm, 2, 0.4, manter_borda=False)
    _so_maior_ilha(bm)
    bmesh.ops.holes_fill(bm, edges=[e for e in bm.edges if e.is_boundary], sides=30)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    for _ in range(2):  # malha fina para a estampa sair legivel na cor por vertice
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=1, use_grid_fill=True)
    bm.to_mesh(cam.data)
    bm.free()

    me2 = cam.data
    cores = np.tile(np.array([*PRETO, 1.0], np.float32), (len(me2.vertices), 1))
    est = estampas()
    zg = zp - 0.02  # altura da gola no peito
    for v in me2.vertices:
        c = v.co
        lado = "frente" if c.y < 0 else "costas"
        img, larg, alt, topo = est[lado]
        if abs(c.x) > 0.20:
            continue
        x = c.x if lado == "frente" else -c.x
        u = 0.5 + x / larg
        vv = (zg - topo - c.z) / alt
        if 0 <= u <= 1 and 0 <= vv <= 1:
            cor = cor_estampa(img, u, vv)
            if cor:
                cores[v.index, :3] = cor
    return cam, cores


def _so_maior_ilha(bm):
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


def fazer_short(ob, base_idx, dom, jt):
    """Short preto folgado, barra um pouco acima do joelho."""
    me = ob.data
    zq = jt["joint-pelvis"].z
    zj = jt["joint-l-knee"].z
    zb = zj + 0.05

    def ok(o, co):
        if o.startswith("thigh") or o in ("pelvis", "Root"):
            return True
        if o.startswith("calf"):
            return co.z > zb - 0.05
        return o.startswith("spine_01") and co.z < zq + 0.10
    sh = objeto_de_faces("Short", me, base.faces_por_osso(me, base_idx, dom, ok))
    bm = bmesh.new()
    bm.from_mesh(sh.data)
    suavizar(bm, 8, 0.5, manter_borda=False)
    cortar(bm, Vector((0, 0, zq + 0.05)), Vector((0, 0, 1)))
    cortar(bm, Vector((0, 0, zb)), Vector((0, 0, -1)))

    def folga(v):  # abre para a barra (perna larga)
        t = max(0.0, min(1.0, (zq - 0.05 - v.co.z) / (zq - 0.05 - zb)))
        return 0.014 + 0.026 * t
    engrossar(bm, folga)
    bm.to_mesh(sh.data)
    bm.free()
    cores = np.zeros((len(sh.data.vertices), 4), np.float32)
    for v in sh.data.vertices:
        t = 0.92 + 0.08 * math.sin(v.co.z * 140 + v.co.x * 50)
        cores[v.index] = (*(c * t for c in PRETO), 1)
    return sh, cores


def esconder_pele(ob, base_idx, dom, jt):
    """Tira a pele coberta pela roupa; pernas abaixo do short e pes ficam."""
    me = ob.data
    zq, zo = jt["joint-pelvis"].z, jt["joint-l-shoulder"].z
    zb = jt["joint-l-knee"].z + 0.08

    def coberto(o, co):
        if co.z < zb:
            return False
        if co.z < zq + 0.05:
            return o.startswith("thigh") or o in ("pelvis", "Root")
        if co.z < zo - 0.03:
            return o.startswith(("spine", "clavicle")) or o in ("pelvis", "Root")
        return False
    faces = set(base.faces_por_osso(me, base_idx, dom, coberto))
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(me)
    bm.free()


# ---------------------------------------------------------------- cabelo
def criar_cabelo(ob_corpo, olho):
    """Miolo do cabelo tirado das fotos (arte/felipe_cabelo.py), cor escura com
    leve variacao (o brilho dos cachos vem das cards)."""
    import felipe_cabelo
    ob = felipe_cabelo.criar_nucleo(ob_corpo, olho)
    me = ob.data
    cores = np.zeros((len(me.vertices), 4), np.float32)
    for v in me.vertices:
        t = 0.85 + 0.25 * math.sin(v.co.x * 260) * math.sin(v.co.z * 230 + v.co.y * 190)
        cores[v.index] = (CABELO[0] * t, CABELO[1] * t, CABELO[2] * t, 1)
    return ob, cores


# ------------------------------------------------------------- tudo junto
def construir_tudo():
    configurar_base()
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    ob, bco, novo, grupo_face, k, z_min = base.construir_corpo()
    ob.name = ob.data.name = "Felipe"
    _, _, faces_todas = base.ler_obj()
    jt = base.juntas(bco, faces_todas, k, z_min)
    usados = np.array(sorted(novo, key=novo.get))
    dom = base.osso_dominante()
    olho_e = base.centro_grupo(ob.data, grupo_face, "helper-l-eye")[0]
    olho_d = base.centro_grupo(ob.data, grupo_face, "helper-r-eye")[0]
    olho = (olho_e + olho_d) / 2
    olho_z = olho.z
    base.fechar_maos(ob, bco, faces_todas, k, z_min, usados)
    cores = pintar_rosto(ob, grupo_face)
    pecas = [fazer_camiseta(ob, usados, dom, jt), fazer_short(ob, usados, dom, jt),
             criar_cabelo(ob, olho)]
    base.aplicar_cores(ob, cores)
    rig = base.riggar(ob, bco, faces_todas, k, z_min, usados)
    rig.name = rig.data.name = "FelipeRig"
    for peca, cor in pecas:
        base.aplicar_cores(peca, cor)
        base.copiar_pesos(peca, ob, "Head" if peca.name.startswith("Cabelo") else None)
    esconder_pele(ob, usados, dom, jt)
    objs = [ob] + [p for p, _ in pecas]
    base.prender(objs, rig)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.join()
    ob.data.color_attributes.active_color = ob.data.color_attributes["Col"]
    ob["olho_z"] = olho_z
    return ob, rig


def renderizar(pasta, ob, olho_z):
    """Frente, lado, costas (corpo) e rosto de frente, 3/4 e perfil; fundo
    transparente para a comparacao com as fotos (arte/felipe_comparar.py)."""
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    cena.render.film_transparent = True
    sh = cena.display.shading
    sh.light, sh.color_type = "STUDIO", "VERTEX"
    sh.show_specular_highlight = False
    cena.view_settings.view_transform = "Standard"
    cam_d = bpy.data.cameras.new("Cam")
    cam_d.type = "ORTHO"
    cam = bpy.data.objects.new("Cam", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    zr = olho_z - 0.01
    for nome, (ang, esc, z, res) in {
        "frente": (0, 2.0, 0.92, (600, 1000)), "lado": (90, 2.0, 0.92, (600, 1000)),
        "costas": (180, 2.0, 0.92, (600, 1000)),
        "rosto": (0, 0.40, zr, (800, 800)), "rosto_34": (35, 0.40, zr, (800, 800)),
        "rosto_lado": (90, 0.40, zr, (800, 800)),
    }.items():
        cena.render.resolution_x, cena.render.resolution_y = res
        cam_d.ortho_scale = esc
        a = math.radians(ang)  # gira a camera em volta do boneco (0 = de frente)
        cam.location = (5 * math.sin(a), -5 * math.cos(a), z)
        cam.rotation_euler = (math.radians(90), 0, a)
        cena.render.filepath = os.path.join(pasta, nome + ".png")
        bpy.ops.render.render(write_still=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ob, rig = construir_tudo()
    print("Felipe HD: %d vertices, %d faces, %d ossos" % (
        len(ob.data.vertices), len(ob.data.polygons), len(rig.data.bones)))
    if "--render" in args:
        renderizar(os.path.abspath(args[args.index("--render") + 1]), ob, ob["olho_z"])
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))


if __name__ == "__main__":
    main()

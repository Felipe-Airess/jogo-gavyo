"""Felipe ("Bungas") em alta definicao, no mesmo pipeline do Miguel.

Reaproveita arte/miguel_humano.py (malha base, alvos e rig do MakeHuman, CC0):
aqui ficam so os parametros do Felipe e as pecas que mudam (camiseta folgada
com estampa, short, pes descalcos, cabelo mais volumoso).

Referencias: arte/referencias/felipe/ (1,72 m, 72 kg, luta descalco).

Uso (Blender 3.6+ ou o modulo bpy):
  python arte/felipe_humano.py -- --render DIR [--blend ARQ]
"""
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


def configurar_base():
    """Os modulos do Miguel leem estes globais; troca para o Felipe."""
    base.ALTURA, base.MACRO, base.FORMA = ALTURA, MACRO, FORMA
    base.PELE, base.CABELO = PELE, CABELO


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
def criar_cabelo(ob_corpo, olho_z):
    """Cabelo cacheado volumoso: mesma ideia do Miguel (um volume so com cachos
    esculpidos), mais alto, cheio dos lados e atras, franja na testa."""
    me_c = ob_corpo.data

    def escalpo(co):
        orelha = abs(co.x) > 0.062 and olho_z - 0.060 < co.z < olho_z + 0.010 and -0.03 < co.y < 0.04
        if orelha:
            return False
        if co.z > olho_z + 0.045:
            return True
        if co.z > olho_z - 0.010 and co.y > -0.055:
            return True
        return co.y > 0.015 and co.z > olho_z - 0.095

    faces = [p.index for p in me_c.polygons if all(escalpo(me_c.vertices[i].co) for i in p.vertices)]
    ob = objeto_de_faces("Cabelo", me_c, faces)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.normal_update()
    z1 = max(v.co.z for v in bm.verts)

    def volume(v):
        alto = max(0.0, (v.co.z - olho_z) / (z1 - olho_z))
        tras = min(1.0, max(0.0, v.co.y + 0.02) / 0.08)
        return 0.020 + 0.034 * alto ** 1.1 + 0.016 * tras
    engrossar(bm, volume)
    for v in bm.verts:  # franja cai na testa, ate perto da sobrancelha
        if v.co.y < -0.045 and v.co.z < olho_z + 0.11:
            v.co.z -= 0.020 * max(0.0, 1 - abs(v.co.x) / 0.07)
            v.co.y -= 0.006
    bm.to_mesh(ob.data)
    bm.free()
    sol = ob.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.04
    sol.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Solid")
    remesh(ob, 0.006)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    suavizar(bm, 3, 0.5, manter_borda=False)
    bm.normal_update()
    rng = np.random.default_rng(23)
    externos = [v for v in bm.verts if v.co.z > olho_z - 0.03 or v.co.y > 0.03]
    sementes = [externos[i].co.copy() for i in rng.choice(len(externos), 900, replace=False)]
    raios = rng.uniform(0.008, 0.014, len(sementes))  # cachos fechados
    from mathutils.kdtree import KDTree
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
        desloc.append((v, v.normal * cacho))
    for v, d in desloc:
        v.co += d
    bm.to_mesh(ob.data)
    bm.free()
    me = ob.data
    cores = np.zeros((len(me.vertices), 4), np.float32)
    kd2 = KDTree(len(sementes))
    for i, sp in enumerate(sementes):
        kd2.insert(sp, i)
    kd2.balance()
    for v in me.vertices:
        _, i, d = kd2.find(v.co)
        brilho = max(0.0, 1 - d / raios[i]) ** 0.7
        t = 0.7 + 1.0 * brilho
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
    olho_z = base.centro_grupo(ob.data, grupo_face, "helper-l-eye")[0].z
    base.fechar_maos(ob, bco, faces_todas, k, z_min, usados)
    cores, _ = base.pintar_corpo(ob, grupo_face, jt)
    pecas = [fazer_camiseta(ob, usados, dom, jt), fazer_short(ob, usados, dom, jt),
             criar_cabelo(ob, olho_z)]
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

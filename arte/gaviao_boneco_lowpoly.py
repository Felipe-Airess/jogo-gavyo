"""Boneco low poly do Miguel (estilo PS1 / Fears to Fathom).

Gera uma malha continua em T-pose (Skin modifier aplicado), sem textura,
com cores por material. Compativel com Blender 3.6 LTS e versoes mais novas.

Uso:
  blender -b -P arte/gaviao_boneco_lowpoly.py                 # so gera o boneco
  blender -b -P arte/gaviao_boneco_lowpoly.py -- --render DIR # gera e renderiza
  blender -b -P arte/gaviao_boneco_lowpoly.py -- --blend ARQ  # salva .blend

Referencia: 1,76 m, 67 kg, magro, ombros largos, rosto largo nas bochechas,
orelhas marcadas, cabelo cacheado volumoso em cima e na franja.
"""
import math
import os
import sys

import bpy
import bmesh

ALTURA = 1.76

# ------------------------------------------------------------------ partes
# A malha nasce de metaballs (capsulas e elipsoides que se fundem numa
# superficie unica), e convertida em malha e decimada ate o estilo PS1.
# x = lado (+x esquerda do boneco), y = profundidade (frente = -y), z = altura.
CAPSULAS = []    # (ponto a, ponto b, raio, cor)
ELIPSOIDES = []  # (centro, (rx, ry, rz), cor)


def cap(a, b, r, cor, espelho=False):
    CAPSULAS.append((a, b, r, cor))
    if espelho:
        CAPSULAS.append(((-a[0], a[1], a[2]), (-b[0], b[1], b[2]), r, cor))


def eli(c, raios, cor, espelho=False):
    ELIPSOIDES.append((c, raios, cor))
    if espelho:
        ELIPSOIDES.append(((-c[0], c[1], c[2]), raios, cor))


# pernas: jeans reto, finas; tenis brancos
cap((0.095, 0.0, 0.10), (0.093, 0.0, 0.50), 0.050, "jeans", True)
cap((0.093, 0.0, 0.50), (0.090, 0.0, 0.86), 0.064, "jeans", True)
eli((0.100, -0.045, 0.045), (0.050, 0.130, 0.050), "tenis", True)
# quadril e cintura (magro)
eli((0.0, 0.0, 0.92), (0.155, 0.095, 0.090), "jeans")
eli((0.0, 0.0, 1.03), (0.145, 0.092, 0.095), "verde")
# tronco: afunila da cintura para os ombros largos
eli((0.0, 0.0, 1.18), (0.150, 0.095, 0.110), "camisa")
eli((0.0, -0.005, 1.31), (0.170, 0.100, 0.100), "camisa")
cap((-0.165, 0.0, 1.405), (0.165, 0.0, 1.405), 0.065, "camisa")
# bracos em T: manga curta, antebraco fino, mao achatada
cap((0.18, 0.0, 1.405), (0.33, 0.0, 1.405), 0.054, "camisa", True)
cap((0.33, 0.0, 1.405), (0.48, 0.0, 1.405), 0.040, "pele", True)
cap((0.48, 0.0, 1.405), (0.71, 0.0, 1.405), 0.033, "pele", True)
eli((0.79, 0.0, 1.400), (0.085, 0.020, 0.045), "pele", True)
# pescoco
cap((0.0, 0.010, 1.42), (0.0, 0.005, 1.55), 0.056, "pele")
# cabeca: queixo pequeno, bochechas largas, cranio
eli((0.0, -0.005, 1.640), (0.088, 0.098, 0.105), "pele")
eli((0.0, -0.030, 1.605), (0.095, 0.065, 0.050), "pele")        # bochechas
eli((0.0, -0.040, 1.555), (0.045, 0.040, 0.028), "pele")        # queixo
eli((0.0, -0.098, 1.620), (0.020, 0.024, 0.030), "pele")        # nariz
eli((0.0, -0.085, 1.578), (0.034, 0.020, 0.012), "labio")       # boca
eli((0.098, 0.012, 1.632), (0.016, 0.022, 0.036), "pele", True)  # orelhas
# cabelo cacheado: volume em cima, lados curtos, franja na testa
for c, r in [((0.0, 0.0, 1.735), (0.088, 0.100, 0.055)),
             ((0.0, 0.040, 1.700), (0.088, 0.085, 0.060)),
             ((0.0, 0.075, 1.665), (0.072, 0.040, 0.045))]:
    eli(c, r, "cabelo")
for x, y, z, r in [(0.000, -0.010, 1.785, 0.045), (0.055, 0.020, 1.775, 0.040),
                   (-0.055, 0.020, 1.775, 0.040), (0.030, -0.060, 1.765, 0.038),
                   (-0.030, -0.060, 1.765, 0.038), (0.000, 0.060, 1.765, 0.040),
                   (0.075, -0.020, 1.745, 0.034), (-0.075, -0.020, 1.745, 0.034),
                   (0.070, 0.060, 1.735, 0.034), (-0.070, 0.060, 1.735, 0.034),
                   (0.000, -0.088, 1.715, 0.028), (0.045, -0.085, 1.712, 0.026),
                   (-0.045, -0.085, 1.712, 0.026), (0.072, -0.065, 1.700, 0.022),
                   (-0.072, -0.065, 1.700, 0.022)]:
    eli((x, y, z), (r, r, r), "cabelo")

# desce cabeca e cabelo: pescoco curto como nas fotos
DZ_CABECA = -0.035
CAPSULAS[:] = [(a, (b[0], b[1], b[2] + DZ_CABECA) if b[2] > 1.5 else b, r, c)
               for a, b, r, c in CAPSULAS]
ELIPSOIDES[:] = [((c[0], c[1], c[2] + DZ_CABECA) if c[2] > 1.5 else c, r, k)
                 for c, r, k in ELIPSOIDES]

# ------------------------------------------------------------------ cores
CORES = {
    "pele": (0.55, 0.33, 0.22),
    "labio": (0.62, 0.32, 0.27),
    "cabelo": (0.025, 0.02, 0.018),
    "camisa": (0.88, 0.88, 0.86),
    "verde": (0.05, 0.38, 0.18),
    "jeans": (0.36, 0.52, 0.72),
    "tenis": (0.92, 0.92, 0.92),
}

ALVO_FACES = 1400  # ~2800 triangulos


def _dist_capsula(p, a, b, r):
    ab = [b[k] - a[k] for k in range(3)]
    ap = [p[k] - a[k] for k in range(3)]
    t = sum(ab[k] * ap[k] for k in range(3)) / max(sum(v * v for v in ab), 1e-9)
    t = min(1.0, max(0.0, t))
    d = math.sqrt(sum((ap[k] - t * ab[k]) ** 2 for k in range(3)))
    return d - r


def _dist_elipsoide(p, c, r):
    q = [(p[k] - c[k]) / r[k] for k in range(3)]
    n = math.sqrt(sum(v * v for v in q))
    return (n - 1.0) * min(r)


def cor_do_ponto(p):
    melhor, cor = 1e9, "pele"
    for a, b, r, c in CAPSULAS:
        d = _dist_capsula(p, a, b, r)
        if d < melhor:
            melhor, cor = d, c
    for c0, r, c in ELIPSOIDES:
        d = _dist_elipsoide(p, c0, r)
        if d < melhor:
            melhor, cor = d, c
    # tronco: barra da camisa verde reta (como o uniforme), jeans abaixo
    if cor in ("camisa", "verde", "jeans") and abs(p[0]) < 0.20 and p[2] > 0.80:
        cor = "camisa" if p[2] > 1.13 else "verde" if p[2] > 0.96 else "jeans"
    return cor


def construir():
    from mathutils import Vector

    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)

    mb = bpy.data.metaballs.new("MiguelMeta")
    mb.resolution = 0.016
    mb.render_resolution = 0.016
    mb.threshold = 0.6
    meta = bpy.data.objects.new("MiguelMeta", mb)
    bpy.context.scene.collection.objects.link(meta)

    # Um elemento metaball de raio R com threshold 0.6 tem superficie em
    # ~0.63*R; K compensa para que os raios acima sejam os da superficie.
    K = 1.0 / 0.63
    for a, b, r, _ in CAPSULAS:
        va, vb = Vector(a), Vector(b)
        e = mb.elements.new()
        e.type = "CAPSULE"
        e.co = (va + vb) / 2
        e.radius = r * K
        e.size_x = (vb - va).length / 2
        e.rotation = Vector((1, 0, 0)).rotation_difference((vb - va).normalized())
        e.stiffness = 2.0
    for c, (rx, ry, rz), _ in ELIPSOIDES:
        e = mb.elements.new()
        e.type = "ELLIPSOID"
        e.co = c
        m = max(rx, ry, rz)
        e.radius = m * K
        e.size_x, e.size_y, e.size_z = rx / m, ry / m, rz / m
        e.stiffness = 2.0

    bpy.context.view_layer.update()
    deps = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(meta.evaluated_get(deps))
    bpy.data.objects.remove(meta, do_unlink=True)
    me.name = "Miguel"
    ob = bpy.data.objects.new("Miguel", me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)

    # fecha e solda a malha, depois reduz para o visual PS1
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.002)
    bm.to_mesh(me)
    bm.free()
    dec = ob.modifiers.new("Decimate", "DECIMATE")
    dec.ratio = min(1.0, ALVO_FACES * 2 / max(1, len(me.polygons) * 2))
    dec.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="Decimate")

    # altura exata (topo do cabelo) e pes no chao
    zs = [v.co.z for v in me.vertices]
    k = ALTURA / (max(zs) - min(zs))
    for v in me.vertices:
        v.co.z = (v.co.z - min(zs)) * k
        v.co.x *= k
        v.co.y *= k

    for nome, rgb in CORES.items():
        mat = bpy.data.materials.new(nome)
        mat.diffuse_color = (*rgb, 1.0)
        me.materials.append(mat)
    ordem = list(CORES)
    for pol in me.polygons:
        c = pol.center
        pol.material_index = ordem.index(cor_do_ponto((c.x / k, c.y / k, c.z / k + min(zs))))
        pol.use_smooth = False
    return ob


# ----------------------------------------------------------------- render
def renderizar(pasta):
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light = "STUDIO"
    sh.color_type = "MATERIAL"
    sh.show_object_outline = True
    sh.background_type = "VIEWPORT"
    sh.background_color = (0.55, 0.55, 0.57)
    cena.render.film_transparent = False
    cena.render.resolution_x = 900
    cena.render.resolution_y = 1000
    cena.render.image_settings.file_format = "PNG"

    cam_data = bpy.data.cameras.new("Cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 2.0
    cam = bpy.data.objects.new("Cam", cam_data)
    cena.collection.objects.link(cam)
    cena.camera = cam

    vistas = {
        "frente": ((0, -5, 0.90), (math.pi / 2, 0, 0)),
        "lado": ((5, 0, 0.90), (math.pi / 2, 0, math.pi / 2)),
        "costas": ((0, 5, 0.90), (math.pi / 2, 0, math.pi)),
    }
    for nome, (loc, rot) in vistas.items():
        cam.location = loc
        cam.rotation_euler = rot
        cena.render.filepath = os.path.join(pasta, "miguel_%s.png" % nome)
        bpy.ops.render.render(write_still=True)

    # close do rosto
    cam_data.ortho_scale = 0.45
    for nome, (loc, rot) in (("rosto_frente", vistas["frente"]), ("rosto_lado", vistas["lado"])):
        cam.location = (loc[0], loc[1], 1.60)
        cam.rotation_euler = rot
        cena.render.filepath = os.path.join(pasta, "miguel_%s.png" % nome)
        bpy.ops.render.render(write_still=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ob = construir()
    me = ob.data
    zs = [v.co.z for v in me.vertices]
    print("Miguel: %d faces, %d tris, altura %.3f m" % (
        len(me.polygons), sum(len(p.vertices) - 2 for p in me.polygons), max(zs) - min(zs)))
    if "--render" in args:
        renderizar(os.path.abspath(args[args.index("--render") + 1]))
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))


main()

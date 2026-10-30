"""Boneco low poly do Miguel (estilo PS1 / Fears to Fathom).

Gera uma malha continua em T-pose (Skin modifier aplicado), sem textura,
com cores por material. Compativel com Blender 3.6 LTS e versoes mais novas.

Uso:
  blender -b -P arte/gaviao_boneco_lowpoly.py                 # so gera o boneco
  blender -b -P arte/gaviao_boneco_lowpoly.py -- --render DIR # gera e renderiza
  blender -b -P arte/gaviao_boneco_lowpoly.py -- --blend ARQ  # salva .blend
  opcoes: --glb ARQ, --textura ARQ.png, --render-pose DIR, --sem-textura, --sem-rig

Pipeline (praticas de modelagem de personagem para jogo):
  1. forma por metaballs (volumes simples, cabeca lisa estilo Fears to Fathom);
  2. retopologia em quads uniformes e simetricos (voxel + QuadriFlow), centro
     soldado, sombreamento suave;
  3. UV automatico com o rosto ampliado na textura; textura 512 projetada das
     fotos, misturada pelo angulo da superficie, pele igualada entre fotos,
     cor de 15 bits e amostragem Closest;
  4. rig com nomes do SkeletonProfileHumanoid do Godot (retarget automatico),
     pesos automaticos suavizados, no maximo 4 ossos por vertice;
  5. export glTF com transformacoes aplicadas (--glb).

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


# pernas: jeans reto e folgado (nao colado), barra caindo no tenis
cap((0.098, 0.0, 0.11), (0.096, 0.0, 0.50), 0.064, "jeans", True)
cap((0.096, 0.0, 0.50), (0.092, 0.0, 0.86), 0.076, "jeans", True)
eli((0.100, -0.045, 0.045), (0.050, 0.130, 0.050), "tenis", True)
# quadril e cintura (magro)
eli((0.0, 0.0, 0.92), (0.165, 0.100, 0.095), "jeans")
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
cap((0.725, -0.020, 1.398), (0.765, -0.055, 1.398), 0.013, "pele", True)  # polegar
# pescoco
cap((0.0, 0.010, 1.42), (0.0, 0.005, 1.55), 0.056, "pele")
# cabeca no estilo Fears to Fathom: volume simples e liso, o rosto vem da
# textura. So o nariz tem um relevo discreto; boca e olhos sao so textura.
eli((0.0, 0.010, 1.655), (0.080, 0.095, 0.095), "pele")         # cranio
eli((0.0, -0.025, 1.600), (0.081, 0.075, 0.075), "pele")        # rosto
eli((0.0, -0.035, 1.550), (0.070, 0.058, 0.042), "pele")        # mandibula
eli((0.0, -0.058, 1.524), (0.034, 0.030, 0.024), "pele")        # queixo
eli((0.0, -0.088, 1.600), (0.014, 0.020, 0.028), "pele")        # nariz
eli((0.090, 0.018, 1.622), (0.014, 0.022, 0.034), "pele", True)  # orelhas
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

# cabelo um pouco mais baixo (volume medido na foto de frente)
ELIPSOIDES[:] = [((c[0], c[1], c[2] - 0.025 * (c[2] > 1.69)) if k == "cabelo" else c, r, k)
                 for c, r, k in ELIPSOIDES]

# franja sobe um pouco: a testa aparece entre a franja e a sobrancelha
ELIPSOIDES[:] = [((c[0], c[1], c[2] + 0.018) if k == "cabelo" and c[1] < -0.05 and c[2] < 1.73
                  else c, r, k) for c, r, k in ELIPSOIDES]

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

ALVO_QUADS = 1450  # ~2700 triangulos depois de triangular no motor


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
    # Retopologia: em vez de decimar (triangulos soltos, sem fluxo), refaz a
    # malha em quads de tamanho uniforme e simetricos (QuadriFlow), como um
    # modelador faria na retopo. Antes, voxel remesh deixa a malha fechada.
    me.use_mirror_x = True
    rem = ob.modifiers.new("Voxel", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = 0.008
    bpy.ops.object.modifier_apply(modifier="Voxel")
    # vertices quase repetidos do voxel fazem o QuadriFlow recusar a malha
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=0.0005)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    bpy.ops.object.quadriflow_remesh(target_faces=ALVO_QUADS, use_mesh_symmetry=True,
                                     use_preserve_sharp=False, use_preserve_boundary=False,
                                     smooth_normals=False, seed=7)
    me = ob.data
    if len(me.polygons) > ALVO_QUADS * 2:
        raise RuntimeError("QuadriFlow falhou (%d faces)" % len(me.polygons))
    # a simetria do QuadriFlow deixa o meio descosturado: solda (sem isso o
    # sombreamento suave quebra numa linha no meio do rosto)
    bm = bmesh.new()
    bm.from_mesh(me)
    meio = [v for v in bm.verts if abs(v.co.x) < 0.004]
    for v in meio:
        v.co.x = 0.0
    bmesh.ops.remove_doubles(bm, verts=meio, dist=0.003)
    bm.to_mesh(me)
    bm.free()
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
        pol.use_smooth = True  # sombreamento suave, como no Fears to Fathom
    ob["k"], ob["z_min"] = k, min(zs)
    return ob



# ---------------------------------------------------------------- textura
# Textura 512x512 feita so com as fotos de referencia: cada texel da malha e
# projetado (ortografico) na foto do lado para onde a face aponta.
# Projecoes: foto -> (px0, sx, py0, sy, z0, eixo). px = px0 + sx * eixo,
# py = py0 - sy * (z - z0); fotos normalizadas para 1500x2000.
FOTOS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "referencias", "miguel")
TEX = 512
PROJ = {
    # coordenadas do modelo antes do ajuste para 1,76 m (nao mudam com a escala)
    "rosto_frente": (820, 4285, 1000, 4921, 1.568, lambda x, y: x),
    "perfil_direito": (1010, 5730, 1000, 3916, 1.582, lambda x, y: -y - 0.122),
    "perfil_esquerdo": (300, 5730, 1010, 4237, 1.583, lambda x, y: y + 0.122),
    "cabeca_costas": (640, 5364, 1230, 4083, 1.521, lambda x, y: -x),
    "corpo_frente": (750, 922, 1840, 922, -0.005, lambda x, y: x),
}


def _carregar(nome):
    import numpy as np
    img = bpy.data.images.load(os.path.join(FOTOS, nome + ".jpg"))
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, w, 4)[::-1, :, :3]  # linha 0 = topo


def _amostra(fotos, nome, x, y, z):
    px0, sx, py0, sy, z0, eixo = PROJ[nome]
    im = fotos[nome]
    h, w = im.shape[:2]
    u = int(px0 + sx * eixo(x, y))
    v = int(py0 - sy * (z - z0))
    if 0 <= u < w and 0 <= v < h:
        return im[v, u]
    return None


def texturizar(ob, k, z_min):
    import numpy as np
    me = ob.data
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    # o rosto ganha mais area na textura: aumenta a cabeca so durante o UV
    orig = [v.co.copy() for v in me.vertices]
    bpy.ops.object.mode_set(mode="OBJECT")
    for v in me.vertices:
        if v.co.z > 1.45:
            v.co.x *= 2.2
            v.co.y *= 2.2
            v.co.z = 1.45 + (v.co.z - 1.45) * 2.2
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(80), island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    for v, co in zip(me.vertices, orig):
        v.co = co
    me.update()

    fotos = {n: _carregar(n) for n in PROJ}
    # "delighting" simples: a pele das fotos de perfil fica com a mesma cor
    # media da pele da foto de frente, para nao aparecer emenda de luz
    ref = fotos["rosto_frente"][1050:1150, 560:680].reshape(-1, 3).mean(0)
    for nome, (y0, y1, x0, x1) in (("perfil_direito", (1000, 1100, 500, 650)),
                                   ("perfil_esquerdo", (1050, 1150, 650, 800))):
        m = fotos[nome][y0:y1, x0:x1].reshape(-1, 3).mean(0)
        fotos[nome] = np.clip(fotos[nome] * (ref / m), 0, 1)
    # pele dos bracos: media da bochecha na foto de frente
    pele = fotos["rosto_frente"][1050:1150, 560:680].reshape(-1, 3).mean(0)
    # amostra de cachos (foto de costas) para o topo e onde a foto mostra fundo
    cachos = fotos["cabeca_costas"][250:950, 250:950]
    tex = np.zeros((TEX, TEX, 3), dtype=np.float32)
    feito = np.zeros((TEX, TEX), dtype=bool)
    uv = me.uv_layers.active.data

    vn = [v.normal.copy() for v in me.vertices]
    for pol in me.polygons:
        n = pol.normal
        cen = pol.center
        cor = cor_do_ponto((cen.x / k, cen.y / k, cen.z / k + z_min))
        cabeca = cen.z > 1.46 and cor in ("pele", "cabelo", "labio")
        if cabeca:
            # a frente do rosto (nariz, macas) usa sempre a foto de frente
            frente = 0.8 if cen.y < -0.045 and cor != "cabelo" else 0.0
            pesos = {"rosto_frente": -n.y + frente, "cabeca_costas": n.y,
                     "perfil_direito": -n.x, "perfil_esquerdo": n.x}
            fonte = max(pesos, key=pesos.get)
        elif abs(cen.x) < 0.22:
            fonte = "corpo_frente"
        else:
            fonte = None
        base = np.array(CORES[cor]) ** (1 / 2.2)
        li = list(pol.loop_indices)
        P = [me.vertices[me.loops[i].vertex_index].co for i in li]
        N = [vn[me.loops[i].vertex_index] for i in li]
        T = [uv[i].uv for i in li]
        for t in range(1, len(li) - 1):
            tri = (0, t, t + 1)
            a, b, c = (np.array(T[i]) * TEX for i in tri)
            pa, pb, pc = (np.array(P[i]) for i in tri)
            na, nb, nc = (np.array(N[i]) for i in tri)
            x0, y0 = np.floor(np.minimum(np.minimum(a, b), c)).astype(int) - 1
            x1, y1 = np.ceil(np.maximum(np.maximum(a, b), c)).astype(int) + 1
            den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if abs(den) < 1e-12:
                continue
            for ty in range(max(y0, 0), min(y1, TEX)):
                for tx in range(max(x0, 0), min(x1, TEX)):
                    qx, qy = tx + 0.5, ty + 0.5
                    l1 = ((b[1] - c[1]) * (qx - c[0]) + (c[0] - b[0]) * (qy - c[1])) / den
                    l2 = ((c[1] - a[1]) * (qx - c[0]) + (a[0] - c[0]) * (qy - c[1])) / den
                    l3 = 1 - l1 - l2
                    if min(l1, l2, l3) < -0.02:
                        continue
                    q = l1 * pa + l2 * pb + l3 * pc
                    q = np.array((q[0] / k, q[1] / k, q[2] / k + z_min))
                    col = None
                    if fonte == "corpo_frente":
                        # costas do corpo: mesma estampa espelhada
                        xx = q[0] if n.y < 0.3 else -q[0]
                        if q[2] < 0.86:  # pernas: fica dentro da perna da foto
                            lado = 1 if xx > 0 else -1
                            # na foto as pernas abrem do joelho para baixo
                            centro = 0.10 + 0.07 * max(0.0, min(1.0, (0.50 - q[2]) / 0.40))
                            xx = lado * centro + max(-0.03, min(0.03, xx - lado * 0.10))
                        col = _amostra(fotos, fonte, max(-0.20, min(0.20, xx)), q[1], q[2])
                    elif cabeca:
                        # mistura as fotos pelo angulo da superficie (sem emenda dura)
                        nq = l1 * na + l2 * nb + l3 * nc
                        nq = nq / max(np.linalg.norm(nq), 1e-6)
                        frente = 0.6 if q[1] < -0.045 and cor != "cabelo" else 0.0
                        soma, peso = np.zeros(3), 0.0
                        for nome, w in (("rosto_frente", -nq[1] + frente),
                                        ("cabeca_costas", nq[1]),
                                        ("perfil_direito", -nq[0]),
                                        ("perfil_esquerdo", nq[0])):
                            if w <= 0:
                                continue
                            amo = _amostra(fotos, nome, q[0], q[1], q[2])
                            if amo is None or (cor != "cabelo" and amo.min() > 0.55) \
                                    or (cor == "cabelo" and amo.mean() > 0.30):
                                continue
                            soma += amo * w ** 3
                            peso += w ** 3
                        col = soma / peso if peso > 0 else None
                    elif fonte:
                        col = _amostra(fotos, fonte, q[0], q[1], q[2])
                    if cor == "cabelo" and (col is None or col.mean() > 0.30
                                            or q[2] > 1.76):
                        ch, cw = cachos.shape[:2]
                        col = cachos[int((q[1] + q[2]) * 3000) % ch,
                                     int((q[0] + 0.5 * q[2]) * 3000) % cw]
                    if cabeca and cor != "cabelo" and col is not None and col.min() > 0.55:
                        col = None  # parede/gola atras do pescoco na foto
                    if col is None:
                        col = pele if cor == "pele" else base
                    tex[ty, tx] = col
                    feito[ty, tx] = True

    # espalha a borda das ilhas para nao aparecer costura
    for _ in range(4):
        viz = np.zeros_like(tex)
        cnt = np.zeros(feito.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(feito, (dy, dx), (0, 1))
            viz += np.roll(tex, (dy, dx), (0, 1)) * m[..., None]
            cnt += m
        novo = ~feito & (cnt > 0)
        tex[novo] = viz[novo] / cnt[novo][:, None]
        feito |= novo

    tex = np.round(tex * 31) / 31  # 15 bits de cor, como no PS1
    img = bpy.data.images.new("miguel_textura", TEX, TEX)
    rgba = np.concatenate([tex, np.ones((TEX, TEX, 1), np.float32)], 2)
    img.pixels.foreach_set(rgba.ravel())
    img.pack()

    mat = bpy.data.materials.new("miguel")
    mat.use_nodes = True
    nt = mat.node_tree
    no_tex = nt.nodes.new("ShaderNodeTexImage")
    no_tex.image = img
    no_tex.interpolation = "Closest"
    bsdf = nt.nodes.get("Principled BSDF")
    nt.links.new(no_tex.outputs["Color"], bsdf.inputs["Base Color"])
    me.materials.clear()
    me.materials.append(mat)
    return img

# -------------------------------------------------------------------- rig
# Ossos em coordenadas do modelo antes da escala (mesmas das partes acima).
# nome: (cabeca do osso, cauda, pai). Nomes .L/.R para espelhar poses.
def _ossos():
    # Nomes do SkeletonProfileHumanoid do Godot 4: o importador mapeia sozinho
    # e da para reaproveitar animacoes de outros humanoides (retarget).
    # Left = esquerda do personagem (+x, ele olha para -y).
    o = {
        "Hips": ((0, 0, 0.93), (0, 0, 1.03), None),
        "Spine": ((0, 0, 1.03), (0, 0, 1.17), "Hips"),
        "Chest": ((0, 0, 1.17), (0, 0, 1.29), "Spine"),
        "UpperChest": ((0, 0, 1.29), (0, 0, 1.40), "Chest"),
        "Neck": ((0, 0.005, 1.40), (0, 0.005, 1.485), "UpperChest"),
        "Head": ((0, 0.005, 1.485), (0, 0.005, 1.75), "Neck"),
    }
    for lado, sx in (("Left", 1), ("Right", -1)):
        o[lado + "Shoulder"] = ((sx * 0.03, 0, 1.39), (sx * 0.17, 0, 1.405), "UpperChest")
        o[lado + "UpperArm"] = ((sx * 0.17, 0, 1.405), (sx * 0.47, 0, 1.405), lado + "Shoulder")
        o[lado + "LowerArm"] = ((sx * 0.47, 0, 1.405), (sx * 0.71, 0, 1.405), lado + "UpperArm")
        o[lado + "Hand"] = ((sx * 0.71, 0, 1.405), (sx * 0.87, 0, 1.40), lado + "LowerArm")
        o[lado + "UpperLeg"] = ((sx * 0.092, 0, 0.90), (sx * 0.096, -0.005, 0.50), "Hips")
        o[lado + "LowerLeg"] = ((sx * 0.096, -0.005, 0.50), (sx * 0.098, 0.01, 0.09), lado + "UpperLeg")
        o[lado + "Foot"] = ((sx * 0.098, 0.01, 0.09), (sx * 0.100, -0.10, 0.03), lado + "LowerLeg")
        o[lado + "Toes"] = ((sx * 0.100, -0.10, 0.03), (sx * 0.100, -0.17, 0.03), lado + "Foot")
    return o


def riggar(ob, k, z_min):
    """Cria o esqueleto e liga a malha com pesos automaticos."""
    def f(p):
        return (p[0] * k, p[1] * k, (p[2] - z_min) * k)

    arm_data = bpy.data.armatures.new("MiguelRig")
    rig = bpy.data.objects.new("MiguelRig", arm_data)
    bpy.context.scene.collection.objects.link(rig)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    ossos = _ossos()
    for nome, (a, b, _) in ossos.items():
        e = arm_data.edit_bones.new(nome)
        e.head, e.tail = f(a), f(b)
        e.roll = 0.0
    for nome, (_, _, pai) in ossos.items():
        if pai:
            e = arm_data.edit_bones[nome]
            e.parent = arm_data.edit_bones[pai]
            e.use_connect = (tuple(e.head) == tuple(e.parent.tail))
    bpy.ops.object.mode_set(mode="OBJECT")

    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    # suaviza e normaliza os pesos (dobras sem quinas nas articulacoes)
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.object.vertex_group_smooth(group_select_mode="ALL", factor=0.5, repeat=2)
    bpy.ops.object.vertex_group_limit_total(group_select_mode="ALL", limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    sem_peso = sum(1 for v in ob.data.vertices if not v.groups)
    print("Rig: %d ossos, %d vertices sem peso" % (len(ossos), sem_peso))
    return rig


def pose_teste(rig):
    """Pose para conferir os pesos: braco abaixado, joelho e cotovelo dobrados."""
    from mathutils import Euler
    pb = rig.pose.bones
    for b in pb:
        b.rotation_mode = "XYZ"
    pb["LeftUpperArm"].rotation_euler = Euler((0, 0, math.radians(-65)))
    pb["LeftLowerArm"].rotation_euler = Euler((0, 0, math.radians(-70)))
    pb["RightUpperArm"].rotation_euler = Euler((math.radians(-60), 0, 0))
    pb["LeftUpperLeg"].rotation_euler = Euler((math.radians(-50), 0, 0))
    pb["LeftLowerLeg"].rotation_euler = Euler((math.radians(70), 0, 0))
    pb["Head"].rotation_euler = Euler((0, 0, math.radians(30)))
    pb["Spine"].rotation_euler = Euler((math.radians(10), 0, 0))


# ----------------------------------------------------------------- render
def renderizar(pasta, so_corpo=False):
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light = "STUDIO"
    sh.color_type = "TEXTURE" if bpy.data.images.get("miguel_textura") else "MATERIAL"
    sh.show_object_outline = True
    sh.show_specular_highlight = False
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
        cena.render.filepath = os.path.join(pasta, "miguel_%s%s.png" % ("pose_" * so_corpo, nome))
        bpy.ops.render.render(write_still=True)
    if so_corpo:
        return

    # close do rosto
    cam_data.ortho_scale = 0.45
    for nome, (loc, rot) in (("rosto_frente", vistas["frente"]), ("rosto_lado", vistas["lado"])):
        cam.location = (loc[0], loc[1], ALTURA - 0.19)
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
    if "--sem-textura" not in args:
        img = texturizar(ob, ob["k"], ob["z_min"])
        if "--textura" in args:
            img.filepath_raw = os.path.abspath(args[args.index("--textura") + 1])
            img.file_format = "PNG"
            img.save()
    rig = None
    if "--sem-rig" not in args:
        rig = riggar(ob, ob["k"], ob["z_min"])
    if "--glb" in args:
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(args[args.index("--glb") + 1]),
                                  export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True)
    if "--render" in args:
        renderizar(os.path.abspath(args[args.index("--render") + 1]))
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))
    if "--render-pose" in args and rig:
        pose_teste(rig)
        renderizar(os.path.abspath(args[args.index("--render-pose") + 1]), so_corpo=True)


main()

"""Cabelo do Felipe: miolo de volume tirado das fotos + cards de cachos.

Miolo: o couro cabeludo do modelo (linha do cabelo na testa tirada da selfie de
frente) e empurrado para fora, pela normal, ate sair da silhueta do cabelo nas
fotos de frente ou de perfil do video (de longe, mesma camera; a selfie de
perto encolhe o cabelo ~20-27%). A forma segue o cranio e a espessura vem das
fotos; depois vira volume fechado (voxel) e e suavizada.

Usado por felipe_humano.py; sozinho:  python arte/felipe_cabelo.py --mascaras DIR
"""
import json
import math
import os

import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
FOTOS = os.path.join(AQUI, "referencias", "felipe", "fotos_originais")
ALINHAMENTO = os.path.join(AQUI, "felipe_fotos_alinhamento.json")
PINTURA = os.path.join(AQUI, "felipe_rosto_pintura.json")
ESCURO = 78         # luminancia maxima do cabelo nas fotos
CORTE_BAIXO = -0.115  # nada de cabelo abaixo disto (relativo aos olhos): camiseta
GRADE = ((-0.20, 0.20), (-0.14, 0.32), (-0.13, 0.27))  # x, y, z em volta dos olhos
PASSO = 0.002       # grade das mascaras (m)
LATERAL = 0.75      # quanto os lados afinam (0 = igual ao resto)
ALTURA_LADO = -0.035  # nos lados o cabelo desce ate aqui (rel. aos olhos): altura do nariz
FOLGA_LADO = 0.013  # lados retos: quanto passam da cabeca abaixo dos olhos (m)
ESP_LADO = 0.014    # espessura maxima nos lados abaixo dos olhos (colado na cabeca)
SILHUETA = "selfie"  # "selfie" (compacto, escolhido) ou "video" (tamanho medido de longe)
ESP_FRENTE, ESP_MAX, ESP_MIN = 0.025, 0.085, 0.008  # espessura do cabelo (m)


def _mascara_foto(caminho, limite=ESCURO, sem_pele=False):
    """Pixels escuros; sem_pele tira a pele na sombra (avermelhada; cabelo e neutro)."""
    from PIL import Image
    a = np.asarray(Image.open(os.path.join(FOTOS, caminho)).convert("RGB"), np.float32)
    m = a.mean(2) < limite
    if sem_pele:
        m &= (a[..., 0] - a[..., 2]) < 16
    return m


def _amostrar(mask, m, coords):
    """mask[foto] nos pontos do modelo: inverte a afim foto px -> modelo."""
    a = np.vstack([np.array(m), [0, 0, 1]])
    inv = np.linalg.inv(a)
    px = coords @ inv[:2, :2].T + inv[:2, 2]
    h, w = mask.shape
    xi, yi = np.round(px[:, 0]).astype(int), np.round(px[:, 1]).astype(int)
    ok = (xi >= 0) & (xi < w) & (yi >= 0) & (yi < h)
    out = np.zeros(len(coords), bool)
    out[ok] = mask[yi[ok], xi[ok]]
    return out


VIDEO = os.path.join(AQUI, "referencias", "felipe", "angulos_principais")
VIDEO_FRENTE = "frente_neutra_19.50s.jpg"
VIDEO_PERFIL = "perfil_virado_direita_28.50s.jpg"  # olhando para a direita


def _olho_queixo_video():
    """Olhos e queixo no quadro de frente do video (detector numa ampliacao)."""
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions, vision
    from PIL import Image
    caixa, amp = (420, 250, 860, 750), 4
    im = Image.open(os.path.join(VIDEO, VIDEO_FRENTE)).convert("RGB").crop(caixa)
    im = im.resize((im.width * amp, im.height * amp), Image.LANCZOS)
    det = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=os.environ.get(
            "FACE_LANDMARKER", os.path.join(AQUI, "..", "..", "face_landmarker.task"))), num_faces=1))
    r = det.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=np.asarray(im).copy()))
    p = np.array([[q.x * im.width, q.y * im.height] for q in r.face_landmarks[0]]) / amp
    p += caixa[:2]
    return (p[468] + p[473]) / 2, p[152]


def _contorno_dir(mask, linhas):
    """x mais a direita de cada linha (perfil virado para a direita)."""
    out = np.full(len(linhas), np.nan)
    for n, y in enumerate(linhas):
        c = np.where(mask[int(y)])[0]
        if len(c):
            out[n] = c.max()
    return out


def mascaras(xs, ys, zs, nariz=(-0.05, -0.045), fonte=None):
    """Cabelo no espaco do modelo (z e y relativos aos olhos):
    F[x, z] e P[y, z]: silhueta externa, dos quadros do video (de longe, mesma
    camera e escala nos dois); R[x, z]: cabelo na frente do rosto, da selfie de
    frente (alinhada pelos 478 pontos; de perto ela encolhe o cabelo, mas na
    frente do rosto o alinhamento e exato)."""
    from scipy import ndimage
    pt = json.load(open(PINTURA))
    olho, queixo = _olho_queixo_video()
    k = -pt["queixo"][1] / (queixo[1] - olho[1])  # m por pixel do video
    mf = _mascara_foto(os.path.join(VIDEO, VIDEO_FRENTE), sem_pele=True)
    mp_ = _mascara_foto(os.path.join(VIDEO, VIDEO_PERFIL), sem_pele=True)
    mf = ndimage.binary_opening(ndimage.binary_closing(mf, iterations=2), iterations=1)
    mp_ = ndimage.binary_opening(ndimage.binary_closing(mp_, iterations=2), iterations=1)
    m_f = [[k, 0, -olho[0] * k], [0, -k, olho[1] * k]]
    # perfil: mesma escala e mesma altura dos olhos (ele gira no lugar); em y, a
    # ponta do nariz (mais a direita entre olho e boca) cai na do modelo
    linhas = np.arange(olho[1] + 0.3 * (queixo[1] - olho[1]), olho[1] + 0.75 * (queixo[1] - olho[1]))
    pele = _mascara_foto(os.path.join(VIDEO, VIDEO_PERFIL), 150)  # pessoa inteira
    cont = _contorno_dir(pele, linhas)
    ponta, linha_ponta = np.nanmax(cont), linhas[np.nanargmax(cont)]
    # ponta do nariz do video -> ponta do nariz do modelo (y, z relativos aos olhos)
    m_p = [[-k, 0, ponta * k + nariz[0]], [0, -k, linha_ponta * k + nariz[1]]]
    gx, gz = np.meshgrid(xs, zs, indexing="ij")
    xz = np.stack([gx.ravel(), gz.ravel()], 1)
    f = _amostrar(mf, m_f, xz).reshape(gx.shape)
    gy, gz2 = np.meshgrid(ys, zs, indexing="ij")
    p = _amostrar(mp_, m_p, np.stack([gy.ravel(), gz2.ravel()], 1)).reshape(gy.shape)
    al = json.load(open(ALINHAMENTO))
    ms = _mascara_foto(os.path.join(FOTOS, al["frente"]["foto"]))
    ms = ndimage.binary_opening(ndimage.binary_closing(ms, iterations=4), iterations=2)
    r = _amostrar(ms, al["frente"]["px_para_xz"], xz).reshape(gx.shape)
    if (fonte or SILHUETA) == "selfie":
        # cabelo compacto (escolha do Felipe): silhueta das selfies, que deixam o
        # cabelo menor e colado na cabeca
        f = r.copy()
        mp2 = _mascara_foto(os.path.join(FOTOS, al["perfil"]["foto"]))
        mp2 = ndimage.binary_opening(ndimage.binary_closing(mp2, iterations=4), iterations=2)
        p = _amostrar(mp2, al["perfil"]["px_para_yz"], np.stack([gy.ravel(), gz2.ravel()], 1)).reshape(gy.shape)
    for m in (f, p, r):
        m[:, zs < CORTE_BAIXO] = False
    return f, p, r


def _grade_mask(mask, a0, b0, passo=PASSO):
    """Consulta mask[i, j] em pontos (a, b) em metros."""
    def f(a, b):
        i = np.round((np.asarray(a) - a0) / passo).astype(int)
        j = np.round((np.asarray(b) - b0) / passo).astype(int)
        ok = (i >= 0) & (i < mask.shape[0]) & (j >= 0) & (j < mask.shape[1])
        out = np.zeros(np.shape(i), bool)
        out[ok] = mask[i[ok], j[ok]]
        return out
    return f


def _espessura(y, z):
    """Maior espessura: franja fina na frente do rosto, volume cheio atras e em
    cima; abaixo da linha dos olhos afina (sem "protetor de ouvido")."""
    t = np.clip((y + 0.02) / 0.08, 0.0, 1.0)
    baixo = np.clip((z + 0.03) / 0.06, 0.3, 1.0)
    return (ESP_FRENTE + (ESP_MAX - ESP_FRENTE) * t) * baixo


def espessuras(co, nor, escalpo, f, p, xs, ys, zs):
    """Anda pela normal de cada vertice do couro cabeludo ate sair da silhueta
    de frente OU da de perfil (cabelo + cabeca, buracos fechados)."""
    from scipy import ndimage
    f, p = f.copy(), p.copy()
    cab = co[co[:, 2] > -0.14]
    for m, a, a0 in ((f, 0, xs[0]), (p, 1, ys[0])):  # a cabeca tambem e silhueta
        i = np.round((cab[:, a] - a0) / PASSO).astype(int)
        j = np.round((cab[:, 2] - zs[0]) / PASSO).astype(int)
        ok = (i >= 0) & (i < m.shape[0]) & (j >= 0) & (j < m.shape[1])
        m[i[ok], j[ok]] = True
    f = ndimage.binary_fill_holes(ndimage.binary_closing(f, iterations=3))
    p = ndimage.binary_fill_holes(ndimage.binary_closing(p, iterations=3))
    F, P = _grade_mask(f, xs[0], zs[0]), _grade_mask(p, ys[0], zs[0])
    t = np.zeros(len(co))
    vivo = escalpo.copy()
    for s in np.arange(0.0, ESP_MAX + 1e-9, PASSO):
        q = co + nor * s
        vivo &= F(q[:, 0], q[:, 2]) & P(q[:, 1], q[:, 2])
        t[vivo] = s
    # lados mais finos (pedido do Felipe): corta onde a normal aponta para o lado
    lados = 1.0 - LATERAL * np.abs(nor[:, 0])
    lim = _espessura(co[:, 1], co[:, 2]) * lados
    # abaixo da linha dos olhos, nos lados: cabelo colado (como a versao aprovada)
    baixo_lado = (np.abs(co[:, 0]) > 0.045) & (co[:, 2] < 0.01) & (co[:, 1] < 0.11)
    lim[baixo_lado] = np.minimum(lim[baixo_lado], ESP_LADO)
    return np.clip(t, ESP_MIN, lim)


def _lados_retos(ob, co, o):
    """Abaixo da linha dos olhos os lados descem retos, no maximo FOLGA_LADO alem
    da cabeca (sem contar a orelha), como na versao aprovada pelo Felipe."""
    x, y, z = co[:, 0], co[:, 1], co[:, 2]
    orelha = (np.abs(x) > 0.055) & (z > -0.075) & (z < 0.02) & (y > -0.025) & (y < 0.05)
    cab = co[~orelha & (z > -0.12)]
    zs = np.arange(-0.12, 0.08, 0.004)
    meia = np.array([np.abs(cab[np.abs(cab[:, 2] - zz) < 0.004, 0]).max() for zz in zs])
    for v in ob.data.vertices:
        p = np.array(v.co[:]) - o
        lim = np.interp(p[2], zs, meia) + FOLGA_LADO
        lim += 0.08 * min(1.0, max(0.0, p[2] / 0.04))  # some acima dos olhos
        if abs(p[0]) > lim:
            v.co.x = o[0] + math.copysign(lim, p[0])


def criar_nucleo(ob_corpo, olho, nome="Cabelo"):
    """Miolo do cabelo (objeto Blender) na posicao do corpo."""
    import bmesh
    import bpy
    from miguel_humano import objeto_de_faces, remesh, suavizar
    pt = json.load(open(PINTURA))
    topo_sob = max(z for _, z in pt["sobrancelha_d"])
    me = ob_corpo.data
    me.update()
    co = np.array([v.co[:] for v in me.vertices]) - np.array(olho[:])
    nor = np.array([v.normal[:] for v in me.vertices])
    xs, ys, zs = (np.arange(a, b + 1e-9, PASSO) for a, b in GRADE)
    meio = co[(co[:, 2] > -0.14) & (np.abs(co[:, 0]) < 0.01) & (co[:, 2] > -0.07) & (co[:, 2] < -0.02)]
    ponta = meio[meio[:, 1].argmin()]
    f, p, r = mascaras(xs, ys, zs, (ponta[1], ponta[2]))
    # franja: em cada coluna, cabelo de cima ate o cacho mais baixo (acima da
    # sobrancelha) - os vaos de pele entre os cachos nao viram testa careca
    r = r.copy()
    acima = zs > topo_sob
    for i in range(r.shape[0]):
        c = np.where(r[i] & acima)[0]
        if len(c):
            r[i, c.min():] = True
    R = _grade_mask(r, xs[0], zs[0])
    x, y, z = co[:, 0], co[:, 1], co[:, 2]
    orelha = (np.abs(x) > 0.055) & (z > -0.07) & (z < 0.015) & (y > -0.02) & (y < 0.045)
    # couro cabeludo: atras da orelha acima da nuca; na frente e nos lados, so
    # onde a selfie de frente mostra cabelo, e acima da sobrancelha
    # atras desce ate a nuca; nos lados para na metade da orelha (sem "abas")
    lateral = np.abs(x) > 0.045
    tras = (y > 0.035) & (z > -0.075) & ~(lateral & (y < 0.11) & (z < ALTURA_LADO))
    lado = (np.abs(x) > 0.058) & (z > ALTURA_LADO)  # lados alem do rosto
    frente = (y <= 0.035) & R(x, z) & ((z > topo_sob + 0.006) | lado)
    escalpo = (z > -0.10) & ~orelha & (tras | frente)
    t = espessuras(co, nor, escalpo, f, p, xs, ys, zs)
    faces = [pl.index for pl in me.polygons if all(escalpo[i] for i in pl.vertices)]
    ob = objeto_de_faces(nome, me, faces)
    vs = sorted({i for fi in faces for i in me.polygons[fi].vertices})
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    esp = t[vs]
    viz = [[e.other_vert(v).index for e in v.link_edges] for v in bm.verts]
    # distancia (em arestas) ate a borda: nos lados a ponta do cabelo afina e
    # encosta na cabeca em vez de abrir como sino
    dist = np.full(len(bm.verts), 99)
    fila = [v.index for v in bm.verts if v.is_boundary]
    dist[fila] = 0
    while fila:
        prox = []
        for i in fila:
            for j in viz[i]:
                if dist[j] > dist[i] + 1:
                    dist[j] = dist[i] + 1
                    prox.append(j)
        fila = prox
    lado_v = np.abs(co[vs, 0]) > 0.04
    afina = np.where(lado_v, np.clip(dist / 5.0, 0.25, 1.0), 1.0)
    for _ in range(40):  # silhueta tem fios soltos: espessura suave, peca unica
        esp = np.array([0.5 * esp[i] + 0.5 * esp[n].mean() if n else esp[i]
                        for i, n in enumerate(viz)])
    esp *= afina
    bm.normal_update()
    for v, e in zip(bm.verts, esp):
        v.co += v.normal * e
    bm.to_mesh(ob.data)
    bm.free()
    sol = ob.modifiers.new("Solid", "SOLIDIFY")
    sol.thickness = 0.03
    sol.offset = -1
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="Solid")
    remesh(ob, 0.005)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    suavizar(bm, 4, 0.5, manter_borda=False)
    bm.to_mesh(ob.data)
    bm.free()
    _lados_retos(ob, co, np.array(olho[:]))
    for pl in ob.data.polygons:
        pl.use_smooth = True
    dec = ob.modifiers.new("Dec", "DECIMATE")
    dec.ratio = min(1.0, 6000 / max(1, len(ob.data.polygons)))
    bpy.ops.object.modifier_apply(modifier="Dec")
    return ob


def salvar_mascaras(pasta):
    """Confere as mascaras: cabelo das fotos levado ao modelo."""
    from PIL import Image
    os.makedirs(pasta, exist_ok=True)
    xs, ys, zs = (np.arange(a, b, 0.001) for a, b in GRADE)
    f, p, r = mascaras(xs, ys, zs)
    for nome, m in (("frente", f.T[::-1]), ("perfil", p.T[::-1, ::-1]), ("rosto", r.T[::-1])):
        Image.fromarray((m * 255).astype(np.uint8)).save(os.path.join(pasta, "mascara_%s.png" % nome))


if __name__ == "__main__":
    import sys
    salvar_mascaras(sys.argv[sys.argv.index("--mascaras") + 1])


# ------------------------------------------------------------ cards
TEXTURA = os.path.join(AQUI, "felipe_cachos.png")  # gerada por textura_cachos()
VARIANTES = 4  # colunas do atlas


def textura_cachos(caminho=TEXTURA, larg=128, alt=256, semente=5):
    """Atlas RGBA de cachos fechados (molinhas), VARIANTES colunas larg x alt.
    Cada cacho: fio em espiral descendo (projecao de uma helice), com o lado
    de tras mais escuro, brilho castanho na frente e fios soltos na ponta."""
    from PIL import Image, ImageDraw
    rng = np.random.default_rng(semente)
    esc = 4  # desenha grande e reduz (borda suave)
    W, H = larg * esc, alt * esc
    atlas = Image.new("RGBA", (W * VARIANTES, H), (0, 0, 0, 0))
    for var in range(VARIANTES):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        n = 2 + var // 2  # cachos por card
        for c in range(n):
            x0 = W * (0.15 + 0.7 * rng.random())
            y0 = H * 0.02 * rng.random()
            raio = W * rng.uniform(0.13, 0.19)
            passo = raio * rng.uniform(1.0, 1.4)
            voltas = (H * rng.uniform(0.6, 0.95) - y0) / passo
            fase = rng.random() * 6.28
            ph1, ph2 = rng.random(2) * 6.28
            for fio in range(5):  # 5 fios por cacho (mecha grossa)
                dx, dr = rng.normal(0, raio * 0.12), rng.uniform(0.8, 1.1)
                pts = []
                for t in np.linspace(0, voltas * 6.283, int(voltas * 40)):
                    rr = dr * (1 + 0.28 * np.sin(t * 0.31 + ph1))  # cacho irregular
                    yy = passo * t / 6.283 * (1 + 0.15 * np.sin(t * 0.23 + ph2))
                    # helice vista de cima em angulo: a profundidade (sin) sobe na
                    # imagem e o fio desenha lacos, como os cachos da foto
                    pts.append((x0 + dx + raio * rr * np.cos(t + fase) + 0.05 * W * np.sin(t / 9 + ph2),
                                y0 + yy + 0.75 * raio * rr * np.sin(t + fase),
                                np.sin(t + fase)))
                for (xa, ya, fa), (xb, yb, _) in zip(pts, pts[1:]):
                    frente = fa > 0
                    base = 18 if frente else 8
                    brilho = int(base + (34 * fa if frente else 0))
                    cor = (brilho + 8, brilho + 3, brilho, 255)
                    d.line([(xa, ya), (xb, yb)], fill=cor, width=int(esc * (3.2 if frente else 3.8)))
        atlas.paste(im, (W * var, 0))
    atlas = atlas.resize((larg * VARIANTES, alt), Image.LANCZOS)
    a = np.asarray(atlas).copy()
    a[..., 3] = np.where(a[..., 3] > 110, 255, 0)  # recorte (alpha scissor no Godot)
    Image.fromarray(a).save(caminho)
    return caminho


def material_cards():
    """Textura de cachos com recorte de alfa (Greater Than -> exporta como MASK
    no glTF; no Godot vira alpha scissor) e as duas faces visiveis."""
    import bpy
    mat = bpy.data.materials.get("CabeloCachos")
    if mat:
        return mat
    if not os.path.exists(TEXTURA):
        textura_cachos()
    mat = bpy.data.materials.new("CabeloCachos")
    mat.use_nodes = True
    mat.use_backface_culling = False
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(TEXTURA)
    tex.interpolation = "Closest"
    corte = nt.nodes.new("ShaderNodeMath")
    corte.operation = "GREATER_THAN"
    corte.inputs[1].default_value = 0.5
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], corte.inputs[0])
    nt.links.new(corte.outputs[0], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.6
    if hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


def criar_cards(nucleo, olho, n=260, semente=3, nome="CabeloCards"):
    """Cards de cachos espetadas no miolo: base enterrada ~1 cm, saindo para fora
    e um pouco para baixo, girando em volta da normal; na borda da franja, cards
    penduradas sobre a testa. Um objeto, UV por variante do atlas."""
    import bpy
    from mathutils import Vector
    rng = np.random.default_rng(semente)
    me = nucleo.data
    me.update()
    o = Vector(olho[:])
    pt = json.load(open(PINTURA))
    topo_sob = max(z for _, z in pt["sobrancelha_d"])
    # nada embaixo do volume (pescoco) nem na cara
    pol = [pl for pl in me.polygons if pl.normal.z > -0.5 and pl.center.z - o.z > -0.06]
    area = np.array([pl.area for pl in pol])
    escolha = rng.choice(len(pol), n, p=area / area.sum())
    cartas = []
    for i in escolha:
        pl = pol[i]
        c = pl.center.copy()
        nrm = pl.normal.copy()
        # para baixo pela superficie; 70% deitadas sobre o volume, 30% saindo
        # para fora (quebram a silhueta, como os cachos soltos da foto)
        baixo = Vector((0, 0, -1)) - nrm * nrm.z
        if baixo.length < 0.2:  # topo da cabeca: direcao qualquer na superficie
            baixo = nrm.orthogonal()
        baixo.normalize()
        ang = rng.normal(0, 0.6)
        baixo = (baixo * math.cos(ang) + nrm.cross(baixo) * math.sin(ang)).normalized()
        solta = rng.random() < 0.3
        u = (baixo + nrm * (0.9 if solta else 0.25)).normalized()
        w = nrm.cross(u).normalized()
        if solta:  # gira a card em volta do comprimento para nao ser chapada
            g = rng.uniform(-1.0, 1.0)
            w = (w * math.cos(g) + nrm * math.sin(g)).normalized()
        cartas.append((c - u * 0.008 + nrm * 0.004, u, w, rng.uniform(0.04, 0.055), rng.uniform(0.05, 0.07)))
    # franja: pontos do miolo na frente da testa, logo acima da sobrancelha
    franja = [v.co.copy() for v in me.vertices
              if v.co.y - o.y < -0.02 and topo_sob < v.co.z - o.z < topo_sob + 0.04]
    for k in rng.choice(len(franja), min(len(franja), 18), replace=False):
        c = franja[k]
        u = Vector((0, -0.25, -1)).normalized()
        w = Vector((1, 0, 0))
        cartas.append((c + Vector((0, -0.004, 0.012)), u, w, rng.uniform(0.03, 0.045), rng.uniform(0.035, 0.05)))
    vs, fs, uvs = [], [], []
    for base, u, w, larg, comp in cartas:
        a = base - w * larg / 2
        q = len(vs)
        vs += [a, a + w * larg, a + w * larg + u * comp, a + u * comp]
        fs.append((q, q + 1, q + 2, q + 3))
        var = rng.integers(VARIANTES)
        u0, u1 = var / VARIANTES, (var + 1) / VARIANTES
        uvs += [(u0, 1), (u1, 1), (u1, 0), (u0, 0)]  # topo da textura na base
    malha = bpy.data.meshes.new(nome)
    malha.from_pydata([v[:] for v in vs], [], fs)
    uvl = malha.uv_layers.new(name="UVMap")
    for li, l in enumerate(malha.loops):
        uvl.data[li].uv = uvs[l.vertex_index]
    ob = bpy.data.objects.new(nome, malha)
    bpy.context.scene.collection.objects.link(ob)
    ob.data.materials.append(material_cards())
    print("cards de cabelo: %d (%d na franja)" % (len(cartas), len(cartas) - n))
    return ob

"""Encaixa o rosto do Felipe nas fotos por pontos e grava um alvo de forma.

  python arte/felipe_rosto.py [--zerar] [--sem-perfil] [--debug DIR]
  python arte/felipe_rosto.py --checar DIR   # nao grava; foto x modelo alinhados

Frente: o detector de rosto do MediaPipe (478 pontos) roda na foto de frente e
num render da cabeca do modelo; cada ponto do render vira um ponto da malha
(raio da camera ate a pele), entao os dois conjuntos se correspondem sem
marcacao manual. A foto e alinhada ao modelo (escala, giro e posicao, minimos
quadrados), o deslocamento e espelhado (rosto simetrico) e espalhado pela
cabeca com pesos gaussianos.

Perfil: o contorno da frente do rosto (testa, nariz, labios, queixo) e tirado
da foto de perfil pela diferenca para a parede clara e comparado com o
contorno do modelo na mesma escala; a diferenca em profundidade move a faixa
do meio do rosto.

Saida: arte/felipe_rosto.target.gz (formato dos alvos do MakeHuman, indices
da malha base, decimetros). felipe_humano.py aplica esse alvo depois de FORMA.
Rodar de novo acumula (encaixe em passadas); --zerar recomeca.
"""
import gzip
import math
import os
import sys

import bpy  # antes do bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import felipe_humano as fh  # noqa: E402
import miguel_humano as base  # noqa: E402

FOTOS = os.path.join(AQUI, "referencias", "felipe", "fotos_originais")
FOTO_FRENTE = "36554.jpg"
FOTO_PERFIL = "36560.jpg"   # virado para a direita da imagem
ALVO = fh.ALVO_ROSTO
MODELO_MP = os.environ.get("FACE_LANDMARKER", os.path.join(AQUI, "..", "..", "face_landmarker.task"))
ESC = 0.30                  # largura (m) do quadro do render da cabeca
RES = 1024


# ----------------------------------------------------------- detector
def detector():
    import mediapipe as mp
    from mediapipe.tasks.python import BaseOptions, vision
    return mp, vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=MODELO_MP), num_faces=1))


def pontos(det, caminho):
    mp, d = det
    r = d.detect(mp.Image.create_from_file(caminho))
    if not r.face_landmarks:
        raise RuntimeError("rosto nao achado em " + caminho)
    from PIL import Image
    w, h = Image.open(caminho).size
    return np.array([[p.x * w, p.y * h] for p in r.face_landmarks[0]])


# ------------------------------------------------------------- render
def preparar_cena():
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    cena.render.film_transparent = False
    sh = cena.display.shading
    sh.light, sh.color_type = "STUDIO", "VERTEX"
    sh.show_specular_highlight = False
    cena.view_settings.view_transform = "Standard"
    cena.world = cena.world or bpy.data.worlds.new("W")
    cena.render.resolution_x = cena.render.resolution_y = RES
    cam_d = bpy.data.cameras.new("CamRosto")
    cam_d.type = "ORTHO"
    cam_d.ortho_scale = ESC
    cam = bpy.data.objects.new("CamRosto", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    return cena, cam


def render(cena, cam, centro, ang, caminho, transparente=False):
    a = math.radians(ang)
    cam.location = (centro.x + 2 * math.sin(a), centro.y - 2 * math.cos(a), centro.z)
    cam.rotation_euler = (math.radians(90), 0, a)
    cena.render.film_transparent = transparente
    cena.render.filepath = caminho
    bpy.ops.render.render(write_still=True)


def px_para_mundo(p, centro):
    """Pixel do render de frente -> (x, z) no mundo."""
    return (centro.x + (p[0] / RES - 0.5) * ESC, centro.z + (0.5 - p[1] / RES) * ESC)


# ------------------------------------------------------------ encaixe
def procrustes(a, b):
    """Escala s, giro R, translacao t com s*R*a + t ~ b (2D)."""
    ma, mb = a.mean(0), b.mean(0)
    a0, b0 = a - ma, b - mb
    u, sv, vt = np.linalg.svd(a0.T @ b0)
    r = (u @ vt).T
    if np.linalg.det(r) < 0:
        vt[-1] *= -1
        r = (u @ vt).T
    s = sv.sum() / (a0 ** 2).sum()
    return s, r, mb - s * (r @ ma)


def espelho(pts):
    """Indice do ponto simetrico (pelos pontos do modelo, que e simetrico)."""
    m = pts.copy()
    m[:, 0] *= -1
    d = ((pts[None, :, :] - m[:, None, :]) ** 2).sum(-1)
    return d.argmin(1)


def espalhar(vs, ctrl, desl, sigma, alcance):
    """Deslocamento de cada vertice: media gaussiana dos pontos de controle,
    sumindo quando o vertice esta longe de todos (alcance)."""
    out = np.zeros_like(vs)
    for i0 in range(0, len(vs), 4000):
        v = vs[i0:i0 + 4000]
        d2 = ((v[:, None, :] - ctrl[None, :, :]) ** 2).sum(-1)
        w = np.exp(-d2 / (2 * sigma ** 2))
        soma = w.sum(1, keepdims=True)
        media = (w @ desl) / np.maximum(soma, 1e-9)
        perto = np.sqrt(d2.min(1))
        fade = np.clip(1 - (perto - sigma) / alcance, 0, 1) ** 2
        out[i0:i0 + 4000] = media * fade[:, None]
    return out


def contorno_foto(caminho, x_max=None):
    """Para cada linha, o x mais a direita que nao e parede (perfil virado p/ dir.)."""
    from PIL import Image
    a = np.asarray(Image.open(caminho).convert("RGB"), np.float32)
    lum = a.mean(2)
    parede = np.median(lum[:, -60:], axis=1, keepdims=True)
    fg = lum < parede - 28
    h, w = fg.shape
    xs = np.full(h, np.nan)
    for y in range(h):
        c = np.where(fg[y, : x_max or w])[0]
        if len(c):
            xs[y] = c.max()
    return xs


def contorno_render(caminho):
    """Perfil do modelo (render transparente, olhando para a direita da imagem)."""
    from PIL import Image
    a = np.asarray(Image.open(caminho))[..., 3] > 10
    xs = np.full(a.shape[0], np.nan)
    for y in range(a.shape[0]):
        c = np.where(a[y])[0]
        if len(c):
            xs[y] = c.max()
    return xs


def painel(foto, render_png, m, saida, lado=600):
    """foto alinhada | modelo | metade de cada. m: matriz 2x3 foto px -> render px."""
    from PIL import Image
    r = Image.open(render_png).convert("RGBA")
    fundo = Image.new("RGBA", r.size, (205, 205, 200, 255))
    r = Image.alpha_composite(fundo, r).convert("RGB")
    a = np.vstack([m, [0, 0, 1]])
    inv = np.linalg.inv(a)[:2].ravel()
    f = Image.open(foto).convert("RGB").transform(r.size, Image.AFFINE, tuple(inv),
                                                  resample=Image.BICUBIC, fillcolor=(235, 235, 232))
    mist = Image.blend(f, r, 0.5)
    out = Image.new("RGB", (lado * 3, lado))
    for i, im in enumerate((f, r, mist)):
        out.paste(im.resize((lado, lado), Image.LANCZOS), (lado * i, 0))
    out.save(saida)


# contornos (indices do MediaPipe) das manchas pintadas no rosto
POLIGONOS = {
    "sobrancelha_d": [70, 63, 105, 66, 107, 55, 65, 52, 53, 46],
    "sobrancelha_e": [300, 293, 334, 296, 336, 285, 295, 282, 283, 276],
    "labios": [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314,
               17, 84, 181, 91, 146],
}
PINTURA = os.path.join(AQUI, "felipe_rosto_pintura.json")


def salvar_pintura(pf_m, s):
    """Polignos da foto (ja no espaco do modelo, x/z em metros) relativos ao meio
    das iris, simetrizados, mais pontos de referencia para cavanhaque e bigode."""
    import json
    meio = (pf_m[468] + pf_m[473]) / 2
    rel = pf_m - meio
    out = {}
    for nome, idx in POLIGONOS.items():
        out[nome] = rel[idx].round(5).tolist()
    # sobrancelhas espelhadas e promediadas (rosto simetrico)
    d, e = np.array(out["sobrancelha_d"]), np.array(out["sobrancelha_e"])
    m = (d * [-1, 1] + e) / 2
    out["sobrancelha_e"], out["sobrancelha_d"] = m.round(5).tolist(), (m * [-1, 1]).round(5).tolist()
    for nome, i in (("labio_baixo", 17), ("queixo", 152), ("subnasal", 2),
                    ("labio_cima", 0), ("canto_boca", 291), ("nariz_asa", 98)):
        out[nome] = rel[i].round(5).tolist()
    json.dump(out, open(PINTURA, "w"), indent=1)


def tracos(xs, olho):
    """Raiz do nariz, ponta do nariz e frente do queixo num contorno de perfil
    (x por linha, virado para a direita). Devolve {nome: (linha, x)}."""
    def faixa(a, b, f):
        lin = np.arange(int(a), int(b))
        v = xs[lin]
        i = f(np.where(np.isnan(v), -1e9 if f is np.argmax else 1e9, v))
        return float(lin[i]), float(xs[lin[i]])
    ponta = faixa(olho, olho + 260, np.argmax)
    d = ponta[0] - olho
    raiz = faixa(olho - 0.25 * d, ponta[0] - 0.3 * d, np.argmin)
    # labios -> dobra abaixo do labio -> queixo (o labio pode ficar mais a frente)
    d = ponta[0] - raiz[0]  # mais firme que o olho (o detector erra o olho de perfil)
    labio = faixa(ponta[0] + 0.5 * d, ponta[0] + 1.2 * d, np.argmax)
    dobra = faixa(labio[0], labio[0] + 0.8 * d, np.argmin)
    queixo = faixa(dobra[0], dobra[0] + 0.8 * d, np.argmax)
    return {"raiz": raiz, "ponta": ponta, "labio": labio, "dobra": dobra, "queixo": queixo}


def main():
    args = sys.argv[1:]
    if "--zerar" in args and os.path.exists(ALVO):
        os.remove(ALVO)
    dbg = args[args.index("--debug") + 1] if "--debug" in args else None
    chk = args[args.index("--checar") + 1] if "--checar" in args else None  # so mede e mostra
    if chk:
        os.makedirs(chk, exist_ok=True)
    if dbg:
        os.makedirs(dbg, exist_ok=True)
    tmp = dbg or os.path.join(AQUI, "..", "..", "tmp_rosto")
    os.makedirs(tmp, exist_ok=True)

    fh.configurar_base()
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    ob, bco, novo, grupo_face, k, z_min = base.construir_corpo()
    usados = np.array(sorted(novo, key=novo.get))
    _, _, faces_todas = base.ler_obj()
    jt = base.juntas(bco, faces_todas, k, z_min)
    cores = fh.pintar_rosto(ob, grupo_face)
    base.aplicar_cores(ob, cores)
    me = ob.data
    co = np.array([v.co[:] for v in me.vertices])
    olho_e = base.centro_grupo(me, grupo_face, "helper-l-eye")[0]
    olho_d = base.centro_grupo(me, grupo_face, "helper-r-eye")[0]
    centro = Vector((0, (olho_e.y + olho_d.y) / 2 + 0.06, (olho_e.z + olho_d.z) / 2 - 0.03))
    olhos = set()
    for g in ("helper-l-eye", "helper-r-eye"):
        olhos |= base.centro_grupo(me, grupo_face, g)[1]

    cena, cam = preparar_cena()
    det = detector()

    # ---------------- frente
    r_frente = os.path.join(tmp, "modelo_frente.png")
    render(cena, cam, centro, 0, r_frente)
    pm = pontos(det, r_frente)
    pf = pontos(det, os.path.join(FOTOS, FOTO_FRENTE))
    bvh = BVHTree.FromObject(ob, bpy.context.evaluated_depsgraph_get())
    ctrl, alvo2d = [], []
    xz = np.array([px_para_mundo(p, centro) for p in pm])
    # foto -> espaco do modelo (x, z): y da imagem cresce para baixo
    pf_xz = np.stack([pf[:, 0], -pf[:, 1]], 1)
    s, r, t = procrustes(pf_xz, xz)
    pf_m = (s * (r @ pf_xz.T)).T + t
    desl = pf_m - xz
    j = espelho(xz)
    desl = (desl + desl[j] * np.array([-1, 1])) / 2  # simetrico
    for i, (x, z) in enumerate(xz):
        hit = bvh.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)))
        if hit[0] is None:
            continue
        ctrl.append(hit[0][:])
        alvo2d.append(desl[i])
    ctrl = np.array(ctrl)
    alvo2d = np.array(alvo2d)
    erro_antes = np.sqrt((desl ** 2).sum(1)).mean()
    print("frente: %d pontos, desvio medio %.1f mm, escala foto->modelo %.5f m/px"
          % (len(ctrl), erro_antes * 1000, s))
    if chk:
        # foto px -> (x, -y) -> mundo (s, r, t) -> pixel do render
        sr = s * r
        mm = np.array([[RES / ESC, 0, RES / 2 - centro.x * RES / ESC],
                       [0, -RES / ESC, RES / 2 + centro.z * RES / ESC]])
        a = np.array([[sr[0, 0], -sr[0, 1], t[0]], [sr[1, 0], -sr[1, 1], t[1]]])
        m = mm[:, :2] @ a
        m[:, 2] += mm[:, 2]
        painel(os.path.join(FOTOS, FOTO_FRENTE), r_frente, m, os.path.join(chk, "rosto_frente.png"))
    if not chk:
        salvar_pintura(pf_m, s)
    d3 = np.zeros((len(ctrl), 3))
    d3[:, 0], d3[:, 2] = alvo2d[:, 0], alvo2d[:, 1]
    cabeca = co[:, 2] > jt["joint-neck"].z - 0.02
    total = np.zeros_like(co)
    total[cabeca] = espalhar(co[cabeca], ctrl, d3, 0.012, 0.035)

    # ---------------- perfil (profundidade da faixa do meio)
    if "--sem-perfil" not in args:
        r_lado = os.path.join(tmp, "modelo_perfil.png")
        render(cena, cam, centro, -90, r_lado, transparente=True)  # olhando p/ direita
        cm = contorno_render(r_lado)
        cf = contorno_foto(os.path.join(FOTOS, FOTO_PERFIL))
        # os dois contornos estao virados para a direita: x maior = mais a frente.
        # Tracos achados igual nos dois: raiz do nariz (o mais fundo entre olho e
        # ponta), ponta do nariz e frente do queixo.
        pp = pontos(det, os.path.join(FOTOS, FOTO_PERFIL))
        olho_lf = pp[[33, 133, 362, 263, 468, 473]][:, 1].mean()
        oz_m = (olho_e.z + olho_d.z) / 2 + total[list(olhos), 2].mean()
        olho_lm = (0.5 - (oz_m - centro.z) / ESC) * RES
        tf, tm = tracos(cf, olho_lf), tracos(cm, olho_lm)
        for nome, t in (("foto", tf), ("modelo", tm)):
            print("perfil %s (linha, x): %s" % (nome, " ".join(
                "%s %.0f,%.0f" % (n, *v) for n, v in t.items())))
        # foto -> pixels do render: escala e altura pelas linhas de raiz, ponta e
        # labio (minimos quadrados); profundidade pela raiz do nariz. O queixo dele
        # e recuado (quase nao passa da dobra), entao nao serve de regua.
        ref = ("raiz", "ponta", "labio")
        e, c0 = np.polyfit([tf[n][0] for n in ref], [tm[n][0] for n in ref], 1)
        linha_m = lambda lf: c0 + lf * e  # noqa: E731
        prof_m = lambda xf: tm["raiz"][1] + (xf - tf["raiz"][1]) * e  # noqa: E731
        if chk:
            m = np.array([[e, 0, tm["raiz"][1] - tf["raiz"][1] * e], [0, e, c0]])
            painel(os.path.join(FOTOS, FOTO_PERFIL), r_lado, m, os.path.join(chk, "rosto_perfil.png"))
        lin_f = np.arange(len(cf))
        lin_fm = linha_m(lin_f)
        a, b = int(tm["raiz"][0]) - 6, int(tm["queixo"][0] + 0.25 * (tm["queixo"][0] - tm["ponta"][0]))
        dz_lista = []
        for lm in range(a, b):
            if np.isnan(cm[lm]):
                continue
            xf = np.interp(lm, lin_fm, cf)
            if np.isnan(xf):
                continue
            z = centro.z + (0.5 - (lm + 0.5) / RES) * ESC
            dz_lista.append((z, -(prof_m(xf) - cm[lm]) * ESC / RES))  # frente = -y
        dz_lista = np.array(dz_lista)[::-1]  # z crescente
        zz, dd = dz_lista[:, 0], dz_lista[:, 1]
        dd = np.convolve(np.pad(dd, 4, mode="edge"), np.ones(9) / 9, mode="valid")
        print("perfil: %d linhas, desvio medio %.1f mm (max %.1f), escala %.3f"
              % (len(zz), np.abs(dd).mean() * 1000, np.abs(dd).max() * 1000, e))
        zs_m = centro.z + (0.5 - (np.arange(RES) + 0.5) / RES) * ESC
        frente_m = -(cm / RES - 0.5) * ESC
        ok_m = ~np.isnan(frente_m)
        frente_em = lambda z: np.interp(z, zs_m[ok_m][::-1], frente_m[ok_m][::-1])  # noqa: E731
        for i in np.where(cabeca)[0]:
            if i in olhos:
                continue
            x, y, z = co[i] + total[i]
            if z < zz.min() - 0.01 or z > zz.max() + 0.01:
                continue
            dy = np.interp(z, zz, dd)
            # so a frente do rosto, forte no meio e sumindo para os lados
            larg = 0.024 if z < oz_m - 0.012 else 0.035  # nariz/boca estreito
            wx = math.exp(-(x / larg) ** 2)
            # na frente da cabeca: ate ~3 cm atras do contorno naquela altura
            prof = max(0.0, min(1.0, 1 - (y - frente_em(z) - 0.012) / 0.025))
            fz = min(1.0, (z - (zz.min() - 0.01)) / 0.01, ((zz.max() + 0.01) - z) / 0.01)
            total[i, 1] += dy * wx * max(prof, 0.0) ** 0.5 * max(fz, 0.0)
        if dbg:
            np.savetxt(os.path.join(dbg, "perfil_dz.txt"), dz_lista)

    # olhos: translacao rigida (o globo nao deforma)
    for g in ("helper-l-eye", "helper-r-eye"):
        vs = list(base.centro_grupo(me, grupo_face, g)[1])
        total[vs] = total[vs].mean(0)

    if chk:
        return
    # ---------------- grava (acumula com o alvo anterior)
    ant = {}
    if os.path.exists(ALVO):
        idx, d = fh.ler_alvo_rosto()
        ant = {int(a): b for a, b in zip(idx, d)}
    f = 1 / (0.1 * k)
    for i in np.where(np.abs(total).sum(1) > 1e-6)[0]:
        dx, dy, dz = total[i]
        bi = int(usados[i])
        novo_d = np.array([dx * f, dz * f, -dy * f]) + ant.get(bi, 0)
        ant[bi] = novo_d
    with gzip.open(ALVO, "wt") as arq:
        arq.write("# Felipe: rosto encaixado nas fotos (arte/felipe_rosto.py)\n")
        for bi in sorted(ant):
            arq.write("%d %.5f %.5f %.5f\n" % (bi, *ant[bi]))
    print("alvo gravado: %s (%d vertices)" % (ALVO, len(ant)))


if __name__ == "__main__":
    main()

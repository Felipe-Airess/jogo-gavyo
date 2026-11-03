"""Animacoes 3D do Miguel, recriando as animacoes do 2D (assets/miguel.json).

Uso:
  blender -b -P arte/miguel_animacoes.py -- --glb arte/miguel_animado.glb \
      --manifesto arte/miguel_animacoes.json --previa arte/renders/animacoes

Como e feito (fluxo de animador de jogo de luta):
  * rig de controle: IK nas pernas (pes plantados no chao) e nos bracos
    (posicao do punho), quadril e coluna em FK; depois tudo e "assado"
    (bake) em keyframes nos ossos de deformacao e os controles somem;
  * golpes em tres fases, como em jogo de luta: preparacao (antecipacao,
    carrega o quadril), contato (quadril e ombro giram juntos, peso vai para
    a frente) e recuperacao (mais lenta que a ida);
  * mesma duracao total e mesmo instante de contato dos clipes 2D, para a
    logica de colisao do duelo continuar valendo (ver o manifesto JSON).

Guarda ortodoxa: pe esquerdo na frente, o personagem olha para -y.
Angulos das poses em graus, nos eixos do modelo: (inclina p/ frente, inclina
p/ o lado, gira). Posicoes em metros (x = esquerda dele, -y = frente, z = cima).
"""
import json
import math
import os
import runpy
import sys

import bpy
from mathutils import Euler, Matrix, Vector

AQUI = os.path.dirname(os.path.abspath(__file__))
FPS = 60

# ------------------------------------------------------------------ poses
TORNOZ = 0.085  # altura do tornozelo com o pe no chao

GUARDA = {
    "hip": (0.0, 0.03, -0.085), "hipR": (0, 0, -25),
    "spine": (11, 0, -5), "chest": (5, 0, -5), "uchest": (2, 0, 0),
    "neck": (-8, 0, 15), "head": (6, 0, 18),
    "mL": (0.11, -0.33, 1.27), "mR": (-0.10, -0.24, 1.29),
    "cL": (0.22, -0.05, 0.72), "cR": (-0.24, 0.05, 0.72),
    "pL": (0.11, -0.29, TORNOZ), "pLr": (0, 0, -15),
    "pR": (-0.12, 0.30, TORNOZ), "pRr": (0, 0, -45),
    "jL": (0.25, -1.0, 0.5), "jR": (-0.15, -1.0, 0.5),
}
RELAXADO = dict(GUARDA, **{
    "hip": (0.0, 0.0, -0.01), "hipR": (0, 0, 0),
    "spine": (2, 0, 0), "chest": (0, 0, 0), "uchest": (0, 0, 0),
    "neck": (0, 0, 0), "head": (2, 0, 0),
    "mL": (0.24, 0.02, 0.84), "mR": (-0.24, 0.02, 0.84),
    "cL": (0.5, 0.6, 1.1), "cR": (-0.5, 0.6, 1.1),
    "pL": (0.10, -0.01, TORNOZ), "pLr": (0, 0, 5),
    "pR": (-0.10, 0.01, TORNOZ), "pRr": (0, 0, -5),
    "jL": (0.1, -1.0, 0.5), "jR": (-0.1, -1.0, 0.5),
})
DEITADO = dict(GUARDA, **{  # caiu de costas: cabeca para +y, pes para -y
    "hip": (0.0, 0.42, -0.80), "hipR": (-88, 0, 0),
    "spine": (-2, 0, 0), "chest": (0, 0, 0), "uchest": (0, 0, 0),
    "neck": (5, 0, 0), "head": (5, 0, 10),
    "mL": (0.40, 0.55, 0.10), "mR": (-0.40, 0.60, 0.10),
    "cL": (0.9, 0.4, 0.0), "cR": (-0.9, 0.4, 0.0),
    "pL": (0.16, -0.42, 0.08), "pLr": (-70, 0, 10),
    "pR": (-0.18, -0.38, 0.08), "pRr": (-70, 0, -10),
    "jL": (0.3, -0.2, 1.5), "jR": (-0.3, -0.2, 1.5),
})
SEGURANDO = dict(GUARDA, **{  # clinch: maos na nuca do adversario
    "hipR": (0, 0, -10), "spine": (10, 0, -5), "uchest": (4, 0, 0),
    "neck": (0, 0, 8), "head": (5, 0, 8),
    "mL": (0.07, -0.38, 1.38), "mR": (-0.07, -0.38, 1.38),
    "cL": (0.30, -0.1, 0.9), "cR": (-0.30, -0.1, 0.9),
})
SEGURADO = dict(GUARDA, **{  # cabeca puxada para baixo pelo adversario
    "hip": (0.0, 0.06, -0.10), "hipR": (0, 0, -10),
    "spine": (22, 0, 0), "chest": (10, 0, 0), "uchest": (6, 0, 0),
    "neck": (8, 0, 5), "head": (12, 0, 5),
    "mL": (0.10, -0.32, 1.22), "mR": (-0.10, -0.30, 1.22),
})


def mais(a, b):
    return tuple(x + y for x, y in zip(a, b))


# ------------------------------------------------------------- animacoes
# nome: (id do clipe 2D, loop, duracao ms, contato ms ou None, base, chaves)
# chaves: [(ms, {sobrescreve a base})]. "off" desloca o corpo todo (passo).
A = {}


def anim(nome, clipe, loop, total, contato, chaves, base=GUARDA, **extra):
    A[nome] = dict(clipe=clipe, loop=loop, total=total, contato=contato,
                   base=base, chaves=chaves, **extra)


def sopro(base, periodo, amp=1.0, maos=0.01):
    """Respiracao: o peito sobe, o quadril desce, as maos acompanham."""
    m = periodo // 2
    sobe = {"hip": mais(base["hip"], (0, 0, 0.006 * amp)),
            "uchest": mais(base["uchest"], (-1.5 * amp, 0, 0)),
            "mL": mais(base["mL"], (0, 0, maos)), "mR": mais(base["mR"], (0, 0, maos))}
    desce = {"hip": mais(base["hip"], (0, 0, -0.006 * amp)),
             "uchest": mais(base["uchest"], (1.5 * amp, 0, 0))}
    return [(0, desce), (m, sobe), (periodo, desce)]


# --- paradas e transicoes
anim("idle", "idle", True, 3500, None, [
    (0, {}), (900, {"hip": (0.015, 0, -0.012), "hipR": (0, -2, 4), "head": (2, 0, -6)}),
    (1750, {"uchest": (2, 0, 0)}), (2600, {"hip": (-0.012, 0, -0.008), "hipR": (0, 2, -3),
                                          "head": (0, 0, 8)}), (3500, {})], base=RELAXADO)
anim("guarda", "m3_idle", True, 1200, None, sopro(GUARDA, 1200, 1.4))
anim("cansado", "m5_tired", True, 950, None, [
    (k, dict(v, **{"spine": (20, 0, -5), "head": (14, 0, 18)}))
    for k, v in sopro(dict(GUARDA, **{"hip": (0, 0, -0.10), "mL": (0.10, -0.26, 1.18),
                                     "mR": (-0.12, -0.18, 1.16), "uchest": (5, 0, 0)}),
                      950, 3.0, 0.02)],
    base=dict(GUARDA, **{"hip": (0, 0, -0.10), "mL": (0.10, -0.26, 1.18),
                         "mR": (-0.12, -0.18, 1.16), "spine": (20, 0, -5)}))
anim("entraGuarda", "m_enterGuard", False, 550, None, [
    (0, dict(RELAXADO)), (200, {"hip": (0, 0, -0.07), "mL": (0.10, -0.25, 1.30),
                                "mR": (-0.10, -0.18, 1.30)}), (550, {})])
anim("baixaGuarda", "m_lowerGuard", False, 455, None, [
    (0, {}), (180, {"mL": (0.16, -0.20, 1.02), "mR": (-0.16, -0.14, 1.02),
                    "cL": (0.4, 0.4, 0.9), "cR": (-0.4, 0.4, 0.9), "hip": (0, 0.01, -0.04)}),
    (455, dict(RELAXADO))])

# --- locomocao em guarda (no lugar; os pes deslizam sob o corpo)
def passo_guarda(total, frente=True):
    d = -0.10 if frente else 0.10
    a, b = ("pL", "pR") if frente else ("pR", "pL")
    pa, pb = GUARDA[a], GUARDA[b]
    h = total // 2
    return [
        (0, {a: pa, b: pb}),
        (h * 0.55, {a: mais(pa, (0, d * 0.5, 0.035)), "hip": (0, 0, -0.05)}),
        (h, {a: mais(pa, (0, d, 0)), b: mais(pb, (0, -d * 0.5, 0)), "hip": (0, 0, -0.065)}),
        (h + h * 0.55, {a: mais(pa, (0, d * 0.5, 0)), b: mais(pb, (0, 0, 0.035)),
                        "hip": (0, 0, -0.05)}),
        (total, {a: pa, b: pb}),
    ]


anim("andaFrente", "m4_walkFwd", True, 780, None, passo_guarda(780, True))
anim("andaTras", "m4_walkBack", True, 840, None, passo_guarda(840, False))
anim("comecaAndar", "m5_walkStart", False, 160, None, [
    (0, {}), (80, {"hip": (0, -0.02, -0.07)}), (160, {"hip": (0, -0.01, -0.06)})])
anim("paraAndar", "m5_walkStop", False, 165, None, [
    (0, {"hip": (0, -0.02, -0.065)}), (90, {"hip": (0, 0.01, -0.07)}), (165, {})])


def ciclo_andar(total):
    """Caminhada solta (sem guarda), no lugar."""
    q = total / 4
    def pe(fase):  # fase 0 = contato do calcanhar na frente
        return {0: (-0.17, 0.0), 1: (0.0, 0.0), 2: (0.17, 0.02), 3: (0.0, 0.09)}[fase]
    ch = []
    for i in range(5):
        fl, fr = pe(i % 4), pe((i + 2) % 4)
        alto = i % 2 == 1
        ch.append((q * i, {
            "pL": (0.10, fl[0], TORNOZ + fl[1]), "pR": (-0.10, fr[0], TORNOZ + fr[1]),
            "hip": (0, 0, -0.005 if alto else -0.03), "hipR": (0, 0, 6 * (1 if i % 4 == 0 else -1 if i % 4 == 2 else 0)),
            "mL": (0.23, 0.12 * (1 if i % 4 == 0 else -1 if i % 4 == 2 else 0), 0.86),
            "mR": (-0.23, -0.12 * (1 if i % 4 == 0 else -1 if i % 4 == 2 else 0), 0.86),
        }))
    return ch


anim("andarSolto", "m3_walk", True, 1000, None, ciclo_andar(1000), base=RELAXADO)


def ciclo_correr(total):
    q = total / 4
    corpo = {"spine": (14, 0, 0), "chest": (4, 0, 0), "hipR": (0, 0, 0),
             "neck": (-6, 0, 0), "head": (-2, 0, 0)}
    pes = [(-0.32, 0.0), (0.05, 0.0), (0.30, 0.22), (-0.05, 0.30)]
    ch = []
    for i in range(5):
        fl, fr = pes[i % 4], pes[(i + 2) % 4]
        s = 1 if i % 4 in (0, 1) else -1
        ch.append((q * i, dict(corpo, **{
            "pL": (0.10, fl[0], TORNOZ + fl[1]), "pR": (-0.10, fr[0], TORNOZ + fr[1]),
            "pLr": (-20 if fl[1] > 0.1 else 0, 0, 0), "pRr": (-20 if fr[1] > 0.1 else 0, 0, 0),
            "hip": (0, 0, -0.07 if i % 2 == 0 else -0.02), "hipR": (0, 0, 8 * s),
            "mL": (0.20, 0.18 * s, 1.08), "mR": (-0.20, -0.18 * s, 1.08),
            "cL": (0.5, 0.8, 0.9), "cR": (-0.5, 0.8, 0.9),
            "jL": (0.1, -1, 0.6), "jR": (-0.1, -1, 0.6),
        })))
    return ch


CORRE = ciclo_correr(560)
anim("correr", "m4_run", True, 560, None, CORRE)
anim("comecaCorrer", "m4_runStart", False, 350, None, [
    (0, {}), (120, {"hip": (0, -0.04, -0.09), "spine": (16, 0, -5)}),
    (350, CORRE[0][1])])
anim("paraCorrer", "m4_runStop", False, 410, None, [
    (0, CORRE[0][1]),
    (150, {"pL": (0.11, -0.42, TORNOZ), "hip": (0, 0.06, -0.12), "spine": (-4, 0, -5),
           "mL": (0.15, -0.30, 1.25), "mR": (-0.15, -0.20, 1.25)}),
    (410, {})])

# --- socos (preparacao -> contato -> recuperacao)
def soco(contato, total, prep, golpe, segura=35, recua=None):
    ch = [(0, {}), (contato * 0.45, prep), (contato, golpe),
          (contato + segura, dict(golpe))]
    if recua:
        ch.append(recua)
    ch.append((total, {}))
    return ch


JAB = {"hip": (0, -0.03, -0.065), "hipR": (0, 0, -36), "chest": (4, 0, -10),
       "neck": (-4, 0, 22), "head": (10, 0, 24),
       "mL": (0.03, -0.70, 1.45), "cL": (0.45, 0.0, 1.20),
       "mR": (-0.10, -0.24, 1.30), "pL": (0.11, -0.31, TORNOZ)}
anim("jab", "m3_jab", False, 327, 139, soco(
    139, 327, {"hip": (0, 0.0, -0.07), "hipR": (0, 0, -20),
               "mL": (0.08, -0.29, 1.37)}, JAB))

DIRETO = {"hip": (0, -0.06, -0.07), "hipR": (0, 0, 8), "spine": (8, 0, 6),
          "chest": (4, 0, 6), "neck": (-4, 0, -8), "head": (8, 0, -12),
          "mR": (-0.01, -0.72, 1.46), "cR": (-0.45, 0.2, 1.25),
          "mL": (0.11, -0.26, 1.30), "pRr": (28, 0, -5), "pR": (-0.12, 0.28, TORNOZ + 0.04)}
anim("direto", "m3_cross", False, 486, 157, soco(
    157, 486, {"hip": (0, 0.01, -0.075), "hipR": (0, 0, -33), "mR": (-0.11, -0.16, 1.40)},
    DIRETO))
anim("diretoCorpo", "m3_crossBody", False, 549, 248, soco(
    248, 549, {"hip": (0, 0.0, -0.11), "hipR": (0, 0, -30), "spine": (12, 0, -5)},
    dict(DIRETO, **{"hip": (0, -0.08, -0.17), "spine": (20, 0, 6), "head": (0, 0, -12),
                    "mR": (-0.02, -0.64, 1.12), "mL": (0.11, -0.26, 1.24)})))

PESADO = dict(DIRETO, **{"hip": (0, -0.10, -0.09), "hipR": (0, 0, 18), "spine": (20, 0, 8),
                         "chest": (8, 0, 6), "mR": (0.02, -0.70, 1.40),
                         "cR": (-0.5, 0.0, 1.7)})
anim("pesado", "m3_overhand", False, 688, 293, [
    (0, {}), (130, {"hip": (0, 0.03, -0.09), "hipR": (0, 0, -40), "spine": (0, 0, -8),
                    "mR": (-0.22, 0.08, 1.42)}),
    (230, {"hipR": (0, 0, -10), "mR": (-0.16, -0.38, 1.66), "cR": (-0.6, 0.1, 1.9)}),
    (293, PESADO), (330, dict(PESADO)),
    (440, dict(PESADO, **{"mR": (0.10, -0.52, 1.20), "spine": (24, 0, 10)})),
    (688, {})])

GANCHO = {"hip": (0, -0.02, -0.08), "hipR": (0, 0, -58), "chest": (4, 0, -12),
          "neck": (-4, 0, 30), "head": (8, 0, 32),
          "mL": (-0.06, -0.46, 1.46), "cL": (0.55, -0.15, 1.65),
          "pLr": (0, 0, -55), "pL": (0.11, -0.29, TORNOZ + 0.02)}
anim("gancho", "m4_hook", False, 590, 213, soco(
    213, 590, {"hipR": (0, 0, -12), "hip": (0, 0, -0.08),
               "mL": (0.30, -0.26, 1.42), "cL": (0.6, 0.1, 1.5)}, GANCHO, segura=60))
anim("jabCorpo", "m4_jabBody", False, 559, 167, soco(
    167, 559, {"hip": (0, 0, -0.12), "spine": (14, 0, -5), "hipR": (0, 0, -22)},
    dict(JAB, **{"hip": (0, -0.05, -0.18), "spine": (22, 0, -5), "head": (2, 0, 24),
                 "mL": (0.03, -0.62, 1.12)})))
anim("uppercut", "m4_uppercut", False, 680, 220, soco(
    220, 680, {"hip": (0, 0.0, -0.16), "hipR": (0, 0, -32), "spine": (12, 0, -5),
               "mR": (-0.12, -0.24, 1.08), "cR": (-0.3, 0.3, 0.6)},
    dict(DIRETO, **{"hip": (0, -0.04, -0.03), "hipR": (0, 0, 2), "spine": (-4, 0, 6),
                    "mR": (-0.01, -0.40, 1.56), "cR": (-0.25, -0.55, 0.75),
                    "pRr": (20, 0, -15)}), segura=75))
anim("cotovelada", "m4_elbow", False, 538, 158, soco(
    158, 538, {"hipR": (0, 0, -35), "mR": (-0.16, -0.12, 1.42)},
    dict(DIRETO, **{"hip": (0, -0.04, -0.07), "hipR": (0, 0, 14), "mR": (0.12, -0.28, 1.45),
                    "cR": (-0.7, -0.25, 1.55)}), segura=75))


def com_passo(chaves, avanco, desde):
    """O corpo todo anda 'avanco' m para a frente a partir do instante 'desde'."""
    out = []
    for t, p in chaves:
        p = dict(p)
        if t >= desde:
            p["off"] = (0, -avanco * min(1.0, (t - desde) / 120.0), 0)
        out.append((t, p))
    return out


anim("jabPasso", "m4_jabStep", False, 562, 182, com_passo(soco(
    182, 562, {"hip": (0, 0.0, -0.07), "hipR": (0, 0, -20), "mL": (0.08, -0.29, 1.37),
               "pL": (0.11, -0.36, TORNOZ + 0.04)},
    dict(JAB, **{"pL": (0.11, -0.33, TORNOZ)})), 0.16, 60), avanco=0.16)
anim("diretoPasso", "m4_crossStep", False, 666, 225, com_passo(soco(
    225, 666, {"hip": (0, 0.01, -0.075), "hipR": (0, 0, -33), "mR": (-0.11, -0.16, 1.40),
               "pL": (0.11, -0.36, TORNOZ + 0.04)}, DIRETO), 0.16, 80), avanco=0.16)

# --- chutes
def chute_circular(alto, contato, total, perna_z):
    golpe = {"hip": (0.05, -0.05, -0.04), "hipR": (0, -14, 80), "spine": (-10, 8, 5),
             "chest": (0, 6, 5), "neck": (0, 0, -40), "head": (6, 0, -40),
             "pR": (0.22, -0.78, perna_z), "pRsolto": 50, "jR": (0.9, 0.2, 1.6),
             "pL": (0.11, -0.27, TORNOZ), "pLr": (0, 0, -100),
             "mR": (-0.32, 0.22, 1.12), "cR": (-0.6, 0.6, 1.2),
             "mL": (0.11, -0.30, 1.32)}
    camara = {"hip": (0.04, -0.04, -0.05), "hipR": (0, -6, 35), "spine": (-4, 4, 0),
              "neck": (0, 0, -15), "head": (6, 0, -10),
              "pR": (-0.02, -0.30, perna_z * 0.55), "pRsolto": 40, "jR": (0.4, -0.9, 1.5),
              "pLr": (0, 0, -60), "mR": (-0.25, 0.10, 1.25)}
    return [(0, {}), (contato * 0.30, {"hip": (0.04, -0.02, -0.07), "hipR": (0, 0, -15)}),
            (contato * 0.70, camara), (contato, golpe), (contato + 50, dict(golpe)),
            (contato + (total - contato) * 0.45, dict(camara, **{"pR": (-0.06, -0.05, perna_z * 0.45)})),
            (total, {})]


anim("chuteCircular", "m3_roundKick", False, 663, 301, chute_circular(False, 301, 663, 1.10))
anim("chuteAlto", "m4_kickHigh", False, 944, 294, chute_circular(True, 294, 944, 1.48))
anim("chuteBaixo", "m3_lowKick", False, 717, 298, [
    (0, {}), (110, {"hip": (0.04, -0.02, -0.07), "hipR": (0, 0, -15)}),
    (200, {"hipR": (0, -4, 30), "pR": (-0.10, -0.05, 0.30), "pRsolto": 30, "jR": (0.2, -1, 0.8),
           "pLr": (0, 0, -50)}),
    (298, {"hip": (0.04, -0.06, -0.06), "hipR": (0, -10, 62), "spine": (-6, 6, 4),
           "neck": (0, 0, -30), "head": (6, 0, -30),
           "pR": (0.18, -0.58, 0.42), "pRsolto": 45, "jR": (0.8, -0.4, 0.9),
           "pLr": (0, 0, -80), "mR": (-0.30, 0.18, 1.18), "mL": (0.11, -0.30, 1.30)}),
    (350, {"hip": (0.04, -0.06, -0.06), "hipR": (0, -10, 66), "spine": (-6, 6, 4),
           "neck": (0, 0, -30), "head": (6, 0, -30),
           "pR": (0.24, -0.50, 0.38), "pRsolto": 45, "jR": (0.8, -0.4, 0.9),
           "pLr": (0, 0, -80), "mR": (-0.30, 0.18, 1.18), "mL": (0.10, -0.26, 1.46)}),
    (520, {"hipR": (0, 0, 10), "pR": (-0.10, 0.05, 0.20)}), (717, {})])
CHUTE_FRENTE = {"hip": (0, -0.02, -0.03), "hipR": (0, 0, -10), "spine": (-14, 0, -5),
                "neck": (2, 0, 10), "head": (10, 0, 12),
                "pL": (0.10, -0.84, 0.82), "pLr": (-45, 0, 0), "jL": (0.2, -1.0, 1.4),
                "mL": (0.12, -0.28, 1.28), "mR": (-0.14, -0.14, 1.28)}
anim("chutePasso", "m3_stepKick", False, 852, 400, com_passo([
    (0, {}), (150, {"hip": (0, -0.06, -0.08)}),
    (260, {"pR": (-0.10, -0.12, TORNOZ + 0.05), "hip": (0, -0.10, -0.06), "hipR": (0, 0, -5)}),
    (330, {"pR": (-0.10, -0.16, TORNOZ), "pL": (0.10, -0.40, 0.55), "pLr": (-20, 0, 0),
           "jL": (0.2, -1.0, 1.3), "hip": (0, -0.08, -0.05), "spine": (-6, 0, -5)}),
    (400, dict(CHUTE_FRENTE, pR=(-0.10, -0.16, TORNOZ))),
    (460, dict(CHUTE_FRENTE, pR=(-0.10, -0.16, TORNOZ))),
    (620, {"pR": (-0.10, -0.16, TORNOZ), "pL": (0.10, -0.42, 0.45), "jL": (0.2, -1, 1.2),
           "hip": (0, -0.06, -0.05)}),
    (852, {})], 0.20, 200), avanco=0.20)
JOELHADA = {"hip": (0, -0.10, -0.03), "hipR": (0, 0, -5), "spine": (-12, 0, -5),
            "neck": (4, 0, 8), "head": (10, 0, 8),
            "pR": (-0.05, -0.20, 0.55), "pRr": (40, 0, 0), "jR": (-0.05, -1.2, 1.5),
            "mL": (0.06, -0.48, 1.25), "mR": (-0.06, -0.46, 1.25),
            "cL": (0.3, -0.2, 0.9), "cR": (-0.3, -0.2, 0.9)}
anim("joelhada", "m3_knee", False, 581, 237, [
    (0, {}), (115, {"hip": (0, -0.03, -0.08), "mL": (0.06, -0.48, 1.42), "mR": (-0.06, -0.46, 1.42)}),
    (237, JOELHADA), (290, dict(JOELHADA)),
    (420, {"pR": (-0.10, 0.05, 0.25), "jR": (-0.1, -1, 0.9)}), (581, {})])

# --- combinacoes
anim("comboCorpoUpper", "m4_comboBodyUpper", False, 905, 385,
     A["jabCorpo"]["chaves"][:3] + [(230, {"hip": (0, 0, -0.16), "hipR": (0, 0, -32),
                                            "spine": (12, 0, -5), "mR": (-0.12, -0.24, 1.08),
                                            "cR": (-0.3, 0.3, 0.6)})] +
     [(385, A["uppercut"]["chaves"][2][1]), (460, A["uppercut"]["chaves"][2][1]), (905, {})],
     contatos=[167, 385])
anim("comboJabCotoveloJoelho", "m4_comboJabElbowKnee", False, 870, 350, com_passo([
    (0, {}), (40, {"mL": (0.08, -0.29, 1.37), "hipR": (0, 0, -20)}),
    (90, JAB), (150, {"hipR": (0, 0, -35), "mR": (-0.16, -0.12, 1.42)}),
    (220, dict(DIRETO, **{"hip": (0, -0.04, -0.07), "hipR": (0, 0, 14), "mR": (0.12, -0.28, 1.45),
                          "cR": (-0.7, -0.25, 1.55)})),
    (350, JOELHADA), (420, dict(JOELHADA)), (640, {"pR": (-0.10, 0.05, 0.25)}),
    (870, {})], 0.12, 120), contatos=[90, 220, 350], avanco=0.12)
anim("comboBaixoAlto", "m4_comboLowHigh", False, 928, 368,
     [(t * 0.55, p) for t, p in A["chuteBaixo"]["chaves"][:4]] +
     [(260, {"hipR": (0, 0, 20), "pR": (-0.06, -0.10, 0.45), "jR": (0.3, -1, 1.2)}),
      (368, chute_circular(True, 368, 928, 1.48)[3][1]),
      (420, chute_circular(True, 368, 928, 1.48)[3][1]),
      (650, {"hipR": (0, 0, 20), "pR": (-0.06, -0.05, 0.40)}), (928, {})],
     contatos=[164, 368])
anim("esquivaContra", "m4_slipCounter", False, 630, 330, [
    (0, {}), (150, {"hip": (0.07, -0.02, -0.13), "hipR": (0, 6, -30), "spine": (10, 12, -5),
                    "head": (10, 8, 18)}),
    (240, {"hip": (0.06, -0.02, -0.12), "hipR": (0, 6, -34), "spine": (10, 12, -5)}),
    (330, dict(DIRETO, hip=(0.02, -0.07, -0.09))), (400, dict(DIRETO)), (630, {})])
anim("aparaContra", "m4_parryCounter", False, 631, 231, [
    (0, {}), (110, {"mR": (0.04, -0.45, 1.30), "cR": (-0.4, 0.0, 0.9), "hipR": (0, 0, -18)}),
    (170, {"mR": (0.06, -0.30, 1.22), "hipR": (0, 0, -22), "mL": (0.08, -0.29, 1.37)}),
    (231, dict(JAB, mR=(0.0, -0.28, 1.30))), (290, dict(JAB)), (631, {})])

# --- defesa e reacoes
BLOQUEIO = {"hip": (0, 0.05, -0.09), "spine": (14, 0, -5), "neck": (-2, 0, 15), "head": (16, 0, 18),
            "mL": (0.08, -0.25, 1.40), "mR": (-0.08, -0.20, 1.41),
            "cL": (0.12, -0.35, 0.9), "cR": (-0.12, -0.35, 0.9)}
anim("bloqueio", "m4_block", False, 430, None, [
    (0, {}), (70, dict(BLOQUEIO, hip=(0, 0.05, -0.10))), (430, BLOQUEIO)])
anim("apanhaCabeca", "m4_hitHead", False, 380, None, [
    (0, {}), (60, {"hip": (0, 0.05, -0.06), "uchest": (-10, 0, 5), "neck": (-14, 0, 15),
                   "head": (-22, -6, 26), "mL": (0.14, -0.22, 1.38), "mR": (-0.14, -0.12, 1.36)}),
    (160, {"hip": (0, 0.04, -0.07), "uchest": (-6, 0, 3), "head": (-8, -3, 20)}), (380, {})])
anim("apanhaCorpo", "m4_hitBody", False, 450, None, [
    (0, {}), (70, {"hip": (0, 0.06, -0.10), "spine": (26, 0, -5), "chest": (10, 0, -5),
                   "head": (16, 0, 18), "mL": (0.06, -0.18, 1.12), "mR": (-0.08, -0.12, 1.10),
                   "cL": (0.3, 0.1, 0.8), "cR": (-0.3, 0.1, 0.8)}),
    (200, {"hip": (0, 0.05, -0.09), "spine": (18, 0, -5)}), (450, {})])
anim("apanhaPerna", "m4_hitLeg", False, 450, None, [
    (0, {}), (70, {"hip": (0.03, 0.02, -0.11), "hipR": (0, 10, -25),
                   "pL": (0.13, -0.14, TORNOZ + 0.05), "jL": (0.6, -0.8, 0.4),
                   "spine": (8, -8, -5), "mL": (0.16, -0.24, 1.32)}),
    (200, {"hip": (0.02, 0.01, -0.09), "hipR": (0, 5, -25)}), (450, {})])
anim("apanhaCabecaForte", "m4_hitHeadHeavy", False, 580, None, [
    (0, {}), (60, {"hip": (0, 0.08, -0.06), "hipR": (0, -6, -5), "uchest": (-14, 0, 15),
                   "neck": (-18, 0, -10), "head": (-28, -10, -20),
                   "mL": (0.30, -0.10, 1.30), "mR": (-0.30, 0.0, 1.28),
                   "cL": (0.7, 0.3, 1.0), "cR": (-0.7, 0.3, 1.0)}),
    (210, {"hip": (0, 0.14, -0.10), "pR": (-0.13, 0.44, TORNOZ), "hipR": (0, -4, -12),
           "uchest": (-6, 0, 8), "head": (-10, -6, 0),
           "mL": (0.20, -0.18, 1.24), "mR": (-0.20, -0.08, 1.22)}),
    (580, {})])
anim("grogue", "m4_dazed", True, 750, None, [
    (0, {"hip": (0.04, 0.02, -0.11), "hipR": (0, 6, -20), "head": (6, 12, 14)}),
    (375, {"hip": (-0.04, 0.03, -0.12), "hipR": (0, -6, -28), "head": (10, -12, 22)}),
    (750, {"hip": (0.04, 0.02, -0.11), "hipR": (0, 6, -20), "head": (6, 12, 14)})],
    base=dict(GUARDA, **{"mL": (0.14, -0.22, 1.12), "mR": (-0.14, -0.14, 1.10),
                         "spine": (14, 0, -5), "neck": (4, 0, 12)}))
anim("esquivaTras", "m4_leanBack", False, 460, None, [
    (0, {}), (130, {"hip": (0, 0.09, -0.08), "spine": (-18, 0, -5), "uchest": (-10, 0, 0),
                    "neck": (6, 0, 15), "head": (8, 0, 18), "mL": (0.08, -0.22, 1.36),
                    "pLr": (0, 0, -15)}),
    (230, {"hip": (0, 0.09, -0.08), "spine": (-18, 0, -5), "uchest": (-10, 0, 0),
           "neck": (6, 0, 15), "head": (8, 0, 18)}), (460, {})])
anim("guardaRompida", "m5_guardBreak", False, 655, None, [
    (0, BLOQUEIO), (95, {"hip": (0, 0.07, -0.07), "spine": (-12, 0, -5), "uchest": (-8, 0, 0),
                         "head": (-8, 0, 18),
                         "mL": (0.38, -0.12, 1.55), "mR": (-0.36, -0.06, 1.50),
                         "cL": (0.8, 0.2, 1.4), "cR": (-0.8, 0.2, 1.4)}),
    (295, {"hip": (0, 0.14, -0.10), "pR": (-0.13, 0.44, TORNOZ), "spine": (-4, 0, -5),
           "mL": (0.30, -0.16, 1.30), "mR": (-0.28, -0.08, 1.28)}),
    (655, {"mL": (0.12, -0.26, 1.22), "mR": (-0.12, -0.18, 1.20)})])

# --- chao
anim("queda", "m4_fall", False, 1580, None, [
    (0, {}), (80, {"hip": (0, 0.08, -0.08), "uchest": (-12, 0, 10), "head": (-20, 0, 10),
                   "mL": (0.30, -0.10, 1.35), "mR": (-0.30, 0.0, 1.30)}),
    (280, {"hip": (0, 0.20, -0.30), "hipR": (-25, 0, -15), "spine": (-10, 0, 0),
           "pR": (-0.13, 0.30, TORNOZ), "mL": (0.40, 0.10, 1.10), "mR": (-0.40, 0.15, 1.05)}),
    (440, dict(DEITADO, **{"hip": (0.0, 0.32, -0.66), "hipR": (-60, 0, -5),
                           "pL": (0.14, -0.30, 0.22), "pR": (-0.16, -0.25, 0.18)})),
    (580, dict(DEITADO, **{"hip": (0.0, 0.42, -0.79), "hipR": (-92, 0, 0), "head": (-10, 0, 10),
                           "pL": (0.16, -0.46, 0.14), "pR": (-0.18, -0.40, 0.12)})),
    (720, DEITADO), (1580, DEITADO)])
anim("deitado", "m4_lying", True, 900, None, [
    (0, DEITADO), (450, dict(DEITADO, uchest=(-3, 0, 0), hip=(0.0, 0.42, -0.795))), (900, DEITADO)],
    base=DEITADO)
anim("levantar", "m4_rise", False, 670, None, [
    (0, DEITADO),
    (130, dict(DEITADO, **{"hip": (0.0, 0.36, -0.70), "hipR": (-50, 0, 0), "spine": (10, 0, 0),
                           "mR": (-0.30, 0.45, 0.10), "pL": (0.14, -0.18, TORNOZ + 0.12),
                           "pR": (-0.14, -0.12, TORNOZ + 0.10), "jL": (0.3, -1, 1.2), "jR": (-0.3, -1, 1.2)})),
    (300, {"hip": (0.0, 0.10, -0.48), "hipR": (-5, 0, -15), "spine": (40, 0, -5), "chest": (10, 0, 0),
           "mR": (-0.30, 0.0, 0.40), "mL": (0.20, -0.30, 0.90),
           "pL": (0.12, -0.20, TORNOZ), "pR": (-0.14, 0.20, TORNOZ), "jL": (0.3, -1, 1.0)}),
    (470, {"hip": (0, 0.04, -0.20), "spine": (24, 0, -5), "mL": (0.10, -0.30, 1.20),
           "mR": (-0.12, -0.20, 1.15)}),
    (670, {})])
anim("apanhaChao", "m5_groundHit", False, 320, None, [
    (0, DEITADO), (50, dict(DEITADO, **{"hip": (0.0, 0.42, -0.78), "uchest": (8, 0, 0),
                                        "head": (14, 0, 10), "pL": (0.16, -0.40, 0.18),
                                        "mL": (0.30, 0.40, 0.25)})),
    (320, DEITADO)], base=DEITADO)
anim("socoChao", "m5_groundPunch", False, 540, 225, [
    (0, {}), (120, {"hip": (0, -0.06, -0.24), "spine": (32, 0, -5), "chest": (10, 0, 0),
                    "mR": (-0.12, -0.12, 1.15), "pL": (0.11, -0.38, TORNOZ)}),
    (225, {"hip": (0, -0.10, -0.34), "hipR": (0, 0, 0), "spine": (48, 0, 5), "chest": (14, 0, 0),
           "neck": (0, 0, 0), "head": (10, 0, -5),
           "mR": (-0.04, -0.60, 0.28), "cR": (-0.5, 0.2, 1.0), "mL": (0.10, -0.40, 0.80),
           "pL": (0.11, -0.38, TORNOZ)}),
    (300, {"hip": (0, -0.10, -0.33), "spine": (46, 0, 5), "mR": (-0.04, -0.56, 0.34),
           "pL": (0.11, -0.38, TORNOZ)}),
    (540, {})])
anim("pisao", "m5_stomp", False, 550, 235, [
    (0, {}), (130, {"hip": (0, -0.04, -0.03), "pR": (-0.08, -0.15, 0.55), "pRr": (10, 0, -20),
                    "jR": (-0.1, -1.2, 1.4), "spine": (-6, 0, -5), "mR": (-0.20, -0.10, 1.30)}),
    (235, {"hip": (0, -0.08, -0.10), "pR": (-0.06, -0.40, TORNOZ), "pRr": (0, 0, -20),
           "spine": (14, 0, -5), "head": (16, 0, 15)}),
    (300, {"hip": (0, -0.08, -0.10), "pR": (-0.06, -0.40, TORNOZ), "spine": (14, 0, -5)}),
    (550, {})])

# --- clinch e arremesso
anim("clinchPega", "m5_clinchGrab", False, 260, None, [
    (0, {}), (120, {"mL": (0.12, -0.40, 1.50), "mR": (-0.12, -0.40, 1.50), "hip": (0, -0.03, -0.06)}),
    (260, SEGURANDO)])
anim("clinchSegura", "m5_clinchHold", True, 640, None, [
    (0, SEGURANDO), (320, dict(SEGURANDO, hip=(0.02, -0.01, -0.07), hipR=(0, 3, -14))),
    (640, SEGURANDO)], base=SEGURANDO)
anim("clinchJoelhada", "m5_clinchKnee", False, 470, 190, [
    (0, SEGURANDO),
    (100, dict(SEGURANDO, mL=(0.06, -0.34, 1.38), mR=(-0.06, -0.34, 1.38), hip=(0, 0.0, -0.08))),
    (190, dict(JOELHADA, mL=(0.06, -0.30, 1.28), mR=(-0.06, -0.30, 1.28))),
    (240, dict(JOELHADA, mL=(0.06, -0.30, 1.28), mR=(-0.06, -0.30, 1.28))),
    (470, SEGURANDO)], base=SEGURANDO)
anim("clinchSolta", "m5_clinchRelease", False, 360, None, [
    (0, SEGURANDO), (130, {"mL": (0.10, -0.56, 1.38), "mR": (-0.10, -0.56, 1.38),
                           "hip": (0, 0.06, -0.07), "cL": (0.4, 0, 0.9), "cR": (-0.4, 0, 0.9)}),
    (360, {})])
anim("segurado", "m5_held", True, 850, None, [
    (0, SEGURADO), (425, dict(SEGURADO, hip=(0.03, 0.07, -0.11), hipR=(0, -4, -6))),
    (850, SEGURADO)], base=SEGURADO)
anim("clinchEscapa", "m5_clinchEscape", False, 465, None, [
    (0, SEGURADO), (110, dict(SEGURADO, mL=(0.04, -0.38, 1.50), mR=(-0.04, -0.38, 1.50),
                              cL=(0.2, -0.3, 1.0), cR=(-0.2, -0.3, 1.0))),
    (220, {"hip": (0, 0.10, -0.07), "spine": (4, 0, -5), "mL": (0.18, -0.50, 1.60),
           "mR": (-0.18, -0.48, 1.58), "pR": (-0.12, 0.42, TORNOZ)}),
    (465, {})])
anim("arremesso", "m5_throw", False, 615, 345, [
    (0, SEGURANDO), (115, dict(SEGURANDO, hip=(0, -0.04, -0.10), hipR=(0, 0, -20))),
    (235, dict(SEGURANDO, **{"hip": (0.05, -0.05, -0.12), "hipR": (0, 0, 40), "spine": (14, 0, 15),
                             "mL": (0.20, -0.34, 1.30), "mR": (-0.05, -0.30, 1.30),
                             "pR": (-0.02, -0.10, TORNOZ), "pRr": (0, 0, 60)})),
    (345, dict(SEGURANDO, **{"hip": (0.06, -0.04, -0.13), "hipR": (0, 0, 95), "spine": (16, 0, 20),
                             "neck": (0, 0, -40), "head": (14, 0, -30),
                             "mL": (0.40, 0.10, 0.80), "mR": (0.20, 0.10, 0.85),
                             "cL": (0.6, -0.4, 1.4), "cR": (0.0, -0.5, 1.4),
                             "pR": (-0.02, -0.10, TORNOZ), "pRr": (0, 0, 80), "pLr": (0, 0, 40)})),
    (450, dict(SEGURANDO, **{"hip": (0.06, -0.04, -0.11), "hipR": (0, 0, 80), "spine": (12, 0, 10),
                             "mL": (0.36, 0.05, 0.95), "mR": (0.15, 0.05, 0.95),
                             "pR": (-0.02, -0.10, TORNOZ), "pRr": (0, 0, 70)})),
    (615, {})], base=SEGURANDO)
anim("arremessado", "m5_thrown", False, 915, None, [
    (0, SEGURADO), (175, dict(SEGURADO, hip=(0.05, 0.0, -0.12), hipR=(0, -10, 30))),
    (345, {"hip": (0.15, 0.05, -0.30), "hipR": (-20, -30, 90), "spine": (20, 0, 10),
           "mL": (0.40, -0.10, 1.10), "mR": (-0.30, 0.10, 1.10), "pL": (0.20, -0.10, 0.30),
           "pR": (-0.05, 0.30, TORNOZ)}),
    (515, dict(DEITADO, **{"hip": (0.05, 0.30, -0.62), "hipR": (-60, -10, 30),
                           "pL": (0.20, -0.25, 0.25)})),
    (615, DEITADO), (915, DEITADO)])

# --------------------------------------------------------------- rig/bake
OSSOS_FK = {"spine": "Spine", "chest": "Chest", "uchest": "UpperChest", "neck": "Neck", "head": "Head"}


def rot_local(pb, graus):
    """Rotacao nos eixos do modelo -> quaternion no espaco local do osso."""
    m = pb.bone.matrix_local.to_3x3()
    r = Euler([math.radians(g) for g in graus], "XYZ").to_matrix()
    return (m.inverted() @ r @ m).to_quaternion()


def montar_controles(rig):
    """Cria alvos/polos (empties) e as restricoes IK dos bracos e pernas."""
    ctl = {}
    for nome in ("mL", "mR", "pL", "pR", "cL", "cR", "jL", "jR"):
        e = bpy.data.objects.new("ctl_" + nome, None)
        bpy.context.scene.collection.objects.link(e)
        e.rotation_mode = "QUATERNION"
        ctl[nome] = e
    pbs = rig.pose.bones
    for lado, L in (("Left", "L"), ("Right", "R")):
        ik = pbs[lado + "LowerArm"].constraints.new("IK")
        ik.target, ik.pole_target, ik.chain_count = ctl["m" + L], ctl["c" + L], 2
        ik = pbs[lado + "LowerLeg"].constraints.new("IK")
        ik.target, ik.pole_target, ik.chain_count = ctl["p" + L], ctl["j" + L], 2
        cr = pbs[lado + "Foot"].constraints.new("COPY_ROTATION")
        cr.target = ctl["p" + L]
        cr.mix_mode = "REPLACE"  # o alvo ja carrega a orientacao do pe em repouso
        cr.target_space = "WORLD"
        cr.owner_space = "WORLD"
    for pb in pbs:
        pb.rotation_mode = "QUATERNION"
    return ctl


def calibrar_polos(rig, ctl):
    """Acha o pole_angle que faz cotovelo/joelho apontar para o polo."""
    aplicar_pose(rig, ctl, GUARDA)
    for osso, polo in (("LeftLowerArm", "cL"), ("RightLowerArm", "cR"),
                       ("LeftLowerLeg", "jL"), ("RightLowerLeg", "jR")):
        ik = rig.pose.bones[osso].constraints[0]
        melhor = None
        for ang in range(-180, 180, 10):
            ik.pole_angle = math.radians(ang)
            bpy.context.view_layer.update()
            junta = rig.matrix_world @ rig.pose.bones[osso].head
            d = (ctl[polo].matrix_world.translation - junta).length
            if melhor is None or d < melhor[0]:
                melhor = (d, ang)
        ik.pole_angle = math.radians(melhor[1])
        print("polo %s: %d graus" % (osso, melhor[1]))


def aplicar_pose(rig, ctl, pose):
    pbs = rig.pose.bones
    off = Vector(pose.get("off", (0, 0, 0)))
    hip = Vector(pose["hip"]) + off
    hb = pbs["Hips"]
    m = hb.bone.matrix_local.to_3x3()
    hb.location = m.inverted() @ hip
    hb.rotation_quaternion = rot_local(hb, pose["hipR"])
    for chave, osso in OSSOS_FK.items():
        pbs[osso].rotation_quaternion = rot_local(pbs[osso], pose[chave])
    deitado = pose["hipR"][0] < -40  # no chao as maos nao seguem o quadril
    for chave in ("mL", "mR", "cL", "cR"):
        segue = Vector((0, 0, 0)) if deitado else Vector(pose["hip"]) - Vector(GUARDA["hip"])
        ctl[chave].location = Vector(pose[chave]) + off + segue
    for chave in ("pL", "pR", "jL", "jR"):
        ctl[chave].location = Vector(pose[chave]) + off
    for chave, osso in (("pL", "LeftFoot"), ("pR", "RightFoot")):
        # "pRsolto": pe segue a canela, com a ponta esticada (graus), nos chutes
        solto = pose.get(chave + "solto")
        pbs[osso].constraints[0].influence = 0.0 if solto is not None else 1.0
        pbs[osso].rotation_quaternion = rot_local(pbs[osso], (solto or 0, 0, 0))
        repouso = (rig.matrix_world.to_3x3() @ pbs[osso].bone.matrix_local.to_3x3())
        r = Euler([math.radians(g) for g in pose[chave + "r"]], "XYZ").to_matrix() @ repouso
        q = r.to_quaternion()
        if q.dot(repouso.to_quaternion()) < 0:
            q.negate()
        ctl[chave].rotation_quaternion = q


def pose_cheia(base, sobre):
    p = dict(base)
    p.update(sobre)
    return p


def chavear(rig, ctl, frame):
    pbs = rig.pose.bones
    pbs["Hips"].keyframe_insert("location", frame=frame)
    for osso in ["Hips"] + list(OSSOS_FK.values()):
        pbs[osso].keyframe_insert("rotation_quaternion", frame=frame)
    for e in ctl.values():
        e.keyframe_insert("location", frame=frame)
    for chave, osso in (("pL", "LeftFoot"), ("pR", "RightFoot")):
        ctl[chave].keyframe_insert("rotation_quaternion", frame=frame)
        pbs[osso].keyframe_insert("rotation_quaternion", frame=frame)
        pbs[osso].constraints[0].keyframe_insert("influence", frame=frame)


def assar(rig, ctl, nome, dados):
    """Chaveia os controles, assa nos ossos e devolve a acao final."""
    rig.animation_data_create()
    for e in ctl.values():
        e.animation_data_clear()
    rig.animation_data.action = None
    fim = round(dados["total"] * FPS / 1000)
    for t, sobre in dados["chaves"]:
        aplicar_pose(rig, ctl, pose_cheia(dados["base"], sobre))
        chavear(rig, ctl, t * FPS / 1000)
    bpy.context.scene.frame_start, bpy.context.scene.frame_end = 0, fim
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    controle = rig.animation_data.action
    bpy.ops.nla.bake(frame_start=0, frame_end=fim, step=1, only_selected=True,
                     visual_keying=True, clear_constraints=False, use_current_action=False,
                     bake_types={"POSE"})
    bpy.ops.object.mode_set(mode="OBJECT")
    acao = rig.animation_data.action
    acao.name = nome
    acao.use_fake_user = True
    rig.animation_data.action = None
    if controle and controle != acao:
        bpy.data.actions.remove(controle)
    for e in ctl.values():
        if e.animation_data and e.animation_data.action:
            bpy.data.actions.remove(e.animation_data.action)
    return acao, fim


# ---------------------------------------------------------------- previa
def ob_cor_vertice():
    return any(o.type == "MESH" and o.data.color_attributes for o in bpy.data.objects)


VISTAS = {"34": Vector((2.6, -3.6, 0.9)), "frente": Vector((0, -4.4, 0.4)),
          "lado": Vector((4.4, -0.2, 0.4))}


def renderizar_previas(rig, acoes, pasta, vista="34"):
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    cena.render.engine = "BLENDER_WORKBENCH"
    sh = cena.display.shading
    sh.light = "STUDIO"
    sh.color_type = "VERTEX" if ob_cor_vertice() else "TEXTURE"
    sh.show_specular_highlight = False
    sh.background_type = "VIEWPORT"
    sh.background_color = (0.55, 0.55, 0.57)
    cena.render.resolution_x, cena.render.resolution_y = 300, 340
    cam_d = bpy.data.cameras.new("CamPrevia")
    cam_d.type, cam_d.ortho_scale = "ORTHO", 2.4
    cam = bpy.data.objects.new("CamPrevia", cam_d)
    cena.collection.objects.link(cam)
    cena.camera = cam
    alvo = Vector((0, -0.15, 0.85))
    cam.location = alvo + VISTAS[vista]
    cam.rotation_euler = (alvo - cam.location).to_track_quat("-Z", "Y").to_euler()
    saida = {}
    for nome, (acao, fim, dados) in acoes.items():
        rig.animation_data.action = acao
        tempos = sorted(set([0, dados["total"] * 0.25, dados["contato"] or dados["total"] * 0.5,
                             dados["total"] * 0.65, dados["total"]]))
        arquivos = []
        for i, t in enumerate(tempos):
            cena.frame_set(min(fim, round(t * FPS / 1000)))
            cena.render.filepath = os.path.join(pasta, "%s_%d.png" % (nome, i))
            bpy.ops.render.render(write_still=True)
            arquivos.append((t, cena.render.filepath))
        saida[nome] = arquivos
    rig.animation_data.action = None
    return saida


# ------------------------------------------------------------------ main
def preparar(so=None):
    """Monta boneco, textura, rig e assa as animacoes. Devolve (rig, malha, acoes)."""
    cena = bpy.context.scene
    cena.render.fps = FPS
    if os.environ.get("MIGUEL_BONECO", "hd") == "hd":
        # boneco detalhado (malha do MakeHuman, cor por vertice)
        h = runpy.run_path(os.path.join(AQUI, "miguel_humano.py"), run_name="humano")
        ob, rig = h["construir_tudo"]()
    else:  # boneco low poly antigo
        b = runpy.run_path(os.path.join(AQUI, "gaviao_boneco_lowpoly.py"), run_name="boneco")
        ob = b["construir"]()
        b["texturizar"](ob, ob["k"], ob["z_min"])
        rig = b["riggar"](ob, ob["k"], ob["z_min"])
    ctl = montar_controles(rig)
    calibrar_polos(rig, ctl)

    acoes = {}
    for nome, dados in A.items():
        if so and nome not in so:
            continue
        acao, fim = assar(rig, ctl, nome, dados)
        acoes[nome] = (acao, fim, dados)
        print("animacao %-24s %4d ms  %3d quadros" % (nome, dados["total"], fim + 1))

    # os controles so existem para animar: some com eles antes de exportar
    for pb in rig.pose.bones:
        for c in list(pb.constraints):
            pb.constraints.remove(c)
    for e in ctl.values():
        bpy.data.objects.remove(e, do_unlink=True)
    for pb in rig.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_quaternion = (1, 0, 0, 0)
    return rig, ob, acoes


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    so = args[args.index("--so") + 1].split(",") if "--so" in args else None
    rig, ob, acoes = preparar(so)

    if "--manifesto" in args:
        man = {n: {"clipe2d": d["clipe"], "loop": d["loop"], "duracaoMs": d["total"],
                   "contatoMs": d["contato"], "contatosMs": d.get("contatos"),
                   "avancoM": d.get("avanco", 0.0), "quadros": fim + 1, "fps": FPS}
               for n, (a, fim, d) in acoes.items()}
        with open(os.path.abspath(args[args.index("--manifesto") + 1]), "w") as f:
            json.dump(man, f, indent=1, ensure_ascii=False)
    if "--previa" in args:
        vista = args[args.index("--vista") + 1] if "--vista" in args else "34"
        renderizar_previas(rig, acoes, os.path.abspath(args[args.index("--previa") + 1]), vista)
    if "--glb" in args:
        rig.animation_data_create()
        for nome, (acao, fim, d) in acoes.items():
            tr = rig.animation_data.nla_tracks.new()
            tr.name = nome
            tr.strips.new(nome, 0, acao)
        kw = {}
        if bpy.app.version >= (4, 0, 0):
            kw["export_animation_mode"] = "NLA_TRACKS"
        else:
            kw["export_nla_strips"] = True
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(args[args.index("--glb") + 1]),
                                  export_format="GLB", use_selection=True, export_apply=True,
                                  export_yup=True, **kw)


if __name__ == "__main__":
    main()

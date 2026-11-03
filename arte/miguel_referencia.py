"""Miguel ajustado às fotos, preservando o gerador original e o rig Mixamo.

  blender -b -P arte/miguel_referencia.py -- --render DIR --blend ARQ
  blender -b -P arte/miguel_rosto.py -- --zerar --sem-perfil --debug DIR

Saídas de revisão ficam separadas do personagem usado no jogo.
"""
import gzip
import json
import os
import sys

import bpy
import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import miguel_humano as base
from felipe_humano import cobertura, exportar

ALVO_ROSTO = os.path.join(AQUI, "miguel_rosto.target.gz")
PINTURA = os.path.join(AQUI, "miguel_rosto_pintura.json")
_forma_original = base.aplicar_forma
_pintura_original = base.pintar_corpo
_cabelo_original = base.criar_cabelo
_corpo_original = base.construir_corpo


def construir_corpo():
    resultado = _corpo_original()
    ob, _, _, grupos, _, _ = resultado
    # O encaixe frontal altera as pálpebras, mas não a profundidade dos globos.
    # Recuo de 2 mm evita planos quase coincidentes entre olho e pálpebra.
    for nome in ("helper-l-eye", "helper-r-eye"):
        _, indices = base.centro_grupo(ob.data, grupos, nome)
        for i in indices:
            ob.data.vertices[i].co.y += 0.002
    return resultado


def criar_cabelo(ob_corpo, olho_z):
    """Fecha as autointerseções deixadas pelo relevo de cachos original."""
    from mathutils.kdtree import KDTree
    ob, cores = _cabelo_original(ob_corpo, olho_z)
    kd = KDTree(len(ob.data.vertices))
    for v in ob.data.vertices:
        kd.insert(v.co, v.index)
    kd.balance()
    limite = len(ob.data.polygons) * 2
    base.remesh(ob, 0.0035)
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    base.suavizar(bm, 2, 0.35, manter_borda=False)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(ob.data)
    bm.free()
    dec = ob.modifiers.new("Cabelo_sem_sobreposicao", "DECIMATE")
    dec.ratio = min(1.0, limite / max(1, len(ob.data.polygons) * 2))
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier=dec.name)
    novas = np.array([cores[kd.find(v.co)[1]] for v in ob.data.vertices])
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob, novas


def ler_alvo_rosto():
    with gzip.open(ALVO_ROSTO, "rt") as arq:
        linhas = [l.split() for l in arq if l.strip() and not l.startswith("#")]
    return (np.array([int(p[0]) for p in linhas], np.int64),
            np.array([[float(x) for x in p[1:]] for p in linhas], np.float64))


def aplicar_forma(co):
    _forma_original(co)
    if os.path.exists(ALVO_ROSTO):
        idx, d = ler_alvo_rosto()
        np.add.at(co, idx, d)


def pintar_rosto(ob, grupo_face):
    """Contornos de sobrancelhas e lábios medidos na foto; olhos originais."""
    cores, _ = _pintura_original(ob, grupo_face, None)
    ob["olho_z"] = base.centro_grupo(ob.data, grupo_face, "helper-l-eye")[0].z
    if not os.path.exists(PINTURA):
        return cores
    with open(PINTURA) as arq:
        pt = json.load(arq)
    me = ob.data
    oe, ve = base.centro_grupo(me, grupo_face, "helper-l-eye")
    od, vd = base.centro_grupo(me, grupo_face, "helper-r-eye")
    meio, olhos = (oe + od) / 2, ve | vd
    pele = np.array(base.PELE)
    for v in me.vertices:
        if v.index in olhos or v.normal.y > -0.15 or v.co.y > meio.y + 0.02:
            continue
        x, z = v.co.x - meio.x, v.co.z - meio.z
        if not -0.16 < z < 0.07:
            continue
        cores[v.index, :3] = pele
        sob = max(cobertura(x, z, pt["sobrancelha_d"]),
                  cobertura(x, z, pt["sobrancelha_e"]))
        lab = cobertura(x, z, pt["labios"], 0.0012)
        if sob:
            cores[v.index, :3] = pele * (1 - sob) + np.array(base.SOBRANCELHA) * sob
        elif lab:
            cores[v.index, :3] = pele * (1 - lab) + np.array(base.LABIO) * lab
        else:
            # Bigode ralo visível nas referências, sem adicionar cavanhaque.
            if (pt["labio_cima"][1] < z < pt["subnasal"][1] - 0.002
                    and abs(x) < abs(pt["canto_boca"][0]) * 0.9):
                cores[v.index, :3] = pele * 0.88 + np.array(base.SOBRANCELHA) * 0.12
    return cores


def pintar_corpo(ob, grupo_face, jt):
    return pintar_rosto(ob, grupo_face), None


def configurar_base():
    base.aplicar_forma = aplicar_forma
    base.pintar_corpo = pintar_corpo
    base.criar_cabelo = criar_cabelo
    base.construir_corpo = construir_corpo
    cores_fotos = os.path.join(AQUI, "miguel_cores_fotos.json")
    if os.path.exists(cores_fotos):
        with open(cores_fotos) as arq:
            cores = json.load(arq)
        base.PELE = tuple(cores["pele_linear"])
        base.LABIO = tuple(cores["labios_linear"])
        base.CABELO = tuple(cores["cabelo_linear"])


def construir_tudo():
    configurar_base()
    import miguel_uniforme
    import miguel_calca_tenis
    miguel_uniforme.configurar(base)
    miguel_calca_tenis.configurar(base)
    ob, rig = base.construir_tudo()
    miguel_uniforme.limpar_residuo_interno(ob)
    miguel_calca_tenis.limpar_pele_tornozelos(ob)
    preparar_malha(ob, rig)
    miguel_uniforme.refazer_uv(ob)
    return ob, rig


def preparar_malha(ob, rig):
    """Corrige falhas encontradas pelo blender-asset-qa no modelo original."""
    import bmesh
    deform = {g.index: g for g in ob.vertex_groups if g.name in rig.data.bones}
    for v in ob.data.vertices:
        pesos = sorted(((g.weight, g.group) for g in v.groups if g.group in deform), reverse=True)
        soma = sum(w for w, _ in pesos[:4])
        for _, gi in pesos[4:]:
            deform[gi].remove([v.index])
        for w, gi in pesos[:4]:
            deform[gi].add([v.index], w / soma, "REPLACE")
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4])
    bm.to_mesh(ob.data)
    bm.free()
    # O material atual usa cores de vértice; peças geradas tinham UV zerada.
    # Abrir um atlas válido não muda a aparência e permite futuras texturas.
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.015)
    bpy.ops.object.mode_set(mode="OBJECT")


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ob, rig = construir_tudo()
    if "--render" in args:
        import miguel_uniforme
        miguel_uniforme.renderizar(os.path.abspath(args[args.index("--render") + 1]), ob)
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))
    exportar(args)
    print("Miguel referência: %d vértices, %d faces, %d ossos" % (
        len(ob.data.vertices), len(ob.data.polygons), len(rig.data.bones)))


if __name__ == "__main__":
    main()

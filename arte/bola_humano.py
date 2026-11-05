"""Bola, masculino e esguio, 1,75 m e aproximadamente 67 kg.

Pipeline do Felipe: MakeHuman, rosto por landmarks, cabelo por fatias,
pele medida, farda escolar em peças separadas, jeans e tênis.
Referências preservadas em arte/referencias/bola/.

Uso (Blender 3.6+ ou o modulo bpy):
  python arte/bola_humano.py -- --render DIR [--blend ARQ] [--glb ARQ] [--fbx ARQ] [--cards]
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

REF = os.path.join(AQUI, "referencias", "bola", "escolhidas")

# ---------------------------------------------------------------- medidas
# Bola: 1,75 m, aproximadamente 67 kg, masculino e esguio.
# Mistura neutra dos alvos base; nenhuma ancestralidade é inferida das fotos.
ALTURA = 1.75
MACRO = {"gender":1.0,"age":0.40,"muscle":0.35,"weight":0.40,
         "african":1/3,"asian":1/3,"caucasian":1/3}
FORMA = {"buttocks/buttocks-volume":-0.50,"torso/measure-hips-circ":-0.20,
         "neck/measure-neck-circ":-0.10}
# Nenhum slider de rosto: o ajuste vem somente dos landmarks e do perfil.
PELE = (0.4534564754857306, 0.1957399236131166, 0.10238550513668852)  # bochechas medidas nas fotos
CABELO = (0.018, 0.014, 0.013)


ALVO_ROSTO = os.path.join(AQUI, "bola_rosto.target.gz")  # gerado por bola_rosto.py
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
    """Os modulos do Miguel leem estes globais; troca para o Bola."""
    base.ALTURA, base.MACRO, base.FORMA = ALTURA, MACRO, FORMA
    base.PELE, base.CABELO = PELE, CABELO
    base.aplicar_forma = aplicar_forma
    # Paleta medida da farda/jeans da foto de corpo do Bola.
    base.BRANCO = (0.6592239918133873, 0.6592239918133873, 0.6387794556508168)
    base.JEANS = (0.0055217448502396585, 0.010397802292555288, 0.02201299491933654)
    base.VERDE = (0.08690125178766034, 0.20471011883667684, 0.15105804687051058)
    base.VERDE_ESC = (0.07592611945626479, 0.19751643144034023, 0.12752977781342206)
    base.AMARELO = (0.7011695015314021, 0.4704402453042184, 0.08919350686224782)
    base.TEAL = (0.07176144884623908, 0.14497212559723088, 0.11129941482466024)
    base.TENIS = (0.52, 0.5, 0.46)
    base.SOLA = (0.32, 0.32, 0.3)
    base.ROXO=base.TENIS  # não herdar o símbolo roxo do tênis do Miguel



# ------------------------------------------------------------ rosto
PINTURA = os.path.join(AQUI, "bola_rosto_pintura.json")  # gerado por bola_rosto.py
SOBRANCELHA = (0.035, 0.025, 0.022)
LABIO = (0.56, 0.25, 0.20)


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
    sobrancelhas e lábios. A barba rala da foto ainda não está representada."""
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
    pele = np.array(PELE)
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


# ------------------------------------------------------------- roupa
# Mesma técnica MakeHuman do pipeline: roupa é uma peça separada da pele.
def fazer_camiseta(ob, base_idx, dom, jt):
    camisa, _ = base.fazer_camisa(ob, base_idx, dom, jt)
    camisa.name=camisa.data.name="FardaPolo"
    # Polo branca: fecha o decote amplo herdado até a base do pescoço.
    bm=bmesh.new(); bm.from_mesh(camisa.data)
    borda={v for e in bm.edges if e.is_boundary for v in e.verts
           if v.co.z>jt["joint-l-shoulder"].z-.015 and abs(v.co.x)<.14}
    for v in borda:
        v.co.x *= .50
        v.co.z += .022
        v.co.y *= .80
    # Mais amostras para as faixas não virarem blocos de cores.
    bmesh.ops.subdivide_edges(bm,edges=list(bm.edges),cuts=1,use_grid_fill=True)
    bm.to_mesh(camisa.data); bm.free(); camisa.data.update()
    me=camisa.data; zq=jt["joint-pelvis"].z; zo=jt["joint-l-shoulder"].z
    tops={}
    for v in me.vertices:
        ix=int(abs(v.co.x)/.01); tops[ix]=max(tops.get(ix,0),v.co.z)
    from PIL import Image
    frente=np.asarray(Image.open(os.path.join(REF,"corpo_frente.jpg")).convert("RGB"),float)/255
    costas=np.asarray(Image.open(os.path.join(REF,"corpo_costas.jpg")).convert("RGB"),float)/255
    cores=np.ones((len(me.vertices),4),np.float32)
    for v in me.vertices:
        x,y,z=v.co; ax=abs(x); cor=base.BRANCO
        onda=zq+.16+.03*math.sin(x*11+.8)
        if z<onda: cor=base.VERDE if z>zq+.05+.02*math.sin(x*9) else base.VERDE_ESC
        diag=zq+.20-(x-.06)*1.6
        if x>.06 and y<.03 and abs(z-diag)<.011 and z<zq+.22: cor=base.AMARELO
        d=tops[int(ax/.01)]-z
        if .075<ax<.25 and y<.03 and 0<=d<.039:
            cor=(base.VERDE,base.TEAL,base.AMARELO)[min(int(d/.013),2)]
        # Estampa real recortada das fotos, amostrada na superfície da roupa.
        if y<-.035 and .038<x<.105 and zo-.16<z<zo-.075:
            u=(x-.038)/.067; vv=(zo-.075-z)/.085
            pixel=frente[int(395+vv*82),int(550+u*70)]
            if pixel.mean()<.58: cor=tuple(pixel**2.2)
        if y>.03 and -.105<x<.105 and zo-.105<z<zo-.045:
            u=(.105-x)/.21; vv=(zo-.045-z)/.060
            pixel=costas[int(310+vv*53),int(350+u*150)]
            if pixel.mean()<.57: cor=tuple(pixel**2.2)
        cores[v.index]=(*cor,1)
    return camisa,cores


def fazer_gola(jt):
    # Gola de polo dobrada, branca com friso verde. Peça presa ao tórax.
    n=64; verts=[]; faces=[]; colors=[]
    z=jt["joint-neck"].z; cy=-.005
    for raio,altura in ((1.,.024),(1.38,-.004),(1.43,-.006)):
        for i in range(n):
            a=2*math.pi*i/n
            x=.052*raio*math.cos(a); y=cy+.048*raio*math.sin(a)
            queda=.018*max(0,-math.sin(a))
            verts.append((x,y,z+altura-queda))
            colors.append((*((base.VERDE) if raio>1.4 else base.BRANCO),1))
    for j in range(2):
        for i in range(n):
            a=j*n+i; b=j*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    me=bpy.data.meshes.new("GolaPolo");me.from_pydata(verts,[],faces);me.update()
    gola=bpy.data.objects.new("GolaPolo",me);bpy.context.collection.objects.link(gola)
    return gola,np.asarray(colors,np.float32)

# ---------------------------------------------------------------- cabelo
def criar_cabelo(ob_corpo, olho):
    """Miolo do cabelo tirado das fotos (arte/bola_cabelo.py), cor escura com
    leve variacao (o brilho dos cachos vem das cards)."""
    import bola_cabelo
    if bola_cabelo.MIOLO == "fatias":
        ob = bola_cabelo.criar_nucleo_fatias(ob_corpo, olho)
    else:
        ob = bola_cabelo.criar_nucleo(ob_corpo, olho)
    me = ob.data
    # Abre a linha central da franja por deslocamento contínuo da superfície;
    # mantém a cobertura do crânio. Nada é recortado no topo.
    for v in me.vertices:
        x,y,z=v.co.x-olho.x,v.co.y-olho.y,v.co.z-olho.z
        if y<-.018 and .015<z<.105 and abs(x)<.042:
            v.co.z += .022*(1-abs(x)/.042)*math.sin(math.pi*(z-.015)/.09)
    me.update()
    cores = np.zeros((len(me.vertices), 4), np.float32)
    for v in me.vertices:
        t = 0.85 + 0.25 * math.sin(v.co.x * 260) * math.sin(v.co.z * 230 + v.co.y * 190)
        cores[v.index] = (CABELO[0] * t, CABELO[1] * t, CABELO[2] * t, 1)
    return ob, cores


def copiar_pesos_superficie(dest,corpo,so_osso=None):
    """Interpola pesos no triângulo da pele; evita degraus do vizinho mais próximo."""
    if so_osso:
        return base.copiar_pesos(dest,corpo,so_osso)
    from mathutils.bvhtree import BVHTree
    from mathutils.geometry import barycentric_transform
    me=corpo.data;me.calc_loop_triangles()
    faces=[tuple(t.vertices) for t in me.loop_triangles]
    bvh=BVHTree.FromPolygons([v.co for v in me.vertices],faces,all_triangles=True)
    nomes={g.index:g.name for g in corpo.vertex_groups}
    grupos={n:dest.vertex_groups.new(name=n) for n in base.MAPA_OSSOS}
    for v in dest.data.vertices:
        loc,_,face,_=bvh.find_nearest(v.co)
        if face is None: raise RuntimeError("Roupa sem superfície de suporte")
        ids=faces[face];a,b,c=[me.vertices[i].co for i in ids]
        weights=barycentric_transform(loc,a,b,c,Vector((1,0,0)),Vector((0,1,0)),Vector((0,0,1)))
        total={}
        for vi,factor in zip(ids,weights):
            for g in me.vertices[vi].groups:
                n=nomes[g.group]
                if n in grupos:total[n]=total.get(n,0)+max(0,factor)*g.weight
        for n,w in total.items():
            if w>1e-5:grupos[n].add([v.index],w,"REPLACE")


def revisar_malhas(objs, rig):
    """Limpeza de geometria e pesos de exportação; não altera poses."""
    for ob in objs:
        if ob.name == "Bola":
            bm=bmesh.new();bm.from_mesh(ob.data);visto=set();remover=[]
            for v0 in bm.verts:
                if v0 in visto: continue
                pilha=[v0];visto.add(v0);ilha=[]
                while pilha:
                    v=pilha.pop();ilha.append(v)
                    for edge in v.link_edges:
                        w=edge.other_vert(v)
                        if w not in visto: visto.add(w);pilha.append(w)
                # Restos de pele genital/virilha fechados sob a calça.
                if len(ilha)<100 and max(v.co.z for v in ilha)<1.2:
                    remover.extend(ilha)
            if remover: bmesh.ops.delete(bm,geom=remover,context="VERTS")
            bm.to_mesh(ob.data);bm.free()
        bm=bmesh.new();bm.from_mesh(ob.data)
        ng=[f for f in bm.faces if len(f.verts)>4]
        if ng: bmesh.ops.triangulate(bm,faces=ng)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
        bm.to_mesh(ob.data);bm.free()
        deform={g.index for g in ob.vertex_groups if g.name in rig.data.bones}
        for v in ob.data.vertices:
            ws=sorted([(g.group,g.weight) for g in v.groups if g.group in deform],key=lambda x:x[1],reverse=True)
            total=sum(w for _,w in ws[:4])
            for gi,w in ws:
                ob.vertex_groups[gi].remove([v.index])
            if total:
                for gi,w in ws[:4]: ob.vertex_groups[gi].add([v.index],w/total,"REPLACE")
        if not ob.data.uv_layers:
            bpy.ops.object.select_all(action="DESELECT");ob.select_set(True)
            bpy.context.view_layer.objects.active=ob
            bpy.ops.object.mode_set(mode="EDIT");bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(island_margin=.015)
            bpy.ops.object.mode_set(mode="OBJECT")


# ------------------------------------------------------------- tudo junto
def construir_tudo(com_cards=False):
    configurar_base()
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    ob, bco, novo, grupo_face, k, z_min = base.construir_corpo()
    ob.name = ob.data.name = "Bola"
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
    pecas = [fazer_camiseta(ob, usados, dom, jt), fazer_gola(jt), base.fazer_calca(ob, usados, dom, jt),
             base.fazer_tenis(ob, usados, dom, jt),
             criar_cabelo(ob, olho)]
    base.aplicar_cores(ob, cores)
    rig = base.riggar(ob, bco, faces_todas, k, z_min, usados)
    rig.name = rig.data.name = "BolaRig"
    for peca, cor in pecas:
        base.aplicar_cores(peca, cor)
        copiar_pesos_superficie(peca, ob, "Head" if peca.name.startswith("Cabelo") else None)
    extras = []
    if com_cards:  # experimental: cachos em cards (textura com recorte de alfa)
        import bola_cabelo
        cards = bola_cabelo.criar_cards(pecas[-1][0], olho)
        attr = cards.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")  # p/ o join
        attr.data.foreach_set("color", np.ones(len(cards.data.vertices) * 4, np.float32))
        base.copiar_pesos(cards, ob, "Head")
        extras.append(cards)
    base.esconder_pele(ob, usados, dom, jt)
    objs = [ob] + [p for p, _ in pecas] + extras
    base.prender(objs, rig)
    revisar_malhas(objs,rig)
    # Pele, farda, calça, tênis e cabelo permanecem peças distintas com o mesmo rig.
    for material in bpy.data.materials:
        if material.name=="Miguel": material.name="BolaCores"
    ob["olho_y"] = olho.y
    ob["olho_z"] = olho_z
    return ob, rig


def _luz_eevee(cena):
    """EEVEE: mostra a cor por vertice (pele, roupa) e a textura das cards juntas."""
    cena.render.engine = "BLENDER_EEVEE"
    cena.render.film_transparent = True
    cena.view_settings.view_transform = "Standard"
    mundo = cena.world or bpy.data.worlds.new("Mundo")
    cena.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.35, 0.35, 0.35, 1)
    cena.eevee.taa_render_samples = 16
    for nome_luz, energia, rot in (("Sol", 1.8, (50, 0, 30)), ("Contra", 0.8, (60, 0, 200))):
        luz = bpy.data.lights.new(nome_luz, "SUN")
        luz.energy = energia
        lo = bpy.data.objects.new(nome_luz, luz)
        lo.rotation_euler = [math.radians(a) for a in rot]
        cena.collection.objects.link(lo)


def renderizar(pasta, ob, olho_z, eevee=False):
    """Frente, lado, costas (corpo) e rosto de frente, 3/4 e perfil; fundo
    transparente para a comparacao com as fotos (arte/bola_comparar.py).
    Workbench (rapido, cor por vertice); com cards precisa de EEVEE (textura)."""
    os.makedirs(pasta, exist_ok=True)
    cena = bpy.context.scene
    if not eevee:
        cena.render.engine = "BLENDER_WORKBENCH"
        cena.render.film_transparent = True
        sh = cena.display.shading
        sh.light, sh.color_type = "STUDIO", "VERTEX"
        sh.show_specular_highlight = False
        cena.view_settings.view_transform = "Standard"
        # a luz de estudio escurece ~0,385x; +1,38 de exposicao faz a cor no render
        # bater com a cor da pele nas fotos (comparacao justa)
        cena.view_settings.exposure = 1.38
    else:
        _luz_eevee(cena)
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
    cards = "--cards" in args  # experimental (ver bola_cabelo.criar_cards)
    ob, rig = construir_tudo(com_cards=cards)
    print("Bola HD: %d vertices, %d faces, %d ossos" % (
        len(ob.data.vertices), len(ob.data.polygons), len(rig.data.bones)))
    if "--render" in args:
        renderizar(os.path.abspath(args[args.index("--render") + 1]), ob, ob["olho_z"], eevee=cards)
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(args[args.index("--blend") + 1]))
    exportar(args)


def exportar(args):
    """--glb ARQ (Godot) e --fbx ARQ (Mixamo): peças separadas + rig de 22
    ossos com nomes humanoides (Hips, Spine, ..., LeftUpperArm), pose em A."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        if o.type in ("MESH", "ARMATURE"):
            o.select_set(True)
    if "--glb" in args:
        bpy.ops.export_scene.gltf(filepath=os.path.abspath(args[args.index("--glb") + 1]),
                                  export_format="GLB", use_selection=True,
                                  export_apply=True, export_yup=True)
    if "--fbx" in args:
        bpy.ops.export_scene.fbx(filepath=os.path.abspath(args[args.index("--fbx") + 1]),
                                 use_selection=True, add_leaf_bones=False,
                                 bake_anim=False, colors_type="SRGB")


if __name__ == "__main__":
    main()

"""Vistas de revisão de um GLB do Miguel (antes/depois), com a mesma câmera.

  python arte/miguel_v2_vistas.py -- --glb ARQ.glb --saida DIR [--pose ACAO:QUADRO ...]

Importa o GLB num Blender limpo (módulo bpy), põe o rig em repouso e
renderiza em EEVEE com o mesmo estúdio de miguel_uniforme.renderizar:
corpo frente/lado/costas/3/4, rosto frente/3/4/perfil, nuca, e a mesma
frente reduzida para 160 px de altura (escala do jogo com filtro retrô).
Com --pose, cada ACAO:QUADRO vira um render extra de corpo inteiro (frente,
lado e 3/4) para teste de deformação.
"""
import math
import os
import sys

import bpy

ARGS = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def arg(nome, padrao=None):
    return ARGS[ARGS.index(nome) + 1] if nome in ARGS else padrao


def estudio(sc):
    sc.render.engine = "BLENDER_EEVEE"
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.exposure = .55
    mundo = bpy.data.worlds.new("Mundo")
    sc.world = mundo
    mundo.use_nodes = True
    mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (.35, .35, .35, 1)
    sc.eevee.taa_render_samples = 16
    for nome, energia, rot in (("Sol", 1.8, (50, 0, 30)), ("Contra", .8, (60, 0, 200))):
        luz = bpy.data.lights.new(nome, "SUN")
        luz.energy = energia
        lo = bpy.data.objects.new(nome, luz)
        lo.rotation_euler = [math.radians(a) for a in rot]
        sc.collection.objects.link(lo)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.abspath(arg("--glb")))
    saida = os.path.abspath(arg("--saida"))
    os.makedirs(saida, exist_ok=True)
    # Sobras de exportação (ex.: Icosphere) não fazem parte do personagem.
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not any(m.type == "ARMATURE" for m in o.modifiers):
            print("IGNORADO_NA_VISTA", o.name, len(o.data.polygons))
            o.hide_render = True
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    malha = next(o for o in bpy.data.objects if o.type == "MESH" and not o.hide_render)
    if rig.animation_data:
        rig.animation_data.action = None
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.location = (0, 0, 0)
    sc = bpy.context.scene
    estudio(sc)
    bpy.context.view_layer.update()
    cabeca = rig.matrix_world @ rig.pose.bones["Head"].head
    zo = cabeca.z + .04  # altura dos olhos
    zr = zo + .02
    cd = bpy.data.cameras.new("Cam")
    cd.type = "ORTHO"
    cam = bpy.data.objects.new("Cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam

    def foto(nome, ang, esc, z, res, elev=0.0):
        a = math.radians(ang)
        e = math.radians(elev)
        cam.location = (5 * math.sin(a) * math.cos(e), -5 * math.cos(a) * math.cos(e), z + 5 * math.sin(e))
        cam.rotation_euler = (math.pi / 2 - e, 0, a)
        cd.ortho_scale = esc
        sc.render.resolution_x, sc.render.resolution_y = res
        sc.render.filepath = os.path.join(saida, nome + ".png")
        bpy.ops.render.render(write_still=True)

    vistas = [
        ("frente", 0, 2.0, .92, (600, 1000)), ("lado", 90, 2.0, .92, (600, 1000)),
        ("costas", 180, 2.0, .92, (600, 1000)), ("tres_quartos", 35, 2.0, .92, (600, 1000)),
        ("rosto", 0, .34, zr, (800, 800)), ("rosto_34", 35, .34, zr, (800, 800)),
        ("rosto_lado", 90, .34, zr, (800, 800)), ("nuca", 180, .34, zr, (800, 800)),
        ("olhos", 0, .16, zo, (800, 400)),
        ("jogo_frente", 0, 2.0, .92, (96, 160)), ("jogo_34", 35, 2.0, .92, (96, 160)),
    ]
    if "--so-poses" not in ARGS:
        for v in vistas:
            foto(*v)
    for spec in [ARGS[i + 1] for i, a in enumerate(ARGS) if a == "--pose"]:
        acao_nome, quadro = spec.split(":")
        acao = bpy.data.actions.get(acao_nome)
        if acao is None:
            print("ACAO_AUSENTE", acao_nome)
            continue
        rig.animation_data_create()
        rig.animation_data.action = acao
        if hasattr(rig.animation_data, "action_slot") and acao.slots:
            rig.animation_data.action_slot = acao.slots[0]
        sc.frame_set(int(quadro))
        bpy.context.view_layer.update()
        hip = rig.matrix_world @ rig.pose.bones["Hips"].head
        for sufixo, ang in (("frente", 0), ("lado", 90), ("34", 35)):
            cam_z = max(.6, hip.z)
            a = math.radians(ang)
            cam.location = (hip.x + 5 * math.sin(a), hip.y - 5 * math.cos(a), cam_z)
            cam.rotation_euler = (math.pi / 2, 0, a)
            cd.ortho_scale = 2.3
            sc.render.resolution_x, sc.render.resolution_y = (600, 690)
            sc.render.filepath = os.path.join(saida, "pose_%s_%s_%s.png" % (acao_nome, quadro, sufixo))
            bpy.ops.render.render(write_still=True)
    tris = sum(len(p.vertices) - 2 for p in malha.data.polygons)
    print("VISTAS_OK", malha.name, "tris", tris, "verts", len(malha.data.vertices),
          "materiais", [m.name for m in malha.data.materials])


if __name__ == "__main__":
    main()

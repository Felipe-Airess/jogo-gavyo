"""Aplica os 25 FBX originais ao Miguel aprovado e exporta o pacote Godot.

bash scripts/blender-mac.sh -P arte/miguel_publicar_animacoes.py
Sem reduzir a amostragem dos FBX. Fontes completas ficam disponíveis na galeria;
recortes de treino têm procedência e duração próprias no manifesto.
"""
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
from PIL import Image, ImageDraw
from mathutils import Quaternion

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT/'arte'))
import miguel_mixamo as mx

OUT = ROOT/'arte/revisoes/miguel-animacoes-20261101'
# nome: arquivo, início/fim relativos, loop, instante relativo do contato.
TREINO = {
    'guarda': ('Ready_Idle', 0, 1, True, None),
    'andaFrente': ('Start_Walking', .45, 1, True, None),
    'andaTras': ('Start_Walking', 1, .45, True, None),
    'correr': ('Running', 0, 1, True, None),
    'jab': ('Punching_1', .15, .85, False, .45),
    'direto': ('Fist_Fight_A', .33, .56, False, .45),
    'gancho': ('Hook_Punch', .10, .85, False, .5),
    'pesado': ('Hell_Slammer_A', .05, .45, False, .5),
    'chuteCircular': ('Kicking', .25, .90, False, .5),
    'chuteAlto': ('Armada', .05, 1, False, .5),
    'joelhada': ('Knee_Jab', .25, .55, False, .5),
    'bloqueio': ('Blocking', .15, .40, True, None),
    'reacaoBloqueio': ('Body_Block', .30, .55, False, None),
    'esquivaTras': ('Dodging', .05, .60, False, None),
    'queda': ('Sweep_Fall', .30, 1, False, None),
    'deitado': ('Sweep_Fall', 1, 1, True, None),
    'levantar': ('Getting_Up', .35, 1, False, None),
    'comboCorpoUpper': ('Knee_Jabs_To_Uppercut', .10, .90, False, None),
}


def recortar(origem, nome, inicio, fim, loop):
    acao, total = origem
    novo = bpy.data.actions.new(nome)
    novo.use_fake_user = True
    n = max(1, round(abs(fim-inicio)*total))
    for fc in acao.fcurves:
        dest = novo.fcurves.new(fc.data_path, index=fc.array_index)
        dest.keyframe_points.add(n+1)
        for i, kp in enumerate(dest.keyframe_points):
            t = inicio*total + (fim-inicio)*total*i/n
            kp.co = (i, fc.evaluate(t))
            kp.interpolation = 'LINEAR'
    # Fecha o ciclo por crossfade no último décimo; quaternions via slerp.
    if loop:
        curvas = {(fc.data_path, fc.array_index): fc for fc in novo.fcurves}
        for caminho in {fc.data_path for fc in novo.fcurves}:
            grupo = sorted((fc for fc in novo.fcurves if fc.data_path == caminho),
                           key=lambda fc: fc.array_index)
            primeiro = [fc.keyframe_points[0].co.y for fc in grupo]
            for i in range(max(0, n-max(2, round(n*.1))), n+1):
                peso = (i-max(0, n-max(2, round(n*.1))))/max(1, min(n, max(2, round(n*.1))))
                atual = [fc.keyframe_points[i].co.y for fc in grupo]
                valores = (Quaternion(atual).slerp(Quaternion(primeiro), peso)
                           if caminho.endswith('rotation_quaternion') else
                           [a*(1-peso)+b*peso for a,b in zip(atual, primeiro)])
                for fc, valor in zip(grupo, valores):
                    fc.keyframe_points[i].co.y = valor
    return novo, n


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if '--pronto' in sys.argv:
        ob=next(o for o in bpy.data.objects if o.type=='MESH')
        rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
        rig.animation_data.action=None
        for tr in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(tr)
        originais={p.stem:(bpy.data.actions[p.stem], round(bpy.data.actions[p.stem].frame_range[1]))
                   for p in sorted((ROOT/'arte/mixamo').glob('*.fbx'))}
        for acao in list(bpy.data.actions):
            if acao.name not in originais:bpy.data.actions.remove(acao)
    else:
        ob, rig, originais = mx.carregar_tudo(str(ROOT/'arte/mixamo'), humano='miguel_referencia.py')
    acoes = dict(originais)
    manifesto = {}
    for nome, (acao, fim) in originais.items():
        manifesto[nome] = dict(fonte=f'{nome}.fbx', intervalo=[0,1], loop=False,
                              duracaoMs=round(fim/60*1000), contatoMs=None,
                              contatosMs=None, avancoM=0, quadros=fim+1, fps=60,
                              tipo='Mixamo completo')
    for nome, (fonte, inicio, fim, loop, contato) in TREINO.items():
        acoes[nome] = recortar(originais[fonte], nome, inicio, fim, loop)
        total = round(acoes[nome][1]/60*1000)
        manifesto[nome] = dict(fonte=f'{fonte}.fbx', intervalo=[inicio,fim], loop=loop,
                              duracaoMs=total, contatoMs=round(total*contato) if contato else None,
                              contatosMs=None, avancoM=0, quadros=acoes[nome][1]+1, fps=60,
                              tipo='Recorte de treino', contatoRevisado=False if contato else None)
    # Auditoria de todos os canais exportados: valores finitos, root sem translação horizontal.
    auditoria = {}
    for nome,(acao,fim) in acoes.items():
        assert fim > 0
        assert all(math.isfinite(k.co.y) for fc in acao.fcurves for k in fc.keyframe_points)
        auditoria[nome] = {'fim':fim, 'canais':len(acao.fcurves), 'valores_finitos':True}
    # location dos ossos usa a base local do repouso, não os eixos do chão.
    # Verifica o quadril avaliado no espaço da armadura em cinco poses por ação.
    mods=[(m,m.show_viewport) for m in ob.modifiers]
    for m,_ in mods:m.show_viewport=False
    for nome,(acao,fim) in acoes.items():
        rig.animation_data.action=acao
        pontos=[]
        for i in range(5):
            bpy.context.scene.frame_set(round(fim*i/4))
            pontos.append(tuple(rig.pose.bones['Hips'].head)[:2])
        desvio=max(math.dist(p,pontos[0]) for p in pontos)
        assert desvio<1e-4,(nome,desvio)
        auditoria[nome]['deslocamento_horizontal_max_m']=desvio
    for m,visivel in mods:m.show_viewport=visivel
    rig.animation_data.action = None
    mx.preparar_rig(rig)
    bpy.context.scene.frame_set(0)
    # Uma faixa NLA por ação; a exportação avalia cada faixa isoladamente.
    for nome,(acao,fim) in acoes.items():
        tr = rig.animation_data.nla_tracks.new()
        tr.name = nome
        tr.strips.new(nome, 0, acao)
        tr.mute = True
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'work/miguel-animado.blend'))
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True);rig.select_set(True)
    kw = ({'export_animation_mode':'NLA_TRACKS'} if bpy.app.version >= (4,0,0)
          else {'export_nla_strips':True})
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'arte/miguel_animado.glb'),
                             export_format='GLB', use_selection=True, export_apply=True,
                             export_yup=True, export_frame_range=False,
                             export_force_sampling=False, **kw)
    for pasta in (ROOT/'arte', ROOT/'godot-3d'):
        (pasta/'miguel_animacoes.json').write_text(json.dumps(manifesto,ensure_ascii=False,indent=2)+'\n')
    shutil.copy2(ROOT/'arte/miguel_animado.glb', ROOT/'godot-3d/miguel_animado.glb')
    (OUT/'canais.json').write_text(json.dumps(auditoria,indent=2)+'\n')
    print('PACOTE_EXPORTADO',len(acoes),flush=True)
    # EEVEE com a textura real do uniforme, 6 poses de cada um dos 25 FBX.
    from felipe_humano import _luz_eevee
    sc=bpy.context.scene;_luz_eevee(sc);sc.view_settings.exposure=.55
    sc.render.resolution_x,sc.render.resolution_y=220,300
    cd=bpy.data.cameras.new('CamAnimacoes');cd.type='ORTHO';cd.ortho_scale=2.7
    cam=bpy.data.objects.new('CamAnimacoes',cd);sc.collection.objects.link(cam);sc.camera=cam
    angle=math.radians(35);cam.location=(5*math.sin(angle),-5*math.cos(angle),.90)
    cam.rotation_euler=(math.pi/2,0,angle)
    for nome,(acao,fim) in originais.items():
        rig.animation_data.action=acao
        folha=Image.new('RGB',(1320,324),(225,228,230));draw=ImageDraw.Draw(folha)
        for i in range(6):
            f=round(fim*i/5);sc.frame_set(f)
            sc.render.filepath=str(ROOT/'work/animacao-quadro.png')
            bpy.ops.render.render(write_still=True)
            im=Image.open(sc.render.filepath).convert('RGBA')
            bg=Image.new('RGBA',im.size,(225,228,230,255))
            folha.paste(Image.alpha_composite(bg,im).convert('RGB'),(220*i,24))
            draw.text((220*i+4,5),f'{nome} / {f}',fill=(15,25,25))
        folha.save(OUT/f'{nome}.jpg',quality=90)
    rig.animation_data.action=None
    print('REVISAO_COMPLETA',len(originais),flush=True)


if __name__=='__main__':
    main()

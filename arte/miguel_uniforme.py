"""Uniforme polo do Miguel: caimento, gola, botões e atlas frente/costas.

As cores e a disposição vêm de referencias/miguel; o escudo é extraído da
foto camisa_frente.jpg, sem redesenhar letras. Integra miguel_referencia.py.
"""
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parent
ATLAS = ROOT/'texturas/miguel_uniforme.png'
MAT = 'Miguel_Uniforme_Polo'
MINX, MAXX, MINZ, MAXZ = -.36, .36, .86, 1.58
_camisa_original = None
_cores_original = None


def gerar_atlas(topo, zq, zo, ombros, eixos, limites):
    from PIL import Image, ImageFilter
    ATLAS.parent.mkdir(parents=True,exist_ok=True)
    # Região conferida visualmente na foto original de 1500 x 2000 pixels.
    foto = Image.open(ROOT/'referencias/miguel/camisa_frente.jpg').convert('RGB')
    selo = foto.crop((690,965,898,1133)).rotate(5,resample=Image.Resampling.BICUBIC,
                                             fillcolor=(235,235,230))
    pix = np.asarray(selo,dtype=np.float32)
    bg = np.asarray(selo.filter(ImageFilter.GaussianBlur(15)),dtype=np.float32)
    alpha = np.clip((bg.mean(2)-pix.mean(2)-13)/55,0,1)
    # Preserva as áreas coloridas do escudo e a coroa, sem o tecido branco.
    sat = (pix.max(2)-pix.min(2))/np.maximum(pix.max(2),1)
    alpha = np.maximum(alpha,np.clip((sat-.16)*4,0,1))
    alpha=np.where(alpha>=.45,alpha,0)
    alpha[:8]=0;alpha[-8:]=0;alpha[:,:8]=0;alpha[:,-8:]=0
    rgb = np.clip(pix/np.maximum(bg,80)*222,0,255).astype(np.uint8)
    selo = Image.fromarray(np.dstack([rgb,(alpha*255).astype(np.uint8)]),'RGBA')
    selo.save(ATLAS.parent/'miguel_escudo_foto.png')
    n=1024
    xx=np.linspace(MINX,MAXX,n); zz=np.linspace(MAXZ,MINZ,n)
    x,z=np.meshgrid(xx,zz)
    panels=[]
    for frente in (True,False):
        a=np.full((n,n,3),(229,231,224),dtype=np.float32)
        onda=zq+.16+.025*np.cos(x*12)
        a[z<onda]=(40,139,109)
        a[z<onda-.055]=(22,114,88)
        # Faixa mais escura junto à barra, como nas fotos.
        a[z<zq+.015]=(17,104,85)
        if frente:
            diagonal=.075+.40*(z-(zq-.035))+.006*np.sin(z*25)
            a[(np.abs(x-diagonal)<.005)&(z<onda+.015)]=(221,177,67)
        d=np.interp(np.abs(x),np.arange(len(topo))*.01,topo)-z
        faixa=(np.abs(x)>.067)&(np.abs(x)<.35)&(d>=0)&(d<.024)
        for i,cor in enumerate([(23,119,84),(32,135,129),(220,177,67)]):
            a[faixa&(d>=i*.008)&(d<(i+1)*.008)]=cor
        for ombro,eixo,limite in zip(ombros,eixos,limites):
            proj=(x-ombro[0])*eixo[0]+(z-ombro[2])*eixo[2]
            a[(proj>limite-.009)&(proj<limite+.008)&(np.sign(x)==np.sign(ombro[0]))&(np.abs(x)>.24)]=(22,111,76)
        tecido=1+.005*np.sin(x*5800)*np.sin(z*6200)+.003*np.cos(z*1500)
        im=Image.fromarray(np.clip(a*tecido[...,None],0,255).astype(np.uint8)).convert('RGBA')
        if frente:
            w,h=.095,.078
            x0,z0=.035,zo-.052
            box=(round((x0-MINX)/(MAXX-MINX)*n),round((MAXZ-z0)/(MAXZ-MINZ)*n))
            stamp=selo.resize((round(w/(MAXX-MINX)*n),round(h/(MAXZ-MINZ)*n)),Image.Resampling.LANCZOS)
            im.alpha_composite(stamp,box)
        panels.append(im.convert('RGB'))
    out=Image.new('RGB',(n,n*2));out.paste(panels[0],(0,0));out.paste(panels[1],(0,n));out.save(ATLAS)


def _peca(nome,verts,faces,cores,parte):
    import bpy
    me=bpy.data.meshes.new(nome);me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new(nome,me);bpy.context.scene.collection.objects.link(ob)
    attr=me.color_attributes.new('Col','FLOAT_COLOR','POINT')
    attr.data.foreach_set('color',np.asarray(cores,np.float32).ravel())
    layer=me.attributes.new('uniforme_parte','INT','FACE')
    layer.data.foreach_set('value',np.full(len(faces),parte,np.int32))
    return ob


def fazer_camisa(corpo,base_idx,dom,jt):
    import bpy
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    import miguel_humano as base
    cam,_=_camisa_original(corpo,base_idx,dom,jt)
    zq,zo=jt['joint-pelvis'].z,jt['joint-l-shoulder'].z
    zc=zo-.11
    faixa=[v.co for v in cam.data.vertices if abs(v.co.z-zc)<.015 and abs(v.co.x)<.20]
    ra=min(.182,max(abs(v.x) for v in faixa))
    cy=(max(v.y for v in faixa)+min(v.y for v in faixa))/2
    rf,rt=(cy-min(v.y for v in faixa))*1.04,(max(v.y for v in faixa)-cy)*1.04
    for v in cam.data.vertices:
        if v.co.z<zc and abs(v.co.x)<.205:
            t=min(1,(zc-v.co.z)/.10)
            cintura=math.exp(-((v.co.z-(zq+.15))/.13)**2)
            largura=ra*(1-.075*cintura)
            profundidade=1-.10*cintura
            quadril=math.exp(-((v.co.z-(zq-.012))/.075)**2)
            ry=min(rt if v.co.y>cy else rf,.103)*profundidade+.027*quadril
            ang=math.atan2((v.co.y-cy)/ry,v.co.x/ra)
            alvo=Vector((largura*math.cos(ang),cy+ry*math.sin(ang),v.co.z))
            v.co=v.co.lerp(alvo,t)
            # Dobras pequenas no tecido, sem marcar a cintura do corpo.
            v.co.y+=.0014*math.sin(v.co.x*82+v.co.z*18)*t
    ombros,eixos,limites=[],[],[]
    for lado in ('l','r'):
        a,b=jt[f'joint-{lado}-shoulder'],jt[f'joint-{lado}-elbow']
        eixo=(b-a).normalized();limite=(b-a).length*.5+.028
        for v in cam.data.vertices:
            p=(v.co-a).dot(eixo)
            if abs(v.co.x)>.22 and p>.025 and v.co.z>zq+.22:
                v.co+=eixo*(.028*min(1,(p-.025)/.08))
        ombros.append(a);eixos.append(eixo);limites.append(limite)
    cam.data.update()
    topo=np.zeros(40)
    for v in cam.data.vertices:
        i=min(int(abs(v.co.x)/.01),39);topo[i]=max(topo[i],v.co.z)
    # Preenche bins sem vértices para evitar faixas quebradas.
    ok=np.flatnonzero(topo>0);topo=np.interp(np.arange(40),ok,topo[ok])
    topo=np.convolve(np.pad(topo,2,mode='edge'),np.array([1,2,3,2,1])/9,mode='valid')
    gerar_atlas(topo,zq,zo,ombros,eixos,limites)
    bvh=BVHTree.FromObject(cam,bpy.context.evaluated_depsgraph_get())
    branco=(*base.BRANCO,1);verde=(.008,.18,.065,1)
    verts,faces,cores=[],[],[]
    n,rows=64,6
    for i in range(n+1):
        theta=.18+(2*math.pi-.36)*i/n
        inner=Vector((.058*math.sin(theta),-.014-.055*math.cos(theta),zo+.090))
        outer=Vector((.097*math.sin(theta),-.014-.098*math.cos(theta),zo+.072-.039*max(math.cos(theta),0)))
        distancia_frente=min(theta,2*math.pi-theta)-.18
        ponta=math.exp(-(distancia_frente/.45)**2)
        outer.x+=math.copysign(.034*ponta,math.sin(theta))
        outer.z-=.012*ponta
        # A borda externa acompanha a camisa e fica presa a ela; a dobra sobe.
        if math.cos(theta)>.05:
            hit=bvh.ray_cast(Vector((outer.x,-1,outer.z)),Vector((0,1,0)))
            if hit[0] is not None:
                near,normal=hit[0],hit[1]
            else:
                near,normal,_,_=bvh.find_nearest(outer)
        else:
            near,normal,_,_=bvh.find_nearest(outer)
        outer=near+normal*.0012
        for j in range(rows+1):
            t=j/rows;p=inner.lerp(outer,t)
            p.z+=.007*math.sin(math.pi*t)
            verts.append(tuple(p));cores.append(verde if j==rows else branco)
    for i in range(n):
        for j in range(rows):
            a=i*(rows+1)+j;b=a+rows+1;faces.append((a,b,b+1,a+1))
    gola=_peca('GolaPolo',verts,faces,cores,1)
    # Textura de vértice do restante das peças, separada do atlas da camisa.
    attr=cam.data.color_attributes.new('Col','FLOAT_COLOR','POINT')
    attr.data.foreach_set('color',np.ones(len(cam.data.vertices)*4,np.float32))
    cam.data.attributes.new('uniforme_parte','INT','FACE')
    pecas=[cam,gola]
    # Vista frontal da carcela: faixas seguem a superfície em vez de flutuar.
    verts,faces,cores=[],[],[]
    ztop=zo+.067
    for row in range(9):
        z=ztop-row*.012
        for x in (-.009,.009):
            hit=bvh.ray_cast(Vector((x,-1,z)),Vector((0,1,0)))
            y=hit[0].y-.0015 if hit[0] else -.08
            verts.append((x,y,z));cores.append(branco)
    for row in range(8):
        a=row*2;faces.append((a,a+1,a+3,a+2))
    pecas.append(_peca('CarcelaPolo',verts,faces,cores,1))
    for z in (ztop-.018,ztop-.057):
        hit=bvh.ray_cast(Vector((0,-1,z)),Vector((0,1,0)))
        if not hit[0]:continue
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=.0032,
                                            location=(0,hit[0].y-.003,z))
        bot=bpy.context.object;bot.name='BotaoPolo'
        bot.scale=(1,.45,1)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        a=bot.data.color_attributes.new('Col','FLOAT_COLOR','POINT')
        a.data.foreach_set('color',np.tile(np.array((.72,.73,.69,1),np.float32),(len(bot.data.vertices),1)).ravel())
        l=bot.data.attributes.new('uniforme_parte','INT','FACE')
        l.data.foreach_set('value',np.ones(len(bot.data.polygons),np.int32));pecas.append(bot)
    bpy.ops.object.select_all(action='DESELECT')
    for p in pecas:p.select_set(True)
    bpy.context.view_layer.objects.active=cam;bpy.ops.object.join()
    cam['uniforme_polo']=True
    colors=np.empty(len(cam.data.vertices)*4,np.float32)
    cam.data.color_attributes['Col'].data.foreach_get('color',colors)
    return cam,colors.reshape(-1,4)


def aplicar_cores(ob,cores):
    import bpy
    _cores_original(ob,cores)
    if not ob.get('uniforme_polo'):return
    mat=bpy.data.materials.get(MAT) or bpy.data.materials.new(MAT);mat.use_nodes=True
    nt=mat.node_tree;nt.nodes.clear()
    out=nt.nodes.new('ShaderNodeOutputMaterial');bs=nt.nodes.new('ShaderNodeBsdfPrincipled')
    bs.inputs['Roughness'].default_value=.91
    tex=nt.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ATLAS),check_existing=True)
    tex.image.colorspace_settings.name='sRGB';tex.image.pack();tex.interpolation='Linear'
    nt.links.new(tex.outputs['Color'],bs.inputs['Base Color']);nt.links.new(bs.outputs[0],out.inputs['Surface'])
    # Retira a multiplicação por cor de vértice no atlas; a gola usa Col normal.
    ob.data.materials.append(mat)
    partes=ob.data.attributes['uniforme_parte']
    for p in ob.data.polygons:p.material_index=0 if partes.data[p.index].value else 1


def refazer_uv(ob):
    uv=ob.data.uv_layers.active
    for p in ob.data.polygons:
        mat=ob.data.materials[p.material_index]
        if mat.name!=MAT:continue
        frente=p.normal.y<0
        for li in p.loop_indices:
            c=ob.data.vertices[ob.data.loops[li].vertex_index].co
            u=(c.x-MINX)/(MAXX-MINX)
            v=(c.z-MINZ)/(MAXZ-MINZ)
            uv.data[li].uv=(u,(.5+.5*v) if frente else .5*v)


def limpar_residuo_interno(ob):
    """Remove a ilha de pele de 21 vértices sob a cintura, identificada no QA."""
    import bmesh
    bm=bmesh.new();bm.from_mesh(ob.data);vistos=set();remover=[]
    for v in list(bm.verts):
        if v in vistos:continue
        ilha=[];pilha=[v];vistos.add(v)
        while pilha:
            atual=pilha.pop();ilha.append(atual)
            for e in atual.link_edges:
                outro=e.other_vert(atual)
                if outro not in vistos:vistos.add(outro);pilha.append(outro)
        if len(ilha)==21:
            coords=np.array([p.co[:] for p in ilha])
            centro=(coords.min(0)+coords.max(0))/2
            if np.linalg.norm(centro-np.array([0,-.124,.984]))<.002:
                remover.extend(ilha)
    if remover:bmesh.ops.delete(bm,geom=remover,context='VERTS')
    bm.to_mesh(ob.data);bm.free()


def configurar(base):
    global _camisa_original,_cores_original
    if _camisa_original is None:
        _camisa_original=base.fazer_camisa;_cores_original=base.aplicar_cores
    base.fazer_camisa=fazer_camisa;base.aplicar_cores=aplicar_cores


def renderizar(pasta,ob):
    import bpy
    from felipe_humano import _luz_eevee
    pasta=Path(pasta);pasta.mkdir(parents=True,exist_ok=True)
    # Reabrir um .blend renderizado não deve duplicar a iluminação do estúdio.
    for luz in [o for o in bpy.data.objects if o.type=='LIGHT']:
        bpy.data.objects.remove(luz,do_unlink=True)
    sc=bpy.context.scene;_luz_eevee(sc)
    sc.view_settings.exposure=.55
    sc.eevee.use_gtao=True;sc.eevee.gtao_distance=.08
    sc.render.image_settings.file_format='PNG'
    cd=bpy.data.cameras.new('CamUniforme');cd.type='ORTHO'
    cam=bpy.data.objects.new('CamUniforme',cd);sc.collection.objects.link(cam);sc.camera=cam
    for name,angle,scale,height,res in [
        ('frente',0,2,.92,(600,1000)),('lado',90,2,.92,(600,1000)),
        ('costas',180,2,.92,(600,1000)),('uniforme_frente',0,.78,1.22,(900,900)),
        ('uniforme_34',35,.78,1.22,(900,900)),('uniforme_costas',180,.78,1.22,(900,900)),
        ('rosto',0,.40,ob['olho_z']-.01,(800,800)),
        ('rosto_34',35,.40,ob['olho_z']-.01,(800,800)),
        ('rosto_lado',90,.40,ob['olho_z']-.01,(800,800)),
        ('calca_frente',0,1.10,.55,(800,1000)),
        ('tenis_34',35,.62,.14,(1000,600)),
        ('tenis_lado',90,.50,.14,(1000,600))]:
        a=math.radians(angle)
        centro_y=-.09 if name.startswith('tenis') else 0
        cam.location=(5*math.sin(a),centro_y-5*math.cos(a),height)
        cam.rotation_euler=(math.pi/2,0,a);cd.ortho_scale=scale
        sc.render.resolution_x,sc.render.resolution_y=res
        sc.render.filepath=str((pasta/(name+'.png')).resolve())
        bpy.ops.render.render(write_still=True)

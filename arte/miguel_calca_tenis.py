"""Revisão de silhueta do jeans e tênis a partir das referências do Miguel.

Mantém os ossos existentes. O jeans reaproveita a malha e afunila abaixo do
joelho; os tênis têm sola, cabedal, abertura e cadarços próprios.
"""
import math
from pathlib import Path

import numpy as np

_calca_original=None


def cor_jeans_foto():
    from PIL import Image
    a=np.array(Image.open(Path(__file__).resolve().parent/'referencias/miguel/corpo_frente2.jpg').convert('RGB'),dtype=float)
    rec=a[1150:1750,400:1100];r,g,b=rec[...,0],rec[...,1],rec[...,2]
    mask=(b>r+20)&(g>r+12)&(b<210)&(rec.mean(2)<190)
    if mask.sum()<100:raise RuntimeError('Área de jeans insuficiente na referência')
    srgb=np.median(rec[mask],axis=0)/255
    return np.where(srgb<=.04045,srgb/12.92,((srgb+.055)/1.055)**2.4)


def fazer_calca(corpo,base_idx,dom,jt):
    cal,_=_calca_original(corpo,base_idx,dom,jt)
    zk,za=jt['joint-l-knee'].z,jt['joint-l-ankle'].z
    for v in cal.data.vertices:
        lado='l' if v.co.x>=0 else 'r'
        joelho,tornozelo=jt[f'joint-{lado}-knee'],jt[f'joint-{lado}-ankle']
        t=max(0,min(1,(zk-v.co.z)/(zk-za)))
        centro=joelho.lerp(tornozelo,t)
        afunilar=1-.24*t**1.25
        v.co.x=centro.x+(v.co.x-centro.x)*afunilar
        v.co.y=centro.y+(v.co.y-centro.y)*(1-.14*t)
        # Vincos suaves concentrados no joelho e no tecido junto à barra.
        dobra=.0022*math.exp(-((v.co.z-zk)/.065)**2)*math.sin(v.co.z*110+v.co.x*12)
        dobra+=.0035*math.exp(-((v.co.z-(za+.065))/.05)**2)*math.sin(v.co.z*180+v.co.x*28)
        dy=v.co.y-centro.y;dx=v.co.x-centro.x;rad=math.hypot(dx,dy)
        if rad>1e-5:
            v.co.x+=dobra*dx/rad;v.co.y+=dobra*dy/rad
        if v.co.z<za+.085:
            tbarra=max(0,min(1,(za+.085-v.co.z)/.040))
            alvo=za+.031+.002*math.sin(math.atan2(dy,dx)*3)
            v.co.z=v.co.z*(1-tbarra)+alvo*tbarra
    cal.data.update()
    cor=cor_jeans_foto();cores=np.ones((len(cal.data.vertices),4),np.float32)
    for v in cal.data.vertices:
        lado='l' if v.co.x>=0 else 'r';k,a=jt[f'joint-{lado}-knee'],jt[f'joint-{lado}-ankle']
        t=max(0,min(1,(zk-v.co.z)/(zk-za)));centro=k.lerp(a,t)
        dx,dy=v.co.x-centro.x,v.co.y-centro.y
        frente=max(0,-dy/max(math.hypot(dx,dy),1e-5))
        lavado=1+.18*frente*math.exp(-((v.co.z-.67)/.19)**2)
        # Costura lateral e dobra da barra, evitando as faixas periódicas antigas.
        lateral=abs(dx)>abs(dy)*2.8 and abs(dx)>.035
        barra=v.co.z<za+.045
        fator=lavado*(.78 if lateral else 1)*(.83 if barra else 1)
        fator*=1+.012*math.sin(v.co.x*370+v.co.z*570)
        cores[v.index,:3]=cor*fator
    return cal,cores


def _tubo(verts,faces,colors,pontos,cor,raio=.0014):
    from mathutils import Vector
    start=len(verts);n=8
    for i,p in enumerate(pontos):
        tangent=Vector(pontos[min(i+1,len(pontos)-1)])-Vector(pontos[max(0,i-1)])
        tangent.normalize();u=tangent.cross(Vector((0,0,1))).normalized();v=tangent.cross(u).normalized()
        for j in range(n):
            q=Vector(p)+raio*(math.cos(2*math.pi*j/n)*u+math.sin(2*math.pi*j/n)*v)
            verts.append(tuple(q));colors.append(cor)
    for i in range(len(pontos)-1):
        for j in range(n):
            a=start+i*n+j;b=start+i*n+(j+1)%n;faces.append((a,b,b+n,a+n))
    # Tampas sem n-gons nem vértices coincidentes.
    for ring,inverter in [(0,True),(len(pontos)-1,False)]:
        ci=len(verts);verts.append(tuple(pontos[ring]));colors.append(cor)
        for j in range(n):
            a=start+ring*n+j;b=start+ring*n+(j+1)%n
            faces.append((ci,b,a) if inverter else (ci,a,b))


def fazer_tenis(corpo,base_idx,dom,jt):
    import bpy,bmesh
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    verts,faces=[],[];n=48
    for lado in ('l','r'):
        ankle=jt[f'joint-{lado}-ankle'];cx=ankle.x
        ytoe=jt[f'joint-{lado}-foot-2'].y-.011;yheel=ankle.y+.073
        yc=(ytoe+yheel)/2;half=(yheel-ytoe)/2
        start=len(verts)
        for layer in range(7):
            for j in range(n):
                theta=2*math.pi*j/n;sn,cs=math.sin(theta),math.cos(theta)
                sx=math.copysign(abs(sn)**.78,sn);sy=math.copysign(abs(cs)**.72,cs)
                width=.055*(.90 if cs>.2 else 1)
                x0=cx+width*sx;y0=yc+half*sy
                if layer<=3:
                    scales=[.96,1,1,.97];zz=[0,.006,.023,.030]
                    x=cx+(x0-cx)*scales[layer];y=yc+(y0-yc)*scales[layer];z=zz[layer]
                elif layer==4:
                    x=cx+(x0-cx)*.94;y=yc+(y0-yc)*.97;z=.048+.016*(cs+1)/2
                else:
                    # Abertura e contraforte ao redor do tornozelo.
                    scale=1 if layer==5 else .90
                    x=cx+.037*sx*scale;y=ankle.y-.012+.052*sy*scale
                    z=.110 if layer==5 else .107
                verts.append((x,y,z))
        for layer in range(6):
            for j in range(n):
                a=start+layer*n+j;b=a+n;faces.append((a,b,start+(layer+1)*n+(j+1)%n,start+layer*n+(j+1)%n))
        center=len(verts);verts.append((cx,yc,0))
        for j in range(n):faces.append((center,start+j,start+(j+1)%n))
    me=bpy.data.meshes.new('GEO-Tenis');me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new('GEO-Tenis',me);bpy.context.scene.collection.objects.link(ob)
    bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.subdivide_edges(bm,edges=bm.edges[:],cuts=2,use_grid_fill=True)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces[:]);bm.to_mesh(me);bm.free();me.update()
    colors=np.ones((len(me.vertices),4),np.float32)
    for v in me.vertices:
        lado='l' if v.co.x>0 else 'r';a=jt[f'joint-{lado}-ankle'];toe=jt[f'joint-{lado}-foot-2'].y-.011
        t=(v.co.y-toe)/(a.y+.073-toe)
        color=np.array((.78,.79,.76))
        if v.co.z<.009:color=np.array((.28,.29,.28))
        elif v.co.z<.028:color=np.array((.85,.85,.81))
        elif v.co.z<.035:color=np.array((.55,.57,.54))
        elif abs(v.co.x-a.x)<.025 and v.co.y<a.y-.055:color=np.array((.68,.70,.67))
        colors[v.index,:3]=color
    # Cadarços apoiados no cabedal, amostrando a altura da superfície.
    bpy.context.view_layer.update();bvh=BVHTree.FromObject(ob,bpy.context.evaluated_depsgraph_get())
    vv=[v.co[:] for v in me.vertices];ff=[tuple(p.vertices) for p in me.polygons];cc=colors.tolist()
    for lado in ('l','r'):
        ankle=jt[f'joint-{lado}-ankle']
        # Faixa roxa como superfície contínua: evita degraus de cor por vértice.
        for side in (-1,1):
            inicio=len(vv);valid=True
            for j in range(33):
                t=j/32;y=ankle.y-.170+.160*t
                z=.044+.035*t**1.8-.006*math.sin(math.pi*t)
                largura=.0006+.0035*math.sin(math.pi*t)**.7
                for altura in (z-largura,z+largura):
                    hit=bvh.ray_cast(Vector((ankle.x+side*.15,y,altura)),Vector((-side,0,0)))
                    if hit[0] is None:valid=False;break
                    vv.append((hit[0].x+side*.0018,y,altura));cc.append((.20,.075,.40,1))
                if not valid:break
            if valid:
                for j in range(32):
                    a=inicio+j*2;ff.append((a,a+2,a+3,a+1) if side>0 else (a+1,a+3,a+2,a))
            else:
                del vv[inicio:];del cc[inicio:]
        for row in range(5):
            y=ankle.y-.145+row*.015;pontos=[]
            for i in range(7):
                x=ankle.x-.023+i*.046/6;yy=y+.003*math.sin(i*math.pi/6)
                hit=bvh.ray_cast(Vector((x,yy,.3)),Vector((0,0,-1)))
                if hit[0]:pontos.append((x,yy,hit[0].z+.0008))
            if len(pontos)==7:_tubo(vv,ff,cc,pontos,(.90,.90,.86,1))
    me.clear_geometry();me.from_pydata(vv,[],ff);me.update()
    for p in me.polygons:p.use_smooth=True
    return ob,np.array(cc,np.float32)


def configurar(base):
    global _calca_original
    if _calca_original is None:_calca_original=base.fazer_calca
    base.fazer_calca=fazer_calca;base.fazer_tenis=fazer_tenis


def limpar_pele_tornozelos(ob):
    """Remove dois fragmentos isolados de pele antes cobertos pelo tênis antigo."""
    import bmesh
    bm=bmesh.new();bm.from_mesh(ob.data);vistos=set();remover=[]
    for v in bm.verts:
        if v in vistos:continue
        pilha=[v];ilha=[];vistos.add(v)
        while pilha:
            p=pilha.pop();ilha.append(p)
            for e in p.link_edges:
                q=e.other_vert(p)
                if q not in vistos:vistos.add(q);pilha.append(q)
        if len(ilha) in (15,18) and all(.05<p.co.z<.15 and .16<abs(p.co.x)<.25 for p in ilha):
            remover.extend(ilha)
    if remover:bmesh.ops.delete(bm,geom=remover,context='VERTS')
    bm.to_mesh(ob.data);bm.free()

"""Folhas foto | modelo | sobreposição, com alinhamento registrado e sem editar malhas.
Uso: work/venv-modelo/bin/python arte/bola_comparar.py DIR_RENDERS DIR_SAIDA
"""
import os,sys,json
from pathlib import Path
from urllib.request import urlopen
from urllib.parse import urlencode
import numpy as np
from PIL import Image,ImageOps,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];REF=ROOT/'arte/referencias/bola';FOTOS=REF/'escolhidas'

def points(file):
    endpoint=os.environ.get('FACE_LANDMARKER_URL','http://127.0.0.1:8767/landmarks')
    with urlopen(endpoint+'?'+urlencode({'file':str(file.resolve())}),timeout=90) as response:
        p=np.asarray(json.load(response),float)
    if len(p)!=478:raise RuntimeError(f'{file}: esperados 478 pontos, obtidos {len(p)}')
    return p

def similar(a,b):
    ca,cb=a.mean(0),b.mean(0);aa,bb=a-ca,b-cb
    u,s,vt=np.linalg.svd(aa.T@bb);r=(u@vt).T
    if np.linalg.det(r)<0:vt[-1]*=-1;r=(u@vt).T
    scale=s.sum()/(aa**2).sum();t=cb-scale*(r@ca)
    return np.column_stack([scale*r,t])

def panel(photo,model,matrix,out,title):
    bg=Image.new('RGBA',model.size,(205,205,200,255));render=Image.alpha_composite(bg,model).convert('RGB')
    inv=np.linalg.inv(np.vstack([matrix,[0,0,1]]))[:2].ravel()
    aligned=photo.transform(model.size,Image.Transform.AFFINE,tuple(inv),resample=Image.Resampling.BICUBIC,fillcolor=(235,235,232))
    size=(600,600 if model.height==model.width else 1000)
    ims=[aligned,render,Image.blend(aligned,render,.5)]
    sheet=Image.new('RGB',(1800,size[1]+45),(245,245,242));d=ImageDraw.Draw(sheet)
    for i,im in enumerate(ims):sheet.paste(im.resize(size,Image.Resampling.LANCZOS),(i*600,45))
    font_path=Path('/System/Library/Fonts/Supplemental/Arial.ttf')
    font=ImageFont.truetype(str(font_path),18) if font_path.exists() else ImageFont.load_default()
    d.text((8,7),title+' - FOTO | MODELO | SOBREPOSIÇÃO',fill='black',font=font)
    sheet.save(out)

def main():
    source=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=True)
    origin=json.loads((FOTOS/'origem.json').read_text());rows=json.loads((REF/'mediapipe-triagem.json').read_text())['fotos']
    alignment={}
    for label,photo_name,render_name in [('frente','rosto_frente.jpg','rosto.png'),('34','rosto_34_direita.jpg','rosto_34.png')]:
        photo=Image.open(FOTOS/photo_name).convert('RGB');render=Image.open(source/render_name).convert('RGBA')
        pf=np.asarray(next(r['landmarks'] for r in rows if r['arquivo']==origin[photo_name]))[:,:2]
        pm=points(source/render_name)
        # As fotos olham para a direita; a câmera de +35 graus mostra o lado oposto.
        if label=='34':
            render=ImageOps.mirror(render)
            mirrored=source/'rosto_34_espelhado.png';render.save(mirrored)
            pm=points(mirrored)
        m=similar(pf,pm);alignment[label]=m.tolist()
        panel(photo,render,m,out/(label+'.png'),label+'; registro 2D por landmarks')
        if label=='frente':
            rgb=np.asarray(render.convert('RGB'),float);samples=[]
            for index in [50,280,205,425,101,330]:
                x,y=np.round(pm[index]).astype(int);samples.append(np.median(rgb[y-6:y+7,x-6:x+7,:3],axis=(0,1)))
            measured=np.median(samples,axis=0);target=np.asarray(json.loads((REF/'pele-medida.json').read_text())['srgb_alvo'])
            report={'alvo_srgb':target.tolist(),'render_srgb':measured.tolist(),'diferenca_absoluta':np.abs(target-measured).tolist(),'passou_15_por_canal':bool(np.max(np.abs(target-measured))<=15),'metodo':'mesmos seis pontos de bochecha; mediana de patches 13x13, render Workbench Standard exposição +1,38'}
            (out/'pele-render.json').write_text(json.dumps(report,indent=2))
    al=json.loads((ROOT/'arte/bola_fotos_alinhamento.json').read_text());reg=al['registro_perfil']
    eye=json.loads((ROOT/'arte/revisoes/bola/olho-exportacao.json').read_text());k=.3/.4*800/1024
    m=np.array([[k*reg['escala'],0,400-k*512+k*reg['u0']-(eye['olho_y']+.06)*2000],[0,k*reg['escala'],400-k*512+k*reg['v0']+40]])
    render=ImageOps.mirror(Image.open(source/'rosto_lado.png').convert('RGBA'))
    panel(Image.open(FOTOS/'rosto_perfil_direita.jpg').convert('RGB'),render,m,out/'perfil.png','perfil; registro fixo, raiz inferida sob cabelo; modelo espelhado')
    alignment['perfil']=m.tolist()
    # Corpo: altura aparente, com diferença de pose explícita. Não calcula IoU.
    photo=Image.open(FOTOS/'corpo_frente.jpg').convert('RGB');render=Image.open(source/'frente.png').convert('RGBA')
    alpha=np.asarray(render)[:,:,3]>10;ys,xs=np.where(alpha)
    scale=(ys.max()-ys.min())/(1279-20);tx=(xs.min()+xs.max())/2-scale*510;ty=ys.min()-scale*20
    m=np.array([[scale,0,tx],[0,scale,ty]])
    panel(photo,render,m,out/'corpo.png','corpo: A-pose versus braços baixos; pontas dos tênis cortadas na foto; escala aproximada')
    alignment['corpo']=m.tolist();(out/'alinhamentos.json').write_text(json.dumps(alignment,indent=2))
    low=Image.new('RGBA',(426,240),(205,205,200,255));small=render.copy();small.thumbnail((200,240),Image.Resampling.NEAREST);low.alpha_composite(small,((426-small.width)//2,0));low.convert('RGB').save(out/'jogo-426x240.png');low.resize((1704,960),Image.Resampling.NEAREST).convert('RGB').save(out/'jogo-ampliado.png')
if __name__=='__main__':main()

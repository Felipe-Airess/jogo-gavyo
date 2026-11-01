import json,os,urllib.parse,urllib.request
import numpy as np
from PIL import Image
from pathlib import Path
ref=Path('arte/referencias/miguel');regs=[]
for name in ['rosto_frente.jpg','rosto_frente2.jpg','rosto_frente3.jpg','rosto_frente4.jpg']:
 with urllib.request.urlopen('http://127.0.0.1:8767/landmarks?'+urllib.parse.urlencode({'file':str((ref/name).resolve())}),timeout=100) as r: pts=np.array(json.load(r))
 a=np.asarray(Image.open(ref/name).convert('RGB'));h,w=a.shape[:2]
 def patch(pt,r=8):
  x,y=np.round(pt).astype(int);return a[max(0,y-r):min(h,y+r+1),max(0,x-r):min(w,x+r+1)].reshape(-1,3)
 cheeks=np.concatenate([patch(pts[i]) for i in [50,280,205,425,101,330]])
 lip=patch((pts[14]+pts[17])/2,5)
 x0,x1=np.floor(pts[:,0].min()).astype(int),np.ceil(pts[:,0].max()).astype(int)
 top=pts[10,1];height=pts[152,1]-top
 crop=a[max(0,int(top-height*.7)):max(1,int(top-height*.05)),max(0,x0):min(w,x1)]
 mask=(crop.max(2)<85)&(crop.max(2)-crop.min(2)<25)
 hair=crop[mask]
 regs.append({'foto':name,'pele_srgb':np.median(cheeks,axis=0).tolist(),'labios_srgb':np.median(lip,axis=0).tolist(),'cabelo_srgb':np.median(hair,axis=0).tolist(),'pixels_cabelo':int(mask.sum())})
res={'fontes':regs,'nota':'Cores aparentes das fotos sob a iluminação da sala, não albedo físico.'}
for key in ['pele','labios','cabelo']:
 c=np.median([r[key+'_srgb'] for r in regs],axis=0)/255
 res[key+'_linear']=np.where(c<=.04045,c/12.92,((c+.055)/1.055)**2.4).round(5).tolist()
Path('arte/miguel_cores_fotos.json').write_text(json.dumps(res,ensure_ascii=False,indent=2)+'\n');print(json.dumps(res,indent=2))
